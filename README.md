# Virtual Face Cam Mac

OBS, pyvirtualcam 없이 **앱 자체만으로 macOS 카메라 목록에 나타나는 가상 웹캠**을
만드는 네이티브 macOS 프로젝트입니다.

목표는 Zoom, Teams, Chrome, FaceTime 같은 앱의 카메라 선택 목록에서
`Virtual Face Cam`을 직접 선택하게 만드는 것입니다.

## 현재 구현된 것

- SwiftUI host app
- CoreMediaIO Camera Extension
- Host app에서 이미지 선택
- App Group 공유 폴더에 이미지와 설정 저장
- Camera Extension이 이미지를 읽어서 `CVPixelBuffer` 프레임 생성
- `CMIOExtensionStream`으로 1280x720 30fps 프레임 송출
- 이미지가 없을 때 placeholder 프레임 송출
- Xcode 프로젝트 생성 및 unsigned Debug build 검증

## 중요한 현실 제약

macOS에서 진짜 카메라 장치로 보이려면 **Camera Extension은 반드시 서명된 System Extension**이어야 합니다.

그래서 이 프로젝트는 일반 Python 앱처럼 더블클릭만으로 끝나는 구조가 아닙니다. 최초 설치에는 아래가 필요합니다.

- Xcode
- Paid Apple Developer Program team. Xcode의 무료 `Personal Team`은 System Extension 권한을 지원하지 않습니다.
- App Group 등록
- macOS System Extension 승인

OBS 같은 외부 가상 카메라 앱은 필요 없지만, Apple 보안 정책 때문에 시스템 확장 승인과 서명은 필요합니다.

## 초보자용 사용 목표

완성된 signed 앱 기준 사용 흐름은 아래와 같습니다.

1. `Virtual Face Cam.app`을 엽니다.
2. **Install / Refresh Camera**를 누릅니다.
3. macOS가 시스템 확장을 허용하라고 하면 승인합니다.
4. 앱에서 이미지 파일을 선택합니다.
5. Zoom, Teams, Chrome에서 카메라를 `Virtual Face Cam`으로 선택합니다.
6. 선택한 이미지가 웹캠 화면처럼 나옵니다.

## 개발자가 지금 실행하는 방법

먼저 Xcode 버전을 확인합니다.

```bash
xcodebuild -version
```

macOS Sequoia에서는 Xcode 15.x가 GUI에서 막힐 수 있습니다. 이 프로젝트는 Xcode 26.3에서
unsigned build를 확인했습니다.

### 1. Xcode 열기

```bash
open native/VirtualFaceCamMac.xcodeproj
```

또는 프로젝트를 다시 생성하고 열려면:

```bash
./scripts/open_project.sh
```

`open_project.sh`는 `xcodegen`이 필요합니다.

```bash
brew install xcodegen
```

### 2. Team 설정

Xcode에서 아래 두 target 모두 본인 Apple Developer Team을 선택하세요.

- `VirtualFaceCam`
- `VirtualFaceCamCameraExtension`

App Group도 등록해야 합니다.

```text
group.com.taehui.virtualfacecam
```

주의: Xcode가 `Personal Team`으로 표시하는 무료 팀은 이 프로젝트를 실제 카메라로 설치할 수 없습니다.
`Cannot create a Mac App Development provisioning profile ... Personal development teams ... do not support the System Extension capability.`
오류가 나면 유료 Apple Developer Program 팀으로 전환해야 합니다.

자세한 내용은 [docs/signing-and-install.md](docs/signing-and-install.md)를 보세요.

### 3. 앱 실행

Xcode에서 `VirtualFaceCam` scheme을 선택하고 Run을 누릅니다.

앱이 열리면:

1. **Install / Refresh Camera** 클릭
2. macOS System Settings에서 확장 승인
3. 이미지 선택
4. 영상 앱에서 `Virtual Face Cam` 선택

## 컴파일만 확인하기

서명 없이 코드가 빌드되는지만 확인하려면:

```bash
./scripts/build_dev.sh
```

이 명령은 `CODE_SIGNING_ALLOWED=NO`로 빌드합니다. 앱 설치와 카메라 등록 테스트는 하지 않습니다.

서명 빌드를 시도하려면:

```bash
TEAM_ID=YOUR_TEAM_ID ./scripts/build_signed_dev.sh
```

예를 들어 Xcode Team ID가 `ABCDE12345`라면:

```bash
TEAM_ID=ABCDE12345 ./scripts/build_signed_dev.sh
```

## 폴더 구조

```text
native/
  VirtualFaceCamHost/             # SwiftUI host app
  VirtualFaceCamCameraExtension/  # CoreMediaIO Camera Extension
  Shared/                         # App Group 설정/공유 모델
  Resources/                      # 앱 아이콘
  project.yml                     # XcodeGen 프로젝트 정의

docs/
  standalone-virtual-camera-plan.md
  signing-and-install.md
  legacy-image-stage.md
```

## 기존 OBS 기반 프로젝트

OBS Virtual Camera를 사용해서 바로 실행하는 Python 버전은 아래 저장소에 있습니다.

https://github.com/TaeHuiKKIM/virtual-face-cam

## 검증 상태

이 repo의 현재 상태에서 확인한 것:

- Swift source typecheck 통과
- plist/entitlements lint 통과
- XcodeGen project 생성 통과
- Xcode 26.3에서 unsigned Debug build 성공
- Xcode 무료 Personal Team으로 signed build가 막히는 것 확인

아직 확인하지 못한 것:

- 유료 Apple Developer Program Team으로 signed build
- macOS System Extension 승인
- Zoom/Teams에서 실제 카메라 목록 노출

이 마지막 단계는 유료 Developer Team/App Group 등록이 필요합니다.

## 라이선스

MIT
