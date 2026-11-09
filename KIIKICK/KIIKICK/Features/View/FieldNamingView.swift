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
    /// 등록 자체를 취소하고 이 플로우 전체를 닫을 때(뒤로가기/등록 취소) 호출된다.
    var onFinish: () -> Void = {}
    /// 저장된 Field에서 "경기 준비" 화면의 "준비하기"를 눌렀을 때 호출된다.
    var onFieldPrepared: ((Field) -> Void)? = nil

    @State private var fieldName: String = ""
    @State private var isPresentingLeaveConfirm = false
    @State private var saveErrorMessage: String?
    @State private var savedField: Field?

    private static let maxNameLength = 18

    private var trimmedName: String {
        fieldName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 이모지만 막는다 — 일반 특수문자는 Figma 주석에 "사용 가능"이라고 명시돼 있다.
    private var containsDisallowedCharacter: Bool {
        fieldName.contains { $0.isKiikickFieldNameDisallowed }
    }

    private var validationErrorMessage: String? {
        if let saveErrorMessage { return saveErrorMessage }
        if fieldName.count > Self.maxNameLength { return "경기장 이름은 최대 \(Self.maxNameLength)자까지 입력할 수 있어요" }
        if !fieldName.isEmpty && trimmedName.isEmpty { return "공백만으로는 이름을 설정할 수 없어요" }
        if containsDisallowedCharacter { return "사용할 수 없는 문자가 포함되어 있어요" }
        return nil
    }

    private var textFieldState: KiikickTextFieldState {
        if validationErrorMessage != nil { return .error }
        return fieldName.isEmpty ? .default : .completed
    }

    private var canSave: Bool {
        !trimmedName.isEmpty
            && fieldName.count <= Self.maxNameLength
            && !containsDisallowedCharacter
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
                maxCount: Self.maxNameLength
            )
            .onChange(of: fieldName) { _, _ in saveErrorMessage = nil }
            .padding(.horizontal, 24)

            Spacer()

            CtaView(text: "등록 완료", type: .primary, size: .large, isActive: canSave) {
                save()
            }
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.gray950)
        .navigationTitle("경기장 등록")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { handleBack() } label: { Image(systemName: "chevron.backward") }
            }
        }
        .alert("경기장 등록을 취소할까요?", isPresented: $isPresentingLeaveConfirm) {
            Button("계속 등록", role: .cancel) {}
            Button("등록 취소", role: .destructive) { onFinish() }
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
    }

    private func handleBack() {
        if canSave {
            isPresentingLeaveConfirm = true
        } else {
            dismiss()
        }
    }

    private func save() {
        guard canSave, rawCoordinates.count == 4 else { return }
        let corrected = correctedCoordinates
        let field = Field(
            name: trimmedName,
            cornerA: FieldCorner(latitude: corrected[0].latitude, longitude: corrected[0].longitude),
            cornerB: FieldCorner(latitude: corrected[1].latitude, longitude: corrected[1].longitude),
            cornerC: FieldCorner(latitude: corrected[2].latitude, longitude: corrected[2].longitude),
            cornerD: FieldCorner(latitude: corrected[3].latitude, longitude: corrected[3].longitude),
            rawCornerA: FieldCorner(latitude: rawCoordinates[0].latitude, longitude: rawCoordinates[0].longitude),
            rawCornerB: FieldCorner(latitude: rawCoordinates[1].latitude, longitude: rawCoordinates[1].longitude),
            rawCornerC: FieldCorner(latitude: rawCoordinates[2].latitude, longitude: rawCoordinates[2].longitude),
            rawCornerD: FieldCorner(latitude: rawCoordinates[3].latitude, longitude: rawCoordinates[3].longitude)
        )
        modelContext.insert(field)
        do {
            try modelContext.save()
            savedField = field
        } catch {
            modelContext.delete(field)
            saveErrorMessage = "경기장을 등록하지 못했어요. 다시 시도해 주세요"
        }
    }
}

private extension Character {
    /// 이모지(실제로 그려지는 것들)만 걸러낸다 — 숫자/# 같은 "isEmoji=true"지만 평소엔
    /// 일반 글자로 보이는 스칼라까지 막으면 과하다.
    var isKiikickFieldNameDisallowed: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmojiPresentation || (scalar.properties.isEmoji && scalar.value > 0x238C)
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
