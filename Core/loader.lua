--loader.lua
assert(loadfile(lfs.writedir().."ColdWar/Core/logger.lua"))()

local campaign_logger_file = lfs.writedir() .. "/ColdWar/Files/Logs/Campaign_" .. tostring(os.date("%m-%d-%Y")) .. ".log"

Campaign_log = logger:new(logger.enums.info, campaign_logger_file, "a", "%Y-%m-%d", "%H:%M:%S")

Campaign_log:info("loader.lua","loader initialized",campaign_logger_file)

assert(loadfile(lfs.writedir().."ColdWar/Core/variables.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/util.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/hexDefines.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/recon_v2.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/infrastructure.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/persistence.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/taskingEngine.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/aircraftAttrition.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/helicopter.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/SplashTesting.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/debugger.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/ewr_ECW.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/csar.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/pointCommodities.lua"))()
assert(loadfile(lfs.writedir().."ColdWar/Core/AI.lua"))()


persist.saveHexCoalition(ecw.hexInstances)
persist.saveUnitTemplatesToFile()
persist.spawnUnitTemplatesFromFiles()

infrastructure.infraInit(ecw.hexInstances)
infrastructure.depotInit(ecw.hexInstances)
infrastructure.factoryInit(ecw.hexInstances)

redTE = te.createTaskingEntity("red", 1)
blueTE = te.createTaskingEntity("blue", 2)

te.aa = timer.scheduleFunction(te.spawnAA , ecw.hexInstances, timer.getTime() + 11 )
timer.scheduleFunction(function(t) te.init(unpack(t)) end, {redTE, blueTE, ecw.hexInstances}, timer.getTime() + 3)
timer.scheduleFunction(function(t) te.init(unpack(t)) end, {blueTE, redTE, ecw.hexInstances}, timer.getTime() + 3)


--ecw.hexInstances["Sector 3-15"].usableWarMaterial = -20

if ecwVersionToLoad == 1 then
    te.id = timer.scheduleFunction(te.controlLoop , {redTE,blueTE,ecw.hexInstances} , timer.getTime() + 60 )
elseif ecwVersionToLoad == 2 then
    te.id = timer.scheduleFunction(te.controlLoopV2 , {redTE,blueTE,ecw.hexInstances} , timer.getTime() + 60 )
    te.hexHealthAudit = timer.scheduleFunction(te.calculateHexHealth , nil , timer.getTime() + 60 )
end

te.aa = timer.scheduleFunction(te.spawnAA , ecw.hexInstances, timer.getTime() + 11 )

te.spawnFARP(ecw.hexInstances,timer.getTime()+5)


ecw.slots = {}
local f = io.open(lfs.writedir() .. "ColdWar/Files/.slots", "r")
local s = f:read()
f:close()