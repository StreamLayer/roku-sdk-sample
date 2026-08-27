
'------------------------------------------------------------------------------
'  StreamLayer Roku SDK / Demo Application
'
'  Copyright (c) 2025 StreamLayer.
'  All rights reserved.
'
'  This file is part of the StreamLayer Roku SDK package or its associated
'  demo application. Redistribution or modification is permitted only under
'  the terms of the StreamLayer license agreement.
'
'  Description:
'      This component is intended for integrators as part of the
'      StreamLayer Integration Sample.
'------------------------------------------------------------------------------


'==================================== INIT =====================================
sub init()
    setupBaseNodes()
    observeEvents()
    initializeUI()
    resetState()
    loadConfig()
    showVastSectionIfNeeded()
    setupVisibleElements()
    initStreamLayerSDK()

    m.focusTimer.control = "start"
end sub


'=============================== BASE NODE SETUP ===============================
sub setupBaseNodes()
    m.eventInput = m.top.findNode("eventInput")
    m.startBtn = m.top.findNode("StartDemoBtn")
    m.keyboardDialog = m.top.findNode("KeyboardDialog")
    m.errorLabel = m.top.findNode("errorLabel")
    m.PlayerScreen = m.top.findNode("PlayerScreen")
    m.eventSection = m.top.findNode("eventSection")
    m.vastUrlLabel = m.top.findNode("vastUrlLabel")
    m.focusTimer = m.top.findNode("focusTimer")
end sub

'============================= OBSERVERS & EVENTS ==============================
sub observeEvents()
    ' --- Button press ---
    m.startBtn.observeField("buttonSelected", "onStartPressed")

    ' --- Keyboard OK/Cancel ---
    m.keyboardDialog.observeField("buttonSelected", "onKeyboardDone")

    m.playerScreen.observeField("closed", "onPlayerClosed")
    m.focusTimer.observeField("fire", "updateFocus")
end sub


'================================ INITIALIZE UI ================================
sub initializeUI()
    palette = createObject("roSGNode", "RSGPalette")
    palette.colors = {
        DialogBackgroundColor: "0x111D25"
    }

    m.keyboardDialog.palette = palette
    m.keyboardDialog.visible = false
    m.errorLabel.text = ""
    m.errorLabel.visible = false
    m.vastUrlLabel.text = ""
    m.vastUrlLabel.visible = false
    m.visibleElements = []
end sub


'================================= RESET STATE =================================
sub resetState()
    m.eventId = ""
    m.focusIndex = 0 ' 0 = input, 1 = button
    m.isSdkInitialized = false
    m.isVastModeEnabled = false
    m.isOverlayVisible = false
    m.vastUrl = ""
    m.vastAdType = ""
    m.vastAdTarget = ""
    m.isNotificationEnabled = false
    m.settings = invalid
end sub


'================================ OPEN KEYBOARD ================================
sub openKeyboard()
    m.keyboardDialog.title = "Enter Event ID"
    m.keyboardDialog.text = m.eventId

    m.keyboardDialog.buttons = ["OK", "Cancel"]
    m.keyboardDialog.visible = true
    m.keyboardDialog.setFocus(true)

    hideError()
end sub


'=============================== CLOSE KEYBOARD ================================
sub closeKeyboard()
    m.keyboardDialog.visible = false
    m.keyboardDialog.setFocus(false)
end sub


'================================ KEYBOARD DONE ================================
sub onKeyboardDone(event as object)
    result = m.keyboardDialog.buttonSelected ' 0 = OK, 1 = Cancel

    if result = 0 then
        entered = m.keyboardDialog.text
        if entered <> invalid then
            m.eventId = entered
            m.eventInput.text = entered
        end if
    end if

    ' --- Close dialog ---
    closeKeyboard()

    ' --- Restore focus ---
    setFocus()
end sub


'================================ START PRESSED ================================
sub onStartPressed()

    if not m.isSdkInitialized
        showError("SDK Is not initialized")
        return
    end if


    if m.isVastModeEnabled
        print "[MainScene] Starting demo with vastUrl: "; m.vastUrl
    else 
        print "[MainScene] Starting demo with Event ID: "; m.eventId


        if m.eventId = "" or m.eventId = invalid then
            showError("Please enter a valid Event ID")
            return
        end if
    end if 

    playMediaEvent(m.eventId, m.vastUrl)
end sub


'================================= LOAD CONFIG =================================
sub loadConfig()
    configText = ReadAsciiFile("pkg:/config/config.json")

    if configText = invalid
        showError("[Config] Failed to read config file: pkg:/config/config.json")
        return
    end if

    configData = ParseJson(configText)

    if configData = invalid
        showError("[Config] Failed to parse JSON config")
        return
    end if

    ' Validate required fields
    if configData.settings = invalid
        showError("[Config] Missing 'settings' section in config")
        return
    end if

    m.isVastModeEnabled = configData.settings.isVastModeEnabled
    m.vastUrl = configData.settings.vastUrl
    m.vastAdType = configData.settings.vastAdType
    m.vastAdTarget = configData.settings.vastAdTarget
    m.isNotificationEnabled = configData.settings.isNotificationEnabled
    m.settings = configData.settings
end sub


'========================= SHOW VAST SECTION IF NEEDED =========================
sub showVastSectionIfNeeded()
    m.vastUrlLabel.visible = m.isVastModeEnabled
    m.vastUrlLabel.text = " Vast url :  " + m.vastUrl 
end sub
 

'============================ INIT STREAM LAYER SDK ============================
sub initStreamLayerSDK()
    if m.settings = invalid
        showError("[SLManager] Cannot initialize SDK: settings not loaded")
        return
    end if

    settings = m.settings

    ' --- Validate required fields ---
    if settings.apiKey = invalid or settings.sdkUri = invalid
        showError("[SLManager] Missing required fields in settings (apiKey or sdkUri)")
        return
    end if


    config = {
        apiKey: settings.apiKey,
        sdkUri: settings.sdkUri,
        isLoggingEnabled: settings.isLoggingEnabled,
        isAnalyticsEnabled: settings.isAnalyticsEnabled,
        isPrefetchEnabled: settings.isPrefetchEnabled,
        isVastModeEnabled: m.isVastModeEnabled
    }

    m.isSdkInitialized = m.playerScreen.callFunc("initStreamLayerSDK", config)

    if not m.isSdkInitialized
        showError(" [SLManager] Failed to initialize StreamLayer SDK")
    end if
end sub


'============================== PLAY MEDIA EVENT ===============================
sub playMediaEvent(eventId as string, vastUrl as string)
    if m.settings = invalid
        showError("[SLManager] Cannot initialize SDK: settings not loaded")
        return
    end if

    mediaItem = {
        id: eventId,
        vastUrl: m.vastUrl
        vastAdType: m.vastAdType
        vastAdTarget: m.vastAdTarget
        isNotificationEnabled: m.isNotificationEnabled
        stream: m.settings.streamUrl,
    }

    '--- Start playback ---
    m.playerScreen.callFunc("playStream", mediaItem)
    m.playerScreen.visible = true
    m.playerScreen.focus = true
end sub


'================================= SHOW ERROR ==================================
sub showError(msg as string)
    m.errorLabel.text = msg
    m.errorLabel.visible = true
end sub


'================================= HIDE ERROR ==================================
sub hideError()
    m.errorLabel.visible = false
    m.errorLabel.text = ""
end sub

'=========================== SETUP VISIBLE ELEMENTS ============================
sub setupVisibleElements()

    'Event input belongs to eventSection
    if m.eventSection.visible
        m.visibleElements.push(m.eventInput)
    end if

    'Start button is always visible
    m.visibleElements.push(m.startBtn)
end sub


'================================ UPDATE FOCUS =================================
sub updateFocus()
   setFocus()
end sub


'================================== SET FOCUS ==================================
sub setFocus()

    if m.visibleElements = invalid or m.visibleElements.count() = 0 then return

    ' Clamp index
    if m.focusIndex >= m.visibleElements.count()
        m.focusIndex = m.visibleElements.count() - 1
    end if
    if m.focusIndex < 0 then m.focusIndex = 0

    ' Reset visual state
     m.eventInput.opacity = 0.6
     m.startBtn.opacity = 0.6

    currentElement = m.visibleElements[m.focusIndex]

    ' Apply focus
    if currentElement.isSameNode(m.eventInput)
        m.eventInput.opacity = 1.0
        m.startBtn.setFocus(false) 
        m.top.setFocus(true)
    else
        currentElement.opacity = 1.0
        currentElement.setFocus(true)
    end if
end sub


'============================== ON PLAYER CLOSED ===============================
sub onPlayerClosed()
    m.playerScreen.visible = false
    m.playerScreen.focus = false
    m.focusIndex = 0
    setFocus()
end sub


'============================= REMOTE KEY HANDLING =============================
function onKeyEvent(key as string, press as boolean) as boolean
    if (not press) then return false

    '-------------- Navigation -------------
    if key = "down" then
        m.focusIndex = 1
        setFocus()
        return true
    end if

    if key = "up" then
        m.focusIndex = 0
        setFocus()
        return true
    end if

    '-------------- OK Pressed -------------
    if key = "OK" then
        if m.focusIndex = 0 then
            openKeyboard()
            return true
        end if
    end if

    return false
end function
