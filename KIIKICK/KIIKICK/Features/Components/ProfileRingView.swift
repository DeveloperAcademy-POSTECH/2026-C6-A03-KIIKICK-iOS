//
//  ProfileRingView.swift
//  KIIKICK
//
//  Figma 컴포넌트 "ProfileRing" (node 732:6891, variants "Property 1" = Default/Overdrive).
//  get_design_context로 받은 원본 에셋 그대로 가져왔다 — 트랙(ic_ring_track, #303030
//  도넛)과 진행 글로우(ic_ring_progress/ic_ring_progress_overdrive, 라디얼 그라데이션)는
//  둘 다 고정 벡터 에셋이고 점수에 따라 직접 그리는 게 아니다. 즉 이 컴포넌트는 숫자를
//  보고 꽉 채워지는 비율 게이지가 아니라, "평소(민트 글로우)"/"오버드라이브(라임 글로우,
//  풀 링)" 두 상태만 있는 뱃지에 가깝다 — Overall 100 이상이면 Overdrive로 바뀐다.
//
//  가운데 원은 Figma에서 "img_profile" 레이어(실제 유저 프로필 사진이 들어갈 자리)다.
//  TODO: 지금은 실제 유저 아바타 연동 전이라 img_profile_default 고정 이미지를 쓴다.
//  나중에 UserSession/AuthUserResponse.avatarUrl이 실제로 채워지면(비동기 이미지 로딩
//  필요) 이 자리를 그걸로 교체한다.
//

import SwiftUI

struct ProfileRingView: View {
    var isOverdrive: Bool
    var profileImage: Image = Image("img_profile_default")
    var size: CGFloat = 190

    /// Figma 기준 가운데 원 지름 비율. get_design_context가 돌려준 CSS는
    /// `aspect-[121.93/121.93] left-[11.64%] right-[11.64%]`인데, 그 aspect-ratio 숫자는
    /// 레이어의 "원래" 치수를 그대로 실어나른 것일 뿐 190 기준 절대값이 아니다 — 실제
    /// 렌더링 지름은 left/right 11.64% 인셋으로 정해진다: 190 × (1 − 2×0.1164) ≈ 145.8,
    /// 비율로는 ≈ 0.77. (121.93/190 ≈ 0.64로 잘못 계산했던 적이 있음 — 틀린 값이었다.)
    private var profileDiameter: CGFloat { size * 0.77 }

    var body: some View {
        ZStack {
            Image("ic_ring_track")
                .resizable()
                .frame(width: size, height: size)

            Image(isOverdrive ? "ic_ring_progress_overdrive" : "ic_ring_progress")
                .resizable()
                .frame(width: size, height: size)

            profileImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: profileDiameter, height: profileDiameter)
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
    }
}

#Preview("Default") {
    ProfileRingView(isOverdrive: false)
        .padding()
        .background(Color.gray950)
}

#Preview("Overdrive") {
    ProfileRingView(isOverdrive: true)
        .padding()
        .background(Color.gray950)
}

#Preview("small, Home에서 쓰는 크기") {
    ProfileRingView(isOverdrive: false, size: 116)
        .padding()
        .background(Color.gray950)
}
