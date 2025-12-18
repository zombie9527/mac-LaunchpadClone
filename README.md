# LaunchpadClone

A high-performance, native macOS Launchpad alternative built with SwiftUI.

## Features

- **Native Performance**: Built with SwiftUI and AppKit for a smooth, lag-free experience.
- **Fast Discovery**: Automatically scans `/Applications`, `/System/Applications`, and `~/Applications`.
- **Async Icon Loading**: Icons are loaded in the background to ensure the UI remains responsive.
- **Memory Caching**: Uses `NSCache` for instant icon retrieval after the first load.
- **Real-time Search**: Quickly filter applications by name.
- **Modern UI**: Features a translucent (blur) background and elegant hover animations.

## Requirements

- macOS 14.0 or later
- Swift 5.9+

## How to Run

1. Clone the repository or navigate to the project folder.
2. Open your terminal and run:
   ```bash
   cd LaunchpadClone
   swift run LaunchpadClone
   ```

## How to Package as .app

To create a standalone `.app` bundle that you can move to your Applications folder:

1. Navigate to the `LaunchpadClone` directory.
2. Run the packaging script:
   ```bash
   ./package.sh
   ```
3. A `LaunchpadClone.app` will be created in the current directory.


## Project Structure

- `Sources/LaunchpadClone/`: Contains the Swift source code.
- `Package.swift`: Swift Package Manager configuration.

## License

MIT
