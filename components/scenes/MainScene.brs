
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


'================================ INIT ======================================'
sub init()
    setupBaseNodes()
    observeEvents()
    initializeUI()
    resetState()
    setFocus()
    loadConfig()
    initStreamLayerSDK()
end sub


'=========================== BASE NODE SETUP ================================='
sub setupBaseNodes()
    m.eventInput = m.top.findNode("eventInput")
    m.startBtn = m.top.findNode("StartDemoBtn")
    m.keyboardDialog = m.top.findNode("KeyboardDialog")
    m.errorLabel = m.top.findNode("errorLabel")
    m.PlayerScreen = m.top.findNode("PlayerScreen")
end sub

'=========================== OBSERVERS & EVENTS ==============================='
sub observeEvents()
    ' --- Button press ---
    m.startBtn.observeField("buttonSelected", "onStartPressed")

    ' --- Keyboard OK/Cancel ---
    m.keyboardDialog.observeField("buttonSelected", "onKeyboardDone")

    m.playerScreen.observeField("closed", "onPlayerClosed")
end sub


'=========================== INITIALIZE UI ==================================='
sub initializeUI()
    palette = createObject("roSGNode", "RSGPalette")
    palette.colors = {
        DialogBackgroundColor: "0x111D25"
    }

    m.keyboardDialog.palette = palette
    m.keyboardDialog.visible = false
    m.errorLabel.text = ""
    m.errorLabel.visible = false
end sub


'=========================== RESET STATE ====================================='
sub resetState()
    m.eventId = ""
    m.focusIndex = 0 ' 0 = input, 1 = button
    m.isSdkInitialized = false
    m.settings = invalid
end sub


'=========================== OPEN KEYBOARD =================================='
sub openKeyboard()
    m.keyboardDialog.title = "Enter Event ID"
    m.keyboardDialog.text = m.eventId

    m.keyboardDialog.buttons = ["OK", "Cancel"]
    m.keyboardDialog.visible = true
    m.keyboardDialog.setFocus(true)

    hideError()
end sub

'=========================== CLOSE KEYBOARD =================================='
sub closeKeyboard()
    m.keyboardDialog.visible = false
    m.keyboardDialog.setFocus(false)
end sub


'=========================== KEYBOARD DONE ==================================='
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


'=========================== START PRESSED ==================================='
sub onStartPressed()
    if m.eventId = "" or m.eventId = invalid then
        showError("Please enter a valid Event ID")
        return
    end if

    print " [MainScene] Starting demo with Event ID: "; m.eventId

    if not m.isSdkInitialized
        showError("SDK Is not initialized")
        return
    end if

    playMediaEvent(m.eventId)
end sub

'============================ LOAD CONFIG =================================='
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

    m.settings = configData.settings
end sub


'=========================== INIT STREAM LAYER SDK ============================'
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
        enableLogging: settings.enableLogging
    }

    m.isSdkInitialized = m.playerScreen.callFunc("initStreamLayerSDK", config)

    if not m.isSdkInitialized
        showError(" [SLManager] Failed to initialize StreamLayer SDK")
    end if
end sub


'============================ PLAY MEDIA EVENT ============================'
sub playMediaEvent(eventId as string)
    if m.settings = invalid
        showError("[SLManager] Cannot initialize SDK: settings not loaded")
        return
    end if

    mediaItem = {
        id: eventId,
        stream: m.settings.streamUrl
    }

    '--- Start playback ---
    m.playerScreen.callFunc("playStream", mediaItem)
    m.playerScreen.visible = true
    m.playerScreen.focus = true
end sub

'=============================== SHOW ERROR =================================='
sub showError(msg as string)
    m.errorLabel.text = msg
    m.errorLabel.visible = true
end sub

'=============================== HIDE ERROR =================================='
sub hideError()
    m.errorLabel.visible = false
    m.errorLabel.text = ""
end sub

'=============================== SET FOCUS ==================================='
sub setFocus()
    if m.focusIndex = 0 then
        m.eventInput.opacity = 1.0
        m.startBtn.opacity = 0.6
        m.startBtn.setFocus(false)
        m.top.setFocus(true)
    else
        m.eventInput.opacity = 0.6
        m.startBtn.opacity = 1.0
        m.startBtn.setFocus(true)
    end if
end sub

'============================ ON PLAYER CLOSED ============================'
sub onPlayerClosed()
    m.playerScreen.visible = false
    m.playerScreen.focus = false
    m.focusIndex = 0
    setFocus()
end sub


'========================= REMOTE KEY HANDLING ================================'
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
