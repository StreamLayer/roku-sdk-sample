'------------------------------------------------------------------------------
'  File: SLView.brs
'
'  Description:
'       Visual container that embeds the StreamLayerManager and provides
'       a layout container for the StreamLayer SDK visual node.
'       Handles manager binding, event forwarding, and focus management.
'------------------------------------------------------------------------------


'==================================== INIT =====================================
sub init()
    m.sdkContainer = m.top.findNode("sdkContainer")

    if m.sdkContainer = invalid
        logMessage("error", "Initialization failed: sdkContainer node is missing")
        return
    end if

    m.manager = CreateObject("roSGNode", "SLManager")

    if m.manager = invalid
        logMessage("error", "Initialization failed: Unable to create SLManager node")
        return
    end if

    m.top.appendChild(m.manager)

    m.manager.callFunc("bind", { container: m.sdkContainer })

    registerSdkObservers()

    logMessage("info", "Initialization completed: SLManager successfully attached")
end sub

'=========================== REGISTER SDK OBSERVERS ============================
sub registerSdkObservers()
    m.manager.observeField("isPromoVisible", "onPromoVisible")
    m.manager.observeField("isNotificationVisible", "onNotificationVisible")
    m.manager.observeField("isPauseAdVisible", "onPauseAdVisible")
    m.manager.observeField("isResumeRequested", "onResumeRequested")
    m.manager.observeField("isEventReady", "onEventReady")
end sub

'=============================== INITIALIZE SDK ================================
function initialize(params as object) as boolean
    if not hasManager() then return false

    logMessage("info", "SDK initialization started")
    return m.manager.callFunc("initialize", params)
end function

'================================= DISPOSE SDK =================================
sub disposeSdk()
    if not hasManager() then return
    m.manager.callFunc("disposeSdk")
end sub

'================================== SET EVENT ==================================
sub setEvent(event as string)
    if not hasManager() then return
    m.manager.callFunc("setEvent", event)
end sub

'================================ SET VAST MODE ================================
sub setVastModeEnabled(isVastModeEnabled as boolean)
    if not hasManager() then return
    m.manager.callFunc("setVastModeEnabled", isVastModeEnabled)
end sub

'================================= GET VERSION =================================
function getVersion() as dynamic
    if not hasManager() then return invalid

    version = m.manager.callFunc("getVersion")
    return version
end function

'============================= CHECK SDK INSTANCE ==============================
function hasManager() as boolean
    if m.manager = invalid
        logMessage("error", "Operation failed: StreamLayer SDK is not initialized")
        return false
    end if

    return true
end function

'============================== PROMO VISIBILITY ===============================
sub onPromoVisible(event as object)
    state = event.getData()
    logMessage("info", "Promo visibility changed: " + state.toStr())
    m.top.isPromoVisible = state
end sub

'=========================== NOTIFICATION VISIBILITY ===========================
sub onNotificationVisible(event as object)
    state = event.getData()
    logMessage("info", "Notification visibility changed: " + state.toStr())
    m.top.isNotificationVisible = state
end sub

'============================= PAUSE AD VISIBILITY =============================
sub onPauseAdVisible(event as object)
    state = event.getData()
    logMessage("info", "PauseAd visibility changed: " + state.toStr())
    m.top.isPauseAdVisible = state
end sub

'================================ EVENT READY ==================================
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
    if not hasManager() then return
    m.manager.focus = m.top.focus
end sub

'================================ ATTACH PLAYER ================================
sub attachPlayer(playerRef as object)
    if not hasManager() then return

    if playerRef = invalid
        logMessage("error", "Attach player failed: Invalid playerRef value")
        return
    end if

    m.manager.callFunc("attachPlayer", playerRef)
end sub

'================================ SHOW VAST AD =================================
sub showPauseAd(params = invalid)
    if not hasManager() then return
    m.manager.callFunc("showPauseAd", params)
end sub

'=================================== SHOW AD ===================================
sub showAd(params = invalid)
    if not hasManager() then return
    m.manager.callFunc("showAd", params)
end sub

'================================ CLOSE VAST AD ================================
sub closePauseAd()
    if not hasManager() then return
    m.manager.callFunc("closePauseAd")
end sub

'=============================== SET PAUSE STATE ===============================
sub setPauseState(pauseState as boolean)
    if not hasManager() then return
    m.manager.callFunc("setPauseState", pauseState)
end sub

'================================ CREATE LOGGER ================================
sub logMessage(level as string, msg as string)
    prefix = "[SLView] "

    if level = "info"
        prefix += "[INFO] "
    else if level = "warn"
        prefix += "[WARN] ⚠️ "
    else if level = "error"
        prefix += "[ERROR] ❌ "
    end if

    print prefix + msg
end sub
