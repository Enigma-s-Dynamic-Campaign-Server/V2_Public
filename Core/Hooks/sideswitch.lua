local sides = {}
sides[1] = {}
sides[2] = {}
local dir = lfs.writedir() .. "/ColdWar/Files/.sides"
local pw = "floggerz"

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

local function load()
    local f = io.open(dir,"r")
    sides = net.json2lua(f:read("*all"))
    f:close()
    return
end

local function save()
    local f = io.open(dir,"w")
    local s = f:write(net.lua2json(sides))
    f:close()
    return
end

local function getUcid(pid)
    return net.get_player_info(pid , 'ucid')
end

local function checkSide(pid)
    local ucid = net.get_player_info(pid , 'ucid')
    if sides[1][ucid] ~= nil then return 1 end
    if sides[2][ucid] ~= nil then return 2 end
    return 0
end

local function resetSidePid(pid)
    local ucid = getUcid(pid)
    sides[1][ucid] = nil
    sides[2][ucid] = nil
    save()
end

local function resetSideUcid(ucid)
    sides[1][ucid] = nil
    sides[2][ucid] = nil
    save()
end

local function totalReset()
    sides = {}
    sides[1] = {}
    sides[2] = {}
    save()
end

local sideswitch = {}

function sideswitch.onPlayerTryChangeSlot(pid, coa, sid)
    if coa == 0 then return end

    if sides[coa][getUcid(pid)] ~= nil then
        net.send_chat_to("Welcome back!", pid)
        return
    else
        net.send_chat_to("You're not on that team!", pid)
    end
    if sides[1][getUcid(pid)] == nil and sides[2][getUcid(pid)] == nil then
        net.send_chat_to("please type -red or -blue to pick a side!", pid)
    end
    return false
end

function sideswitch.onPlayerTrySendChat(pid, msg, toAll)
    if msg == "-red" or msg == "-blue" then
        if checkSide(pid) == 0 then
            if msg == "-red" then
                sides[1][getUcid(pid)] = true
                net.send_chat_to("You have selected red side!", pid)
            end
            if msg == "-blue" then
                sides[2][getUcid(pid)] = true
                net.send_chat_to("You have selected blue side!", pid)
            end
            save()
        end
    end

    if gameMasters[getUcid(pid)] == true then
        if msg == "-pids" then
            local players = net.get_player_list()

            for i,tpid in next, players do
                net.send_chat_to(tostring(net.get_player_info(tpid , 'name')) .. " " .. tostring(getUcid(tpid)), pid)
            end
        end
        if msg == "-reset" then
            totalReset()
        end
        if string.find(msg, "-reset") then
            local ucid = split(msg," ")[2]
            resetSideUcid(ucid)
        end
    end

end

function sideswitch.onMissionLoadEnd()
    local missionName = DCS.getMissionFilename()
    
    if ("INIT.miz" == missionName:sub(#missionName - 7, #missionName)) then
        totalReset()
    end
    load()
    return
end

DCS.setUserCallbacks(sideswitch)