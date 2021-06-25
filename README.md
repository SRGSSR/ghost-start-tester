Ghost Start Technical Investigations
====================================

*Ghost starts*, i.e. comScore `start` events sent while the application is in background, have been reported as an issue affecting SRG SSR apps only, as they were not observed when validating apps from other Swiss publishers. It was therefore concluded that SRG SSR apps were incorrectly implementing comScore and Mediapulse specifications.

In this article **we prove that ghost starts are not an SRG SSR applications issue, but that they are merely an artifact of standard comScore SDK integration**. They are unavoidable in applications which the system is allowed to start without user intervention, for example when silent push notifications being received.

During our investigations we also discovered behavioral conflicts between the comScore SDK and the [Airship](https://www.airship.com) SDK. These conflicts might potentially affect measurements not only for apps involved in the Mediapulse initiative, but for any app implementing comScore and Airship at the same time. This problem is not theoretical, as comScore and Airship are two industry standards widely used.

## Unavoidability of Ghost Starts

According to the official comScore implementation guide, section 2.2:

> It is strongly advised to configure and start the library from within the `-application:didFinishLaunchingWithOptions:` method in an application project using Objective-C, or the equivalent location in a project using Swift.

the comScore SDK must be started from the `-application:didFinishLaunchingWithOptions:` method. Any other integration approach is dangerous, as it is likely that only the nominal integration path is well tested, documented and supported.

The `-application:didFinishLaunchingWithOptions:` method is the entry point of iOS and tvOS applications. This method is usually called when the user starts an app by tapping on its icon, but can also be called when the system [starts an app in background](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622921-application). Possible background launch conditions for an application are [officially documented](https://developer.apple.com/documentation/uikit/uiapplication/launchoptionskey), most notably silent push notifications, location updates or Bluetooth devices.

For example, when a silent push notification is received and the application is not running, the system might [wake up the application in background](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app) when appropriate to let it perform some work (like prefetching data), in which case `-application:didFinishLaunchingWithOptions:` will be called with the app running in the background for a limited amount of time.

When an application is launched by the system in background, and assuming the comScore SDK was integrated as recommended, a `start` event is therefore always sent in background. **This is unavoidable and ghost starts must therefore be considered as an expected byproduct of correct comScore integration**. In simple apps they might never be encountered, but any non-trivial app using push notifications or location services might emit them.

## Investigation methodology

To prove that ghost starts are a byproduct of recommended comScore integration in apps woken up by the system in background, we created a simple sample application integrating the comScore SDK and responding to [silent push notifications](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app). The application in itself does nothing and displays only a _Hello, World!_ message. It does not contain any SRG SSR specific logic at all.

The source code of the application is provided within this repository. Two tags are available for two versions of the source code:

- `simple`: Simple project with comScore and silent notification support only.
- `airship`: Same as the simple project, but with Airship additionally linked **and** started. Push notifications are not sent through Airship, though. We merely setup Airship with a configuration file and call its `takeOff` method.

Note that the sample application requires entitlements for push notifications and background modes (remote notifications).

### Development setup

We used the following development setup:

- comScore 6.8.1
- Airship 14.5.1
- iOS 14.6 running on iPhone XS.

This information is provided for completeness but results should be the same with any kind of similar setup.

### How to run the project

You can run the demo project in the simple and Airship scenarios as follows:

1. Clone the repository.
2. Switch to the tag you want to test.
3. Provide a custom bundle identifier and a development team for application code signing.
4. Your Apple developer account needs to be setup so that push notifications can be sent to the application when run on a device. The following [repository](https://github.com/onmyway133/PushNotifications) provides instructions how this can be achieved, as well as a useful tool to send push notification paylods to the app manually through APNS.
5. Run the app and accept to receive push notifications. Retrieve the device token displayed in the Xcode console.
6. Send a push notification with the tool above, your p8 file, key and team information, the device token and a payload with `content-availability` set to 1:
    
    ```
    {
        "aps": {
            "content-available": 1
        }
    }
    ```

For convenience we captured the result obtained for both demos in two separate videos below. Each capture displays a physical iPhone (mirrored with Quick Time), uses Charles to monitor its network traffic and the macOS Console to observe a few log outputs inserted in the source code. Note that we added banner information to the notification payload so that notifications can be seen when they are received by the device, though this is not needed and does not change the results in any way.

#### Remark

Silent notifications wake up the application in `-application:didFinishLaunchingWithOptions:` with a `nil` options dictionary. The notification payload is received in `-application:didReceiveRemoteNotification:fetchCompletionHandler:`.

### Simple Demo

The simple demo implements comScore and push notification support only:

1. The [video](simple.mp4) starts by showing the app is not running.
2. We start the app a first time interactively. A foreground `start` event is seen in Charles.
3. We kill the application.
4. We send a push notification with `content-available` set to 1. No comScore additional activity is seen in Charles for a while.
5. After having waited for some time we launch the app by tapping on its icon. A ghost start event is immediately appearing in Charles.

The ghost start event has a timestamp `ns_ts` corresponding to the time the push notification was initially received. Its `ns_ap_id` is the timestamp at which the event is sent, i.e. the timestamp corresponding to the user launching the app.

### Airship Demo

The Airship demo is the simple demo, with Airship linked and started (but not used in any other way):

1. The [video](airship.mp4) starts by showing the app is not running.
2. We start the app a first time interactively. A foreground `start` event is seen in Charles.
3. We kill the application.
4. We send a push notification with `content-available` set to 1. A background `start` event immediately appears in Charles.

The ghost start event has a timestamp `ns_ts` corresponding to the time the push notification is received. Its `ns_ap_id` is the timestamp at the time the event is sent, which only has a slight delay in comparison to `ns_ts`, as comScore introduces a small delay between the time an event is received and the time it is actually sent over the network.

## Results

For applications woken up by the system in the background (by silent push notifications, location services, etc.), standard comScore integration leads to `start` events being sent in the background, i.e. to ghost starts. This is **unavoidable** since standard comScore integration requires the SDK to be started from the application entry point, which is called when the app is launched interactively by a user or when the system is allowed to wake it up without user intervention.

In addition we discovered that applications using Airship send ghost starts with a very different timing:

- If the application does not use Airship a ghost start event is recorded but not sent right away. The recorded `start` event is only sent later when the user brings the app to the foreground. The timestamp `ns_ts` of the ghost start event corresponds to the time the event was initially recorded, provided the app has not been killed in the meantime.
- If the application links **and** uses Airship (by calling its `takeOff` method) it seems to gain greater background execution capabilities. Airship and comScore are closed source SDKs and the reasons for this behavior remain obscure. Tricks to have greater background capabilities and method swizzling or injection conflicts could provide plausible explanations, though this requires further investigation. As a result, any ghost start event is sent right away, with the timestamp `ns_ts` representing the time the app was woken up by the system.

In both cases the ghost start event timestamp is not representative of the time the user starts interacting with the app. As ghost starts cannot be avoided it is therefore incorrect to rely on `start` events as a sign of user interaction. Moreover, depending on how comScore tracks usage duration internally, there is an offset between a ghost start timestamp and the time a user starts interacting with the application. If the start event provides a reference point for duration calculations this offset might incorrectly add a positive bias to usage durations calculated by the comScore SDK. This needs to be confirmed as we have no access to the source code, but this could be a potential issue.

## Ghost starts in SRG SSR apps

The Airship SDK is used in several SRG SSR app as the official solution for push notification support. This explains why background starts could be recorded without testers interacting with our apps. This might also explain why this issue was not discovered for apps from other Swiss media publishers, as these publishers might not use Airship or might have simpler applications. You namely have to closely look at the `start` timestamps to distinguish those which might have occurred earlier in background. The fifth component of `ns_ap_env` sent in `start` labels can namely be used to distinguish interactive starts (value = 1) from ghost starts (value = 2).

## TL;DR and Next Steps

We proved that the ghost start issue reported for SRG SSR apps is not related to our implementation in any way. It is solely the result of standard comScore integration in applications which can be launched by the system. Interferences with Airship, a widely adopted industry standard for push notification management, were also discovered during our investigations as well.

A complete solution to the problems we found involves Mediapulse and comScore. This is required because all applications participating in the Mediapulse initiative are potentially affected in the same way as SRG SSR apps.

### Next Steps for Mediapulse

Mediapulse wants to count user interactions. Since ghost starts are an expected byproduct of correct comScore integration, and since we must already send page view events when the app is started or resumed (to comply with Mediapulse rules), we recommend Mediapulse to adjust its criteria and to count user interactions based on view events only. Starts must not be used as a sign of user interaction as ghost starts are unavoidable.

### Next Steps for comScore

Timestamps  `ns_ts` for ghost starts do not correspond to the time users start the app interactively. If this can impact usage duration negatively comScore should probably provide a corresponding bug fix.

If interference with Airship is a problem comScore should find the reason why this happens. Potential similar interferences with other 3rd party SDKs should be mitigated if possible, provided the reason of the interference is well understood.