local lives = {}
local dir = lfs.writedir() .. "/ColdWar/Files/.lives" --unuser
local pw = "floggerz"
local players = {}

local lifeTypes = {}
lifeTypes["Standard"] = 3
lifeTypes["Ground Attack"] = 3
lifeTypes["Interceptor"] = 4
lifeTypes["Helicopter"] = 5
lifeTypes["Reserve"] = 4
local slots = {}

local typeDefinitions = {}
typeDefinitions["AJS37"] = "Ground Attack"
typeDefinitions["F-5E"] = "Interceptor"

if true then return end

local gameMasters = {
    ["cdaccde02cd922f6820fac97a85b11ea"] = true, -- wizard
    ["d35ed385ccdc621dc3d9e3ac9def9c22"] = true, -- smooth rough
    ["3c04770340531d31c2fc04fe0c23ecd2"] = true, -- tempest
    ["843b4a640fdb7a285d559a5a2128ccb5"] = true, -- rooster strokes
    ["025ee29567ec00061db890812f4b8ec5"] = true, -- yink
    ["814f636a3668af4c8a17621e67d7dff4"] = true, -- deadseed
    ["591c2d480f1c5195842da92f39acbfa9"] = true, -- super etendard
    ["c7cb85663d0c7ec68fac35c6d2480339"] = true, -- king crab
    ["cd1d2b089787691966d51b7467bcdd78"] = true, -- flyboy
    ["58d656379adf57b36ce5c23300b1de3b"] = true, -- enigma
    ["fd1cd519b421f617b6a2828c89707f73"] = true, -- Matroshka
    ["d4c4c902196a1168791778290608e7b9"] = true, -- Sol
    ["86bdedba966c40f1e07e976754bb68b1"] = true, -- llds07
    ["43009af9ad72caf2a3ff31396bed074"] = true, -- EagleEYe
    ["0281bea18cdf359c363a7263a558a40b"] = true, -- Dundar
    ["feb5e632e80a58097cb2eeb832a8b5be"] = true, -- HardtoKidnap
    ["32c0aa33414e9be166cadfcb7c4da9ae"] = true, -- Igloo
    ["43009af9ad72caf2a3ff31396bed074f"] = true -- Eagleye
}

local function split(pString, pPattern) --string.split
    local Table = {}
    local fpat = "(.-)" .. pPattern
    local last_end = 1
    local s, e, cap = pString:find(fpat, 1)
    while s do
       if s ~= 1 or cap ~= "" then
      table.insert(Table,cap)
       end
       last_end = e+1
       s, e, cap = pString:find(fpat, last_end)
    end
    if last_end <= #pString then
       cap = pString:sub(last_end)
       table.insert(Table, cap)
    end
    return Table
 end

local function getSlots()
    local red_slots = DCS.getAvailableSlots("red")
    local blue_slots = DCS.getAvailableSlots("blue")

    log.write("lives hook",log.INFO, tostring(red_slots))
    log.write("lives hook",log.INFO, tostring(blue_slots))

    if red_slots ~= nil then
        for i, t in next, red_slots do
            slots[t.unitId] = t
            log.write("lives hook", log.INFO,tostring(t.unitId).. " added to slot list")
        end
    end

    if blue_slots ~= nil then
        for i, t in next, blue_slots do
            slots[t.unitId] = t
            log.write("lives hook", log.INFO,tostring(t.unitId).. " added to slot list")
        end
    end
end


local function getUcid(pid)
    return net.get_player_info(pid , 'ucid')
end

function lives.getPlayersLives(pid,type1)
    local userString = getUcid(pid) .. "_" .. tostring(type1)
    log.write("lives hook", log.INFO,tostring(getUcid(pid)).. " " .. tostring(type1) .. " " .. userString)
    local lives,err = net.dostring_in("server", "return trigger.misc.getUserFlag('".. userString .."')")
    return lives
end

function lives.onPlayerConnect(pid)
   return
end

function lives.onPlayerTryChangeSlot(pid, coa, sid)

    if players[getUcid(pid)] == nil then
        players[getUcid(pid)] = true
        for type,amt in next, lifeTypes do
            local userString = getUcid(pid) .. "_" .. type
            local lives,err = net.dostring_in("server", "return trigger.action.setUserFlag('".. userString .."', " .. tostring(amt) ..  ")")
            
            local lives,err = net.dostring_in("server", "return trigger.misc.getUserFlag('".. userString .."')")
            log.write("lives hook", log.INFO,tostring(getUcid(pid))  .. " lives set to " .. tostring(lives)  .. " for " .. type)
        end
        log.write("lives hook", log.INFO,tostring(getUcid(pid)).. " lives set to max!")
    end

    local slot = slots[sid]
    local slotType
    for k,v in next, slot do
        log.write("slot", log.INFO, tostring(k) .. " " .. tostring(v))
    end

    if typeDefinitions[slot.type] == nil then
        slotType = "Standard"
        log.write("lives hook", log.INFO,tostring(getUcid(pid)).. " type definition not set for ".. tostring(slot.type))
    else
        slotType = typeDefinitions[slot.type]
    end
    local lives = lives.getPlayersLives(pid,slotType)

    log.write("lives hook", log.INFO,tostring(getUcid(pid)).. " lives for ".. tostring(lives).. " " .. slotType)
    net.send_chat_to("You have " .. tostring(lives) .. " "  .. slotType .. " lives remaining.", pid)
    if tonumber(tostring(lives)) > 0 then
        return
    else
        return false
    end
end

function lives.onMissionLoadEnd()
    getSlots()
end

DCS.setUserCallbacks(lives)