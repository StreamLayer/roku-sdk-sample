'------------------------------------------------------------------------------
'  File: SLManager.brs
'
'  Description:
'      Logic component that manages the StreamLayer SDK lifecycle.
'      Handles SDK library loading, initialization, player binding, promo
'      visibility events, and focus coordination between the SDK and the
'      host application.
'------------------------------------------------------------------------------


'==================================== INIT =====================================
sub init()
    m.apiUrl = ""
    m.apiKey = ""
    m.playerRef = invalid
    m.container = invalid
    m.streamLayerNode = invalid
    m.sdkLibrary = m.top.findNode("SLSDKLibrary")
    m.isLoggingEnabled = false
    m.isAnalyticsEnabled = false
    m.isVastModeEnabled = false
    m.isPrefetchEnabled = false
end sub

'=============================== INITIALIZE SDK ================================
function initialize(params as object) as boolean

    logMessage("info", "Starting StreamLayer SDK initialization...")

    '--- Validate SDK library node ---
    if m.sdkLibrary = invalid
        logMessage("error", "SDK initialization aborted: SLSDKLibrary node is missing")
        return false
    end if

    '--- Prevent double initialization ---
    if m.streamLayerNode <> invalid
        logMessage("warn", "SDK is already initialized: Skipping initialization")
        return false
    end if

    '--- Validate params object ---
    if params = invalid
        logMessage("error", "SDK initialization aborted: Received invalid params object")
        return false
    end if

    '--- Enable logging flag (optional) ---
    if params.isLoggingEnabled <> invalid
        m.isLoggingEnabled = params.isLoggingEnabled
    end if

    '--- Enable analytics flag (optional) ---
    if params.isAnalyticsEnabled <> invalid
        m.isAnalyticsEnabled = params.isAnalyticsEnabled
    end if

    '--- Enable vast mode ---
    if params.isVastModeEnabled <> invalid
        m.isVastModeEnabled = params.isVastModeEnabled
    end if

    if params.isPrefetchEnabled <> invalid
        m.isPrefetchEnabled = params.isPrefetchEnabled
    end if


    '--- Optional: player reference can be attached later ---
    if params.playerRef <> invalid
        m.playerRef = params.playerRef
    end if

    m.apiUrl = params.apiUrl
    m.apiKey = params.apiKey
   
    '--- Load SDK Component Library ---
    loadSDKLibrary(params.sdkUri)

    return true
end function

'============================== LOAD SDK LIBRARY ===============================
sub loadSDKLibrary(sdkUri as object)

    '--- Validate required data: sdkUri ---
    if sdkUri = invalid
        logMessage("error", "SDK initialization aborted: sdkUri is missing.")
        return
    end if

    logMessage("info", "Loading StreamLayer SDK from URI: " + sdkUri)
    m.sdkLibrary.uri = sdkUri
    m.sdkLibrary.observeField("loadStatus", "onLibLoaded")
end sub

'================================ ON LIB LOADED ================================
sub onLibLoaded()
    if not isSdkLibraryReady() then return
    if not createStreamLayerNode() then return

    unregisterLibraryObserver()
    registerSdkObservers()

    if not attachNodeToContainer() then return

    initSdk()
end sub

'============================ IS SDK LIBRARY READY =============================
function isSdkLibraryReady() as boolean
    if m.sdkLibrary.loadStatus <> "ready"
        logMessage("error", "SDK initialization aborted: library failed to load")
        return false
    end if

    logMessage("info", "SDK library: Ready")
    return true
end function

'=============================== INITIALIZE SDK ================================
sub initSdk()

    params = {
        apiUrl: m.apiUrl,
        apiKey: m.apiKey,
        playerRef: m.playerRef,
        isLoggingEnabled: m.isLoggingEnabled,
        isAnalyticsEnabled: m.isAnalyticsEnabled,
        isPrefetchEnabled: m.isPrefetchEnabled,
        isVastModeEnabled: m.isVastModeEnabled
    }

    logMessage("info", "StreamLayer SDK initialization started.")
    m.streamLayerNode.callFunc("initSdk", params)
end sub

'================================= DISPOSE SDK =================================
sub disposeSdk()
    if not hasSdkInstance(false)
        logMessage("warn", "disposeSdk() called but SDK instance is not initialized")
        return
    end if

    logMessage("info", "Disposing StreamLayer SDK instance...")

    if m.container <> invalid
        m.container.removeChild(m.streamLayerNode)
    end if

    m.streamLayerNode = invalid
end sub

'==================================== BIND =====================================
sub bind(config as object)
    if config = invalid or config.container = invalid
        logMessage("error", "bind() failed: Invalid container configuration")
        return
    end if

    m.container = config.container
end sub

'========================== CREATE STREAM LAYER NODE ===========================
function createStreamLayerNode() as boolean
    m.streamLayerNode = CreateObject("roSGNode", "StreamLayerSDK:StreamLayer")

    if m.streamLayerNode = invalid
        logMessage("error", "Failed to create StreamLayer SDK node")
        return false
    end if

    return true
end function

'========================= UNREGISTER LIBRARY OBSERVER =========================
sub unregisterLibraryObserver()
    m.sdkLibrary.unobserveField("loadStatus")
end sub

'=========================== REGISTER SDK OBSERVERS ============================
sub registerSdkObservers()
    m.streamLayerNode.observeField("log", "onSdkLog")
    m.streamLayerNode.observeField("isPromoVisible", "onPromoVisible")
    m.streamLayerNode.observeField("isNotificationVisible", "onNotificationVisible")
    m.streamLayerNode.observeField("isPauseAdVisible", "onPauseAdVisible")
    m.streamLayerNode.observeField("isResumeRequested", "onResumeRequested")
    m.streamLayerNode.observeField("isEventReady", "onEventReady")
end sub

'========================== ATTACH NODE TO CONTAINER ===========================
function attachNodeToContainer() as boolean
    if m.container <> invalid
        m.container.appendChild(m.streamLayerNode)
    else
        logMessage("error", "Initialization failed: No container provided for SDK node")
        return false
    end if

    return true
end function

'================================== SET EVENT ==================================
sub setEvent(eventId as string)
    if not hasSdkInstance() then return
    m.streamLayerNode.callFunc("setEvent", eventId)
end sub

'================================ SET VAST MODE ================================
sub setVastModeEnabled(isVastModeEnabled as boolean)
    if not hasSdkInstance() then return
    m.streamLayerNode.callFunc("setVastModeEnabled", isVastModeEnabled)
end sub

'================================ ATTACH PLAYER ================================
sub attachPlayer(playerRef as object)
    if not hasSdkInstance() then return

    if playerRef = invalid
        logMessage("error", "Player attaching failed: Invalid playerRef")
        return
    end if

    m.streamLayerNode.callFunc("attachPlayer", { playerRef: playerRef })
end sub

'================================ SHOW VAST AD =================================
sub showPauseAd(params = invalid)
    if not hasSdkInstance() then return

    if m.isVastModeEnabled
        if params = invalid
            logMessage("error", "showPauseAd ignored: VAST params not provided")
            return
        end if

        if params.vastUrl = invalid or params.vastUrl = ""
            logMessage("error", "showPauseAd ignored: VAST URL not provided")
            return
        end if

        m.streamLayerNode.callFunc("showPauseAd", params)
    else
        m.streamLayerNode.callFunc("showPauseAd")
    end if
end sub

'=================================== SHOW AD ===================================
' Standard ad shapes run over playback: the card stops the host player itself and
' brings it back when it is done. Pause shapes go through showPauseAd instead.
sub showAd(params = invalid)
    if not hasSdkInstance() then return

    if params = invalid
        logMessage("error", "showAd ignored: VAST params not provided")
        return
    end if

    if params.vastUrl = invalid or params.vastUrl = ""
        logMessage("error", "showAd ignored: VAST URL not provided")
        return
    end if

    m.streamLayerNode.callFunc("showAd", params)
end sub

'================================ CLOSE VAST AD ================================
sub closePauseAd()
    if not hasSdkInstance() then return
    m.streamLayerNode.callFunc("closePauseAd")
end sub

'=============================== SET PAUSE STATE ===============================
sub setPauseState(pauseState as boolean)
    if not hasSdkInstance() then return
    m.streamLayerNode.callFunc("setPauseState", pauseState)
end sub

'================================= GET VERSION =================================
function getVersion() as dynamic
    if not hasSdkInstance() then return invalid

    version = m.streamLayerNode.callFunc("getVersion")
    logMessage("info", "StreamLayer SDK version: " + version)
    return version
end function

'=================================== SDK LOG ===================================
sub onSdkLog(event as object)
    msg = event.getData()
    print msg
end sub

'============================== PROMO VISIBILITY ===============================
sub onPromoVisible(event as object)
    isVisible = event.getData()
    logMessage("info", "Promo visibility: " + isVisible.toStr())
    m.top.isPromoVisible = isVisible
end sub

'=========================== NOTIFICATION VISIBILITY ===========================
sub onNotificationVisible(event as object)
    isVisible = event.getData()
    logMessage("info", "Notification visibility: " + isVisible.toStr())
    m.top.isNotificationVisible = isVisible
end sub

'============================= PAUSE AD VISIBILITY =============================
sub onPauseAdVisible(event as object)
    isVisible = event.getData()
    logMessage("info", "PauseAd visibility: " + isVisible.toStr())
    m.top.isPauseAdVisible = isVisible
end sub

'================================ EVENT READY ==================================
' The SDK resolved the event and can be asked for ads.
sub onEventReady(event as object)
    m.top.isEventReady = event.getData()
end sub

'============================== RESUME REQUESTED ===============================
sub onResumeRequested()
    logMessage("info", "isResumeRequested")
    m.top.isResumeRequested = true
end sub

'================================== GET FOCUS ==================================
sub onGetFocus()
    setFocus()
end sub

'================================== SET FOCUS ==================================
sub setFocus()
    if not hasSdkInstance() then return
    m.streamLayerNode.callFunc("setFocus", m.top.focus)
end sub

'============================= CHECK SDK INSTANCE ==============================
function hasSdkInstance(logOnFail = true as boolean) as boolean
    if m.streamLayerNode = invalid
        if logOnFail
            logMessage("error", "StreamLayer SDK instance is not initialized")
        end if
        return false
    end if

    return true
end function

'================================ CREATE LOGGER ================================
sub logMessage(level as string, msg as string)
    prefix = "[SLManager] "

    if level = "info"
        prefix += "[INFO] "
    else if level = "warn"
        prefix += "[WARN] ⚠️ "
    else if level = "error"
        prefix += "[ERROR] ❌ "
    end if

    print prefix + msg
end sub
