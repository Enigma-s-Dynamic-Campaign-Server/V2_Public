--[[
	V2
]]--

local stringToBoolean = { ["true"] = true, ["false"] = false }
local flipMarker = 9564067

hexObject = {}

ecw.hexInstances = {}

ecw.coaEnums = {}
ecw.coaEnums[1] = "RED"
ecw.coaEnums[2] = "BLUE"
ecw.healthBarID = 400000000

ecw.countryEnums = {}
ecw.countryEnums[1] = country.id.RUSSIA
ecw.countryEnums[2] = country.id.USA

ecw.oppositeCoa = {}
ecw.oppositeCoa[1] = 2
ecw.oppositeCoa[2] = 1

ecw.priorityMarkers = {}
ecw.priorityMarkers[1] = {}
ecw.priorityMarkers[2] = {}
ecw.priorityMarkers[3] = {}

ecw.sideEnumerators = {}
ecw.sideEnumerators["TOPLEFT"] = 1
ecw.sideEnumerators["TOPRIGHT"] = 2
ecw.sideEnumerators["LEFT"] = 3
ecw.sideEnumerators["RIGHT"] = 4
ecw.sideEnumerators["BOTTOMLEFT"] = 5
ecw.sideEnumerators["BOTTOMRIGHT"] = 6
ecw.sideEnumerators[1] = "TOPLEFT"
ecw.sideEnumerators[2] = "TOPRIGHT"
ecw.sideEnumerators[3] = "LEFT"
ecw.sideEnumerators[4] = "RIGHT"
ecw.sideEnumerators[5] = "BOTTOMLEFT"
ecw.sideEnumerators[6] = "BOTTOMRIGHT"

ecw.shortenedEnum = {}
ecw.shortenedEnum["TOPLEFT"] = "TL"
ecw.shortenedEnum["TOPRIGHT"] = "TR"
ecw.shortenedEnum["LEFT"] = " L"
ecw.shortenedEnum["RIGHT"] = " R"
ecw.shortenedEnum["BOTTOMLEFT"] = "BL"
ecw.shortenedEnum["BOTTOMRIGHT"] = "BR"

ecw.oppositeEnum = {}
ecw.oppositeEnum["TOPLEFT"] = "BOTTOMRIGHT"
ecw.oppositeEnum["TOPRIGHT"] = "BOTTOMLEFT"
ecw.oppositeEnum["LEFT"] = "RIGHT"
ecw.oppositeEnum["RIGHT"] = "LEFT"
ecw.oppositeEnum["BOTTOMLEFT"] = "TOPRIGHT"
ecw.oppositeEnum["BOTTOMRIGHT"] = "TOPLEFT"

ecw.airbaseHex = {}

local flipped = 0

local dir = lfs.writedir() .. "/ColdWar/"
ecw.startInit = true
ecw.loadFromPersistence = false
local f = io.open(dir .. ".startInit","r")
local s = f:read("*all")
f:close()

if s == "false" then
	ecw.startInit = false
end

f = io.open(dir .. ".loadFromPersistence","r")
s = f:read("*all")
f:close()

if s ~= "" then ecw.loadFromPersistence = stringToBoolean[s] end

--Campaign_log:info("startInit",util.ct(ecw.startInit))
--Campaign_log:info("loadFromPersistence",util.ct(ecw.loadFromPersistence))


trigger.action.markToAll(696969 , tostring(flipped) , {x = 0, y = 0 , z = 0} , true)

function ChangeFlippedMarkerText()
	flipped = flipped + 1
	trigger.action.setMarkupText(696969, tostring(flipped) )
end

function hexObject:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

function ecw.createHexInstance(name, indices, origin, points, color)
	local instance = hexObject:new()
	ecw.hexInstances[name] = instance

	instance.name = name
	instance.x = tonumber(util.split(util.split(name," ")[2],"-")[2])
	instance.y = tonumber(util.split(util.split(name," ")[2],"-")[1])
	instance.neighbors = {}
	instance.indices = indices
	instance.origin = origin
	instance.points = points
	instance.type = "NOTHING"
	instance.poi = {}
	instance.pathModifier = 1
	instance.pathLengths = {}
	instance.coa = 0
	instance.markerIndex = 0
	instance.frontlineSides = {}
	instance.factoryHealth = 1
	instance.lastAttritionTick = 0
	instance.healthBar = -2
	instance.distanceFromFrontline = -1
	instance.depotHealth = 1
	instance.trueDistancePaths = {}
	instance.priorityMarker = -1
	instance.factoryToDepotPaths = {}
	instance.depotToFrontlinepaths = {}
	instance.healthPercentage = 1
	instance.color = color
	instance.ewr = nil
	local blueColorString = "0x0000ffff"
	local redColorString  = "0xff0000ff"
	instance.initCoa = 0
	if instance.color == blueColorString then instance.initCoa = 2 end
	if instance.color == redColorString then instance.initCoa = 1 end

	instance.isWinCondition = false

	instance.spawnPoints = {}
	instance.aaSpawnPoints = {}
	instance.farpSpawnPoints = {}
	instance.groups = {}
	instance.aaGroups = {}
	instance.farpGroups = {}
	for k,v in next, ecw.shortenedEnum do
		instance.groups[k] = {}
	end

	instance.airfields = {}

	instance.infrastructureObjects = {}
	instance.depotObjects = {}
	instance.factoryObjects = {}

	instance.strategicValue = 0
	instance.frontlineStrategicValue = 0
	instance.reinforcementStrategicValue = 0
	instance.strategicPaths = {}
	instance.airfieldSourceDepot = {}
	instance.spawnedPlatoonCount = 0

	instance.factoryOutput = 0
	instance.warMaterial = 0
	instance.usableWarMaterial = 40
	instance.usedAttritionWM = 0

	return instance
end


---------------------------------------------------------------------------------------------------------------------------------hexObject function definitions

function hexObject:defineNeighbors()

	local name = self.name
	local x,y = self.x, self.y
	local mX,mY
	self.neighbors = {}

	for i = 1, 6 do self.neighbors[ecw.sideEnumerators[i]] = nil end

	--top left
	mX, mY = x - 1 , y - 1
	for names, instance in next, ecw.hexInstances do
		if mX == instance.x and mY == instance.y and instance.coa ~= 0 then self.neighbors["TOPLEFT"] = instance break end
	end

	--top right
	mX, mY = x + 1 , y - 1
	for names, instance in next, ecw.hexInstances do
		if mX == instance.x and mY == instance.y and instance.coa ~= 0 then self.neighbors["TOPRIGHT"] = instance break end
	end

	--left
	mX, mY = x - 2 , y
	for names, instance in next, ecw.hexInstances do
		if mX == instance.x and mY == instance.y  and instance.coa ~= 0 then self.neighbors["LEFT"] = instance break end
	end

	--right
	mX, mY = x + 2 , y
	for names, instance in next, ecw.hexInstances do
		if mX == instance.x and mY == instance.y and instance.coa ~= 0 then self.neighbors["RIGHT"] = instance break end
	end

	--bottom left
	mX, mY = x - 1 , y + 1
	for names, instance in next, ecw.hexInstances do
		if mX == instance.x and mY == instance.y and instance.coa ~= 0 then self.neighbors["BOTTOMLEFT"] = instance break end
	end

	--bottom right
	mX, mY = x + 1 , y + 1
	for names, instance in next, ecw.hexInstances do
		if mX == instance.x and mY == instance.y and instance.coa ~= 0 then self.neighbors["BOTTOMRIGHT"] = instance break end
	end

	return
end

function hexObject:assignDepotToAirfield()

	if self.poi["Airbase"] == nil then return end

	local dist,closestDepotHex = math.huge,self
	for hexName, pathLength in next, self.pathLengths do
		if ecw.hexInstances[hexName].poi["Depot"] ~= nil then
			if pathLength < dist then
				self.airfieldSourceDepot = ecw.hexInstances[hexName]
				dist = pathLength
			end
		end
	end
	util.log("assignDepotToAirfield",self.name,self.coa,"assigned",self.airfieldSourceDepot.name,self.airfieldSourceDepot.coa)
	return self.airfieldSourceDepot
end


function hexObject:findShortestPaths(hexList, trueDistanceModifier, includeEnemy, includeNeutral)

	local hexLengthTable = {}
	local hexPathTable = {}
	local visitedHexes = {}
	local unvisitedHexes = hexList
	local hex, nextHex
	local count = 0

	for k,v in next, hexList do
		hexLengthTable[k] = nil
		count = count + 1
	end

	hexLengthTable[self.name] = self.pathModifier * trueDistanceModifier

	for index = 0, count do

		local lowestValue = math.huge

		for k, v in next, hexLengthTable do
			if type(v) == 'number' and visitedHexes[k] ~= true and ((self.coa == hexList[k].coa) or includeEnemy) and ((hexList[k].coa ~= 0) or includeNeutral) then
				if v < lowestValue then
					lowestValue = v
					nextHex = k
					break
				end
			end
		end

		if hexList[nextHex] ~= nil then
			local t = ecw.findPaths(hexList[nextHex], trueDistanceModifier, includeEnemy, includeNeutral)
			local pathLengths = t.pl

			for k, v in next, pathLengths do
				if visitedHexes[k] ~= true then
					if hexLengthTable[k] == nil then
						hexLengthTable[k] = hexLengthTable[hexList[nextHex].name] + v
						hexPathTable[k] = {}
					elseif hexLengthTable[k] > (v + hexLengthTable[hexList[nextHex].name]) then
						hexLengthTable[k] = (v + hexLengthTable[hexList[nextHex].name])
					end
				end
			end
			visitedHexes[hexList[nextHex].name] = true
		end
	end
	--[[
	for k,v in next, hexLengthTable do
		break
		util.log("DEBUG1",tostring(k) .. " " .. tostring(v))
	end
	]]--
	self.pathLengths = hexLengthTable --table of hexName, distance
	if trueDistanceModifier == 0 then self.trueDistancePaths = hexLengthTable end
	return hexLengthTable

end

function hexObject:findFrontlineSides()

	self.frontlineSides = {}

	for neighborSide, neighborHex in next, self.neighbors do
		if neighborHex.coa ~= self.coa then
			table.insert(self.frontlineSides,neighborSide)
		end
	end
end

function hexObject:calculateStrategicValue()

	self.strategicValue = 1


	if self.poi["Infrastructure"] ~= nil then
		self.strategicValue = self.strategicValue + 1
	end

	-- depots

	if self.poi["Depot"] ~= nil then
		self.strategicValue = self.strategicValue + 1
		self.depotHealth = 1
	end

	-- airfields

	if self.poi["Airbase"] ~= nil then
		self.strategicValue = self.strategicValue + 1
	end
	-- harbors?

	if self.poi["Harbor"] ~= nil then
		self.strategicValue = self.strategicValue + 1
	end

	if self.poi["Factory"] ~= nil then
		self.strategicValue = self.strategicValue + 1
		self.factoryHealth = 1
	end

	-- surrounded?
	return self.strategicValue
end

function hexObject:auditInfrastructure()

	if self.infrastructureObjects ~= nil then
		for triggerName, infraObject in next, self.infrastructureObjects do
			self.pathModifier = 1 + (infraObject:audit() * (infrastructure.defaultHexHit)) --adds infrastructure damages based on the number of targets destroyed to
			if self.pathModifier > 1 then util.log("pathModifier",self.name,self.pathModifier) end
		end
	end
	if self.depotObjects ~= nil then
		for triggerName, depotObject in next, self.depotObjects do
			self.depotHealth = 1 + (depotObject:audit() * (infrastructure.defaultHexHit)) --adds infrastructure damages based on the number of targets destroyed to 
			if self.depotHealth > 1 then util.log("depotHealth",self.name,self.depotHealth) end
		end
	end
	if self.factoryObjects ~= nil then
		for triggerName, factoryObject in next, self.factoryObjects do
			self.factoryHealth = 1 + (factoryObject:audit() * (infrastructure.defaultHexHit)) --adds infrastructure damages based on the number of targets destroyed to 
			if self.factoryHealth > 1 then util.log("factoryHealth",self.name,self.factoryHealth) end
		end
	end
	return {self.pathModifier,self.depotHealth,self.factoryHealth}
end


function hexObject:findPlatoonSpawnpoints(...)
	if arg[1] ~= nil then local side = arg[1] end

	self.spawnPoints = {}
	for enum, neighbor in next, self.neighbors do
		self.spawnPoints[enum] = {}
	end

	for index, triggerTable in next, env.mission.triggers.zones do
		if triggerTable.name:find("Platoon") ~= nil then

			for enum,neighbor in next, self.neighbors do

				if triggerTable.name:find(ecw.shortenedEnum[enum]) ~= nil then

					local tempCoords = {x = triggerTable.x, z = triggerTable.y, y = 0}
					local isInHex = ecw.pointInsideHex(tempCoords,self)

					if isInHex == true then
						self.spawnPoints[enum][triggerTable.name] = triggerTable
						util.log("find platoon spawnPoint",self.name,triggerTable.name)
					end
				end
			end

		elseif triggerTable.name:find("SAM") ~= nil then

			local tempCoords = {x = triggerTable.x, z = triggerTable.y, y = 0}
			local isInHex = ecw.pointInsideHex(tempCoords,self)
			if isInHex == true then
				self.aaSpawnPoints[triggerTable.name] = triggerTable
				util.log("find aa spawnPoint",self.name,triggerTable.name)
			end
		elseif triggerTable.name:find("FARP") ~= nil  then

			local tempCoords = {x = triggerTable.x, z = triggerTable.y, y = 0}
			local isInHex = ecw.pointInsideHex(tempCoords,self)
			if isInHex == true then
				self.farpSpawnPoints[triggerTable.name] = triggerTable
				util.log("find farp spawnPoint",self.name,triggerTable.name)
			end
		end
	end

	return self.spawnPoints
end

function hexObject:auditSpawnpoints()
	local count = 0
	for enum, neighbor in next, self.neighbors do
		for triggerName, platoon in next, self.groups[enum] do
			if platoon:isExist() then
				if platoon:getSize() <= 0 then
					self.groups[enum][triggerName] = nil
					util.log("audit",platoon:getName(),"in",self.name, "is at 0 units. dereferenced.")
				else
					count = count + 1
				end

				if platoon:getCoalition() ~= self.coa then
					self.groups[enum][triggerName] = nil
					platoon:destroy()
				end
			end
		end
	end
	return count
end

function hexObject:auditAASpawnpoints()
	local count = 0
	for triggerName, triggerTable in next, self.aaSpawnPoints do
		local platoon = self.aaGroups[triggerName]
		if self.aaGroups[triggerName] ~= nil then
			if self.aaGroups[triggerName]:isExist() then
				if self.aaGroups[triggerName]:getSize() > 0 then
					if self.aaSpawnPoints[triggerName] ~= nil then
						self.aaSpawnPoints[triggerName].currentCount = self.aaGroups[triggerName]:getSize()
					else
						self.aaGroups[triggerName] = nil
					end
				end
			end
		end
	end
	if count > 0 then
		util.log("audit aa",self.name,"active aa:",count)
	end
	return count
end


function hexObject:spawnFarpGroup()
	local count = 0

	local SetImmortal = {
		id = 'SetImmortal',
		params = {
			value = true
		}
	}

	for triggerName, triggerTable in next, self.farpSpawnPoints do
		for groupName,group in next, self.farpGroups do
			if group ~= nil then
				if group:isExist() then
					group:destroy()
				end
			end
		end
	end

	for triggerName, triggerTable in next, self.farpSpawnPoints do
		local group = util.spawnUnitTemplate(te.farpGroup[self.coa], self.coa,{x = triggerTable.x, z = triggerTable.y, y = 0})
		group:getController():setCommand(SetImmortal)
		self.farpGroups[group:getName()] = group
	end

	return count
end

function hexObject:spawnAA()

	local spawnAmount = 2 - self:auditAASpawnpoints()
	local shortestToFrontlineHex = 200
	local isFrontline = false
	--length to frontline, spawn based on that self.trueDistancePaths
	if util.countList(self.aaSpawnPoints) <= 0 then return end

	self:findShortestPaths(ecw.hexInstances, 0, false, false)

	for hexName,distance in next, self.trueDistancePaths do
		--util.log("spawnAA dist:",self.name,hexName,distance)
		for enum,neighbor in next, ecw.hexInstances[hexName].neighbors do
			if neighbor.coa ~= self.coa then
				--util.log("spawnAA compare:",shortestToFrontlineHex,distance,distance < shortestToFrontlineHex)
				if distance < shortestToFrontlineHex then
					shortestToFrontlineHex = distance
					--util.log("spawnAA compare:",shortestToFrontlineHex,distance,"| set:",hexName,"to",shortestToFrontlineHex)
				end
			end
		end
	end
	if shortestToFrontlineHex >= 200 then util.log("aa exit",self.name,shortestToFrontlineHex) return end
	for triggerName, triggerTable in next, self.aaSpawnPoints do
		if self.aaGroups[triggerName] ~= nil then self.aaGroups[triggerName]:destroy() end
		local newGroup = util.spawnUnitTemplate(te.selectAATemplate(self.coa,shortestToFrontlineHex), self.coa, trigger.misc.getZone(triggerName).point)
		self.aaGroups[triggerName] = newGroup
	end
	self:auditAASpawnpoints()
	if shortestToFrontlineHex < 200 then util.log("aa Spawning",spawnAmount, "aa spawned at",self.name,"| distance:",shortestToFrontlineHex,"| type:", te.selectAATemplate(self.coa,shortestToFrontlineHex):getName()) end
	return spawnAmount -- will return 0 if all spawned successfully, positive integer if some didnt spawn
end

function hexObject:spawnPlatoonOnDelay(platoonToSpawn, coa, positionTable,enum,triggerName,time,modifier)
	if self.coa == coa then timer.scheduleFunction(util.spawnUnitTemplateTimed , {platoonToSpawn, coa, positionTable, self, enum, triggerName, modifier} , time ) end
end


function hexObject:spawnPlatoons(spawnAmount, templates, enums, modifier) -- randomize placement

	if spawnAmount == nil then spawnAmount = 0 end

	self:auditSpawnpoints()
	local platoonToSpawn, spawnedPlatoon, enum
	local initialAmount = spawnAmount
	local enumSpawnTable = {}

	if util.countList(enums) <= 0 then return spawnAmount end

	for k,enum in next, enums do
		if self.neighbors[enum] ~= nil then
			if self.neighbors[enum].coa ~= self.coa then
				for triggerName, triggerTable in next, self.spawnPoints[enum] do
					triggerTable["enum"] = enum
					table.insert(enumSpawnTable, triggerTable)
				end
			end
		end
	end
	enumSpawnTable = util.shuffle(enumSpawnTable)

	for index, triggerTable in next, enumSpawnTable do
		if spawnAmount <= 0 then break end
		enum = triggerTable["enum"]
		if self.groups[enum][triggerTable.name] == nil then
			self:spawnPlatoonOnDelay(templates[(util.returnPlatoonType({x = triggerTable.x, y = triggerTable.y}))][math.random(util.countList(templates[(util.returnPlatoonType({x = triggerTable.x, y = triggerTable.y}))]))], self.coa, {x = triggerTable.x, z = triggerTable.y, y = 0},enum,triggerTable.name,timer.getTime() + 1 + spawnAmount, modifier)
			spawnAmount = spawnAmount - 1
		end
	end
	util.log("platoon Spawning", initialAmount - spawnAmount, ecw.coaEnums[self.coa], "Platoons spawned at",self.name,"| unspawned amount:",spawnAmount)
	return spawnAmount -- will return 0 if all spawned successfully, positive integer if some didnt spawn
end

function hexObject:generateWarMaterial(amount)
	self.warMaterial = self.warMaterial + amount
	return self.warMaterial
end

function hexObject:frontlineHexSupplyRequest(hexList)

	local supplyRequest = {}

	local hexLengthTable = self:findShortestPaths(hexList, 1, false, false)

	local closestDepot
	local depots = {}
	local dist = 20

	for name, length in next, hexLengthTable do
		if hexList[name].coa == self.coa then
			if hexList[name].poi["Depot"] ~= nil then
				depots[name] = length
				closestDepot = name
			end
		end
	end

	for name, length in next, depots do
		if length <= depots[closestDepot] then
			closestDepot = name
			dist = length
		end
	end



	supplyRequest["hex"] = self.name
	supplyRequest["depot"] = closestDepot
	supplyRequest["infraModifier"] = dist


	if closestDepot ~= nil then
		hexList[closestDepot]:auditInfrastructure()
	end

	return supplyRequest
end

function hexObject:reclaimSpawnpoints()
	return
end

function hexObject:applyAttrition()

	local attritionTable = {}
	local oppositeSide, ratio, difference, total
	local friendlyCount, enemyCount = 1,1
	self:auditSpawnpoints()

	for enum, neighbor in next, self.neighbors do
		if neighbor.coa ~= self.coa and neighbor ~= nil and neighbor.coa ~= 0 then
			neighbor:auditSpawnpoints()
			oppositeSide = ecw.oppositeEnum[enum]

			if self.groups[enum] ~= nil then
				for triggerName, group in next, self.groups[enum] do
					if group:isExist() then
						friendlyCount = friendlyCount + (group:getSize()/group:getInitialSize())
					else
						self.groups[enum][triggerName] = nil
					end
				end
			end

			if neighbor.groups[oppositeSide] then
				for triggerName, group in next, neighbor.groups[oppositeSide] do
					if group:isExist() then
						enemyCount = enemyCount + (group:getSize()/group:getInitialSize())
					else
						neighbor.groups[oppositeSide][triggerName] = nil
					end
				end
			end
		end
	end

	ratio = enemyCount / friendlyCount

	self.usableWarMaterial = self.usableWarMaterial - (ratio * ecw.attritionBaseValue)
	self.lastAttritionTick = (ratio * ecw.attritionBaseValue)
	return
end

local function flipMarkerIncrement()
	trigger.action.removeMark(flipMarker)
	flipMarker = flipMarker + 1
	trigger.action.markToAll(flipMarker,"-=hexflipped=-", {0,0,0} , true)
	util.log("flipMarker",flipMarker)
end

function hexObject:flipOwner(newWarMaterial, ...)
	local uwm = self.usableWarMaterial
	local tempTable,friendlyGroupTable, enemyGroupTable = {},{},{}
	local enemyCounter, friendlyCounter = 0,0
	if uwm < 0 then

		self:auditSpawnpoints()

		for k,v in next, self.infrastructureObjects do
			recon.removeMarkersInfra(v)
		end

		for k,v in next, self.depotObjects do
			recon.removeMarkersInfra(v)
		end

		for k,v in next, self.factoryObjects do
			recon.removeMarkersInfra(v)
		end

		for triggerName,group in next, self.aaGroups do
			recon.removeMarkersAA(group)
		end

		for enum, neighbor in next, self.neighbors do
			for triggerName, platoon in next, self.groups[enum] do
				friendlyGroupTable[triggerName] = platoon
				friendlyCounter = friendlyCounter + 1
				recon.removeMarkersGroup(self.groups[enum][triggerName])
				if platoon:isExist() then
					self.groups[enum][triggerName]:destroy()
				end
				self.groups[enum][triggerName] = nil
			end
		end
		if arg[1] == nil then
			if friendlyCounter < 10 then friendlyCounter = 10 end
		end

		for enum, neighbor in next, self.neighbors do
			if neighbor.coa ~= self.coa then
				neighbor:auditSpawnpoints()
				for triggerName, platoon in next, neighbor.groups[ecw.oppositeEnum[enum]] do
					enemyGroupTable[triggerName] = platoon
					enemyCounter = enemyCounter + 1
					recon.removeMarkersGroup(self.groups[enum][triggerName])
					if platoon:isExist() then
						neighbor.groups[ecw.oppositeEnum[enum]][triggerName]:destroy()
					end
					neighbor.groups[ecw.oppositeEnum[enum]][triggerName] = nil
				end
			end
		end
		if arg[1] == nil then
			if enemyCounter < 12 then enemyCounter = 12 end
		end

		for k,v in next, self.infrastructureObjects do
			v:repair()
		end
		for k,v in next, self.depotObjects do
			v:repair()

		end
		for k,v in next, self.factoryObjects do
			v:repair()
		end

		if self.coa == 1 then self.coa = 2 elseif self.coa == 2 then self.coa = 1 end

		--infrastructure

		for k,v in next, self.infrastructureObjects do
			v.coa = self.coa
			v:swapCoalition("Infrastructure")
		end
		for k,v in next, self.depotObjects do
			v:swapCoalition("Depot")
			v:reveal(true,true)

		end
		for k,v in next, self.factoryObjects do
			v:swapCoalition("Factory")
			v:reveal(true,true)
		end

		----
		ecw.updateHexOwnershipColors({self})

		self.usableWarMaterial = te.defaultUsableWarMaterial * 1.25--newWarMaterial / self.pathModifier
		if arg[1] ~= nil then self.usableWarMaterial = 0 end
		Campaign_log:info("Flip Owner",util.ct(self.name, "flipped to:",self.coa))

		for enum, neighbor in next, self.neighbors do
			if self.coa ~= neighbor.coa then
				table.insert(tempTable,enum)
			end
		end

		if arg[1] == nil then
			self:spawnPlatoons(enemyCounter,{land = te.platoonTemplates[self.coa], naval =  te.navalTemplates[self.coa]} , tempTable)
		end
		self:spawnAA()
		self:spawnFarpGroup()

		for hexName,hex in next, ecw.hexInstances do
			hex:assignDepotToAirfield()
		end

		tempTable = {}
		local neighborCounter = 0
		for enum, neighbor in next, self.neighbors do
			if self.coa ~= neighbor.coa then
				neighborCounter = neighborCounter + 1
			end
		end
		for enum, neighbor in next, self.neighbors do
			if self.coa ~= neighbor.coa then
				if arg[1] == nil then
					neighbor:spawnPlatoons(math.ceil(friendlyCounter/neighborCounter), {land = te.platoonTemplates[neighbor.coa], naval =  te.navalTemplates[neighbor.coa]} , {ecw.oppositeEnum[enum]})
				end
			end
			neighbor:auditSpawnpoints()
		end
		persist.saveHexCoalition(ecw.hexInstances)
		persist.saveToHexFiles(ecw.hexInstances,0)
		flipMarkerIncrement()
		return self
	else
		return nil
	end

	self:auditSpawnpoints()
end

function hexObject:returnDepotObjects()

	local zone
	local foundUnits,activeUnits = {},{}
	for index, triggerTable in next, env.mission.triggers.zones do
		if triggerTable.name:find("Depot") ~= nil then

			zone = trigger.misc.getZone(triggerTable.name)

			if ecw.pointInsideHex(zone.point,self) then
				self.depotZone = triggerTable


				local sphere = trigger.misc.getZone(triggerTable.name)
				local volS = {
					id = world.VolumeType.SPHERE,
					params = {
						point = sphere.point,
						radius = sphere.radius
					}
				}
				foundUnits,activeUnits = {},{}
				local ifFound = function(foundItem, val)

					if string.find(foundItem:getName(),"ACTIVE")~=nil then
						table.insert(activeUnits,foundItem)
					else
						table.insert(foundUnits,foundItem)
					end
					return true
				end

				world.searchObjects(Object.Category.STATIC, volS, ifFound)
				util.log("SaveDepots",self.name,triggerTable.name,#foundUnits,#activeUnits)
			end
		end
	end
	return {foundUnits, activeUnits}
end
function hexObject:updateMarker()
	trigger.action.setMarkupText(self.markerIndex ,"UWM: " .. tostring(self.usableWarMaterial) )
end

function hexObject:resetLineTypes()
	for index,lineIndex in next, self.indices do
		trigger.action.setMarkupTypeLine(lineIndex, 1 )
	end
end

function ecw.test(i)
	for k,v in next, ecw.hexInstances do
		for index,lineIndex in next, v.indices do
			trigger.action.setMarkupTypeLine(lineIndex,i )
		end
	end
end

function hexObject:resetPriorityMarker()
	if self.priorityMarker > 0 then
		trigger.action.removeMark(self.priorityMarker)
		self.priorityMarker = -1
	end
end

function hexObject:createHealthBar(...)
	local cont = false
	for enum, neighbor in next, self.neighbors do
		if neighbor.coa ~= self.coa then cont = true end
	end
	if not cont then return end
	self.healthBar = ecw.healthBarID + 1
	ecw.healthBarID =  ecw.healthBarID + 1

	local blue = {0,0,1,0.25}
	local red = {1,0,0,0.25}
	local white = {1,1,1,0.25}
	local black = {0,0,0,0.25}
	local color

	if self.coa == 0 then
		color = white
	elseif self.coa == 1 then
		color = red
	elseif self.coa == 2 then
		color = blue
	end

	local borderColor = color
	borderColor[4] = 0.5


	local top = self.points[4]
	local newTop = {x = top.x, y = top.y, z = top.z}
	newTop.z = newTop.z + 1250
	local bottom = self.points[5]
	local newBottom = {x = bottom.x, y = bottom.y, z = bottom.z}

	local ratio = 1 - (self.usableWarMaterial/ecw.maxWarMaterial)
	local distance = newBottom.x - newTop.x

	newBottom.x = newBottom.x - (distance * ratio)
	if arg[1] ~= nil then color[4] = 0 end
	trigger.action.rectToAll(-1 , self.healthBar , newTop , newBottom ,  borderColor ,  color , 1 , true)

	return
end

function hexObject:updateHealthBar(...)
	trigger.action.removeMark(self.healthBar)
	self:createHealthBar(arg)
	return
end

local ewrTester = 5345345

function hexObject:spawnEWR()
	if self.poi["EWR"] == nil then return nil end
	local ewr1 = {}
	ewr1.name = "EWR_GROUP_" .. tostring(self.name)
	ewr1.task = 'Ground Nothing'
	ewr1.tasks = {}
	ewr1.route = {}
	ewr1.units = {}
	ewr1.units[1] = {}
	ewr1.units[1].type = ewr.spawnTypeName
	ewr1.units[1].y = self.poi["EWR"].y
	ewr1.units[1].x = self.poi["EWR"].x
	ewr1.units[1].name = "EWR_" .. tostring(self.name)
	ewr1.units[1].heading = 0
	local newEWR = coalition.addGroup(ecw.countryEnums[self.coa], Group.Category.GROUND, ewr1)
	
	newEWR:getController():setOption(AI.Option.Air.id.SILENCE , true)
	ewrTester = ewrTester + 1
	self.ewr = newEWR
	util.log("EWR", "Spawning",newEWR:getName(),"for",self.coa,"in",self.name,"at",ewr1.units[1].x,ewr1.units[1].y)
	local SetImmortal = { 
		id = 'SetImmortal', 
		params = { 
		  value = true 
		} 
	  }
	  self.ewr:getController():setCommand(SetImmortal)

end

function hexObject:auditAirbaseOwnership()
	for abName, ab in next, self.airfields do
		if ab ~= nil then
			if ab:isExist() == true then
				if ab:getCoalition() ~= self.coa then
					util.log("AIRBASE OWNER WARNING:",ab:getName(),"NOT OWNED BY",self.coa,". REPORTING AS",ab:getCoalition())
					ab:setCoalition(self.coa)
					util.log("AIRBASE OWNERSHIP FORCE SET:",ab:getName(),"SET TO",self.coa)
				end
			end
		end
	end
end

function hexObject:createPriorityMarker(number)

	local pointTable = {}

	for index,point in next, ecw.priorityMarkers[number] do
		pointTable[index] = {x = point.x - 2000, z = point.y - 1200, y = point.y}
	end

	local pointX = self.points[6].x
	local pointZ = self.points[6].z

	for index, point in next, pointTable do
		if type(point) == "table" then
			if point.x ~= nil and point.z ~= nil then
				point.x = point.x + pointX
				point.z = point.z + pointZ
			end
		end
	end

	pointTable[#pointTable+1],pointTable[#pointTable+2],pointTable[#pointTable+3] = {0, 0, 0, 0.8},{0, 0, 0, 0.3},1
	trigger.action.markupToAll(7, -1 , infra.markerCounter ,unpack(pointTable))
	self.priorityMarker = infra.markerCounter
	infra.markerCounter = infra.markerCounter + 1
end
---------------------------------------------------------------------------------------------------------------------------------hexObject suppporting functions

function ecw.createPriorityMarkers()
	local pointTable = {}
	local drawingNames,currentMarker = {}, ""
	drawingNames["1_template"] = {"1_template",1}
	drawingNames["2_template"] = {"2_template",2}
	drawingNames["3_template"] = {"3_template",3}

	for k, v in next, env.mission.drawings.layers[4].objects do
		if drawingNames[v.name] ~= nil then
			if drawingNames[v.name][1] ~= nil then
				for k in ipairs(v.points) do
					ecw.priorityMarkers[drawingNames[v.name][2]][k] = {x = v.points[k].x, z = v.points[k].y, y = v.points[k].y}
				end
			end
		end
	end
end
ecw.createPriorityMarkers()


function ecw.findPaths(hex, trueDistanceModifier, includeEnemy, includeNeutral) --only used in pathfinding function
	local neighbors = hex.neighbors
	local pathLengths = {}

	for sideEnum, instance in next, neighbors do
		if ((instance.coa == hex.coa) or includeEnemy) then
			if (instance.coa ~= 0) or includeNeutral then
				if trueDistanceModifier == 0 then
					pathLengths[instance.name] = 1
				else
					pathLengths[instance.name] = instance.pathModifier
				end
			end
		end
	end

	return {name = hex.name, pl = pathLengths}
end

ecw.winConditions = {}

function ecw.init()

	local i = 9001

	for k, v in next, env.mission.drawings.layers[5].objects do --all "Author" objects
		if string.find(v.name,"Sector") ~= nil then
			local points = {} --convert points to vec3 and translate them
			for index, point in next, v["points"] do
				point.z = point.y + v.mapY
				point.x = point.x + v.mapX
				points[index] = point
			end

			local nextIndex = 1
			local indices = {}

			for index, point in next, points do --create lines and group them together into table

				if index == #points then nextIndex = 1 else	nextIndex = nextIndex + 1 end

				trigger.action.lineToAll(-1 , i , point , points[nextIndex] , {0, 0, 0, 0.5} , 1 , true)
				table.insert(indices,i)
				i = i + 1

			end

			local averageX, averageZ, count = 0,0,0

			for index, value in next, points do
				averageX = averageX + value.x
				averageZ = averageZ + value.z
				count = count + 1
			end
			averageX = averageX / count
			averageZ = averageZ / count

			ecw.createHexInstance(v.name, indices, {x = averageX, z = averageZ, y = 0}, points, v.colorString)	--create hex instance with values
		end
	end
	local f, s
	local sectorTable, sector = {}, {}
	local blueColorString = "0x0000ffff"
	local redColorString  = "0xff0000ff"
	if ecw.startInit == true then
		for hexName, hex in next, ecw.hexInstances do
			local coa = 0
			if hex.color == blueColorString then coa = 2 elseif hex.color == redColorString then coa = 1 end
			ecw.hexInstances[hexName].coa = coa
		end
		timer.scheduleFunction(flipMarkerIncrement, nil, timer.getTime() + 20)
	else
		f = io.open(lfs.writedir() .. "/ColdWar/Files/".. util.getTheatre() ..".hexCoalitions","r")
		s = f:read("*all")
		f:close()
		sectorTable = util.split(s,"\n")
		for k, v in next, sectorTable do
			sector = util.split(v,",")
			ecw.hexInstances[sector[1]].coa = tonumber(sector[2])
		end
	end


	for name, instance in next, ecw.hexInstances do --define each hex's neighbors based on names
		instance:returnDepotObjects()
		instance:defineNeighbors()
		instance:findPlatoonSpawnpoints()
	end

	ecw.updateHexOwnershipColors(ecw.hexInstances)
	ecw.assignHexType(ecw.hexInstances)
end

function ecw.updateHexOwnershipColors(hexList)
	local blue = {0,0,1,0.5}
	local red = {1,0,0,0.5}
	local white = {1,1,1,0.5}
	local black = {0,0,0,0.5}
	local color

	for k, v in next, hexList do
		if v.coa == 0 then

			color = white
		elseif v.coa == 1 then
			color = red
		elseif v.coa == 2 then
			color = blue
		end

		trigger.action.setUserFlag( v.name , v.coa )

		for k2, v2 in next, v.indices do
			trigger.action.setMarkupColor(v2 , color )
		end

	end
end

function ecw.assignHexType(hexList)
	local isEnemy

	for hexName, hexInstance in next, hexList do
		isEnemy = false
		for sideEnum, neighbor in next, hexInstance.neighbors do
			if hexInstance.coa ~= neighbor.coa  and neighbor.coa ~= 0 then
				isEnemy = true
			end
		end

		if isEnemy then
			hexInstance.type = "FRONTLINE"
			trigger.action.setUserFlag( hexInstance.name .. "_FRONTLINE" , 1 )
		else
			hexInstance.type = "BACKLINE"
			trigger.action.setUserFlag( hexInstance.name .. "_FRONTLINE" , 2 )
		end

		local t = {}
		local g = {}
		t[1] = "Depot"
		t[2] = "Factory"
		t[3] = "Objective"
		t[4] = "EWR"

		for i, triggerTitle in next, t do
			for index, triggerTable in next, env.mission.triggers.zones do
				if triggerTable.name:find(triggerTitle) ~= nil then
					local tempCoords = {x = triggerTable.x, z = triggerTable.y, y = 0}
					local isInHex = ecw.pointInsideHex(tempCoords,hexInstance)

					if isInHex == true then
						hexInstance.poi[triggerTitle] = triggerTable
						if triggerTitle == "Objective" then
							ecw.winConditions[hexInstance.name] = ecw.oppositeCoa[hexInstance.initCoa]
						end
					end
				end
			end
		end

		for index, airbase in next, world.getAirbases() do
			if airbase:getDesc().category == 0 then
				local tempCoords = airbase:getPoint()
				local isInHex = ecw.pointInsideHex(tempCoords,hexInstance)

				if isInHex == true then
					hexInstance.poi["Airbase"] = airbase
					hexInstance.airfields[airbase:getName()] = airbase
				end
			end
		end

		for index, airbase in next, world.getAirbases() do
			local tempCoords = airbase:getPoint()
			local isInHex = ecw.pointInsideHex(tempCoords,hexInstance)
			if isInHex == true then
				ecw.airbaseHex[airbase:getName()] = hexName
				airbase:autoCapture(false)
			end
		end
	end

	for k,v in next, hexList do
		--trigger.action.outText(tostring(k) .. " " .. tostring(v.type),200)
		if v.coa == 0 then

			for enum,neighbor in next, v.neighbors do
				neighbor.neighbors[ecw.oppositeEnum[enum]] = nil
			end

			ecw.hexInstances[v.name] = nil
		end
	end
end

function ecw.enumEquivalent(input)
	return
end

function ecw.returnHex(name)
	return ecw.hexInstances[name]
end

function ecw.populateMarkups(hexList)

	local i = 11000

	for k, v in next, hexList do
		if v.markerIndex ~= 0 then
			trigger.action.removeMark(v.markerIndex)
		end
	end

	for k, v in next, hexList do
		i = i + 1
		local s = v.name
		if v.poi["Objective"] ~= nil then s = s .. " | " .. ecw.coaEnums[ecw.oppositeCoa[v.initCoa]] .." OBJECTIVE" end
		trigger.action.markToAll(i , s , v.origin , true)
		v.markerIndex = i
	end
end

function ecw.pointInsideHex(point,hexInstance)

	local polygon = {}

	for k, v in next, hexInstance.points do
		table.insert(polygon, v.x)
		table.insert(polygon, v.z)
	end

	return util.isPointInPolygon(point.x, point.z, polygon)
end

function ecw.findHexFromPoint(point,hexList)

	local polygon = {}
	for hexName, hex in next, hexList do
		polygon = {}
		for k, v in next, hex.points do
			table.insert(polygon, v.x)
			table.insert(polygon, v.z)
		end

		local localHex = util.isPointInPolygon(point.x, point.z, polygon)
		if localHex == true then return hex end
	end
	return nil
end

ecw.init()

--ecw.hexInstances["Sector 1-7"]:findShortestPaths(ecw.hexInstances, 0, false, false)

ecw.populateMarkups(ecw.hexInstances)



local hexEventHandler = {}

function hexEventHandler:onEvent(event)

	if event.id == world.event.S_EVENT_BASE_CAPTURED then
		util.log("HEXEH - S_EVENT_BASE_CAPTURED:",event.place:getName(),event.time)
	end

end

world.addEventHandler(hexEventHandler)
