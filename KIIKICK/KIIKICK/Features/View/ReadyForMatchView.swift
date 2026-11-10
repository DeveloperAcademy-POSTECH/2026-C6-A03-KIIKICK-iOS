//
//  ReadyForMatchView.swift
//  KIIKICK
//
//  Figma node 241:1767 / 544:4044 "ready" — "경기장 선택 or 생성 이후 경기 준비중 화면".
//  운동장을 기존 목록에서 고르든(FieldListView) 새로 등록하든(FieldNamingView) 마지막에
//  이 확인 화면을 거친 뒤에야 실제로 "경기 준비됨" 신호를 보낸다(onPrepare) — 두 진입
//  경로가 똑같이 이 화면으로 모인다.
//
//  우측 상단 "…" 메뉴에 "경기장 삭제하기"가 있고(544:4044가 그 메뉴를 펼친 상태),
//  눌렀을 때 뜨는 확인 Alert는 node 544:4105 "Alert" — UserProfileView의 "친구 삭제"
//  Alert와 같은 네이티브 SwiftUI .alert 패턴.
//
//  "selected field" 썸네일은 Figma 목업에서는 범용 축구장 일러스트지만, FieldThumbnailView
//  주석 참고 — 실제 등록 좌표로 렌더링한 위성 스냅샷을 쓴다(FieldNamingView와 동일 컴포넌트).
//

import CoreLocation
import SwiftData
import SwiftUI

struct ReadyForMatchView: View {
    @Environment(\.modelContext) private var modelContext

    let field: Field
    /// "준비하기"를 눌렀을 때 호출된다 — 실제 워치 연동(sessionManager.updateMatchPrepared)과
    /// 홈 화면까지의 복귀는 호출부(FieldListView/FieldNamingView를 거쳐 HomeView)가 맡는다.
    var onPrepare: () -> Void = {}
    /// 운동장이 삭제됐을 때 호출된다 — 호출부가 이 화면을 닫는다.
    var onDeleted: () -> Void = {}

    @State private var isPresentingDeleteConfirm = false
    @State private var isEditingField = false
    @State private var pendingDeleteKey: UUID?
    @State private var isMutating = false
    @State private var mutationErrorMessage = ""
    @State private var isPresentingMutationError = false

    private var correctedCoordinates: [CLLocationCoordinate2D] {
        [field.cornerA, field.cornerB, field.cornerC, field.cornerD].map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    var body: some View {
        VStack(spacing: 28) {
            FieldThumbnailView(coordinates: correctedCoordinates)
                .padding(.horizontal, 24)

            Text("\(field.name)에서의\n경기를 준비할까요?")
                .font(.body1M)
                .foregroundStyle(.colorTextPrimary)
                .multilineTextAlignment(.center)

            Spacer()

            CtaView(text: isMutating ? "처리 중..." : "준비하기", type: .primary, size: .large, isActive: !isMutating) {
                onPrepare()
            }
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("경기 준비")
        .navigationBarTitleDisplayMode(.inline)
        // FieldListView가 자기 화면에서 .navigationBarHidden(true)로 네비게이션 바를
        // 숨기고 커스텀 헤더를 직접 그리는데, 이 "숨김" 상태가 SwiftUI에서 같은
        // NavigationStack의 다음 화면까지 새어 들어오는 경우가 있다 — 그 상태로
        // 여기로 넘어오면 시스템 바 레이아웃이 제대로 안 잡혀서 뒤로가기/말줄임 버튼이
        // 겹쳐 보였다. 명시적으로 false를 줘서 이 화면은 항상 정상적으로 보이게 한다.
        .navigationBarHidden(false)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("경기장 수정하기", systemImage: "pencil") {
                        isEditingField = true
                    }
                    Button("경기장 삭제하기", role: .destructive) {
                        isPresentingDeleteConfirm = true
                    }
                } label: {
                    Label("경기장 관리", systemImage: "ellipsis")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.gray50)
                        .frame(width: 44, height: 44)
                }
                .disabled(isMutating)
            }
        }
        .navigationDestination(isPresented: $isEditingField) {
            FieldCreationView(
                editingField: field,
                onFinish: { isEditingField = false },
                onFieldUpdated: { _ in isEditingField = false }
            )
        }
        .alert("이 경기장을 삭제할까요?", isPresented: $isPresentingDeleteConfirm) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) { Task { await deleteField() } }
        } message: {
            Text("삭제한 경기장은 복구할 수 없어요.")
        }
        .alert("경기장을 삭제하지 못했어요", isPresented: $isPresentingMutationError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(mutationErrorMessage)
        }
    }

    private func deleteField() async {
        guard !isMutating else { return }
        isMutating = true
        defer { isMutating = false }
        let key = pendingDeleteKey ?? UUID()
        pendingDeleteKey = key
        do {
            try await VenueStore.archive(field, idempotencyKey: key, context: modelContext)
            pendingDeleteKey = nil
            onDeleted()
        } catch {
            presentMutationError(error, fallback: "경기장을 삭제하지 못했어요. 다시 시도해 주세요")
        }
    }

    private func presentMutationError(_ error: Error, fallback: String) {
        guard !Task.isCancelled else { return }
        if case let NetworkError.invalidHttpStatusCode(_, message) = error {
            mutationErrorMessage = message ?? fallback
        } else {
            mutationErrorMessage = fallback
        }
        isPresentingMutationError = true
    }
}

#Preview {
    NavigationStack {
        ReadyForMatchView(field: Field(
            name: "우리집앞 풋살장",
            cornerA: FieldCorner(latitude: 37.5, longitude: 127.0),
            cornerB: FieldCorner(latitude: 37.5, longitude: 127.001),
            cornerC: FieldCorner(latitude: 37.501, longitude: 127.001),
            cornerD: FieldCorner(latitude: 37.501, longitude: 127.0)
        ))
    }
}
