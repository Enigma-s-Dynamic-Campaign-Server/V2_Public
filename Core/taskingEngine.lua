--tasking engine

taskingEntity = {}

te.id = 0
te.taskingEntities = {}
te.reinforcementTickRequirement = math.ceil(te.loopTime / (14400 / te.initialPlatoonCount))
te.nextTick = 0
te.wmCreated = {}
te.wmCreated[1] = 0
te.wmCreated[2] = 0
te.wmDistributed = {}
te.wmDistributed[1] = 0
te.wmDistributed[2] = 0
te.wmReceived = {}
te.wmReceived[1] = 0
te.wmReceived[2] = 0
te.numberOfFrontlines = 0
te.platoonsPerFrontline = 0

depotHealth = {}
factoryHealth = {}
infrastructureHealth = {}

depotHealth[1],depotHealth[2] = 0,0
factoryHealth[1],factoryHealth[2] = 0,0
infrastructureHealth[1],infrastructureHealth[2] = 0,0

function taskingEntity:new(t)
	t = t or {}   
	setmetatable(t, self)
	self.__index = self	
	return t
end

function te.createTaskingEntity(name, coa)

	local instance = taskingEntity:new()
	te.taskingEntities[name] = instance
	
	instance.name = name
	instance.coa = coa
	instance.friendlyHexList = {}
	instance.reinforcementTick = 0
	instance.surplusPlatoons = 0
	instance.attritionValue = 0
	instance.csarReconCounter = 0

	instance.factoryHealth = 1
	
	return instance
end

local dir = lfs.writedir() .. "/ColdWar/Files/Persistence/"


---------------------------------------------------------------------------------------------------------------------------------taskingEntity function definitions
function taskingEntity:countFriendlyPlatoons(hexList)
	local platoonCount = 0
	for hexName, hex in next, hexList do
		if hex.coa == self.coa then
			platoonCount = platoonCount + hex:auditSpawnpoints()
		end
	end 
	return platoonCount
end

function taskingEntity:populateFriendlyHexes(hexList)
	
	self.friendlyHexList = {}
	
	for k, v in next, hexList do
		if v.coa == self.coa then
			self.friendlyHexList[k] = v
		end
	end
	
	return self.friendlyHexList
end

function taskingEntity:frontlinePathing(hexList)

	self:populateFriendlyHexes(hexList)
	ecw.assignHexType(hexList)
	ecw.updateHexOwnershipColors(hexList)
	
	for k, v in next, self.friendlyHexList do
		v:findFrontlineSides()
	end

	for k, v in next, hexList do
		v:calculateStrategicValue()
	end
	
	for k, v in next, hexList do
		if v.type == "FRONTLINE" and v.coa ~= 0 then
			local friendlyPaths = v:findShortestPaths(hexList, 0, false, false)
			
			v.frontlineStrategicValue = v.strategicValue
			
			for hexName, hexPathValue in next, friendlyPaths do
				
				local mod = hexList[hexName].strategicValue / (hexPathValue + 1)
				
			
				v.frontlineStrategicValue = v.frontlineStrategicValue + mod
			end
			--trigger.action.outText(v.name .. " " .. tostring(v.frontlineStrategicValue), 2000)
		end
	end
	
end

function taskingEntity:findSpawnPoints(hexList)
	for name,hex in next, hexList do
		hex:findPlatoonSpawnpoints()
	end
end

function taskingEntity:spawnPlatoonsAtHex(hex, amount, templates, enums, modifier)
	hex.spawnedPlatoonCount = amount
	hex:spawnPlatoons(amount, templates, enums, modifier)
end

function taskingEntity:countDepots(hexList)

	self.depotCount = 0

	for k,v in next, hexList do
		if v.coa == self.coa and v.poi["Depot"] ~= nil then
			self.depotCount = self.depotCount + 1
		end
	end
	return self.depotCount
end

function taskingEntity:factoriesToDepots(hexList)

	local paths, distributionAmount, depotIntake, total
	local totalAmount = 0
	local depotCount = self:countDepots(hexList)
	
	for k,v in next, hexList do
		if v.coa == self.coa and v.poi["Factory"] ~= nil then
			infraPaths = v:findShortestPaths(hexList, 1, false, false)
			truePaths = v:findShortestPaths(hexList, 0, false, false)
			distributionAmount = v.warMaterial / depotCount
			for hexName, infraModifier in next, infraPaths do
				if hexList[hexName].coa == v.coa and hexList[hexName].poi["Depot"] ~= nil and hexList[hexName].poi["Factory"] == nil then					
				
					depotIntake = distributionAmount / ((infraModifier - truePaths[hexName]))
					
					local extraWarMaterial = (hexList[hexName].warMaterial + depotIntake) - ecw.maxWarMaterial
					if extraWarMaterial > 0 then depotIntake = depotIntake - ((hexList[hexName].warMaterial + depotIntake)- ecw.maxWarMaterial) end

					if depotIntake > v.warMaterial then depotIntake = v.warMaterial end
					
					depotIntake = math.floor(depotIntake) * (2 - v.factoryHealth)
					if depotIntake <= 0 then depotIntake = 0 end					
					
					hexList[hexName].warMaterial = hexList[hexName].warMaterial + depotIntake
					v.warMaterial = v.warMaterial - depotIntake
					totalAmount = totalAmount + depotIntake
					util.log("TE Factory -> Depot","Factory Sector: ",v.name,"| Depot Sector: ", hexName,"| Modifier: ",((infraModifier - truePaths[hexName])),"| EWM:" ,extraWarMaterial ,"| WM Transferred: ", depotIntake, "| WM Remaining: ", v.warMaterial)
					
				end
			end
		end
	end
	return totalAmount
end

function taskingEntity:depotsToFrontline(hexList, enemyTE)
	self:frontlinePathing(hexList)
	enemyTE:frontlinePathing(hexList)
	local t,amount,total = {}, 0, 0
	local requestTable = {}
	local useTable = {}
	local totalAmount = 0

	local hexStrategicValue, count = 0, 0

	for k, v in next, hexList do
		hexStrategicValue = 0
		if v.coa == self.coa then
			for neighborSide, neighbor in next, v.neighbors do
				if neighbor.coa ~= v.coa and v.type == 'FRONTLINE' then
					hexStrategicValue = hexStrategicValue + neighbor.frontlineStrategicValue
				end
			end
			
			if v.type == 'FRONTLINE' then
				v.neighborStrategicValue = math.log(hexStrategicValue)
				table.insert(t, v)
				requestTable[v.name] = {}
			end
		end
	end

	table.sort(t, function (k1, k2) return k1.neighborStrategicValue > k2.neighborStrategicValue end)
	
	for i in ipairs(t) do
		total = total + t[i].neighborStrategicValue
	end
	
	local platoonCount = te.initialPlatoonCount
	local total, request = 0, {}
	
	for index, hex in next, t do 
		total = total + hex.neighborStrategicValue
		request = hex:frontlineHexSupplyRequest(hexList)
		requestTable[request["hex"]] = request
	end

	local highestRequest, tempTable, supplyAmount, defaultDepotSupply, currentRequest = 1, {}, 0, te.defaultSupplyAmount * 2, {}
	
	local depotBalances = {}
	local depotWithdrawals = {}
	
	for i in ipairs(t) do
	
		currentRequest = requestTable[t[i].name]
		if currentRequest["depot"] ~= nil then
			
			
			if depotBalances[currentRequest["depot"]] == nil then
				depotBalances[currentRequest["depot"]] = defaultDepotSupply
				if hexList[currentRequest["depot"]].warMaterial < defaultDepotSupply then
					depotBalances[currentRequest["depot"]] = hexList[currentRequest["depot"]].warMaterial
				end
			end			
			
			if currentRequest["infraModifier"] == 1 then currentRequest["infraModifier"] = 1.5 end

			local infrastructureModifier = (currentRequest["infraModifier"] * ecw.depotDistanceModifier)
			if infrastructureModifier == 0 then infrastructureModifier = 1 end
			
			supplyAmount = (depotBalances[currentRequest["depot"]] * (t[i].neighborStrategicValue / total)) / infrastructureModifier
			
			if depotWithdrawals[currentRequest["depot"]] == nil then depotWithdrawals[currentRequest["depot"]] = 0 end
			
			if supplyAmount > depotBalances[currentRequest["depot"]] then supplyAmount = depotBalances[currentRequest["depot"]] end
			
			--util.log("Test",supplyAmount, t[i].warMaterial, ecw.maxWarMaterial, supplyAmount - (ecw.maxWarMaterial - t[i].warMaterial))		
			if (supplyAmount + t[i].usableWarMaterial) > ecw.maxWarMaterial then
				supplyAmount = supplyAmount - (t[i].usableWarMaterial - ecw.maxWarMaterial)
			end
			
			supplyAmount = supplyAmount / hexList[currentRequest["depot"]].depotHealth
			totalAmount = totalAmount + supplyAmount
			depotBalances[currentRequest["depot"]] = depotBalances[currentRequest["depot"]] - supplyAmount
			t[i].usableWarMaterial = t[i].usableWarMaterial + supplyAmount
			
			--util.outText(2,t[i].name,math.floor(t[i].usableWarMaterial), supplyAmount)
			
			depotWithdrawals[currentRequest["depot"]] = depotWithdrawals[currentRequest["depot"]] + supplyAmount
			
			util.log("Depot Supply Request","| Depot:",currentRequest["depot"],"| Hex:",t[i].name,"|Depot supply:",hexList[currentRequest["depot"]].warMaterial,"| Depot Health:",hexList[currentRequest["depot"]].depotHealth ,"| Strategic Value:",t[i].neighborStrategicValue,"| Supply Amount:",supplyAmount,"| infraModifier:",currentRequest["infraModifier"],"| Total WM",t[i].usableWarMaterial)
		end
	end
	
	for depotName, withdrawal in next, depotWithdrawals do
		hexList[depotName].warMaterial = hexList[depotName].warMaterial - withdrawal
		util.log("Depot Withdrawal", "Depot:",depotName,"Amount:",withdrawal)
	end
	
	return totalAmount
end

function taskingEntity:manufactureWarMaterial(hexList)
	
	local amount = 0
	local factories = {}
	local totalAmount = 0
	
	for hexName,hex in next, hexList do
		if hex.coa == self.coa and hex.poi["Factory"] ~= nil then
			table.insert(factories,hex)
		end
	end
	
	amount = te.manufacturedWarMaterial / (#factories)
	
	for i in ipairs(factories) do
		if factories[i].warMaterial < ecw.maxWarMaterial then
			factories[i].warMaterial = factories[i].warMaterial + (amount * (2 - factories[i].factoryHealth))
			 totalAmount = totalAmount + (amount * factories[i].factoryHealth)
			util.log("Manufacturing",factories[i].name,"manufactured",(amount * factories[i].factoryHealth),"war material | health:",factories[i].factoryHealth,"| amount:",amount,"| WM:",factories[i].warMaterial)
		else
			util.log("Manufacturing",factories[i].name,"stock is full at",factories[i].warMaterial,". skipping manufacturing.")
		end
	end
	
	return totalAmount
end

function taskingEntity:calculateStrategicValue(hexList,count2)

	local t,amount = {}, 0
	local hexStrategicValue, count, enums = 0, 0, {}

	for k, v in next, hexList do
		hexStrategicValue = 0
		if v.coa == self.coa then
			for neighborSide, neighbor in next, v.neighbors do
				if neighbor.coa ~= v.coa and v.type == 'FRONTLINE' then
					hexStrategicValue = hexStrategicValue + neighbor.frontlineStrategicValue
				end
			end
			
			if v.type == 'FRONTLINE' then
				v.neighborStrategicValue = math.log(hexStrategicValue)
				table.insert(t, v)
			end
		end
	end

	table.sort(t, function (k1, k2) return k1.neighborStrategicValue > k2.neighborStrategicValue end)

	local platoonCount = count2
	local total = 0
	
	for k, v in next, t do
		total = total + v.neighborStrategicValue
	end
	
	local divisionTable = {}
	
	for k,v in next, t do
		amount = math.floor(platoonCount * (v.neighborStrategicValue / total))
		divisionTable[v.name] = amount
	end
	
	return {t = t , divisionTable = divisionTable}
end
---------------------------------------------------------------------------------------------------------------------------------execution and misc function definitions

function te.calculateHexHealth(_,time)
	
	for hexName, hex in next, ecw.hexInstances do
		local friendlyCount = 0
		local isFrontline = false
		local frontlineCount = 0
		for enum, neighbor in next, hex.neighbors do
			if neighbor.coa ~= hex.coa then
				frontlineCount = frontlineCount + 1
				isFrontline = true
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
		end
		if isFrontline then
			hex.healthPercentage = util.round(friendlyCount / (te.platoonsPerFrontline * frontlineCount),2)
		end
	end

	depotHealth[1],depotHealth[2] = 0,0
	factoryHealth[1],factoryHealth[2] = 0,0
	infrastructureHealth[1],infrastructureHealth[2] = 0,0

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
	end

	if time ~= nil then
		return time + 30
	end
end

function te.endSession(winner)
	util.outText(30,"Session Ended! rotating in 30 seconds...")
	
	local triggerName
	
	for name,tE in next, te.taskingEntities do
		triggerName = tE:repair(te.repairAmount)
		util.log("post repair",tE.name)
	end
	
	persist.id = timer.scheduleFunction(persist.saveToHexFiles , ecw.hexInstances , timer.getTime() + 1 )
	
	if winner ~= 3 then
		local f = io.open(lfs.writedir() .. "/ColdWar/.startInit","w")
		local s = f:write("true")
		util.log(".startInit","wrote","true")
		f:close()
	end
	
	trigger.action.setUserFlag("endSession" , winner )
end

timer.scheduleFunction(te.endSession,3, timer.getTime() + te.serverRuntime )

trigger.action.setUserFlag( "server_runtime" , timer.getTime() + te.serverRuntime )

function te.checkWin(hexList)
	--[[
	local f = io.open(lfs.writedir() .. "/ColdWar/Files/".. util.getTheatre() ..".winCondition","r")
	local s = f:read("*all")
	f:close()
	]]--
	local wc,t = {},{}
	wc[1] = {}
	wc[2] = {}
	local ownershipCount = {}
	ownershipCount[1] = 0
	ownershipCount[2] = 0

	local winCount = {}
	winCount[1] = 0
	winCount[2] = 0

	--[[
	for index, line in next, util.split(s,"\n") do
		t = util.split(line,",")
		wc[tonumber(t[2])][ t[1] ] = tonumber(t[2])
		ownershipCount[tonumber(t[2])] = ownershipCount[tonumber(t[2])] + 1
		util.log("ownershipCount",tonumber(t[2]),ownershipCount[tonumber(t[2])])
	end
	]]--
	for hexName, hex in next, hexList do
		if hex.poi["Objective"] ~= nil then
			wc[ecw.oppositeCoa[hex.initCoa]][hex.name] = ecw.oppositeCoa[hex.initCoa]
			ownershipCount[ecw.oppositeCoa[hex.initCoa]] = ownershipCount[ecw.oppositeCoa[hex.initCoa]] + 1
			util.log("ownershipCount",hex.initCoa,ownershipCount[ecw.oppositeCoa[hex.initCoa]])
		end
	end

	for i = 1,2 do
		for capital,invader in next, wc[i] do
			util.log("capital,invader",i,capital,invader)
			if hexList[capital].coa == invader then
				winCount[invader] = winCount[invader] + 1
			end
			util.log("winCount",invader,winCount[invader])
			if winCount[invader] >= ownershipCount[invader] then
				util.outText(60,"campaign is over!",ecw.coaEnums[invader],"wins!")
				te.endSession(invader)
			end
		end
	end
	return
end

function te.spawnAA(hexList,time)
	local counter = 1
	for hexName,hex in next, hexList do
		timer.scheduleFunction(te.spawnAAatHex,hex,timer.getTime() + counter)
		counter = counter + 1
	end
	return timer.getTime() + 3600
end

function te.spawnAAatHex(hex,time)
	hex:spawnAA()
end

function te.spawnFARP(hexList,time)
	local counter = 1
	for hexName,hex in next, hexList do
		timer.scheduleFunction(te.spawnFarpatHex,hex,timer.getTime() + counter)
		counter = counter + 1
	end
	return timer.getTime() + 3600
end

function te.spawnFarpatHex(hex,time)
	hex:spawnFarpGroup()
end

function te.selectAATemplate(coa,distance)
	local group = te.aaTemplates[coa][distance]
	return group
end


function te.init(tE, enemyTE, hexList, ...)
	util.log("INIT","Start init for",ecw.coaEnums[tE.coa])
	
	local enums = {}
	--rank order attack/defense
	
	tE:frontlinePathing(hexList)
	enemyTE:frontlinePathing(hexList)
	
	
	for hexName,hex in next, hexList do
		if hex.poi["Factory"] ~= nil then
		
			hex.warMaterial = ecw.maxWarMaterial / 4
			
			local pointTable = {}
	
			for k, v in next, env.mission.drawings.layers[4].objects do
				
				if v.name == "Factory" then
					pointTable = {}
					for k in ipairs(v.points) do
						pointTable[k] = {x = v.points[k].x, z = v.points[k].y, y = v.points[k].y}
					end
					break
					--pointTable[#pointTable+1],pointTable[#pointTable+2],pointTable[#pointTable+3] = {1, 0, 0, 1},{1, 0.5, 0, 1},1
					--trigger.action.markupToAll(7, -1 , 412980498357 ,unpack(pointTable))
				end
			end
			
			local pointX = hex.poi["Factory"].x
			local pointZ = hex.poi["Factory"].y
			
			for index, point in next, pointTable do
				if type(point) == "table" then
					if point.x ~= nil and point.z ~= nil then
						point.x = point.x + pointX
						point.z = point.z + pointZ
					end
				end
			end
			pointTable[#pointTable+1],pointTable[#pointTable+2],pointTable[#pointTable+3] = {0, 0, 0, 0.5},{0, 0, 0, 0.5},1
			trigger.action.markupToAll(7, -1 , infra.markerCounter ,unpack(pointTable))
			infra.markerCounter = infra.markerCounter + 1
		end
		
		if hex.poi["Depot"] ~= nil then
		
			hex.warMaterial = ecw.maxWarMaterial / 4
			
			local pointTable = {}
	
			for k, v in next, env.mission.drawings.layers[4].objects do
				
				if v.name == "Depot" then
					pointTable = {}
					for k in ipairs(v.points) do
						pointTable[k] = {x = v.points[k].x, z = v.points[k].y, y = v.points[k].y}
					end
					break
					--pointTable[#pointTable+1],pointTable[#pointTable+2],pointTable[#pointTable+3] = {1, 0, 0, 1},{1, 0.5, 0, 1},1
					--trigger.action.markupToAll(7, -1 , 412980498357 ,unpack(pointTable))
				end
			end
			
			local pointX = hex.poi["Depot"].x
			local pointZ = hex.poi["Depot"].y
			
			for index, point in next, pointTable do
				if type(point) == "table" then
					if point.x ~= nil and point.z ~= nil then
						point.x = point.x + pointX
						point.z = point.z + pointZ
					end
				end
			end
			pointTable[#pointTable+1],pointTable[#pointTable+2],pointTable[#pointTable+3] = {0, 0, 0, 0.5},{0, 0, 0, 0.5},1
			trigger.action.markupToAll(7, -1 , infra.markerCounter ,unpack(pointTable))
			infra.markerCounter = infra.markerCounter + 1
		end	

		hex:assignDepotToAirfield()
	end
	
	tE:countDepots(hexList)
	enemyTE:countDepots(hexList)
	
	local platoonCount = te.initialPlatoonCount
	
	local strategicTable = tE:calculateStrategicValue(hexList,platoonCount)
	
	local t,total = strategicTable.t,0
	local divisionTable = strategicTable.divisionTable
	
	tE:factoriesToDepots(hexList)
	tE:depotsToFrontline(hexList, enemyTE)
	
	if ecw.startInit == true  or ecw.loadFromPersistence == true then
		util.log("te init","persistence",ecw.loadFromPersistence)
		local f = io.open(lfs.writedir() .. "/ColdWar/.startInit","w")
		f:write("false")
		f:close()
	else
		for hexName,hex in next, hexList do
			if hex.coa == tE.coa then
				hex:auditInfrastructure()
				hex:createHealthBar()
			end
			
			for depotName,depotObject in next, hex.depotObjects do
				persist.spawnDepotFromHexFile(hexName,depotObject)
			end
			for depotName,factoryObject in next, hex.factoryObjects do
				persist.spawnFactoryFromHexFile(hexName,factoryObject)
			end
			for depotName,infraObject in next, hex.infrastructureObjects do
				persist.spawnInfraFromHexFile(hexName,infraObject)
			end						
		end
	end
	
	if true then --ecw.loadFromPersistence == false then

	if ecwVersionToLoad == 2 then
	---------------------------------------------------------------------------------------------------------------------infra audit
		depotHealth[1],depotHealth[2] = 0,0
		factoryHealth[1],factoryHealth[2] = 0,0
		infrastructureHealth[1],infrastructureHealth[2] = 0,0

		for hexName, hex in next, hexList do
			hex:auditInfrastructure()
			hex:auditAASpawnpoints()
			hex:auditAirbaseOwnership()
			hex:resetLineTypes()
			hex:resetPriorityMarker()
			hex:updateHealthBar("pls delete")
			depotHealth[hex.coa] = depotHealth[hex.coa] + (hex.depotHealth - 1)
			factoryHealth[hex.coa] = factoryHealth[hex.coa] + (hex.factoryHealth - 1)
			infrastructureHealth[hex.coa] = infrastructureHealth[hex.coa] + (hex.pathModifier - 1)
		end

		Campaign_log:info("INIT 2.2 infra audit RED", util.ct("depot:",depotHealth[1],"| factory:", factoryHealth[1],"| infra:", infrastructureHealth[1]))
		Campaign_log:info("INIT 2.2 infra audit BLUE", util.ct("depot:",depotHealth[2],"| factory:", factoryHealth[2],"| infra:", infrastructureHealth[2]))
		
		local depotFactor = {}
		depotFactor[0] = 1
		depotFactor[1] = depotHealth[1] * te.depotModifier
		depotFactor[2] = depotHealth[2] * te.depotModifier

		local factoryFactor = {}
		factoryFactor[0] = 1
		factoryFactor[1] = factoryHealth[1] * te.factoryPlatoonModifier
		factoryFactor[2] = factoryHealth[2] * te.factoryPlatoonModifier

		local infrastructureFactor = {}
		infrastructureFactor[0] = 1
		infrastructureFactor[1] = infrastructureHealth[1] * te.infrastructurePlatoonModifier
		infrastructureFactor[2] = infrastructureHealth[2] * te.infrastructurePlatoonModifier



		local sectorEnumPairs = {}
		sectorEnumPairs[1] = {}
		sectorEnumPairs[2] = {}
		te.numberOfFrontlines = 0
		for hexName, hex in next, hexList do
			for enum,neighbor in next, hex.neighbors do
				if neighbor.coa ~= hex.coa and neighbor.coa ~= 0 then
					if sectorEnumPairs[hex.coa][hexName] == nil then
						sectorEnumPairs[hex.coa][hexName] = {} 
					end
					table.insert(sectorEnumPairs[hex.coa][hexName], enum)
					te.numberOfFrontlines = te.numberOfFrontlines + 0.5
				end
			end
		end
		te.platoonsPerFrontline = math.ceil(te.initialPlatoonCount / te.numberOfFrontlines)
		Campaign_log:info("INIT frontline distribution",util.ct(te.initialPlatoonCount,"| # of frontlines:", te.numberOfFrontlines,"| platoons per frontline:", te.platoonsPerFrontline))

		for coa, sectorTable in next, sectorEnumPairs do
			for hexName, enums in next, sectorTable do
				if coa == tE.coa then
					tE:spawnPlatoonsAtHex(hexList[hexName], te.platoonsPerFrontline * #enums, {land = te.platoonTemplates[tE.coa], naval = te.navalTemplates[tE.coa]}, enums, factoryFactor[tE.coa] + infrastructureFactor[tE.coa])
				end
			end
		end
		
	end
		if ecwVersionToLoad == 1 then
		for i,v in ipairs(t) do			
			for sideEnum, neighborHex in next, v.neighbors do
				if neighborHex.coa ~= v.coa then table.insert(enums, sideEnum) end
				tE:spawnPlatoonsAtHex(v, divisionTable[v.name], {land = te.platoonTemplates[tE.coa], naval =  te.navalTemplates[tE.coa]}, enums)
				total = total + divisionTable[v.name]
			end
			enums = {}
		end
	end
	end
	
	--[[ --recon test
	for k,enum in next, ecw.hexInstances["Sector 3-15"].groups do
		for triggerName, platoon in next, enum do
			for index, unit in next, platoon:getUnits() do
				recon.addMarkerUnit(unit,1)
			end
		end
	end
	]]--
	
	
	util.outText(5, "te.init done for ",ecw.coaEnums[tE.coa])
	util.log("Initial Platoon Count","coalition:",tE.coa,"| Total platoons:",tE:countFriendlyPlatoons(hexList),"| max:",te.initialPlatoonCount)
	util.log("INIT","End init for",ecw.coaEnums[tE.coa])
	
end

function te.controlLoopV2(taskingTable, time)
	util.outText(5,"Tick Executed!")
	Campaign_log:info("te.controlLoopV2","-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
	Campaign_log:info("te.controlLoopV2","tick starting")
	local tE1 = taskingTable[1]
	local tE2 = taskingTable[2]
	local hexList = taskingTable[3]
	local somethingFlipped = false

	local redAttDiff = redTE.attritionValue - blueTE.attritionValue
	if redAttDiff < 0 then redAttDiff = 0 end
	local blueAttDiff = blueTE.attritionValue - redTE.attritionValue
	if blueAttDiff < 0 then blueAttDiff = 0 end

	local strengthList = {}
	strengthList[0] = 0
	strengthList[1] = 0
	strengthList[2] = 0
	--compute strength for each side
	for hexName, hex in next, hexList do
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
		trigger.action.setUserFlag(hex.name .. "_HP" , math.floor((friendlyCount / hex.spawnedPlatoonCount) * 100) )
		strengthList[hex.coa] = strengthList[hex.coa] + friendlyCount
	end

	--get winner
	local winner,loser = 0,0
	if strengthList[1] > strengthList[2] then
		winner,loser = 1,2
	elseif strengthList[2] > strengthList[1] then
		winner,loser = 2,1
	end

	local hexesToFlip = {}
	for hexName, hex in next, hexList do
		local distTable = hex:findShortestPaths(hexList, 0, false, false)
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
			Campaign_log:info("surrounded",util.ct(hexName, "flipped due to being surrounded"))
			hexesToFlip[hex.name] = true
			somethingFlipped = true
		end
	end

	---------------------------------------------------------------------------------------------------------------------infra audit
	depotHealth[1],depotHealth[2] = 0,0
	factoryHealth[1],factoryHealth[2] = 0,0
	infrastructureHealth[1],infrastructureHealth[2] = 0,0

	local depotCount = {}
	local factoryCount = {}
	local infrastructureCount = {}
	depotCount[1],depotCount[2] = 0,0
	factoryCount[1],factoryCount[2] = 0,0
	infrastructureCount[1],infrastructureCount[2] = 0,0

	for hexName, hex in next, hexList do
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

	Campaign_log:info("2.2 infra audit RED", util.ct("depot:",depotHealth[1],"| factory:", factoryHealth[1],"| infra:", infrastructureHealth[1]))
	Campaign_log:info("2.2 infra audit BLUE", util.ct("depot:",depotHealth[2],"| factory:", factoryHealth[2],"| infra:", infrastructureHealth[2]))
	Campaign_log:info("2.2 count audit RED", util.ct("depot:",depotCount[1],"| factory:", factoryCount[1],"| infra:", infrastructureCount[1]))
	Campaign_log:info("2.2 count audit BLUE", util.ct("depot:",depotCount[2],"| factory:", factoryCount[2],"| infra:", infrastructureCount[2]))
	--[[
	local depotFactor = {}
	depotFactor[0] = 1
	depotFactor[1] = depotHealth[1] * te.depotModifier
	depotFactor[2] = depotHealth[2] * te.depotModifier

	local factoryFactor = {}
	factoryFactor[0] = 1
	factoryFactor[1] = factoryHealth[1] * te.factoryPlatoonModifier
	factoryFactor[2] = factoryHealth[2] * te.factoryPlatoonModifier

	local infrastructureFactor = {}
	infrastructureFactor[0] = 1
	infrastructureFactor[1] = infrastructureHealth[1] * te.infrastructurePlatoonModifier
	infrastructureFactor[2] = infrastructureHealth[2] * te.infrastructurePlatoonModifier




	---------------------------------------------------------------------------------------------------------------------calcuate ratio and capture amount
	Campaign_log:info("strength",util.ct("winner count:",strengthList[winner],"| loser count:",strengthList[loser]))
	local ratio = 1 - strengthList[loser] / strengthList[winner]
	local numberToCapture = math.floor(ratio/((te.variancePercentageRequired + (attritionDiff * te.attritionCaptureModifier)) * depotFactor[winner]))
	Campaign_log:info("strength",util.ct("winner:",winner,"| loser:",loser,"| ratio:", ratio, "| numberToCapture:",numberToCapture))

	local varianceRequiredRed = te.variancePercentageRequired - (depotFactor[2]) + (redAttDiff * te.attritionCaptureModifier)
	local varianceRequiredBlue = te.variancePercentageRequired - (depotFactor[1]) + (blueAttDiff * te.attritionCaptureModifier)

	Campaign_log:info("Variance required","Red:",tostring(varianceRequiredRed))
	Campaign_log:info("Variance required","Blue:",tostring(varianceRequiredBlue))
	]]--
	local numberToCapture = 0

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
	if teWinner ~= nil then 
		Campaign_log:info("attrition", util.ct("Winner:",teWinner.attritionValue, "| Loser: ",teLoser.attritionValue ,"| Difference: ",attritionDiff))
	end

	local variance = 0
	if redTotal > blueTotal then variance = redTotal - blueTotal end
	if blueTotal > redTotal then variance = blueTotal - redTotal end
	numberToCapture = variance / ((te.variancePercentageRequired + (attritionDiff * te.attritionCaptureModifier)) * 1000)


	Campaign_log:info("compare on tick",
		"\n|red:",redFrontline,redDepots,redFactories,redInfrastructure,
		"\n|blue:",blueFrontline,blueDepots,blueFactories,blueInfrastructure
	)
	winner = 0
	loser = 0
	if redTotal > blueTotal then winner = 1 loser = 2 end
	if redTotal < blueTotal then winner = 2 loser = 1 end

	if numberToCapture > 0 then
		somethingFlipped = true
		Campaign_log:info("attrition","Something flipped: resetting attrition values")
		redTE.attritionValue = 0
		blueTE.attritionValue = 0
	end

	for i=numberToCapture,1,-1 do
		local weakestHex = {}
		weakestHex[0] = ""
		weakestHex[1] = math.huge
		local hexStrengths = {}
		for hexName, hex in next, hexList do
			local friendlyCount = 0
			if hexesToFlip[hexName] == nil then
				local isFrontline = false
				if hex.coa == loser then
					for enum, neighbor in next, hex.neighbors do
						if neighbor.coa ~= hex.coa then
							isFrontline = true
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
					end
				end
				if isFrontline then
					hexStrengths[hexName] = friendlyCount
				end
			end
		end

		for hexName, count in next, hexStrengths do
			local enemyNeighbors = 0
			for enum, neighbor in next, ecw.hexInstances[hexName].neighbors do
				if neighbor.coa ~= ecw.hexInstances[hexName].coa then
					enemyNeighbors = enemyNeighbors + 1
				end
			end
			if enemyNeighbors < te.frontlinesRequiredToPush then
				hexStrengths[hexName] = nil
			end
		end

		for hexName, friendlyCount in next, hexStrengths do
			if weakestHex[1] > friendlyCount and hexesToFlip[weakestHex[0]] == nil then
				weakestHex[0] = hexName
				weakestHex[1] = friendlyCount
			end
		end
		if weakestHex[0] ~= "" then
			
			hexesToFlip[weakestHex[0]] = true
			Campaign_log:info("weakest hex calc", util.ct("weakest hex added: ", weakestHex[0], weakestHex[1]))
		end
	end

	for hexName, bool in next, hexesToFlip do
	
		ecw.hexInstances[hexName].usableWarMaterial = -100
		ecw.hexInstances[hexName]:flipOwner(0,"no spawns!")
		Campaign_log:info("flipping hexes", util.ct(ecw.coaEnums[ecw.hexInstances[hexName].coa],"has captured",hexName,"!"))
		util.outText(15,ecw.coaEnums[ecw.hexInstances[hexName].coa],"has captured",hexName,"!")
	end

	ecw.assignHexType(hexList)

	---------------------------------------------------------------------------------------------------------------------strategic calculations

	local strategicTable1 = tE1:calculateStrategicValue(hexList,te.initialPlatoonCount)
	local t1,total = strategicTable1.t,0
	local divisionTable1 = strategicTable1.divisionTable

	local strategicTable2 = tE2:calculateStrategicValue(hexList,te.initialPlatoonCount)
	local t2,total = strategicTable2.t,0
	local divisionTable2 = strategicTable2.divisionTable

	for i = 1,3 do
		if strategicTable1.t[i] ~= nil then
			strategicTable1.t[i]:createPriorityMarker(i)
		end
	end

	for i = 1,3 do
		if strategicTable2.t[i] ~= nil then
			strategicTable2.t[i]:createPriorityMarker(i)
		end
	end

	---------------------------------------------------------------------------------------------------------------------despawn and respawn all units
	if somethingFlipped then
		ecw.assignHexType(hexList)
		for hexName, hex in next, hexList do
			for enum, neighbor in next, hex.neighbors do
				if hex.groups[enum] ~= nil then
					for triggerName, group in next, hex.groups[enum] do
						group:destroy()
						hex.groups[enum][triggerName] = nil
					end
				end
			end
			hex:auditSpawnpoints()
		end
		Campaign_log:info("group clear", util.ct("cleared groups everywhere"))

		local enums = {}
		total = 0
	end
	
	local sectorEnumPairs = {}
	sectorEnumPairs[1] = {}
	sectorEnumPairs[2] = {}
	te.numberOfFrontlines = 0
	for hexName, hex in next, hexList do
		for enum,neighbor in next, hex.neighbors do
			if neighbor.coa ~= hex.coa and neighbor.coa ~= 0 then
				if sectorEnumPairs[hex.coa][hexName] == nil then
					sectorEnumPairs[hex.coa][hexName] = {} 
				end
				table.insert(sectorEnumPairs[hex.coa][hexName], enum)
				te.numberOfFrontlines = te.numberOfFrontlines + 0.5
			end
		end
	end
	te.platoonsPerFrontline = math.ceil(te.initialPlatoonCount / te.numberOfFrontlines)

	if somethingFlipped then
		Campaign_log:info("frontline distribution",util.ct(te.initialPlatoonCount,"| # of frontlines:", te.numberOfFrontlines,"| platoons per frontline:", te.platoonsPerFrontline))

		for coa, sectorTable in next, sectorEnumPairs do
			for hexName, enums in next, sectorTable do
				if coa == 1 then
					tE1:spawnPlatoonsAtHex(hexList[hexName], te.platoonsPerFrontline * #enums, {land = te.platoonTemplates[tE1.coa], naval =  te.navalTemplates[tE1.coa]}, enums, 0)--factoryFactor[1] + infrastructureFactor[1])
				else
					tE2:spawnPlatoonsAtHex(hexList[hexName], te.platoonsPerFrontline * #enums, {land = te.platoonTemplates[tE2.coa], naval =  te.navalTemplates[tE2.coa]}, enums, 0)--factoryFactor[2] + infrastructureFactor[2])
				end			
			end
		end
	end

	te.nextTick = time + te.loopTime
		--[[
		for i,v in ipairs(t1) do
			for sideEnum, neighborHex in next, v.neighbors do
				if neighborHex.coa ~= v.coa then table.insert(enums, sideEnum) end
			end
			Campaign_log:info("TE1 spawning", util.ct(v.name,v.coa,divisionTable1[v.name]))
			tE1:spawnPlatoonsAtHex(v, divisionTable1[v.name], {land = te.platoonTemplates[tE1.coa], naval =  te.navalTemplates[tE1.coa]}, enums, factoryFactor[1] + infrastructureFactor[1])
			if type(divisionTable1[v.name]) == "number" then
				total = total + divisionTable1[v.name]
			end
			enums = {}
		end
		Campaign_log:info("TE1 SPAWN TOTAL", util.ct("spawned",total,"units"))
		total = 0
		for i,v in ipairs(t2) do
			for sideEnum, neighborHex in next, v.neighbors do
				if neighborHex.coa ~= v.coa then table.insert(enums, sideEnum) end
			end
			Campaign_log:info("TE2 spawning", util.ct(v.name,v.coa,divisionTable2[v.name]))
			tE2:spawnPlatoonsAtHex(v, divisionTable2[v.name], {land = te.platoonTemplates[tE2.coa], naval =  te.navalTemplates[tE2.coa]}, enums, factoryFactor[2] + infrastructureFactor[2])
			if type(divisionTable2[v.name]) == "number" then
				total = total + divisionTable2[v.name]
			end
			enums = {}
		end
		Campaign_log:info("TE2SPAWN TOTAL", util.ct("spawned",total,"units"))
		]]--
	--[[
		collect ratio of sides remaining /
		calculate variance required (depot calculation) -- /
			how do we calculate number of hexes takes? --multiplier of variance? /
		find weakest sector, take that, repeat as necessary /
		calculate unit strength based on factory/infrastructure health --needs factory/infra integration
		respawn units /
	]]--

	for hexName, hex in next, hexList do
		hex:spawnEWR()
	end

	te.checkWin(hexList)
	te.nextTick = time + te.loopTime
	trigger.action.setUserFlag( "next_tick" , tostring(te.nextTick))
	return time + te.loopTime
end

function te.controlLoop(taskingTable, time)
	util.outText(5,"Tick Executed!")
	util.log("te.controlLoop tick",timer.getTime(),"---------------------------------------------------------------------------------------------------------------------------------")
	--supply
	
	te.wmCreated = {}
	te.wmCreated[1] = 0
	te.wmCreated[2] = 0
	te.wmDistributed = {}
	te.wmDistributed[1] = 0
	te.wmDistributed[2] = 0
	te.wmReceived = {}
	te.wmReceived[1] = 0
	te.wmReceived[2] = 0
	
	local platoonCount
	
	for hexName,hex in next, taskingTable[3] do
		if not breakthroughEnabled then break end
		local flip = false
		if hex:auditSpawnpoints() <= 0 and hex.type == "FRONTLINE" then
			for enum,neighbor in next, hex.neighbors do
				flip = false
				if hex.coa ~= neighbor.coa then
					for triggerName,platoon in next, neighbor.groups[ecw.oppositeEnum[enum]] do
						if platoon ~= nil then
							hex.usableWarMaterial = -100
							hex:flipOwner(neighbor.usableWarMaterial)
							util.outText(20,hex.name,"has been captured by",ecw.coaEnums[hex.coa],"by breakthrough!")
							util.log("BREAKTHROUGH",hex.name,"has been captured by",ecw.coaEnums[hex.coa],"by breakthrough!")
							flip = true
							break
						end
					end
				end
				if flip then break end
			end
		end
		hex:auditInfrastructure()
		hex:auditAASpawnpoints()
		hex:auditAirbaseOwnership()
		hex:applyAttrition()
		hex:resetLineTypes()
		hex:resetPriorityMarker()
	end
	
	local tE1 = taskingTable[1]
	local tE2 = taskingTable[2]
	local hexList = taskingTable[3]
	
	te.wmCreated[1] = tE1:manufactureWarMaterial(hexList)
	te.wmDistributed[1] = tE1:factoriesToDepots(hexList)
	te.wmReceived[1] = tE1:depotsToFrontline(hexList, tE2)
	
	te.wmCreated[2] = tE2:manufactureWarMaterial(hexList)
	te.wmDistributed[2] = tE2:factoriesToDepots(hexList)
	te.wmReceived[2] = tE2:depotsToFrontline(hexList, tE1)
	
	--attrition logging
	
	for hexName,hex in next, hexList do
		if hex.usedAttritionWM ~= 0 then
			util.log("usedAttritionWM",hexName,"ate",hex.usedAttritionWM,"war material on attrition.")
			hex.usedAttritionWM = 0
		end
	end
	
	--attritrion & flips
	
	local flip = false
	local hasFlipped = false
	for hexName,hex in next, hexList do
		if hex.usableWarMaterial < 0 then
			for enum,neighbor in next, hex.neighbors do
				flip = false
				if neighbor.coa ~= hex.coa then
					for triggerName,platoon in next, neighbor.groups[ecw.oppositeEnum[enum]] do
						if platoon ~=nil then
							hex:flipOwner(neighbor.usableWarMaterial)
							util.outText(20,hex.name,"has been captured by",ecw.coaEnums[hex.coa])
							flip = true
							hasFlipped = true
							break
						end
					end
				end
				if flip then break end
			end
		end
	end
	if hasFlipped then ChangeFlippedMarkerText() end

	for hexName,hex in next, hexList do
		hex:updateHealthBar()
	end	
	ecw.assignHexType(hexList)
	
	--spawns

	tE1.reinforcementTick = tE1.reinforcementTick + (1 * tE1.factoryHealth)
	tE2.reinforcementTick = tE2.reinforcementTick + (1 * tE2.factoryHealth)
	
	util.log("Reinforcement Tick","te1",tE1.reinforcementTick,"te2",tE2.reinforcementTick)
	
	local strategicTable = tE1:calculateStrategicValue(hexList,1)
	for k,v in next, strategicTable.t do
		v.reinforcementStrategicValue = (v.neighborStrategicValue * (v.lastAttritionTick)) * (100 - v.usableWarMaterial)
		util.log("reinforcementStrategicValue",v.reinforcementStrategicValue,v.neighborStrategicValue,v.lastAttritionTick,v.usableWarMaterial,v.name,v.coa)
	end
	
	table.sort(strategicTable.t, function (k1, k2) return k1.reinforcementStrategicValue > k2.reinforcementStrategicValue end)
	
	--spawn one platoon for the highest value in t
	
	for i = 1,3 do
		if strategicTable.t[i] ~= nil then
			strategicTable.t[i]:createPriorityMarker(i)
		end
	end
	
	if tE1.reinforcementTick >= te.reinforcementThreshold then	
	
		local hex = strategicTable.t[1]
		local ratio,minRatio = 0,math.huge
		local neediestEnum,friendlyCount,enemyCount
		
		for enum, neighbor in next, hex.neighbors do
			if neighbor.coa ~= hex.coa and neighbor ~= nil and hex.coa ~= 0 then
				hex:auditSpawnpoints()
				oppositeSide = ecw.oppositeEnum[enum]
				
				friendlyCount,enemyCount = 1,1
				
				if hex.groups[enum] ~= nil then
					for triggerName, group in next, hex.groups[enum] do
						friendlyCount = friendlyCount + 1--group:getSize()
					end
				end
				
				if neighbor.groups[oppositeSide] then
					for triggerName, group in next, neighbor.groups[oppositeSide] do
						enemyCount = enemyCount + 1--group:getSize()
					end
				end
				
				if enemyCount > 0 then ratio = friendlyCount / enemyCount else ratio = math.huge end
				ratio = friendlyCount / enemyCount				
				if ratio < minRatio then neediestEnum = enum end
			end
		end
		tE1.reinforcementTick = 0
		if tE1:countFriendlyPlatoons(hexList) < te.initialPlatoonCount then
			tE1:spawnPlatoonsAtHex(hex, te.reinforcementAmount, {land = te.platoonTemplates[tE1.coa], naval = te.navalTemplates[tE1.coa]}, {neediestEnum})
			--util.outText(5,"Reinforcement","coalition:",hex.coa,"| hex:",hex.name,"| amount:",1,"| enum:",neediestEnum)
			util.outText(10,"Red Reinforced",hex.name,"with",te.reinforcementAmount,"Platoons")
			util.log("Reinforcement","coalition:",hex.coa,"| hex:",hex.name,"| amount:",te.reinforcementAmount,"| enum:",neediestEnum,"| Total platoons:",tE1:countFriendlyPlatoons(hexList),"| max:",te.initialPlatoonCount)
		else
			util.log("Reinforcement","coalition:",hex.coa,"| over platoon limit. skipping reinforcement.",tE1:countFriendlyPlatoons(hexList),te.initialPlatoonCount)
		end
	end

	local strategicTable = tE2:calculateStrategicValue(hexList,1)
	for k,v in next, strategicTable.t do
		v.reinforcementStrategicValue = (v.neighborStrategicValue * (v.lastAttritionTick)) * (100 - v.usableWarMaterial)
		util.log("reinforcementStrategicValue",v.reinforcementStrategicValue,v.neighborStrategicValue,v.lastAttritionTick,v.usableWarMaterial,v.name,v.coa)
	end
	
	table.sort(strategicTable.t, function (k1, k2) return k1.reinforcementStrategicValue > k2.reinforcementStrategicValue end)
	
	--spawn one platoon for the highest value in t
	
	for i = 1,3 do
		if strategicTable.t[i] ~= nil then
			strategicTable.t[i]:createPriorityMarker(i)
		end
	end
	
	if tE2.reinforcementTick >= te.reinforcementThreshold then
		
		local hex = strategicTable.t[1]
		local ratio,minRatio = 0,math.huge
		local neediestEnum,friendlyCount,enemyCount
		
		for enum, neighbor in next, hex.neighbors do
			if neighbor.coa ~= hex.coa and neighbor ~= nil and hex.coa ~= 0 then
				hex:auditSpawnpoints()
				oppositeSide = ecw.oppositeEnum[enum]
				
				friendlyCount,enemyCount = 1,1
				
				if hex.groups[enum] ~= nil then
					for triggerName, group in next, hex.groups[enum] do
						friendlyCount = friendlyCount + 1--group:getSize()
					end
				end
				
				if neighbor.groups[oppositeSide] then
					for triggerName, group in next, neighbor.groups[oppositeSide] do
						enemyCount = enemyCount + 1--group:getSize()
					end
				end
				
				if enemyCount > 0 then ratio = friendlyCount / enemyCount else ratio = math.huge end
				ratio = friendlyCount / enemyCount	
				if ratio < minRatio then neediestEnum = enum end
			end
		end
		tE2.reinforcementTick = 0
		if tE2:countFriendlyPlatoons(hexList) < te.initialPlatoonCount then
			util.log("Platoon Count",tE2:countFriendlyPlatoons(hexList),te.initialPlatoonCount)
			tE2:spawnPlatoonsAtHex(hex, te.reinforcementAmount, {land = te.platoonTemplates[tE2.coa], naval =  te.navalTemplates[tE2.coa]}, {neediestEnum}) 
			util.outText(10,"Blue Reinforced",hex.name,"with",te.reinforcementAmount,"Platoons")
			--util.outText(5,"Reinforcement","coalition:",hex.coa,"| hex:",hex.name,"| amount:",1,"| enum:",neediestEnum)
			util.log("Reinforcement","coalition:",hex.coa,"| hex:",hex.name,"| amount:",te.reinforcementAmount,"| enum:",neediestEnum,"| Total platoons:",tE2:countFriendlyPlatoons(hexList),"| max:",te.initialPlatoonCount)
		else
			util.log("Reinforcement","coalition:",hex.coa,"| over platoon limit. skipping reinforcement.",tE2:countFriendlyPlatoons(hexList),te.initialPlatoonCount)
		end
	end	
	
	te.checkWin(hexList)
	
	ecw.loadFromPersistence = false
	local f = io.open(lfs.writedir() .. "/ColdWar/.loadFromPersistence","w")
	local s = f:write(tostring(ecw.loadFromPersistence))
	f:close()
	util.log(".loadFromPersistence","wrote",ecw.loadFromPersistence)
	
	te.nextTick = time + te.loopTime
	trigger.action.setUserFlag( "next_tick" , tostring(te.nextTick))
	return time + te.loopTime
end

function taskingEntity:repair(count)	
	
	for i = 1, count do
		local t = {}
		for triggerName, object in next, infrastructure[self.coa].damaged do
			table.insert(t,triggerName)
		end
		local logO
		if #t > 0 then logO = infrastructure[self.coa].damaged[t[math.random(#t)]]:repair() end
		util.log("Reinforcement Tick Repair:",logO)
		util.outText(20,logO,"Repaired")
	end
end

function taskingEntity:revealRandomInfrastructure()
	local friendlyHexList = {}
	for hexName, hex in next, ecw.hexInstances do
		if hex.coa == self.coa then
			table.insert(friendlyHexList, hexName)
		end
	end

	local r = math.random(#friendlyHexList)

	for triggerName, infraObject in next, ecw.hexInstances[friendlyHexList[r]].infrastructureObjects do
		
		local foundUnits = {}

		for staticName, static in next, infraObject:reveal() do
			
			if static ~= nil then
				if static:isExist() then
					if static:getCoalition() == self.coa and static:getLife() >= 1 then
						if recon.currentMarkers[static:getCoalition()][static:getName()] == nil then
							recon.addMarkerUnit(static,0)
						end
					end
				end
			end
		end

		util.outText(12, triggerName, "in", ecw.hexInstances[friendlyHexList[r]].name, "has been revealed from interrogation!")
	end

end