[English Version (README.md)](./README.md)

# Quota Bar 🚀

macOS 메뉴 바에서 **AI 코딩 플랜 사용량**을 여러 플랫폼에서 실시간으로 모니터링하는 가볍고 강력한 앱입니다.

**기존 GLM Bar의 새로운 이름** — 이제 4개 플랫폼을 지원합니다!

![App UI Sample](https://github.com/uwseoul/quota-bar/raw/main/screenshot_placeholder.png) 
*(UI 예시: 멀티 플랫폼 카드 레이아웃)*

## ✨ 주요 특징

- **멀티 플랫폼 지원**: **GLM (z.ai)**, **MiniMax**, **OpenAI Codex**, **OpenCode Go** — 한 앱에서 모두 모니터링.
- **iStat Menus 스타일 UI**: 메뉴 바 공간을 최적화한 수직 레이아웃.
- **다중 쿼터 모니터링**: 5시간(5H), 주간(WK), 월간(MO), 롤링, 7D 등 다양한 쿼터 지원.
- **3가지 표시 모드**:
  - **백분율(%)**: 사용량 퍼센트 표시
  - **막대 그래프(Bar)**: 시각적 막대 그래프
  - **속도 신호등(Signal)**: 사용 속도를 신호등으로 표시 (녹/노/빨)
- **4가지 메뉴 바 모드**:
  - **Highest Usage**: 전체 플랫폼 중 사용률이 가장 높은 쿼터 하나
  - **First Quota per Platform**: 각 플랫폼의 첫 번째 쿼터
  - **One per Platform**: 각 플랫폼에서 사용률이 가장 높은 쿼터
  - **Manual Select**: 메뉴 바에 표시할 쿼터를 직접 체크박스로 선택
- **속도 기반 색상 표시**:
  - 🔴 빨강 (Fast): 사용 속도가 빠름 — 할당량 초과 위험
  - 🟡 노랑 (Normal): 적당한 사용 속도
  - 🟢 초록 (Slow): 여유 있는 사용 속도 — 안전
- **다크 모드 지원**: 다크/라이트 메뉴 바 모두에서 흰색 글자로 선명하게 표시
- **카드 스타일 팝오버**: 플랫폼별로 깔끔하게 구분된 카드 UI
- **오른쪽 클릭 설정**: 메뉴 바 아이콘 오른쪽 클릭으로 설정 바로 열기
- **보안 중심**: API Key는 소스 코드에 저장되지 않으며, 맥의 `UserDefaults`를 통해 로컬에만 안전하게 보관됩니다.
- **자동 실행 지원**: 시스템 재부팅 후에도 자동으로 실행되도록 설정 가능.
- **낮은 리소스 점유**: Native Swift/SwiftUI로 제작되어 CPU 및 메모리 사용량이 극히 낮습니다.

## 🛠 설치 및 실행 방법

### 1. 앱 다운로드 (권장) - `.app` 번들
가장 쉬운 방법입니다. 일반 macOS 앱처럼 작동합니다.
1. [Releases](https://github.com/uwseoul/quota-bar/releases) 페이지에서 `QuotaBar.zip`을 다운로드합니다.
2. ZIP을 풀고 `QuotaBar.app`을 **응용 프로그램** 폴더로 이동합니다.
3. 앱을 실행합니다. ("신뢰할 수 없는 개발자" 경고가 나오면 앱을 우클릭해서 '열기'를 선택하세요.)

### 2. 터미널 바이너리 다운로드
1. Releases 페이지에서 `quota-bar-macos.tar.gz`를 다운로드합니다.
2. 터미널에서 실행: `chmod +x quota-bar && ./quota-bar &`

### 3. 소스에서 빌드
직접 빌드하려면 터미널에서 다음을 실행하세요:

```bash
swiftc QuotaBarApp.swift Models/Storage.swift Services/UsageFetcher.swift Services/GLMFetcher.swift Services/MiniMaxFetcher.swift Services/CodexFetcher.swift Services/OpenCodeGoFetcher.swift Views/ContentView.swift Views/SettingsView.swift Views/MenuBarRenderer.swift -o QuotaBar
```

또는 빌드 스크립트 사용:
```bash
./scripts/build-universal.sh
```

**Intel 및 Apple Silicon 맥 모두 지원하는 유니버셜 바이너리**가 생성됩니다.

**요구사항:** macOS 11.0 (Big Sur) 이상

## ⚙️ 플랫폼 설정

### GLM (z.ai / bigmodel.cn)
1. 팝업에서 Settings를 엽니다.
2. **Z.ai API Key**를 입력합니다.
3. 플랫폼을 선택합니다 (`z.ai` 또는 `bigmodel.cn`).

### MiniMax TokenPlan
1. Settings → Platforms에서 MiniMax를 켭니다.
2. **MiniMax Token Plan API Key**를 입력합니다 (`sk-cp-...` 형식).

### OpenAI Codex
1. Settings → Platforms에서 Codex를 켭니다.
2. 터미널에서 `codex login`을 실행했는지 확인하세요.
3. 앱이 `~/.codex/auth.json`을 자동으로 읽습니다 — 수동 키 입력 불필요.

### OpenCode Go
1. Settings → Platforms에서 OpenCode Go를 켭니다.
2. **Workspace ID**를 입력합니다 (URL: `https://opencode.ai/workspace/{id}/go`).
3. **Auth Cookie** 값을 입력합니다 (브라우저 개발자 도구 → Application → Cookies → `auth`).
4. "연결 방법 보기" 버튼을 누륩면 상세 설명을 볼 수 있습니다.

## 🔄 업데이트

앱 낭부에서 GitHub 최신 릴리즈를 확인할 수 있습니다.

- 수동 확인: 팝업 열기 → `Check for Updates...`
- 새 버전이 있으면 GitHub Releases 페이지가 자동으로 열립니다.

## 📝 기술 스택
- **언어**: Swift
- **프레임워크**: SwiftUI, AppKit (CoreGraphics 렌더링)
- **빌드**: 순수 `swiftc` (Xcode 프로젝트 없음, SPM 없음)
- **상태**: 활발한 개발 중

## 📄 라이선스
MIT License

---
*AI 코딩 플랜 사용자들을 위해 ❤️을 담아 제작*
