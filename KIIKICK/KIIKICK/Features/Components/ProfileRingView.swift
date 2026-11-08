//
//  ProfileRingView.swift
//  KIIKICK
//
//  Figma 컴포넌트 "ProfileRing" (node 732:6891/733:8741, variants "Property 1" =
//  Default/Overdrive). 이전엔 트랙/진행 아트웍을 그대로 이미지(ic_ring_track,
//  ic_ring_progress/_overdrive)로 받아 썼는데, 그 진행 아트웍이 점수와 무관하게 항상
//  같은 모양이라 "Overall 몇 점인지"와 링이 실제로 안 맞았다. 이제 트랙/진행 둘 다
//  네이티브 Circle().trim(...)으로 직접 그리고, 진행 비율은 score/100으로 계산한다
//  (100 이상이면 Overdrive — 풀 링 + 라임/민트 그라데이션).
//
//  치수는 기존 이미지 에셋에서 실측한 값 그대로 비율로 옮겼다: 트랙 두께는 지름의
//  20.9/190(≈11%), 가운데 프로필 원 지름은 지름의 146/190(≈0.77).
//
//  진행 링 색은 원본 SVG의 radialGradient 정의(gradientTransform scale(95), stop
//  0.8365→1 등)를 실측해보면 각도(sweep) 방향이 아니라 "링 두께 단면"을 따라 안쪽은
//  밝고 바깥쪽은 어둡게 바뀌는 방사형 그라데이션이다 — 스트로크 두께(74.1~95 반경)가
//  거의 그 페이드 구간(79.5~95 / 73.8~94.75) 안에 들어간다. 처음엔 AngularGradient로
//  구현해서 색이 호를 따라 돌면서 바뀌는 잘못된 모양이 됐었다 — RadialGradient로
//  바로잡았다.
//
//  가운데 원은 Figma에서 "img_profile" 레이어(실제 유저 프로필 사진이 들어갈 자리)다.
//  TODO: 지금은 실제 유저 아바타 연동 전이라 img_profile_default 고정 이미지를 쓴다.
//  나중에 UserSession/AuthUserResponse.avatarUrl이 실제로 채워지면(비동기 이미지 로딩
//  필요) 이 자리를 그걸로 교체한다.
//

import SwiftUI

struct ProfileRingView: View {
    var score: Int
    var profileImage: Image = Image("img_profile_default")
    var size: CGFloat = 190

    private var progress: Double {
        min(max(Double(score), 0), 100) / 100
    }

    private var isOverdrive: Bool { score >= 100 }

    private var lineWidth: CGFloat { size * (20.9 / 190) }
    private var profileDiameter: CGFloat { size * (146.0 / 190.0) }

    private var progressGradientColors: [Color] {
        isOverdrive ? [.lime500, .mint500] : [.mint500, .mint700]
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray800, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: isOverdrive ? 1 : progress)
                .stroke(
                    RadialGradient(
                        colors: progressGradientColors,
                        center: .center,
                        startRadius: (size / 2) - lineWidth,
                        endRadius: size / 2
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            profileImage
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: profileDiameter, height: profileDiameter)
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
    }
}

#Preview("45점") {
    ProfileRingView(score: 45)
        .padding()
        .background(Color.gray950)
}

#Preview("Overdrive (100+)") {
    ProfileRingView(score: 120)
        .padding()
        .background(Color.gray950)
}

#Preview("0점") {
    ProfileRingView(score: 0)
        .padding()
        .background(Color.gray950)
}

#Preview("small, Home에서 쓰는 크기") {
    ProfileRingView(score: 72, size: 116)
        .padding()
        .background(Color.gray950)
}
