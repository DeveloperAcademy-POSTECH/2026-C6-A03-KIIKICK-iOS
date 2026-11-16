# 경기 목업 데이터

실제 손흥민·이강인·김민재의 경기 기록을 공개 원시 좌표로 확보하기는 어렵기 때문에, 개발 화면과 히트맵 로직 검증에는 `scripts/generate_mock_match_data.py`를 사용한다.

생성 데이터는 실제 선수 기록이 아니다. 선수 이름은 활동 영역 프로필을 구분하기 위한 라벨이며, 다음 특성을 반영한다.

- 손흥민 프로필: 전방·측면 체류 비중과 고속 주행을 높임
- 이강인 프로필: 중앙·우측 하프스페이스를 오가는 플레이메이커형 분포
- 김민재 프로필: 자기 진영 중앙에 밀집하고 이동 폭을 낮춤
- 위치는 105×68m 경기장의 미터 좌표와 `0...1` 정규화 좌표를 함께 제공
- 속도와 심박은 위치 변화량과 쿼터 경과 시간에 따라 결정적으로 생성
- 같은 `--seed`를 사용하면 같은 결과가 재생성됨

## 실행

전체 선수, 4쿼터, 5초 간격 데이터를 파일로 만든다.

```bash
python3 scripts/generate_mock_match_data.py \
  --seed 102 \
  --output /tmp/kiikick-mock-match.json
```

화면 개발용으로 데이터 크기를 줄일 수 있다.

```bash
python3 scripts/generate_mock_match_data.py \
  --players son-heung-min lee-kang-in \
  --quarters 2 \
  --quarter-seconds 300 \
  --seconds-per-point 10 \
  --output /tmp/kiikick-mock-preview.json
```

## 좌표 사용

히트맵은 `points[].x`, `points[].y`를 사용한다. 원본 GPS 경로가 필요한 화면으로 연결할 때는 `xMeters`, `yMeters`를 등록된 `Field`의 네 꼭짓점에 역변환하면 된다. 현재 프로젝트의 `FieldCoordinateMapper`는 GPS → 정규화 좌표를 담당하므로, 목업을 로컬 `WorkoutRecord`에 주입하는 경우에는 정규화 좌표에서 GPS를 만드는 정방향 변환을 별도로 두는 편이 안전하다.

목업을 실제 데이터로 교체할 때에는 `source`와 `disclaimer`를 제거하거나 실제 제공자의 이용 조건·출처 표기로 교체해야 한다.

## iOS 임시 검증 화면

Debug 빌드에서는 `RootView`가 인증·메인 탭 대신 `MockHeatmapRootView`를 바로 표시한다.

- 진입 즉시 손흥민·이강인·김민재 스타일의 목업 경기 3개를 생성한다.
- 목록에서 각 히트맵을 한 번에 비교할 수 있다.
- 항목을 누르면 쿼터별 히트맵을 확인할 수 있다.
- `기존 타임라인 보기`를 누르면 앱의 기존 `TimelineView`로 이동해 재생 슬라이더와 통계를 확인할 수 있다.
- 상단 `저장`은 현재 생성 데이터를 앱 Documents 디렉터리의 `mock-heatmap-{seed}.json`으로 저장한다.
- `다시 만들기`는 seed를 1 증가시켜 다른 경로를 재생성한다.

Release 빌드에는 이 임시 Root 분기가 포함되지 않고 기존 인증 흐름을 사용한다.
