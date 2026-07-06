# Native Project

This is the Swift + CoreMediaIO implementation of Virtual Face Cam.

Open the generated Xcode project:

```bash
open VirtualFaceCamMac.xcodeproj
```

Regenerate it from `project.yml`:

```bash
brew install xcodegen
xcodegen generate
```

The host app installs the embedded Camera Extension, copies the chosen image into
the App Group container, and writes `camera-config.json`. The extension reads
that shared state and renders frames into a CoreMediaIO camera stream.

Signing is required for real installation. See `../docs/signing-and-install.md`.
