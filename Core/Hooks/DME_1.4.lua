--dynamic mission editor


----------------------------------------------------------------------------------------------------------------  object definitions
--[[

create a new mission object with dme.createInstance(missionName), mission name being the source file to serve as the base for the new mission.

returnMissionTemplate will return a mission table from the supplied filepath

methods: writeMissionTemplateToFile

writeMissionTemplateToFile will take a missionObject's values and write them to a new miz file, using its defined source file as a base template. will write to the supplied filepath.
]]
--

local function split(pString, pPattern) --string.split
	local Table = {}
	local fpat = "(.-)" .. pPattern
	local last_end = 1
	local s, e, cap = pString:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(Table, cap)
		end
		last_end = e + 1
		s, e, cap = pString:find(fpat, last_end)
	end
	if last_end <= #pString then
		cap = pString:sub(last_end)
		table.insert(Table, cap)
	end
	return Table
end

missionObject = {}

dme = {}
dme.instances = {}

function missionObject:new(t)
	t = t or {}
	setmetatable(t, self)
	self.__index = self
	return t
end

function dme.createInstance(missionName)
	local instance = missionObject:new()
	instance:sourceFile(missionName)
	dme.instances[missionName] = instance
	return instance
end

function missionObject:sourceFile(filename)
	self.sourceFile = filename
	self.mission = dme.returnMissionTemplate(filename)

	self.returnFiles = {}
	self.returnFiles["mission"] = self.mission
	self.returnFiles["dictionary"] = false
	self.returnFiles["mapResource"] = false
	self.returnFiles["options"] = false
	self.returnFiles["theatre"] = false
	self.returnFiles["warehouses"] = false
end

--[[
										function dme.writeMissionTemplateToFile(templateMission,fileToWrite)
											
											local missionString = dme.serializeWithCycles("mission", templateMission)
											
											local vm = "start cmd /c C:\\source\\7z.exe e -y "..fileToWrite.." -oC:\\export"
											os.execute(vm)
											dme.sleep(1)
											local f = assert(io.open("C:\\export\\mission", "w"))
											f:write(missionString)
											f:close()
											vm = "start cmd /c C:\\source\\7z.exe a "..fileToWrite.. " C:\\\\export\\\\"
											os.execute(vm)
										end
										]]
--

function missionObject:writeMissionTemplateToFile(fileToWrite)
	fileToWrite = string.gsub(fileToWrite, "\\", "\\\\")
	local vm = 'start cmd /c C:\\source\\7za.exe x -y "' .. self.sourceFile .. '" -oC:\\export'
	os.execute(vm)
	dme.sleep(2)

	for fileName, fileValue in next, self.returnFiles do
		if fileValue ~= false then
			log.write("DME", log.INFO, "found " .. fileName .. " to be written!")
			local f = assert(io.open("C:\\export\\" .. fileName, "w"))
			f:write(dme.serializeWithCycles(fileName, fileValue))
			f:close()
		end
	end

	log.write("DME", log.INFO, "writing " .. fileToWrite .. " to file!")

	vm = 'start cmd /c C:\\source\\7za.exe a -tzip "' .. fileToWrite .. '" C:\\\\export\\\\ -mem=ZipCrypto'
	os.execute(vm)
	dme.sleep(2)
end

function dme.readCampaignRotationFile(filepath)
	local f = io.open(filepath, "r")

	if f == nil then
		log.write("DME", log.INFO, filepath .. " doesnt exist!")
		return {}
	end
	if string.find(filepath, ".rq") == nil then
		log.write("DME", log.INFO, filepath .. " is not a valid campaign rotation file!")
		return {}
	end

	local s = f:read("*all")
	f:close()
	local rows = split(s, "\n")
	return rows, s
end

function dme.incrementCampaignRotationFile(rotation_file, mission_filepath)
	local rows, s = dme.readCampaignRotationFile(rotation_file)
	if rows[1] == nil then return nil end


	for f in lfs.dir(mission_filepath) do --adds mission inits not on the list to the end of the queue
		if string.find(f, "INIT") ~= nil then
			local is_in_file = false
			for v, c in next, rows do
				if f == c then is_in_file = true end
			end
			if not is_in_file then
				table.insert(rows, f)
				log.write("DME", log.INFO, "not in file| adding: " .. s)
			end
		end
	end

	for i = #rows, 1, -1 do --remove missions in list that dont exist in folder
		local exists_in_folder = false
		for f in lfs.dir(mission_filepath) do
			if rows[i] == f then exists_in_folder = true end
		end
		if string.find(rows[i],".orig") then
			log.write("DME", log.INFO, "removing " .. rows[i])
			table.remove(rows, i)
		elseif not exists_in_folder then
			log.write("DME", log.INFO, "removing " .. rows[i])
			table.remove(rows, i)
		end
	end

	log.write("DME", log.INFO, "current campaign queue: \n" .. s)
	local next_mission = rows[1]
	log.write("DME", log.INFO, "next mission will be: " .. next_mission)
	table.insert(rows, next_mission)
	table.remove(rows, 1)

	local s = "" --writing the compiled table to a string to write
	for i = 1, #rows do
		s = s .. rows[i] .. "\n"
		log.write("DME", log.INFO, "assigning " .. rows[i] .. " to position " .. tostring(i))
	end

	local f = io.open(rotation_file, "w")
	f:write(s)
	f:close()

	return mission_filepath .. next_mission
end

function dme.returnMissionTemplate(filename)
	filename = string.gsub(filename, "\\", "\\\\")
	log.write("DME", log.INFO, "cracking open " .. filename)

	local vm = 'start cmd /c C:\\source\\7za.exe x -y "' .. filename .. '" -oC:\\export'
	os.execute(vm)
	dme.sleep(2)
	local f = io.open("C:\\export\\mission", "r")
	local s = f:read("*all")
	f:close()
	s = "local " .. s .. "\ndme_mission = mission"
	if loadstring then
		loadstring(s)()
	else
		load(s)()
	end

	return dme_mission
end

function dme.returnOptionsTemplate(filename)
	filename = string.gsub(filename, "\\", "\\\\")
	log.write("DME", log.INFO, "Options: cracking open " .. filename)

	local vm = 'start cmd /c C:\\source\\7za.exe x -y "' .. filename .. '" -oC:\\export'
	os.execute(vm)
	dme.sleep(2)
	local f = io.open("C:\\export\\options", "r")
	local s = f:read("*all")
	f:close()
	s = "local " .. s .. "\ndme_options = options"
	if loadstring then
		loadstring(s)()
	else
		load(s)()
	end

	return dme_options
end

function missionObject:setOptionsFromFile(filename)
	self.returnFiles["options"] = dme.returnOptionsTemplate(filename)
end

function missionObject:getWeatherFromTemplate(filename)
	return self.mission.weather
end

function missionObject:setWeatherFromTemplate(template)
	self.mission.weather = template
end

function missionObject:getRestrictionsFromTemplate(filename)
	return
end

function missionObject:getDifficultyFromTemplate(filename)
	return
end

----------------------------------------------------------------------------------------------------------------  restriction definitions
--[[
										
										payload function definitions
										
										comes in both plane and helicopter types
										loadWeaponTemplates will return a table of unitTables to be used for applying to a mission table, must be supplied a .miz filepath
										applyweapontemplatetoall will replace all unit's payload of the same type as the supplied template argument. plane and heli are defined seperately.
										]]
--
function dme.loadWeaponTemplatesPlanes(filename)
	local missionTemplate = dme.returnMissionTemplate(filename)

	local weaponTemplates = {}

	for coalition, coaTable in next, missionTemplate.coalition do
		weaponTemplates[coalition] = {}
		for countries, countryTable in next, coaTable.country do
			for groupKey, groupValue in next, countryTable.plane.group do
				for unitKey, unitTable in next, groupValue.units do
					weaponTemplates[coalition][unitTable.name] = unitTable

					log.write("DME", log.INFO,
						tostring(coalition) ..
						" " .. unitTable.type .. " " .. unitTable.name .. " restrictions available!")
				end
			end
		end
	end

	return weaponTemplates
end

function dme.loadWeaponTemplatesHelis(filename)
	local missionTemplate = dme.returnMissionTemplate(filename)

	local weaponTemplates = {}

	for coalition, coaTable in next, missionTemplate.coalition do
		weaponTemplates[coalition] = {}
		for countries, countryTable in next, coaTable.country do
			for groupKey, groupValue in next, countryTable.helicopter.group do
				for unitKey, unitTable in next, groupValue.units do
					weaponTemplates[coalition][unitTable.name] = unitTable

					log.write("DME", log.INFO,
						tostring(coalition) ..
						" " .. unitTable.type .. " " .. unitTable.name .. " restrictions available!")
				end
			end
		end
	end

	return weaponTemplates
end

function missionObject:applyWeaponTemplateToAllPlanes(inputUnitTable)
	local typeName = inputUnitTable.type
	local index = 0

	for coalition, coaTable in next, self.mission.coalition do
		for countries, countryTable in next, coaTable.country do
			if countryTable.plane ~= nil then
				for groupKey, groupValue in next, countryTable.plane.group do
					for unitKey, unitTable in next, groupValue.units do
						if unitTable.type == typeName then
							index = index + 1
							unitTable.payload = {}
							unitTable.payload = inputUnitTable.payload
							unitTable.AddPropAircraft = inputUnitTable.AddPropAircraft
						end
					end
				end
			end
		end
	end

	log.write("DME", log.INFO,
		tostring(index) .. " " .. typeName .. " payloads replaced with template: " .. inputUnitTable.name)
	return
end

function missionObject:applyWeaponTemplateToAllHelis(inputUnitTable)
	local typeName = inputUnitTable.type
	local index = 0

	for coalition, coaTable in next, self.mission.coalition do
		for countries, countryTable in next, coaTable.country do
			if countryTable.helicopter ~= nil then
				for groupKey, groupValue in next, countryTable.helicopter.group do
					for unitKey, unitTable in next, groupValue.units do
						if unitTable.type == typeName then
							index = index + 1
							unitTable.payload = {}
							unitTable.payload = inputUnitTable.payload
							unitTable.AddPropAircraft = inputUnitTable.AddPropAircraft
						end
					end
				end
			end
		end
	end

	log.write("DME", log.INFO,
		tostring(index) .. " " .. typeName .. " payloads replaced with template: " .. inputUnitTable.name)
	return
end

function missionObject:applyWeaponTemplateToPlaneGroupFilter(inputUnitTable, filter)
	local typeName = inputUnitTable.type
	local index = 0
	for coalition, coaTable in next, self.mission.coalition do
		for countries, countryTable in next, coaTable.country do
			if countryTable.plane ~= nil then
				for groupKey, groupValue in next, countryTable.plane.group do
					if string.find(groupValue.name, filter) ~= nil then
						for unitKey, unitTable in next, groupValue.units do
							if unitTable.type == typeName then
								index = index + 1
								unitTable.payload = {}
								unitTable.payload = inputUnitTable.payload
							end
						end
					end
				end
			end
		end
	end

	log.write("DME", log.INFO,
		tostring(index) .. " " .. typeName .. " payloads replaced with template: " .. inputUnitTable.name)
	return
end

function missionObject:applyWeaponTemplateToHeliGroupFilter(inputUnitTable, filter)
	local typeName = inputUnitTable.type
	local index = 0

	for coalition, coaTable in next, self.mission.coalition do
		for countries, countryTable in next, coaTable.country do
			if countryTable.helicopter ~= nil then
				for groupKey, groupValue in next, countryTable.helicopter.group do
					if string.find(groupValue.name, filter) ~= nil then
						for unitKey, unitTable in next, groupValue.units do
							if unitTable.type == typeName then
								index = index + 1
								unitTable.payload = inputUnitTable.payload
								unitTable.AddPropAircraft = inputUnitTable.AddPropAircraft
							end
						end
					end
				end
			end
		end
	end

	log.write("DME", log.INFO,
		tostring(index) ..
		" " .. typeName .. " payloads & AddPropAircraft replaced with template: " .. inputUnitTable.name)
	return
end

---------------------------------------------------------------------------------------------------------------- radio definitions
--same as the payload commands, just for radio's instead

function dme.loadRadioTemplatesPlanes(filename)
	local missionTemplate = dme.returnMissionTemplate(filename)

	local radioTemplates = {}

	for coalition, coaTable in next, missionTemplate.coalition do
		radioTemplates[coalition] = {}
		for countries, countryTable in next, coaTable.country do
			for groupKey, groupValue in next, countryTable.plane.group do
				for unitKey, unitTable in next, groupValue.units do
					radioTemplates[coalition][unitTable.name] = unitTable
					log.write("DME", log.INFO,
						tostring(coalition) ..
						" " .. unitTable.type .. " " .. unitTable.name .. " radio presets available!")
				end
			end
		end
	end

	return radioTemplates
end

function dme.loadRadioTemplatesHelis(filename)
	local missionTemplate = dme.returnMissionTemplate(filename)

	local radioTemplates = {}

	for coalition, coaTable in next, missionTemplate.coalition do
		radioTemplates[coalition] = {}
		for countries, countryTable in next, coaTable.country do
			for groupKey, groupValue in next, countryTable.helicopter.group do
				for unitKey, unitTable in next, groupValue.units do
					radioTemplates[coalition][unitTable.name] = unitTable
					log.write("DME", log.INFO,
						tostring(coalition) ..
						" " .. unitTable.type .. " " .. unitTable.name .. " radio presets available!")
				end
			end
		end
	end

	return radioTemplates
end

function missionObject:applyRadioTemplateToAllPlanes(inputUnitTable)
	local typeName = inputUnitTable.type
	local index = 0

	for coalition, coaTable in next, self.mission.coalition do
		for countries, countryTable in next, coaTable.country do
			if countryTable.plane ~= nil then
				for groupKey, groupValue in next, countryTable.plane.group do
					for unitKey, unitTable in next, groupValue.units do
						if unitTable.type == typeName then
							unitTable.Radio = inputUnitTable.Radio
							index = index + 1
						end
					end
				end
			end
		end
	end
	log.write("DME", log.INFO,
		tostring(index) .. " " .. typeName .. " radios replaced with radio template: " .. inputUnitTable.name)
end

function missionObject:removeModRequirements()
	self.mission.requiredModules = {}
end

function missionObject:applyRadioTemplateToAllHelis(inputUnitTable)
	log.write("DME", log.INFO, "trying to replace all " .. inputUnitTable.type .. " with " .. inputUnitTable.name)
	local typeName = inputUnitTable.type
	local index = 0

	for coalition, coaTable in next, self.mission.coalition do
		for countries, countryTable in next, coaTable.country do
			if countryTable.helicopter ~= nil then
				for groupKey, groupValue in next, countryTable.helicopter.group do
					for unitKey, unitTable in next, groupValue.units do
						if unitTable.type == typeName then
							unitTable.Radio = inputUnitTable.Radio
							index = index + 1
						end
					end
				end
			end
		end
	end
	log.write("DME", log.INFO,
		tostring(index) .. " " .. typeName .. " radios replaced with radio template: " .. inputUnitTable.name)
end

----------------------------------------------------------------------------------------------------------------  date definitions
--commands for modifying mission time.

function missionObject:setStartTime(start_time)
	self.mission.start_time = start_time
end

function missionObject:setDay(day)
	self.mission.date["Day"] = day
end

function missionObject:setMonth(month)
	self.mission.date["Month"] = month
end

function missionObject:setYear(year)
	self.mission.date["Year"] = year
end

function missionObject:getCalendarTime()
	return {
		self.mission.start_time,
		self.mission.date["Day"],
		self.mission.date["Month"],
		self.mission.date["Year"]
	}
end

function missionObject:getCalendarTimeNamed()
	return {
		startTime = self.mission.start_time,
		day = self.mission.date["Day"],
		month = self.mission.date["Month"],
		year = self.mission.date["Year"]
	}
end

function missionObject:setCalendarTime(calendarList)
	self.mission.start_time = calendarList[1]
	self.mission.date["Day"] = calendarList[2]
	self.mission.date["Month"] = calendarList[3]
	self.mission.date["Year"] = calendarList[4]
end

----------------------------------------------------------------------------------------------------------------  date patch definitions

function missionObject:findMatchingDateTemplate(templateFolderPath)
	--compile templates from folder
	local templateList = {}

	for file_name in lfs.dir(templateFolderPath) do
		if not (file_name == "." or file_name == "..") then
			if file_name:len() > 10 then
				if string.sub(file_name, file_name:len() - 3, file_name:len()) == ".miz" then
					local year = string.sub(file_name, file_name:len() - 7, file_name:len() - 4)
					log.write("DME", log.INFO, "parsed: " .. file_name .. " | trying to parse year: " .. year)
					local year = tonumber(year)
					if year ~= nil then
						log.write("DME", log.INFO, "adding: " .. file_name)
						templateList[year] = file_name
					end
				end
			end
		end
	end

	--compare to mission's date and find appropriate filter

	local finalYear = -1
	local missionYear = tonumber(self:getCalendarTimeNamed().year)

	for year, file_name in next, templateList do
		if year <= missionYear then
			if finalYear < year then
				finalYear = year
			end
		end
	end

	log.write("DME", log.INFO, "applying year: " .. tostring(finalYear) .. " to mission ")
	--return weapon template mission
	return templateFolderPath .. templateList[finalYear]
end

----------------------------------------------------------------------------------------------------------------  time definitions

function missionObject:setTime(time)
	if type(time) == "number" then
		self.mission.start_time = time
		return true
	end
	return false
end

----------------------------------------------------------------------------------------------------------------  weather definitions
--individual weather functions

function missionObject:setTemperature(temp)
	if type(temp) == "number" then
		self.mission.weather.season.temperature = temp
		return true
	end
	return false
end

function missionObject:setQNH(qnh)
	if type(qnh) == "number" then
		self.mission.weather.qnh = qnh
		return true
	end
	return false
end

function missionObject:setGroundTurbulence(gt)
	if type(gt) == "number" then
		self.mission.weather.groundTurbulence = gt
		return true
	end
	return false
end

function missionObject:setDustDensity(dd)
	if type(dd) == "number" then
		self.mission.weather.dust_density = dd
		return true
	end
	return false
end

function missionObject:setWindAt2000(dir, speed)
	if type(dir) == "number" and type(speed) == "number" then
		self.mission.weather.wind["at2000"]["dir"] = dir
		self.mission.weather.wind["at2000"]["speed"] = speed
		return true
	end
	return false
end

function missionObject:setWindAtGround(dir, speed)
	if type(dir) == "number" and type(speed) == "number" then
		self.mission.weather.wind["atGround"]["dir"] = dir
		self.mission.weather.wind["atGround"]["speed"] = speed
		return true
	end
	return false
end

function missionObject:setWindAt8000(dir, speed)
	if type(dir) == "number" and type(speed) == "number" then
		self.mission.weather.wind["at8000"]["dir"] = dir
		self.mission.weather.wind["at8000"]["speed"] = speed
		return true
	end
	return false
end

function missionObject:setFogEnable(fog)
	if type(fog) == "boolean" then
		self.mission.weather.wind.enable_fog = fog
		return true
	end
	return false
end

function missionObject:setFogVisibility(fog)
	if type(fog) == "number" then
		self.mission.weather.wind.fog.visibility = fog
		return true
	end
	return false
end

function missionObject:setFogThickness(fog)
	if type(fog) == "number" then
		self.mission.weather.wind.fog.thickness = fog
		return true
	end
	return false
end

function missionObject:setAtmosphereType(atm)
	if type(atm) == "number" then
		self.mission.weather["atmosphere_type"] = atm
		return true
	end
	return false
end

function missionObject:setCloudsPreset(cloud)
	if type(cloud) == "string" then
		self.mission.weather.clouds.preset = cloud
		return true
	end
	return false
end

function missionObject:setCloudsDensity(cloud)
	if type(cloud) == "number" then
		self.mission.weather.clouds.density = cloud
		return true
	end
	return false
end

function missionObject:setCloudsIprecptns(cloud)
	if type(cloud) == "number" then
		self.mission.weather.clouds.iprecptns = cloud
		return true
	end
	return false
end

function missionObject:setCloudsThickness(cloud)
	if type(cloud) == "number" then
		self.mission.weather.clouds.thickness = cloud
		return true
	end
	return false
end

function missionObject:setCloudsBase(cloud)
	if type(cloud) == "number" then
		self.mission.weather.clouds.base = cloud
		return true
	end
	return false
end

function missionObject:setVisibility(vis)
	if type(vis) == "number" then
		self.mission.weather.visibility.distance = vis
		return true
	end
	return false
end

function missionObject:setWeatherName(name)
	if type(name) == "string" then
		self.mission.weather["name"] = name
		return true
	end
	return false
end

function missionObject:setDustEnable(dust)
	if type(dust) == "number" then
		self.mission.weather.enable_dust = dust
		return true
	end
	return false
end

function missionObject:setWeatherType(wtype)
	if type(wtype) == "number" then
		self.mission.weather.type_weather = wtype
		return true
	end
	return false
end

--[[
										mission["weather"] = {}
										mission["weather"]["season"] = {}
										mission["weather"]["season"]["temperature"] = 20
										mission["weather"]["modifiedTime"] = true
										mission["weather"]["qnh"] = 760
										mission["weather"]["groundTurbulence"] = 0
										mission["weather"]["dust_density"] = 0
										mission["weather"]["wind"] = {}
										mission["weather"]["wind"]["at2000"] = {}
										mission["weather"]["wind"]["at2000"]["dir"] = 0
										mission["weather"]["wind"]["at2000"]["speed"] = 0
										mission["weather"]["wind"]["atGround"] = {}
										mission["weather"]["wind"]["atGround"]["dir"] = 358.9999630965
										mission["weather"]["wind"]["atGround"]["speed"] = 2
										mission["weather"]["wind"]["at8000"] = {}
										mission["weather"]["wind"]["at8000"]["dir"] = 0
										mission["weather"]["wind"]["at8000"]["speed"] = 0
										mission["weather"]["enable_fog"] = false
										mission["weather"]["fog"] = {}
										mission["weather"]["fog"]["visibility"] = 0
										mission["weather"]["fog"]["thickness"] = 0
										mission["weather"]["cyclones"] = {}
										mission["weather"]["atmosphere_type"] = 0
										mission["weather"]["clouds"] = {}
										mission["weather"]["clouds"]["preset"] = "Preset8"
										mission["weather"]["clouds"]["density"] = 0
										mission["weather"]["clouds"]["iprecptns"] = 0
										mission["weather"]["clouds"]["thickness"] = 200
										mission["weather"]["clouds"]["base"] = 5460
										mission["weather"]["visibility"] = {}
										mission["weather"]["visibility"]["distance"] = 80000
										mission["weather"]["name"] = "Winter, clean sky"
										mission["weather"]["enable_dust"] = false
										mission["weather"]["type_weather"] = 0
										]]
--

--these two functions are for turning a list into a serialized string for writing to files

function dme.basicSerialize(value)
	if type(value) == "number" then
		return tostring(value)
	elseif type(value) == "boolean" then
		return tostring(value)
	else
		return string.format("%q", value)
	end
end

function dme.serializeWithCycles(name, value, saved)
	local serialized = {}
	saved = saved or {}
	if type(value) == "number" or type(value) == "string" or type(value) == "boolean" or type(value) == "table" then
		serialized[#serialized + 1] = name .. " = "
		if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
			serialized[#serialized + 1] = dme.basicSerialize(value) .. "\n"
		else
			if saved[value] then
				serialized[#serialized + 1] = saved[value] .. "\n"
			else
				saved[value] = name
				serialized[#serialized + 1] = "{}\n"
				for k, v in pairs(value) do
					local fieldname = string.format("%s[%s]", name, dme.basicSerialize(k))
					serialized[#serialized + 1] = dme.serializeWithCycles(fieldname, v, saved)
				end
			end
		end
		return table.concat(serialized)
	else
		return ""
	end
end

function dme.sleep(n)
	if n > 0 then os.execute("ping -n " .. tonumber(n + 1) .. " localhost > NUL") end
end

----------------------------------------------------------------------------------------------------------------  typeName change

function missionObject:changeTypeName(originalType, newType)
	local index = 0

	for coalition, coaTable in next, self.mission.coalition do
		log.write("DME", log.INFO, tostring(coalition) .. " " .. tostring(coaTable))

		for countries, countryTable in next, coaTable.country do
			if countryTable.plane ~= nil then
				for groupKey, groupValue in next, countryTable.plane.group do
					for unitKey, unitTable in next, groupValue.units do
						if unitTable.type == originalType then
							unitTable.type = newType
							index = index + 1
						end
					end
				end
			end
		end
	end

	log.write("DME", log.INFO, tostring(index) .. " " .. originalType .. "s replaced with type: " .. newType)
	return
end

----------------------------------------------------------------------------------------------------------------  coalition editing

function missionObject:addExtraCoalition(coalitionName)
	self.mission.coalition[coalitionName] = {}
	self.mission.coalition[coalitionName]["nav_points"] = {}
	self.mission.coalition[coalitionName]["bullseye"] = {}
	self.mission.coalition[coalitionName]["bullseye"]["x"] = 0
	self.mission.coalition[coalitionName]["bullseye"]["y"] = 0
	self.mission.coalition[coalitionName]["country"] = {}
	return
end

function missionObject:addCountryToCoalition(coalitionName, countryEnum)
	local removed = false

	if self.mission.coalitions[coalitionName] == nil then
		self.mission.coalitions[coalitionName] = {}
	end

	for coaName, coa in next, self.mission.coalitions do
		for i, country in next, coa do
			if country == countryEnum then
				table.remove(self.mission.coalitions[coaName], i)
				log.write("DME", log.INFO,
					"removed country " .. tostring(countryEnum) .. " from coalition " .. tostring(coaName))
				break
			end
		end
	end
	table.insert(self.mission.coalitions[coalitionName], countryEnum)

	if self.mission.coalition[coalitionName] == nil then
		self:addExtraCoalition(coalitionName)
	end

	log.write("DME", log.INFO, "added country " .. tostring(countryEnum) .. " to coalition " .. tostring(coalitionName))
	return
end

function missionObject:moveCountryAssetsToCoalition(countryEnum, coalitionName)
	local countryT = {}

	for coaName, coaTable in next, self.mission.coalition do
		if coaName ~= coalitionName then
			if coaTable.country ~= nil then
				for i, countryTable in next, coaTable.country do
					if countryTable["id"] == countryEnum then
						countryT = countryTable
						if self.mission.coalition[coaName].country == nil then
							self.mission.coalition[coaName].country = {}
						end
						self.mission.coalition[coaName].country[i] = nil
					end
				end
			end
		end
	end

	table.insert(self.mission.coalition[coalitionName].country, countryT)
	log.write("DME", log.INFO,
		"added country tables " .. tostring(countryEnum) .. " to coalition " .. tostring(coalitionName))

	return
end

function missionObject:changeAircraftCountryByFilter(pat, countryEnum)
	return
end

----------------------------------------------------------------------------------------------------------------  execution

--[[
										local newMission = dme.createInstance("C:\\source\\cold-war-production-v168.miz")
										
										newMission:getWeatherFromTemplate("C:\\source\\weapon_templates.miz")
										
										local restrictionTemplates = dme.loadWeaponTemplates("C:\\source\\weapon_templates.miz")
										
										newMission:applyWeaponRestrictionTemplateToAll( restrictionTemplates["red"]["Template A - MiG-21"] )
										
										newMission:writeMissionTemplateToFile("C:\\DME\\cold-war-production-v143_export.miz")
										]]
--

dmeHooks = {}

--[[
										
										onMissionLoadEnd() is the hook that DME will utilize
										
										DME basically takes a initilization mission and creates two copies to be edited. after it modifies the server config file to change the mission list, it will end the dcs process to apply the changes.
										
										there will be two missions named 'mission name'_DME1.miz and 'mission name'_DME2.miz. when a mission finishes loading, it will modify the mission that was not loaded to whatever we specify in the hook.
										In our specific case, we cycle through 7 weather template missions and apply weapon restrictions based on theatre.
										
										please look through the hook for details regarding our implementation
										
										]]
--



function dmeHooks.onMissionLoadEnd()
	local dmeMissionToEdit = 0
	local serverSettingsFile = lfs.writedir() .. "Config/serverSettings.lua"
	local savedGames = lfs.writedir()
	local missionName = DCS.getMissionFilename()

	log.write("DME", log.INFO, "current missionFileName: " .. missionName)
	local initFound = ("INIT.miz" == missionName:sub(#missionName - 7, #missionName)) --if the mission ends in INIT.miz, it will run the init portion of the hook

	dofile(serverSettingsFile)                                                     --load config table into an accessible namespace

	log.write("DME", log.INFO, "config table: " .. tostring(cfg))

	if missionName:find("_DME1.miz") ~= nil then dmeMissionToEdit = 2 end --either mission to be editied
	if missionName:find("_DME2.miz") ~= nil then dmeMissionToEdit = 1 end
	log.write("DME", log.INFO, "Next Mission: " .. tostring(dmeMissionToEdit))
	log.write("DME", log.INFO, "INIT found: " .. tostring(initFound))

	if initFound then  --if init miz
		cfg.missionList = {} --modify the mission list
		cfg.missionList[1] = missionName:sub(1, #missionName - 8) .. "_DME1.miz"
		cfg.missionList[2] = missionName:sub(1, #missionName - 8) .. "_DME2.miz"

		local serverSettingsString = dme.serializeWithCycles("cfg", cfg) --write the config (cfg) to the server settings file
		local f = io.open(serverSettingsFile, "w")
		f:write(serverSettingsString)
		f:close()
	end

	if dmeMissionToEdit > 0 or initFound then                          --if its one or two or is init miz
		local nextMission
		if dmeMissionToEdit > 0 then                                   --if its a DME1 or DME2
			nextMission = dme.createInstance(cfg.missionList[dmeMissionToEdit]) --create new mission object based on the supplied file
		elseif initFound then                                          --if init
			nextMission = dme.createInstance(missionName)              ----create new mission object based on the supplied file
		end

		------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


		local theatre = nextMission.mission.theatre
		local weatherDir =
			"C:\\Users\\ecwadmin\\Saved Games\\DCS.openbeta_server\\ColdWar\\Files\\DME\\Weather Templates\\" ..
			theatre ..
			"\\"                                                                                               --folders where weather templates are stored. needs sub folders for each theatre
		local optionsFile =
		"C:\\Users\\ecwadmin\\Saved Games\\DCS.openbeta_server\\ColdWar\\Files\\DME\\Options Templates\\options.miz" --filepath where options file is defined
		local f = io.open(savedGames .. ".weatherIndex", "r")
		local index = tonumber(f:read("*all"))
		f:close()

		if index == 0 or index == nil then --if there is a not a weather index file, create it.
			local f = io.open(savedGames .. ".weatherIndex", "w")
			f:write("1")
			f:close()
		end

		nextMission:setOptionsFromFile(optionsFile)

		log.write("DME", log.INFO, DCS.getMissionName())
		log.write("DME", log.INFO, DCS.getMissionFilename())

		--------------------------------------------------------------------------------------------- Weather Section

		local weatherFileCount = 0

		for file in lfs.dir(weatherDir) do --count the number of weather templates for use later
			if file ~= "." and file ~= ".." then
				weatherFileCount = weatherFileCount + 1
			end
		end

		if index >= weatherFileCount then
			index = 1
		else
			index = tonumber(index) + 1
		end

		log.write("DME", log.INFO, "weather index: " .. tostring(index)) --this block changes the weather to the next file based on the index from the weatherIndex file
		for file in lfs.dir(weatherDir) do
			log.write("DME", log.INFO, "weather file: " .. tostring(file) .. " " .. file:sub(#file - 4, #file - 4))
			if tonumber(file:sub(#file - 4, #file - 4)) == index then
				log.write("DME", log.INFO, "Applying weather template: " .. weatherDir .. file)
				local weatherTemplateMission = dme.createInstance(weatherDir .. file) --create a missionObject with selected weather file
				local weather = weatherTemplateMission:getWeatherFromTemplate() --get weather from the created missionObject
				nextMission:setWeatherFromTemplate(weather)               --set weather from the template

				local newCalendar = weatherTemplateMission:getCalendarTimeNamed() --get the time/date

				nextMission:setStartTime(newCalendar.startTime)
				nextMission:setDay(newCalendar.day)
				nextMission:setMonth(newCalendar.month)

				log.write("DME", log.INFO,
					"Setting calendar date: Time: " ..
					tostring(newCalendar.startTime) ..
					" | Day: " .. tostring(newCalendar.day) .. " | Month: " .. tostring(newCalendar.month))

				break
			end
		end

		local f = io.open(savedGames .. ".weatherIndex", "w")
		f:write(tostring(index))
		f:close()

		local weapon_template_path = nextMission:findMatchingDateTemplate(
			"C:\\Users\\ecwadmin\\Saved Games\\DCS.openbeta_server\\ColdWar\\Files\\DME\\Weapon Templates\\")

		--nextMission:addCountryToCoalition("green", 17)            --add insurgents to green
		--nextMission:moveCountryAssetsToCoalition(17, "green")     --move insurgent country table to green
		--------------------------------------------------------------------------------------------- Weapon Section
		nextMission:changeTypeName("Su-33", "MiG-21Bis")
		nextMission:changeTypeName("FA-18C_hornet", "F-5E-3")
		--------------------------------------------------------------------------------------------- Weapon Section

		local weaponTemplatesPlanes = dme.loadWeaponTemplatesPlanes(weapon_template_path) --weapon template definitions
		local weaponTemplatesHelis = dme.loadWeaponTemplatesHelis(weapon_template_path)

		local templateText = 'Red Template '

		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "MiG-19"]) --THESE NEED TO BE EXACT TO WORK CORRECTLY
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "MiG-21"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "Su-25"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "Su-25T"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "MiG-15"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "Mirage-F1EE"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "Mirage-F1CE"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "Mirage-F1BE"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "MiG-29"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "L-39"])
		nextMission:applyWeaponTemplateToAllHelis(weaponTemplatesHelis["red"][templateText .. "Mi-8"])
		nextMission:applyWeaponTemplateToAllHelis(weaponTemplatesHelis["red"][templateText .. "Mi-24"])

		--syrian yaks
		nextMission:applyWeaponTemplateToPlaneGroupFilter(weaponTemplatesPlanes["red"]["Yak-38"], "Yak%-38")
		nextMission:applyWeaponTemplateToPlaneGroupFilter(weaponTemplatesPlanes["red"]["Kh-23"], "Kh%-23")

		local templateText = 'Blue Template '
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["blue"][templateText .. "F-5"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["blue"][templateText .. "AJS37"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["blue"][templateText .. "MB-339"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["blue"][templateText .. "F-86"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["blue"][templateText .. "C-101"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["blue"][templateText .. "A-10"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["blue"][templateText .. "F-14A-135-GR"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["blue"][templateText .. "F-16"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["blue"][templateText .. "F-15"])
		nextMission:applyWeaponTemplateToAllPlanes(weaponTemplatesPlanes["blue"][templateText .. "A-4E-C"])
		nextMission:applyWeaponTemplateToAllHelis(weaponTemplatesHelis["blue"][templateText .. "SA342M"])
		nextMission:applyWeaponTemplateToAllHelis(weaponTemplatesHelis["blue"][templateText .. "SA342L"])
		nextMission:applyWeaponTemplateToAllHelis(weaponTemplatesHelis["blue"][templateText .. "SA342Mini"])
		nextMission:applyWeaponTemplateToAllHelis(weaponTemplatesHelis["blue"][templateText .. "UH-1"])
		nextMission:applyWeaponTemplateToAllHelis(weaponTemplatesHelis["blue"][templateText .. "AH-64"])
		nextMission:applyWeaponTemplateToAllHelis(weaponTemplatesHelis["blue"][templateText .. "OH-58D(R)"])

		--------------------------------------------------------------------------------------------- Radio Section

		local radioTemplatesPlanes = dme.loadRadioTemplatesPlanes(weapon_template_path) --radio template definition
		local radioTemplatesHelis = dme.loadRadioTemplatesHelis(weapon_template_path)

		local templateText = 'Red Template '
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["red"][templateText .. "MiG-19"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["red"][templateText .. "MiG-21"])
		nextMission:applyRadioTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "Mirage-F1EE"])
		nextMission:applyRadioTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "Mirage-F1CE"])
		nextMission:applyRadioTemplateToAllPlanes(weaponTemplatesPlanes["red"][templateText .. "Mirage-F1BE"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["red"][templateText .. "Su-25"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["red"][templateText .. "Su-25T"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["red"][templateText .. "MiG-15"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["red"][templateText .. "MiG-29"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["red"][templateText .. "L-39"])
		nextMission:applyRadioTemplateToAllHelis(radioTemplatesHelis["red"][templateText .. "Mi-8"])
		nextMission:applyRadioTemplateToAllHelis(radioTemplatesHelis["red"][templateText .. "Mi-24"])

		local templateText = 'Blue Template '
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["blue"][templateText .. "F-5"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["blue"][templateText .. "AJS37"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["blue"][templateText .. "MB-339"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["blue"][templateText .. "F-86"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["blue"][templateText .. "A-10"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["blue"][templateText .. "C-101"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["blue"][templateText .. "F-14A-135-GR"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["blue"][templateText .. "F-16"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["blue"][templateText .. "F-15"])
		nextMission:applyRadioTemplateToAllPlanes(radioTemplatesPlanes["blue"][templateText .. "A-4E-C"])
		nextMission:applyRadioTemplateToAllHelis(radioTemplatesHelis["blue"][templateText .. "SA342M"])
		nextMission:applyRadioTemplateToAllHelis(radioTemplatesHelis["blue"][templateText .. "SA342L"])
		nextMission:applyRadioTemplateToAllHelis(radioTemplatesHelis["blue"][templateText .. "SA342Mini"])
		nextMission:applyRadioTemplateToAllHelis(radioTemplatesHelis["blue"][templateText .. "UH-1"])
		nextMission:applyRadioTemplateToAllHelis(radioTemplatesHelis["blue"][templateText .. "AH-64"])
		nextMission:applyRadioTemplateToAllHelis(radioTemplatesHelis["blue"][templateText .. "OH-58D(R)"])

		nextMission:removeModRequirements()

		if initFound then --if its the init, write the template to the 2 missions defined in the config list
			nextMission:writeMissionTemplateToFile(cfg.missionList[1])
			nextMission:writeMissionTemplateToFile(cfg.missionList[2])

			local f = io.open("C:/Users/ecwadmin/Saved Games/DCS.openbeta_server/ColdWar/.loadFromPersistence", "w")
			f:write("true")
			f:close()

			DCS.exitProcess()
		elseif dmeMissionToEdit > 0 then --if not, and its already a DME mission, then write to the next mission in line
			nextMission:writeMissionTemplateToFile(cfg.missionList[dmeMissionToEdit])
		end
	end
end

local theatres = {} --set next theatre. ends up as ServerSettings_X.lua
theatres["Caucasus"] = "Syria"
theatres["Syria"] = "Caucasus"

local function theatre()
	return (DCS.getCurrentMission().mission.theatre)
end

function dmeHooks.onNetMissionEnd()
	local serverSettingsFile           = lfs.writedir() .. "Config/serverSettings.lua"
	local serverSettingsDirectoryFiles = lfs.writedir() .. "ColdWar/Files/Configs/ServerSettings_"
	local campaignEnded, _error        = net.dostring_in('server', " return trigger.misc.getUserFlag('endSession'); ") --get the flag of whatever the campaign end is tied to. currently set to 1 in FinishCampaign() in base.lua


	log.write("loadNextRotation", log.INFO, "endSession: " .. tostring(campaignEnded))

	if tostring(campaignEnded) ~= "3" then
		--[[ --old method
												local newTheatre = theatres[theatre()]
												log.write("loadNextRotation", log.INFO, "Campaign Ended! overwriting server settings with: " .. serverSettingsDirectoryFiles .. newTheatre .. ".lua")
												local f = io.open(serverSettingsDirectoryFiles .. newTheatre .. ".lua",'r')
												local newServerSettings = f:read("*all")
												--read
												f:close()
												
												local f = io.open(serverSettingsFile,'w')
												f:write(newServerSettings)
												f:close()
										
												log.write("loadNextRotation", log.INFO, "Exiting process...")
												
												DCS.exitProcess()
												]]
		--

		local next_mission = dme.incrementCampaignRotationFile(
			lfs.writedir() .. "ColdWar/Files/Configs/current.rq",
			lfs.writedir() .. "ColdWar/Files/Missions/"
		)
		log.write("loadNextRotation", log.INFO, "next campaign will be: " .. next_mission)

		dofile(serverSettingsFile)

		local nextCampaign = {}
		nextCampaign[1] = next_mission
		cfg.missionList = nextCampaign

		local serverSettingsString = dme.serializeWithCycles("cfg", cfg) --write the config (cfg) to the server settings file
		local f = io.open(serverSettingsFile, "w")
		f:write(serverSettingsString)
		f:close()

		DCS.exitProcess()

		return
	end
end

DCS.setUserCallbacks(dmeHooks)
