# Uppidi Upload

![Uppidi Logo](assets/logo.png)

A simple, cross-platform file uploader that works on your phone, tablet, desktop, or web browser. Upload images, videos, and other files to your choice of free public hosting services.

> **AI (LLM) Usage Notice:** This project is being developed with extensive AI assistance. The app is tested manually only on Android and Linux.

## Screenshots

| Light | Dark |
|---|---|
| ![Main screen (light)](docs/screenshots/main-screen-light.jpg) | ![Main screen (dark)](docs/screenshots/main-screen-dark.jpg) |
| ![Upload screen (light)](docs/screenshots/upload-screen-light.jpg) | ![Upload screen (dark)](docs/screenshots/upload-screen-dark.jpg) |
| ![Settings screen (light)](docs/screenshots/settings-screen-light.jpg) | ![Settings screen (dark)](docs/screenshots/settings-screen-dark.jpg) |

## Supported Hosting Providers

- Catbox
- Uguu.se
- Tmpfile.link
- FreeImage.host
- TempSH
- HttpBin.org (for testing)

## Supported Platforms

Uppidi runs on:

- Android phones and tablets
- iPhones and iPads (coming soon)
- Linux desktops (Windows and MacOS coming soon)
- Web browsers

On mobile devices, you can upload directly from your photo gallery or choose any file from your device. On desktop and web, you can select files from your computer. You can also share files directly to Uppidi from other apps.

## Getting Started

1. Download and install Uppidi on your device.
2. Open Uppidi and select which hosting service you want to use.
4. Select a file to upload from your device.
5. Tap upload and wait for it to finish.
6. Copy the link from the app to share your file.

### Building from Source

See [BUILDING.md](BUILDING.md) for instructions on building Uppidi from source for Android, Linux, and web.

> Pre-built binary packages are coming soon.

## Web Browser Version

Uppidi works in web browsers, but some hosting services cannot be used directly from a browser due to technical limitations (CORS restrictions). On native platforms (Android, Linux desktop), you can configure an HTTP/HTTPS proxy in settings to route uploads through an intermediary server.

## Upload History

Uppidi keeps a record of your recent uploads, including the file name, hosting service used, and the link to your file. You can view this history anytime to copy links or check what you have uploaded.

## Language Support

Uppidi supports English, Italian, and Turkish. Additional languages can be added.

## Privacy

Uppidi does not store, view, or keep copies of files you upload. Your files go directly from your device to the hosting service you select. 

## License

Uppidi Upload is released under the GNU General Public License v3 (GPLv3). See the LICENSE file for full details.
