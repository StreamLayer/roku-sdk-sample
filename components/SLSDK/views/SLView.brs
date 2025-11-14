'------------------------------------------------------------------------------------
'#  File: SLView.brs
'#
'#  Description:
'#       Visual container that embeds the StreamLayerManager and provides
'#       a layout container for the StreamLayer SDK visual node.
'#       Handles manager binding, event forwarding, and focus management.
'------------------------------------------------------------------------------------


'================================ INIT ================================================
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

    m.manager.observeField("promoVisible", "onPromoVisible")

    logMessage("info", "Initialization completed: SLManager successfully attached")
end sub


'============================ INITIALIZE SDK ==========================================
function initialize(initParams as object) as boolean
    if not hasManager() then return false

    logMessage("info", "SDK initialization started")
    return m.manager.callFunc("initialize", initParams)
end function


'============================= DISPOSE SDK ============================================
sub disposeSdk()
    if not hasManager() then return
    m.manager.callFunc("disposeSdk")
end sub


'================================ SET EVENT ==========================================
sub setEvent(event as string)
    if not hasManager() then return
    m.manager.callFunc("setEvent", event)
end sub


'============================== GET VERSION ===========================================
function getVersion() as dynamic
    if not hasManager() then return invalid

    version = m.manager.callFunc("getVersion")
    return version
end function


'=========================== CHECK SDK INSTANCE =======================================
function hasManager() as boolean
    if m.manager = invalid
        logMessage("error", "Operation failed: StreamLayer SDK is not initialized")
        return false
    end if

    return true
end function


'============================= PROMO VISIBILITY =======================================
sub onPromoVisible(event as object)
    state = event.getData()
    logMessage("info", "Promo visibility changed: " + state.toStr())
    m.top.promoVisible = state
end sub


'=============================== FOCUS HANDLING =======================================
sub onGetFocus()
    setFocus()
end sub


sub setFocus()
    if not hasManager() then return
    m.manager.focus = m.top.focus
end sub


'============================= ATTACH PLAYER ==========================================
sub attachPlayer(playerRef as object)
    if not hasManager() then return

    if playerRef = invalid
        logMessage("error", "Attach player failed: Invalid playerRef value")
        return
    end if

    m.manager.callFunc("attachPlayer", playerRef)
end sub


'=============================== CREATE LOGGER ========================================='
sub logMessage(level as string, msg as string)
    prefix = "[SLView] "

    if level = "info"
        prefix += "[INFO] "
    else if level = "warn"
        prefix += "[WARN] ⚠️ "
    else if level = "error"
        prefix += "[ERROR] ❌ "
    else
        prefix += ""
    end if

    print prefix + msg
end sub
