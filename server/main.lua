local QBCore = exports['qb-core']:GetCoreObject()
local Groups = {}

-- Events

RegisterNetEvent('srp-garbage:server:createJob', function( groupID)
    local src = source
    if exports['ps-playergroups']:getJobStatus(groupID) == "WAITING" then
        Groups[#Groups + 1] = {
            ["groupID"] = groupID,
            ["truckID"] = 0,
            ["routes"] = 10,
            ["currentRoute"] = 0,
            ["bags"] = 0,
            ["pickupAmount"] = 0,
            ["totalCollected"] = 0
        }
        Wait(500)

        local TruckSpawn = Config.TruckSpawns[math.random(1, #Config.TruckSpawns)]

        local car = CreateVehicleServerSetter("trash", "automobile", TruckSpawn.x, TruckSpawn.y, TruckSpawn.z, TruckSpawn.w)

        while not DoesEntityExist(car) do
            Wait(25)
        end

        if DoesEntityExist(car) then
            SetVehicleNumberPlateText(car, "GARB"..tostring(math.random(1000, 9999)))
            SetVehicleDoorsLocked(car, 1)
            Wait(1000)
            Groups[groupID].truckID = car
            Groups[groupID].route = PickRandomRoute()
            Groups[groupID].pickupAmount = math.random(4, 6)
            local plate = GetVehicleNumberPlateText(car)
            local members = exports['ps-playergroups']:getGroupMembers(groupID)
            for i = 1, #members do
                TriggerClientEvent('vehiclekeys:client:SetOwner', members[i], plate)
                TriggerClientEvent("garbage:updatePickup", members[i], Routes.Locations[Groups[groupID]["route"]]["coords"])
                Wait(100)
                TriggerClientEvent("srp-garbage:client:startRoute", members[i], NetworkGetNetworkIdFromEntity(car))
            end
            
            exports["ps-playergroups"]:setJobStatus(groupID, "GARBAGE RUN")
        end
        exports["ps-playergroups"]:CreateBlipForGroup(groupID, "garbagePickup", {
            label = "Pickup", 
            coords = Routes.Locations[Groups[groupID]["route"]]["coords"], 
            sprite = 162, 
            color = 11, 
            scale = 1.0, 
            route = true,
            routeColor = 2,
        })
    else
        TriggerClientEvent('QBCore:Notify', src, "ERROR", "error")
    end
end)

RegisterNetEvent('srp-garbage:server:stopJob', function(groupID)
    local src = source
    local truckCoords = GetEntityCoords(Groups[groupID]["truckID"])

    if #(truckCoords - Config.Blip) < 50 then
        DeleteEntity(Groups[groupID]["truckID"])

        exports["ps-playergroups"]:RemoveBlipForGroup(groupID, "garbagePickup")
        local members = exports["ps-playergroups"]:getGroupMembers(groupID)
        local payout = math.floor((Groups[groupID]["totalCollected"] * Config.PPB) / exports["ps-playergroups"]:getGroupSize(groupID) + 0.5)

        for i=1, #members do
            TriggerClientEvent("srp-garbage:client:endRoute", members[i])
            if payout > 0 then
                local Player = QBCore.Functions.GetPlayer(members[i])
                Player.Functions.AddMoney("bank", payout, "Garbage Runs")
                TriggerClientEvent("QBCore:Notify", members[i], "You got $"..payout.." for your garbage run", "success")
            end
        end
        Groups[groupID].totalCollected = 0
        Groups.groupID = nil
        exports["ps-playergroups"]:setJobStatus(groupID, "WAITING")
    else 
        TriggerClientEvent("QBCore:Notify", src, "Your truck is not inside the facility", "error")
    end
end)

RegisterServerEvent("srp-garbage:server:updateBags", function(groupID)
    local src = source
    Groups[groupID].bags = Groups[groupID].bags + 1
    Groups[groupID].totalCollected = Groups[groupID].totalCollected + 1
    if Groups[groupID].bags >= Groups[groupID].pickupAmount then
        Groups[groupID].bags = 0
        Groups[groupID].pickupAmount = math.random(4, 6)
        local newRoute = PickRandomRoute()
        while newRoute == Groups[groupID].currentRoute do
            newRoute = PickRandomRoute()
            Wait(100)
        end
        local members = exports["ps-playergroups"]:getGroupMembers(groupID)
        for i=1, #members do
            TriggerClientEvent("QBCore:Notify", members[i], "All bags collected for this dumpster", "primary")
            TriggerClientEvent('srp-garage:client:pickupClean', members[i])
            TriggerClientEvent('garbage:updatePickup', members[i], Routes.Locations[newRoute]["coords"])
            if math.random(1, 100) > 70 then
                local itemIndex = math.random(1, #Config.Rewards)
                local amount = math.random(Config.Rewards[itemIndex]["min"], Config.Rewards[itemIndex]["max"])
                local Player = QBCore.Functions.GetPlayer(members[i])
                Player.Functions.AddItem(Config.Rewards[itemIndex]["item"], amount)
                TriggerClientEvent('inventory:client:ItemBox', members[i], QBCore.Shared.Items[Config.Rewards[itemIndex]["item"]], 'add', amount)
            end
        end
        Groups[groupID].currentRoute = newRoute
        exports["ps-playergroups"]:RemoveBlipForGroup(groupID, "garbagePickup")
        exports["ps-playergroups"]:CreateBlipForGroup(groupID, "garbagePickup", {
            label = "Pickup", 
            coords = Routes.Locations[newRoute]["coords"], 
            sprite = 162, 
            color = 11, 
            scale = 1.0, 
            route = true,
            routeColor = 2,
        })
    end
end)

-- Functions

function PickRandomRoute()
    return math.random(1, #Routes.Locations)
end