# 2026-C6-A03-KIIKICK-iOS
Asher, Gonn, Phoebe, Rudy

## 로컬 빌드 설정

`KIIKICK/Config.xcconfig.example`을 `KIIKICK/Config.xcconfig`로 복사하고 API 주소를 설정합니다.
개인 기기에서 빌드할 때는 이 파일에 `KIIKICK_DEVELOPMENT_TEAM`과 `KIIKICK_BUNDLE_IDENTIFIER`를 추가합니다.
iOS·Watch의 Debug·Release가 같은 설정을 읽고 Watch의 연결 ID도 자동으로 맞춥니다.

`Config.xcconfig`는 Git에서 제외되므로 `main` 최신화 시 개인 값이 덮어써지지 않습니다.
Xcode의 Signing 화면에서 Team·Bundle Identifier를 직접 바꾸면 프로젝트에 고정값이 다시 생기므로 개인 값은 이 파일에서만 수정합니다.
이 설정 연결을 포함한 프로젝트 변경이 `main`에 반영되어 있어야 새 브랜치에서도 그대로 적용됩니다.
