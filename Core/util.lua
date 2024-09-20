
util.platoonCounter = 0
util.activeAC = {}
util.isLanded = {}
util.groupCommands = {}
util.markersIndeces = 11235496
util.activeAC = {}
util.isLanded = {}

util.activeAC = {}
util.isLanded = {}
util.reconPlaneCounter = 1

local typeDefinitions = {}
typeDefinitions["AJS37"] = "Ground Attack"
typeDefinitions["F-5E"] = "Interceptor"

function util.getUcid(playerName)
    for i, pid in next,  net.get_player_list() do
        if net.get_player_info(pid , 'name') == playerName then
            return net.get_player_info(pid , 'ucid')
        end
    end
    return nil
end

function util.round(num, numDecimalPlaces)

	if num == 0 then return 0 end
	
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function util.getAGL(point)
	return (point.y - (land.getHeight({x = point.x, y = point.z})))
end

function util.distance( unit1 , unit2) --use z instead of y for getPoint()
	
		local x1 = unit1:getPoint().x
		local y1 = unit1:getPoint().z
		local z1 = unit1:getPoint().y
		local x2 = unit2:getPoint().x
		local y2 = unit2:getPoint().z
		local z2 = unit2:getPoint().y

	return math.sqrt( (x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end


function util.distanceVec3( vec1 , vec2) --use z instead of y for getPoint()
	
	local x1 = vec1.x
	local y1 = vec1.z
	local z1 = vec1.y
	local x2 = vec2.x
	local y2 = vec2.z
	local z2 = vec2.y

return math.sqrt( (x2-x1)^2 + (y2-y1)^2 + (z2-z1)^2)
end

function util.split(pString, pPattern) --string.split
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

function util.greenfor_slot(_, time)

	local players = 1

	for k,player in next, net.get_player_list() do
		local playerName = "SLOT_" .. net.get_player_info(player,'name')
		local uid = tonumber(trigger.misc.getUserFlag(playerName))
		if uid > 0 then
			return
		end
	end
end

function util.isPointInPolygon(x, y, poly)

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
function util.spawnUnitTemplateTimedAA(t,time)

	local templateGroup = t[1]
	local coa = t[2]
	local point = t[3]
	local hex = t[4]
	local enum = t[5]
	local triggerName = t[6]
	
	local templateUnits = templateGroup:getUnits()
	local origin = templateUnits[1]:getPoint()
	local group = {}
	local country1
	group.name = templateUnits[1]:getName() .. '_group_' .. tostring(timer.getTime()) .. "_" .. tostring(util.platoonCounter)
	group.task = 'Ground Nothing'
	group.units = {}
	group.hiddenOnMFD = true
	if te.hiddenOnF10 == true then group.hidden = true end

	if coa == 1 then
		country1	= country.id.RUSSIA
	elseif coa == 2 then
		country1 = country.id.USA
	else
		return nil
	end

	for k,v in next, templateUnits do 
		group.units[k] = {}
		group.units[k].name     = v:getName() .. "_" .. tostring(k) .. "_" .. tostring(timer.getTime()) .. "_" .. tostring(util.platoonCounter)
		
		group.units[k].type     = v:getTypeName()
		group.units[k].x        = (v:getPoint().x - origin.x) + point.x
		group.units[k].y        = (v:getPoint().z - origin.z) + point.z
		group.units[k].heading  = math.random() * (math.pi * 2)
	end
	util.platoonCounter = util.platoonCounter + 1
	local newGroup = coalition.addGroup(country1, Group.Category.GROUND , group)

	hex.groups[enum][triggerName] = newGroup
	return nil
end

function util.spawnUnitTemplateTimed(t,time)

	local templateGroup = t[1]
	local coa = t[2]
	local point = t[3]
	local hex = t[4]
	local enum = t[5]
	local triggerName = t[6]
	local modifier = math.floor(t[7])
	local templateUnits = templateGroup:getUnits()
	local origin = templateUnits[1]:getPoint()
	local group = {}
	local groupCategory = templateGroup:getCategory()
	local country1
	group.name = templateUnits[1]:getName() .. '_group_' .. tostring(timer.getTime()) .. "_" .. tostring(util.platoonCounter)
	group.task = 'Ground Nothing'
	group.units = {}
	group.hiddenOnMFD = true
	if te.hiddenOnF10 == true then group.hidden = true end
	if te.hiddenOnF10 == true then group.hidden = true end

	if coa == 1 then
		country1	= country.id.RUSSIA
	elseif coa == 2 then
		country1 = country.id.USA
	else
		return nil
	end

	if modifier == nil then modifier = 0 end
	if (#templateUnits - modifier) < te.minimumSpawns then
			modifier = #templateUnits - te.minimumSpawns
	end

	util.log("spawn modifier", coa, modifier, #templateUnits, group.name)
	for k,v in next, templateUnits do
		if k <= (#templateUnits - modifier) or #templateUnits == 1 then
			group.units[k] = {}
			group.units[k].name     = v:getName() .. "_" .. tostring(k) .. "_" .. tostring(timer.getTime()) .. "_" .. tostring(util.platoonCounter)
			
			group.units[k].type     = v:getTypeName()
			group.units[k].x        = (v:getPoint().x - origin.x) + point.x
			group.units[k].y        = (v:getPoint().z - origin.z) + point.z
			group.units[k].heading  = math.random() * (math.pi * 2)
		end
	end
	util.platoonCounter = util.platoonCounter + 1
	
	local foundUnits = {}
	local sphere = trigger.misc.getZone(triggerName)
	sphere.point.y = land.getHeight({x = sphere.point.x,y = sphere.point.z})
	local volS = {
	id = world.VolumeType.SPHERE,
		params = {
			point = sphere.point,
			radius = sphere.radius
		}
	}
 
	local ifFound = function(foundItem, val)
		if string.find(foundItem:getName(),"Platoon") ~= nil or string.find(foundItem:getName(),"Sea") ~= nil then
			foundUnits[#foundUnits + 1] = foundItem:getName()
		end
		return true
	end
	
	world.searchObjects(Object.Category.UNIT, volS, ifFound)
	if #foundUnits <= 0 then
		local newGroup = coalition.addGroup(country1, groupCategory , group)
		hex.groups[enum][triggerName] = newGroup
	end

	return nil
end

function util.spawnUnitGroup(typeName,name, coa, point, count)
	
	local origin = point
	local group = {}
	local country1
	
	group.name = name .. '_group_' .. tostring(timer.getTime()) .. "_" .. tostring(util.platoonCounter)
	group.task = 'Ground Nothing'
	group.units = {}
	group.hiddenOnMFD = true
	if te.hiddenOnF10 == true then group.hidden = true end

	if coa == 1 then
		country1	= country.id.RUSSIA
	elseif coa == 2 then
		country1 = country.id.USA
	else
		return nil
	end

	for i = 1, count do
		group.units[i] = {}
		group.units[i].name     = name .. "_" .. tostring(i) .. "_" .. tostring(timer.getTime()) .. "_" .. tostring(util.platoonCounter)
		group.units[i].type     = typeName
		group["units"][i]["x"] 	= origin.x + (18 * math.cos(math.rad( (i / count) * 360 )))
		group["units"][i]["y"]	= origin.z + (18 * math.sin(math.rad( (i / count) * 360 )))
		group.units[i].heading  = math.rad((i / count) * 360 )
	end
	util.platoonCounter = util.platoonCounter + 1
	local newGroup = coalition.addGroup(country1, Group.Category.GROUND , group)
	return newGroup
end

function util.spawnUnitTemplate(templateGroup, coa, point, ...)
		
	local templateUnits = templateGroup:getUnits()

	local origin = templateUnits[1]:getPoint()
	local group = {}
	local country1
	group.name = templateUnits[1]:getName() .. '_group_' .. tostring(timer.getTime()) .. "_" .. tostring(util.platoonCounter)
	group.task = 'Ground Nothing'
	group.units = {}
	group.hiddenOnMFD = true
	if te.hiddenOnF10 == true then group.hidden = true end

	if coa == 1 then
		country1	= country.id.RUSSIA
	elseif coa == 2 then
		country1 = country.id.USA
	else
		return nil
	end

	for k,v in next, templateUnits do 
		group.units[k] = {}
		group.units[k].name     = v:getName() .. "_" .. tostring(k) .. "_" .. tostring(timer.getTime()) .. "_" .. tostring(util.platoonCounter)
		
		group.units[k].type     = v:getTypeName()
		group.units[k].x        = (v:getPoint().x - origin.x) + point.x
		group.units[k].y        = (v:getPoint().z - origin.z) + point.z
		group.units[k].heading  = math.random() * (math.pi * 2)
	end
	util.platoonCounter = util.platoonCounter + 1
	local newGroup = coalition.addGroup(country1, Group.Category.GROUND , group)
	return newGroup
end

function util.spawnUnitTemplateFromString(templateString, coa, templateType)

	local group = {}
	local country1
	group.name = util.split(templateString,"~")[1]

	group.task = 'Ground Nothing'
	group.units = {}
	group.hiddenOnMFD = true
	if te.hiddenOnF10 == true then group.hidden = true end
	local units = util.split(util.split(templateString,"~")[2],"|") 	-- 	Blue Platoon 1-1-1, M-60, 244046.78125 ,-448623.40625013 ,1.570796370511, false
	--																		unit:getName() .. "," .. unit:getTypeName() .. "," ..  unit:getPoint().x .. "," .. unit:getPoint().z  .. "," .. math.rad(util.heading(unit:getName()))  .. "," .. tostring(dead) .. "|"
	if coa == 1 then
		country1	= country.id.RUSSIA
	elseif coa == 2 then
		country1 = country.id.USA
	else
		return nil
	end

	for k,v in next, units do
		local unitTable = util.split(v,",")
		group.units[k] = {}
		group.units[k].name     = unitTable[1]
		group.units[k].type     = unitTable[2]
		group.units[k].x        = unitTable[3]
		group.units[k].y        = unitTable[4]
		group.units[k].heading  = unitTable[5]
	end
	util.platoonCounter = util.platoonCounter + 1
	local newGroup = coalition.addGroup(country1, templateType, group)
	util.log("spawnUnitTemplateFromString",group.name,newGroup:getName())
	return newGroup
end

function util.showSquadMember(t,time)
	local g,heliName,squadType = t[1],t[2],t[3]
	if util.isLanded[heliName] and Unit.getByName(heliName) ~= nil then
		if Unit.getByName(heliName):isExist() then
			if heli.instances[heliName].squads[squadType] > 0 then
				g:activate()
				heli.instances[heliName].squads[squadType] = heli.instances[heliName].squads[squadType] - 1
				heli.instances[heliName]:auditPassengers()
				heli.troopDropEvent(Unit.getByName(heliName), squadType)
				util.outTextForUnit(Unit.getByName(heliName),5,squadType,"troops in crew cabin:",heli.instances[heliName].squads[squadType])
			end
		end
	end
end

function util.groupGoToNextWaypoint(t,time)
	local g,w1,w2 = t[1],t[2],t[3]
	if not g:isExist() then return nil end
	if g:getSize() <= 0 then g:destroy() return nil end
	
	local goToWaypoint =
	{
		["enabled"] = true,
		["auto"] = false,
		["id"] = "GoToWaypoint",
		["params"] = 
		{
			["fromWaypointIndex"] = 1,
			["nWaypointIndx"] = 2,
		} -- end of ["params"]
	}

	local foundUnits = {}
	local volS = {
		id = world.VolumeType.SPHERE,
		params = {
			point = g:getUnits()[1]:getPoint(),
			radius = 15
		}
	}
	
	local ifFound = function(foundItem, val)
		if foundItem:getDesc().category == 1 then
			foundUnits[#foundUnits + 1] = foundItem:getName()
			return true
		end
	end
	
	world.searchObjects(Object.Category.UNIT, volS, ifFound)
	if #foundUnits <= 0 then g:getController():pushTask(goToWaypoint) else return timer.getTime() + 2 end
end

function util.spawnSquad(typeName,amount,coa,point,heading,squadBearing,heliName,targetPoint,squadType,heliInstance)
	if heliInstance.stopCommands == true then util.outText(20,"stopCommands",true) return end
	if heliInstance.unloading == true then util.outText(20,"unloading",true) return end
	heliInstance.unloading = true
	local group = {}
	local country1
	local groupsToReturn = {} 
	local heading = math.rad(heading)
	local oldPoint = targetPoint
	local heliPoint = Unit.getByName(heliName):getPoint()
	local newPoint
	
	if coa == 1 then country1 = country.id.RUSSIA elseif coa == 2 then country1 = country.id.USA else return nil end
	local bearing = math.rad(util.bearing(targetPoint,Unit.getByName(heliName):getPoint()))
	if math.sqrt((heliPoint.x - targetPoint.x)^2 + (heliPoint.y - targetPoint.y)^2 + (heliPoint.z - targetPoint.z)^2) > 1900 then
	
		newPoint = {
			x = targetPoint.x + (math.cos(bearing) * 2700),
			y = 0,
			z = targetPoint.z + (math.sin(bearing) * 2700)
		}
	else
		newPoint = heliPoint
	end
	
	util.outTextForUnit(Unit.getByName(heliName),5,"Dropping off",amount,squadType,"troops.")
	timer.scheduleFunction(function(heliN) heli.instances[heliN].unloading = false end,heliName,timer.getTime() + amount + 3)
	timer.scheduleFunction(function(heliN) heli.instances[heliN].stopCommands = false end,heliName,timer.getTime() + amount + 3)
	timer.scheduleFunction(function(heliN) heli.instances[heliN]:auditCommands() end,heliName,timer.getTime() + amount + 3)
	for i = 1,amount do
		group = {}
		group.name = typeName .. '_group_' .. tostring(timer.getTime()) .. "_" .. tostring(util.platoonCounter) .. tostring(i)
		group.task = 'Ground Nothing'
		group.units = {}
		group.start_time = math.huge
		group.visible = false
		group.hiddenOnMFD = true
	if te.hiddenOnF10 == true then group.hidden = true end
		
		group.units[1] = {}
		group.units[1].name     = typeName .. "_" .. tostring(i) .. "_" .. tostring(timer.getTime()) .. "_" .. tostring(util.platoonCounter)
		
		group.units[1].type     = typeName
		group.units[1].x        = point.x + (math.cos(heading + squadBearing) * 6) + (math.cos(math.rad( ((i-1) / (amount-1)) * 180 ) + (squadBearing - math.rad(90)) + heading) * (amount/2))
		group.units[1].y        = point.z + (math.sin(heading + squadBearing) * 6) + (math.sin(math.rad( ((i-1) / (amount-1)) * 180 ) + (squadBearing - math.rad(90)) + heading) * (amount/2))
		group.units[1].heading  = math.rad(util.bearing(Unit.getByName(heliName):getPoint(),{x = group.units[1].x, z = group.units[1].y, y = 0}))
		group.route = util.returnRoute({x = group.units[1].x, z = group.units[1].y},newPoint)--{x = group.units[1].x + 1000, z = group.units[1].y + 1000})
		
		util.platoonCounter = util.platoonCounter + 1
		groupsToReturn[i] = coalition.addGroup(country1, Group.Category.GROUND , group)
		groupsToReturn[i]:getController():setOption(0, 3)
		timer.scheduleFunction(util.groupGoToNextWaypoint,{groupsToReturn[i],1,2},timer.getTime() + amount + 3)
		timer.scheduleFunction(util.showSquadMember,{groupsToReturn[i],heliName,squadType},timer.getTime() + (i * 1))
	end
	return groupsToReturn,newPoint
end

function util.bearing(vec3A, vec3B)
	local azimuth = math.atan2(vec3B.z - vec3A.z, vec3B.x - vec3A.x)
	return azimuth<0 and math.deg(azimuth+2*math.pi) or math.deg(azimuth)
end

function util.bearingUnit(unitA, unitB)
	return util.bearing(unitA:getPoint(),unitB:getPoint())
end


function util.outText(timing, ...)
	local s = ""
	for i in ipairs(arg) do
		s = s .. tostring(arg[i]) .. " "
	end
	trigger.action.outText(s,timing)
end

function util.outTextForUnit(unit,timing, ...)
	local s = ""
	for i in ipairs(arg) do
		s = s .. tostring(arg[i]) .. " "
	end
	if unit ~= nil then
		trigger.action.outTextForUnit(unit:getID(), s , timing)
	end
end

function util.outTextForCoalition(coa,timing, ...)
	local s = ""
	for i in ipairs(arg) do
		s = s .. tostring(arg[i]) .. " "
	end
	trigger.action.outTextForCoalition(coa , s , timing)
end

function util.log(t,...)	
	local s = ""
	for i in ipairs(arg) do
		s = s .. tostring(arg[i]) .. " "
	end
	log.write(t, log.INFO, s)
end

function util.shuffle(tbl)
  for i = #tbl, 2, -1 do
    local j = math.random(i)
    tbl[i], tbl[j] = tbl[j], tbl[i]
  end
  return tbl
end

function util.sleep(n)
	if n > 0 then os.execute("ping -n " .. tonumber(n+1) .. " localhost > NUL") end
end


function util.vec3ToPitch(vec3)
	return math.deg(math.atan2(vec3.x.y, math.sqrt(vec3.x.z^2+vec3.x.x^2)))
end

function util.vec3ToRoll(vec3)
	return math.deg(math.atan2(-vec3.z.y, vec3.y.y))
end

function util.vec3ToYaw(vec3)
	return math.deg(math.atan2( vec3.x.z, vec3.x.x ))
end

function util.respawnStatic(static,dead,hidden,...)

	local staticTable,country = {},""
	
	if arg[1][1] == true then
		staticTable = static
		country = arg[1][2]
	else
		staticTable.name = static:getName()
		staticTable.x = static:getPoint().x
		staticTable.y = static:getPoint().z
		staticTable.type = static:getTypeName()
		staticTable.heading = math.rad(util.staticHeading(static:getName()))
		staticTable.dead = dead
		staticTable.hidden = hidden
		country = arg[1][2]
		--country = static:getCountry()
	end
	
	if #arg > 1 then
		staticTable.x = arg[2]
		staticTable.y = arg[3]
		staticTable.name = arg[4]
	end
	if staticTable["type"] == ".Ammunition depot" then staticTable["shape_name"] = "SkladC" staticTable["category"] = "Warehouses" end
	local s = coalition.addStaticObject(country , staticTable )
	return s
end

function util.returnRoute(startVec3,moveVec3)
	local route = 
	{
		["points"] = 
		{
			[1] = 
			{
				["type"] = "Turning Point",
				["alt_type"] = "BARO",
				["ETA"] = 20,
				["formation_template"] = "",
				["y"] = startVec3.z,
				["x"] = startVec3.x,
				["speed"] = 4,
				["action"] = "Off Road",
				["task"] = 
				{
					["id"] = "ComboTask",
					["params"] = 
					{
						["tasks"] = 
						{
							[1] = 
							{
								["number"] = 1,
								["auto"] = false,
								["id"] = "Hold",
								["enabled"] = true,
								["params"] = 
								{
									["templateId"] = "",
								}, -- end of ["params"]
							}, -- end of [1]
						}, -- end of ["tasks"]
					}, -- end of ["params"]
				}, -- end of ["task"]
			}, -- end of [1]
			[2] = 
			{
				["alt"] = 5,
				["type"] = "Turning Point",
				["ETA"] = 0,
				["alt_type"] = "BARO",
				["formation_template"] = "",
				["y"] = moveVec3.z,
				["x"] = moveVec3.x,
				["ETA_locked"] = false,
				["speed"] = 4,
				["action"] = "Off Road",
				["task"] = 
				{
					["id"] = "ComboTask",
					["params"] = 
					{
						["tasks"] = 
						{
						}, -- end of ["tasks"]
					}, -- end of ["params"]
				}, -- end of ["task"]
				["speed_locked"] = false,
			}, -- end of [2]
		}, -- end of ["points"]
	} -- end of ["route"]
	return route
end

function util.selectClosestAirfield(coa,enemyHexName)


	local closestDist = math.huge
	local hexToSpawnAt = ""
	ecw.hexInstances[enemyHexName]:findShortestPaths(ecw.hexInstances, 0, true, false)
	for hexName, hex in next, ecw.hexInstances do
		if ecw.hexInstances[enemyHexName].pathLengths[hexName] ~= nil then
			if ecw.hexInstances[enemyHexName].pathLengths[hexName] < closestDist and hex.poi["Airbase"] ~= nil and hex.coa == coa then
				if ecw.hexInstances[enemyHexName].pathLengths[hexName] >= pc.minimumSpawnDistance then
					hexToSpawnAt = hexName
					closestDist = ecw.hexInstances[enemyHexName].pathLengths[hexName]
				end
			end
		end
	end
	return hexToSpawnAt
end

function util.returnStaticTable(static,dead,hidden,...)

	local staticTable = {}
	staticTable.name = static:getName()
	staticTable.x = static:getPoint().x
	staticTable.y = static:getPoint().z
	staticTable.type = static:getTypeName()
	staticTable.heading = math.rad(util.staticHeading(static:getName()))
	staticTable.dead = dead
	staticTable.hidden = hidden
	staticTable.country = static:getCountry()
	
	if #arg > 0 then
		staticTable.x = arg[1]
		staticTable.y = arg[2]
		staticTable.name = arg[3]
	end
	
	return staticTable
end

function util.checkSpeed(unit)
	
	local vec3 = unit:getVelocity()
	local speed = math.sqrt((vec3.x^2) + (vec3.y^2) + (vec3.z^2))
	return speed
end

function util.eulerToRotationMatrix(roll,pitch,yaw)
		--[[
	Generate a full three-dimensional rotation matrix from euler angles
	 
	Input
	:param roll: The roll angle (radians)
	:param pitch: The pitch angle (radians)
	:param yaw: The yaw angle (radians)
	 
	Output
	:return: A 3x3 element matix containing the rotation matrix.
	 
		]]--
		
	--[[
  -                                                   -
            |   cq*cr               sq          sr*cq           |
            |                                                   |
            |   -sq*cr*cp-sr*sp     cq*cp       -sq*sr*cp+sp*cr |
            |                                                   |
            |   sq*sp*cr-sr*cp      -sp*cq      sq*sr*sp+cr*cp  |
            -                                                   -
	]]--
		-- First row of the rotation matrix
	local q,p,r = roll,pitch,yaw
		
	local x00 = math.cos(q) * math.cos(r)
	local x01 = math.sin(q)
	local x02 = math.sin(r) * math.cos(q)
		 
		-- Second row of the rotation matrix
	local y10 = -math.sin(q) * math.cos(r) * math.cos(p) - math.sin(r) * math.sin(p)
	local y11 = math.cos(q) * math.cos(p)
	local y12 = -math.sin(q) * math.sin(r) * math.cos(p) + math.sin(p) * math.cos(r)
		 
		-- Third row of the rotation matrix
	local z20 = math.sin(q) * math.sin(p) * math.cos(r) - math.sin(r) * math.cos(p)
	local z21 = -math.sin(p) * math.cos(q)
	local z22 = math.sin(q) * math.sin(r) + math.cos(r) * math.cos(p)
		 
		-- 3x3 rotation matrix
	local rot_matrix = {
		x = {
			x = x00, y = x01, z = x02
		},
		y = {
			x = y10, y = y11, z = y12
		},
		z = {
			x = z20, y = z21, z = z22
		}
	}

	return rot_matrix
end

function util.isDir(path)
	if (lfs.attributes(path, "mode") == "directory") then
		return true
	end
	return false
end

function util.isFile(path)
	local f=io.open(path,"r")
	if f~=nil then io.close(f) return true else return false end
end

function util.heading(unitName)

	local unit = Unit.getByName(unitName)
	if unit == nil then unit = StaticObject.getByName(unitName) end
	local unitPos = unit:getPosition()
	local headingRad = math.atan2( unitPos.x.z, unitPos.x.x )
 
	if headingRad < 0 then headingRad = headingRad + 2 * math.pi end

	return headingRad * 180 / math.pi
end

function util.staticHeading(unitName)

	local unit = 	StaticObject.getByName(unitName)
	local unitPos = unit:getPosition()
	local headingRad = math.atan2( unitPos.x.z, unitPos.x.x )
 
	if headingRad < 0 then headingRad = headingRad + 2 * math.pi end

	return headingRad * 180 / math.pi
end

function util.closestAirbase(unit)
	
	local closest, dist = {},math.huge
	
	for index, airbase in next, world.getAirbases() do
		if util.distance(unit,airbase) < dist then
			closest = airbase
			dist = util.distance(unit,airbase)
		end
	end
	
	return {base = closest, distance = dist}
end

function util.countList(list)
	local c = 0
	if list == nil then return 0 end
	for k,v in next, list do
		c = c + 1
	end
	return c
end

function util.addSubMenuForGroup(groupID,path,name,time)
	
	if util.groupCommands[groupID] == nil then util.groupCommands[groupID] = {} end
	
	local function addCommandForGroup(input)
		local table = missionCommands.addSubMenuForGroup(input[1],input[2],input[3])
		util.groupCommands[input[1]][input[3]] = table
	end
	
	timer.scheduleFunction(addCommandForGroup , {groupID,path,name} , time )
	return 
end

function util.addCommandForGroup(groupID,name,path,func,args,time)
	
	if util.groupCommands[groupID] == nil then util.groupCommands[groupID] = {} end
	
	local function addCommandForGroup(input)
		local index = missionCommands.addCommandForGroup(input[1],input[2],input[3],input[4],input[5])
		util.groupCommands[input[6]][input[2]] = index
	end
	
	timer.scheduleFunction(addCommandForGroup , {groupID,name,path,func,args,groupID} , time ) 
end

function util.returnPlatoonType(vec2)
	
	local surfaceType = land.getSurfaceType(vec2)
	
	if surfaceType ~= land.SurfaceType.SHALLOW_WATER and surfaceType ~= land.SurfaceType.WATER then
		return "land"
	else
		return "naval"
	end
	
end

function util.modifyWarMaterial(hexName,amount,modifier)
	local hex = ecw.hexInstances[hexName]
	
	hex.warMaterial = hex.warMaterial + (amount * modifier)
	--util.log("modifyWarMaterial",hexName,hex.warMaterial)
	return (amount * modifier)
end

function util.getPlayerInfo(unit)
	for k,player in next, net.get_player_list() do
		local playerName = net.get_player_info(player,'name')
		if unit:getPlayerName() == playerName then
			return net.get_player_info(player)
		end
	end
end

function util.getTheatre()

	if Airbase.getByName("Batumi") ~= nil then
		return "Caucasus"
	elseif Airbase.getByName("Nellis AFB") ~= nil then
		return "Nevada"
	elseif Airbase.getByName("Evreux") ~= nil then
		return "Normandy"
	elseif Airbase.getByName("Haifa") ~= nil then
		return "Syria"
	elseif Airbase.getByName("Khasab") ~= nil then
		return "Persian Gulf"
	end
end


function util.modifyLife(eI,type,mod)
	local ucid = util.getUcid(eI:getPlayerName())
	local typeDef
	if typeDefinitions[type] == nil then typeDef = "Standard" else typeDef = typeDefinitions[type] end
	local userString = ucid .. "_" .. typeDef
	local lives = trigger.misc.getUserFlag(userString)
	trigger.action.setUserFlag(userString, tonumber(tostring(lives)) + mod)
	local lives = trigger.misc.getUserFlag(userString)
	util.outTextForUnit(eI,5,"You have",lives,type,"lives remaining.")
end

local utilEventHandler = {}
util.hasCampaignCommand = {}

function utilEventHandler:onEvent(event)
	local eI
	if event.initiator ~= nil then eI = event.initiator end
	if event.initiator == nil then return end
	if eI == nil then return end
	
	if eI:getDesc().category ~= 0 and eI:getDesc().category ~= 1 then return end
	
	if world.event.S_EVENT_BIRTH == event.id then
        --landed/active reset
		if eI == nil then return end

		if eI.getPlayerName == nil then return end
		if eI:getPlayerName() == nil then return end
		local inFriendlyHex = ecw.findHexFromPoint(eI:getPoint(),ecw.hexInstances).coa == eI:getCoalition()
		
		if not inFriendlyHex then
			local playerID
			for k,player in next, net.get_player_list() do
				local playerInfo = net.get_player_info(player,'name')
				if eI:getPlayerName() == playerInfo then
					net.force_player_slot(net.get_player_info(player,'id'),0,0)
				end
			end
		end
		
        util.activeAC[eI:getName()] = false
        util.isLanded[eI:getName()] = true
		
		if util.hasCampaignCommand[eI:getName()] == nil then
			if ecwVersionToLoad == 1 then
				util.addCommandForGroup(eI:getGroup():getID(),"Campaign Overview",nil,util.displayCampaign,eI:getName(),timer.getTime()+6)
			elseif ecwVersionToLoad == 2 then
				util.addCommandForGroup(eI:getGroup():getID(),"Campaign Overview",nil,util.displayCampaign_v2,eI:getName(),timer.getTime()+6)
			end
			util.hasCampaignCommand[eI:getName()] = true
		end
		
		if debugger == true then
			util.outText(20,eI:getName(),"birth")
			util.outText(20,util.activeAC[eI:getName()], util.isLanded[eI:getName()])
		end
		return
	end

	if world.event.S_EVENT_TAKEOFF == event.id then 
        --landed/active reset
		util.isLanded[eI:getName()] = false
		local placeName = "the field"
		if event.place ~= nil then
			placeName = event.place:getName()
		end
		if util.activeAC[eI:getName()] ~= true then
			util.activeAC[eI:getName()] = true
			trigger.action.outTextForUnit(eI:getID() , "You have taken off from " .. placeName .. ".", 10 )
			if livesEnabled then util.modifyLife(eI,-1) end

			if ecwVersionToLoad == 2 then
				local weight = util.baseAttrition
				if util.aircraftWeights[event.initiator:getTypeName()] ~= nil then weight = util.aircraftWeights[event.initiator:getTypeName()] end
				local att = weight * util.attritionMultiplier

				if event.initiator:getCoalition() == 1 then
					redTE.attritionValue = redTE.attritionValue + att
				else
					blueTE.attritionValue = blueTE.attritionValue + att
				end
			end
		end
		if debugger == true then util.outText(20,eI:getName(),"takeoff") util.outText(20,util.activeAC[eI:getName()], util.isLanded[eI:getName()]) end
		return
	end

	if world.event.S_EVENT_LAND == event.id then
        --landed/active reset
		if eI == nil then return end
		util.isLanded[eI:getName()] = true
		if event.place ~= nil then
			if event.place:isExist() then
				if event.place.getCoalition ~= nil and Object.getCategory(event.place) == 4 then
					if util.activeAC[eI:getName()] == true and event.place:getCoalition() == eI:getCoalition() then
						util.activeAC[eI:getName()] = false
						trigger.action.outTextForUnit(eI:getID() , "You have landed at " .. event.place:getName() .. ".", 10 )
						if livesEnabled then util.modifyLife(eI,1) end

						if ecwVersionToLoad == 1 then 
							local att = util.modifyWarMaterial(ecw.airbaseHex[event.place:getName()],util.aircraftWeights[eI:getTypeName()] * util.attritionMultiplier, 1)
							ecw.hexInstances[ecw.airbaseHex[event.place:getName()]].usedAttritionWM = ecw.hexInstances[ecw.airbaseHex[event.place:getName()]].usedAttritionWM + att
						elseif ecwVersionToLoad == 2 then
							local weight = util.baseAttrition
							if util.aircraftWeights[event.initiator:getTypeName()] ~= nil then weight = util.aircraftWeights[event.initiator:getTypeName()] end
							local att = weight * util.attritionMultiplier
							
							if event.initiator:getCoalition() == 1 then
								redTE.attritionValue = redTE.attritionValue - att
							else
								blueTE.attritionValue = blueTE.attritionValue - att
							end
						end
					end
				end
			end
		elseif util.closestAirbase(eI).distance < 500 then
			local closestAirbase = util.closestAirbase(eI).base
			if util.activeAC[eI:getName()] == true and closestAirbase:getCoalition() == eI:getCoalition() then
				util.activeAC[eI:getName()] = false
				trigger.action.outTextForUnit(eI:getID() , "You have landed at " .. closestAirbase:getName() .. ".", 10 )
				if ecwVersionToLoad == 1 then
						
					local att = util.modifyWarMaterial(ecw.airbaseHex[closestAirbase:getName()],util.aircraftWeights[eI:getTypeName()] * util.attritionMultiplier, 1)
					ecw.hexInstances[ecw.airbaseHex[closestAirbase:getName()]].usedAttritionWM = ecw.hexInstances[ecw.airbaseHex[closestAirbase:getName()]].usedAttritionWM + att

				elseif ecwVersionToLoad == 2 then
					local weight = util.baseAttrition
					if util.aircraftWeights[event.initiator:getTypeName()] ~= nil then weight = util.aircraftWeights[event.initiator:getTypeName()] end
					local att = weight * util.attritionMultiplier
					if event.initiator:getCoalition() == 1 then
						redTE.attritionValue = redTE.attritionValue - att
					else
						blueTE.attritionValue = blueTE.attritionValue - att
					end
				end			
			end
		end
		if debugger == true then util.outText(20,eI:getName(),"landing") util.outText(20,util.activeAC[eI:getName()], util.isLanded[eI:getName()]) end
		return
	end
	return
end

function util.addUserPoints(name,points)
	
	if dcsbot then
		if dcsbot.addUserPoints then
			dcsbot.addUserPoints(name,points)										
			log.write("scripting", log.INFO, "util.addUserPoints: "..tostring(points).." added for "..name)
			return {name, points}
		else
			log.write("scripting", log.INFO, "util.addUserPoints: dcsbot.addUserPoints function missing!")
			return nil
		end
	else
		log.write("scripting", log.INFO, "util.addUserPoints: dcsbot table missing!")
		return nil
	end
end


function util.getUserPoints(name)
	
	if dcsbot then
		if dcsbot.getUserPoints then
			local points = dcsbot.getUserPoints(name)					
			log.write("scripting", log.INFO, "util.getUserPoints: got for "..name .. " " .. tostring(points))
			return {name, points}
		else
			log.write("scripting", log.INFO, "util.getUserPoints: dcsbot.getUserPoints function missing!")
			return nil
		end
	else
		log.write("scripting", log.INFO, "util.getUserPoints: dcsbot table missing!")
		return nil
	end

end

function util.ct(...)
	local outString = ""
	for s in ipairs(arg) do
		outString = outString .. " " .. tostring(arg[s])
	end
	return outString
end

function util.displayCampaign(unitName)
	local unit = Unit.getByName(unitName)
	if unit == nil then return end
	
	local blueFactories, blueDepots = {},{}
	local redFactories, redDepots = {},{}
	local s = "Campaign Overview:\n"
	
	local minutes = math.floor((te.nextTick - timer.getTime())/60)
	local seconds = math.fmod((te.nextTick - timer.getTime()),60)
	
	s = s .. "\nNext Tick: " .. string.format("%02d:%02d",minutes,seconds) .. "\n"
	
	for hexName,hex in next, ecw.hexInstances do
		if hex.poi["Factory"] ~= nil then
			if hex.coa == 1 then
				redFactories[hex.name] = infrastructure.instances[hex.poi["Factory"].name]
			elseif hex.coa == 2 then
				blueFactories[hex.name] = infrastructure.instances[hex.poi["Factory"].name]
			end
		end
		
		if hex.poi["Depot"] ~= nil then
			if hex.coa == 1 then
				redDepots[hex.name] = infrastructure.instances[hex.poi["Depot"].name]
			elseif hex.coa == 2 then
				blueDepots[hex.name] = infrastructure.instances[hex.poi["Depot"].name]
			end
		end
		
		
		

	end
	
	s = s .. "\nBlue:"
	
	for hexName,infraObject in next, blueFactories do
		s = s .. "\nFactory " .. hexName .. ": " .. tostring(100 - (util.round(100 * infraObject.ratio,1))) .. "%"
	end
	
	for hexName,infraObject in next, blueDepots do
		s = s .. "\nDepot " .. hexName .. ": " .. tostring(100 - (util.round(100 * infraObject.ratio,1))) .. "%"
	end
	
	s = s .. "\n\nRed:"
	
	for hexName,infraObject in next, redFactories do
		s = s .. "\nFactory " .. hexName .. ": " .. tostring(100 - (util.round(100 * infraObject.ratio,1))) .. "%"
	end
	
	for hexName,infraObject in next, redDepots do
		s = s .. "\nDepot " .. hexName .. ": " .. tostring(100 - (util.round(100 * infraObject.ratio,1))) .. "%"
	end
	
	s = s .. "\n\nSupply State:\n"
	
	s = s .. "\nBlue:\n"
	
	s = s .. "WM Manufactured: " .. tostring(math.floor(te.wmCreated[2])) .. "\n"
	s = s .. "WM Depot Distribution: " .. tostring(math.floor(te.wmDistributed[2])) .. "\n"
	s = s .. "WM Frontline Supply: " .. tostring(math.floor(te.wmReceived[2])) .. "\n"	
	
	s = s .. "\nRed:\n"
	
	s = s .. "WM Manufactured: " .. tostring(math.floor(te.wmCreated[1])) .. "\n"
	s = s .. "WM Depot Distribution: " .. tostring(math.floor(te.wmDistributed[1])) .. "\n"
	s = s .. "WM Frontline Supply: " .. tostring(math.floor(te.wmReceived[1])) .. "\n"	

	
	--[[14:59 until next tick

blue
factory 1-1: 100%
factor 2-1: 100%
factor 3-1: 100%
Depot 5-5 hP: 100%
Depot 5-5 hP: 100%
Depot 5-5 hP: 100%
infrasturcture hp: 50%

supply state
wm created: 100
wm distributed: 50
wm recieved: 25
]]--
	util.outTextForUnit(unit,25,s)
end

function util.percentageToASCII(percentage)

	local healthbar = "["

	for i = 1, 10 do
		local modulus = math.fmod(percentage, i * 10)
		if (i * 10) <= percentage then
			healthbar = healthbar .. "▰"
		elseif modulus > 0 and ((i * 10) - modulus) == percentage then
			healthbar = healthbar .. "◧"
		else
			healthbar = healthbar .. "▱"
		end
	end

	healthbar = healthbar .. "] "
	return healthbar
end


function util.displayCampaign_v2(unitName)
	local unit = Unit.getByName(unitName)
	if unit == nil then return end
	
	local blueFrontlines, redFrontlines = {},{}
	local blueFactories, blueDepots = {},{}
	local redFactories, redDepots = {},{}
	local s = "\nCampaign Overview:\n"

	local minutes = math.floor((te.nextTick - timer.getTime())/60)
	local seconds = math.fmod((te.nextTick - timer.getTime()),60)
	
	s = s .. "\nNext Tick: " .. string.format("%02d:%02d",minutes,seconds) .. ""
	


    local minutes = math.floor((te.serverRuntime - timer.getTime())/60)
	local seconds = math.fmod((te.serverRuntime - timer.getTime()),60)
	
	s = s .. "\nServer Reboot: " .. string.format("%02d:%02d",minutes,seconds) .. "\n"
	
	
	for hexName,hex in next, ecw.hexInstances do
		hexObject:auditInfrastructure()
		if hex.poi["Factory"] ~= nil then
			if hex.coa == 1 then
				redFactories[hex.name] = infrastructure.instances[hex.poi["Factory"].name]
			elseif hex.coa == 2 then
				blueFactories[hex.name] = infrastructure.instances[hex.poi["Factory"].name]
			end
		end
		
		if hex.poi["Depot"] ~= nil then
			if hex.coa == 1 then
				redDepots[hex.name] = infrastructure.instances[hex.poi["Depot"].name]
			elseif hex.coa == 2 then
				blueDepots[hex.name] = infrastructure.instances[hex.poi["Depot"].name]
			end
		end

		for enum, neighbor in next, hex.neighbors do
			if neighbor.coa ~= hex.coa and neighbor.coa ~= 0 then
				if hex.coa == 1 then
					redFrontlines[hex.name] = true
				elseif hex.coa == 2 then
					blueFrontlines[hex.name] = true
				end
				break
			end
		end
	end
	
	depotHealth[1],depotHealth[2] = 0,0
	factoryHealth[1],factoryHealth[2] = 0,0
	infrastructureHealth[1],infrastructureHealth[2] = 0,0

	local depotCount = {}
	local factoryCount = {}
	local infrastructureCount = {}
	depotCount[1],depotCount[2] = 0,0
	factoryCount[1],factoryCount[2] = 0,0
	infrastructureCount[1],infrastructureCount[2] = 0,0

	for hexName, hex in next, ecw.hexInstances do
		hex:auditInfrastructure()
		hex:auditAASpawnpoints()
		hex:auditAirbaseOwnership()
		hex:resetLineTypes()
		hex:resetPriorityMarker()
		hex:updateHealthBar("pls delete")
		depotHealth[hex.coa] = depotHealth[hex.coa] + (hex.depotHealth - 1)
		factoryHealth[hex.coa] = factoryHealth[hex.coa] + (hex.factoryHealth - 1)
		infrastructureHealth[hex.coa] = infrastructureHealth[hex.coa] + (hex.pathModifier - 1)

		if hex.poi["Depot"] ~= nil then depotCount[hex.coa] = depotCount[hex.coa] + 1 end
		if hex.poi["Factory"] ~= nil then factoryCount[hex.coa] = factoryCount[hex.coa] + 1 end
		infrastructureCount[hex.coa] = infrastructureCount[hex.coa] + util.countList(hex.infrastructureObjects)
	end

	
	local strengthList = {}
	strengthList[0] = 0
	strengthList[1] = 0
	strengthList[2] = 0
	--compute strength for each side
	for hexName, hex in next, ecw.hexInstances do
		hex.usableWarMaterial = 0
		local friendlyCount = 0
		for enum, neighbor in next, hex.neighbors do
			if hex.groups[enum] ~= nil then
				for triggerName, group in next, hex.groups[enum] do
					if group:isExist() then
						friendlyCount = friendlyCount + (group:getSize()/group:getInitialSize())
					else
						hex.groups[enum][triggerName] = nil
					end
				end
			end
		end
		strengthList[hex.coa] = strengthList[hex.coa] + friendlyCount
		trigger.action.setUserFlag(hex.name .. "_HP" , math.floor((friendlyCount / hex.spawnedPlatoonCount) * 100) )
	end

	--get winner
	local winner,loser = 0,0
	if strengthList[1] > strengthList[2] then
		winner,loser = 1,2
	elseif strengthList[2] > strengthList[1] then
		winner,loser = 2,1
	end

	local hexesToFlip = {}
	for hexName, hex in next, ecw.hexInstances do
		local distTable = hex:findShortestPaths(ecw.hexInstances, 0, false, false)
		local isSurrounded = true
		local isFrontline = false

		for enum, neighbor in next, hex.neighbors do
			if hex.coa == neighbor.coa then
				isSurrounded = false
			else
				isFrontline = true
			end
		end
		local hasFactoryConnection = false
		for hexName, distance in next, distTable do
			if ecw.hexInstances[hexName].poi["Factory"] ~= nil then
				hasFactoryConnection = true
			end
		end

		if not hasFactoryConnection then isSurrounded = true isFrontline = true end

		if isFrontline and isSurrounded then
			for enum, neighbor in next, hex.neighbors do
				if hex.groups[enum] ~= nil then
					for triggerName, group in next, hex.groups[enum] do
						group:destroy()
						hex.groups[enum][triggerName] = nil
					end
				end
			end
			--Campaign_log:info("surrounded",util.ct(hexName, "flipped due to being surrounded"))
			hexesToFlip[hex.name] = true
			local somethingFlipped = true
		end
	end


	local numberToCapture = 0

	local teWinner, teLoser
	if winner == 1 then teWinner = redTE teLoser = blueTE else teWinner = blueTE teLoser = redTE end

	local function checkZero(health, count, percentage)
		if count == 0 then return 0 end
		return (health / count) * percentage
	end

	local totals = te.frontlinePercentage + te.depotPercentage + te.factoryPercentage + te.infrastructurePercentage
	local frontlinePercentage = te.frontlinePercentage/totals
	local depotPercentage = te.depotPercentage/totals
	local factoryPercentage = te.factoryPercentage/totals
	local infrastructurePercentage = te.infrastructurePercentage/totals

	local redFrontline = (1 - ( strengthList[1] /te.initialPlatoonCount )) * frontlinePercentage
	trigger.action.setUserFlag("RED_FRNT", math.ceil(1000 - (redFrontline * 1000),2))
	local redDepots =  checkZero(depotHealth[1], depotCount[1], depotPercentage)
	trigger.action.setUserFlag("RED_DEPT", math.ceil(1000 - (redDepots * 1000),2))
	local redFactories = checkZero(factoryHealth[1], factoryCount[1], factoryPercentage)
	trigger.action.setUserFlag("RED_FACT", math.ceil(1000 - (redFactories * 1000)))
	local redInfrastructure = checkZero(infrastructureHealth[1], infrastructureCount[1], infrastructurePercentage)
	trigger.action.setUserFlag("RED_INFR", math.ceil(1000 - (redInfrastructure * 1000)))

	local blueFrontline = (1 - ( strengthList[2] /te.initialPlatoonCount )) * frontlinePercentage
	trigger.action.setUserFlag("BLUE_FRNT", math.ceil(1000 - (blueFrontline * 1000)))
	local blueDepots = checkZero(depotHealth[2], depotCount[2], depotPercentage)
	trigger.action.setUserFlag("BLUE_DEPT", math.ceil(1000 - (blueDepots * 1000)))
	local blueFactories = checkZero(factoryHealth[2], factoryCount[2], factoryPercentage)
	trigger.action.setUserFlag("BLUE_FACT", math.ceil(1000 - (blueFactories * 1000)))
	local blueInfrastructure = checkZero(infrastructureHealth[2], infrastructureCount[2], infrastructurePercentage)
	trigger.action.setUserFlag("BLUE_INFR", math.ceil(1000 - (blueInfrastructure * 1000)))
	local redTotal = util.round(1000 - ((redFrontline + redDepots + redFactories + redInfrastructure) * 1000), 1)
	local blueTotal = util.round(1000 - ((blueFrontline + blueDepots + blueFactories + blueInfrastructure) * 1000), 1)

	local teWinner, teLoser
	local attritionDiff = 0
	if redTotal > blueTotal then teWinner = redTE teLoser = blueTE elseif redTotal < blueTotal then teWinner = blueTE teLoser = redTE end
	if teWinner ~= nil then
		attritionDiff = teWinner.attritionValue - teLoser.attritionValue
	end
	if attritionDiff < 0 then attritionDiff = 0 end

	local variance = 0
	if redTotal > blueTotal then variance = redTotal - blueTotal end
	if blueTotal > redTotal then variance = blueTotal - redTotal end
	numberToCapture = variance / ((te.variancePercentageRequired + (attritionDiff * te.attritionCaptureModifier)) * 1000)

    s = s .. "\n--------------- "
	s = s .. "\nRed Total Health: " .. tostring(redTotal) .. "/" .. tostring(1000)
	s = s .. "\nRed Frontline Health: " .. tostring(util.round(frontlinePercentage * 1000 - (redFrontline * 1000),2)) .. "/" .. tostring(frontlinePercentage * 1000)
	s = s .. "\nRed Depot Health: " .. tostring(util.round(depotPercentage * 1000 - (redDepots * 1000),2)) .. "/" .. tostring(depotPercentage * 1000)
	s = s .. "\nRed Factory Health: " .. tostring(util.round(factoryPercentage * 1000 - (redFactories * 1000),2)) .. "/" .. tostring(factoryPercentage * 1000)
	s = s .. "\nRed Infrastructure Health: " .. tostring(util.round(infrastructurePercentage * 1000 - (redInfrastructure * 1000),2)) .. "/" .. tostring(infrastructurePercentage * 1000)
    s = s .. "\n--------------- "
	s = s .. "\nBlue Total Health: " .. tostring(blueTotal) .. "/" .. tostring(1000)
	s = s .. "\nBlue Frontline Health: " .. tostring(util.round(frontlinePercentage * 1000 - (blueFrontline * 1000),2)) .. "/" .. tostring(frontlinePercentage * 1000)
	s = s .. "\nBlue Depot Health: " .. tostring(util.round(depotPercentage * 1000 - (blueDepots * 1000),2)) .. "/" .. tostring(depotPercentage * 1000)
	s = s .. "\nBlue Factory Health: " .. tostring(util.round(factoryPercentage * 1000 - (blueFactories * 1000),2)) .. "/" .. tostring(factoryPercentage * 1000)
	s = s .. "\nBlue Infrastructure Health: " .. tostring(util.round(infrastructurePercentage * 1000 - (blueInfrastructure * 1000),2)) .. "/" .. tostring(infrastructurePercentage * 1000)
    s = s .. "\n--------------- "
	local t = "\n"
	if redTotal > blueTotal then  t = "Red " elseif blueTotal > redTotal then t = "Blue " end
	s = s .. "\n\nAirframe Attrition: "
	s = s .. "\nRED:  " .. tostring(util.round(redTE.attritionValue,2))
    s = s .. "\nBLUE: " .. tostring(util.round(blueTE.attritionValue,2))
    s = s .. "\nDifference required to capture: " .. tostring(util.round((te.variancePercentageRequired + (attritionDiff * te.attritionCaptureModifier)) * 1000,2))
	s = s .. "\n" .. t .. "Leading. Current Difference: " ..tostring(math.floor(variance))
	s = s .. "\n" .. t .. "Capture Amount: " .. tostring(math.floor(numberToCapture))


    s = s .. "\n\nRandomly Repaired Factories/Depots/Infrastructure at Server Reboot: " .. tostring(util.round(te.repairAmount)) ..""


	util.outTextForUnit(unit,25,s)
end

world.addEventHandler(utilEventHandler)

function util.getDigit(num, digit)
	local n = 10 ^ digit
	local n1 = 10 ^ (digit - 1)
	return math.floor((num % n) / n1)
end
