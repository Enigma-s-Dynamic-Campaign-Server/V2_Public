--persistence

--save hex states
----units
----infrastructure
----aa defense
----depot
----factory


--look for folder, if doesnt exist create

--create file for each group > group values, spawnpoint, units
	--applies to units,
	
--depot/factory 	> both have set spawnpoints, (create master file? with tracking file?) subtract tracking from master to repair? repair rate?
--infrastructure 	> ''
--aa defense

--control loop -resaves units

persist = {}

local dir = lfs.writedir() .. "/ColdWar/Files/Persistence/"

---------------------------------------------------------------------------------------------------------------------------------persist methods

function persist.returnGroup(group)
	if group == nil then return "" end
	if not group:isExist() then return "" end
	local returnString = group:getName() .. "~"
	local unitString = ""
	local dead = false
	for k, unit in next, group:getUnits() do
		dead = false
		if unit:getLife() < 1 then dead = true end
		returnString = returnString .. unit:getName() .. "," .. unit:getTypeName() .. "," ..  unit:getPoint().x .. "," .. unit:getPoint().z  .. "," .. math.rad(util.heading(unit:getName()))  .. "," .. tostring(dead) .. "|" 
	end
	return returnString
end

function persist.returnStatic(static)
	local dead = false
	if not static.getLife then return "" end
	if static:getLife() < 1 then dead = true end
	local returnString = static:getName() .. "," .. static:getPoint().x .. "," .. static:getPoint().z .. "," .. static:getTypeName() .. "," .. math.rad(util.staticHeading(static:getName())) .. "," .. tostring(dead)
	return returnString
end

function persist.saveHexCoalition(hexList)
	local s = ""
	for hexName, hex in next, hexList do
		s = s .. hexName .. ","..tostring(hex.coa).."\n"
	end
	local f = io.open(lfs.writedir() .. "/ColdWar/Files/".. util.getTheatre() ..".hexCoalitions","w")
	f:write(s)
	f:close()
	util.log("saveHexCoalition","saved hex coalitions")
end

function persist.initDepots(hexList)
	
	for hexName,hex in next, hexList do
	
		local depotTable = hex:returnDepotObjects()
		local masterDepot, activeDepot = depotTable[1],depotTable[2]
		
		local static = {}
		
		for k, depotStatic in next, masterDepot do
		
			static = {}
			static.name = depotStatic:getName()
			static.x = depotStatic:getPoint().x
			static.y = depotStatic:getPoint().z
			static.z = depotStatic:getPoint().y
			static.type = depotStatic:getTypeName()
			static.heading = math.rad(util.staticHeading(depotStatic:getName()))
			static.dead = false
			
			hex.depotObjects[static.name] = coalition.addStaticObject(depotStatic:getCountry() , static )
		end
	end
end

function persist.auditHexFiles(hexList)
	
	for hexName, hex in next, hexList do
		if not util.isFile(dir .. hexName .. ".hex") then
			local f = io.open(dir .. hexName .. ".hex","w")
			f:write("EOF")
			f:close()
		end
	end
end

function persist.spawnDepotFromHexFile(hexName,depotObject)
	local f = io.open(dir .. hexName .. ".hex", "r")
	local s = util.split(util.split(f:read("*all"),"ENDPLATOONS")[2],"ENDDEPOTS")[1]
	f:close()
	local isAlive = false
	local actualStatic
	local statics,staticName = util.split(s,"\n"),""
	
	ecw.hexInstances[hexName].activeStatics = {}
	local country = ecw.countryEnums[ecw.hexInstances[hexName].coa]
	
	for staticName, staticTable in next, depotObject.statics do
		depotObject.deadStatics[staticName] = StaticObject.getByName(staticName)
		if StaticObject.getByName(staticName) ~= nil then
			StaticObject.getByName(staticName):destroy()
		end
	end
	
	for i, staticString in next, statics do
		isAlive = false
		staticName = util.split(staticString,",")[1]
		actualStatic = StaticObject.getByName(staticName)
		if depotObject.statics[staticName] ~= nil then
			s = util.respawnStatic(depotObject.statics[staticName],false,false,{true,country}) --todo
			depotObject.deadStatics[staticName] = nil
			depotObject.activeStatics[staticName] = s
			isAlive = true
		end
		
	end
	util.log("spawnDepotFromHexFile",hexName,depotObject.triggerName)
	return
end


function persist.spawnFactoryFromHexFile(hexName,factoryObject)
	local f = io.open(dir .. hexName .. ".hex", "r")
	local s = util.split(util.split(f:read("*all"),"ENDDEPOTS")[2],"ENDFACTORIES")[1]
	f:close()
	local isAlive = false
	local actualStatic
	local statics,staticName = util.split(s,"\n"),""
	
	ecw.hexInstances[hexName].activeStatics = {}
	local country = ecw.countryEnums[ecw.hexInstances[hexName].coa]
	
	for staticName, staticTable in next, factoryObject.statics do
		factoryObject.deadStatics[staticName] = StaticObject.getByName(staticName)
		if StaticObject.getByName(staticName) ~= nil then
			StaticObject.getByName(staticName):destroy()
		end
	end
	
	for i, staticString in next, statics do
		isAlive = false
		staticName = util.split(staticString,",")[1]
		actualStatic = StaticObject.getByName(staticName)
		if factoryObject.statics[staticName] ~= nil then
			s = util.respawnStatic(factoryObject.statics[staticName],false,false,{true,country}) --todo
			factoryObject.deadStatics[staticName] = nil
			factoryObject.activeStatics[staticName] = s
			isAlive = true
		end
		
	end
	util.log("spawnfactoryFromHexFile",hexName,factoryObject.triggerName)
	return
end

function persist.spawnInfraFromHexFile(hexName,infraObject)
	local f = io.open(dir .. hexName .. ".hex", "r")
	local s = util.split(util.split(f:read("*all"),"ENDFACTORIES")[2],"ENDINFRA")[1]
	local active,dead,infraString = "","",util.split(s,"\n")
	f:close()
	
	for k,v in next, infraString do
		if v == infraObject.triggerName then
			dead = infraString[k+1]
			active = infraString[k+2]
		end
	end
	
	if dead ~= "DEAD|" or active ~= "ACTIVE|" then
		infraObject:reveal()
	end
	
	if #util.split(dead,"|") > 1 then
		dead = util.split(dead,"DEAD")[1]
---@diagnostic disable-next-line: cast-local-type
		dead = util.split(dead,"|")
		
		--if #dead >= util.countList(infraObject.statics) then infraObject:createFireMarker() end
		
		for i = 1, #dead do
			infraObject.deadStatics[dead[i]] = dead[i]
			recon.deleteMarkerByName(infraObject.coa,dead[i])
			if StaticObject.getByName(dead[i]) ~= nil then
				trigger.action.explosion(StaticObject.getByName(dead[i]):getPoint() , 500 )
			end
		end
	end
	
	if #util.split(active,"|") > 1 then
		
		active = util.split(active,"ACTIVE")[1]
---@diagnostic disable-next-line: cast-local-type
		active = util.split(active,"|")
		for i = 1, #active do
			infraObject.activeStatics[active[i]] = StaticObject.getByName(active[i])
		end
		
		local sphere = trigger.misc.getZone(infraObject.triggerName)
		--trigger.action.markToAll(5434523456, "test", sphere.point)
		
		 sphere.point.y = land.getHeight({x = sphere.point.x, y = sphere.point.z})
		
		local volS = {
			id = world.VolumeType.SPHERE,
			params = {
				point = sphere.point,
				radius = sphere.radius
			}
		}
		
		local ifFound = function(foundItem, val)
			recon.addMarkerUnit(foundItem,0)
			return true
		end
		
		world.searchObjects(Object.Category.STATIC, volS, ifFound)
	end
	--[[
	local isAlive = false
	local actualStatic
	
	ecw.hexInstances[hexName].activeStatics = {}
	local country = ecw.countryEnums[ecw.hexInstances[hexName].coa]
	
	for staticName, staticTable in next,infraObject.statics do
		infraObject.deadStatics[staticName] = StaticObject.getByName(staticName)
		if StaticObject.getByName(staticName) ~= nil then
			StaticObject.getByName(staticName):destroy()
		end
	end
	
	for i, staticString in next, statics do
		isAlive = false
		staticName = util.split(staticString,",")[1]
		actualStatic = StaticObject.getByName(staticName)
		if infraObject.statics[staticName] ~= nil then
			s = util.respawnStatic(infraObject.statics[staticName],false,false,{true,country}) --todo
			infraObject.deadStatics[staticName] = nil
			infraObject.activeStatics[staticName] = s
			isAlive = true
		end
		
	end
	util.log("spawnInfraFromHexFile",hexName,infraObject.triggerName)
	return
	]]--
end

function persist.spawnUnitsFromHexFile(hexName,spawn)

	local f = io.open(dir .. hexName .. ".hex", "r")
	local s = util.split(f:read("*all"),"ENDPLATOONS")[1]
	f:close()
	local platoons, count, coa = util.split(s,"\n"), 0, ecw.hexInstances[hexName].coa
	local enumTable,platoonTable = {},{}
	for k,v in next, ecw.shortenedEnum do enumTable[k] = 0 end
	--initial release will just spawn the same number of platoons, not exact copy tho
	
	if #platoons <= 0 then return end

	for enum, shortEnum in next, ecw.shortenedEnum do
		for k,v in next, platoons do
			platoonTable = util.split(v,"|")
			if #platoonTable > 1 then
				if string.find(platoonTable[#platoonTable],shortEnum) ~= nil then
					enumTable[enum] = enumTable[enum] + 1
				end
			end
		end
	end
	
	local total = 0
	
	for enum, spawnAmount in next, enumTable do
		if spawnAmount > 0 and spawn then
			util.log("spawnUnitsFromHexFile",hexName,enum,spawnAmount) 
			ecw.hexInstances[hexName]:spawnPlatoons(spawnAmount, te.platoonTemplates[coa], {enum})
		else
			total = total + spawnAmount
		end
	end
	--te.platoonTemplates[tE.coa]
	return total
end

--[[
te.platoonTemplates = {}
te.platoonCounter = 0
te.platoonTemplates[1] = {}
te.platoonTemplates[2] = {}

te.navalTemplates = {}
te.navalTemplates[1] = {}
te.navalTemplates[2] = {}

te.aaTemplates = {}
te.aaTemplates[1] = {}
te.aaTemplates[2] = {}

te.farpGroup = {}
te.farpGroup[1] = Group.getByName("Red FARP Support")
te.farpGroup[2] = Group.getByName("Blue FARP Support")
]]--
function persist.saveUnitTemplatesToFile()

	local dir = ""
	local bluePlatoonsFile,redPlatoonFile

	for index, group in next, coalition.getGroups(1, 2) do
		local typeName = group:getUnits()[1]:getTypeName()

		if string.find(group:getName(),"Platoon") ~= nil then
			table.insert(te.platoonTemplates[1],group)
		end
		if string.find(group:getName(),"Red FARP Support") ~= nil then
			te.farpGroup[1] = group
		end
	end

	for index, group in next, coalition.getGroups(2, 2) do
		local typeName = group:getUnits()[1]:getTypeName()

		if string.find(group:getName(),"Platoon") ~= nil then
			table.insert(te.platoonTemplates[2],group)
		end
		if string.find(group:getName(),"Blue FARP Support") ~= nil then
			te.farpGroup[2] = group
		end
	end

	for index, group in next, coalition.getGroups(1, 3) do
		if string.find(group:getName(),"Naval") ~= nil then
			table.insert(te.navalTemplates[1],group)
		end
	end

	for index, group in next, coalition.getGroups(2, 3) do
		if string.find(group:getName(),"Naval") ~= nil then
			table.insert(te.navalTemplates[2],group)
		end
	end




	te.aaTemplates[1][1] = Group.getByName("RED SAM 1")
	te.aaTemplates[1][2] = Group.getByName("RED SAM 2")
	te.aaTemplates[1][3] = Group.getByName("RED SAM 3")

	te.aaTemplates[2][1] = Group.getByName("BLUE SAM 1")
	te.aaTemplates[2][2] = Group.getByName("BLUE SAM 2")
	te.aaTemplates[2][3] = Group.getByName("BLUE SAM 3")

	local failedToSaveTemplates = false
	if #te.platoonTemplates[1] <= 0 or #te.platoonTemplates[2] <= 0 then
		failedToSaveTemplates = true
	end
	
	local dir = lfs.writedir() .. "/ColdWar/Files/Unit Templates/" .. util.getTheatre() .. "/"
	local blueDir = dir .. "BLUE/"
	local redDir = dir .. "RED/"
	
	for index, group in next, te.platoonTemplates[1] do --red platoon
		local outString = ""
		local platoonString = persist.returnGroup(group) .. "\n"
		outString = outString .. platoonString
		local f = io.open(redDir .. "Platoons/" .. (group:getName()) .. ".template","w")
		f:write(outString)
		f:close()
		group:destroy()
	end

	for index, group in next, te.platoonTemplates[2] do --blue platoon
		local outString = ""
		local platoonString = persist.returnGroup(group) .. "\n"
		outString = outString .. platoonString
		local f = io.open(blueDir .. "Platoons/" .. (group:getName()) .. ".template","w")
		f:write(outString)
		f:close()
		group:destroy()
	end
	
	for index, group in next, te.navalTemplates[1] do --red naval
		local outString = ""
		local platoonString = persist.returnGroup(group) .. "\n"
		outString = outString .. platoonString
		local f = io.open(redDir .. "Naval/" .. (group:getName()) .. ".template","w")
		f:write(outString)
		f:close()
		group:destroy()
	end
	
	for index, group in next, te.navalTemplates[2] do --blue naval
		local outString = ""
		local platoonString = persist.returnGroup(group) .. "\n"
		outString = outString .. platoonString
		local f = io.open(blueDir .. "Naval/" .. (group:getName()) .. ".template","w")
		f:write(outString)
		f:close()
		group:destroy()
	end
	
	for index, group in next, te.aaTemplates[1] do --red aa
		local outString = ""
		local platoonString = persist.returnGroup(group) .. "\n"
		outString = outString .. platoonString
		local f = io.open(redDir .. "SAM/" .. (group:getName()) .. ".template","w")
		f:write(outString)
		f:close()
		group:destroy()
	end
	
	for index, group in next, te.aaTemplates[2] do --blue aa
		local outString = ""
		local platoonString = persist.returnGroup(group) .. "\n"
		outString = outString .. platoonString
		local f = io.open(blueDir .. "SAM/" .. (group:getName()) .. ".template","w")
		f:write(outString)
		f:close()
		group:destroy()
	end
	
	if te.farpGroup[1] ~= nil then --red farp
		local outString = ""
		local platoonString = persist.returnGroup(te.farpGroup[1]) .. "\n"
		outString = outString .. platoonString
		local f = io.open(redDir .. "FARP/" .. (te.farpGroup[1]:getName()) .. ".template","w")
		f:write(outString)
		f:close()
		te.farpGroup[1]:destroy()
	end
	
	if te.farpGroup[2] ~= nil then --blue farp
		local outString = ""
		local platoonString = persist.returnGroup(te.farpGroup[2]) .. "\n"
		outString = outString .. platoonString
		local f = io.open(blueDir .. "FARP/" .. (te.farpGroup[2]:getName()) .. ".template","w")
		f:write(outString)
		f:close()
		te.farpGroup[2]:destroy()
	end

end

function persist.spawnUnitTemplatesFromFiles()
	
	te.platoonTemplates = {}
	te.platoonCounter = 0
	te.platoonTemplates[1] = {}
	te.platoonTemplates[2] = {}

	te.navalTemplates = {}
	te.navalTemplates[1] = {}
	te.navalTemplates[2] = {}

	te.aaTemplates = {}
	te.aaTemplates[1] = {}
	te.aaTemplates[2] = {}

	te.farpGroup = {}
	te.farpGroup[1] = Group.getByName("Red FARP Support")
	te.farpGroup[2] = Group.getByName("Blue FARP Support")
	
	local dir = lfs.writedir() .. "/ColdWar/Files/Unit Templates/" .. util.getTheatre() .. "/"
	local blueDir = dir .. "BLUE/"
	local redDir = dir .. "RED/"
	
	--util.spawnUnitTemplateFromString(templateString, coa)
	--red platoons
	for file in lfs.dir(redDir .. "Platoons/") do --count the number of weather templates for use later
		if file ~= "." and file ~= ".." then
			local f = io.open(redDir .. "Platoons/" .. file,"r")
			util.spawnUnitTemplateFromString(f:read("*all"), 1, Group.Category.GROUND )
			f:close()
		end
	end
	--blue platoons
	for file in lfs.dir(blueDir .. "Platoons/") do --count the number of weather templates for use later
		if file ~= "." and file ~= ".." then
			local f = io.open(blueDir .. "Platoons/" .. file,"r")
			util.spawnUnitTemplateFromString(f:read("*all"), 2, Group.Category.GROUND )
			f:close()
		end
	end	
	--red naval
	for file in lfs.dir(redDir .. "Naval/") do --count the number of weather templates for use later
		if file ~= "." and file ~= ".." then
			local f = io.open(redDir .. "Naval/" .. file,"r")
			util.spawnUnitTemplateFromString(f:read("*all"), 1, Group.Category.SHIP )
			f:close()
		end
	end
	--blue naval
	for file in lfs.dir(blueDir .. "Naval/") do --count the number of weather templates for use later
		if file ~= "." and file ~= ".." then
			local f = io.open(blueDir .. "Naval/" .. file,"r")
			util.spawnUnitTemplateFromString(f:read("*all"), 2, Group.Category.SHIP )
			f:close()
		end
	end	
	--red farp
	for file in lfs.dir(redDir .. "FARP/") do --count the number of weather templates for use later
		if file ~= "." and file ~= ".." then
			local f = io.open(redDir .. "FARP/" .. file,"r")
			util.spawnUnitTemplateFromString(f:read("*all"), 1, Group.Category.GROUND )
			f:close()
		end
	end	
	--blue farp
	for file in lfs.dir(blueDir .. "FARP/") do --count the number of weather templates for use later
		if file ~= "." and file ~= ".." then
			local f = io.open(blueDir .. "FARP/" .. file,"r")
			util.spawnUnitTemplateFromString(f:read("*all"), 2, Group.Category.GROUND )
			f:close()
		end
	end		
	--red sam
	for file in lfs.dir(redDir .. "SAM/") do --count the number of weather templates for use later
		if file ~= "." and file ~= ".." then
			local f = io.open(redDir .. "SAM/" .. file,"r")
			util.spawnUnitTemplateFromString(f:read("*all"), 1, Group.Category.GROUND )
			f:close()
		end
	end
	--blue sam
	for file in lfs.dir(blueDir .. "SAM/") do --count the number of weather templates for use later
		if file ~= "." and file ~= ".." then
			local f = io.open(blueDir .. "SAM/" .. file,"r")
			util.spawnUnitTemplateFromString(f:read("*all"), 2, Group.Category.GROUND )
			f:close()
		end
	end
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	for index, group in next, coalition.getGroups(1, 2) do
		if string.find(group:getName(),"Platoon") ~= nil then
			table.insert(te.platoonTemplates[1],group)
		end
		if string.find(group:getName(),"Red FARP Support") ~= nil then
			te.farpGroup[1] = group
		end
	end

	for index, group in next, coalition.getGroups(2, 2) do
		if string.find(group:getName(),"Platoon") ~= nil then
			table.insert(te.platoonTemplates[2],group)
		end
		if string.find(group:getName(),"Blue FARP Support") ~= nil then
			te.farpGroup[2] = group
		end
	end

	for index, group in next, coalition.getGroups(1, 3) do
		if string.find(group:getName(),"Naval") ~= nil then
			table.insert(te.navalTemplates[1],group)
		end
	end

	for index, group in next, coalition.getGroups(2, 3) do
		if string.find(group:getName(),"Naval") ~= nil then
			table.insert(te.navalTemplates[2],group)
		end
	end

	for i = 0,1 do te.aaTemplates[1][i] = Group.getByName("RED SAM 1")  end
	for i = 2,3 do te.aaTemplates[1][i] = Group.getByName("RED SAM 2")  end
	for i = 4,20 do te.aaTemplates[1][i] = Group.getByName("RED SAM 3") end
	for i = 0,1 do te.aaTemplates[2][i] = Group.getByName("BLUE SAM 1") end
	for i = 2,3 do te.aaTemplates[2][i] = Group.getByName("BLUE SAM 2") end
	for i = 4,20 do te.aaTemplates[2][i] = Group.getByName("BLUE SAM 3") end
	
	return
end

function persist.saveToHexFiles(hexList,time)
	
	for hexName, hex in next, hexList do
		hex:auditAirbaseOwnership()
	end

	local platoonString
	local hexString = ""
	util.log("saveToHexFiles","persistence save started.",timer.getTime())
	persist.saveHexCoalition(hexList)
	for hexName, hex in next, hexList do
		if util.isFile(dir .. hexName .. ".hex") then
			--units			
			hexString = "STARTPLATOONS\n"
			for enum, triggerTable in next, hex.groups do
				for triggerName, platoon in next, triggerTable do
					platoonString = persist.returnGroup(platoon) .."|".. hexName .."|".. triggerName .. "|\n"
					hexString = hexString .. platoonString
				end
			end
			
			hexString = hexString .. "ENDPLATOONS\n"
			
			
			--depots
			local s
			for depotObjectName, depotObject in next, hex.depotObjects do
				for staticName,staticObject in next, depotObject.statics do
					s = StaticObject.getByName(staticObject.name)
					if s ~= nil then
						if s:getLife() >= 1 and string.find(s:getName(),"Depot") ~= nil then
							local returnObj = persist.returnStatic(s)
							if returnObj ~= nil then
								hexString = hexString .. persist.returnStatic(s) .. "\n"
							end
						end
					end
				end				
			end
			
			hexString = hexString .. "ENDDEPOTS\n"
			
			--factory
			local s
			for factoryObjectName, factoryObject in next, hex.factoryObjects do
				for staticName,staticObject in next, factoryObject.statics do
					s = StaticObject.getByName(staticObject.name)
					if s ~= nil then
						if s:getLife() >= 1 and string.find(s:getName(),"Factory") ~= nil then
							local returnObj = persist.returnStatic(s)
							if returnObj ~= nil then
								hexString = hexString .. persist.returnStatic(s) .. "\n"
							end
						end
					end
				end				
			end
			
			hexString = hexString .. "ENDFACTORIES\n"
			--infrastructure
			local s
			local alreadyDead = {}
			for infraName, infraObject in next, hex.infrastructureObjects do
				s = infraName .. "\nDEAD|"
				for staticName,staticObject in next, infraObject.deadStatics do
					s = s .. staticName .. "|"
					alreadyDead[staticName] = true
				end
				s = s .. "\nACTIVE|"
				for staticName,staticObject in next, infraObject.activeStatics do
					if alreadyDead[staticName] ~= true then
						s = s .. staticName .. "|"
					end
				end
				hexString = hexString .. s .. "\n"
			end
			hexString = hexString .. "ENDINFRA\n"
			-----------------------------------------------
			local f = io.open(dir .. hexName .. ".hex","w")
			f:write(hexString)
			f:close()
		end
	end
	util.log("saveToHexFiles","persistence save done.",timer.getTime())
	return time + 60
end

--persist.initDepots(ecw.hexInstances)
persist.auditHexFiles(ecw.hexInstances)
if ecw.startInit == true or ecw.loadFromPersistence == true then --fix for wrong coalition on depots during campaign reset
	timer.scheduleFunction(
		function(hexList)
			persist.saveToHexFiles(hexList,0)
			
			f = io.open(lfs.writedir() .. "/ColdWar/.loadFromPersistence","w")
			s = f:write("false")
			f:close()
			
			for hexName,hex in next, hexList do

				for depotName,depotObject in next, hex.depotObjects do
					persist.spawnDepotFromHexFile(hexName,depotObject)
				end
				for depotName,factoryObject in next, hex.factoryObjects do
					persist.spawnFactoryFromHexFile(hexName,factoryObject)
				end
				
			end
		end,
		ecw.hexInstances,
		timer.getTime() + 1
	)
end



local persistEventHandler = {}

function persistEventHandler:onEvent(event)

	if world.event.S_EVENT_DEAD == event.id then --dead event is used for deleting recon marks
		return
	end
end

world.addEventHandler(persistEventHandler)

persist.id = timer.scheduleFunction(persist.saveToHexFiles , ecw.hexInstances , timer.getTime() + 20 )
