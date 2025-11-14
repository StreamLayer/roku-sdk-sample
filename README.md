# StreamLayer Roku Consumer Demo App

Demo Roku channel used for testing the **StreamLayer SDK (SLSDK)** integration.  
This application demonstrates:

- dynamic SDK package loading  
- SDK initialization  
- player binding  
- event/session handling  
- rendering StreamLayer interactive overlays inside a Roku SceneGraph UI  

The `SLSDK` integration module is fully self-contained and can be copied into any Roku channel.

---

## 🚀 Installation & Setup

### Requirements
- Roku device (Roku Ultra recommended)
- Roku OS **11.5+**
- Developer Mode enabled  
- Ability to sideload apps (`http://<ROKU_IP>`)
- Basic understanding of **BrightScript** and **SceneGraph**

---

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

---

## ⚙️ Configuration

Edit `config.json`:

```json
{
  "settings": {
    "host": "https://www.streamlayer.io",
    "language": "EN",
    "platform": "roku",
    "apiKey": "REPLACE_WITH_YOUR_API_KEY",
    "sdkUri": "pkg:/shared/StreamLayerSDK.pkg",
    "streamUrl": "REPLACE_WITH_YOUR_STREAM_URL",
    "enableLogging": true
  }
}
```

### Field Descriptions

| Field | Description |
|------|-------------|
| **host** | StreamLayer backend host |
| **language** | UI language code (e.g., EN) |
| **platform** | Always `"roku"` |
| **apiKey** | Your StreamLayer API Key (required) |
| **sdkUri** | Path to the StreamLayer SDK package |
| **streamUrl** | Video stream URL for the demo player |
| **enableLogging** | Enables StreamLayer debug logging |

---

## 🧩 Integration Architecture Overview

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

---

# 📘 StreamLayer Roku Public API

This is the API surface exposed by `SLView` to the host application.

---

## **initialize(params)**
Initializes the StreamLayer SDK.

### Parameters:
| Key | Required | Description |
|-----|----------|-------------|
| `apiKey` | ✔ | StreamLayer API key |
| `sdkUri` | ✔ | Path to SDK package |
| `playerRef` | ✖ | SceneGraph video node |
| `enableLogging` | ✖ | Enables debug logs |

### Example:
```brightscript
slView.initialize({
    apiKey: m.config.apiKey,
    playerRef: m.videoPlayer,
    sdkUri: m.config.sdkUri,
    enableLogging: true
})
```

---

## **attachPlayer(playerRef)**
Attaches/re-attaches your video player to StreamLayer.

```brightscript
slView.attachPlayer(m.videoPlayer)
```

---

## **setEvent(eventId)**
Tells StreamLayer to load data for a specific event/session.

```brightscript
slView.setEvent("event123")
```

---

## **disposeSdk()**
Destroys all StreamLayer UI and removes the container.

```brightscript
slView.disposeSdk()
```

---

## **getVersion()**
Returns the current version of the StreamLayer SDK.

```brightscript
version = slView.getVersion()
? "[App] SDK version: " + version
```

---

## **Public Fields**

### **promoVisible (boolean)**  
Read-only.  
Indicates when a promo/ad overlay is visible.

Example:
```brightscript
m.slView.observeField("promoVisible", "onPromoVisibleChanged")
```

---

### **focus (boolean)**  
Used by the host to transfer focus to StreamLayer UI.

```brightscript
slView.focus = true
```

---

# 🧪 Usage Example (Demo App)

### XML
```xml
<SLView id="SLView" visible="true" />
```

### BRS
```brightscript
m.slView = m.top.findNode("SLView")

m.slView.callFunc("initialize", {
    apiKey: m.config.apiKey,
    playerRef: m.videoPlayer,
    sdkUri: m.config.sdkUri
})

m.slView.setEvent("event123")

version = m.slView.getVersion()
? "SDK version: " + version
```

---

# ▶️ Video Streaming Example

Included demo stream:

```
https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8
```

Replace with your own HLS/DASH stream URL.

---

# 🧠 Developer Notes

### View Logs (recommended)
```
telnet <ROKU-IP> 8085
```

Logs are tagged:
- `[SLView]`
- `[SLManager]`
- `[StreamLayerSDK]`

---

# 👥 Maintainers
**StreamLayer Engineering Team**  
© 2025 StreamLayer. All rights reserved.