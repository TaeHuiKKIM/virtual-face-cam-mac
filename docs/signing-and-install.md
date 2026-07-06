# Signing and Install Notes

## Why signing matters

`Virtual Face Cam` is a macOS Camera Extension. Camera Extensions are System
Extensions, so macOS will not load them like a normal unsigned command-line app.

You need:

- Xcode
- A paid Apple Developer Program team
- App target and Camera Extension target signed by the same team
- System Extension install entitlement on the host app
- App Group shared by host app and extension

Important: Xcode's free `Personal Team` is not enough for this app. Camera
Extensions are System Extensions, and Apple does not allow Personal Teams to
create provisioning profiles for the System Extension capability.

## Getting a signing identity

On this Mac, you can check existing code-signing identities with:

```bash
security find-identity -v -p codesigning
```

If it prints `0 valid identities found`, create one through Xcode:

1. Join the paid Apple Developer Program if you need real System Extension testing or distribution.
2. Open Xcode.
3. Go to **Xcode > Settings... > Accounts**.
4. Press **+** and sign in with your Apple ID.
5. Select your Team.
6. Press **Manage Certificates...**.
7. Press **+**.
8. Choose **Apple Development**.

Xcode stores the certificate and its private key in Keychain. After that,
`security find-identity` should show an Apple Development identity.

If `security find-certificate -c "Apple Development"` finds a certificate but
`security find-identity -v -p codesigning` still prints `0 valid identities
found`, the private key is missing. In that case, create the certificate from
Xcode with **Manage Certificates... > + > Apple Development** instead of only
downloading a certificate from the Developer website.

Then open the project and select the same Team for both targets:

- `VirtualFaceCam`
- `VirtualFaceCamCameraExtension`

Personal Team signing may work for ordinary apps, but this project needs a paid
team. If the build prints this error, the selected team is still a free Personal
Team:

```text
Cannot create a Mac App Development provisioning profile for "com.taehui.virtualfacecam".
Personal development teams ... do not support the System Extension capability.
```

Try a signed development build with:

```bash
TEAM_ID=YOUR_TEAM_ID ./scripts/build_signed_dev.sh
```

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
