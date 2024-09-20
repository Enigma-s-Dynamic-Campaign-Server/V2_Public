heliObject = {}
troopObject = {}
heli.hasCommands = {}
inf.instances = {}
inf.exfils = {}

function heliObject:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

function heli.createheliObject(unit)
	local instance = heliObject:new()

	instance.unit = unit
	instance.name = unit:getName()
	instance.type = instance.unit:getTypeName()
	if unit.getPlayerName then
		instance.playerName = unit:getPlayerName()
	else
		instance.playerName = "Server"
	end
	instance.coa = unit:getCoalition()
	instance.passengers = 0
	instance.squads = {}
	instance.maxPassengers = heli.maxPassengers[instance.type]
	instance.autoTroopDrop = false
	instance.lastCommand = {}
	instance.csarPassengers = {}
	instance.csarPassengers[1] = 0
	instance.csarPassengers[2] = 0
	instance.marker = 0
	heli.instances[instance.name] = instance
	instance.paths = {}
	instance.weight = 0
	instance.stopCommands = false
	instance.unloading = false
	for infType, amount in next, heli.squadSize do
		instance.squads[infType] = 0
	end
	return instance
end

function troopObject:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

function inf.createTroopObject(heliName, playerName, coa, infType, count, groups)
	local instance = troopObject:new()

	instance.name = infType .. "_" .. tostring(coa) .. "_" .. tostring(timer.getTime()) .. "_" .. heliName
	instance.heliName = heliName
	instance.playerName = playerName
	instance.type = infType
	instance.coa = coa
	instance.maxCount = heli.squadSize[infType]
	instance.count = count
	inf.instances[instance.name] = instance
	instance.group = {}
	instance.groups = groups
	instance.exfilGroup = {}
	instance.marker = -1

	return instance
end

---------------------------------------------------------------------------------------------------------------------------------heliObject function definitions
function heliObject:updateSelf()
	self.unit = Unit.getByName(self.name)
	self.type = self.unit:getTypeName()
	self.playerName = self.unit:getPlayerName()
	self.coa = self.unit:getCoalition()
end

function heliObject:reset()
	self.unit = Unit.getByName(self.name)
	self.name = self.unit:getName()
	self.type = self.unit:getTypeName()
	self.playerName = self.unit:getPlayerName()
	self.coa = self.unit:getCoalition()
	self.passengers = 0
	self.squads = {}
	self.maxPassengers = heli.maxPassengers[self.type]
	self.autoTroopDrop = false
	self.csarPassengers = {}
	self.csarPassengers[1] = 0
	self.csarPassengers[2] = 0

	heli.instances[self.name] = self

	for infType, amount in next, heli.squadSize do
		self.squads[infType] = 0
	end
end

function heli.exfilLoop(t, time)
	local heliInstance, unit, filter = unpack(t)

	if unit == nil then return end
	if not unit:isExist() then return end
	if not (unit:getLife() > 1) then return end

	local point1 = Unit.getByName(heliInstance.name):getPoint()

	local foundUnits = {}
	local volS = {
		id = world.VolumeType.SPHERE,
		params = {
			point = point1,
			radius = 3000
		}
	}

	local foundGroups = {}
	local ifFound = function(foundItem, val)
		if debugger == true then util.outText(5, heliInstance.name, foundItem:getName(), "found group") end
		if foundItem ~= nil then
			if foundItem:isExist() then
				if foundItem:getLife() >= 1 then
					if string.find(foundItem:getGroup():getName(), filter) ~= nil then
						if foundItem:getCoalition() == heliInstance.coa then
							foundGroups[foundItem:getGroup():getName()] = foundItem:getGroup()
						elseif string.find(foundItem:getGroup():getName(), "CSAR") then
							foundGroups[foundItem:getGroup():getName()] = foundItem:getGroup()
						end
					end
				end
			end
		end
	end

	world.searchObjects(Object.Category.UNIT, volS, ifFound)

	local count = 0
	for groupName, group in next, foundGroups do
		trigger.action.signalFlare(group:getUnits()[1]:getPoint(), 3, math.rad(math.random(360)))
		if debugger == true then
			util.outText(7, util.distance(group:getUnits()[1], unit), "\n",
				inf.exfils[group:getName()])
		end
		if util.distance(group:getUnits()[1], unit) < 75 then
			if util.checkSpeed(unit) < 1 then
				count = group:getSize()
				local troopInstance = inf.exfils[group:getName()]
				if count + heliInstance:auditPassengers() > heliInstance.maxPassengers then
					count = heliInstance.maxPassengers - heliInstance:auditPassengers()
				end

				local canLoadSquadType, infType = false, ""
				for i, squadType in next, heli.transportTypes[unit:getTypeName()] do
					if squadType == troopInstance.type then
						canLoadSquadType = true
						infType = squadType
						break
					end
				end

				if canLoadSquadType == true and count > 0 then
					heliInstance.squads[infType] = heliInstance.squads[infType] + count
					util.outTextForUnit(unit, 10, "You picked up", count, infType, "troops.")
					heli.troopPickupEvent(unit, infType, count)
					if infType == "CSAR" then
						heliInstance.csarPassengers[group:getCoalition()] = heliInstance.csarPassengers
							[group:getCoalition()] + 1
					end
					if heliInstance.marker == nil then heliInstance.marker = 0 end
					heliInstance:auditCommands()
					if heliInstance.marker > 0 then
						trigger.action.removeMark(heliInstance.marker)
					end
					if inf.exfils[group:getName()] ~= nil then
						inf.exfils[group:getName()] = nil
						group:destroy()
						troopInstance = nil
						heliInstance:displayPassengers(true)
					end
				end
			end
			--speed check
			--exfil
		end
	end
	timer.scheduleFunction(heli.exfilLoop, { heliInstance, unit, filter }, timer.getTime() + 8)
end

function heliObject:auditCommands()
	local addList = {}

	if self.unit == nil then return end
	if not self.unit:isExist() then return end

	missionCommands.removeItemForGroup(self.unit:getGroup():getID(), nil)

	local subMenu = missionCommands.addSubMenuForGroup(self.unit:getGroup():getID(), "EWR System")
	missionCommands.addCommandForGroup(self.unit:getGroup():getID(), "Bogey Dope", subMenu, ewr.bogeyDope,
		self.unit:getName())
	missionCommands.addCommandForGroup(self.unit:getGroup():getID(), "Request Picture", subMenu, ewr.picture,
		self.unit:getName())
	missionCommands.addCommandForGroup(self.unit:getGroup():getID(), "Request Friendly Picture", subMenu,
		ewr.friendlyPicture, self.unit:getName())
	missionCommands.addCommandForGroup(self.unit:getGroup():getID(), "Swap Distance Units", subMenu,
		ewr.swapDistanceUnits, self.unit:getName())
	missionCommands.addCommandForGroup(self.unit:getGroup():getID(), "Toggle Auto Display", subMenu,
		ewr.toggleAutoDisplay, self.unit:getName())

	self.root                = missionCommands.addSubMenuForGroup(self.unit:getGroup():getID(), "Troop Orders", nil)
	local path               = self.root

	self.paths.loadTroops    = missionCommands.addSubMenuForGroup(self.unit:getGroup():getID(), "Load Troop Menu", path)
	self.paths.dropTroops    = missionCommands.addSubMenuForGroup(self.unit:getGroup():getID(), "Drop Troop Menu", path)
	self.paths.displayTroops = missionCommands.addCommandForGroup(self.unit:getGroup():getID(), "Display Passengers",
		path, heli.display, { self, true })
	self.paths.displayCSAR   = missionCommands.addCommandForGroup(self.unit:getGroup():getID(), "Display Nearest CSAR",
		path, csar.list_csar, { self.name, self.coa })

	for k, v in next, heli.transportTypes[self.unit:getTypeName()] do
		if v ~= "CSAR" then
			util.addCommandForGroup(self.unit:getGroup():getID(), "Load " .. v, self.paths.loadTroops, heli.loadTroops,
				{ self, tostring(v) }, timer.getTime() + 0.1)
		end
	end
	for k, v in next, self.squads do --redo
		addList[k] = v
	end

	if self.autoTroopDrop == false then
		for infType, amt in next, addList do
			local squadCount = util.round(amt / heli.squadSize[infType], 2)
			while squadCount > 0 do
				util.addCommandForGroup(self.unit:getGroup():getID(), infType .. " Squad: Drop " .. squadCount,
					self.paths.dropTroops, heli.queueCommand, { self, infType, squadCount }, timer.getTime() + 0.2)
				squadCount = squadCount - 1
			end
		end
	elseif self.autoTroopDrop == true then
		util.addCommandForGroup(self.unit:getGroup():getID(), "Cancel " .. self.lastCommand[1] .. " Drop",
			self.paths.dropTroops, heli.cancelCommand, self, timer.getTime() + 0.2)
	end

	util.addCommandForGroup(self.unit:getGroup():getID(), "Campaign Overview", nil, util.displayCampaign_v2,
		self.unit:getName(), timer.getTime() + 0.4)

	return
end

--get troops (normal? specwar? recon? JTAC Kappa?)

function heliObject:loadTroops(typeName)
	self:updateSelf()
	if util.activeAC[self.name] == true then
		util.outTextForUnit(self.unit, 15, "Can't load troops here! Land at a friendly base!")
		return
	end

	if util.isLanded[self.name] == false then
		return
	end

	local amountToLoad = heli.squadSize[typeName]

	if (self:auditPassengers() + amountToLoad) <= self.maxPassengers then --passenger check
		self.squads[typeName] = self.squads[typeName] + (heli.squadSize[typeName])
		util.outTextForUnit(self.unit, 15, "You loaded a", typeName, "squad!")
		self:displayPassengers(true)
	else
		util.outTextForUnit(self.unit, 15, "Not enough room for a", typeName, "squad! You need",
			(self:auditPassengers() + amountToLoad) - self.maxPassengers, "more seats!")
		util.outTextForUnit(self.unit, 15, "Loaded Troops:", self:auditPassengers(), "/", self.maxPassengers, s)
	end
	self:auditCommands()
	return
end

function heliObject:auditPassengers()
	local count = 0
	for typeName, amt in next, self.squads do
		count = count + amt
	end
	self.passengers = count --self.csarPassengers[1] + self.csarPassengers[2]
	trigger.action.setUnitInternalCargo(self.name, self.passengers * heli.squadWeight[self.coa])
	self.weight = self.passengers * heli.squadWeight[self.coa]
	return self.passengers
end

function heliObject:displayPassengers(display)
	local s = ""
	local t = {}

	for k, v in next, heli.transportTypes[self.type] do
		t[v] = 0.0
	end
	local tAmt = 0
	for typeName, amt in next, self.squads do
		tAmt = 0
		if type(tAmt) == "nil" then tAmt = 0 end
		t[typeName] = tAmt + util.round((amt / heli.squadSize[typeName]), 2)
	end

	for typeName, count in next, t do
		s = s .. "\n" .. typeName .. ": " .. tostring(count)
	end

	if display == true then
		util.outTextForUnit(self.unit, 15, "Loaded Troops:", self:auditPassengers(), "/", self.maxPassengers, s,
			"\nWeight:", self.weight, "kg")
	end

	return t
end

--drop troops (auto and manual)? (drop at airbase returns?)

function heliObject:findHexPos()
	local pos = self.unit:getPoint()
	local localHex

	--if util.activeAC[self.name] == false or util.isLanded[self.name] == false then return end	
	for hexName, hex in next, ecw.hexInstances do
		if ecw.pointInsideHex(pos, hex) == true then
			localHex = hex
			break
		end
	end

	return localHex
end

function heli.dropLoop(heliInstance, time)
	--if debugger == true then util.outText(10,"drop loop debugger:",heliInstance.name,util.isLanded[heliInstance.name],util.activeAC[heliInstance.name],heliInstance.stopCommands,heliInstance.autoTroopDrop,heliInstance.unloading) end
	if Unit.getByName(heliInstance.name) == nil then return nil end
	if heliInstance.autoTroopDrop == false then return nil end
	if util.isLanded[heliInstance.name] == true and heliInstance.autoTroopDrop == true then
		if util.checkSpeed(Unit.getByName(heliInstance.name)) < 1 then -- and heliInstance.stopCommands == false then
			heli.executeCommand(heliInstance)
			return nil
		elseif util.checkSpeed(Unit.getByName(heliInstance.name)) >= 1 then
			util.outTextForUnit(Unit.getByName(heliInstance.name), 5, "Moving too fast to drop!")
		end
	end
	return time + 1
end

function heliObject:dropTroops(squadCount, squadType)
	local localHex = self:findHexPos()
	if localHex == nil then
		util.outTextForUnit(Unit.getByName(self.name), 10, "Cant unload when not in a Hex!")
		return
	end
	local isInEnemyHex = localHex.coa ~= self.coa and localHex.coa ~= 0
	local troopCount = math.floor(squadCount * heli.squadSize[squadType])
	local typeName, returnedGroups = inf.squadComp[self.coa][squadType], {}

	if isInEnemyHex and squadType ~= "CSAR" then
		if squadCount > 0 then
			local foundUnits = {}
			local volS = {
				id = world.VolumeType.SPHERE,
				params = {
					point = self.unit:getPoint(),
					radius = inf.searchRadius[squadType]
				}
			}

			local ifFound = function(foundItem, val)
				for index, filter in next, inf.unitFilter[squadType] do
					if string.find(foundItem:getName(), filter) ~= nil and self.coa ~= foundItem:getCoalition() then
						if string.find(foundItem:getName(), "marker") ~= nil or foundItem:getLife() > 1 then
							table.insert(foundUnits, { dist = util.distance(foundItem, self.unit), unit = foundItem })
							return true
						end
					end
				end
			end

			local attributeList = {}
			attributeList[1] = "Air Defense"
			attributeList[1] = "SR SAM"

			local tableList = {}
			local outputTable = {}
			local alreadyFiltered = {}
			local extraTable = {}

			for i, filter in ipairs(tableList) do
				for i, t in next, foundUnits do
					if t.unit:getDesc().attributes[filter] == true and alreadyFiltered[t.unit:getName()] == false then
						table.insert(outputTable, t)
						alreadyFiltered[t.unit:getName()] = true
					end
				end
			end

			for _, t in next, foundUnits do
				if alreadyFiltered[t.unit:getName()] == false then
					table.insert(outputTable, t)
					alreadyFiltered[t.unit:getName()] = true
				end
			end

			foundUnits = outputTable

			world.searchObjects(Object.Category.UNIT, volS, ifFound)
			volS.params.radius = volS.params.radius * 2
			world.searchObjects(Object.Category.STATIC, volS, ifFound)
			local reconPoint = self.unit:getPoint()
			reconPoint.x = reconPoint.x + 12
			reconPoint.z = reconPoint.z + 12
			if squadType == "Recon" then
				recon.createJtac(self.coa, reconPoint)
			end

			table.sort(foundUnits, function(k1, k2) return k1.dist < k2.dist end)

			local targetPoint = self.unit:getPoint()
			if #foundUnits > 0 then
				if foundUnits[1].unit ~= nil then
					if foundUnits[1].unit.getPoint ~= nil then
						targetPoint = foundUnits[1].unit:getPoint()
					end
				end
			end

			local returnedGroups, exfilPoint = util.spawnSquad(typeName, troopCount, self.coa, self.unit:getPoint(),
				util.heading(self.name), heli.deploySide[self.type], self.name, targetPoint, squadType, self)
			self.stopCommands = true
			local squad = inf.createTroopObject(self.name, self.playerName, self.coa, squadType, 0, returnedGroups)
			timer.scheduleFunction(inf.startMission, { squad, squadType, troopCount, returnedGroups, exfilPoint,
				foundUnits }, timer.getTime() + inf.missionTime[squad.type])
		end
	elseif util.activeAC[self.name] == false then
		self.squads[squadType] = self.squads[squadType] - (squadCount * heli.squadSize[squadType])
		local friendlyCsarReturned, EnemyCsarReturned
		if squadType == "CSAR" then
			friendlyCsarReturned, EnemyCsarReturned = self.csarPassengers[self.coa],
				self.csarPassengers[ecw.oppositeCoa[self.coa]]
			util.outTextForUnit(Unit.getByName(self.name), 10, "CSAR Returned | Friendly: ", friendlyCsarReturned,
				"| Enemy:", EnemyCsarReturned)
			util.addUserPoints(self.name, friendlyCsarReturned + EnemyCsarReturned)
			if self.coa == 1 then
				redTE.attritionValue = redTE.attritionValue - (friendlyCsarReturned)
				redTE.csarReconCounter = redTE.csarReconCounter + EnemyCsarReturned
				if redTE.csarReconCounter > math.random(5) then
					blueTE:revealRandomInfrastructure()
					redTE.csarReconCounter = 0
				end
			else
				blueTE.attritionValue = redTE.attritionValue - (friendlyCsarReturned)
				blueTE.csarReconCounter = blueTE.csarReconCounter + EnemyCsarReturned
				if blueTE.csarReconCounter > math.random(5) then
					redTE:revealRandomInfrastructure()
					blueTE.csarReconCounter = 0
				end
			end

			self.csarPassengers[self.coa], self.csarPassengers[ecw.oppositeCoa[self.coa]] = 0, 0
		end

		util.outTextForUnit(Unit.getByName(self.name), 10, "Dropped out", squadCount, squadType, "Squads")
		heli.cancelCommand(self)
	else
		util.outTextForUnit(Unit.getByName(self.name), 10, "cant unload here!")
	end
	return
end

function heliObject:toggleAutoTroopDrop()
	if self.autoTroopDrop == true then
		self.autoTroopDrop = false
	elseif self.autoTroopDrop == false then
		self.autoTroopDrop = true
	else
		self.autoTroopDrop = false
	end
	util.outTextForUnit(self.unit, 20, "Automatic troop drops set to:", instance.autoTroopDrop)
	return self.autoTroopDrop
end

---------------------------------------------------------------------------------------------------------------------------------troopObject definitions

function troopObject:standardTroopMission(squadCount, groups, newPoint, foundUnits)
	local squadType
	local count = 0 --count number of units
	for k, g in next, groups do
		if g:isExist() and g.getUnits ~= nil then
			if #g:getUnits() > 0 then
				for i, unit in next, g:getUnits() do
					if unit:isExist() then
						if unit:isActive() then
							if unit:getLife() > 1 then
								count = count + 1
							end
						end
					end
				end
			end
		end
	end
	--kill the targets

	if count <= 0 then
		util.outTextForUnit(Unit.getByName(self.heliName), 15, "Squad is KIA!")
	else
		squadType = self.type
		if (Unit.getByName(self.heliName)) ~= nil then
			--util.outTextForUnit(Unit.getByName(self.heliName),20,"Units found:",#foundUnits)
			if debugger then util.outText(20, "Units found:", #foundUnits) end
		end

		local unitCount = 0

		if #foundUnits > 0 and self.type ~= "Recon" then
			local killedCount = 0
			local killedUnits = {}
			for i = 1, math.ceil(count * inf.killsPerSoldier[self.coa][squadType]) do
				if i > #foundUnits then break end
				if foundUnits[i].unit ~= nil then
					if foundUnits[i].unit.isExist ~= nil then
						if foundUnits[i].unit:isExist() then
							heli.troopKillEvent(Unit.getByName(self.heliName), foundUnits[i].unit, squadType)
							table.insert(killedUnits, foundUnits[i].unit:getTypeName())
							trigger.action.explosion(foundUnits[i].unit:getPoint(), inf.bombSize[squadType])
							unitCount = unitCount + 1
						end
					end
				end
			end


			for k, v in next, killedUnits do
				if self.playerName == nil then self.playerName = "Server" end
				net.send_chat(self.playerName .. " killed a " .. v .. " with a " .. squadType .. " drop.", true)
			end
		elseif #foundUnits > 0 and self.type == "Recon" then
			local infraCount, hex = 0, {} --infra markers
			for index, unitDistTable in next, foundUnits do
				if string.find(unitDistTable.unit:getName(), "Infrastructure") ~= nil and string.find(unitDistTable.unit:getName(), "marker") ~= nil then
					for staticName, static in next, infrastructure.markers[unitDistTable.unit:getName()]:reveal() do
						if static:isExist() then
							if static:getCoalition() ~= self.coa and static:getLife() >= 1 then
								if recon.currentMarkers[static:getCoalition()][static:getName()] == nil then
									recon.addMarkerUnit(static, 0)
									infraCount = infraCount + 1
								end
							end
						end
					end
					hex = ecw.findHexFromPoint(unitDistTable.unit:getPoint(), ecw.hexInstances)
					util.outTextForCoalition(self.coa, 10, "Infrastructure in", hex.name, "found!")
				end
			end

			local unitCount, hex = 0, {}
			for index, unitDistTable in next, foundUnits do --units
				if unitDistTable.unit ~= nil then
					if unitDistTable.unit.isExist ~= nil then
						if unitDistTable.unit:isExist() then
							if string.find(unitDistTable.unit:getName(), "Platoon") ~= nil or string.find(unitDistTable.unit:getName(), "SAM") ~= nil or string.find(unitDistTable.unit:getName(), "Depot") ~= nil then
								if unitDistTable.unit:getCoalition() ~= self.coa and unitDistTable.unit:getLife() >= 1 then
									if recon.currentMarkers[unitDistTable.unit:getCoalition()][unitDistTable.unit:getName()] == nil then
										recon.addMarkerUnit(unitDistTable.unit, 0)
										unitCount = unitCount + 1
									end
								end
							end
						end
					end
				end
			end
			if self.playerName == nil then self.playerName = "Server" end
			util.outTextForCoalition(self.coa, 10, self.playerName, "found", unitCount, "units with Recon Troops!")
		end

		util.addUserPoints(self.playerName, math.ceil(unitCount * inf.pointModifier[self.type]))
		util.outTextForUnit(Unit.getByName(self.heliName), 20, "Troops awaiting exfil...")
	end
	--extract
	if count <= 0 then
		return
	else
		for k, g in next, groups do
			if g:isExist() then
				g:destroy()
			end
		end
		local xRand, yRand = 1, 1
		if math.random(2) == 1 then xRand = -1 end
		if math.random(2) == 1 then yRand = -1 end
		--[[
		local localHex
		
		for hexName,hex in next, ecw.hexInstances do
			if ecw.pointInsideHex(newPoint,hex) == true then
				localHex = hex
				break
			end
		end
		]]
		--
		trigger.action.markToCoalition(util.markersIndeces, squadType .. " squad last known position, awaiting exfil",
			newPoint, self.coa, false)
		self.marker = util.markersIndeces
		util.markersIndeces = util.markersIndeces + 1

		newPoint.x = newPoint.x + (math.random(inf.exfilRandomNumber[squadType]) * xRand)
		newPoint.z = newPoint.z + (math.random(inf.exfilRandomNumber[squadType]) * yRand)
		self.groups = {}
		local exfilGroup = util.spawnUnitGroup(inf.squadComp[self.coa][squadType], "EXFIL_" .. self.name, self.coa,
			newPoint, count)
		self.exfilGroup = exfilGroup
		if exfilGroup ~= nil then
			inf.exfils[exfilGroup:getName()] = self
			if debugger == true then
				util.outText(20, "exfil group:", exfilGroup:getName(), "\n",
					inf.exfils[exfilGroup:getName()].heliName)
			end
			timer.scheduleFunction(inf.deleteExfilGroup, self, timer.getTime() + inf.deletionTime)
		end
	end

	return
end

function troopObject:SOFTroopMission(squadCount, groups)
	util.outText(20, squadCount)
	return
end

function troopObject:ReconTroopMission(squadCount, groups)
	util.outText(20, squadCount)
	return
end

function inf.deleteExfilGroup(troopInstance)
	for i, g in next, troopInstance.groups do
		g:destroy()
	end

	if troopInstance.marker > 0 then
		trigger.action.removeMark(troopInstance.marker)
	end

	if troopInstance.exfilGroup ~= nil then
		if troopInstance.exfilGroup:isExist() then
			troopInstance.exfilGroup:destroy()
		end
	end
	inf.exfils[troopInstance.name] = nil

	util.log("deleteExfilGroup", "deleted", troopInstance.name)
	troopInstance = nil
	return
end

function inf.startMission(t, time)
	local squad, squadType, groupCount, groups, extractPoint, targets = unpack(t)

	inf.missions[squadType](squad, groupCount, groups, extractPoint, targets)
end

inf.missions = {}
inf.missions["Standard"] = troopObject.standardTroopMission
inf.missions["SOF"] = troopObject.standardTroopMission --SOFTroopMission
inf.missions["Recon"] = troopObject.standardTroopMission


---------------------------------------------------------------------------------------------------------------------------------heli misc function definitions
function heli.dropStandardTroops(t)
	t[1]:dropTroops(t[2], "Standard")
end

function heli.dropSOFTroops(t)
	t[1]:dropTroops(t[2], "SOF")
end

function heli.dropReconTroops(t)
	t[1]:dropTroops(t[2], "Recon")
end

function heli.dropCSARTroops(t)
	t[1]:dropTroops(t[2], "CSAR")
end

function heli.cancelCommand(heliInstance)
	util.outTextForUnit(Unit.getByName(heliInstance.name), 10,
		"Canceled/Completed " ..
		tostring(heliInstance.lastCommand[2] * heli.squadSize[heliInstance.lastCommand[1]]) ..
		" " .. heliInstance.lastCommand[1] .. " Troop drop.")
	heliInstance.lastCommand = {}
	heliInstance.autoTroopDrop = false
	heliInstance:auditCommands()
end

function heli.queueCommand(t)
	local heliInstance, squadType, count = unpack(t)
	if heliInstance.unloading == true then return end
	local localHex = ecw.findHexFromPoint(Unit.getByName(heliInstance.name):getPoint(), ecw.hexInstances)
	if localHex == nil then
		util.outTextForUnit(Unit.getByName(heliInstance.name), 10, "Cant unload when not in a Hex!")
		return
	end
	heliInstance.lastCommand = { squadType, count }
	util.outTextForUnit(Unit.getByName(heliInstance.name), 10,
		tostring(count * heli.squadSize[squadType]) .. " " .. squadType .. " Troops getting ready to disembark...")
	heliInstance.autoTroopDrop = true
	timer.scheduleFunction(heli.dropLoop, heliInstance, timer.getTime() + 1)
	heliInstance:auditCommands()
end

function heli.executeCommand(heliInstance)
	heli.commands[heliInstance.lastCommand[1]]({ heliInstance, heliInstance.lastCommand[2] })
	heliInstance.lastCommand = {}
	heliInstance.autoTroopDrop = false
end

heli.commands = {}
heli.commands["Standard"] = heli.dropStandardTroops
heli.commands["SOF"] = heli.dropSOFTroops
heli.commands["Recon"] = heli.dropReconTroops
heli.commands["CSAR"] = heli.dropCSARTroops

--spawn troop for pickup

--troop movement?

--scheduled kill?
function heli.loadTroops(t)
	t[1]:loadTroops(t[2])
	return
end

function heli.toggleDrop(heliInstance)
	heliInstance:toggleAutoTroopDrop()
	return
end

function heli.display(t)
	t[1]:displayPassengers(t[2])
end

---------------------------------------------------------------------------------------------------------------------------------EH definitions

local heliEventHandler = {}

function heliEventHandler:onEvent(event)
	local eI
	if event.initiator ~= nil then eI = event.initiator else return end

	if world.event.S_EVENT_LAND == event.id then
		if eI ~= nil then
			if eI:isExist() then
				if heli.instances[eI:getName()] ~= nil then
					if heli.instances[eI:getName()].lastCommand ~= {} and ecw.findHexFromPoint(eI:getPoint(), ecw.hexInstances) ~= nil then
						if ecw.findHexFromPoint(eI:getPoint(), ecw.hexInstances).coa ~= eI:getCoalition() then
							timer.scheduleFunction(heli.dropLoop, heli.instances[eI:getName()], timer.getTime() + 1)
						end
					end
				end
			end
		end
	end

	if world.event.S_EVENT_TAKEOFF == event.id then
		if eI:getDesc().category == 1 and heli.instances[eI:getName()] ~= nil then
			heli.instances[eI:getName()]:auditCommands()
		end
	end

	if world.event.S_EVENT_BIRTH == event.id then
		if eI.getPlayerName == nil then return end
		if eI:getPlayerName() == nil then return end

		trigger.action.setUnitInternalCargo(eI:getName(), 0)
		if eI:getDesc().category == 1 then
			local helicopter
			if heli.instances[eI:getName()] == nil then
				helicopter = heli.createheliObject(eI)
				helicopter:auditCommands()
				timer.scheduleFunction(heliObject.auditCommands, helicopter, timer.getTime() + 10)
			end

			heli.instances[eI:getName()]:updateSelf()
			heli.instances[eI:getName()]:reset()
			heli.exfilLoop({ heli.instances[eI:getName()], eI, "EXFIL" }, timer.getTime() + 4)

			--util.outTextForUnit(eI,15,"Automatic troop drops set to:",instance.autoTroopDrop)
			local squadTypes = ""
			for k, v in next, heli.transportTypes[eI:getTypeName()] do
				squadTypes = squadTypes .. v .. ", "
			end
			squadTypes = string.sub(squadTypes, 1, #squadTypes - 2)
			util.outTextForUnit(eI, 15, "Squad types you can load:", squadTypes)
			util.outTextForUnit(eI, 15, "Seats available:",
				heli.instances[eI:getName()].maxPassengers - heli.instances[eI:getName()].passengers)
		end
		return
	end

	return
end

world.addEventHandler(heliEventHandler)

world.event.S_EVENT_ECW_TROOP_DROP   = world.event.S_EVENT_MAX + 1050
world.event.S_EVENT_ECW_TROOP_KILL   = world.event.S_EVENT_MAX + 1051
world.event.S_EVENT_ECW_TROOP_PICKUP = world.event.S_EVENT_MAX + 1052

function heli.troopDropEvent(unit, troop_type)
	local Event = {
		id = world.event.S_EVENT_ECW_TROOP_DROP,
		time = timer.getTime(),
		initiator = unit,
		weapon_name = troop_type,
	}
	world.onEvent(Event)
end

function heli.troopKillEvent(unit, target, troop_type)
	local Event = {
		id = world.event.S_EVENT_ECW_TROOP_KILL,
		time = timer.getTime(),
		initiator = unit,
		weapon_name = troop_type,
		target = target,
	}
	world.onEvent(Event)
end

function heli.troopPickupEvent(unit, troop_type, count)
	local Event = {
		id = world.event.S_EVENT_ECW_TROOP_PICKUP,
		time = timer.getTime(),
		initiator = unit,
		weapon_name = troop_type,
		comment = count,
	}
	world.onEvent(Event)
end
