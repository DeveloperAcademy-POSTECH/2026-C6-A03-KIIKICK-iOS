//
//  FieldListView.swift
//  KIIKICK
//
//  Figma node 241:1752 "myfiled"(목록 있음) / 542:3727 "myfiled"(빈 상태) / 241:1793
//  "myfield-scroll"(스크롤) — "내 경기장" 화면.
//
//  DESIGN-GAP: 상단 "tool bar"(뒤로가기 + 중앙 타이틀)는 시스템 네비게이션 바가 아니라
//  HomeView 헤더와 같은 방식의 커스텀 HStack이다 — 뒤로가기 버튼이 유리질감 원형
//  배경(glassCircleBackground, HomeView의 +/알림 버튼과 동일 컴포넌트)을 쓰기 때문에
//  시스템 toolbar 대신 직접 그렸다.
//
//  DESIGN-GAP: "새 경기장 등록하기" CTA는 Figma에서 배경 color-background-secondary
//  (gray900) + label1_m(16pt Medium) 조합인데, 기존 CtaView.secondary는 gray850 +
//  title2SB(18pt SemiBold)를 쓴다 — 화면 하나만을 위한 별도 변형을 새로 만들기보다
//  기존 secondary 변형을 그대로 재사용했다.
//
//  운동장을 고르거나(기존 목록) 새로 등록하거나(FieldCreationView 시트) 둘 다
//  ReadyForMatchView("경기 준비" 확인 화면, node 241:1767/544:4044)로 모인다 — 거기서
//  "준비하기"를 눌러야만 onFieldPrepared가 실제로 호출된다.
//

import SwiftUI
import SwiftData

struct FieldListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    // `isArchived` 조건을 SwiftData predicate로 넣으면, 비어 있는 저장소에서도
    // `@Query`가 계속 재평가되어 화면 렌더링 루프에 빠진다. 정렬만 SwiftData에
    // 맡기고, 보관 항목은 표시 직전에 제외한다.
    @Query(sort: \Field.name) private var fields: [Field]
    @State private var isPresentingRegistration = false
    @State private var selectedField: Field?
    @State private var isSynchronizing = false
    @State private var synchronizationError: String?
    var onFieldPrepared: ((Field) -> Void)? = nil
    /// 분석 준비 중 기존 기록에 운동장을 연결할 때는 경기 준비 화면을 거치지 않는다.
    var onFieldSelected: ((Field) -> Void)? = nil

    var body: some View {
        let activeFields = fields.filter { !$0.isArchived }

        ScrollView {
            VStack(spacing: 16) {
                CtaView(
                    text: "새 경기장 등록하기",
                    type: .secondary,
                    size: .large,
                    isActive: !isSynchronizing
                ) {
                    isPresentingRegistration = true
                }

                if isSynchronizing && activeFields.isEmpty {
                    ProgressView("경기장을 불러오는 중...")
                        .tint(.mint500)
                        .foregroundStyle(.gray300)
                        .padding(.top, 32)
                } else if let synchronizationError {
                    synchronizationErrorView(synchronizationError)
                }

                if activeFields.isEmpty && !isSynchronizing {
                    emptyState
                        .padding(.top, 48)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(activeFields) { field in
                            fieldRow(field)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .applyingSoftTopScrollEdgeEffect()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            header
        }
        .task { await synchronizeFields() }
        .refreshable { await synchronizeFields() }
        .navigationDestination(item: $selectedField) { field in
            ReadyForMatchView(
                field: field,
                onPrepare: { onFieldPrepared?(field) },
                onDeleted: { selectedField = nil }
            )
        }
        .sheet(isPresented: $isPresentingRegistration) {
            NavigationStack {
                FieldCreationView(
                    onFinish: { isPresentingRegistration = false },
                    onFieldPrepared: { field in
                        isPresentingRegistration = false
                        onFieldPrepared?(field)
                    },
                    onFieldSaved: directFieldSaveHandler
                )
            }
        }
    }

    private func fieldRow(_ field: Field) -> some View {
        Button {
            if let onFieldSelected {
                onFieldSelected(field)
                dismiss()
            } else {
                selectedField = field
            }
        } label: {
            NaviRowView(text: field.name, textStyle: .title3M)
        }
        .buttonStyle(.plain)
        .disabled(isSynchronizing)
    }

    private var directFieldSaveHandler: ((Field) -> Void)? {
        guard let onFieldSelected else { return nil }
        return { field in
            isPresentingRegistration = false
            onFieldSelected(field)
        }
    }

    private func synchronizationErrorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.body4R)
                .foregroundStyle(.gray300)
                .multilineTextAlignment(.center)
            Button("다시 불러오기") { Task { await synchronizeFields() } }
                .font(.label4SB)
                .foregroundStyle(.mint500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("아직 등록한 경기장이 없어요")
                .font(.title4SB)
            Text("내 움직임을 경기장에 정확히 표시하려면\n경기장 등록이 필요해요")
                .font(.body4R)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.gray50)
        .frame(maxWidth: .infinity)
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.backward")
                    .foregroundStyle(.gray50)
                    .frame(width: 44, height: 44)
                    .glassCircleBackground()
            }
            .buttonStyle(.plain)

            Spacer()

            Text("내 경기장")
                .font(.head3B)
                .foregroundStyle(.colorTextPrimary)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(Color.gray950)
    }

    private func synchronizeFields() async {
        guard UserSession.token != nil, !isSynchronizing else { return }
        isSynchronizing = true
        synchronizationError = nil
        defer { isSynchronizing = false }
        do {
            try await VenueStore.synchronize(context: modelContext)
        } catch {
            guard !Task.isCancelled else { return }
            synchronizationError = "경기장 목록을 동기화하지 못했어요.\n로컬 경기장은 그대로 사용할 수 있어요."
        }
    }
}

private extension View {
    /// `scrollEdgeEffectStyle`는 iOS 26부터 있는데 프로젝트 배포 타깃은 18.6이라 가드한다.
    @ViewBuilder
    func applyingSoftTopScrollEdgeEffect() -> some View {
        if #available(iOS 26.0, *) {
            scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self
        }
    }
}

#Preview("목록 있음") {
    NavigationStack {
        FieldListView(onFieldPrepared: { _ in })
    }
}
