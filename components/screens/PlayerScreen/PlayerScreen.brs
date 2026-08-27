'------------------------------------------------------------------------------
'  File: PlayerScreen.brs
'   Description:
'       Handles the main playback logic, progress tracking, and StreamLayer SDK
'       integration for the player screen.
'
'       Responsible for:
'           • Initializing and configuring the video player
'           • Managing playback state and progress bar
'           • Handling StreamLayer SDK event synchronization
'           • Responding to remote key inputs and overlays
'------------------------------------------------------------------------------


'==================================== INIT =====================================
sub init()
    setupBaseNodes()
    setupObservers()

    m.isVastModeEnabled = false
end sub

'============================== SETUP BASE NODES ===============================
sub setupBaseNodes()
    m.player = m.top.findNode("Player")
    m.slView = m.top.findNode("SLView")

    m.pauseAdTimer = m.top.findNode("PauseAdTimer")
end sub

'============================= OBSERVERS & EVENTS ==============================
sub setupObservers()
    m.player.observeField("state", "onPlayerStateChange")
    m.slView.observeField("isPromoVisible", "onPromoVisible")
    m.slView.observeField("isNotificationVisible", "onNotificationVisible")
    m.slView.observeField("isPauseAdVisible", "onPauseAdVisible")
    m.slView.observeField("isResumeRequested", "onResumeRequested")
    m.slView.observeField("isEventReady", "onEventReady")
    
    m.pauseAdTimer.observeField("fire", "onPauseAdTimerFired")
end sub

'============================= RESET PLAYER STATE ==============================
sub resetPlayerState()
    m.eventSetStarted = false
    m.isPlaying = false
    m.currentEven = invalid
    m.isPromoVisible = false
    m.isOverlayVisible = false
    m.vastUrl = ""
    m.vastAdType = ""
    m.vastAdTarget = ""
    m.isNotificationEnabled = false
end sub

'=========================== ON PAUSE AD TIMER FIRED ===========================
sub onPauseAdTimerFired()
    if m.player.state <> "paused" then return
    if m.isOverlayVisible then return

    ' In VAST-only mode, pause ads are fully controlled by the host application.
    ' SDK acts only as a renderer and lifecycle manager.

    if m.isVastModeEnabled
        showVastPauseAd()
    else
        showPauseAd()
    end if
end sub

'============================ INIT STREAMLAYER SDK =============================
function initStreamLayerSDK(initParams as object) as boolean

    m.isVastModeEnabled = initParams.isVastModeEnabled

    config = {
        apiKey: initParams.apiKey,
        playerRef: m.player,
        sdkUri: initParams.sdkUri,
        isLoggingEnabled: initParams.isLoggingEnabled,
        isAnalyticsEnabled: initParams.isAnalyticsEnabled,
        isVastModeEnabled: m.isVastModeEnabled,
        isPrefetchEnabled: initParams.isPrefetchEnabled
    }

    result = m.slView.callFunc("initialize", config)
    return result
end function

'=========================== ON PLAYER STATE CHANGE ============================
sub onPlayerStateChange()
    state = m.player.state

    if state = "error"
        ?"[Player Error] Last error code: " + m.player.errorCode.toStr()
        ?"[Player Error] Last error message: " + m.player.errorMsg

        m.isPlaying = false
        m.pauseAdTimer.control = "stop"
        setSLViewPauseState(false)
        closePauseAd()

    else if state = "playing"
        ?"[Player] Playback started"
        
        m.isPlaying = true

        ' Always stop pause ads when playback resumes
        m.pauseAdTimer.control = "stop"
        setSLViewPauseState(false)
        closePauseAd()

        if not m.eventSetStarted
            setSLViewEvent(m.currentEventId)
            m.eventSetStarted = true
        end if

    else if state = "paused"
        ?"[Player] Playback paused"

        m.isPlaying = false
        setSLViewPauseState(true)

        m.pauseAdTimer.control = "stop"
        m.pauseAdTimer.control = "start"

    else if state = "buffering"
        ?"[Player] Buffering..."

        m.isPlaying = false
        m.pauseAdTimer.control = "stop"
   
    else if state = "finished" or state = "stopped"
        ?"[Player] Playback finished or stopped"

        m.isPlaying = false
        m.pauseAdTimer.control = "stop"
        setSLViewPauseState(false)
        closePauseAd()
    end if
end sub

'================================= PLAY STREAM =================================
sub playStream(mediaItem as object)

    resetPlayerState()

    if mediaItem.stream = invalid or mediaItem.stream = ""
        ?"[Player Error]. Missing or empty streamUrl"
        return
    end if

    videoContent = createObject("RoSGNode", "ContentNode")
    videoContent.streamFormat = "hls"
    videoContent.url = mediaItem.stream

    m.player.content = videoContent
    m.player.control = "play"
    m.currentEventId = mediaItem.id
    m.vastUrl = mediaItem.vastUrl
    m.vastAdType = mediaItem.vastAdType
    m.vastAdTarget = mediaItem.vastAdTarget
    m.isNotificationEnabled = mediaItem.isNotificationEnabled
end sub

'================================= STOP STREAM =================================
sub stopStream()
    m.player.control = "stop"
    m.player.content = invalid
    m.isPlaying = false
end sub

'================================ ON EVENT READY ===============================
' Resolving the event takes a round trip, so a standard shape can only be asked
' for once the SDK reports it is inside the event.
sub onEventReady()
    if not m.isVastModeEnabled then return
    if m.vastAdTarget <> "standard" then return

    showVastAd()
end sub

'============================= ON RESUME REQUESTED =============================
sub onResumeRequested()
    ?"[Player] Resuming"
    togglePlayPause()
end sub

'============================== TOGGLE PLAY/PAUSE ==============================
function togglePlayPause() as boolean
    
    state = m.player.state

    if state = "none" or state = "finished" or state = "stopped"
        m.player.control = "play"
        return true
    end if

    if state = "buffering"
        return false
    end if

    if state = "playing"
        m.player.control = "pause"

    else if state = "paused"
        m.player.control = "resume"
    end if

    return true
end function

'============================== SET SL VIEW EVENT ==============================
sub setSLViewEvent(eventId as string)
    m.slView.callFunc("setEvent", eventId)
end sub

'============================= SHOW VAST PAUSE AD ==============================
' Pause shapes: this app stopped the stream, and the ad holds the screen until
' the viewer leaves it.
sub showVastPauseAd()
    params = {
        vastUrl: m.vastUrl,
        type: m.vastAdType,
        isNotificationEnabled: m.isNotificationEnabled
    }

    m.slView.callFunc("showPauseAd", params)
end sub

'================================ SHOW VAST AD =================================
' Standard shapes run over playback: the card stops this app's player itself and
' brings it back when it is done.
sub showVastAd()
    params = {
        vastUrl: m.vastUrl,
        type: m.vastAdType,
        isNotificationEnabled: m.isNotificationEnabled
    }

    m.slView.callFunc("showAd", params)
end sub

'================================ SHOW PAUSE AD ================================
sub showPauseAd()
    m.slView.callFunc("showPauseAd")
end sub

'=============================== CLOSE PAUSE AD ================================
sub closePauseAd()
    m.slView.callFunc("closePauseAd")
end sub

'=========================== SET SL VIEW PAUSE STATE ===========================
sub setSLViewPauseState(pauseState as boolean)
    m.slView.callFunc("setPauseState", pauseState)
end sub

'============================== ON PROMO VISIBLE ===============================
sub onPromoVisible(event as object)
    m.isOverlayVisible = event.getData()
    ?"[PlayerScreen] Promo visible: " + m.isOverlayVisible.ToStr()
    updateOverlayState()
end sub

'=========================== ON NOTIFICATION VISIBLE ===========================
sub onNotificationVisible(event as object)
    m.isOverlayVisible = event.getData()
    ?"[PlayerScreen] Notification visible: " + m.isOverlayVisible.ToStr()
    updateOverlayState()
end sub

'============================= ON PAUSE AD VISIBLE =============================
sub onPauseAdVisible(event as object)
    m.isOverlayVisible = event.getData()
    ?"[PlayerScreen] PauseAd visible: " + m.isOverlayVisible.ToStr()
    updateOverlayState()
end sub

'============================ UPDATE OVERLAY STATE =============================
sub updateOverlayState()
    m.slView.visible = m.isOverlayVisible
    setFocus()
end sub

'================================ ON GET FOCUS =================================
sub onGetFocus()
    setFocus()
end sub

'================================== SET FOCUS ==================================
sub setFocus()
    m.slView.focus = false
    if m.slView.visible
        m.slView.focus = m.top.focus
    else
        m.top.setFocus(m.top.focus)
    end if
end sub

'================================ ON KEY EVENT =================================
function onKeyEvent(key as string, press as boolean) as boolean
    if (not press) then return false

    if key = "back"
        if m.isOverlayVisible = true then 
            closePauseAd()
            return true
        end if 

        stopStream()

        '--- Notify parent ---
        m.top.closed = true
        return true
    end if

    if key = "play"
        togglePlayPause()
        return true
    end if

    if key = "OK" or key = "left" or key = "right" or key = "down" or key = "up"
        return true
    end if

    return false
end function
