# Image Stage for macOS

OBS, pyvirtualcam, 가상 카메라 드라이버 없이 동작하는 macOS용 이미지
프리젠터 앱입니다. 로컬 브라우저 UI에서 이미지나 폴더를 선택하고
전체 화면 슬라이드쇼로 띄울 수 있습니다.

이 앱은 다른 앱의 카메라 목록에 웹캠으로 나타나지 않습니다. 웹캠 장치로
보이게 하려면 [virtual-face-cam](https://github.com/TaeHuiKKIM/virtual-face-cam)
repo의 가상 카메라 앱을 사용하세요.

## 필요한 것

1. macOS
2. Python 3.9 이상

추가 Python 패키지는 설치하지 않습니다.

## 실행

저장소를 받은 뒤 둘 중 하나를 실행하세요.

```bash
./run-mac.command
```

또는 Finder에서 `Image Stage.app`을 더블클릭합니다.

로컬 브라우저가 열리면 이미지 또는 폴더를 선택하세요. `Play`, `Stop`,
`Fullscreen`, `Blackout`, `Mirror`, `Contain/Cover`를 지원합니다.

## 앱 번들 갱신

소스 파일을 수정한 뒤 앱 번들 안의 리소스를 갱신하려면:

```bash
./scripts/build_app.sh
```

## 문제 해결

- Python을 못 찾으면 python.org의 macOS installer를 설치하거나
  `brew install python`을 실행하세요.
- 브라우저가 자동으로 열리지 않으면 터미널에 표시된 `http://127.0.0.1:...`
  주소를 직접 여세요.

## License

MIT
