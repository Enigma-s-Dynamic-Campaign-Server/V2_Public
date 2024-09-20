
function ai.spawnSeadPlane(coa,hexName)
	local t = {}
	local targetPoint = {}
	for triggerName, triggerTable in next, ecw.hexInstances[hexName].aaSpawnPoints do
		table.insert(t,triggerName)
	end
	if #t <= 0 then util.outTextForCoalition(coa,10,"SEAD Flight cancelled, no targets.") return false end

	targetPoint = trigger.misc.getZone(t[math.random(#t)])

	local hexspawn = util.selectClosestAirfield(coa,hexName)--uncap[coa][i]
	local x, y
	if hexspawn == "" then
		if coa == 1 then
			local spawnPoint = trigger.misc.getZone("Red Bomber Spawn")
			x = spawnPoint.point.x
			y = spawnPoint.point.z
		elseif coa == 2 then
			local spawnPoint = trigger.misc.getZone("Blue Bomber Spawn")
			x = spawnPoint.point.x
			y = spawnPoint.point.z
		else return
		end
	else
		x = ecw.hexInstances[hexspawn].origin.x
		y = ecw.hexInstances[hexspawn].origin.z
	end

	local type = {}
	type[1] = "Su-17M4"
	type[2] = "F-4E"

	local group = {}
	group.units = {}
	group.name = "SEADFlight_" .. hexName .. "_" .. tostring(timer.getTime())
	group.task = "SEAD"
	group.units[1] = {}
	group.units[1].x = x
	group.units[1].y = y
	group.units[1].alt = 10000
	group.units[1].speed = 250
	group.units[1].name = group.name .. "_" .. tostring(1)
	group.units[1].type = type[coa]
	group.units[1].heading = math.rad(util.bearing({x = x, y = 0, z = y}, ecw.hexInstances[hexName].origin))
	if coa == 1 then
		group.units[1].payload =
		{
			["pylons"] = 
			{
				[1] = 
				{
					["CLSID"] = "{Kh-25MP}",
				}, -- end of [1]
				[3] = 
				{
					["CLSID"] = "{Kh-25MP}",
				}, -- end of [3]
				[4] = 
				{
					["CLSID"] = "{A5BAEAB7-6FAF-4236-AF72-0FD900F493F9}",
				}, -- end of [4]
				[5] = 
				{
					["CLSID"] = "{A5BAEAB7-6FAF-4236-AF72-0FD900F493F9}",
				}, -- end of [5]
				[6] = 
				{
					["CLSID"] = "{Kh-25MP}",
				}, -- end of [6]
				[8] = 
				{
					["CLSID"] = "{Kh-25MP}",
				}, -- end of [8]
			}, -- end of ["pylons"]
			["fuel"] = "3770",
			["flare"] = 64,
			["chaff"] = 64,
			["gun"] = 100,
		} -- end of ["payload"]
	else
		group.units[1].payload =
		{
			["pylons"] = 
			{
				[1] = 
				{
					["CLSID"] = "{AGM_45A}",
				}, -- end of [1]
				[2] = 
				{
					["CLSID"] = "{AGM_45A}",
				}, -- end of [2]
				[5] = 
				{
					["CLSID"] = "{8B9E3FD0-F034-4A07-B6CE-C269884CC71B}",
				}, -- end of [5]
				[9] = 
				{
					["CLSID"] = "{AGM_45A}",
				}, -- end of [9]
				[8] = 
				{
					["CLSID"] = "{AGM_45A}",
				}, -- end of [8]
			}, -- end of ["pylons"]
			["fuel"] = "4864",
			["flare"] = 30,
			["chaff"] = 60,
			["gun"] = 100,
		} -- end of ["payload"]
	end
	group.units[1]["callsign"] = 
	{
		[1] = 2,
		[2] = 3,
		["name"] = "Enfield13",
		[3] = util.reconPlaneCounter,
	}
	util.reconPlaneCounter = util.reconPlaneCounter + 1
	group.units[1]["alt_type"] = "BARO"
	group["taskSelected"] = true
	group["route"] = 
	{
		["points"] = 
		{
			[1] = 
			{
				["alt"] = 5000,
				["action"] = "Turning Point",
				["alt_type"] = "BARO",
				["speed"] = 250,
				["task"] = 
				{
					["id"] = "ComboTask",
					["params"] = 
					{
						["tasks"] = 
						{
							[1] = 
							{
								["enabled"] = true,
								["auto"] = true,
								["id"] = "WrappedAction",
								["number"] = 1,
								["params"] = 
								{
									["action"] = 
									{
										["id"] = "Option",
										["params"] = 
										{
											["value"] = 2,
											["name"] = 1,
										}, -- end of ["params"]
									}, -- end of ["action"]
								}, -- end of ["params"]
							}, -- end of [1]
							[2] = 
							{
								["enabled"] = true,
								["auto"] = true,
								["id"] = "WrappedAction",
								["number"] = 2,
								["params"] = 
								{
									["action"] = 
									{
										["id"] = "Option",
										["params"] = 
										{
											["value"] = 2,
											["name"] = 13,
										}, -- end of ["params"]
									}, -- end of ["action"]
								}, -- end of ["params"]
							}, -- end of [2]
							[3] = 
							{
								["enabled"] = true,
								["auto"] = true,
								["id"] = "WrappedAction",
								["number"] = 3,
								["params"] = 
								{
									["action"] = 
									{
										["id"] = "Option",
										["params"] = 
										{
											["value"] = true,
											["name"] = 19,
										}, -- end of ["params"]
									}, -- end of ["action"]
								}, -- end of ["params"]
							}, -- end of [3]
							[4] = 
							{
								["enabled"] = true,
								["auto"] = true,
								["id"] = "WrappedAction",
								["number"] = 4,
								["params"] = 
								{
									["action"] = 
									{
										["id"] = "Option",
										["params"] = 
										{
											["targetTypes"] = 
											{
												[1] = "Air Defence",
											}, -- end of ["targetTypes"]
											["name"] = 21,
											["value"] = "Air Defence;",
											["noTargetTypes"] = 
											{
												[1] = "Fighters",
												[2] = "Multirole fighters",
												[3] = "Bombers",
												[4] = "Helicopters",
												[5] = "UAVs",
												[6] = "Infantry",
												[7] = "Fortifications",
												[8] = "Tanks",
												[9] = "IFV",
												[10] = "APC",
												[11] = "Artillery",
												[12] = "Unarmed vehicles",
												[13] = "Aircraft Carriers",
												[14] = "Cruisers",
												[15] = "Destroyers",
												[16] = "Frigates",
												[17] = "Corvettes",
												[18] = "Light armed ships",
												[19] = "Unarmed ships",
												[20] = "Submarines",
												[21] = "Cruise missiles",
												[22] = "Antiship Missiles",
												[23] = "AA Missiles",
												[24] = "AG Missiles",
												[25] = "SA Missiles",
											}, -- end of ["noTargetTypes"]
										}, -- end of ["params"]
									}, -- end of ["action"]
								}, -- end of ["params"]
							}, -- end of [4]
							[5] = 
							{
								["enabled"] = true,
								["auto"] = false,
								["id"] = "WrappedAction",
								["number"] = 5,
								["params"] = 
								{
									["action"] = 
									{
										["id"] = "Option",
										["params"] = 
										{
											["value"] = true,
											["name"] = 25,
										}, -- end of ["params"]
									}, -- end of ["action"]
								}, -- end of ["params"]
							}, -- end of [5]
							[6] = 
							{
								["enabled"] = true,
								["auto"] = false,
								["id"] = "EngageTargetsInZone",
								["number"] = 6,
								["params"] = 
								{
									["y"] = targetPoint.point.z,
									["x"] = targetPoint.point.x,
									["targetTypes"] = 
									{
										[1] = "Air Defence",
									}, -- end of ["targetTypes"]
									["value"] = "Air Defence;",
									["noTargetTypes"] = 
									{
									}, -- end of ["noTargetTypes"]
									["priority"] = 0,
									["zoneRadius"] = 5000,
								}, -- end of ["params"]
							}, -- end of [6]
						}, -- end of ["tasks"]
					}, -- end of ["params"]
				}, -- end of ["task"]
				["type"] = "Turning Point",
				["ETA"] = 0,
				["ETA_locked"] = true,
				["y"] = y,
				["x"] = x,
				["formation_template"] = "",
				["speed_locked"] = true,
			}, -- end of [1]
			[2] = 
			{
				["alt"] = 5000,
				["action"] = "Turning Point",
				["alt_type"] = "BARO",
				["speed"] = 250,
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
				["type"] = "Turning Point",
				["ETA"] = 419.0660118071,
				["ETA_locked"] = false,
				["y"] = targetPoint.point.z,
				["x"] = targetPoint.point.x,
				["formation_template"] = "",
				["speed_locked"] = true,
			}, -- end of [2]
		}, -- end of ["points"]
	} -- end of ["route"]

	util.log("Spawn SEAD Plane","spawning...")
	local spawnedGroup = coalition.addGroup(ecw.countryEnums[coa],Group.Category.AIRPLANE,group)
	util.log("Spawn SEAD Plane","spawned")
	return true
end


function ai.spawnReconPlane(coa,hexName)
	local hexspawn = util.selectClosestAirfield(coa,hexName)--uncap[coa][i]

	local x, y

	if hexspawn == "" then
		if coa == 1 then
			local spawnPoint = trigger.misc.getZone("Red Bomber Spawn")
			x = spawnPoint.point.x
			y = spawnPoint.point.z
		elseif coa == 2 then
			local spawnPoint = trigger.misc.getZone("Blue Bomber Spawn")
			x = spawnPoint.point.x
			y = spawnPoint.point.z
		else return
		end
	else
		x = ecw.hexInstances[hexspawn].origin.x
		y = ecw.hexInstances[hexspawn].origin.z
	end

	local type = {}
	type[1] = "MiG-25RBT"
	type[2] = "F-4E"

	local group = {}
	group.units = {}
	group.name = "ReconFlight_" .. hexName .. "_" .. tostring(timer.getTime())
	group.task = "Reconnaissance"
	

	group.units[1] = {}
	group.units[1].x = x
	group.units[1].y = y
	group.units[1].alt = 15000
	group.units[1].speed = 444
	group.units[1].type = type[coa]
	group.units[1].name = group.name .. "_" .. tostring(1)
	group.units[1].heading = math.rad(util.bearing({x = x, y = 0, z = y}, ecw.hexInstances[hexName].origin))

	group.units[1]["callsign"] = 
	{
		[1] = 2,
		[2] = 3,
		["name"] = "Enfield12",
		[3] = util.reconPlaneCounter,
	}
	util.reconPlaneCounter = util.reconPlaneCounter + 1
	group.units[1]["payload"] = 
	{
		["pylons"] = 
		{
		}, -- end of ["pylons"]
		["fuel"] = "15245",
		["flare"] = 0,
		["chaff"] = 0,
		["gun"] = 100,
	}
	group.units[1]["alt_type"] = "BARO"
	group["taskSelected"] = true
	group["route"] = 
	{
		["points"] = 
		{
			[1] = 
			{
				["alt"] = 15000,
				["action"] = "Turning Point",
				["alt_type"] = "BARO",
				["speed"] = 595.66546161835,
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
				["type"] = "Turning Point",
				["ETA"] = 0,
				["ETA_locked"] = false,
				["y"] = y,
				["x"] = x,
				["formation_template"] = "",
				["speed_locked"] = true,
			}, -- end of [1]
			[2] = 
			{
				["alt"] = 15000,
				["action"] = "Fly Over Point",
				["alt_type"] = "BARO",
				["speed"] = 595.66546161835,
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
				["type"] = "Turning Point",
				["ETA"] = 375.16429128682,
				["ETA_locked"] = false,
				["y"] = ecw.hexInstances[hexName].origin.z,
				["x"] = ecw.hexInstances[hexName].origin.x,
				["formation_template"] = "",
				["speed_locked"] = true,
			}, -- end of [2]
			[3] = 
			{
				["alt"] = 15000,
				["action"] = "Fly Over Point",
				["alt_type"] = "BARO",
				["speed"] = 595.66546161835,
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
				["type"] = "Turning Point",
				["ETA"] = 4024.5556045169,
				["ETA_locked"] = false,
				["y"] = y,
				["x"] = x,
				["formation_template"] = "",
				["speed_locked"] = true,
			}, -- end of [3]
		}, -- end of ["points"]
	}

	util.log("Spawn Recon Plane","spawning...")
	local spawnedGroup = coalition.addGroup(ecw.countryEnums[coa],Group.Category.AIRPLANE,group)
	spawnedGroup:getController():setOption(AI.Option.Air.id.ROE , AI.Option.Air.val.ROE.WEAPON_HOLD)
	spawnedGroup:getController():setOption(AI.Option.Air.id.REACTION_ON_THREAT , AI.Option.Air.val.REACTION_ON_THREAT.NO_REACTION)
	util.log("Spawn Recon Plane","spawned")
	return true
end


function ai.spawnBomberMission(coa,hexName)
	local spawnPoint = {}
    if coa == 1 then
        spawnPoint = trigger.misc.getZone("Red Bomber Spawn")
    elseif coa == 2 then
        spawnPoint = trigger.misc.getZone("Blue Bomber Spawn")
    else return
    end

	local point = {}

	if ecw.hexInstances[hexName].poi["Factory"] == nil then
		util.outText(15,"Invalid Mission! aborting...")
		return false
	else
		util.outText(15,"Target:",ecw.hexInstances[hexName].poi["Factory"].name)
		point.x = ecw.hexInstances[hexName].poi["Factory"].x
		point.z = ecw.hexInstances[hexName].poi["Factory"].y
		point.y = 0
	end

	local type = {}
	type[1] = "Tu-95MS"
	type[2] = "B-52H"

	local group = {}
	group.units = {}
	group.name = "BomberFlight_" .. hexName .. "_" .. tostring(timer.getTime())
	group.task = "Ground Attack"
	
    for i = 1, 4 do
        group.units[i] = {}
        group.units[i].x = spawnPoint.point.x + (i * 500)
        group.units[i].y = spawnPoint.point.z + (i * 500)
        group.units[i].alt = 12000
        group.units[i].speed = 400
        group.units[i].type = type[coa]
		group.units[i].name = group.name .. "_" .. tostring(i)
        group.units[i].heading = math.rad(util.bearing(spawnPoint.point, ecw.hexInstances[hexName].origin))
        group.units[i]["alt_type"] = "BARO"
        group.units[i]["callsign"] =
        {
            [1] = 2,
            [2] = 3,
            ["name"] = "Enfield14",
            [3] = util.reconPlaneCounter,
        }
        if coa == 2 then
            group.units[i]["payload"] = 
            {
                ["pylons"] = 
                {
                }, -- end of ["pylons"]
                ["fuel"] = "141135",
                ["flare"] = 192,
                ["chaff"] = 1125,
                ["gun"] = 100,
            }
        elseif coa == 1 then
            
        end
        util.reconPlaneCounter = util.reconPlaneCounter + 1
    end

	group["taskSelected"] = true
	group["route"] = 
    {
        ["points"] = 
        {
            [1] = 
            {
                ["alt"] = 12000,
                ["action"] = "Turning Point",
                ["alt_type"] = "BARO",
                ["speed"] = 400,
                ["task"] = 
                {
                    ["id"] = "ComboTask",
                    ["params"] = 
                    {
                        ["tasks"] = 
                        {
                            [1] = 
                            {
                                ["enabled"] = true,
                                ["auto"] = true,
                                ["id"] = "WrappedAction",
                                ["number"] = 1,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "Option",
                                        ["params"] = 
                                        {
                                            ["value"] = 0,
                                            ["name"] = 1,
                                        }, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [1]
                            [2] = 
                            {
                                ["enabled"] = true,
                                ["auto"] = true,
                                ["id"] = "WrappedAction",
                                ["number"] = 2,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "Option",
                                        ["params"] = 
                                        {
                                            ["value"] = 1,
                                            ["name"] = 3,
                                        }, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [2]
                            [3] = 
                            {
                                ["enabled"] = true,
                                ["auto"] = true,
                                ["id"] = "WrappedAction",
                                ["number"] = 3,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "Option",
                                        ["params"] = 
                                        {
											["variantIndex"] = 2,
											["name"] = 5,
											["formationIndex"] = 5,
											["value"] = 327682,
										}, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [3]
                            [4] = 
                            {
                                ["enabled"] = true,
                                ["auto"] = true,
                                ["id"] = "WrappedAction",
                                ["number"] = 4,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "Option",
                                        ["params"] = 
                                        {
                                            ["value"] = true,
                                            ["name"] = 15,
                                        }, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [4]
                            [5] = 
                            {
                                ["enabled"] = true,
                                ["auto"] = true,
                                ["id"] = "WrappedAction",
                                ["number"] = 5,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "Option",
                                        ["params"] = 
                                        {
                                            ["targetTypes"] = 
                                            {
                                            }, -- end of ["targetTypes"]
                                            ["name"] = 21,
                                            ["value"] = "none;",
                                            ["noTargetTypes"] = 
                                            {
                                                [1] = "Fighters",
                                                [2] = "Multirole fighters",
                                                [3] = "Bombers",
                                                [4] = "Helicopters",
                                                [5] = "UAVs",
                                                [6] = "Infantry",
                                                [7] = "Fortifications",
                                                [8] = "Tanks",
                                                [9] = "IFV",
                                                [10] = "APC",
                                                [11] = "Artillery",
                                                [12] = "Unarmed vehicles",
                                                [13] = "AAA",
                                                [14] = "SR SAM",
                                                [15] = "MR SAM",
                                                [16] = "LR SAM",
                                                [17] = "Aircraft Carriers",
                                                [18] = "Cruisers",
                                                [19] = "Destroyers",
                                                [20] = "Frigates",
                                                [21] = "Corvettes",
                                                [22] = "Light armed ships",
                                                [23] = "Unarmed ships",
                                                [24] = "Submarines",
                                                [25] = "Cruise missiles",
                                                [26] = "Antiship Missiles",
                                                [27] = "AA Missiles",
                                                [28] = "AG Missiles",
                                                [29] = "SA Missiles",
                                            }, -- end of ["noTargetTypes"]
                                        }, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [5]
                            [6] = 
                            {
                                ["enabled"] = true,
                                ["auto"] = true,
                                ["id"] = "WrappedAction",
                                ["number"] = 6,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "EPLRS",
                                        ["params"] = 
                                        {
                                            ["value"] = true,
                                            ["groupId"] = 1,
                                        }, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [6]
                        }, -- end of ["tasks"]
                    }, -- end of ["params"]
                }, -- end of ["task"]
                ["type"] = "Turning Point",
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["y"] = spawnPoint.point.z,
                ["x"] = spawnPoint.point.x,
                ["formation_template"] = "",
                ["speed_locked"] = true,
            }, -- end of [1]
            [2] = 
            {
                ["alt"] = 12000,
                ["action"] = "Fly Over Point",
                ["alt_type"] = "BARO",
                ["speed"] = 400,
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
                ["type"] = "Turning Point",
                ["ETA"] = 960.50081774416,
                ["ETA_locked"] = false,
                ["y"] = point.z,
                ["x"] = point.x,
                ["formation_template"] = "",
                ["speed_locked"] = true,
            }, -- end of [2]
            [3] = 
            {
                ["alt"] = 12000,
                ["action"] = "Turning Point",
                ["alt_type"] = "BARO",
                ["speed"] = 400,
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
                ["type"] = "Turning Point",
                ["ETA"] = 1911.0618574982,
                ["ETA_locked"] = false,
                ["y"] = spawnPoint.point.z,
                ["x"] = spawnPoint.point.x,
                ["formation_template"] = "",
                ["speed_locked"] = true,
            }, -- end of [3]
        }, -- end of ["points"]
    } -- end of ["route"]

	util.log("Spawn Plane","spawning...")
	local spawnedGroup = coalition.addGroup(ecw.countryEnums[coa],Group.Category.AIRPLANE,group)
	spawnedGroup:getController():setOption(AI.Option.Air.id.ROE , AI.Option.Air.val.ROE.WEAPON_HOLD)
	spawnedGroup:getController():setOption(AI.Option.Air.id.REACTION_ON_THREAT , AI.Option.Air.val.REACTION_ON_THREAT.NO_REACTION)
	util.log("Spawn Plane","spawned")
	local targetPoint = {}
	targetPoint.z = point.z
	targetPoint.x =  point.x
	targetPoint.y = 0
	timer.scheduleFunction(pc.bomberCheck,{group.name,targetPoint,ecw.hexInstances[hexName].poi["Factory"]},timer.getTime()+15)
	return true
end



function ai.spawnRepairPlane(coa,hexName)
	--local hexspawn = util.selectClosestAirfield(coa,hexName)--uncap[coa][i]

	local spawnPoint

    if coa == 1 then
        spawnPoint = trigger.misc.getZone("Red Bomber Spawn")
    elseif coa == 2 then
        spawnPoint = trigger.misc.getZone("Blue Bomber Spawn")
    else return
    end

	local type = {}
	type[1] = "IL-76MD"
	type[2] = "C-130"

	local group = {}
	group.units = {}
	group.name = "TransportFlight_" .. hexName .. "_" .. tostring(timer.getTime())
	group.task = "Transport"
	

	group.units[1] = {}
	group.units[1].x = spawnPoint.point.x
	group.units[1].y = spawnPoint.point.z
	group.units[1].alt = 5000
	group.units[1].speed = 333
	group.units[1].type = type[coa]
	group.units[1].name = group.name .. "_" .. tostring(1)
	group.units[1].heading = math.rad(util.bearing(spawnPoint.point, ecw.hexInstances[hexName].origin))


	group.units[1]["callsign"] = 
	{
		[1] = 2,
		[2] = 3,
		["name"] = "Enfield14",
		[3] = util.reconPlaneCounter,
	}
	util.reconPlaneCounter = util.reconPlaneCounter + 1
	group.units[1]["payload"] = 
	{
		["pylons"] = 
		{
		}, -- end of ["pylons"]
		["fuel"] = 66202.5,
		["flare"] = 0,
		["chaff"] = 0,
		["gun"] = 100,
	}
	group.units[1]["alt_type"] = "BARO"
	group["taskSelected"] = true
	group["route"] = 
	{
		["points"] = 
		{
			[1] = 
			{
				["alt"] = 5000,
				["action"] = "Turning Point",
				["alt_type"] = "BARO",
				["speed"] = 333,
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
				["type"] = "Turning Point",
				["ETA"] = 0,
				["ETA_locked"] = true,
				["y"] = spawnPoint.point.z,
				["x"] = spawnPoint.point.x,
				["formation_template"] = "",
				["speed_locked"] = true,
			}, -- end of [1]
			[2] =
			{
				["alt"] = 30,
				["action"] = "Fly Over Point",
				["alt_type"] = "RADIO",
				["speed"] = 147.22222222222,
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
				["type"] = "Turning Point",
				["ETA"] = 315.00121302677,
				["ETA_locked"] = false,
				["y"] = ecw.hexInstances[hexName].origin.z,
				["x"] = ecw.hexInstances[hexName].origin.x,
				["formation_template"] = "",
				["speed_locked"] = true,
			}, -- end of [2]
			[3] = 
			{
				["alt"] = 5000,
				["action"] = "Turning Point",
				["alt_type"] = "BARO",
				["speed"] = 330,
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
				["type"] = "Turning Point",
				["ETA"] = 449.76400973513,
				["ETA_locked"] = false,
				["y"] = spawnPoint.point.z,
				["x"] = spawnPoint.point.x,
				["formation_template"] = "",
				["speed_locked"] = true,
			}, -- end of [3]
		}, -- end of ["points"]
	} -- end of ["route"]

	util.log("Spawn Transport Plane","spawning...")
	local spawnedGroup = coalition.addGroup(ecw.countryEnums[coa],Group.Category.AIRPLANE,group)
	spawnedGroup:getController():setOption(AI.Option.Air.id.ROE , AI.Option.Air.val.ROE.WEAPON_HOLD)
	spawnedGroup:getController():setOption(AI.Option.Air.id.REACTION_ON_THREAT , AI.Option.Air.val.REACTION_ON_THREAT.NO_REACTION)
	util.log("Spawn Transport Plane","spawned")
	timer.scheduleFunction(pc.transportCheck,{group.name,ecw.hexInstances[hexName].origin,hexName},timer.getTime()+15)
	return true
end


function ai.spawnAwacsPlane(coa,hexName)
	local spawnPoint

    if coa == 1 then
        spawnPoint = trigger.misc.getZone("Red Bomber Spawn")
    elseif coa == 2 then
        spawnPoint = trigger.misc.getZone("Blue Bomber Spawn")
    else return
    end

	local type = {}
	type[1] = "A-50"
	type[2] = "E-3A"

	local group = {}
	group.units = {}
	group.name = "AwacsFlight_" .. hexName .. "_" .. tostring(timer.getTime())
	group.task = "AWACS"
	

	group.units[1] = {}
	group.units[1].x = spawnPoint.point.x
	group.units[1].y = spawnPoint.point.z
	group.units[1].alt = 5000
	group.units[1].speed = 333
	group.units[1].type = type[coa]
	group.units[1].heading = math.rad(util.bearing(spawnPoint.point, ecw.hexInstances[hexName].origin))
	group.units[1].name = group.name .. "_" .. tostring(1)


	group.units[1]["callsign"] = 
	{
		[1] = 2,
		[2] = 3,
		["name"] = "Enfield15",
		[3] = util.reconPlaneCounter,
	}
	util.reconPlaneCounter = util.reconPlaneCounter + 1
	group.units[1]["payload"] = 
	{
		["pylons"] =
		{
		}, -- end of ["pylons"]
		["fuel"] = 66202.5,
		["flare"] = 0,
		["chaff"] = 0,
		["gun"] = 100,
	}
	group.units[1]["alt_type"] = "BARO"
	group["taskSelected"] = true
	group["route"] = 
	{
		["points"] = 
		{
			[1] = 
			{
				["alt"] = 12000,
				["action"] = "Turning Point",
				["alt_type"] = "BARO",
				["speed"] = 219.44444444444,
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
								["auto"] = true,
								["id"] = "AWACS",
								["enabled"] = true,
								["params"] = 
								{
								}, -- end of ["params"]
							}, -- end of [1]
						}, -- end of ["tasks"]
					}, -- end of ["params"]
				}, -- end of ["task"]
				["type"] = "Turning Point",
				["ETA"] = 0,
				["ETA_locked"] = true,
				["y"] = spawnPoint.point.z,
				["x"] = spawnPoint.point.x,
				["formation_template"] = "",
				["speed_locked"] = true,
			}, -- end of [1]
			[2] = 
			{
				["alt"] = 12000,
				["action"] = "Turning Point",
				["alt_type"] = "BARO",
				["speed"] = 219.44444444444,
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
								["id"] = "Orbit",
								["enabled"] = true,
								["params"] = 
								{
									["altitude"] = 12000,
									["pattern"] = "Circle",
									["speed"] = 180.55555555556,
									["speedEdited"] = true,
								}, -- end of ["params"]
							}, -- end of [1]
						}, -- end of ["tasks"]
					}, -- end of ["params"]
				}, -- end of ["task"]
				["type"] = "Turning Point",
				["ETA"] = 202.07463047067,
				["ETA_locked"] = false,
				["y"] = ecw.hexInstances[hexName].origin.z,
				["x"] = ecw.hexInstances[hexName].origin.x,
				["formation_template"] = "",
				["speed_locked"] = true,
			}, -- end of [2]
		}, -- end of ["points"]
	}

	util.log("Spawn Awacs Plane","spawning...")
	local spawnedGroup = coalition.addGroup(ecw.countryEnums[coa],Group.Category.AIRPLANE,group)
	spawnedGroup:getController():setOption(AI.Option.Air.id.ROE , AI.Option.Air.val.ROE.WEAPON_HOLD)
	spawnedGroup:getController():setOption(AI.Option.Air.id.REACTION_ON_THREAT , AI.Option.Air.val.REACTION_ON_THREAT.NO_REACTION)
	spawnedGroup:getController():setOption(AI.Option.Air.id.SILENCE , true)
	util.log("Spawn Awacs Plane","spawned")
	return true
end
