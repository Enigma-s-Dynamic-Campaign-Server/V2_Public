--slotblocker

local backline_typeNames = {} --add values to this list to limit to non frontline spawns
backline_typeNames["Mirage-F1EE"] = true
backline_typeNames["Mirage-F1CE"] = true
backline_typeNames["Mirage-F1BE"] = true
backline_typeNames["MiG-19P"] = true
backline_typeNames["MiG-21Bis"] = true
backline_typeNames["F-86F Sabre"] = true
backline_typeNames["F-5E-3"] = true
backline_typeNames["AJS37"] = true
backline_typeNames["F-14A-135-GR"] = true
backline_typeNames["MiG-29A"] = true

local canAlwaysSpawn = {}
canAlwaysSpawn["Syria"] = {}
canAlwaysSpawn["Syria"]["Sector 1-9"] = true
canAlwaysSpawn["Syria"]["Sector 1-13"] = true
canAlwaysSpawn["Syria"]["Sector 9-7"] = true
canAlwaysSpawn["Syria"]["Sector 10-10"] = true
canAlwaysSpawn["Syria"]["Sector 40-12"] = true
canAlwaysSpawn["Syria"]["Sector 41-9"] = true
canAlwaysSpawn["Syria"]["Sector 48-6"] = true
canAlwaysSpawn["Syria"]["Sector 49-9"] = true
canAlwaysSpawn["Caucasus"] = {}
canAlwaysSpawn["Caucasus"]["Sector 2-2"] = true
canAlwaysSpawn["Caucasus"]["Sector 3-19"] = true
canAlwaysSpawn["Caucasus"]["Sector 11-11"] = true
canAlwaysSpawn["Caucasus"]["Sector 18-20"] = true
--canAlwaysSpawn["Syria"]["EXACT Sector Name"] = true
--canAlwaysSpawn["Caucasus"]["EXACT Sector Name"] = true

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

local function isPointInPolygon(x, y, poly)

	local x1, y1, x2, y2
	local len = #poly
	x2, y2 = poly[len - 1], poly[len]
	local wn = 0
	for idx = 1, len, 2 do
		x1, y1 = x2, y2
		x2, y2 = poly[idx], poly[idx + 1]
	
		if y1 > y then
			if (y2 <= y) and (x1 - x) * (y2 - y) < (x2 - x) * (y1 - y) then
				wn = wn + 1
			end
		else
			if (y2 > y) and (x1 - x) * (y2 - y) > (x2 - x) * (y1 - y) then
				wn = wn - 1
			end
		end
	end
	return wn % 2 ~= 0 -- even/odd rule
end

local function pointInsideHex(point,points)

	local polygon = {}

	for k, v in next, points do
		table.insert(polygon, v.x)
		table.insert(polygon, v.z)
	end
	
	return isPointInPolygon(point.x, point.z, polygon)
end

local slotBlocker = {}
local slotblock = {}
slotblock.slotsByName = {}
slotblock.slotsByHex = {}

slotblock.gameMasters = {
    ["cdaccde02cd922f6820fac97a85b11ea"] = true, -- wizard
    ["d35ed385ccdc621dc3d9e3ac9def9c22"] = true, -- smooth rough
    ["3c04770340531d31c2fc04fe0c23ecd2"] = true, -- tempest
    ["843b4a640fdb7a285d559a5a2128ccb5"] = true, -- rooster strokes
    ["025ee29567ec00061db890812f4b8ec5"] = true, -- yink
    ["814f636a3668af4c8a17621e67d7dff4"] = true, -- deadseed
    ["591c2d480f1c5195842da92f39acbfa9"] = true, -- super etendard
    ["c7cb85663d0c7ec68fac35c6d2480339"] = true, -- king crab
    ["848eb0431a905ee04d86af37f8441c9f"] = true, -- Shadowfrost
    ["58d656379adf57b36ce5c23300b1de3b"] = true, -- enigma
    ["fd1cd519b421f617b6a2828c89707f73"] = true, -- Matroshka
    ["d4c4c902196a1168791778290608e7b9"] = true, -- Sol
    ["86bdedba966c40f1e07e976754bb68b1"] = true, -- llds07
    ["43009af9ad72caf2a3ff31396bed074"] = true, -- EagleEYe
    ["0281bea18cdf359c363a7263a558a40b"] = true, -- Dundar
    ["feb5e632e80a58097cb2eeb832a8b5be"] = true, -- HardtoKidnap
    ["32c0aa33414e9be166cadfcb7c4da9ae"] = true, -- Igloo
    ["43009af9ad72caf2a3ff31396bed074f"] = true, -- Eagleye
    ["e14babad806dec750575295c6b75ef2e"] = true, -- Overwatch	
    ["9e5591038d488a61a8ef2d1488447049"] = true -- Pat

	
	
	
}

local hexes = {}

local function isGameMaster(ucid)
	log.write("slotblocker gameMaster check", log.INFO,tostring(ucid) .. " " .. tostring(slotblock.gameMasters[ucid]))
    if slotblock.gameMasters[ucid] then
        return true
    end
    return false
end

local function findHexes()
	local miz = DCS.getCurrentMission().mission
	for k, v in next, miz.drawings.layers[5].objects do --all "Author" objects
		
		local points = {} --convert points to vec3 and translate them
		for index, point in next, v["points"] do
			point.z = point.y + v.mapY
			point.x = point.x + v.mapX 
			points[index] = point
		end
		
		local nextIndex = 1
		local indices = {}
			
		
		local averageX, averageZ, count = 0,0,0
		
		for index, value in next, points do
			averageX = averageX + value.x
			averageZ = averageZ + value.z
			count = count + 1
		end
		averageX = averageX / count
		averageZ = averageZ / count
		hexes[v.name] = {indices, {x = averageX, z = averageZ, y = 0}, points}
		log.write("slotblocker", log.INFO, v.name)
		--ecw.createHexInstance(v.name, indices, {x = averageX, z = averageZ, y = 0}, points)	--create hex instance with values
	end
end

function slotBlocker.onPlayerTrySendChat(playerId, message)
    if playerId == 1 then
        if string.upper(message) == "PUSH NEXT" then
            net.load_next_mission( )
        end
    end

    if string.find(message, "YAKFOR") ~= nil or string.find(message, "GREENFOR") ~= nil then
        
        local slots_to_try = {}

        for unitName, dataTable in next, slotblock.slotsByName do
            if string.find(message, "R-3S") ~= nil then
                if string.find(unitName, "R-3S") then
                    slots_to_try[unitName] = dataTable
                end
            end
            if string.find(message, "GUNPOD") ~= nil then
                if string.find(unitName, "GUNPOD") then
                    slots_to_try[unitName] = dataTable
                end
            end
            if string.find(message, "ROCKETS") ~= nil then
                if string.find(unitName, "ROCKETS") then
                    slots_to_try[unitName] = dataTable
                end
            end
            if string.find(message, "BOMB") ~= nil then
                if string.find(unitName, "BOMB") then
                    slots_to_try[unitName] = dataTable
                end
            end
        end

        for unitName, dataTable in next, slots_to_try do
            local slotted = DCS.getUnitProperty(dataTable.unitId, "DCS.UNIT_PLAYER_NAME")
            log.write("yakfor check", log.INFO, unitName .. " player name:" .. tostring(slotted))
            if slotted == nil then
                net.force_player_slot(playerId, 3, tostring(dataTable.unitId))
                break
            end
        end
        return ""
    end

end

function slotBlocker.onMissionLoadEnd() --from wizard RIP
	findHexes()
    slotblock.mission = DCS.getCurrentMission().mission
    slotblock.theatre = slotblock.mission.theatre
    for coalitionSide, coalitionData in pairs(slotblock.mission.coalition) do
        if coalitionSide ~= "neutrals" then
            if type(coalitionData) == "table" then
                if coalitionData.country then -- country has data
                    for _, ctryData in pairs(coalitionData.country) do
                        for objType, objData in pairs(ctryData) do
                            if objType == "plane" or objType == "helicopter" then
                                for _, groupData in pairs(objData.group) do
                                    for _, unitData in pairs(groupData.units) do
                                        if unitData.skill == "Client" then
                                            slotblock.slotsByName[unitData.name] = {
                                                ["unitType"] = unitData.type,
                                                ["unitName"] = unitData.name,
                                                ["category"] = objType,
                                                ["side"] = coalitionSide,
                                                ["x"] = unitData.x,
                                                ["y"] = unitData.y,
                                                ["unitId"] = unitData.unitId
                                            }

											for hexName,hexTable in next, hexes do
												if pointInsideHex({x = unitData.x, z = unitData.y},hexTable[3]) then
													log.write("slotblocker match", log.INFO, unitData.name .. " found in " .. hexName)
													slotblock.slotsByName[unitData.name].hexName = hexName
													break
												end
											end											
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    local s = ""
    for unitName, dataTable in next, slotblock.slotsByName do
        s = s .. unitName .. "," .. tostring(dataTable.unitId) .. "\n"
    end

    local f = io.open(lfs.writedir() .. "ColdWar/Files/.slots", "w")
    f:write(s)
    f:close()
end

function slotBlocker.onPlayerTryChangeSlot(playerID, side, slotID)
	
	local unitType 	= DCS.getUnitProperty(slotID, DCS.UNIT_TYPE)
	local unitName 	= DCS.getUnitProperty(slotID, DCS.UNIT_NAME)
    local theatre = DCS.getCurrentMission().mission.theatre
	
    if unitType == "instructor" then
        if isGameMaster(net.get_player_info(playerID ,'ucid')) then return true end
        return false
    end

	local hexName = slotblock.slotsByName[unitName].hexName
	local hexOwner, err = net.dostring_in("server", "return trigger.misc.getUserFlag('".. hexName .."')")
	
	log.write("slotblocker check", log.INFO,tostring(hexOwner) .. " " .. tostring(side) .. " " .. tostring(backline_typeNames[unitType]))
	
    if backline_typeNames[unitType] ~= nil and tostring(side) == tostring(hexOwner) then
        local isBackline,err = net.dostring_in("server", "return trigger.misc.getUserFlag('".. hexName .. "_FRONTLINE" .."')")
		log.write("backline check", log.INFO, tostring(isBackline) .. " " .. type(isBackline) .. " " .. tostring(canAlwaysSpawn[theatre][hexName]))

        if (tostring(isBackline) == tostring(2)) or (canAlwaysSpawn[theatre][hexName] ~= nil) then
            net.send_chat_to("Slot allowed!", playerID)
            return
        else
			net.send_chat_to(unitType .. " can't be used on a frontline hex!", playerID)
            return false
		end
    end

	if tostring(side) == tostring(hexOwner) then
		net.send_chat_to("Slot allowed!", playerID)
		return
	else
		net.send_chat_to("You dont own "..hexName..". Please try another aerodrome.", playerID)
		return false
	end	
end

function slotBlocker.onPlayerTryConnect(addr,ucid,name,playerId)

    if slotblock.gameMasters[ucid] ~= nil then
        return
    end

	if #net.get_player_list() >= 70 then
		return false, "Server is full! Please wait before trying again!"
	end
end

log.write("slotblocker init", log.INFO,"hexblocker started")

DCS.setUserCallbacks(slotBlocker)
