# shopping-assistant-mobile-client
Cross platform mobile client application for Shopping Assistant that utilizes Natural Language Processing (NLP) technology to interpret user queries for products and gifts. Users interact through a chat-style interface to communicate their shopping requirements.

## Table of Contents
- [Features](#features)
- [Stack](#stack)
- [Installation](#installation)
  - [Prerequisites](#prerequisites)
  - [Setup Instructions](#setup-instructions)
- [Configuration](#configuration)

## Features
- Cross-platform mobile app built with Flutter.
- Chat-style interface for natural language queries related to shopping.
- Integration with NLP technology to understand user product and gift requests.
- Supports managing wishlists and personal product selections.
- Product browsing with images, ratings, prices, and descriptions.
- Cart management of selected products.
- Account login and authentication.
- Real-time event stream handling for search and product suggestions.
- Supports adding products to personal wishlists.
- Supports iOS and Android platforms with native configurations.

## Stack
- Dart & Flutter (UI framework for cross-platform mobile development)
- GraphQL (queries and mutations via graphql_flutter)
- HTTP networking with http package
- JWT token management with jwt_decoder
- State management and UI with Flutter
- Local storage using shared_preferences
- Native Android code: Kotlin
- Native iOS code: Swift and Objective-C bridging header
- Image caching with cached_network_image
- UI icons and graphics in SVG format

## Installation

### Prerequisites
- Flutter SDK installed (stable channel recommended)
- Dart SDK included with Flutter
- Android Studio or Xcode for respective platform builds
- Android device or emulator / iOS device or simulator
- CocoaPods installed (for iOS dependencies)

### Setup Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/Shchoholiev/shopping-assistant-mobile-client.git
   cd shopping-assistant-mobile-client
   ```

2. Get Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. iOS setup (from root project folder):
   ```bash
   cd ios
   pod install
   cd ..
   ```

4. Run on Android:
   ```bash
   flutter run -d android
   ```

5. Run on iOS:
   ```bash
   flutter run -d ios
   ```

6. For building release versions, follow Flutter's platform-specific deployment guidelines.

## Configuration
- This app uses environment-specific API base URLs set internally. Consider modifying the base URL in `lib/network/api_client.dart` if needed.
- Authentication tokens are managed and cached via `shared_preferences`.
- No explicit environment variable files are required; sensitive data such as API keys or tokens should be managed securely and injected at runtime if applicable.
- Android Manifest and iOS Info.plist include Internet permission by default.

Please ensure your development environment matches versions compatible with the dependencies listed in `pubspec.yaml` and platform configurations in the `android` and `ios` folders.
