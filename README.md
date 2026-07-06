# Image Stage for Mac

Mac에서 이미지나 이미지 폴더를 크게 띄우는 아주 단순한 앱입니다.
OBS, 가상 카메라, pyvirtualcam 설치가 필요 없습니다.

## 이 앱을 쓰면 좋은 경우

- 이미지를 전체 화면으로 띄우고 싶을 때
- 폴더 안 이미지를 슬라이드쇼로 보여주고 싶을 때
- Zoom/Teams에서 **화면 공유**로 보여주면 충분할 때
- OBS 설치 없이 간단히 쓰고 싶을 때

## 이 앱으로 안 되는 것

이 앱은 Mac의 카메라 목록에 나타나는 웹캠 장치가 아닙니다.
Zoom, Teams, Chrome에서 카메라로 선택하려면 아래 저장소의 Virtual Face Cam을 사용하세요.

https://github.com/TaeHuiKKIM/virtual-face-cam

## 가장 쉬운 실행 방법

### 1. 다운로드

1. 이 GitHub 페이지에서 초록색 **Code** 버튼을 누릅니다.
2. **Download ZIP**을 누릅니다.
3. 받은 ZIP 파일을 압축 해제합니다.

### 2. 앱 열기

1. `Image Stage.app`을 오른쪽 클릭합니다.
2. **열기**를 누릅니다.
3. 경고창이 나오면 다시 **열기**를 누릅니다.
4. 브라우저 창이 열리면 성공입니다.

터미널에서 실행하려면:

```bash
./run-mac.command
```

## 사용 방법

1. **Images**에서 이미지 여러 장을 고르거나 **Folder**에서 폴더를 고릅니다.
2. 오른쪽 큰 화면에 이미지가 보입니다.
3. **Play**를 누르면 자동으로 넘어갑니다.
4. **Stop**을 누르면 멈춥니다.
5. **Fullscreen**을 누르면 전체 화면으로 볼 수 있습니다.
6. **Blackout**은 화면을 검게 가립니다.
7. **Mirror image**는 이미지를 좌우 반전합니다.

## 필요한 것

Mac과 Python 3.9 이상이 필요합니다.
대부분의 Mac에는 `/usr/bin/python3`가 이미 들어 있습니다.
추가 Python 패키지는 설치하지 않습니다.

## 브라우저가 안 열리면

터미널 창에 이런 주소가 보입니다.

```text
http://127.0.0.1:8770/
```

그 주소를 복사해서 Safari나 Chrome 주소창에 붙여넣으세요.

## 앱 아이콘

`Image Stage.app`에는 macOS용 앱 아이콘이 포함되어 있습니다.
Finder, Dock, Launchpad에서 앱 아이콘으로 표시됩니다.

## 앱 번들 갱신

소스 파일을 수정한 뒤 앱 번들 안의 파일을 다시 채우려면:

```bash
./scripts/build_app.sh
```

## 라이선스

MIT
