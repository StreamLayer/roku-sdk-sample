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


'================================= INIT ==================================='
sub init()
    setupBaseNodes()
    observeEvents()

    m.isPlaying = false
    m.currentEven = invalid
end sub


'=========================== BASE NODE SETUP ================================='
sub setupBaseNodes()
    m.player = m.top.findNode("Player")
    m.slView = m.top.findNode("SLView")
end sub


'=========================== OBSERVERS & EVENTS ==============================='
sub observeEvents()
    m.slView.observeField("promoVisible", "onPromoVisible")
    m.player.observeField("state", "onPlayerStateChange")
end sub


'========================= INIT STREAMLAYER VIEW ============================'
function initStreamLayerSDK(initParams as object) as boolean

    config = {
        apiKey: initParams.apiKey,
        playerRef: m.player,
        sdkUri: initParams.sdkUri,
        enableLogging: initParams.enableLogging
    }

    result = m.slView.callFunc("initialize", config)
    return result
end function


'=========================== ON PLAYER STATE CHANGE ========================='
sub onPlayerStateChange()
    state = m.player.state

    if state = "error"
        ?"[Player Error] Last error code: " + m.player.errorCode.toStr()
        ?"[Player Error] Last error message: " + m.player.errorMsg

    else if state = "playing"
        m.isPlaying = true
        ?" [Player] Playback started"
        setSLViewEvent(m.currentEventId)

    else if state = "finished" or state = "stopped"
        m.isPlaying = false
        ?"[Player] Playback finished or stopped"

    else if state = "buffering"
        m.isPlaying = false
        ?" [Player] Buffering..."

    else
        ?"⚠️ [Player] Unknown player state: " + state
    end if
end sub


'============================== PLAY STREAM ==============================='
sub playStream(mediaItem as object)

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
end sub


'============================== STOP STREAM ==============================='
sub stopStream()
    m.player.control = "stop"
    m.player.content = invalid
    m.isPlaying = false
end sub


'=============================== SET EVENT ================================'
sub setSLViewEvent(eventId as string)
    m.slView.callFunc("setEvent", eventId)
end sub


'============================= ON PROMO VISIBLE ============================='
sub onPromoVisible(event as object)
    m.isPromoVisible = event.getData()
    ?"[PlayerScreen] Promo visible: " + m.isPromoVisible.ToStr()

    m.slView.visible = m.isPromoVisible
    setFocus()
end sub


'============================== ON GET FOCUS =============================='
sub onGetFocus()
    setFocus()
end sub


'================================ SET FOCUS ================================'
sub setFocus()
    m.slView.focus = false
    if m.slView.visible
        m.slView.focus = m.top.focus
    else
        m.top.setFocus(m.top.focus)
    end if
end sub


'========================== REMOTE CONTROL EVENTS ========================='
function onKeyEvent(key as string, press as boolean) as boolean
    if (not press) then return false

    if key = "back"
        stopStream()

        '--- Notify parent ---
        m.top.closed = true
        return true
    end if

    if key = "OK" or key = "left" or key = "right" or key = "down" or key = "up"
        return true
    end if

    return false
end function