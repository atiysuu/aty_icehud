CreateThread(function()
    while true do
        Player = PlayerPedId()
        PlayerPosition = GetEntityCoords(Player)
        Wait(1000)
    end
end)

if Config.UseCarHud then
    SpeedMultiplier = Config.SpeedUnit == "kmh" and 3.6 or 2.23694

    CreateThread(function()
        local SeatBelt = false
        local Cruise = false
        local sleep = 1000
        local speedBuffer, velBuffer  = {0.0,0.0}, {}

        while true do
            if IsPedInAnyVehicle(Player, false) then
                DisplayRadar(true)
                sleep = 1
                local Vehicle = GetVehiclePedIsIn(Player, false)
                local Speed = math.floor(GetEntitySpeed(Vehicle)*SpeedMultiplier)
                local Rpm = math.floor(GetVehicleCurrentRpm(Vehicle) * 100)
                local Vehicle = GetVehiclePedIsIn(Player, false)
                local VehicleHealth = GetVehicleEngineHealth(Vehicle)
                local Fuel = GetVehicleFuelLevel(Vehicle)
                
                if IsControlJustPressed(0, Config.CruiseKey) and not Cruise and GetPedInVehicleSeat(Vehicle, -1) == PlayerPedId() then
                    SetVehicleMaxSpeed(Vehicle, (Speed / SpeedMultiplier) + 0.0)
                    Cruise = true
                elseif IsControlJustPressed(0, Config.CruiseKey) and Cruise and GetPedInVehicleSeat(Vehicle, -1) == PlayerPedId() then
                    SetVehicleMaxSpeed(Vehicle, 0.0)
                    Cruise = false
                end
                
                if IsControlJustPressed(0, Config.SeatBeltKey) and not SeatBelt then
                    SeatBelt = true
                elseif IsControlJustPressed(0, Config.SeatBeltKey) and SeatBelt then
                    SeatBelt = false
                end

                if SeatBelt then
                    DisableControlAction(0, 75)
                elseif not SeatBelt then
                    speedBuffer[2] = speedBuffer[1]
                    speedBuffer[1] = GetEntitySpeed(Vehicle) 

                    velBuffer[2] = velBuffer[1]
                    velBuffer[1] = GetEntityVelocity(Vehicle)

                    if speedBuffer[2] and GetEntitySpeedVector(Vehicle, true).y > 1.0  and speedBuffer[1] > 15 and (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.255) then			   
                    
                        if not SeatBelt then
                            local co = GetEntityCoords(Player)
                            local fw = ForwardValue(Player)
                            SetEntityCoords(Player, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
                            SetEntityVelocity(Player, velBuffer[2].x, velBuffer[2].y, velBuffer[2].z)
                            Wait(500)
                            SetPedToRagdoll(Player, 1000, 1000, 0, 0, 0, 0)                    
                            SeatBelt = false
                        end
        
                        local seatPlayerId = {}
                        for i=1, GetVehicleModelNumberOfSeats(GetEntityModel(Vehicle)) do
                            if i ~= 1 then
                                if not IsVehicleSeatFree(Vehicle, i-2) then 
                                    local otherPlayerId = GetPedInVehicleSeat(Vehicle, i-2) 
                                    local playerHandle = NetworkGetPlayerIndexFromPed(otherPlayerId)
                                    local playerServerId = GetPlayerServerId(playerHandle)
                                    table.insert(seatPlayerId, playerServerId)
                                end
                            end
                        end

                        if #seatPlayerId > 0 then TriggerServerEvent("aty_icehud:server:EjectPlayer", seatPlayerId, velBuffer[2]) end
                    end
                end

                SendNUIMessage({
                    action = "VehicleInfo",
                    vehicleSpeed = Speed,
                    cruise = Cruise,
                    rpm = Rpm,
                    seatBelt = SeatBelt,
                    vehicleHealth= VehicleHealth,
                    speedUnit = Config.SpeedUnit,
                    fuel = Fuel,
                })
            else
                DisplayRadar(false)
                speedBuffer[1], speedBuffer[2] = 0.0, 0.0
                SeatBelt = false
                sleep = 1000
                SendNUIMessage({
                    action = "OutSideOfTheCar"
                })
            end
            Wait(sleep)
        end
    end)

    RegisterNetEvent('aty_icehud:client:EjectPlayer')
    AddEventHandler('aty_icehud:client:EjectPlayer', function(velocity)
        if not SeatBelt then
            local co = GetEntityCoords(Player)
            local fw = Fwv(Player)
            SetEntityCoords(Player, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
            SetEntityVelocity(Player, velocity.x, velocity.y, velocity.z)
            Wait(500)
            SetPedToRagdoll(Player, 1000, 1000, 0, 0, 0, 0)       
            SeatBelt = false  
        end
    end)
end

CreateThread(function()
    while true do
        local StreetHash = GetStreetNameAtCoord(PlayerPosition.x, PlayerPosition.y, PlayerPosition.z)
        local Street = GetStreetNameFromHashKey(StreetHash)

        SendNUIMessage({
            action = "StreetUpdate",
            street = Street,
        })
        
        Wait(1000)
    end
end) 

CreateThread(function()
    while true do

        local health = GetEntityHealth(Player)
        local val = health - 100
        local armour = GetPedArmour(Player)
        local stamina = math.floor(GetPlayerStamina(PlayerId()))
        local oxygen = math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId())) * 10
        local InWater = IsPedSwimmingUnderWater(Player)
    
        if GetEntityModel(Player) == `mp_f_freemode_01` then
            val = (health + 25 ) - 100
        end

        SendNUIMessage({
            action = "StatusUpdate",
            health = val,
            armour = armour,
            stamina = stamina,
            oxygen = oxygen,
            inWater = InWater,
        })
        
        Wait(1000)
    end
end) 

function ForwardValue(entity)  
    local hr = GetEntityHeading(entity) + 90.0
    if hr < 0.0 then hr = 360.0 + hr end
    hr = hr * 0.0174533
    return { x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0 }
end

function IsCar(veh)
    local vc = GetVehicleClass(veh)
    return (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20)
end 