[English Version (README.md)](./README.md)

# GLM Bar 🚀

macOS 메뉴바에서 **Zhipu AI (z.ai) 코딩 플랜** 사용량을 실시간으로 모니터링하는 가볍고 강력한 앱입니다.

![App UI Sample](https://github.com/uwseoul/glm-bar/raw/main/screenshot_placeholder.png) 
*(UI 예시: iStat Menus 스타일의 2단 레이아웃)*

## ✨ 주요 특징

 - **iStat Menus 스타일 UI**: 메뉴바 공간을 최적화한 2단 수직 레이아웃 (라벨/수치) 제공.
- **다중 쿼터 모니터링**: 5시간(5H), 주간(WK), 월간(MO) 사용량을 한눈에 확인.
- **3가지 표시 모드**:
  - **백분율(%)**: 사용량 퍼센트 표시
  - **막대 그래프(Bar)**: 시각적 막대 그래프
  - **사용 속도(Rate)**: 남은 시간 대비 사용 속도 표시 (빠름/보통/느림)
- **속도 기반 색상 표시**:
  - 🔴 빠름 (FAST): 사용 속도가 빠름 - 할당량 초과 위험
  - 🔵 보통 (OK): 적당한 사용 속도
  - 🟢 느림 (SLOW): 여유 있는 사용 속도 - 안전
- **다크 모드 지원**: 자동/라이트/다크 모드 선택 가능
- **Z.ai 공식 로고**: 공식 로고 사용
- **릴리즈 확인 바로가기**: 앱 내부에서 최신 GitHub 릴리즈를 확인하고, 새 버전이 있으면 다운로드 페이지를 바로 열 수 있습니다.
- **보안 중심**: API Key는 소스 코드에 저장되지 않으며, 맥의 `UserDefaults`를 통해 로컬에만 안전하게 보관됩니다.
- **자동 실행 지원**: 시스템 재부팅 후에도 자동으로 실행되도록 설정 가능.
- **낮은 리소스 점유**: Native Swift/SwiftUI로 제작되어 CPU 및 메모리 사용량이 극히 낮습니다.

## 🛠 설치 및 실행 방법

### 1. 앱 다운로드 (권장) - `.app` 형태
가장 편리한 방법입니다. 일반적인 macOS 앱처럼 동작합니다.
1. [Releases](https://github.com/uwseoul/glm-bar/releases) 페이지에서 `GLMBar.zip` 파일을 다운로드합니다.
2. 압축을 푼 후 `GLMBar.app` 파일을 **응용 프로그램(Applications)** 폴더로 옮깁니다.
3. 앱을 실행합니다. (최초 실행 시 '확인되지 않은 개발자' 메시지가 뜨면 우클릭 후 '열기'를 선택해 주세요.)

### 2. 터미널용 바이너리 다운로드
1. 릴리즈 페이지에서 `glm-bar-macos.tar.gz` 파일을 다운로드합니다.
2. 압축 해제 후 터미널에서 실행합니다: `chmod +x glm-bar && ./glm-bar &`

앱 번들과 터미널 바이너리 모두 최신 릴리즈를 직접 내려받아 업데이트하는 방식입니다.

### 3. 소스 직접 빌드
직접 빌드하고 싶은 경우 터미널에서 다음 명령어를 실행하세요:

```bash
./scripts/build-universal.sh
```

이 스크립트는 **유니버설 바이너리**를 생성합니다 (Intel 및 Apple Silicon Mac 모두 지원):
- `dist/glm-bar` - 터미널용 바이너리
- `dist/GLMBar.app` - 앱 번들
- `dist/glm-bar-macos.tar.gz` - 릴리즈 아카이브 (터미널용)
- `dist/GLMBar.zip` - 릴리즈 아카이브 (앱 번들)

### 4. 릴리즈 빌드 참고사항 (로컬 + CI)
릴리즈 빌드 전에 아래 스크립트를 실행하세요:

```bash
./scripts/check-release-prereqs.sh
```

필수 환경 변수:
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_TEAM_ID`

이 자격 증명은 로컬 빌드 자체에는 필수가 아니지만, 릴리즈 패키징에서 notarization까지 수행하려면 필요합니다.

릴리즈 빌드는 버전 입력값도 하나의 소스에서 명시적으로 받아야 합니다:

```bash
RELEASE_BUILD=1 RELEASE_VERSION=1.2.3 RELEASE_BUILD_NUMBER=123 ./scripts/build-universal.sh
```

노타리제이션 프로파일 계약 이름: `glmbar-notary` (필요할 때만 `NOTARY_PROFILE_NAME`으로 변경).

**요구사항:** macOS 11.0 (Big Sur) 이상

터미널용 바이너리 실행:
```bash
./dist/glm-bar &
```

앱 번들 설치:
```bash
cp -r dist/GLMBar.app /Applications/
```

## 🔄 업데이트 방식

앱 팝업 안에서 최신 GitHub 릴리즈를 확인할 수 있습니다.

- 수동 확인: 앱 팝업 열기 -> `Check for Updates...`
- 새 버전이 있으면 GitHub Releases 페이지를 엽니다
- 업데이트 설치는 최신 `GLMBar.zip` 또는 `glm-bar-macos.tar.gz`를 직접 내려받아 진행합니다

현재는 Sparkle 피드 기반의 인플레이스 자동 업데이트는 지원하지 않습니다.

## ⚙️ 설정 방법
1. 메뉴바 아이콘을 클릭하여 팝업 창을 엽니다.
2. 하단의 **Settings...** 버튼을 누릅니다.
3. 자신의 **Z.ai API Key**를 입력하고 플랫폼(`z.ai` 또는 `bigmodel.cn`)을 선택합니다.
4. 원하는 표시 스타일과 쿼터 항목을 체크합니다.

## 📝 기술 스택
- **Language**: Swift
- **Framework**: SwiftUI, AppKit (CoreGraphics rendering)
- **Status**: Active Development

## 📄 라이선스
MIT License

---
*Created with ❤️ for GLM Coding Plan users.*
