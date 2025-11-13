

'================================= MAIN ==================================='
sub main(args as Dynamic)
    screen = CreateObject("roSGScreen")
    m.port = CreateObject("roMessagePort")
    screen.setMessagePort(m.port)
    
    '--- Create a scene and load /components/MainScene.xml ---'
    scene = screen.CreateScene("MainScene")
    screen.show()
    scene.observeField("exitApp", m.port)
    scene.signalBeacon("AppLaunchComplete")
    scene.setFocus(true)

    while true
        msg = wait(0, m.port)
        msgType = type(msg)

        if msgType = "roSGScreenEvent"
            if msg.isScreenClosed() then return
        else if msgType = "roSGNodeEvent"
            field = msg.getField()
            if field = "exitApp" then
                return
            end if
        end if
    end while
end sub
