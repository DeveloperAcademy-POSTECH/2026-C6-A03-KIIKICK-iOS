# Overview

> 개인 축구·풋살 경기 기록 앱. Apple Watch로 경기 중 위치와 심박을 기록하고, iPhone에서 히트맵과 트래킹 지표로 돌아본다.

## Platform

- **watchOS**: 경기 기록 (운동 세션, 위치, 심박)
- **iOS**: 운동장 등록, 경기 분석 (히트맵, 트래킹 지표, 구간 재생)
- Swift / SwiftUI, HealthKit, CoreLocation, MapKit

## 1차 기능

### 1. 워치 기록 (HealthKit)

- 워치에서 축구 운동 세션(`HKWorkoutSession`, 축구 activity type)을 시작·종료한다.
- 경기 중 GPS 위치 샘플과 심박수를 수집하고, 운동 기록은 HealthKit에 저장한다.
- 위치 경로는 워크아웃 루트로 함께 저장해 iPhone에서 다시 읽을 수 있게 한다.

### 2. 축구 트래킹 데이터

- 위치·심박 샘플로부터 경기 지표를 계산한다.
  - **스프린트**: 일정 속도 이상으로 일정 시간 이상 유지된 구간. 횟수, 최고 속도, 스프린트 거리 등.
  - **심박수 구간**: 구간별(Zone) 머문 시간과 비율.
  - 총 이동 거리, 평균·최고 속도 등 기본 지표.
- 스프린트 판정 기준 속도·시간, 심박 구간 경계는 **아직 확정되지 않았다.** 하드코딩하지 말고 한곳에 모은 상수/설정으로 두어 나중에 바꾸기 쉽게 한다.

### 3. 히트맵

- 경기 중 위치를 운동장 좌표계로 변환해 히트맵으로 보여준다.
- 보간(interpolation), 스무딩, 셀 크기 등 세부 렌더링 방식은 **추후 결정**. 지금은 렌더링 로직을 교체 가능한 구조로 두고, 세부 알고리즘을 임의로 확정하지 않는다.

### 4. 운동장 생성

- 지도(MapKit)에서 운동장의 네 모서리를 **핀 4개**로 찍어 운동장을 등록한다.
- 등록한 운동장은 이름과 함께 저장해 다음 경기에서 다시 선택할 수 있다.
- 네 점은 직사각형이 아닐 수 있으므로(핀 오차, 실제 구장 형태), GPS 좌표 → 운동장 정규화 좌표(예: 가로·세로 0~1) 변환은 사각형 기준의 투영 변환으로 처리한다.
- 핀 순서(어느 모서리가 첫 번째인지)와 터치라인·골라인 방향은 일관된 규칙으로 정의하고 저장한다.

### 5. 공격 방향 설정

- 쿼터제 또는 전후반제에 따라 기간(period)마다 공격 방향이 바뀔 수 있다.
- 사용자에게 각 기간의 공격 방향을 묻고, 기간별로 저장한다.
- 히트맵과 분석 화면은 공격 방향을 기준으로 정규화해 **모든 기간이 같은 방향으로 공격하는 것처럼** 보이게 한다 (예: 항상 왼쪽 → 오른쪽).
- 경기 형식(쿼터 / 전후반)과 각 기간의 시작·종료 시점도 함께 기록해야 기간별 방향 보정이 가능하다.

### 6. 구간 재생 (타임라인 슬라이더)

- 화면 하단에 영상 플레이어처럼 경기 타임라인 슬라이더를 둔다.
- 슬라이더 위치를 시작점으로 **고정 길이 구간(기본 10초)** 의 위치만 히트맵으로 보여준다.
- 슬라이더를 움직이면 구간이 따라 이동해, 경기 중 어떤 방식으로 움직였는지 흐름으로 확인할 수 있다.
- 구간 길이는 설정값으로 둔다. 스크러빙 중 끊김이 없도록 시간 기준 필터링이 빨라야 한다 (샘플을 시간순으로 정렬해 두고 범위 탐색).

# Git Strategy

Follow rules/GIT.md

# Design Rules

When implementing UI from Figma, follow: rules/FIGMA.md and use design system tokens and components defined in rules/DESIGN.md

# SwiftUI Rules

When writing, modifying, or reviewing SwiftUI code under `Earthu/`, follow the `swiftui-pro` skill.

- Claude Code: `.claude/skills/swiftui-pro/SKILL.md`
- Codex: `.codex/skills/swiftui-pro/SKILL.md` (symlink to the same directory)

Load its `references/*.md` as the skill directs. Where it conflicts with rules/DESIGN.md, this project's design tokens win.