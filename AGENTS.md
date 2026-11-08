# Overview

> 개인 축구·풋살 경기 기록 앱. Apple Watch로 경기 중 위치와 심박을 기록하고, iPhone에서 히트맵과 트래킹 지표로 돌아본다.

## Platform

- **watchOS**: 경기 기록 (운동 세션, 위치, 심박)
- **iOS**: 운동장 등록, 경기 분석 (히트맵, 트래킹 지표, 구간 재생)
- Swift / SwiftUI, HealthKit, CoreLocation, MapKit

# Network

When Implementing API related functions follow rules/NETWORK.md

# Git Strategy

Follow rules/GIT.md

# Design Rules

When implementing UI from Figma, follow: rules/FIGMA.md and use design system tokens and components defined in rules/DESIGN.md

# SwiftUI Rules

When writing, modifying, or reviewing SwiftUI code under `Earthu/`, follow the `swiftui-pro` skill.

- Claude Code: `.claude/skills/swiftui-pro/SKILL.md`
- Codex: `.codex/skills/swiftui-pro/SKILL.md` (symlink to the same directory)

Load its `references/*.md` as the skill directs. Where it conflicts with rules/DESIGN.md, this project's design tokens win.