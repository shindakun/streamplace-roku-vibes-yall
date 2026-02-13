sub init()
    m.top.functionName = "fetchLiveStreams"
end sub

sub fetchLiveStreams()
    ' Base URL for the stream.place XRPC API
    baseUrl = "https://stream.place/xrpc/"

    ' First, get live users
    liveUsers = getLiveUsers(baseUrl)

    if liveUsers = invalid OR liveUsers.count() = 0
        ' Try recommendations as fallback
        liveUsers = getRecommendations(baseUrl)
    end if

    ' Build content nodes for the grid
    content = createObject("roSGNode", "ContentNode")
    liveUserData = []

    if liveUsers <> invalid
        for each user in liveUsers
            item = content.createChild("ContentNode")

            handle = getStringField(user, "handle")
            displayName = getStringField(user, "displayName")
            did = getStringField(user, "did")
            avatar = getStringField(user, "avatar")
            viewers = getIntField(user, "viewers")
            title = getStringField(user, "title")

            if displayName = "" then displayName = handle

            ' Set up the grid item
            item.title = displayName

            ' Caption line 1: stream title or handle
            if title <> ""
                item.shortDescriptionLine1 = title
            else
                item.shortDescriptionLine1 = "@" + handle
            end if

            ' Caption line 2: viewer count
            if viewers > 0
                item.shortDescriptionLine2 = viewers.toStr() + " watching"
            else
                item.shortDescriptionLine2 = "Live now"
            end if

            ' Use avatar as poster if available, otherwise generate placeholder URL
            if avatar <> ""
                item.HDPosterUrl = avatar
                item.SDPosterUrl = avatar
            else
                ' Use a thumbnail from the stream embed
                item.HDPosterUrl = "https://stream.place/og/" + handle
                item.SDPosterUrl = "https://stream.place/og/" + handle
            end if

            ' Store user data for playback
            userData = {
                handle: handle,
                did: did,
                displayName: displayName,
                avatar: avatar,
                title: title
            }
            liveUserData.push(userData)
        end for
    end if

    m.top.liveUserData = liveUserData
    m.top.content = content
end sub

' Fetch currently live users from the XRPC endpoint
function getLiveUsers(baseUrl as String) as Object
    url = baseUrl + "place.stream.live.getLiveUsers"

    response = makeRequest(url)
    if response = invalid then return invalid

    json = parseJSON(response)
    if json = invalid then return invalid

    ' The response should contain a list of live users
    if json.DoesExist("users")
        return json.users
    else if json.DoesExist("actors")
        return json.actors
    else if json.DoesExist("streams")
        return json.streams
    end if

    ' If the response is an array at the top level
    if type(json) = "roArray"
        return json
    end if

    return invalid
end function

' Fetch recommended streams as fallback
function getRecommendations(baseUrl as String) as Object
    url = baseUrl + "place.stream.live.getRecommendations"

    response = makeRequest(url)
    if response = invalid then return invalid

    json = parseJSON(response)
    if json = invalid then return invalid

    if json.DoesExist("recommendations")
        return json.recommendations
    else if json.DoesExist("users")
        return json.users
    else if json.DoesExist("streams")
        return json.streams
    end if

    if type(json) = "roArray"
        return json
    end if

    return invalid
end function

' Make an HTTP GET request
function makeRequest(url as String) as Dynamic
    request = createObject("roUrlTransfer")
    request.setUrl(url)
    request.setCertificatesFile("common:/certs/ca-bundle.crt")
    request.initClientCertificates()
    request.addHeader("Accept", "application/json")
    request.addHeader("User-Agent", "StreamplaceRoku/1.0")
    request.setPort(createObject("roMessagePort"))
    request.enableEncodings(true)

    if request.asyncGetToString()
        msg = wait(10000, request.getPort())
        if type(msg) = "roUrlEvent"
            if msg.getResponseCode() = 200
                return msg.getString()
            else
                print "HTTP Error: "; msg.getResponseCode(); " for "; url
            end if
        else
            print "Request timeout for "; url
        end if
    end if

    return invalid
end function

' Safely get a string field from an associative array
function getStringField(obj as Object, field as String) as String
    if obj = invalid then return ""
    if NOT obj.DoesExist(field) then return ""
    val = obj[field]
    if val = invalid then return ""
    if type(val) = "roString" OR type(val) = "String" then return val
    return val.toStr()
end function

' Safely get an integer field from an associative array
function getIntField(obj as Object, field as String) as Integer
    if obj = invalid then return 0
    if NOT obj.DoesExist(field) then return 0
    val = obj[field]
    if val = invalid then return 0
    if type(val) = "roInt" OR type(val) = "roInteger" OR type(val) = "Integer" then return val
    return 0
end function
