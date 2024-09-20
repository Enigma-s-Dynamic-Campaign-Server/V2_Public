local pointCommodityEventHandler = {}

function pointCommodityEventHandler:onEvent(event)
    if world.event.S_EVENT_MARK_CHANGE == event.id then
        local coa = event.coalition

        if string.find(event.text, "RECON") ~= nil then
            local playerName = ""
            local playerID = ""
            for k, player in next, net.get_player_list() do
                playerID = net.get_player_info(player, 'id')
                if tostring(trigger.misc.getUserFlag(playerID)) ~= "0" then
                    if string.find(event.text, tostring(trigger.misc.getUserFlag(playerID))) then
                        playerName = net.get_player_info(player, 'name')
                        break
                    end
                end
            end
            if playerName == "" then return end

            local hexToFind = ecw.findHexFromPoint(event.pos, ecw.hexInstances)
            if hexToFind ~= nil then
                if hexToFind.coa ~= coa then
                    local usersPoints = util.getUserPoints(playerName)
                    if usersPoints[2] == nil then usersPoints[2] = 0 end
                    if usersPoints[2] >= pc.reconPointCost then
                        util.outTextForCoalition(coa, 15, playerName, "has ordered a Recon Mission over", hexToFind.name)
                        local outcome = ai.spawnReconPlane(coa, hexToFind.name)
                        if outcome == true then util.addUserPoints(playerName, (pc.reconPointCost * -1)) end
                    end
                    trigger.action.removeMark(event.idx)
                    trigger.action.setUserFlag(tostring(playerID), 0)
                end
            end
        end

        if string.find(event.text, "SEAD") ~= nil then
            local playerName = ""
            local playerID = ""
            for k, player in next, net.get_player_list() do
                playerID = net.get_player_info(player, 'id')
                if tostring(trigger.misc.getUserFlag(playerID)) ~= "0" then
                    if string.find(event.text, tostring(trigger.misc.getUserFlag(playerID))) then
                        playerName = net.get_player_info(player, 'name')
                        break
                    end
                end
            end
            if playerName == "" then return end

            local hexToFind = ecw.findHexFromPoint(event.pos, ecw.hexInstances)
            if hexToFind ~= nil then
                if hexToFind.coa ~= coa then
                    local usersPoints = util.getUserPoints(playerName)
                    if usersPoints[2] == nil then usersPoints[2] = 0 end
                    if usersPoints[2] >= pc.seadPointCost then
                        util.outTextForCoalition(coa, 15, playerName, "has ordered a SEAD Mission over", hexToFind.name)
                        local outcome = ai.spawnSeadPlane(coa, hexToFind.name)
                        if outcome == true then util.addUserPoints(playerName, (pc.seadPointCost * -1)) end
                    end
                    trigger.action.removeMark(event.idx)
                    trigger.action.setUserFlag(tostring(playerID), 0)
                end
            end
        end

        if string.find(event.text, "BOMBER") ~= nil then
            local playerName = ""
            local playerID = ""
            for k, player in next, net.get_player_list() do
                playerID = net.get_player_info(player, 'id')
                if tostring(trigger.misc.getUserFlag(playerID)) ~= "0" then
                    if string.find(event.text, tostring(trigger.misc.getUserFlag(playerID))) then
                        playerName = net.get_player_info(player, 'name')
                        break
                    end
                end
            end
            if playerName == "" then return end

            local hexToFind = ecw.findHexFromPoint(event.pos, ecw.hexInstances)
            if hexToFind ~= nil then
                if hexToFind.coa ~= coa then
                    local usersPoints = util.getUserPoints(playerName)
                    if usersPoints[2] == nil then usersPoints[2] = 0 end
                    if usersPoints[2] >= pc.bomberPointCost then
                        util.outText(25, playerName, "has ordered a", ecw.coaEnums[coa], "Bomber Mission to",
                            hexToFind.name .. "!")
                        local outcome = ai.spawnBomberMission(coa, hexToFind.name)
                        if outcome == true then util.addUserPoints(playerName, (pc.bomberPointCost * -1)) end
                    end
                    trigger.action.removeMark(event.idx)
                    trigger.action.setUserFlag(tostring(playerID), 0)
                end
            end
        end


        if string.find(event.text, "REPAIR") ~= nil then
            local playerName = ""
            local playerID = ""
            for k, player in next, net.get_player_list() do
                playerID = net.get_player_info(player, 'id')
                if tostring(trigger.misc.getUserFlag(playerID)) ~= "0" then
                    if string.find(event.text, tostring(trigger.misc.getUserFlag(playerID))) then
                        playerName = net.get_player_info(player, 'name')
                        break
                    end
                end
            end
            if playerName == "" then return end

            local hexToFind = ecw.findHexFromPoint(event.pos, ecw.hexInstances)
            if hexToFind ~= nil then
                if hexToFind.coa == coa then
                    local usersPoints = util.getUserPoints(playerName)
                    if usersPoints[2] == nil then usersPoints[2] = 0 end
                    if usersPoints[2] >= pc.repairPointCost then
                        util.outText(25, playerName, "has ordered a", ecw.coaEnums[coa], "Repair Mission to",
                            hexToFind.name .. "!")
                        local outcome = ai.spawnRepairPlane(coa, hexToFind.name)
                        if outcome == true then util.addUserPoints(playerName, (pc.repairPointCost * -1)) end
                    end
                    trigger.action.removeMark(event.idx)
                    trigger.action.setUserFlag(tostring(playerID), 0)
                end
            end
        end

        if string.find(event.text, "AWACS") ~= nil then
            local playerName = ""
            local playerID = ""
            for k, player in next, net.get_player_list() do
                playerID = net.get_player_info(player, 'id')
                if tostring(trigger.misc.getUserFlag(playerID)) ~= "0" then
                    if string.find(event.text, tostring(trigger.misc.getUserFlag(playerID))) then
                        playerName = net.get_player_info(player, 'name')
                        break
                    end
                end
            end
            if playerName == "" then return end

            local hexToFind = ecw.findHexFromPoint(event.pos, ecw.hexInstances)
            if hexToFind ~= nil then
                if hexToFind.coa == coa then
                    local usersPoints = util.getUserPoints(playerName)
                    if usersPoints[2] == nil then usersPoints[2] = 0 end
                    if usersPoints[2] >= pc.awacsPointCost then
                        util.outText(25, playerName, "has ordered a", ecw.coaEnums[coa], "AWACS Mission to",
                            hexToFind.name .. "!")
                        local outcome = ai.spawnAwacsPlane(coa, hexToFind.name)
                        if outcome == true then util.addUserPoints(playerName, (pc.awacsPointCost * -1)) end
                    end
                    trigger.action.removeMark(event.idx)
                    trigger.action.setUserFlag(tostring(playerID), 0)
                end
            end
        end
    end

    if world.event.S_EVENT_LAND == event.id then
        if event.initiator == nil then return end
        local groupName = event.initiator:getGroup():getName()

        if string.find(groupName, "ReconFlight") ~= nil then
            util.log("recon hex", util.split(groupName, "_")[2])
            local hexToReveal = ecw.hexInstances[util.split(groupName, "_")[2]]

            if hexToReveal.coa == event.initiator:getCoalition() then return nil end
            util.log("revealing infra in hex", hexToReveal.name)

            for triggerName, infraObject in next, hexToReveal.infrastructureObjects do
                infraObject:reveal()
                local sphere = trigger.misc.getZone(triggerName)
                sphere.point.y = land.getHeight({ x = sphere.point.x, y = sphere.point.z })
                local volS = {
                    id = world.VolumeType.SPHERE,
                    params = {
                        point = sphere.point,
                        radius = 7000
                    }
                }
                local ifFound = function(foundItem, val)
                    recon.addMarkerUnit(foundItem, 0)
                    return true
                end
                world.searchObjects(Object.Category.STATIC, volS, ifFound)
                world.searchObjects(Object.Category.UNIT, volS, ifFound)
            end
            for triggerName, factoryObject in next, hexToReveal.factoryObjects do
                local sphere = trigger.misc.getZone(triggerName)
                sphere.point.y = land.getHeight({ x = sphere.point.x, y = sphere.point.z })
                local volS = {
                    id = world.VolumeType.SPHERE,
                    params = {
                        point = sphere.point,
                        radius = 7000
                    }
                }
                local ifFound = function(foundItem, val)
                    recon.addMarkerUnit(foundItem, 0)
                    return true
                end
                world.searchObjects(Object.Category.STATIC, volS, ifFound)
                world.searchObjects(Object.Category.UNIT, volS, ifFound)
            end
            for triggerName, depotObject in next, hexToReveal.depotObjects do
                local sphere = trigger.misc.getZone(triggerName)
                sphere.point.y = land.getHeight({ x = sphere.point.x, y = sphere.point.z })
                local volS = {
                    id = world.VolumeType.SPHERE,
                    params = {
                        point = sphere.point,
                        radius = sphere.radius
                    }
                }
                local ifFound = function(foundItem, val)
                    recon.addMarkerUnit(foundItem, 0)
                    return true
                end
                world.searchObjects(Object.Category.STATIC, volS, ifFound)
                world.searchObjects(Object.Category.UNIT, volS, ifFound)
            end

            event.initiator:destroy()
        else
            if string.find(groupName, "Flight") ~= nil and event.initiator:getPlayerName() == nil then
                event.initiator:destroy()
            end
        end
        return
    end
end

function pc.bomberCheck(t, time)
    local bomberGroupName, targetPoint, targetTable = unpack(t)

    local bomberGroup = Group.getByName(bomberGroupName)
    if bomberGroup == nil then return end
    if bomberGroup:getSize() <= 0 then return end

    local min = { x = targetPoint.x, y = targetPoint.y, z = targetPoint.z }
    local max = { x = targetPoint.x, y = targetPoint.y, z = targetPoint.z }

    min.x = min.x - 10000
    min.z = min.z - 10000
    min.y = 0

    max.x = max.x + 10000
    max.z = max.z + 10000
    max.y = 45000

    local volB = {
        id = world.VolumeType.BOX,
        params = {
            min = min,
            max = max
        }
    }

    local foundBombers = 0
    local ifFound = function(foundItem, val)
        if foundItem:getGroup():getName() == bomberGroup:getName() then
            foundBombers = foundBombers + 1
        end
        return true
    end
    world.searchObjects(Object.Category.UNIT, volB, ifFound)

    local foundUnits = {}
    if foundBombers > 0 then
        local sphere = trigger.misc.getZone(targetTable.name)
        local volS = {
            id = world.VolumeType.SPHERE,
            params = {
                point = sphere.point,
                radius = sphere.radius
            }
        }
        local ifFound = function(foundItem, val)
            table.insert(foundUnits, foundItem)
            return true
        end

        world.searchObjects(Object.Category.STATIC, volS, ifFound)

        for _, static in next, foundUnits do
            if static ~= nil then
                if static:isExist() then
                    if static.getPoint ~= nil then
                        trigger.action.explosion(static:getPoint(), 1500)
                    end
                end
            end
        end

        util.outText(20, targetTable.name, "has been bombed!")
        return nil
    end

    return time + 10
end

function pc.transportCheck(t, time)
    local bomberGroupName, targetPoint, hexName = unpack(t)

    local bomberGroup = Group.getByName(bomberGroupName)
    if bomberGroup == nil then return end
    if bomberGroup:getSize() <= 0 then return end

    local min = { x = targetPoint.x, y = targetPoint.y, z = targetPoint.z }
    local max = { x = targetPoint.x, y = targetPoint.y, z = targetPoint.z }

    min.x = min.x - 5000
    min.z = min.z - 5000
    min.y = 0

    max.x = max.x + 5000
    max.z = max.z + 5000
    max.y = 15000

    local volB = {
        id = world.VolumeType.BOX,
        params = {
            min = min,
            max = max
        }
    }

    local foundBombers = 0
    local ifFound = function(foundItem, val)
        if foundItem:getGroup():getName() == bomberGroup:getName() then
            foundBombers = foundBombers + 1
        end
        return true
    end
    world.searchObjects(Object.Category.UNIT, volB, ifFound)

    if ecw.hexInstances[hexName].coa ~= bomberGroup:getCoalition() then return nil end
    if foundBombers > 0 then
        ecw.hexInstances[hexName]:spawnAA()

        if ecw.hexInstances[hexName].poi["Airbase"] ~= nil then
            local volS = {
                id = world.VolumeType.SPHERE,
                params = {
                    point = ecw.hexInstances[hexName].poi["Airbase"]:getPoint(),
                    radius = 13000
                }
            }
            world.removeJunk(volS)
        end

        util.outText(20, hexName, "has been repaired!")
        return nil
    end

    return time + 10
end

world.addEventHandler(pointCommodityEventHandler)
