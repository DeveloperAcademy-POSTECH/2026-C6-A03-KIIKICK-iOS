# 검색·알림 조회 비용 개선

## 변경

- #44: 알림을 ID → 행 모델 Dictionary로 보관하고 날짜·필터별 섹션을 데이터 교체 때 계산한다. 상태 변경은 평균 O(1) ID 조회 뒤 해당 행 모델만 갱신하며 섹션을 다시 정렬하지 않는다. 데이터 교체 시 인덱스와 섹션을 함께 갱신한다. 앱 활성화·시간대 변경·날짜 변경에는 섹션을 다시 구성한다. 섹션 ID는 날짜이며 '오늘' 같은 표시 문자열을 식별자로 쓰지 않는다.
- #45: 친구 검색은 `.task(id:)`에 검색어와 사용자 목록을 함께 연결한다. 200ms debounce 중 취소된 검색은 결과를 게시하지 않는다. 검색 결과를 모델에 저장하므로 화면의 count·empty·ForEach마다 목록을 다시 필터링하지 않는다. 사용자 입력 부분 검색에는 `localizedStandardContains`를 사용한다.

현재 화면은 목업 데이터를 사용한다. 서버 연동(#35), 알림 칩 순서 정책(#38)은 별도다. 부분 문자열 검색은 여전히 O(N)이고 결과 표시도 결과 수에 비례한다. 알림 섹션 전체 교체는 정렬 O(N log N)이며 메모리를 추가로 사용한다. 최초 계산을 피하려고 뷰 initializer에서 데이터를 가공하지 않는다.

## 검증

`scripts/test-query-models.sh`는 실제 Domain 소스를 Swift 6으로 컴파일하고 실행한다. 별도 XCTest 타깃이 없는 저장소에서 모델 변경을 검증하기 위한 테스트다. 날짜 정렬·필터·개별 ID 상태 변경·삭제 후 이전 ID 갱신·데이터 교체·시간대 변경·빈 검색·대소문자 및 한글 부분 검색·검색 취소·사용자 목록 변경을 확인한다.

iPhone 소스 전체는 iOS Simulator SDK, arm64 iOS 18.6 대상, 프로젝트와 같은 Swift 5 모드 및 MainActor 기본 격리로 `swiftc -typecheck`를 통과했다. Xcode가 생성한 GeneratedAssetSymbols.swift를 함께 전달하여 asset color/image 심볼을 사용했다. 기존 SwiftData/FieldCorner 격리 관련 경고는 이 변경 범위에서 수정하지 않았다.

전체 scheme 빌드는 성공하지 않았다. 누락된 gitignored Config.xcconfig는 제공된 example을 복사해 검증 환경에만 준비했다. 그 뒤 기존 Watch AppIcon 콘텐츠 오류가 발생했고, 진단용 `ASSETCATALOG_COMPILER_APPICON_NAME=` 옵션으로 해당 단계를 제외하면 공유 SessionManager.swift가 Watch 타깃에서 WorkoutRecord를 찾지 못하는 기존 컴파일 오류가 발생했다. 관련 프로젝트/Watch 파일은 이 PR에서 수정하지 않았다. 따라서 실제 앱 실행·UI 동작·전체 앱 빌드 성공을 주장하지 않으며 PR은 draft로 등록한다.

원격에 develop 브랜치가 없어 실제 기본 브랜치 main에서 작업하고 main을 PR 대상으로 사용한다. 기존 작업 공간의 개인정보 문서 변경은 포함하지 않는다.
