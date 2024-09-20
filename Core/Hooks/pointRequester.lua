local pq = {}
local function randomizer()
    return math.random(1000,9999)
end

function pq.onPlayerTrySendChat(pid, msg, toAll)

    if msg == "-request" then
        local r = randomizer()
        net.send_chat_to("REQUEST RECEIVED. CODE: " .. tostring(r) , pid , 1)
        local _status,_error  = net.dostring_in('server', " return trigger.action.setUserFlag('" .. tostring(pid) .."'," .. tostring(r) .. "); ")
        return ""
    end
end

DCS.setUserCallbacks(pq)