'------------------------------------------------------------------------------------
'#  File: SLManager.brs
'#
'#  Description:
'#      Logic component that manages the StreamLayer SDK lifecycle.
'#      Handles SDK library loading, initialization, player binding, promo
'#      visibility events, and focus coordination between the SDK and the
'#      host application.
'------------------------------------------------------------------------------------'


'================================ INIT ================================================'
sub init()
    m.apiKey = ""
    m.playerRef = invalid
    m.container = invalid
    m.streamLayerNode = invalid
    m.sdkLibrary = m.top.findNode("SLSDKLibrary")
    m.enableLogging = false
end sub


'============================ INITIALIZE SDK =========================================='
function initialize(initParams as object) as boolean

    logMessage("info", "▶ Starting StreamLayer SDK initialization...")

    '--- Validate SDK library node ---
    if m.sdkLibrary = invalid
        logMessage("error", "Initialization failed: SLSDKLibrary node is missing")
        return false
    end if

    '--- Prevent double initialization ---
    if m.streamLayerNode <> invalid
        logMessage("warn", "SDK is already initialized: Skipping initialization")
        return false
    end if

    '--- Validate initParams object ---
    if initParams = invalid
        logMessage("error", "Initialization failed: Received invalid initParams object")
        return false
    end if

    '--- Enable logging flag (optional) ---
    if initParams.enableLogging <> invalid
        m.enableLogging = initParams.enableLogging
    end if

    '--- Validate required data: apiKey ---
    if initParams.apiKey = invalid
        logMessage("error", "Initialization failed: apiKey is missing")
        return false
    end if

    m.apiKey = initParams.apiKey

    '--- Optional: player reference can be attached later ---
    if initParams.playerRef <> invalid
        m.playerRef = initParams.playerRef
    else
        logMessage("warn", "Player reference not provided: It can be attached later")
    end if

    '--- Validate required data: sdkUri ---
    if initParams.sdkUri = invalid
        logMessage("error", "Initialization failed: sdkUri is missing")
        return false
    end if

    '--- Load SDK Component Library ---
    loadSDKLibrary(initParams.sdkUri)

    return true
end function


'=============================== LOAD SDK LIBRARY ====================================='
sub loadSDKLibrary(sdkUri as string)
    logMessage("info", "Loading StreamLayer SDK from URI: " + sdkUri)
    m.sdkLibrary.uri = sdkUri
    m.sdkLibrary.observeField("loadStatus", "onLibLoaded")
end sub


'============================= ON LIB LOADED =========================================='
sub onLibLoaded()
    if not isSdkLibraryReady()
        return
    end if

    if not createStreamLayerNode() then return

    unregisterLibraryObserver()
    registerSdkObservers()

    if not attachNodeToContainer() then return

    initializeSdk()
end sub


'=========================== IS SDK LIBRARY READY ====================================='
function isSdkLibraryReady() as boolean
    if m.sdkLibrary.loadStatus <> "ready"
        logMessage("error", "Initialization failed: SDK component library failed to load")
        return false
    end if

    logMessage("info", "SDK library: Ready")
    return true
end function


'=========================== CREATE STREAM LAYER NODE ================================='
function createStreamLayerNode() as boolean
    m.streamLayerNode = CreateObject("roSGNode", "StreamLayerSDK:StreamLayer")

    if m.streamLayerNode = invalid
        logMessage("error", "Failed to create StreamLayer SDK node")
        return false
    end if

    return true
end function


'========================= UNREGISTER LIBRARY OBSERVER ================================'
sub unregisterLibraryObserver()
    m.sdkLibrary.unobserveField("loadStatus")
end sub


'=========================== REGISTER SDK OBSERVERS ==================================='
sub registerSdkObservers()
    m.streamLayerNode.observeField("log", "onSdkLog")
    m.streamLayerNode.observeField("promoVisible", "onPromoVisible")
end sub


'=========================== ATTACH NODE TO CONTAINER ================================='
function attachNodeToContainer() as boolean
    if m.container <> invalid
        m.container.appendChild(m.streamLayerNode)
    else
        logMessage("error", "Initialization failed: No container provided for SDK node")
        return false
    end if

    return true
end function


'=============================== INITIALIZE SDK ======================================='
sub initializeSdk()
    params = {
        apiKey: m.apiKey,
        playerRef: m.playerRef,
        enableLogging: m.enableLogging
    }

    logMessage("info", "Calling initSdk() on StreamLayer node...")
    m.streamLayerNode.callFunc("initSdk", params)
end sub


'============================= DISPOSE SDK ============================================'
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


'================================= BIND ==============================================='
sub bind(config as object)
    if config = invalid or config.container = invalid
        logMessage("error", "bind() failed: Invalid container configuration")
        return
    end if

    m.container = config.container
end sub


'============================== SET EVENT ============================================='
sub setEvent(eventId as string)
    if not hasSdkInstance() then return

    m.streamLayerNode.callFunc("setEvent", eventId)
end sub


'============================= ATTACH PLAYER =========================================='
sub attachPlayer(playerRef as object)
    if not hasSdkInstance() then return

    if playerRef = invalid
        logMessage("error", "Player attaching failed: Invalid playerRef")
        return
    end if

    m.streamLayerNode.callFunc("attachPlayer", { playerRef: playerRef })
end sub


'============================== GET VERSION ==========================================='
function getVersion() as dynamic
    if not hasSdkInstance() then return invalid

    version = m.streamLayerNode.callFunc("getVersion")
    logMessage("info", "StreamLayer SDK version: " + version)
    return version
end function


'============================== SDK LOG ==============================================='
sub onSdkLog(event as object)
    msg = event.getData()
    logMessage("info", "[StreamLayerSDK] " + msg)
end sub


'=========================== PROMO VISIBILITY ========================================='
sub onPromoVisible(event as object)
    isVisible = event.getData()
    logMessage("info", "Promo visibility: " + isVisible.toStr())
    m.top.promoVisible = isVisible
end sub


'=============================== FOCUS HANDLING ======================================='
sub onGetFocus()
    setFocus()
end sub


'=============================== SET FOCUS ============================================'
sub setFocus()
    if not hasSdkInstance() then return
    m.streamLayerNode.callFunc("setFocus", m.top.focus)
end sub


'=========================== CHECK SDK INSTANCE ======================================='
function hasSdkInstance(logOnFail = true as boolean) as boolean
    if m.streamLayerNode = invalid
        if logOnFail
            logMessage("error", "StreamLayer SDK instance is not initialized")
        end if
        return false
    end if

    return true
end function


'=============================== CREATE LOGGER ========================================'
sub logMessage(level as string, msg as string)
    prefix = ""

    if level = "info"
        prefix += "[INFO] "
    else if level = "warn"
        prefix += "[WARN] ⚠️ "
    else if level = "error"
        prefix += "[ERROR] ❌ "
    else
        prefix += " "
    end if

    print prefix + msg
end sub
