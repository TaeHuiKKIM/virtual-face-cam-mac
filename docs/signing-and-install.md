# Signing and Install Notes

## Why signing matters

`Virtual Face Cam` is a macOS Camera Extension. Camera Extensions are System
Extensions, so macOS will not load them like a normal unsigned command-line app.

You need:

- Xcode
- An Apple Developer Team
- App target and Camera Extension target signed by the same team
- System Extension install entitlement on the host app
- App Group shared by host app and extension

## Bundle IDs

Default IDs in this repo:

```text
Host app:          com.taehui.virtualfacecam
Camera extension:  com.taehui.virtualfacecam.CameraExtension
App Group:         group.com.taehui.virtualfacecam
```

If your Developer Portal cannot use these IDs, change them consistently in:

- `native/project.yml`
- `native/Shared/VirtualFaceCamShared.swift`
- `native/VirtualFaceCamHost/Host.entitlements`
- `native/VirtualFaceCamCameraExtension/CameraExtension.entitlements`
- `native/VirtualFaceCamCameraExtension/Info.plist`

## First install flow

1. Build and run `VirtualFaceCam` from Xcode.
2. Press **Install / Refresh Camera**.
3. macOS may ask you to approve the system extension.
4. Open System Settings and approve it.
5. Restart the video app that should use the camera.
6. Select `Virtual Face Cam` from the camera list.

Some macOS versions require the app to be in `/Applications` before a System
Extension activation request succeeds.

## Debugging commands

List system extensions:

```bash
systemextensionsctl list
```

Open the generated Xcode project:

```bash
./scripts/open_project.sh
```

Try a development build:

```bash
./scripts/build_dev.sh
```

If the extension is stuck in an old approval state, increment the bundle version
or remove the app and reboot.
