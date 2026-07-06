# Standalone Virtual Camera 기획안

## 목표

사용자가 OBS Studio, pyvirtualcam, 별도 가상 카메라 드라이버를 설치하지 않아도
`Virtual Face Cam.app` 하나로 macOS 카메라 목록에 `Virtual Face Cam`을 띄운다.

사용자는 앱에서 이미지 한 장 또는 이미지 폴더를 고르고, Zoom/Teams/Chrome에서
`Virtual Face Cam`을 카메라로 선택한다.

## 비목표

- 화면 공유용 슬라이드쇼 앱
- Python/Tkinter 기반 GUI
- OBS Virtual Camera 래퍼
- 브라우저 안에서만 보이는 프리뷰 앱
- Windows/Linux standalone driver 구현

## 핵심 제약

macOS에서 진짜 카메라 장치로 나타나려면 일반 앱 프로세스만으로는 부족하다.
Apple의 CoreMediaIO Camera Extension이 필요하다. Camera Extension은 System
Extension이므로 설치 승인, 코드 서명, entitlements, App Group 설정이 필요하다.

따라서 “앱만으로 된다”의 현실적인 의미는 다음과 같다.

1. 사용자가 OBS 같은 타사 드라이버를 설치하지 않는다.
2. 우리 앱 번들 안에 Camera Extension을 포함한다.
3. 사용자가 최초 1회 macOS 시스템 확장 설치를 승인한다.
4. 이후에는 우리 앱만 실행하면 이미지가 가상 카메라로 송출된다.

## 사용자 경험

### 첫 실행

1. 사용자가 `Virtual Face Cam.app`을 연다.
2. 앱이 Camera Extension 설치 필요 여부를 확인한다.
3. 설치가 필요하면 `Install Camera` 버튼을 보여준다.
4. 사용자가 버튼을 누르면 macOS System Extension 승인 흐름이 시작된다.
5. 승인 후 앱이 `Virtual Face Cam` 카메라 사용 가능 상태를 표시한다.

### 평상시 실행

1. 사용자가 이미지 또는 폴더를 선택한다.
2. 앱이 이미지를 App Group 공유 컨테이너에 복사한다.
3. 앱이 출력 설정을 저장한다.
4. 사용자가 Zoom/Teams/Chrome에서 `Virtual Face Cam`을 선택한다.
5. Camera Extension이 공유 컨테이너의 이미지를 프레임으로 렌더링한다.

## 아키텍처

```text
Virtual Face Cam.app
  ├─ Host App
  │  ├─ SwiftUI UI
  │  ├─ 이미지/폴더 선택
  │  ├─ App Group에 이미지 복사
  │  ├─ camera-config.json 저장
  │  └─ System Extension 설치 요청
  │
  └─ Camera Extension
     ├─ CoreMediaIO CMIOExtensionProvider
     ├─ CMIOExtensionDevice
     ├─ CMIOExtensionStream(source)
     ├─ App Group에서 이미지/설정 읽기
     └─ CVPixelBuffer 생성 후 stream.send()
```

## 데이터 저장

App Group:

```text
group.com.taehui.virtualfacecam
```

파일:

```text
camera-config.json
current-image
```

`camera-config.json`:

```json
{
  "imageFileName": "current-image",
  "width": 1280,
  "height": 720,
  "fps": 30,
  "fillMode": "fit",
  "updatedAt": 1720000000
}
```

## MVP 범위

- macOS host app
- Camera Extension target
- 최초 설치 버튼
- 이미지 한 장 선택
- 선택 이미지 가상 카메라 송출
- fit/fill 모드
- 1280x720, 30fps 기본 출력
- 이미지가 없을 때 기본 placeholder 프레임 출력

## 다음 단계

1. Xcode project 생성 및 signing 설정
2. Host app에서 System Extension 설치 확인
3. Extension이 placeholder 프레임으로 카메라 목록에 뜨는지 확인
4. App Group 파일 읽기 검증
5. 선택 이미지 렌더링 검증
6. 폴더 슬라이드쇼 추가
7. 앱 아이콘/온보딩/오류 메시지 정리
8. notarization/배포 패키지 정리

## 리스크

- Apple Developer Team이 없으면 Camera Extension 설치 테스트가 막힌다.
- App Group ID는 Developer Portal에 등록되어 있어야 한다.
- System Extension 최초 설치는 사용자 승인이 필요하다.
- Zoom/Teams/Chrome은 카메라 장치 캐시가 있어 앱 재시작이 필요할 수 있다.
- macOS 버전별 Camera Extension 동작 차이가 있을 수 있다.

## 참고

- Apple Developer Documentation: Creating a camera extension with Core Media I/O
- Apple Developer Documentation: Core Media I/O
- WWDC22: Create camera extensions with Core Media IO
