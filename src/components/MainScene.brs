sub init()
    m.streamGrid = m.top.findNode("streamGrid")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.statusLabel = m.top.findNode("statusLabel")
    m.liveNowLabel = m.top.findNode("liveNowLabel")
    m.emptyStateGroup = m.top.findNode("emptyStateGroup")
    m.loadingSpinner = m.top.findNode("loadingSpinner")
    m.streamInfoOverlay = m.top.findNode("streamInfoOverlay")
    m.nowPlayingLabel = m.top.findNode("nowPlayingLabel")
    m.nowPlayingHandle = m.top.findNode("nowPlayingHandle")

    m.isPlaying = false
    m.liveUsers = []

    ' Observe grid selection
    m.streamGrid.observeField("itemSelected", "onStreamSelected")

    ' Observe video state
    m.videoPlayer.observeField("state", "onVideoStateChange")

    ' Create and kick off the content fetcher task
    m.contentTask = createObject("roSGNode", "StreamContentTask")
    m.contentTask.observeField("content", "onContentLoaded")
    m.contentTask.observeField("liveUserData", "onLiveUserDataLoaded")
    m.contentTask.control = "run"

    ' Set up auto-refresh timer (every 30 seconds)
    m.refreshTimer = createObject("roSGNode", "Timer")
    m.refreshTimer.repeat = true
    m.refreshTimer.duration = 30
    m.refreshTimer.observeField("fire", "onRefreshTimer")
    m.refreshTimer.control = "start"

    m.streamGrid.setFocus(true)
end sub

' Called when the content task finishes loading grid content
sub onContentLoaded()
    content = m.contentTask.content

    m.loadingSpinner.visible = false

    if content <> invalid AND content.getChildCount() > 0
        m.streamGrid.content = content
        m.streamGrid.visible = true
        m.liveNowLabel.visible = true
        m.emptyStateGroup.visible = false

        count = content.getChildCount()
        m.statusLabel.text = count.toStr() + " stream" + iif(count > 1, "s", "") + " live"
        m.streamGrid.setFocus(true)
    else
        m.streamGrid.visible = false
        m.liveNowLabel.visible = false
        m.emptyStateGroup.visible = true
        m.statusLabel.text = "No live streams"
    end if
end sub

' Store the raw live user data for playback lookups
sub onLiveUserDataLoaded()
    m.liveUsers = m.contentTask.liveUserData
end sub

' Called when user selects a stream from the grid
sub onStreamSelected()
    selectedIndex = m.streamGrid.itemSelected

    if m.liveUsers <> invalid AND selectedIndex < m.liveUsers.count()
        userData = m.liveUsers[selectedIndex]
        playStream(userData)
    end if
end sub

' Start playing a stream
sub playStream(userData as Object)
    handle = userData.handle
    did = userData.did
    displayName = userData.displayName

    ' Build the HLS URL from stream.place
    ' stream.place serves HLS via the segments endpoint
    hlsUrl = "https://stream.place/api/playback/" + handle + "/index.m3u8"

    videoContent = createObject("roSGNode", "ContentNode")
    videoContent.url = hlsUrl
    videoContent.title = displayName + " - Live on Streamplace"
    videoContent.streamformat = "hls"
    videoContent.live = true

    m.videoPlayer.content = videoContent
    m.videoPlayer.visible = true
    m.videoPlayer.control = "play"
    m.videoPlayer.setFocus(true)

    ' Show overlay info
    m.nowPlayingLabel.text = displayName
    m.nowPlayingHandle.text = "@" + handle
    m.streamInfoOverlay.visible = true

    m.isPlaying = true

    ' Hide overlay after 5 seconds
    m.overlayTimer = createObject("roSGNode", "Timer")
    m.overlayTimer.repeat = false
    m.overlayTimer.duration = 5
    m.overlayTimer.observeField("fire", "onHideOverlay")
    m.overlayTimer.control = "start"
end sub

sub onHideOverlay()
    m.streamInfoOverlay.visible = false
end sub

' Handle video state changes
sub onVideoStateChange()
    state = m.videoPlayer.state

    if state = "error"
        stopPlayback()
        m.statusLabel.text = "Stream unavailable - may have ended"
    else if state = "finished"
        stopPlayback()
    end if
end sub

' Stop playback and return to grid
sub stopPlayback()
    m.videoPlayer.control = "stop"
    m.videoPlayer.visible = false
    m.streamInfoOverlay.visible = false
    m.isPlaying = false
    m.streamGrid.setFocus(true)
end sub

' Refresh content periodically
sub onRefreshTimer()
    if NOT m.isPlaying
        m.contentTask.control = "run"
    end if
end sub

' Handle deep links (e.g., launching directly to a streamer)
sub onDeepLink()
    handle = m.top.deepLinkHandle
    if handle <> invalid AND handle <> ""
        userData = {
            handle: handle,
            did: "",
            displayName: handle
        }
        playStream(userData)
    end if
end sub

' Handle remote control key presses
function onKeyEvent(key as String, press as Boolean) as Boolean
    if NOT press then return false

    if key = "back"
        if m.isPlaying
            stopPlayback()
            return true
        end if
    else if key = "OK" OR key = "play"
        if m.isPlaying
            ' Toggle overlay visibility
            m.streamInfoOverlay.visible = NOT m.streamInfoOverlay.visible
            return true
        end if
    else if key = "options"
        ' Refresh streams
        if NOT m.isPlaying
            m.loadingSpinner.visible = true
            m.statusLabel.text = "Refreshing..."
            m.contentTask.control = "run"
            return true
        end if
    end if

    return false
end function

function iif(condition as Boolean, trueVal as String, falseVal as String) as String
    if condition then return trueVal
    return falseVal
end function
