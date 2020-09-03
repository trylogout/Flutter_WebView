Flutter Webview
A WebView Flutter project.

## Getting Started
For help getting started with Flutter, view [online documentation](~https://flutter.dev/docs~).


## iOS
In order for plugin to work correctly, you need to add new key to iOS/Runner/Info.plist

``` xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
</dict>
```

NSAllowsArbitraryLoadsInWebContent is for iOS 10+ and NSAllowsArbitraryLoads for iOS 9.

## Android
This project available only for minimum SDK of 21. eval() function only supports SDK of 19 or greater for evaluating Javascript.