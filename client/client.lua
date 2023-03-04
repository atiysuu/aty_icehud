local login = false -- PREVENTS HUD FROM VIEWING WITHOUT SELECTING THE PLAYER CHARACTER -- 
SpeedMultiplier = Config.SpeedUnit == "kmh" and 3.6 or 2.23694 -- SPEED MULTIPLIER (MPH - KMN / Don't Touch) --
DisplayRadar(false) -- CLOSES THE MAP --

if Config.Framework == "esx" then
	ESX = exports['es_extended']:getSharedObject()

	RegisterNetEvent('esx:playerLoaded')
	AddEventHandler('esx:playerLoaded', function()
		login = true
	end)
elseif Config.Framework == "qb" then
	QBCore = exports['qb-core']:GetCoreObject()

	RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
	AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
		login = true
	end)
end

CreateThread(function()
	while not login do
		Wait(1000)
		if login and not hide then
			SendNUIMessage({
				action = "Display"
			})
		end
	end
end)

CreateThread(function()
	while true do
		Player = PlayerPedId()
		PlayerPosition = GetEntityCoords(Player)
		Wait(2000)
	end
end)

RegisterCommand("belt", function()
	SeatBelt = not SeatBelt or false
end, false)

RegisterKeyMapping("belt", "Seatbelt", "keyboard", Config.SeatBeltKey)

RegisterCommand("cruise", function()
	local Vehicle = GetVehiclePedIsIn(Player, false)
	if IsPedInAnyVehicle(Player, false) and GetPedInVehicleSeat(Vehicle, -1) == PlayerPedId() then
		local Speed = math.floor(GetEntitySpeed(Vehicle) * SpeedMultiplier)
		SetVehicleMaxSpeed(Vehicle, (Speed / SpeedMultiplier) + 0.0)
		if not Cruise then
			SetVehicleMaxSpeed(Vehicle, 0.0)
		end
		Cruise = not Cruise or false
	end
end, false)

RegisterKeyMapping("cruise", "Cruise Control", "keyboard", Config.CruiseKey) -- Moved to keymapping to be optimized

------- CAR HUD -------
if Config.UseCarHud then
	SeatBelt = false
	Cruise = false
	CreateThread(function()

		local speedBuffer, velBuffer = {
			0.0,
			0.0
		}, {}
		local sleep = 2000

		while true do
			if IsPedInAnyVehicle(Player, false) then
				sleep = 1000
				DisplayRadar(true)

				local Vehicle = GetVehiclePedIsIn(Player, false)
				local Speed = math.floor(GetEntitySpeed(Vehicle) * SpeedMultiplier)
				
				if SeatBelt then
					sleep = 1 -- Needed to disable key
					DisableControlAction(0, 75) -- PREVENTS PLAYER FROM GETTING OUT OF THE CAR --
				elseif not SeatBelt then
					speedBuffer[2] = speedBuffer[1]
					speedBuffer[1] = GetEntitySpeed(Vehicle)

					velBuffer[2] = velBuffer[1]
					velBuffer[1] = GetEntityVelocity(Vehicle)

					-- GETS THE CARS SPEED --
					if speedBuffer[2] and GetEntitySpeedVector(Vehicle, true).y > 1.0 and speedBuffer[1] > 15
						and (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.255) then

						if not SeatBelt then
							local co = GetEntityCoords(Player)
							local fw = ForwardValue(Player)
							SetEntityCoords(Player, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
							SetEntityVelocity(Player, velBuffer[2].x, velBuffer[2].y, velBuffer[2].z)
							Wait(500)
							SetPedToRagdoll(Player, 1000, 1000, 0, 0, 0, 0)
							SeatBelt = false
						end

						-- GETS EACH SEAT FROM CAR --
						local seatPlayerId = {}
						for i = 1, GetVehicleModelNumberOfSeats(GetEntityModel(Vehicle)) do
							if i ~= 1 then
								if not IsVehicleSeatFree(Vehicle, i - 2) then
									local otherPlayerId = GetPedInVehicleSeat(Vehicle, i - 2)
									local playerHandle = NetworkGetPlayerIndexFromPed(otherPlayerId)
									local playerServerId = GetPlayerServerId(playerHandle)
									table.insert(seatPlayerId, playerServerId)
								end
							end
						end

						-- EJECTS EACH PLAYER FROM THE CAR --
						if #seatPlayerId > 0 then
							TriggerServerEvent("aty_icehud:server:EjectPlayer", seatPlayerId, velBuffer[2])
						end
					end
				end
			else
				sleep = 2000
				DisplayRadar(false)
				speedBuffer[1], speedBuffer[2] = 0.0, 0.0
				SeatBelt = false
				Cruise = false

				SendNUIMessage({
					action = "OutSideOfTheCar"
				})
			end
			Wait(sleep)
		end
	end)

	CreateThread(function()

		while true do
			if IsPedInAnyVehicle(Player, false) then
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
					speedUnit = Config.SpeedUnit,
					fuel = Fuel,
					cruise = Cruise,
					seatBelt = SeatBelt
				})

			end

			Wait(150)
		end
	end)

	------- SEATBELT (DON'T TOUCH) -------
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
elseif not Config.UseCarHud then
	CreateThread(function()
		while true do
			if IsPedInAnyVehicle(Player, false) then
				SendNUIMessage({
					action = "NotUseCarHud"
				})
				DisplayRadar(true)
			else
				SendNUIMessage({
					action = "OutSideOfTheCar"
				})
				DisplayRadar(false)
			end

			Wait(1000)
		end
	end)
end

------- STREET LOCATION -------
CreateThread(function()
	SendNUIMessage({
		action = "Display"
	})

	while true do
		local StreetHash = GetStreetNameAtCoord(PlayerPosition.x, PlayerPosition.y, PlayerPosition.z)
		local Street = GetStreetNameFromHashKey(StreetHash)

		SendNUIMessage({
			action = "StreetUpdate",
			street = Street
		})

		Wait(2000)
	end
end)

------- STATUS HUD -------
if Config.UseStatusHud then
	CreateThread(function()
		local hunger, thirst
		while true do
			if login then

				local health = GetEntityHealth(Player)
				local val = health - 100
				local armour = GetPedArmour(Player)
				local stamina = math.floor(GetPlayerStamina(PlayerId()))
				local oxygen = math.floor(GetPlayerUnderwaterTimeRemaining(PlayerId())) * 10
				local InWater = IsPedSwimmingUnderWater(Player)

				------- REDUCES THE HEALTH FOR DEFAULT MALE PED -------
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
					hunger = QBCore.Functions.GetPlayerData().metadata["hunger"]
					thirst = QBCore.Functions.GetPlayerData().metadata["thirst"]
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
					framework = Config.Framework,
					inWater = InWater
				})
			end

			Wait(1000)
		end
	end)
end

------- STATS (TOP RIGHT) -------
if Config.UsePlayerStats then
	local PlayersPing = 0
	local PlayersCash = 0
	local PlayersBank = 0

	RegisterNetEvent("aty_icehud:client:GetPlayerPing", function(PlayerPing)
		PlayersPing = PlayerPing
	end)

	RegisterNetEvent("aty_icehud:client:GetPlayerMoney", function(PlayerCash, PlayerBank)
		PlayersCash = PlayerCash
		PlayersBank = PlayerBank
	end)

	CreateThread(function()
		while true do
			local PlayerIDX = GetPlayerServerId(PlayerId()) -- PLAYERS SERVER ID --
			TriggerServerEvent("aty_icehud:server:GetPlayerPing") -- PLAYERS PING --
			TriggerServerEvent("aty_icehud:server:GetPlayerMoney") -- PLAYERS MONEY --

			SendNUIMessage({
				action = "StatsUpdate",
				playerId = PlayerIDX,
				playerPing = PlayersPing,
				playerCash = PlayersCash,
				playerBank = PlayersBank
			})
			Wait(1000)
		end
	end)
end

------- VOICE HUD -------

if Config.UseVoiceHud then
	CreateThread(function()
		SendNUIMessage({
			action = "UsingVoiceHud"
		})
	end)

	-- CHECKS PLAYER IF ITS TALKING OR NOT --
	local Talking = false
	Citizen.CreateThread(function()
		while true do
			if NetworkIsPlayerTalking(PlayerId()) then
				if not Talking then
					Talking = true
					SendNUIMessage({
						action = "talking"
					})
				end
			else
				if Talking then
					Talking = false
					SendNUIMessage({
						action = "Nottalking"
					})
				end
			end
			Citizen.Wait(200)
		end
	end)

	RegisterNetEvent('SaltyChat_VoiceRangeChanged')
	AddEventHandler('SaltyChat_VoiceRangeChanged', function(voiceRange, index, availableVoiceRanges)
		index = index + 1
		if index >= 4 then
			index = 3
		end
		SendNUIMessage({
			action = "saltyVoice",
			value = index
		})
	end)

	RegisterNetEvent('pma-voice:setTalkingMode')
	AddEventHandler('pma-voice:setTalkingMode', function(voiceMode)
		SendNUIMessage({
			action = "pmavoice",
			value = voiceMode
		})
	end)

	RegisterNetEvent("mumble:SetVoiceData")
	AddEventHandler("mumble:SetVoiceData", function(player, key, value)
		if GetPlayerServerId(NetworkGetEntityOwner(Player)) == player and key == 'mode' then
			SendNUIMessage({
				action = "mumble",
				value = value
			})
		end
	end)
end

local hide = false

if Config.HideCommand and Config.HideCommand ~= '' then
	RegisterCommand(Config.HideCommand, function(src, args)
		hide = not hide

		if hide then
			SendNUIMessage({
				action = "Hide"
			})
		else
			SendNUIMessage({
				action = "Display"
			})
		end
	end)
end

local cinematic = false

if Config.CinematicCommand and Config.CinematicCommand ~= '' then
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

------- FUNCTIONS -------
function ForwardValue(entity)
	local hr = GetEntityHeading(entity) + 90.0
	if hr < 0.0 then
		hr = 360.0 + hr
	end
	hr = hr * 0.0174533
	return {
		x = math.cos(hr) * 2.0,
		y = math.sin(hr) * 2.0
	}
end

function IsCar(veh)
	local vc = GetVehicleClass(veh)
	return (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20)
end
