Ghost Start Tester app
======================

Ghost starts, i.e. comScore `start` events sent when the application is in background, have been reported as an issue affecting SRG SSR apps, as they were not observed when validating apps from other publishers. It was therefore concluded that SRG SSR implementation was incorrect and the source of ghost starts.

We pretend that ghost starts are not related to SRG SSR applications, but are an artefact of correct integration of the comScore SDK which can potentially affect any app, depending on the features it supports.

# Analysis

According to the official comScore implementation guide, section 2.2:

> It is strongly advised to configure and start the library from within the `-application:didFinishLaunchingWithOptions:` method in an application project using Objective-C, or the equivalent location in a project using Swift.

the comScore SDK is usually started from the `-application:didFinishLaunchingWithOptions:` method. Any other integration approach is dangerous, as it is likely only the nominal integration path is well tested, documented and supported.

The `-application:didFinishLaunchingWithOptions:` method is the entry point of iOS (and tvOS) applications. This method is usually called the user starts the app by tapping on its icon, but can also be called when the system starts the app in background in special circumstances (silent push notification received, location servcices updated, etc.).

The fact the system might start the application in background is [officially documented](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622921-application). For example, when a silent push notification is received and the application is not running, the system might [wake up the application in background](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app) when appropriate to let it perform some work (for example prefetching data), in which case `-application:didFinishLaunchingWithOptions:` will be called but the system will not bring the application to the foreground.

Possible launch conditions for an application are [officially documented](https://developer.apple.com/documentation/uikit/uiapplication/launchoptionskey). Applications might be woken up in background by silent push notifications, location updates or Bluetooth devices, for example.

When an application is launched by the system in background, and assuming the comScore SDK was integrated as recommended, a `start` event is automatically sent in background. This is why ghost starts are artifacts of proper comScore SDK integration, not an SRG SSR implementation issue. 

# Sample Application

Sample application shows how a simple application only integrating the comScore SDK and implementing silent push notifications for updates will be affected by ghost starts.

A dummy publisher id (`1234567`) is used and HTTPS is enabled to comply with App Transport Security, but otherwise comScore initialization is standard and performed in `-application:didFinishLaunchingWithOptions:`. Silent push notification support is implemented 

Finally, the application is enabled for silent push notifications.

# 

- It asks the user to allow push notifications 




https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app

https://developer.apple.com/videos/play/wwdc2020/10063/

