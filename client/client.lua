Framework = Config.Framework == "esx" and exports['es_extended']:getSharedObject() or exports['qb-core']:GetCoreObject()
SpeedMultiplier = Config.SpeedUnit == "kmh" and 3.6 or 2.23694 -- SPEED MULTIPLIER (MPH - KMN / Don't Touch) --
local PlayerData = {}
local SeatBelt = false
local Cruise = false
local hide = false
local cinematic = false
local Ejected = false
local loggedIn = false
local cs, fs = 0.0, 0.0

CreateThread(function()
    while true do
		Wait(2000)

		if Config.Framework == "esx" then
			PlayerData = Framework.GetPlayerData()
		elseif Config.Framework == "qb" then
			PlayerData = Framework.Functions.GetPlayerData()
		else
			PlayerData = {empty = ""}
		end
        
		if not loggedIn and table_size(PlayerData) > 0 then
			DisplayRadar(true)

			SendNUIMessage({
				action = "useOrNot",
				carHud = Config.UseCarHud,
				statusHud = Config.UseStatusHud,
				playerStats = Config.UsePlayerStats,
				voiceHud = Config.UseVoiceHud,
				speedUnit = Config.SpeedUnit
			})

			SendNUIMessage({
				action = "loggedIn",
				status = true,
			})

			loggedIn = true
		end
	end
end)

------- CAR HUD -------
if Config.UseCarHud then
	CreateThread(function()
		local sleep = 1000

		while true do
			local Player = PlayerPedId()
			if IsPedInAnyVehicle(Player, false) then
				DisplayRadar(1)
				sleep = 200
				local Vehicle = GetVehiclePedIsIn(Player, false)
				local Speed = math.floor(GetEntitySpeed(Vehicle) * SpeedMultiplier)
				local Rpm = math.floor(GetVehicleCurrentRpm(Vehicle) * 100)
				local VehicleHealth = GetVehicleEngineHealth(Vehicle)
				local Fuel

				if Config.UseLegacyFuel then
					Fuel = exports["LegacyFuel"]:GetFuel(Vehicle)
				else
					Fuel = GetVehicleFuelLevel(Vehicle)
				end

				SendNUIMessage({
					action = "VehicleInfo",
					vehicleSpeed = Speed,
					rpm = Rpm,
					vehicleHealth = VehicleHealth,
					fuel = Fuel,
				})

				fs = cs
				cs = GetEntitySpeed(Vehicle)
				local mfwd = GetEntitySpeedVector(Vehicle, true).y > 1.0
				local vhfr = (fs - cs) / GetFrameTime() > 981
	
				if not SeatBelt then
					if mfwd and fs*3.6 > 80 and vhfr then
						Ejected = true
						EjectPlayer()
					else
						Ejected = false
						prevVelocity = GetEntityVelocity(Vehicle)
					end
				end
			else
				SeatBelt = false
				Cruise = false
				DisplayRadar(false)
				sleep = 1000
			end
			
			Wait(sleep)
		end
	end)
end

CreateThread(function()
	SendNUIMessage({
		action = "Display"
	})

	while true do
		local PlayerPosition = GetEntityCoords(PlayerPedId())
		local StreetHash = GetStreetNameAtCoord(PlayerPosition.x, PlayerPosition.y, PlayerPosition.z)
		local Street = GetStreetNameFromHashKey(StreetHash)

		SendNUIMessage({
			action = "StreetUpdate",
			street = Street
		})

		Wait(1000)
	end
end)

if Config.UseStatusHud then
	CreateThread(function()
		local hunger, thirst
		while true do
			if table_size(PlayerData) > 0 then
				local Player = PlayerPedId()
				local health = GetEntityHealth(Player)
				local val = health - 100
				local armour = GetPedArmour(Player)
				local stamina = math.floor(GetPlayerStamina(PlayerId()))
				local oxygen = math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId())) * 10
				local InWater = IsPedSwimmingUnderWater(Player)

				if GetEntityModel(Player) == GetHashKey("mp_f_freemode_01") then
					val = (health + 25) - 100
				end

				if Config.Framework == "esx" then
					TriggerEvent('esx_status:getStatus', 'hunger', function(hunger)
						hunger = math.floor(hunger.getPercent())
						SendNUIMessage({
							action = "HungerUpdate",
							hunger = hunger
						})
					end)
					TriggerEvent('esx_status:getStatus', 'thirst', function(thirst)
						thirst = math.floor(thirst.getPercent())
						SendNUIMessage({
							action = "ThirstUpdate",
							thirst = thirst
						})
					end)
				elseif Config.Framework == "qb" then
					hunger = Framework.Functions.GetPlayerData().metadata["hunger"]
					thirst = Framework.Functions.GetPlayerData().metadata["thirst"]

					SendNUIMessage({
						action = "HungerUpdate",
						hunger = hunger
					})
					SendNUIMessage({
						action = "ThirstUpdate",
						thirst = thirst
					})
				end

				SendNUIMessage({
					action = "StatusUpdate",
					health = val,
					armour = armour,
					stamina = stamina,
					oxygen = oxygen,
					isStandalone = Config.Framework,
					inWater = InWater,
					inCar = IsPedInAnyVehicle(Player, false)
				})
			end

			Wait(1000)
		end
	end)
end

------- STATS (TOP RIGHT) -------
if Config.UsePlayerStats then
	if Config.Framework ~= "standalone" then
		CreateThread(function()
			while true do
				triggerServerCallback("aty_icehud:getPlayerData", function(cb)
					SendNUIMessage({
						action = "StatsUpdate",
						playerId = GetPlayerServerId(PlayerId()),
						playerPing = cb.ping,
						playerCash = cb.cash,
						playerBank = cb.bank
					})
				end)
	
				Wait(1000)
			end
		end)
	else
		local PlayersPing
		
		RegisterNetEvent("aty_icehud:client:GetPlayerPing", function(PlayerPing)
			PlayersPing = PlayerPing
		end)

		CreateThread(function()
			while true do
				local PlayerIDX = GetPlayerServerId(PlayerId()) -- PLAYERS SERVER ID --
				TriggerServerEvent("aty_icehud:server:GetPlayerPing") -- PLAYERS PING --

				SendNUIMessage({
					action = "StatsUpdate",
					playerId = PlayerIDX,
					playerPing = PlayersPing,
				})

				Wait(1000)
			end
		end)
	end
end

------- VOICE HUD -------
if Config.UseVoiceHud then
	local Talking = false

	CreateThread(function()
		local sleep = 1000
		while true do
			if NetworkIsPlayerTalking(PlayerId()) then
				Talking = true
				sleep = 200
			else
				Talking = false
				sleep = 1000
			end
			
			SendNUIMessage({
				action = "talkingState",
				state = Talking
			})

			Wait(sleep)
		end
	end)

	RegisterNetEvent('SaltyChat_VoiceRangeChanged')
	AddEventHandler('SaltyChat_VoiceRangeChanged', function(voiceRange, index, availableVoiceRanges)
		index = index + 1
		if index >= 4 then
			index = 3
		end
		SendNUIMessage({
			action = "voiceMod",
			value = index
		})
	end)

	RegisterNetEvent('pma-voice:setTalkingMode')
	AddEventHandler('pma-voice:setTalkingMode', function(voiceMode)
		SendNUIMessage({
			action = "voiceMod",
			value = voiceMode
		})
	end)

	RegisterNetEvent("mumble:SetVoiceData")
	AddEventHandler("mumble:SetVoiceData", function(player, key, value)
		if GetPlayerServerId(NetworkGetEntityOwner(Player)) == player and key == 'mode' then
			SendNUIMessage({
				action = "voiceMod",
				value = value
			})
		end
	end)
end

if Config.HideCommand then
	RegisterCommand(Config.HideCommand, function(src, args)
		hide = not hide

		if hide then
			SendNUIMessage({
				action = "loggedIn",
				status = false
			})
		else
			SendNUIMessage({
				action = "loggedIn",
				status = true
			})
		end
	end)
end

if Config.CinematicCommand then
	RegisterCommand(Config.CinematicCommand, function(src, args)
		cinematic = not cinematic

		if cinematic then
			SendNUIMessage({
				action = "Hide"
			})

			CreateThread(function()
				while cinematic do
					for i = 0, 1.0, 1.0 do
						DrawRect(0.0, 0.0, 2.0, 0.2, 0, 0, 0, 255)
						DrawRect(0.0, i, 2.0, 0.2, 0, 0, 0, 255)
					end

					Wait(0)
				end
			end)
		elseif not hide then
			SendNUIMessage({
				action = "Display"
			})
		end
	end)
end

RegisterCommand("cruiseControl", function(src, args)
	local ped = PlayerPedId()
	local vehicle = GetVehiclePedIsIn(ped, false)
	local isDriver = GetPedInVehicleSeat(vehicle, -1) == ped
	local carSpeed = GetEntitySpeed(vehicle)

	if isDriver then
		if not Cruise then
			SetVehicleMaxSpeed(vehicle, carSpeed)
			Cruise = true
		else
			Cruise = false
			SetVehicleMaxSpeed(vehicle, 0.0)
		end

		SendNUIMessage({
			action = "cruise",
			status = Cruise,
		})
	end
end)

RegisterCommand("seatbelt", function()
	local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

	if vehicle ~= 0 then
		SeatBelt = not SeatBelt

		SendNUIMessage({
			action = "belt",
			status = SeatBelt
		})
	end
end)

RegisterKeyMapping('cruiseControl', 'Toggle Cruise Control', 'keyboard', Config.CruiseKey)
RegisterKeyMapping('seatbelt', 'Toggle Belt', 'keyboard', Config.SeatBeltKey)

function EjectPlayer()
    if not SeatBelt then 
		local playerPed = PlayerPedId()
        local position = GetEntityCoords(playerPed)
        SetEntityCoords(playerPed, position.x, position.y, position.z - 0.47, true, true, true)
        SetEntityVelocity(playerPed, prevVelocity.x, prevVelocity.y, prevVelocity.z)
        Wait(1)
        SetPedToRagdoll(playerPed, 1000, 1000, 0, 0, 0, 0)
        Wait(1000)
        if math.random(1, 3) == 1 then SetEntityHealth(playerPed, 0) end
    end
end