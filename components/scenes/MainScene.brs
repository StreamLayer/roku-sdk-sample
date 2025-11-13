
'------------------------------------------------------------------------------
'  File: MainScene.brs
'   Description:
'       Main entry point of the StreamLayer Roku channel.
'       Handles initial configuration, SDK loading, screen management,
'       and deep linking logic required for Roku certification.
'
'       Responsible for:
'           • Loading configuration and localization data
'           • Initializing StreamLayer SDK
'           • Managing navigation between screens
'           • Handling remote key events
'------------------------------------------------------------------------------



'========================== REMOTE CONTROL EVENTS ==========================='
function onKeyEvent(key as string, press as boolean) as boolean
    if not press return false

    if key = "back"
      
          '--- Exit app directly ---
          m.top.exitApp = true
          return true
    end if

    if key = "OK" or key = "left" or key = "right" or key = "down" or key = "up"
        return true
    end if

    return false
end function