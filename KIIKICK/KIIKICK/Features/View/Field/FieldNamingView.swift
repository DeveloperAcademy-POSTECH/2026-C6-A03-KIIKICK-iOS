//
//  FieldNamingView.swift
//  KIIKICK
//
//  Figma node 256:1094 "newfield_03"(경기장 이름 입력) / 563:5720 "newfield_03"(에러 상태) /
//  259:1467 "Alert"(등록 취소 확인) — iOS 화면
//
//  "selected field" 썸네일은 FieldThumbnailView(공용 컴포넌트) 참고.
//
//  이름 검증 규칙은 563:5720의 description 주석에서 가져왔다:
//  - 공백 포함 18자 이내(화면 안 "0/18" 카운터와 일치 — 본문 에러 문구 중 하나는 "20자"라고
//    적혀 있는데 이건 목업 자체의 오기로 보여 18을 기준으로 삼았다, 🟡 DESIGN-GAP)
//  - 공백만으로는 이름을 설정할 수 없음
//  - 이모지 같은 특수문자는 사용 불가(일반 특수문자는 허용된다고 주석에 명시)
//  - 저장(등록) 자체가 실패하는 경우를 위한 별도 에러 문구도 있음
//
//  저장이 끝나면 바로 onFinish()로 닫지 않고, 새로 만든 Field로 ReadyForMatchView(node
//  241:1767/544:4044 "ready")를 보여준다 — 운동장 선택이든 새로 등록이든 "경기 준비"
//  확인 화면을 거치는 건 똑같다.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct FieldNamingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 사용자가 찍은 순서 그대로의 원본 4핀. 보정된 직사각형은 이 값으로부터 계산한다.
    let rawCoordinates: [CLLocationCoordinate2D]
    let editingField: Field?
    /// 등록 자체를 취소하고 이 플로우 전체를 닫을 때(뒤로가기/등록 취소) 호출된다.
    var onFinish: () -> Void = {}
    /// 저장된 Field에서 "경기 준비" 화면의 "준비하기"를 눌렀을 때 호출된다.
    var onFieldPrepared: ((Field) -> Void)? = nil
    /// 분석 기록처럼 경기 준비 단계 없이 새 경기장을 즉시 사용할 때 호출된다.
    var onFieldSaved: ((Field) -> Void)? = nil
    var onFieldUpdated: ((Field) -> Void)? = nil

    @State private var fieldName: String
    @State private var isPresentingLeaveConfirm = false
    @State private var saveErrorMessage: String?
    @State private var savedField: Field?
    @State private var isSaving = false
    @State private var pendingCreateName: String?
    @State private var pendingCreateKey: UUID?

    init(
        rawCoordinates: [CLLocationCoordinate2D],
        editingField: Field? = nil,
        onFinish: @escaping () -> Void = {},
        onFieldPrepared: ((Field) -> Void)? = nil,
        onFieldSaved: ((Field) -> Void)? = nil,
        onFieldUpdated: ((Field) -> Void)? = nil
    ) {
        self.rawCoordinates = rawCoordinates
        self.editingField = editingField
        self.onFinish = onFinish
        self.onFieldPrepared = onFieldPrepared
        self.onFieldSaved = onFieldSaved
        self.onFieldUpdated = onFieldUpdated
        _fieldName = State(initialValue: editingField?.name ?? "")
    }

    private var trimmedName: String {
        FieldNameRules.normalized(fieldName)
    }

    private var validationErrorMessage: String? {
        if let saveErrorMessage { return saveErrorMessage }
        return FieldNameRules.validationMessage(for: fieldName)
    }

    private var textFieldState: KiikickTextFieldState {
        if validationErrorMessage != nil { return .error }
        return fieldName.isEmpty ? .default : .completed
    }

    private var canSave: Bool {
        FieldNameRules.canSave(fieldName) && !isSaving
    }

    private var correctedCoordinates: [CLLocationCoordinate2D] {
        FieldRectangleCorrector.correct(rawCorners: rawCoordinates)
    }

    var body: some View {
        VStack(spacing: 28) {
            FieldThumbnailView(coordinates: correctedCoordinates)
                .padding(.horizontal, 24)

            KiikickTextField(
                text: $fieldName,
                placeholder: "경기장 이름을 지어주세요",
                state: textFieldState,
                errorMessage: validationErrorMessage ?? "",
                maxCount: FieldNameRules.maxLength
            )
            .onChange(of: fieldName) { _, _ in saveErrorMessage = nil }
            .padding(.horizontal, 24)

            Spacer()

            CtaView(text: actionTitle, type: .primary, size: .large, isActive: canSave) {
                Task { await save() }
            }
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle(editingField == nil ? "경기장 등록" : "경기장 수정")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { handleBack() } label: { Image(systemName: "chevron.backward") }
            }
        }
        .alert(editingField == nil ? "경기장 등록을 취소할까요?" : "경기장 수정을 취소할까요?", isPresented: $isPresentingLeaveConfirm) {
            Button(editingField == nil ? "계속 등록" : "계속 수정", role: .cancel) {}
            Button(editingField == nil ? "등록 취소" : "수정 취소", role: .destructive) { onFinish() }
        } message: {
            Text("입력한 내용은 저장되지 않아요.")
        }
        .navigationDestination(item: $savedField) { field in
            ReadyForMatchView(
                field: field,
                onPrepare: { onFieldPrepared?(field) },
                onDeleted: { onFinish() }
            )
        }
        // 이 화면이 FieldListView의 시트(별도 NavigationStack) 안에 있어서
        // RootView의 전역 .dismissKeyboardOnTap()이 여기까지 안 닿는다 — 시트는
        // 제스처 전파상 독립된 뷰 트리라 따로 달아줘야 한다.
        .dismissKeyboardOnTap()
    }

    private func handleBack() {
        if canSave {
            isPresentingLeaveConfirm = true
        } else {
            dismiss()
        }
    }

    private var actionTitle: String {
        if isSaving { return editingField == nil ? "등록 중..." : "수정 중..." }
        return editingField == nil ? "등록 완료" : "수정 완료"
    }

    private func save() async {
        guard canSave, rawCoordinates.count == 4 else { return }
        isSaving = true
        defer { isSaving = false }
        let corrected = correctedCoordinates
        let correctedCorners = corrected.map { FieldCorner(latitude: $0.latitude, longitude: $0.longitude) }
        let rawCorners = rawCoordinates.map { FieldCorner(latitude: $0.latitude, longitude: $0.longitude) }
        if pendingCreateName != trimmedName {
            pendingCreateName = trimmedName
            pendingCreateKey = UUID()
        }
        guard let idempotencyKey = pendingCreateKey else { return }
        do {
            if let editingField {
                try await VenueStore.update(
                    editingField,
                    name: trimmedName,
                    correctedCorners: correctedCorners,
                    rawCorners: rawCorners,
                    idempotencyKey: idempotencyKey,
                    context: modelContext
                )
                onFieldUpdated?(editingField)
            } else {
                let field = try await VenueStore.create(
                    name: trimmedName,
                    correctedCorners: correctedCorners,
                    rawCorners: rawCorners,
                    idempotencyKey: idempotencyKey,
                    context: modelContext
                )
                if let onFieldSaved {
                    onFieldSaved(field)
                } else {
                    savedField = field
                }
            }
        } catch {
            guard !Task.isCancelled else { return }
            if case let NetworkError.invalidHttpStatusCode(_, message) = error {
                saveErrorMessage = message ?? "경기장을 등록하지 못했어요. 다시 시도해 주세요"
            } else {
                saveErrorMessage = "경기장을 등록하지 못했어요. 네트워크 연결을 확인해 주세요"
            }
        }
    }
}

#Preview {
    NavigationStack {
        FieldNamingView(rawCoordinates: [
            CLLocationCoordinate2D(latitude: 37.5, longitude: 127.0),
            CLLocationCoordinate2D(latitude: 37.5, longitude: 127.001),
            CLLocationCoordinate2D(latitude: 37.501, longitude: 127.001),
            CLLocationCoordinate2D(latitude: 37.501, longitude: 127.0),
        ])
    }
}
