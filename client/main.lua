local hud = false
local speedometer = false
local currentStamina = 100
local staminaRegenRate = 0.3
local staminaDrainRate = 0.5
local minStaminaToSprint = 10
local currentOxygen = 100
local oxygenDrainRate = 0.5
local oxygenRegenRate = 0.3

function GetPlayerSwimming(playerId)
    local player = PlayerPedId()
    local currentOxygenPercent = (currentOxygen / 100) * 100
    
    if IsPedSwimmingUnderWater(player) then
        currentOxygen = math.max(0, currentOxygen - oxygenDrainRate)
        if currentOxygen <= 0 then
            ApplyDamageToPed(player, 1, false)
        end
    else
        currentOxygen = math.min(100, currentOxygen + oxygenRegenRate)
    end
    
    return currentOxygenPercent
end

function GetPlayerStamina(playerId)
    local player = PlayerPedId()
    local currentStaminaPercent = (currentStamina / 100) * 100
    
    if IsPedSprinting(player) and not IsPedSwimming(player) then
        currentStamina = math.max(0, currentStamina - staminaDrainRate)
        if currentStamina <= 0 then
            SetPedMoveRateOverride(player, 0.0)
            DisableControlAction(0, 21, true)
        end
    else
        currentStamina = math.min(100, currentStamina + staminaRegenRate)
        if currentStamina >= minStaminaToSprint then
            SetPedMoveRateOverride(player, 1.0)
            EnableControlAction(0, 21, true)
        end
    end
    
    RestorePlayerStamina(playerId, currentStamina / 100)
    return currentStaminaPercent
end


local last = {
    health = -1,
    armour = -1,
    food = -1,
    water = -1,
    fuel = -1,
    speed = -1,
    stamina = -1,
    swimming = -1,
    pause = false
}

RegisterNUICallback('ready', function(data, cb)
    if data.show then 
        Wait(500)
        SendNUIMessage({
            action = 'show'
        })
        hud = true
    end
end)

if not Config.ESX then
    RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst)
        food = newHunger
        water = newThirst
    end)
end


Citizen.CreateThread(function()
    while true do
        if hud then
            local player = PlayerPedId()
            local health = GetEntityHealth(player) - 100
            local armour = GetPedArmour(player)
            local staminaValue = GetPlayerStamina(PlayerId())
            local swimValue = GetPlayerSwimming(PlayerId())

            local pause = IsPauseMenuActive()
            if pause ~= last.pause then
                SendNUIMessage({action = 'hide', opacity = pause and 0 or 1})
                last.pause = pause
            end

            if Config.ESX then
                TriggerEvent('esx_status:getStatus', 'hunger', function(status) food = status.val / 10000 end)
                TriggerEvent('esx_status:getStatus', 'thirst', function(status) water = status.val / 10000 end)
            end

            if health < 0 then health = 0 end
            if health ~= last.health then SendNUIMessage({action = 'health', health = health}) last.health = health end
            if armour ~= last.armour then SendNUIMessage({action = 'armour', armour = armour}) last.armour = armour end
            if food ~= last.food then SendNUIMessage({action = 'food', food = food}) last.food = food end
            if water ~= last.water then SendNUIMessage({action = 'water', water = water}) last.water = water end
            if staminaValue ~= last.stamina then SendNUIMessage({action = 'stamina', stamina = staminaValue}) last.stamina = staminaValue end
            if swimValue ~= last.swimming then SendNUIMessage({action = 'swimming', swimming = swimValue}) last.swimming = swimValue end
        end
        Wait(50)
    end
end)

Citizen.CreateThread(function()
    while true do
        local wait = 1000
        if hud then
            local player = PlayerPedId()
            if IsPedInAnyVehicle(player) then
                local vehicle = GetVehiclePedIsIn(player)
                if GetPedInVehicleSeat(vehicle, -1) == player then
                    wait = 200
                    if not speedometer then
                        SendNUIMessage({action = 'speedometer', speedometer = 'show', metric = Config.Metric})
                        speedometer = true
                    else
                        local fuel = GetVehicleFuelLevel(vehicle)
                        local speed = GetEntitySpeed(vehicle)
                        if fuel ~= last.fuel then SendNUIMessage({action = 'fuel', fuel = fuel}) last.fuel = fuel end
                        if speed ~= last.speed then SendNUIMessage({action = 'speed', speed = speed}) last.speed = speed end
                    end
                elseif speedometer then
                    SendNUIMessage({action = 'speedometer', speedometer = 'hide', metric = Config.Metric})
                    speedometer = false
                end
            elseif speedometer then
                SendNUIMessage({action = 'speedometer', speedometer = 'hide', metric = Config.Metric})
                speedometer = false
            end
        end
        Wait(wait)
    end
end)

function seatbelt(toggle)
    SendNUIMessage({action = 'seatbelt', seatbelt = toggle})
end

Citizen.CreateThread(function()
    while true do
        local ped = PlayerPedId()
        DisplayRadar(IsPedInAnyVehicle(ped, false))
        Wait(100)
    end
end)

Citizen.CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    SetRadarBigmapEnabled(false, false)
    while true do
        Wait(0)
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
    end
end)
