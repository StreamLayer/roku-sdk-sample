# StreamLayer Roku Consumer Demo App

Demo Roku channel used for testing the **StreamLayer SDK (SLSDK)** integration.  
This application demonstrates:

- dynamic SDK package loading  
- SDK initialization  
- player binding  
- event/session handling  
- rendering StreamLayer interactive overlays inside a Roku SceneGraph UI  

The `SLSDK` integration module is fully self-contained and can be copied into any Roku channel.


## Installation & Setup

### Requirements
- Roku device (Roku Ultra recommended)
- Roku OS **11.5+**
- Developer Mode enabled  
- Ability to sideload apps (`http://<ROKU_IP>`)
- Basic understanding of **BrightScript** and **SceneGraph**



## 📁 Project Structure

```
components/
└── SLSDK/
    ├── SLView/
    │   ├── SLView.xml
    │   └── SLView.brs
    └── SLManager/
        ├── SLManager.xml
        └── SLManager.brs

shared/
└── StreamLayerSDK.pkg   (local SDK package)
```

- **SLView** → Public component that your app interacts with  
- **SLManager** → Internal logic controller (not called directly)  
- **StreamLayerSDK.pkg** → The StreamLayer UI bundle loaded at runtime  



## Integration Model

The host application controls playback and ad timing.
The StreamLayer SDK is responsible for rendering overlays, managing lifecycle, and handling analytics events.



##  Configuration

Edit `config.json`:

```json
{
  "settings": {
    "language": "EN",
    "platform": "roku",
    "apiKey": "REPLACE_WITH_YOUR_API_KEY",
    "sdkUri": "pkg:/shared/StreamLayerSDK.pkg",
    "streamUrl": "REPLACE_WITH_YOUR_STREAM_URL",
    "isLoggingEnabled": true,
    "isAnalyticsEnabled": false,
    "isVastModeEnabled": false,
    "isPrefetchEnabled": false,
    "vastUrl": "REPLACE_WITH_YOUR_VAST_TAG",
    "vastAdType": "LBar21",
    "vastAdTarget": "standard",
    "isNotificationEnabled": false
  }
}
```

Note: config.json is used by the demo application for convenience.
Production integrations should configure the SDK using the initialize() API.

### Field Descriptions

| Field | Description                                                                                           |
|-------|-------------------------------------------------------------------------------------------------------|
| **language**           | UI language code (e.g., EN)                                                          |
| **platform**           | Always `"roku"`                                                                      |
| **apiKey**             | Your StreamLayer API Key (required)                                                  |
| **sdkUri**             | Path to the StreamLayer SDK package                                                  |
| **streamUrl**          | Video stream URL for the demo player                                                 |
| **isLoggingEnabled**   | Enables SDK logging output                                                           |
| **isAnalyticsEnabled** | Enables SDK analytics event reporting                                                |
| **isVastModeEnabled**  | Enables external VAST ad serving.                                                    |
| **isPrefetchEnabled**  | Enables preloading and caching of external VAST ads to reduce pause ad load latency. |
| **vastUrl**            | VAST tag the demo requests when VAST mode is on                                      |
| **vastAdType**         | Ad unit to draw for that tag; empty lets the SDK pick one from the creative          |
| **vastAdTarget**       | Which entry point the demo uses: `pause` or `standard`                               |
| **isNotificationEnabled** | Tease the ad with a notification before showing it                                |



## Integration Architecture Overview

### **1. SLView – Public API Layer**
The only component your app interacts with.  
Provides:
- SDK initialization  
- Player attachment  
- Event switching  
- Focus handling  
- Promo visibility events  

### **2. SLManager – Internal Logic Layer**
Handles:
- SDK package loading  
- Creating StreamLayer root nodes  
- Observing events (`promoVisible`, logs)  
- Passing data to the SDK  
- Cleanup of SDK node  

Developers **do NOT** interact with SLManager directly.


------------------------------------------------------------------------

## StreamLayer Roku Public API

This is the API surface exposed by `SLView` to the host application.


## 
**initialize(params)**

Initializes the StreamLayer SDK and prepares the StreamLayer UI overlay for playback integration.
This method must be called before using any other StreamLayer functionality.

#### Parameters:

-   **apiKey**

Your StreamLayer API key used to authenticate SDK requests.


-   **sdkUri**

Path or URL to the StreamLayer SDK package.
Typical local package path:

pkg:/shared/StreamLayerSDK.pkg

The SDK package can also be delivered via a StreamLayer-hosted CDN endpoint.
Please contact StreamLayer to obtain CDN access and configuration details.

-   **playerRef**

Reference to your SceneGraph Video node.
If not provided during initialization, you can attach the player later using attachPlayer().

-   **isLoggingEnabled**

Enables SDK debug logging output in the Roku console.
Useful during development and troubleshooting.
Default: false

-   **isAnalyticsEnabled**

Enables StreamLayer analytics event reporting.
When enabled, the SDK will send usage, playback, and interaction analytics events to StreamLayer services.
Default: false

-   **isVastModeEnabled**

Enables external VAST ad serving mode.
When enabled, the SDK expects pause ads to be delivered using standard IAB VAST XML responses from external ad servers or hosted XML files instead of StreamLayer native ad delivery.
This allows integration with third-party ad providers such as Google Ad Manager or custom ad decisioning systems.
Default: false

-   **isPrefetchEnabled**

Enables preloading and caching of external VAST ads to reduce pause ad load latency.
When enabled, the SDK will request and cache a VAST ad response in advance, allowing pause ads to be displayed faster when playback is paused.
Prefetch is primarily intended for use with external VAST ad integrations and is most effective when isVastModeEnabled is also enabled.
Default: false

Example:

```brightscript
slView.initialize({
    apiKey: m.config.apiKey,
    playerRef: m.videoPlayer,
    sdkUri: m.config.sdkUri,
    isLoggingEnabled: true,
    isAnalyticsEnabled: false,
    isVastModeEnabled: false,
    isPrefetchEnabled: false
})
```

##
**attachPlayer(playerRef)**

Attaches/re-attaches your video player to StreamLayer.

```brightscript
slView.attachPlayer(m.videoPlayer)
```


## 
**setEvent(eventId)**

Tells StreamLayer to load data for a specific event/session.

```brightscript
slView.setEvent("event123")
```


##
 **disposeSdk()**

Destroys all StreamLayer UI and removes the container.

```brightscript
slView.disposeSdk()
```


## 
**getVersion()**

Returns the current version of the StreamLayer SDK.

```brightscript
version = slView.getVersion()
? "[App] SDK version: " + version
```


##
**showPauseAd(params as Object)** and **showAd(params as Object)**

Two entry points, one per lifecycle. Both take the same `params`; what differs is who owns the
stream while the ad is on screen.

| | `showPauseAd` | `showAd` |
| --- | --- | --- |
| Stream | already stopped by this app | still playing |
| Who resumes it | this app, when the viewer leaves | the card, when the ad is done |
| Closed with | `closePauseAd()` | `closeOverlay()` |

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `vastUrl` | String | yes | VAST XML tag to load |
| `type` | String | no | Ad unit to draw. Leave empty and the SDK picks one from the creative |
| `isNotificationEnabled` | Boolean | no | Tease the ad with a notification the viewer opens it from |

Accepted values for `type`:

| `showPauseAd` | `showAd` |
| --- | --- |
| `PauseVastFullBleed` — full-bleed pause ad | `SideBar21` — sidebar, 2:1 template |
| `PauseVastAd` — standard pause ad | `LBar21` — L-Bar, 2:1 template |
| `PauseAdSidebar11` — pause sidebar, 1:1 | `SideBarImageOnly` — sidebar, single image |
| `PauseAdSidebar21` — pause sidebar, 2:1 | `LBarImageOnly` — L-Bar, single image |
| | `SideBySide` — Side-by-Side |

Pause ad, over a stream this app has stopped:
```brightscript
   slView.showPauseAd({ vastUrl: vastUrl, type: "PauseVastFullBleed" })
```

Standard ad, over running playback:
```brightscript
   slView.showAd({ vastUrl: vastUrl, type: "LBar21" })
```

Native StreamLayer Mode

If isVastModeEnabled = false, `showPauseAd()` takes nothing and the SDK serves its own pause ad.

**Notes:**
The host application controls when ads are requested and which unit is drawn.
`showAd` is ignored until the SDK reports **isEventReady** — resolving the event takes a round trip.
An unknown `type` is treated as if none was given.
Prefetch may be used to reduce pause ad load latency when VAST mode is enabled.


##
**setVastModeEnabled(enabled as Boolean)**


Enables or disables external VAST ad serving mode for the StreamLayer SDK.
This setting controls how pause ads are rendered and can be changed during an active playback session.

**Notes:**
Changes are applied the next time a pause ad is requested.
Does not affect any currently visible pause ad.



------------------------------------------------------------------------

### Public Fields

The following read-only fields expose the current visibility state of StreamLayer overlays.
These fields can be observed to synchronize host UI behavior with SDK overlay state.


##
- isPromoVisible (boolean)
Read-only.
Indicates whether a promo overlay is currently visible.


Example:
```brightscript
m.slView.observeField("isPromoVisible", "onPromoVisible")
```

##
- isNotificationVisible (boolean) 
Read-only.
Indicates whether a notification overlay is currently visible.

Example:
```brightscript
m.slView.observeField("isNotificationVisible", "onNotificationVisible")
```

##
- isEventReady (boolean)
Read-only.
Raised once the SDK has resolved the event and can be asked for ads. `showAd` calls made before
this are ignored.

Example:
```brightscript
m.slView.observeField("isEventReady", "onEventReady")
```

##
- isPauseAdVisible (boolean)
Read-only.
Indicates whether a pause ad overlay is currently visible.

Example:
```brightscript
m.slView.observeField("isPauseAdVisible", "onPauseAdVisible")
```

##
- focus (boolean)

Used by the host to transfer focus to StreamLayer UI.

```brightscript
slView.focus = true
```

------------------------------------------------------------------------

### Test Streams for SDK Overlay Preview

The sample application includes several ready-to-use video streams so you can immediately preview StreamLayer’s interactive overlays inside the Roku player. These streams are provided only for testing and demonstration purposes.
Available Sample Streams

https://storage.googleapis.com/shaka-demo-assets/bbb-dark-truths-hls/hls.m3u8      
https://stream.mux.com/wx8bp9XKXuYjKu3ZqKpE5ga1QVQcF02x.m3u8                      
https://content.jwplatform.com/manifests/vM7nH0Kl.m3u8                            
https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8  


Using Your Own Stream
To test StreamLayer with your own content:
Open config.json.
Locate the streamUrl field.
Replace it with your own valid HLS (.m3u8) URL. You can also use one of the sample test streams above if needed.


## Developer Notes

### View Logs (recommended)
```
telnet <ROKU-IP> 8085
```

Logs are tagged:
- `[SLView]`
- `[SLManager]`
- `[StreamLayerSDK]`


# 👥 Maintainers
**StreamLayer Engineering Team**  
© 2026 StreamLayer. All rights reserved.
