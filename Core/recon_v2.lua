--recon v2
assert(loadfile(lfs.writedir().."ColdWar/Core/util.lua"))()

camera = {}
camera.instances = {}

reconPlane = {}
recon.instances = {}

recon.accuracyThreshold = 4000

recon.redMarkCount = 150000
recon.blueMarkCount = 160000
recon.currentMarkers = {}
recon.currentMarkers[1] = {}
recon.currentMarkers[2] = {}

recon.laserCode = 1511
recon.lowFilm = 120
recon.highFilm = 120
recon.jtacMarks = 170000
---------------------------------------------------------------------------------------------------------------------------------reconPlane methods
--old place for aircraft definitions
---------------------------------------------------------------------------------------------------------------------------------reconPlane methods

function reconPlane:displayParameters()
	local s
	--low alt cams
	s = "Low Alt Cameras:"
	for index, camera in next, self.cameras.unitCameras do
		local s = s .. string.format("\nName: %s\nPitch: %d°\nYaw: %d°\nHoriFOV: %d°\nVertFOV: %d°\nMaxDist: %dm\n",camera.name,camera.pitch,camera.yaw,camera.horizontalHalfAngleFOV * 2,camera.verticalHalfAngleFOV * 2,camera.maxDistance)
		util.outTextForUnit(self.unit,10,s)
	end
	
	--high alt cams
	s = "High Alt Cameras:"
	for index, camera in next, self.cameras.infraCameras do
		local s = s .. string.format("\nName: %s\nPitch: %d°\nYaw: %d°\nHoriFOV: %d°\nVertFOV: %d°\nMaxDist: %dm\n",camera.name,camera.pitch,camera.yaw,camera.horizontalHalfAngleFOV * 2,camera.verticalHalfAngleFOV * 2,camera.maxDistance)
		util.outTextForUnit(self.unit,10,s)
	end
end

function reconPlane:new(t)
	t = t or {}   
	setmetatable(t, self)
	self.__index = self	
	return t
end

function recon.createReconPlane(unitName)

	local instance = reconPlane:new()
	recon.instances[unitName] = instance

	instance.unitName = unitName
	instance.unit = Unit.getByName(unitName)
	instance.playerName = instance.unit:getPlayerName()
	instance.coa = instance.unit:getCoalition()
	
	instance.foundUnits = {}
	instance.foundInfra = {}
	
	instance.cameras = {}
	instance.cameras.unitCameras = {}
	instance.cameras.infraCameras = {}
	instance.inactiveCameras = {}
	instance.commandPaths = {}
	
	instance.unitCameraOn = false
	instance.infraCameraOn = false
	instance.highFilm = recon.highFilm
	instance.lowFilm = recon.lowFilm
	
	return instance
end

function camera:new(t)
	t = t or {}   
	setmetatable(t, self)
	self.__index = self	
	return t
end

function recon.createCamera(name, typeName, unitName, pitch, roll, yaw, horizontalHalfAngleFOV, verticalHalfAngleFOV, maxDistance, infra, film)

	local instance = camera:new()
	
	instance.name = name
	instance.unitName = unitName
	instance.typeName = typeName
	instance.pitch = pitch
	instance.roll = roll
	instance.yaw = yaw
	instance.horizontalHalfAngleFOV = horizontalHalfAngleFOV
	instance.verticalHalfAngleFOV = verticalHalfAngleFOV
	instance.maxDistance = maxDistance
	instance.infra = infra
	util.log("createCamera",name,typeName,unitName)
	return instance
end

---------------------------------------------------------------------------------------------------------------------------------reconPlane methods

function reconPlane:addCamera(cameraInstance)
	if cameraInstance.infra == true then
		table.insert(self.cameras.infraCameras,cameraInstance)
	else
		table.insert(self.cameras.unitCameras,cameraInstance)
	end
end

function reconPlane:captureUnits(...)
	
	local foundUnitTables,returnUnits = {},{}
	local pos = self.unit:getPosition()
	
	for k, camera in next, self.cameras.unitCameras do--redo with optional arguments
		table.insert(foundUnitTables, camera:captureUnits(self.unit, false))
	end
	
	for k, camera in next, self.cameras.infraCameras do--redo with optional arguments
		table.insert(foundUnitTables, camera:captureUnits(self.unit, true))
	end
	
	for k, foundUnits in next, foundUnitTables do
		for unitName, unit in next, foundUnits do
			returnUnits[unitName] = unit
		end
	end
	
	return returnUnits
end

function reconPlane:filterInfraTargets(targetList)
	if targetList ~= nil then
		if type(targetList) == "table" then
			for targetName,targetUnitDist in next, targetList do
				self.foundInfra[targetName] = targetUnitDist
			end
		end
	end
	return
end

function reconPlane:filterUnitTargets(targetList)
	if targetList ~= nil then
		if type(targetList) == "table" then
			for targetName,targetUnitDist in next, targetList do
				util.log("reconDebug",reconPlane.name,targetUnitDist.unit,targetUnitDist.distance)
				self.foundUnits[targetName] = targetUnitDist
			end
		end
	end
	return
end

function reconPlane:returnFilm()

	if util.activeAC[self.unitName] == true then--return if is landed at friendly base
		trigger.action.outTextForUnit(self.unit:getID(), "Land at a friendly base to return film." , 10)
		return
	end
	
	--util.outText(20,self.unitName,"Infra:",util.countList(self.foundInfra),"Units:",util.countList(self.foundUnits))
	
	trigger.action.outTextForUnit(self.unit:getID(), "Successfully returned and restocked film." , 10)
	
	local infraTargets 	= self.foundInfra
	local unitTargets	= self.foundUnits
	local infraCount,unitCount = 0,0
	
	if util.countList(infraTargets) > 0 then
		for k,v in next, infraTargets do
			if string.find(k, "Infrastructure") ~= nil and string.find(k,"marker") ~= nil then
				for staticName, static in next, infrastructure.markers[k]:reveal() do
					if static ~= nil then
						if static:isExist() then
							if static:getCoalition() ~= self.coa and static:getLife() >= 1 then
								if recon.currentMarkers[static:getCoalition()][static:getName()] == nil then
									recon.addMarkerUnit(static,0)
									infraCount = infraCount + 1
								end
							end
						end
					end
				end
			end
		end
	end
	
	trigger.action.outTextForCoalition(self.coa , self.unit:getPlayerName() .." has found " .. tostring(infraCount) .. " infrastructure targets with recon.", 10)
	trigger.action.outTextForUnit(self.unit:getID() , "points gained from infrastructure recon: " .. tostring(math.ceil(infraCount * recon.pointsPerInfra)), 10)
	util.addUserPoints(self.unit:getPlayerName(),math.ceil(infraCount * recon.pointsPerInfra))

	if util.countList(unitTargets) > 0 then
		for k,v in next, unitTargets do
			if v.unit ~= nil then
				if v.unit:isExist() then
					if v.unit:getCoalition() ~= self.coa and v.unit:getLife() >= 1 then
						if recon.currentMarkers[v.unit:getCoalition()][v.unit:getName()] == nil then
							recon.addMarkerUnit(v.unit,v.distance)
							unitCount = unitCount + 1
						end
					end
				end
			end
		end
	end
	
	trigger.action.outTextForCoalition(self.coa , self.unit:getPlayerName() .." has found " .. tostring(unitCount) .. " units with recon.", 10)
	trigger.action.outTextForUnit(self.unit:getID() , "points gained from unit recon: " .. tostring(math.ceil(unitCount * recon.pointsPerUnit)), 10)
	util.addUserPoints(self.unit:getPlayerName(),math.ceil(unitCount * recon.pointsPerUnit))

	self.unit = Unit.getByName(self.unitName)
	self.lowFilm = recon.lowFilm
	self.highFilm = recon.highFilm
	self.foundUnits = {}
	self.foundInfra = {}
	self.unitCameraOn = false
	self.infraCameraOn = false

	return
end
---------------------------------------------------------------------------------------------------------------------------------camera methods

function camera:captureUnits(unit, infra)
	
	if unit == nil then return end
	if not unit:isExist() then return end
	
	local pos = unit:getPosition()
	
	local roll = util.vec3ToRoll(pos)
	local pitch = util.vec3ToPitch(pos)
	local yaw = util.vec3ToYaw(pos)
	
	--util.outText(5,self.name,infra)	
	--util.outText(5,roll)
	--util.outText(5,pitch)	
	--util.outText(5,yaw)
	
	local orientation = {}
	orientation.pitch = math.rad(pitch + self.pitch)
	orientation.roll = math.rad(roll + self.roll)
	orientation.yaw = math.rad(yaw + self.yaw)
	
	if orientation.yaw < -math.pi then --angle is added to and goes below -180
		orientation.yaw = math.pi - (math.abs(orientation.yaw) - math.pi)
	end
	
	if orientation.yaw > math.pi then --angle is added to and exceeds 180
		orientation.yaw = -math.pi + (math.abs(orientation.yaw) - math.pi)
	end
	
	local matrixVec3 = util.eulerToRotationMatrix(orientation.pitch,orientation.roll,orientation.yaw)
	matrixVec3.p = pos.p
	
	--util.outText(5,util.vec3ToRoll(matrixVec3))
	--util.outText(5,util.vec3ToPitch(matrixVec3))	
	--util.outText(5,util.vec3ToYaw(matrixVec3))
	
	local foundUnits = {}
	local volP = {
		id = world.VolumeType.PYRAMID,
		params = {
			--point = pos.p,
			--radius = 10000
			pos = matrixVec3,
			length = self.maxDistance,
			halfAngleHor = math.rad(self.horizontalHalfAngleFOV),
			halfAngleVer = math.rad(self.verticalHalfAngleFOV)
		}
	}
	
	local foundUnits, distance = {}, 0
	local ifFound = function(foundItem, val)
		local distanceCalc = util.distance(foundItem, unit)
		foundUnits[foundItem:getName()] = {unit = foundItem, distance = distanceCalc}
		return true
	end
	
	local cat = Object.Category.UNIT
	if infra == true then cat = Object.Category.STATIC end
	
	world.searchObjects(cat, volP, ifFound)
	--util.outText(5,"RECON DEBUG",unit:getName(),util.countList(foundUnits))
	
	return foundUnits
end


---------------------------------------------------------------------------------------------------------------------------------execution and misc function definitions
function recon.returnFilm(recon_plane)
	recon_plane:returnFilm()
	return
end

function recon.deleteMarkerByName(coa,name)
	if type(recon.currentMarkers[coa][name]) == "number" then
		trigger.action.removeMark(recon.currentMarkers[coa][name])
		util.log("recon.deleteMarkerByName",name,"marker deleted.")
	end
end

function recon.audit(_,time)
	local unit
	for coa, unitNameIndex in next, recon.currentMarkers do
		for k,v in next, unitNameIndex do
			if Unit.getByName(k) ~= nil then
				unit = Unit.getByName(k)
			else
				unit = StaticObject.getByName(k)
			end
			if unit ~= nil then
				if unit.getLife then
					if unit:getLife() < 1 then
						util.log("recon.audit",unit:getName(),"marker deleted.")
						trigger.action.removeMark(v)
						recon.currentMarkers[unit:getCoalition()][unit:getName()] = nil
					end
				else
					util.log("recon.audit",unit:getName(),"marker deleted.")
					trigger.action.removeMark(v)
					recon.currentMarkers[unit:getCoalition()][unit:getName()] = nil
				end
			else
				util.log("recon.audit",k,"marker deleted.")
				trigger.action.removeMark(v)
				recon.currentMarkers[coa][k] = nil
			end
		end
	end
	if time == nil then return nil end
	return time + 30
end

function recon.modifyPoint(point,maxOffset)
	local newPoint,mod = point, 0

	for axis,value in next, point do
		if math.random(2) == 1 then mod = 1 else mod = -1 end

		newPoint[axis] = value + (math.random(0,maxOffset) * mod) 
	end
	return newPoint
end

function recon.addMarkerUnit(unit,accuracy)
	local maxOffset,newPoint,typeName = (accuracy)^(1/2.5),{},"UNKNOWN"
	
	if unit == nil then return end
	if not unit:isExist() then return end
	if unit:getLife() < 1 then return end
	newPoint = recon.modifyPoint(unit:getPoint(),maxOffset)
	if accuracy < recon.accuracyThreshold then typeName = unit:getTypeName() end

	if unit:getCoalition() == 2 then
		
		util.log("recon.addMarkerUnit","adding marker for",unit:getName(),"| accuracy:",accuracy)
		local lat,lon,alt = coord.LOtoLL(newPoint)
		local temp,pressure = atmosphere.getTemperatureAndPressure(newPoint)
		local outString = tostring(util.round(lat,4))..", " .. tostring(util.round(lon,4)) .." | ".. tostring(util.round((29.92 * (pressure/100) / 1013.25) * 25.4,2)) .."\nTYPE: " .. typeName
		trigger.action.markToCoalition(recon.redMarkCount, outString , newPoint , 1 , true)
		recon.currentMarkers[unit:getCoalition()][unit:getName()] = recon.redMarkCount
		recon.redMarkCount = recon.redMarkCount + 1
		return recon.redMarkCount - 1
		
	elseif unit:getCoalition() == 1 then
	
		util.log("recon.addMarkerUnit","adding marker for",unit:getName(),"| accuracy:",accuracy)
		local lat,lon,alt = coord.LOtoLL(newPoint)
		local temp,pressure = atmosphere.getTemperatureAndPressure(newPoint)
		local outString = tostring(util.round(lat,4))..", " .. tostring(util.round(lon,4)) .." | ".. tostring(util.round(pressure/100,2)) .." " .. tostring(util.round(29.92 * (pressure/100) / 1013.25,2)) .."\nTYPE: " .. typeName
		trigger.action.markToCoalition(recon.blueMarkCount, outString , newPoint , 2 , true)
		recon.currentMarkers[unit:getCoalition()][unit:getName()] = recon.blueMarkCount
		recon.blueMarkCount = recon.blueMarkCount + 1
		return recon.blueMarkCount - 1
	end
end

function recon.deleteMarker(unitName)
	return
end

---------------------------------------------------------------------------------------------------------------------------------event handler

function recon.removeMarkersGroup(group)
	if group ~= nil then
		if group:isExist() then
			util.log("recon.removeMarkersGroup","Removing",#group:getUnits(), "marks for group",group:getName())
			for k,v in next, group:getUnits() do
				if recon.currentMarkers[group:getCoalition()][v:getName()] ~= nil then
					trigger.action.removeMark(recon.currentMarkers[group:getCoalition()][v:getName()])
					recon.currentMarkers[group:getCoalition()][v:getName()] = nil
				end
			end
		end
	end
	return
end

function recon.removeMarkersInfra(infraObject)
	if  infraObject ~= nil then
		util.log("recon.removeMarkersInfra","Removing",infraObject.triggerName, "marks")
		for k,v in next, infraObject.statics do
			if recon.currentMarkers[infraObject.coa][v.name] ~= nil then
				trigger.action.removeMark(recon.currentMarkers[infraObject.coa][v.name])
				recon.currentMarkers[infraObject.coa][v.name] = nil
			end
		end
	end
	return
end

function recon.removeMarkersAA(group)
	if group ~= nil then
		util.log("recon.removeMarkersAA","Removing",#group:getUnits(), "marks for AA",group:getName())
		for k,v in next, group:getUnits() do
			if recon.currentMarkers[group:getCoalition()][v:getName()] ~= nil then
				trigger.action.removeMark(recon.currentMarkers[group:getCoalition()][v:getName()])
				recon.currentMarkers[group:getCoalition()][v:getName()] = nil
			end
		end
	end
	return
end

function recon.toggleLow(recon_plane)
	if recon_plane.unitCameraOn == false then
		if recon_plane.lowFilm >= 1 then
			trigger.action.outTextForUnit(recon_plane.unit:getID(),"LOW ALT CAPTURE ON",10,true)
			recon_plane.unitCameraOn = true
			recon.captureUnits(recon_plane)
		end
	else
		trigger.action.outTextForUnit(recon_plane.unit:getID(),"LOW ALT CAPTURE OFF",10,false)
		recon_plane.unitCameraOn = false
	end
end

function recon.toggleHigh(recon_plane)

	if recon_plane.infraCameraOn == false then
		if recon_plane.highFilm >= 1 then
			trigger.action.outTextForUnit(recon_plane.unit:getID(),"HIGH ALT CAPTURE ON",10,true)
			recon_plane.infraCameraOn = true
			recon.captureInfra(recon_plane)
		end
	else		
		trigger.action.outTextForUnit(recon_plane.unit:getID(),"HIGH ALT CAPTURE OFF",10,false)
		recon_plane.infraCameraOn = false
	end
end

function recon.captureUnits(recon_plane)

	if recon_plane.unit == nil then return end
	if not recon_plane.unit:isExist() then return end
	
	if recon_plane.unitCameraOn == true and recon_plane.lowFilm > 0 then
		timer.scheduleFunction( recon.captureUnits , recon_plane, timer.getTime() + 0.5 )
	else
		trigger.action.outTextForUnit(recon_plane.unit:getID(),"Low Alt Camera Off",10,true)
		return
	end
	
	for index, camera in next, recon_plane.cameras.unitCameras do
		local foundUnits = camera:captureUnits(recon_plane.unit, false)
		--util.outText(20,"recon.captureUnits",recon_plane.unit:getName(),util.countList(foundUnits)) 
		recon_plane:filterUnitTargets(foundUnits)
		recon_plane.lowFilm = recon_plane.lowFilm - 1
		trigger.action.outTextForUnit(recon_plane.unit:getID(),"LOW ALT CAPTURE\nFILM LEFT: " .. tostring(recon_plane.lowFilm),10,true)
	end

	return
end

function recon.captureInfra(recon_plane)
	
	if recon_plane.unit == nil then return end
	if not recon_plane.unit:isExist() then return end
		
	if recon_plane.infraCameraOn == true and recon_plane.highFilm > 0 then
		timer.scheduleFunction( recon.captureInfra , recon_plane, timer.getTime() + 3 )
	else
		trigger.action.outTextForUnit(recon_plane.unit:getID(),"High Alt Camera Off",10,true)
		return
	end
	
	for index, camera in next, recon_plane.cameras.infraCameras do
		local foundUnits = camera:captureUnits(recon_plane.unit, true)
		recon_plane:filterInfraTargets(foundUnits)
		recon_plane.highFilm = recon_plane.highFilm - 1
		trigger.action.outTextForUnit(recon_plane.unit:getID(),"HIGH ALT CAPTURE\nFILM LEFT: " .. tostring(recon_plane.highFilm),10,true)
	end	

	return
end

local reconEventHandler = {}

function reconEventHandler:onEvent(event)

	if world.event.S_EVENT_UNIT_LOST == event.id or world.event.S_EVENT_KILL == event.id or world.event.S_EVENT_DEAD == event.id then --dead event is used for deleting recon marks
		
		if world.event.S_EVENT_KILL == event.id then
			local unit = event.target
		else
			local unit = event.initiator
		end
		
		if unit == nil or unit.getCoalition == nil then return end
		if not unit:isExist() then return end
		if recon.currentMarkers[unit:getCoalition()][unit:getName()] ~= nil then --if its in the recon detected target list
			trigger.action.removeMark(recon.currentMarkers[unit:getCoalition()][unit:getName()])
			recon.currentMarkers[unit:getCoalition()][unit:getName()] = nil
		end
		return
	end
	
	if world.event.S_EVENT_BIRTH == event.id then
		
		if string.find(event.initiator:getName(),"Recon") and event.initiator:getPlayerName() ~= nil and recon.airframes[event.initiator:getTypeName()] ~= nil then
			util.log("Recon Birth",event.initiator:getName())
			local recon_plane
			if recon.instances[event.initiator:getName()] == nil then
				
				recon_plane = recon.createReconPlane(event.initiator:getName())
				
				util.addCommandForGroup(event.initiator:getGroup():getID() , "toggle Low Altitude Camera" , nil , recon.toggleLow , recon_plane , timer.getTime() + 10)
				util.addCommandForGroup(event.initiator:getGroup():getID() , "toggle High Altitude Camera" , nil , recon.toggleHigh , recon_plane , timer.getTime() + 10)
				util.addCommandForGroup(event.initiator:getGroup():getID() , "Return Film" , nil , recon.returnFilm , recon_plane , timer.getTime() + 10)
				util.addCommandForGroup(event.initiator:getGroup():getID() , "Display Parameters" , nil , reconPlane.displayParameters , recon_plane , timer.getTime() + 10)
				
				for camName, cameraParams in next, recon.airframes[event.initiator:getTypeName()] do
					local newCameraParams = cameraParams
					newCameraParams[3] = event.initiator:getName()
					recon_plane:addCamera(recon.createCamera(unpack(newCameraParams)))
				end
			else
				recon_plane = recon.instances[event.initiator:getName()]
				recon_plane.unit = Unit.getByName(recon_plane.unitName)
				recon_plane.lowFilm = recon.lowFilm
				recon_plane.highFilm = recon.highFilm
				recon_plane.foundUnits = {}
				recon_plane.foundInfra = {}
				recon_plane.unitCameraOn = false
				recon_plane.infraCameraOn = false
			end
			recon_plane:displayParameters()
		end
	end
end

world.addEventHandler(reconEventHandler)

timer.scheduleFunction(recon.audit, nil, timer.getTime() + 5)

---------------------------------------------------------------------------------------------------------------------------------JTAC\

jtac = {}
local jtacTables = {}

function recon.incrementNextLaserCode()
	--second 5,6,7
	--third/fourth 1-8
	recon.laserCode = recon.laserCode + 1
	if util.getDigit(recon.laserCode,1) > 8 then
		recon.laserCode = (recon.laserCode - 8) + 10
	end

	if util.getDigit(recon.laserCode,2) > 8 then
		recon.laserCode = (recon.laserCode - 80) + 100
	end

	if util.getDigit(recon.laserCode,3) > 7 then
		recon.laserCode = 1511
	end
	return recon.laserCode
end

function jtac:new(t)
	t = t or {}   
	setmetatable(t, self)
	self.__index = self	
	return t
end

local jtacSmokeColor = {}
jtacSmokeColor[1] = 0
jtacSmokeColor[2] = 0
local smokeColorEnum = {}
smokeColorEnum[0] = "Green"
smokeColorEnum[1] = "Red"
smokeColorEnum[2] = "White"
smokeColorEnum[3] = "Orange"
smokeColorEnum[4] = "Blue"


function recon.createJtac(coa,point)
	local instance = jtac:new()

	local foundUnits = {}
	local volS = {
		id = world.VolumeType.SPHERE,
		params = {
			point = point,
			radius = inf.searchRadius["Recon"]
		}
	}
	
	foundUnits = {}
	local ifFound = function(foundItem, val)
		for index, filter in next, inf.unitFilter["Recon"] do
			if string.find(foundItem:getName(),filter) ~= nil and coa ~= foundItem:getCoalition() then
				if string.find(foundItem:getName(),"marker") ~= nil or foundItem:getLife() > 1 then
					table.insert(foundUnits, {dist = util.distanceVec3(foundItem:getPoint(),point), unit = foundItem})
					return true
				end
			end
		end
	end

	world.searchObjects(Object.Category.UNIT, volS, ifFound)
	foundUnits = util.shuffle(foundUnits)
	local group = {}
	group.name = "JTAC " .. tostring(timer.getTime())
	group.task = 'Ground Nothing'
	group.units = {}
	group.visible = false
	group.hiddenOnMFD = true
	local code = recon.incrementNextLaserCode()
	group.units[1] = {}
	group.units[1].name     = "JTAC " .. tostring(math.floor(timer.getTime())) .. " code " .. tostring(code)
	group.units[1].type     = "Soldier M4 GRG"
	group.units[1].x        = point.x
	group.units[1].y        = point.z

	local jtacGroup = coalition.addGroup(ecw.countryEnums[coa], Group.Category.GROUND , group)
	local immortal =
	{ 
		id = 'SetImmortal',
		params = { 
			value = true
		} 
	}
	jtacGroup:getController():setCommand(immortal)

	local expireTime = timer.getTime() + recon.jtacTimer
	local currentTarget = ""
	local currentIndex = 1

	jtacTables[group.units[1].name] = {}

	recon.jtacMarks = recon.jtacMarks + 1
	jtacTables[group.units[1].name].expireTime = timer.getTime() + recon.jtacTimer
	jtacTables[group.units[1].name].foundUnits = foundUnits
	jtacTables[group.units[1].name].currentTarget = ""
	jtacTables[group.units[1].name].currentIndex = 0
	jtacTables[group.units[1].name].spot = ""
	jtacTables[group.units[1].name].code = code
	jtacTables[group.units[1].name].mark = recon.jtacMarks
	jtacTables[group.units[1].name].smokeTime = timer.getTime()
	trigger.action.markToCoalition(jtacTables[group.units[1].name].mark , group.units[1].name .. " | Smoke: " .. tostring(smokeColorEnum[jtacSmokeColor[coa]])  , point , coa , true)

	timer.scheduleFunction(
		function(t)
			local name,color = unpack(t)
			local t = jtacTables[name]
			local foundUnits = t.foundUnits
			local currentIndex = t.currentIndex
			local currentTarget = t.currentTarget
			local nextTarget = false
			if t.expireTime < timer.getTime() then
				util.outTextForCoalition(Unit.getByName(name):getCoalition(),10,name,"expired!")
				trigger.action.removeMark(jtacTables[name].mark)
				Unit.getByName(name):destroy()
				return
			end

			if jtacTables[name].smokeTime + 300 < timer.getTime() then
				trigger.action.smoke(
					jtacTables[name].foundUnits[jtacTables[name].currentIndex].unit:getPoint(),
					color
				)
				jtacTables[name].smokeTime = timer.getTime()
			end

			if jtacTables[name].currentIndex > #foundUnits then
				util.outTextForCoalition(Unit.getByName(name):getCoalition(),10,name,"is out of targets!")
				trigger.action.removeMark(jtacTables[name].mark)
				Unit.getByName(name):destroy()
				return
			end

			if jtacTables[name].currentIndex < 1 then
				jtacTables[name].currentTarget = ""
				jtacTables[name].currentIndex = currentIndex + 1
				nextTarget = true
			elseif not foundUnits[currentIndex].unit:isExist() then
				jtacTables[name].currentTarget = ""
				jtacTables[name].currentIndex = currentIndex + 1
				nextTarget = true
			elseif foundUnits[currentIndex].unit:getLife() < 1 then
				jtacTables[name].currentTarget = ""
				jtacTables[name].currentIndex = currentIndex + 1
				nextTarget = true
			elseif jtacTables[name].foundUnits[currentIndex].unit:getLife() >= 1 and jtacTables[name].currentTarget ~= "" then
				return timer.getTime() + 5
			end

	
			
			if jtacTables[name].currentTarget == "" then
				if foundUnits[currentIndex] ~= nil then
					if not foundUnits[currentIndex].unit:isExist() then
						--util.outTextForCoalition(Unit.getByName(name):getCoalition(),2,name,"searching for new target...")
						return timer.getTime() + 0.1
					else
						if jtacTables[name].currentIndex > #foundUnits then
							Unit.getByName(name):destroy()
							return
						end

						jtacTables[name].currentTarget = jtacTables[name].foundUnits[jtacTables[name].currentIndex].unit:getName()
						trigger.action.smoke(
							jtacTables[name].foundUnits[jtacTables[name].currentIndex].unit:getPoint(),
							color
						)
						jtacTables[name].smokeTime = timer.getTime()
						if jtacTables[name].spot == "" then
							jtacTables[name].spot = Spot.createLaser(
								Unit.getByName(name),
								{x = 0, y = 1000, z = 0},
								jtacTables[name].foundUnits[jtacTables[name].currentIndex].unit:getPoint(),
								jtacTables[name].code
							)
						end

						if jtacTables[name].spot ~= "" then
							if jtacTables[name].spot.setPoint ~= nil then
								jtacTables[name].spot:destroy()
								jtacTables[name].spot = Spot.createLaser(
									Unit.getByName(name),
									{x = 0, y = 1000, z = 0},
									jtacTables[name].foundUnits[jtacTables[name].currentIndex].unit:getPoint(),
									jtacTables[name].code
								)
								--util.outText(5,"new laser point set onto unit", jtacTables[name].foundUnits[jtacTables[name].currentIndex].unit:getName())
								--util.outText(5,"new laser point set onto point", jtacTables[name].spot:getPoint().x, jtacTables[name].spot:getPoint().z)
							end
						end

						util.outTextForCoalition(Unit.getByName(name):getCoalition(),10,name,"lasing next target with",smokeColorEnum[color],"smoke.")
						jtacTables[name].currentTarget = jtacTables[name].foundUnits[currentIndex].unit:getName()
						return timer.getTime() + 5
					end
				end
			end
			
			return timer.getTime() + 5
		end,
		{group.units[1].name,jtacSmokeColor[coa]},
		timer.getTime() + 3
	)

	jtacSmokeColor[coa] = math.fmod(jtacSmokeColor[coa] + 1,5)

end