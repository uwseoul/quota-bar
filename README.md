# GLM Bar 🚀

macOS 메뉴바에서 **Zhipu AI (z.ai) 코딩 플랜** 사용량을 실시간으로 모니터링하는 가볍고 강력한 앱입니다.

![App UI Sample](https://github.com/uwseoul/glm-bar/raw/main/screenshot_placeholder.png) 
*(UI 예시: iStat Menus 스타일의 2단 레이아웃)*

## ✨ 주요 특징

- **iStat Menus 스타일 UI**: 메뉴바 공간을 최적화한 2단 수직 레이아웃 (라벨/수치) 제공.
- **다중 쿼터 모니터링**: 5시간(5H), 주간(WK), 월간(MO) 사용량을 한눈에 확인.
- **다양한 표시 모드**: 백분율(%) 표시 또는 직관적인 막대 그래프(Bar) 모드 선택 가능.
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

### 2. 소스 직접 빌드
직접 빌드하고 싶은 경우 터미널에서 다음 명령어를 실행하세요:

```bash
swiftc -o glm-bar Storage.swift UsageFetcher.swift GLMBarApp.swift -framework SwiftUI -framework AppKit
./glm-bar &
```

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
