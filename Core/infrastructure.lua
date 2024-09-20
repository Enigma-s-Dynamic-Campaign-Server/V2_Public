--infra
----group based on table
----table values > hex assigned, table of units w/ statuses


infrastructure.instances = {}
infrastructure.markers = {}
infra = {}
infra.fireMarker = {}

infra.markerTable = {}
infra.markerCounter = 2309282
infrastructure[1] = {}
infrastructure[1].damaged = {}
infrastructure[2] = {}
infrastructure[2].damaged = {}
infrastructure.countryEnum = {}
infrastructure.countryEnum[1] = country.id.RUSSIA
infrastructure.countryEnum[2] = country.id.USA

function infra:new(t)
	t = t or {}   
	setmetatable(t, self)
	self.__index = self	
	return t
end

function infrastructure.createInfra(triggerName)

	local instance = infra:new()
	infrastructure.instances[triggerName] = instance
	instance.fire = {}
	instance.ratio = 0
	instance.triggerTable = {}
	instance.triggerName = triggerName
	instance.coa = 0
	instance.hex = ""
	instance.statics = {} --name/[list of object attributes for spawning]
	instance.activeStatics = {}
	instance.deadStatics = {}
	instance.marker = {}
	instance.markerPoint = {}
	instance.markerName = {}
	instance.fireMarker = 0
	
	return instance
end


---------------------------------------------------------------------------------------------------------------------------------infra methods

--reveal groups

--[[
local testGroup = {}
testGroup.name = "farpg"
testGroup.task = 'Ground Nothing'
testGroup.units = {}
testGroup.units[1] = {}
testGroup.units[1].name = "farp1"
testGroup.units[1].type = "Invisible FARP"
testGroup.units[1].x = StaticObject.getByName("b"):getPoint().x
testGroup.units[1].y = StaticObject.getByName("b"):getPoint().z

coalition.addGroup(StaticObject.getByName("b"):getCountry() , -1 , testGroup )
]]--


function infra.initFireMarker()
	for k, v in next, env.mission.drawings.layers[4].objects do
		
		if v.name == "Fire Template" then
			local pointTable = {}
			infra.fireMarker = v
			for k in ipairs(v.points) do
					pointTable[k] = {x = v.points[k].x, z = v.points[k].y, y = v.points[k].y + 30}
			end
			--pointTable[#pointTable+1],pointTable[#pointTable+2],pointTable[#pointTable+3] = {1, 0, 0, 1},{1, 0.5, 0, 1},1
			--trigger.action.markupToAll(7, -1 , 412980498357 ,unpack(pointTable))
			infra.fireMarkerTable = pointTable
		end
	end
end

infra.initFireMarker()

function infra:createFireMarker()
	local pointTable = infra.fireMarkerTable
	
	--[[
	for k, v in next, env.mission.drawings.layers[4].objects do
		
		if v.name == "Fire Template" then
			pointTable = {}
			infra.fireMarker = v
			for k in ipairs(v.points) do
					pointTable[k] = {x = v.points[k].x, z = v.points[k].y, y = v.points[k].y + 30}
			end
			break
			--pointTable[#pointTable+1],pointTable[#pointTable+2],pointTable[#pointTable+3] = {1, 0, 0, 1},{1, 0.5, 0, 1},1
			--trigger.action.markupToAll(7, -1 , 412980498357 ,unpack(pointTable))
		end
	end
	]]--
	
	local pointX = trigger.misc.getZone(self.triggerName).point.x
	local pointZ = trigger.misc.getZone(self.triggerName).point.z
	
	for index, point in next, pointTable do
		if type(point) == "table" then
			if point.x ~= nil and point.z ~= nil then
				point.x = point.x + pointX
				point.z = point.z + pointZ
			end
		end
	end
	
	pointTable[#pointTable+1],pointTable[#pointTable+2],pointTable[#pointTable+3] = {1, 0, 0, 1},{1, 0.5, 0, 1},1
	util.log("Fire Marker",self.triggerName)
	trigger.action.markupToAll(7, -1 , infra.markerCounter ,unpack(pointTable))
	self.fireMarker = infra.markerCounter
	infra.markerCounter = infra.markerCounter + 1

end

function infra:reveal(...)
	
	local flip,country = false, infrastructure.countryEnum[self.coa]
	if arg[1] == true then flip = true end
	if arg[2] == true then country = infrastructure.countryEnum[ecw.oppositeCoa[self.coa]] end
	
	for staticName, static in next, self.statics do
		if (flip or self.activeStatics[staticName] == nil) and self.deadStatics[staticName] == nil then
			local s = util.respawnStatic(static,false,false,{true,country})
			self.activeStatics[staticName] = s
			--if timer.getTime() < 100 then trigger.action.explosion(s:getPoint() , 50 ) end
		end
	end
	self:audit()
	return self.activeStatics
end

--add newly repaired groups to be reconned (remove them from revealed group)

function infra:swapCoalition(infraType)
	
	local isExist = false
	for staticName,static in next, self.statics do
		local s = StaticObject.getByName(staticName)
		if s ~= nil then
			if s:isExist() then
				isExist = true
				s:destroy()
			end
			self.activeStatics[staticName] = nil
		end
	end

	infrastructure[ecw.oppositeCoa[self.coa]].damaged[self.triggerName] = nil
	infrastructure[self.coa].damaged[self.triggerName] = nil

	if infraType == "Infrastructure" then
		local s = util.respawnStatic(StaticObject.getByName("infraMarker"),true,true,{false,infrastructure.countryEnum[self.coa]},self.markerPoint.x,self.markerPoint.z,self.markerName)
		self.marker = s
		infrastructure.markers[self.markerName] = self
	end

	return
end

function infra:repair()

	for staticName,static in next, self.deadStatics do
		--s = util.respawnStatic(self.statics[staticName],false,false,{true,infrastructure.countryEnum[self.coa]})
		--s:destroy()
		self.deadStatics[staticName] = nil
		self.activeStatics[staticName] = nil
	end
	infrastructure[self.coa].damaged[self.triggerName] = nil
	util.outTextForCoalition(self.hex.coa,10,self.hex.name,"has repaired",self.triggerName)
	Campaign_log:info("Infrastructure Repair",util.ct("Repaired:",self.triggerName,"| coa:",self.coa,"| hex:",self.hex.name))
	self:audit()
	if string.find(self.triggerName,"Infra") == nil then self:reveal() end
	return self.triggerName
end

--audit

function infra:audit()
	
	self.coa = self.hex.coa
	for staticName,static in next, self.activeStatics do
		if static.getLife ~= nil and static.isExist ~= nil then
			if static:isExist() then
				if static:getLife() < 1 and self.deadStatics[staticName] == nil then
					self.deadStatics[staticName] = staticName
					self.activeStatics[staticName] = nil
					util.log("infra audit",staticName,"added to dead statics.")
					recon.deleteMarkerByName(self.coa,staticName)
				end
			elseif self.deadStatics[staticName] == nil then
				self.deadStatics[staticName] = staticName
				self.activeStatics[staticName] = nil
				util.log("infra audit",staticName,"added to dead statics.")
				recon.deleteMarkerByName(self.coa,staticName)
			end
		else
			self.activeStatics[staticName] = nil
			self.deadStatics[staticName] = staticName
		end
	end
	
	local nextStatic = nil

	local total,dead = util.countList(self.statics), util.countList(self.deadStatics)
	if self.triggerName:find("Depot") ~= nil or  self.triggerName:find("Factory") ~= nil then
		dead = total - util.countList(self.activeStatics)
	end

	if total == 0 then return 0 end
	local ratio = dead / total
	self.ratio = ratio
	if dead > 0 then
		infrastructure[self.coa].damaged[self.triggerName] = self
		if self.fireMarker == 0 then
			local a = 1
			--self:createFireMarker()
		end
	else
		infrastructure[self.coa].damaged[self.triggerName] = nil
		if self.fireMarker > 0 then
			local a = 1
			--trigger.action.removeMark(self.fireMarker)
		end
		self.fireMarker = 0
	end
	util.log("infra audit ratio",ratio)
	return ratio
end

--init infraMarker

function infrastructure.infraInit(hexList)
	
	local debugTable = {}
	local neutralTable = {}

	for index, triggerTable in next, env.mission.triggers.zones do
		if triggerTable.name:find("Infrastructure") ~= nil then
			
			local tempCoords = {x = triggerTable.x, z = triggerTable.y, y = 0}
			for hexName,hex in next, hexList do
			
				local isInHex = ecw.pointInsideHex(tempCoords,hex)

				if isInHex == true then
					neutralTable[triggerTable.name] = true
					--catalog and destroy group
					infrastructure.instances[triggerTable.name] = {}
					local instance = infrastructure.createInfra(triggerTable.name)
					instance.hex = hex
					instance.coa = hex.coa
					instance.triggerTable = triggerTable
					hex.poi["Infrastructure"] = triggerTable
					hex.infrastructureObjects[triggerTable.name] = instance
					util.log("InfraInit",hex.name,triggerTable.name)
					
					local foundUnits = {}
					local sphere = trigger.misc.getZone(triggerTable.name)
					sphere.point.y = land.getHeight({x = sphere.point.x,y = sphere.point.z})
					local volS = {
						id = world.VolumeType.SPHERE,
						params = {
							point = sphere.point,
							radius = sphere.radius
						}
					}
					
					local ifFound = function(foundItem, val)
						instance.statics[foundItem:getName()] = util.returnStaticTable(foundItem,false,false)
						foundItem:destroy()
						return true
					end
					
					world.searchObjects(Object.Category.STATIC, volS, ifFound)
					
				--create marker
				
					local s = util.respawnStatic(StaticObject.getByName("infraMarker"),true,true,{false,infrastructure.countryEnum[instance.coa]},triggerTable.x,triggerTable.y,triggerTable.name .. "_marker")
					instance.marker = s
					instance.markerPoint = s:getPoint()
					instance.markerName = s:getName()
					infrastructure.markers[triggerTable.name .. "_marker"] = instance
					break
				end
			end
		end
	end

	for index, triggerTable in next, env.mission.triggers.zones do
		if neutralTable[triggerTable.name] == nil and triggerTable.name:find("Infrastructure") ~= nil then
			local foundUnits = {}
			local sphere = trigger.misc.getZone(triggerTable.name)
			sphere.point.y = land.getHeight({x = sphere.point.x,y = sphere.point.z})
			local volS = {
				id = world.VolumeType.SPHERE,
				params = {
					point = sphere.point,
					radius = sphere.radius
				}
			}
			
			local ifFound = function(foundItem, val)
				foundItem:destroy()
				return true
			end
			world.searchObjects(Object.Category.STATIC, volS, ifFound)
		end
	end

	return
end


function infrastructure.depotInit(hexList)

	local debugTable = {}
	local neutralTable = {}
	local markString = "DEPT"

	for index, triggerTable in next, env.mission.triggers.zones do
		if triggerTable.name:find("Depot") ~= nil then
		
			local tempCoords = {x = triggerTable.x, z = triggerTable.y, y = 0}
			for hexName,hex in next, hexList do
			
				local isInHex = ecw.pointInsideHex(tempCoords,hex)
				
				if isInHex == true then
				--catalog and destroy group
					neutralTable[triggerTable.name] = true
					infrastructure.instances[triggerTable.name] = {}
					local instance = infrastructure.createInfra(triggerTable.name)
					instance.hex = hex
					instance.coa = hex.coa
					instance.triggerTable = triggerTable
					hex.depotObjects[triggerTable.name] = instance
					util.log("depotInit",hex.name,triggerTable.name)
					markString = markString .. "|" .. hex.name
					local foundUnits = {}
					local sphere = trigger.misc.getZone(triggerTable.name)
					sphere.point.y = land.getHeight({x = sphere.point.x,y = sphere.point.z})
					local volS = {
						id = world.VolumeType.SPHERE,
						params = {
							point = sphere.point,
							radius = sphere.radius
						}
					}
					
					local ifFound = function(foundItem, val)
						instance.statics[foundItem:getName()] = util.returnStaticTable(foundItem,false,false)
						return true
					end
					
					world.searchObjects(Object.Category.STATIC, volS, ifFound)
					--spawn through persistence function
					break
				end
			end
		end
	end

	trigger.action.markToAll(294387534 , markString , {x = 0, y = 0, z = 0} , false, "Depot INIT")

	for index, triggerTable in next, env.mission.triggers.zones do
		if neutralTable[triggerTable.name] == nil and triggerTable.name:find("Depot") ~= nil then
			local foundUnits = {}
			local sphere = trigger.misc.getZone(triggerTable.name)
			sphere.point.y = land.getHeight({x = sphere.point.x,y = sphere.point.z})
			local volS = {
				id = world.VolumeType.SPHERE,
				params = {
					point = sphere.point,
					radius = sphere.radius
				}
			}
			
			local ifFound = function(foundItem, val)
				foundItem:destroy()
				return true
			end
			world.searchObjects(Object.Category.STATIC, volS, ifFound)
		end
	end
	return
end


function infrastructure.factoryInit(hexList)
	
	local debugTable = {}
	local neutralTable = {}
	local markString = "FACT"

	for index, triggerTable in next, env.mission.triggers.zones do
		if triggerTable.name:find("Factory") ~= nil then
		
			local tempCoords = {x = triggerTable.x, z = triggerTable.y, y = 0}
			for hexName,hex in next, hexList do
			
				local isInHex = ecw.pointInsideHex(tempCoords,hex)
				
				if isInHex == true then
					neutralTable[triggerTable.name] = true
				--catalog and destroy group
					infrastructure.instances[triggerTable.name] = {}
					local instance = infrastructure.createInfra(triggerTable.name)
					instance.hex = hex
					instance.coa = hex.coa
					instance.triggerTable = triggerTable
					hex.factoryObjects[triggerTable.name] = instance
					util.log("factoryInit",hex.name,triggerTable.name)
					markString = markString .. "|" .. hex.name
					
					local foundUnits = {}
					local sphere = trigger.misc.getZone(triggerTable.name)
					sphere.point.y = land.getHeight({x = sphere.point.x,y = sphere.point.z})
					local volS = {
						id = world.VolumeType.SPHERE,
						params = {
							point = sphere.point,
							radius = sphere.radius
						}
					}
					
					local ifFound = function(foundItem, val)
					
						if debugTable[foundItem:getTypeName()] == nil and foundItem:getName() == 'static' then
							debugTable[foundItem:getTypeName()] = 1
						elseif debugTable[foundItem:getTypeName()] ~= nil and foundItem:getName() == 'static' then
							debugTable[foundItem:getTypeName()] = debugTable[foundItem:getTypeName()] + 1
						end
						instance.statics[foundItem:getName()] = util.returnStaticTable(foundItem,false,false)
						return true
					end
					
					world.searchObjects(Object.Category.STATIC, volS, ifFound)
					--spawn through persistence function
					break
				end
			end
		end
	end
	
	trigger.action.markToAll(294387535 , markString , {x = 0, y = 0, z = 0} , false, "Factory INIT")

	for k,v in next, debugTable do
		util.outText(120, k,v)
		util.log("debug static", k,v)
	end
	for index, triggerTable in next, env.mission.triggers.zones do
		if neutralTable[triggerTable.name] == nil and triggerTable.name:find("Factory") ~= nil then
			local foundUnits = {}
			local sphere = trigger.misc.getZone(triggerTable.name)
			sphere.point.y = land.getHeight({x = sphere.point.x,y = sphere.point.z})
			local volS = {
				id = world.VolumeType.SPHERE,
				params = {
					point = sphere.point,
					radius = sphere.radius
				}
			}
			local ifFound = function(foundItem, val)
				foundItem:destroy()
				return true
			end
			world.searchObjects(Object.Category.STATIC, volS, ifFound)
		end
	end
	return
end
--[[
local function testFunction(test)
	--infrastructure.instances["Infrastructure 1-37"]:repair()
	ecw.hexInstances["Sector 5-11"].usableWarMaterial = -100
	return
end

timer.scheduleFunction(testFunction , infrastructure.instances["Infrastructure 1-37"] , timer.getTime() + 60 )
]]--


