--debugger

local dir = lfs.writedir() .. "/ColdWar/Files/Persistence/"
local debuggerEventHandler = {}
ExplosionSize = 1000
local password = "ECWCOMMAND"

local gameMasters = {
    ["cdaccde02cd922f6820fac97a85b11ea"] = true, -- wizard
    ["d35ed385ccdc621dc3d9e3ac9def9c22"] = true, -- smooth rough
    ["3c04770340531d31c2fc04fe0c23ecd2"] = true, -- tempest
    ["843b4a640fdb7a285d559a5a2128ccb5"] = true, -- rooster strokes
    ["025ee29567ec00061db890812f4b8ec5"] = true, -- yink
    ["814f636a3668af4c8a17621e67d7dff4"] = true, -- deadseed
    ["591c2d480f1c5195842da92f39acbfa9"] = true, -- super etendard
    ["c7cb85663d0c7ec68fac35c6d2480339"] = true, -- king crab
    ["cd1d2b089787691966d51b7467bcdd78"] = true, -- flyboy
    ["58d656379adf57b36ce5c23300b1de3b"] = true, -- enigma
    ["fd1cd519b421f617b6a2828c89707f73"] = true, -- Matroshka
    ["d4c4c902196a1168791778290608e7b9"] = true, -- Sol
    ["86bdedba966c40f1e07e976754bb68b1"] = true, -- llds07
    ["43009af9ad72caf2a3ff31396bed074"] = true, -- EagleEYe
    ["0281bea18cdf359c363a7263a558a40b"] = true, -- Dundar
    ["feb5e632e80a58097cb2eeb832a8b5be"] = true -- HardtoKidnap
	
	
}

function debuggerEventHandler:onEvent(event)

	--[[
		Event = {
			id = 25,
			idx = number markId,
			time = Abs time,
			initiator = Unit,
			coalition = number coalitionId,
			groupID = number groupId,
			text = string markText,
			pos = vec3
		}
	]]--
	
	if world.event.S_EVENT_MARK_CHANGE == event.id then --dead event is used for deleting recon marks
		
		local unit = event.initiator

		if string.find(event.text,"ECWCOMMAND") == nil and debugger == false then return end
---------------------------------------------------------------------------------------------------------------------------------

		--if debugger == false then return end
		if event.text == "-kill" then
			local foundUnits = {}
			local volS = {
				id = world.VolumeType.SPHERE,
				params = {
					point = event.pos,
					radius = 1000
				}
			}
 
			local ifFound = function(foundItem, val)
				trigger.action.explosion(foundItem:getPoint() , ExplosionSize )
				return true
			end
			
			world.searchObjects(Object.Category.UNIT, volS, ifFound)
			world.searchObjects(Object.Category.STATIC, volS, ifFound)
			trigger.action.removeMark(event.idx)
		end
		
---------------------------------------------------------------------------------------------------------------------------------
		if string.find(event.text,"-reveal") ~= nil then
			
			local localHex
			
			for hexName, hex in next, ecw.hexInstances do
				if ecw.pointInsideHex(event.pos,hex) == true then
					localHex = hex
					break
				end	
			end
			
			for triggerName, infraObject in next, localHex.infrastructureObjects do
				infraObject:reveal()
			end
			trigger.action.removeMark(event.idx)
		end
		
---------------------------------------------------------------------------------------------------------------------------------
		if string.find(event.text,"-recon") ~= nil then
			local foundUnits = {}
			local volS = {
				id = world.VolumeType.SPHERE,
				params = {
					point = event.pos,
					radius = 1000
				}
			}
 
			local ifFound = function(foundItem, val)
				recon.addMarkerUnit(foundItem,0)
				return true
			end
			
			world.searchObjects(Object.Category.UNIT, volS, ifFound)
			world.searchObjects(Object.Category.STATIC, volS, ifFound)
			
			trigger.action.removeMark(event.idx)
		end	
---------------------------------------------------------------------------------------------------------------------------------
		if string.find(event.text,"-loop") ~= nil then
			timer.setFunctionTime(te.id , timer.getTime() + 1)
			util.outText(10,"forced a te.controlLoop execution")
			trigger.action.removeMark(event.idx)
		end
---------------------------------------------------------------------------------------------------------------------------------
		if string.find(event.text,"-recceDebug") ~= nil then
			recon.audit()
			trigger.action.removeMark(event.idx)
		end
---------------------------------------------------------------------------------------------------------------------------------
		if string.find(event.text,"-lua") ~= nil then
			local s = util.split(event.text,"-lua ")[1]
			if loadstring then
				loadstring(s)()
			else
				load(s)()
			end
			trigger.action.removeMark(event.idx)
		end
---------------------------------------------------------------------------------------------------------------------------------
		if string.find(event.text,"-next") ~= nil then
			
			te.endSession(3)
			
			trigger.action.removeMark(event.idx)
		end
---------------------------------------------------------------------------------------------------------------------------------
if string.find(event.text,"-debug_file") ~= nil then
	dofile(lfs.writedir() .. "debug.lua")
	trigger.action.removeMark(event.idx)
end
---------------------------------------------------------------------------------------------------------------------------------
		if string.find(event.text,"-reset") ~= nil then
		
			local f = io.open(dir .. ".startInit","w")
			local s = f:write("true")
			f:close()
			
			te.endSession(3)
			
			trigger.action.removeMark(event.idx)
		end
---------------------------------------------------------------------------------------------------------------------------------
		if string.find(event.text,"-flip") ~= nil then
			
			local localHex
			
			for hexName, hex in next, ecw.hexInstances do
				if ecw.pointInsideHex(event.pos,hex) == true then
					localHex = hex
					break
				end	
			end
			
			localHex.usableWarMaterial = -100
			util.outText(10,"removed war material from",localHex.name)
			
			for enum, neighbor in next, localHex.neighbors do
				for triggerName, group in next, localHex.groups[enum] do
					if group ~= nil then
						if group:isExist() then
							group:destroy()
						end
					end
				end
			end

			if string.find(event.text,"-flip") ~= nil then
				util.outText(10,"forced a te.controlLoop execution for flip")
				timer.setFunctionTime(te.id , timer.getTime() + 1)
			end

			trigger.action.removeMark(event.idx)
		end		
---------------------------------------------------------------------------------------------------------------------------------
		if string.find(event.text,"-troops") ~= nil then
			local coa, typeName = 0,""
			if string.find(event.text,"standard") ~= nil then
				typeName = "Standard"
			elseif string.find(event.text,"sof") ~= nil then
				typeName = "SOF"
			elseif string.find(event.text,"recon") ~= nil then
				typeName = "Recon"
			end
			
			util.outText(10,"type found:",typeName)
			
			if typeName == "" then util.outText(10,"cant find a valid troop type, try again") return end
			
			if string.find(event.text,"red") ~= nil then
				coa = 1
			elseif string.find(event.text,"blue") ~= nil then
				coa = 2
			end
			if coa == 0 then util.outText(10,"not a valid coalition, try again") return end
			
			util.outText(10,"coa found:",coa)
			
			local country1
			
			if coa == 1 then
				country1	= country.id.RUSSIA
			elseif coa == 2 then
				country1 = country.id.USA
			else
				return nil
			end
			
			local group = {}
			group.name =  "inf Debugger_" .. timer.getTime()
			group.route = 
			{
				["points"] = 
				{
					[1] = 
					{
						["alt"] = 500,
						["action"] = "From Ground Area",
						["alt_type"] = "BARO",
						["speed"] = 0,
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
						["type"] = "TakeOffGround",
						["ETA"] = 0,
						["ETA_locked"] = true,
						["y"] = event.pos.z,
						["x"] = event.pos.x,
						["formation_template"] = "",
						["speed_locked"] = true,
					}, -- end of [1]
				}, -- end of ["points"]
			} -- end of ["route"]
			group.task = "Transport"
			group.units = {}
			group.units[1] = {}
			group.units[1].name = group.name .. "_1"
			group.units[1].type = "UH-1H"
			group.units[1].x = event.pos.x
			group.units[1].y = event.pos.z
			
			local g = coalition.addGroup(country1 ,1, group )
			
			timer.scheduleFunction(
				function(t)
					local g1,typeName1 = unpack(t)
					helicopter = heli.createheliObject(g1:getUnits()[1])
					helicopter.squads["Standard"] = 4
					helicopter.squads["SOF"] = 3
					helicopter.squads["Recon"] = 2
					helicopter:dropTroops(1,typeName1)
					timer.scheduleFunction(
						function(g2)
							g2:destroy()
						end,
						g1,
						timer.getTime() + 5
					)
				end,
				{g,typeName},
				timer.getTime() + 3
			)
				
			trigger.action.removeMark(event.idx)
		end
---------------------------------------------------------------------------------------------------------------------------------
	end
end

world.addEventHandler(debuggerEventHandler)
