
csar = {}

csar.lostSouls = {}
csar.lostSouls[coalition.side.RED] = {}
csar.lostSouls[coalition.side.BLUE] = {}
csar.passengerCountMax = {}
csar.passengerCountMax["default"] = 1
csar.passengerCountMax["tandem"] = 2 --for trainers and the f14/two week*TM* plane
csar.passengerCountMax["Mi-24P"] 		= 3
csar.passengerCountMax["UH-1H"]			= 10
csar.passengerCountMax["Mi-8MT"]			= 14 -- I need to go to this party man 14??
csar.passengerCountMax["Mi-8MTV2"]		= 10
csar.passengerCountMax["SA342Mistral"]	= 2
csar.passengerCountMax["SA342Minigun"]	= 3
csar.passengerCountMax["SA342L"]			= 3
csar.passengerCountMax["SA342M"]			= 3
csar.passengerCountMax["OH58D"]			= 3

csar.csarTotalCount = 1

function PassengerCount(unit) --will check passengers based on unit loadout, for now returns max passengers
    return 2 -- passengerCountMax[unit]
end

util.hasCampaignCommand = {}

local e = {}
function e:onEvent(event)


    if event.id == world.event.S_EVENT_LANDING_AFTER_EJECTION then  --eject event
        if event.initiator == nil then return end
        if not event.initiator:isExist() then return end
        local lostSoul = {}
        lostSoul["Point"] = event.initiator:getPoint()
        lostSoul["Coalition"] = event.initiator:getCoalition()
        lostSoul["groupName"] = csar.spawnLostSouls(event.initiator:getPoint(), event.initiator:getCoalition())
        table.insert(csar.lostSouls[event.initiator:getCoalition()],lostSoul)
        event.initiator:destroy()
    end

end

world.addEventHandler(e)


local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end

function csar.list_csar(a)
    csar.audit()
    local callingUnitName,coalition = unpack(a)
    local output = "CSAR:"
    
    local unit = Unit.getByName(callingUnitName)
    if unit == nil then return end
    if not unit:isExist() then return end
    local rangeTable = {}
    local dataTable = {}
    for i, soulTable in next, csar.lostSouls[coalition] do
        rangeTable[soulTable.groupName] = math.floor(csar.rangeTo(unit:getPoint(),soulTable["Point"]))
        dataTable[soulTable.groupName] = soulTable
    end

    local i = 1
    for k,v in spairs(rangeTable) do
        output = output ..  " \n CSAR Group " .. i .. " at Bearing " .. tostring(math.floor(csar.bearing(unit:getPoint(), dataTable[k]["Point"]))) .. " for " .. tostring(util.round(v/1000,3)) .. " Km "
        i = i + 1
        if i >= 10 then break end
    end


    trigger.action.outTextForUnit(unit:getID(),output, 15)
end

function csar.rangeTo(unitPoint ,csarPoint)
    return math.sqrt((csarPoint.x - unitPoint.x)^2 + (csarPoint.z - unitPoint.z)^2)
end

function csar.bearing(unitPoint, csarPoint)
    return util.bearing(unitPoint, csarPoint)
end

function csar.coalitionChecker(coa)
    if coa == 2 then
        return country.id.USA
    elseif coa == 1 then
        return country.id.RUSSIA
    end
end

function csar.spawnLostSouls(point, coa)
    

    local groupData = {}
    
    groupData["visible"] = false
    groupData["task"] = 'Ground Nothing'
    groupData["units"] = {}
    groupData["name"] = "CSAR EXFIL Group" .. tostring(timer.getTime()) .. tostring(csar.csarTotalCount)
  

    local location = point --get location of unit

    groupData.units[1] = {}
    
    groupData.units[1]["type"] = inf.squadComp[coa]["SOF"]
    groupData.units[1]["name"] = "CSAR EXFIL Unit " .. tostring(timer.getTime()) .. tostring(csar.csarTotalCount)
    groupData.units[1]["x"] = location.x
    groupData.units[1]["y"] = location.z

    csar.csarTotalCount = csar.csarTotalCount + 1
    local group = coalition.addGroup(csar.coalitionChecker(coa), Group.Category.GROUND, groupData)
    inf.exfils[group:getName()] = inf.createTroopObject("","Server",coa,"CSAR",1,{group})
    group:getController():setOption(0,4) --turn off weapons
    return group:getName()
end

function csar.audit()

    for coa,coaTable in next, csar.lostSouls do
        for i, csarTable in next, coaTable do
            local group = Group.getByName(csarTable.groupName)
            --do things here do delete group
            if group == nil then csar.lostSouls[coa][i] = nil end
            if not group:isExist() then csar.lostSouls[coa][i] = nil end
            if group:getSize() == 0 then csar.lostSouls[coa][i] = nil end
        end
    end

end


trigger.action.outText("csar.lua loaded",10)
log.write("scripting", log.INFO, "csar.lua loaded")
