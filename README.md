# Lizection


<div align="center">
<img src="Resource/app_icon_cornered.png" width="100" height="100" alt="Lizection App Icon" style="border: 2px solid #ccc; border-radius: 20px;">
</div>

> Live Your Locations 🎯

<a href="#"><img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" width="140" height="40" style="filter: grayscale(100%); opacity: 0.5;"></a>
<span style="color: #666; font-size: 0.9em;">(Coming soon to the App Store)</span>




Lizection is an iOS application that helps users manage and navigate to their calendar event locations efficiently. It integrates with Apple Calendar to sync events and provides a seamless experience for viewing and navigating to event locations.

<div >
  <img src="https://img.shields.io/badge/Swift-6.1-orange.svg" alt="Swift 6.1">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
</div>

## Features

- 📅 Calendar Integration
  - Automatic sync with Apple Calendar
  - Real-time event updates
  - Smart location extraction from event details

- 🗺️ Location Management
  - Interactive map view of all event locations
  - List view with detailed event information
  - One-tap navigation to event locations
  - Geocoding status tracking for locations

- 🎯 Smart Features
  - Time-based event categorization (Upcoming, Current, Past)
  - Automatic geocoding of event locations
  - Background sync for calendar updates
  - Efficient data management with SwiftData

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- SwiftUI
- SwiftData
- MapKit

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/Lizection.git
```

2. Open the project in Xcode:
```bash
cd Lizection
open Lizection.xcodeproj
```

3. Build and run the project (⌘R)

## Usage

1. Grant calendar access when prompted
2. Your calendar events will automatically sync
3. View events in either list or map view
4. Tap on a location to get directions

## Architecture

The app follows a clean architecture pattern with:
- SwiftUI for the user interface
- SwiftData for persistence
- MVVM pattern for state management
- Background processing for calendar sync

See [Arch.md](Arch.md) for detailed architecture diagram.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Apple Calendar API
- MapKit
- SwiftData
- SwiftUI

