ecw = {}
te = {}
recon = {}
infrastructure = {}
util = {}
heli = {}
inf = {}
ewr = {}
pc = {}
ai = {}

debugger = false
breakthroughEnabled = false
livesEnabled = false
ecwVersionToLoad = 2 --1 for og version, 2 for 2.20

env.setErrorMessageBoxEnabled(debugger)
--------------------------------------------------------------------------------------------------------------------------------
pc.minimumSpawnDistance = 2
pc.reconPointCost = 5
pc.seadPointCost = 5
pc.bomberPointCost = 40
pc.repairPointCost = 20
pc.awacsPointCost = 10

if debugger then
	pc.reconPointCost = 0
	pc.seadPointCost = 0
	pc.bomberPointCost = 0
	pc.repairPointCost = 0
	pc.awacsPointCost = 0
end

pc.bomberTypes = {}
pc.bomberTypes["Tu-95MS"] = true
pc.bomberTypes["B-52H"] = true
pc.bomberTypes["A-50"] = true
pc.bomberTypes["E-3A"] = true

--------------------------------------------------------------------------------------------------------------------------------
heli.maxPassengers = {}
heli.transportTypes = {}
heli.maxSquads = {}
heli.deploySide = {}
heli.instances = {}
heli.squadWeight = {}

heli.squadWeight[1] = 120
heli.squadWeight[2] = 100

heli.maxSquads["Recon"] = 1
heli.maxSquads["SOF"] = 1
heli.maxSquads["Standard"] = 2

heli.squadSize = {}

heli.squadSize["Recon"] = 2
heli.squadSize["SOF"] = 3
heli.squadSize["Standard"] = 4
heli.squadSize["CSAR"] = 1

heli.transportTypes["Mi-24P"] 		= {"Standard","SOF","Recon"}
heli.transportTypes["UH-1H"]		= {"Standard","SOF","Recon"}
heli.transportTypes["Mi-8MT"]		= {"Standard","SOF","Recon"}
heli.transportTypes["Mi-8MTV2"]		= {"Standard","SOF","Recon"}
heli.transportTypes["SA342Mistral"]	= {"Recon"}
heli.transportTypes["SA342Minigun"]	= {"Recon","SOF"}
heli.transportTypes["SA342L"]		= {"Recon","SOF"}
heli.transportTypes["SA342M"]		= {"Recon","SOF"}
heli.transportTypes["OH58D"]		= {"Recon"}
for typeName,_ in next, heli.transportTypes do
	table.insert(heli.transportTypes[typeName],"CSAR")
end


heli.maxPassengers["Mi-24P"] 		= 6
heli.maxPassengers["UH-1H"]			= 12
heli.maxPassengers["Mi-8MT"]		= 14
heli.maxPassengers["Mi-8MTV2"]		= 14
heli.maxPassengers["SA342Mistral"]	= 2
heli.maxPassengers["SA342Minigun"]	= 3
heli.maxPassengers["SA342L"]		= 3
heli.maxPassengers["SA342M"]		= 3
heli.maxPassengers["OH58D"]		= 2

heli.deploySide["Mi-24P"] 		= math.rad(90)
heli.deploySide["UH-1H"]		= math.rad(90)
heli.deploySide["Mi-8MT"]		= math.rad(270)
heli.deploySide["Mi-8MTV2"]		= math.rad(270)
heli.deploySide["SA342Mistral"]	= math.rad(90)
heli.deploySide["SA342Minigun"]	= math.rad(90)
heli.deploySide["SA342L"]		= math.rad(90)
heli.deploySide["SA342M"]		= math.rad(90)
heli.deploySide["OH58D"]		= math.rad(90)

--------------------------------------------------------------------------------------------------------------------------------
inf.squadComp = {}
inf.squadComp[1] = {}
inf.squadComp[2] = {}

inf.squadComp[1]["Standard"] = "Paratrooper AKS-74"
inf.squadComp[1]["SOF"] = "Infantry AK ver2"
inf.squadComp[1]["Recon"] = "Infantry AK ver2"

inf.squadComp[2]["Standard"] = "Soldier M4"
inf.squadComp[2]["SOF"] = "Soldier M4 GRG"
inf.squadComp[2]["Recon"] = "Soldier M4 GRG"

inf.unitFilter = {}
inf.unitFilter["Standard"] = {"Platoon","SAM"}
inf.unitFilter["SOF"] = {"Depot","Factory","Infrastructure"}
inf.unitFilter["Recon"] = {"marker","Platoon","Depot","Factory","SAM"}

inf.exfilRandomNumber = {}
inf.exfilRandomNumber["Standard"] = 100
inf.exfilRandomNumber["SOF"] = 150
inf.exfilRandomNumber["Recon"] = 150

inf.searchRadius = {}
inf.searchRadius["Standard"] = 4000
inf.searchRadius["SOF"] = 2000
inf.searchRadius["Recon"] = 12500

inf.missionTime = {}
inf.missionTime["Standard"] = 180
inf.missionTime["SOF"] = 180
inf.missionTime["Recon"] = 300

inf.deletionTime = 720

inf.bombSize = {}

inf.bombSize["Standard"] = 50
inf.bombSize["SOF"] = 600
inf.bombSize["Recon"] = 0

inf.killsPerSoldier = {}
inf.killsPerSoldier[1] = {}
inf.killsPerSoldier[2] = {}

inf.killsPerSoldier[1]["Standard"] = 1
inf.killsPerSoldier[1]["Recon"] = 1
inf.killsPerSoldier[1]["SOF"] = 0.33

inf.killsPerSoldier[2]["Standard"] = 0.5
inf.killsPerSoldier[2]["Recon"] = 1
inf.killsPerSoldier[2]["SOF"] = 0.33

inf.pointModifier = {}
inf.pointModifier["Standard"] = 0.5
inf.pointModifier["SOF"] = 4
inf.pointModifier["Recon"] = 0.125

--------------------------------------------------------------------------------------------------------------------------------
ecw.maxWarMaterial = 100 		--max war material
ecw.attritionBaseValue = 3 		--ratio * this value will determine attrition damage to a hex
ecw.depotDistanceModifier = 1 	-- this is multiplied * (distance + infrastructure damage) to get a reduction in supply throughput.
								-- for example, going from 1 -> 2 will half the supply received by frontlines from depots (e.g. distance of 3 to 6)
--------------------------------------------------------------------------------------------------------------------------------
te.defaultSupplyAmount = 25 	--depot supply maximum
te.manufacturedWarMaterial = 25 --war material per tick for factories
te.reinforcementThreshold = 3 	--turns for repair & reinforcements; modified by factory health
te.loopTime = 7140 				-- 7140 1 hr 59 min
te.initialPlatoonCount = 40 	--initial count and maximum as well
te.defaultUsableWarMaterial = 50 --default for hex on flip
te.serverRuntime = 14400 		--runtime until restart
te.reinforcementAmount = 2
te.repairAmount = 6
te.hiddenOnF10 = true

--2.20 variables below

te.minimumSpawns = 3

te.variancePercentageRequired = 0.08

te.frontlinesRequiredToPush = 2

te.depotModifier = 0.02
--[[ depot modifier
	will multiply ratio of dead depots * the modifier to reduce the variance required
	depotFactor[1] = depotHealth[1] * te.depotModifier -- local numberToCapture = math.floor(ratio/(te.variancePercentageRequired - depotFactor[loser]))
]]--
te.factoryPlatoonModifier = 1
te.infrastructurePlatoonModifier = 0.34
--[[ factory + infra modifier
	will add up all ratio'd factory and infrastructure factors and subtract that value from the maximum allowed units in a platoon
	if k <= (#templateUnits - modifier) then
]]--
te.attritionCaptureModifier = 0.010
--[[
	will multiply a sides differenciated attrition value by this number to increase the variance required
]]--

--2.3 modifiers
te.frontlinePercentage = 0.5
te.depotPercentage = 0.20
te.factoryPercentage = 0.20
te.infrastructurePercentage = 0.1

--------------------------------------------------------------------------------------------------------------------------------
infrastructure.defaultHexHit = 1 -- max % hit if infra/depot/factory is destroyed
--------------------------------------------------------------------------------------------------------------------------------
ewr.spawnTypeName		= "1L13 EWR"
ewr.types				= {"55G6 EWR", "1L13 EWR","E-3A","E-2C","A-50","FPS-117"}
ewr.refreshTime 		= 25
ewr.pictureLimit 		= 5
ewr.closeTargetRadius 	= 10000 --meters for god sight
ewr.debugging 			= false
ewr.maxDetectionRange	= 400000
--------------------------------------------------------------------------------------------------------------------------------


util.baseAttrition = 1
util.attritionMultiplier = 0.25

util.aircraftWeights = {}

util.aircraftWeights["A-10A"]			= 1.25
util.aircraftWeights["F-86F Sabre"]		= 0.85
util.aircraftWeights["A-4E-C"]		    = 0.85
util.aircraftWeights["F-5E-3"] 			= 1.20
util.aircraftWeights["AJS37"] 			= 1
util.aircraftWeights["F-14A-135-GR"] 	= 7
util.aircraftWeights["C-101CC"] 		= 0.8
util.aircraftWeights["MB-339A"] 		= 0.8
util.aircraftWeights["UH-1H"] 			= 0.7
util.aircraftWeights["SA342M"] 			= 0.70
util.aircraftWeights["SA342L"] 			= 0.70
util.aircraftWeights["SA342Minigun"] 	= 0.70
util.aircraftWeights["OH58D"] 	= 0.70
util.aircraftWeights["SA342Mistral"] 	= 0.70
util.aircraftWeights["Su-25"] 			= 0.90
util.aircraftWeights["MiG-15bis"] 		= 0.65
util.aircraftWeights["MiG-19P"] 		= 0.85
util.aircraftWeights["MiG-21Bis"] 		= 1.20
util.aircraftWeights["MiG-29A"] 		= 5.50
util.aircraftWeights["L-39ZA"] 			= 0.80
util.aircraftWeights["Mi-24P"] 			= 0.9
util.aircraftWeights["Mi-8MT"] 			= 0.7
util.aircraftWeights["Mi-8MTV2"] 		= 0.7
util.aircraftWeights["Mirage-F1CE"]		= 1.25
util.aircraftWeights["Mirage-F1BE"]		= 1.15
util.aircraftWeights["Mirage-F1EE"]		= 2.25
util.aircraftWeights["AH-64D BLK.II"]	= 0.85

--------------------------------------------------------------------------------------------------------------------------------
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

te.ewrTemplates = {}
te.ewrTemplates[1] = {}
te.ewrTemplates[2] = {}

te.farpGroup = {}
te.farpGroup[1] = Group.getByName("Red FARP Support")
te.farpGroup[2] = Group.getByName("Blue FARP Support")
--------------------------------------------------------------------------------------------------------------------------------
--[[
for index, group in next, coalition.getGroups(1, 2) do
	if string.find(group:getName(),"Platoon") ~= nil then
		table.insert(te.platoonTemplates[1],group)
	end
end

for index, group in next, coalition.getGroups(2, 2) do
	if string.find(group:getName(),"Platoon") ~= nil then
		table.insert(te.platoonTemplates[2],group)
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
]]--


--------------------------------------------------------------------------------------------------------------------------------
recon.jtacTimer = 3600
recon.jtacEnabled = true
recon.pointsPerInfra = 5
recon.pointsPerUnit = 0.25

recon.airframes = {}
recon.airframes["MiG-21Bis"] = {}
recon.airframes["MiG-21Bis"]["АЩАФА-5"] = {
	"АЩАФА-5",--name,
	"MiG-21Bis",--typeName,
	nil,--unitName,
	-90,--pitch,
	0,--roll,
	0,--yaw,
	20,--horizontalHalfAngleFOV,
	20,--verticalHalfAngleFOV,
	15000,--maxDistance,
	true,--infra (true - picks up only statics, false - picks up units)
	30,--film count
}

recon.airframes["MiG-21Bis"]["АФА-39"] = {
	"АФА-39",--name,
	"MiG-21Bis",--typeName,
	nil,--unitName,
	-30,--pitch,
	0,--roll,
	0,--yaw,
	35,--horizontalHalfAngleFOV,
	20,--verticalHalfAngleFOV,
	7000,--maxDistance,
	false,--infra
	30,--film count
}


recon.airframes["AJS37"] = {}
recon.airframes["AJS37"]["SKa 31"] = {
	"SKa 31",--name,
	"AJS37",--typeName,
	nil,--unitName,
	-90,--pitch,
	0,--roll,
	0,--yaw,
	20,--horizontalHalfAngleFOV,
	20,--verticalHalfAngleFOV,
	15000,--maxDistance,
	true,--infra (true - picks up only statics, false - picks up units)
	30,--film count
}

recon.airframes["AJS37"]["SKa 24C"] = {
	"SKa 24C",--name,
	"AJS37",--typeName,
	nil,--unitName,
	-30,--pitch,
	0,--roll,
	0,--yaw,
	35,--horizontalHalfAngleFOV,
	20,--verticalHalfAngleFOV,
	7000,--maxDistance,
	false,--infra
	30,--film count
}

recon.airframes["F-5E-3"] = {}
recon.airframes["F-5E-3"]["KS-121B"] = {
	"KS-121B",--name,
	"F-5E-3",--typeName,
	nil,--unitName,
	-90,--pitch,
	0,--roll,
	0,--yaw,
	20,--horizontalHalfAngleFOV,
	20,--verticalHalfAngleFOV,
	15000,--maxDistance,
	true,--infra (true - picks up only statics, false - picks up units)
	30,--film count
}

recon.airframes["F-5E-3"]["KS-121A"] = {
	"KS-121A",--name,
	"F-5E-3",--typeName,
	nil,--unitName,
	-30,--pitch,
	0,--roll,
	0,--yaw,
	35,--horizontalHalfAngleFOV,
	20,--verticalHalfAngleFOV,
	7000,--maxDistance,
	false,--infra
	30,--film count
}


recon.airframes["MiG-19P"] = {}
recon.airframes["MiG-19P"]["АЩАФА-5"] = {
	"АЩАФА-5",--name,
	"MiG-19P",--typeName,
	nil,--unitName,
	-90,--pitch,
	0,--roll,
	0,--yaw,
	20,--horizontalHalfAngleFOV,
	20,--verticalHalfAngleFOV,
	15000,--maxDistance,
	true,--infra (true - picks up only statics, false - picks up units)
	30,--film count
}

recon.airframes["MiG-19P"]["АФА-39"] = {
	"АФА-39",--name,1
	"MiG-19P",--typeName,2
	nil,--unitName,3
	-30,--pitch,4
	0,--roll,5
	0,--yaw,6
	35,--horizontalHalfAngleFOV,
	20,--verticalHalfAngleFOV,
	7000,--maxDistance,9
	false,--infra,10
	30,--film count
}


recon.airframes["Mirage-F1CE"] = {}
recon.airframes["Mirage-F1CE"]["Presto Pod"] = {
	"Presto Pod",--name,
	"Mirage-F1CE",--typeName,
	nil,--unitName,
	-90,--pitch,
	0,--roll,
	0,--yaw,
	20,--horizontalHalfAngleFOV,
	20,--verticalHalfAngleFOV,
	15000,--maxDistance,
	true,--infra (true - picks up only statics, false - picks up units)
	30,--film count
}

recon.airframes["Mirage-F1CE"]["Omera 33"] = {
	"Omera 33",--name,
	"Mirage-F1CE",--typeName,
	nil,--unitName,
	-30,--pitch,
	0,--roll,
	0,--yaw,
	35,--horizontalHalfAngleFOV,
	20,--verticalHalfAngleFOV,
	7000,--maxDistance,
	false,--infra
	30,--film count
}
