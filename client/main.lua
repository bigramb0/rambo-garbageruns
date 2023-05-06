local QBCore = exports["qb-core"]:GetCoreObject()
local DoingRoute = false
local HasBag = false
local BagObject = nil
local pickupLocation = vector3(0.0, 0.0, 0.0)
local Truck = nil

-- Threads

CreateThread(function()
    local garbageBlip = AddBlipForCoord(Config.Blip)
    SetBlipSprite(garbageBlip, 318)
    SetBlipDisplay(garbageBlip, 4)
    SetBlipScale(garbageBlip, 1.0)
    SetBlipAsShortRange(garbageBlip, true)
    SetBlipColour(garbageBlip, 54)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Garbage Depot")
    EndTextCommandSetBlipName(garbageBlip)
end)

CreateThread(function()
    local hash = GetHashKey('s_m_y_construct_01')

    -- Loads model
    RequestModel(hash)
    while not HasModelLoaded(hash) do
      Wait(1)
    end
    -- Creates ped when everything is loaded
    ped = CreatePed(0, hash, Config.NPC.x, Config.NPC.y, Config.NPC.z, true, false)
    SetEntityHeading(ped, Config.Heading)
    Wait(1000)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    local ped = {
        `s_m_y_construct_01`,
    }
end)

exports['qb-target']:AddBoxZone("garbped1", vector3(Config.NPC.x, Config.NPC.y, Config.NPC.z), 1, 1, {
    name="garbped1",
    heading=Config.Heading,
    debugPoly=false,
    minZ=Config.NPC.z-2,
    maxZ=Config.NPC.z+2 
  },{
    options = {
        {
            type = "client",
            event = "srp-garbage:client:attemptStart",
            label = 'Start Garbage Run',
            icon = 'fa-solid fa-circle',
            canInteract = function()
                local status = exports['ps-playergroups']:GetJobStage()
                if status == "WAITING" then return true end
                return false
            end,
        },
        {
            type = "client",
            event = "srp-garbage:client:attemptStop",
            label = 'Complete Garbage Run',
            icon = 'fa-solid fa-circle',
            canInteract = function()
                local status = exports['ps-playergroups']:GetJobStage()
                if status == "GARBAGE RUN" then return true end
                return false
            end,
        },
        },
    distance = 3.0
}) 

-- Events

RegisterNetEvent('srp-garbage:client:attemptStart', function()
    print("attempting start")
    if exports['ps-playergroups']:IsGroupLeader() then
        print("is leader")
        if exports["ps-playergroups"]:GetJobStage() == "WAITING" then
            print("is waiting")
            local groupID = exports["ps-playergroups"]:GetGroupID()
            print(groupID)
            local model = GetHashKey("trash")
            RequestModel(model)
            while not HasModelLoaded(model) do
                Wait(0)
            end
            print("model loaded")
            Wait(500)
            TriggerServerEvent("srp-garbage:server:createJob", groupID)
            print("triggered server event")
        else 
            QBCore.Functions.Notify("Your group is already doing something!", "error")
        end
    else 
        QBCore.Functions.Notify("You need to be the group leader to start a job!", "error")
    end
end)

RegisterNetEvent("srp-garbage:client:attemptStop", function()
    if exports["ps-playergroups"]:IsGroupLeader() then 
        if exports["ps-playergroups"]:GetJobStage() == "GARBAGE RUN" then
            local groupID = exports["ps-playergroups"]:GetGroupID()
            Wait(500)
            TriggerServerEvent("srp-garbage:server:stopJob", groupID)
        else 
            QBCore.Functions.Notify("Your group isn't doing a run!", "error")
        end
    else 
        QBCore.Functions.Notify("You are not the group leader!", "error")
    end
end)

RegisterNetEvent("srp-garbage:client:startRoute", function(truckID)
    Truck = NetworkGetEntityFromNetworkId(truckID)
    exports['qb-target']:AddGlobalVehicle({
        options = { 
        {

            icon = 'fas fa-trash-alt',
            label = 'Toss Trash',
            action = function(entity) 
                TossTrash()
            end,   
            canInteract = function(entity, distance, data)
                if entity == Truck and HasBag then return true end 
                return false
            end,
            }
        },
        distance = 2.5,
    })
    DoingRoute = true
end)

RegisterNetEvent("srp-garbage:client:endRoute", function()
    exports['qb-target']:RemoveGlobalVehicle("Toss Trash")
    HasBag = false
    BagObject = nil
    Truck = nil
    pickupLocation = vector3(0.0, 0.0, 0.0)
    DetachEntity(BagObject, 1, false)
    DeleteObject(BagObject)
    BagObject = nil
    DoingRoute = false
end)

RegisterNetEvent("srp-garbage:client:pickupClean", function()
    DetachEntity(BagObject, 1, false)
    DeleteObject(BagObject)
    BagObject = nil
end)



RegisterNetEvent('srp-garbage:client:takeBag', function()
    local ped = PlayerPedId()
    LoadAnimation('missfbi4prepp1')
    TaskPlayAnim(ped, 'missfbi4prepp1', '_bag_walk_garbage_man', 6.0, -6.0, -1, 49, 0, 0, 0, 0)
    BagObject = CreateObject(`prop_cs_rub_binbag_01`, 0, 0, 0, true, true, true)
    AttachEntityToEntity(BagObject, ped, GetPedBoneIndex(ped, 57005), 0.12, 0.0, -0.05, 220.0, 120.0, 0.0, true, true, false, true, 1, true)
    HasBag = true
    AnimCheck()
end)

-- Functions

function LoadAnimation(dict)
    RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do Wait(10) end
end

function AnimCheck()
    CreateThread(function()
        while HasBag do
            local ped = PlayerPedId()
            if not IsEntityPlayingAnim(ped, 'missfbi4prepp1', '_bag_walk_garbage_man', 3) then
                ClearPedTasksImmediately(ped)
                LoadAnimation('missfbi4prepp1')
                TaskPlayAnim(ped, 'missfbi4prepp1', '_bag_walk_garbage_man', 6.0, -6.0, -1, 49, 0, 0, 0, 0)
            end
            Wait(200)
        end
    end)
end

function DeliverAnim()
    local ped = PlayerPedId()
    LoadAnimation('missfbi4prepp1')
    TaskPlayAnim(ped, 'missfbi4prepp1', '_bag_throw_garbage_man', 8.0, 8.0, 1100, 48, 0.0, 0, 0, 0)
    FreezeEntityPosition(ped, true)
    Wait(1450)

    for _, v in pairs(GetGamePool("CObject")) do
        if IsEntityAttachedToEntity(ped, v) then
        SetEntityAsMissionEntity(v, true, true)
        DeleteObject(v)
        DeleteEntity(v)
        end
    end
    TaskPlayAnim(ped, 'missfbi4prepp1', 'exit', 8.0, 8.0, 1100, 48, 0.0, 0, 0, 0)
    FreezeEntityPosition(ped, false)
    BagObject = nil
end

function TossTrash()
    QBCore.Functions.Progressbar("deliverbag", "Tossing Trash", 2000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function() -- Done
        HasBag = false
        DeliverAnim()
        Wait(1500)
        TriggerServerEvent("srp-garbage:server:updateBags", exports["ps-playergroups"]:GetGroupID())
    end, function() -- Cancel
       
    end)
end

function isDoingGarbage()
    return DoingRoute
end
exports('isDoingGarbage', isDoingGarbage)


RegisterNetEvent("garbage:updatePickup", function(coords)
    pickupLocation = coords

    exports['qb-target']:AddCircleZone("trashcans", vector3(pickupLocation.x, pickupLocation.y-1, pickupLocation.z), 2,{
        name = "trashcans",
        useZ = true,
        debugPoly = false
        }, {
            options = {
                {
                    type = "client",
                    event = "srp-garbage:client:takeBag",
                    icon = "fas fa-sign-in-alt",
                    label = "Get bag of trash",
                },
            },
            distance = 2.5
    })
end)