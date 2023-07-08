Framework = Config.Framework == "esx" and exports['es_extended']:getSharedObject() or exports['qb-core']:GetCoreObject()

function registerServerCallback(...)
	if Config.Framework == "qb" then
		Framework.Functions.CreateCallback(...)
    elseif Config.Framework == "esx" then
		Framework.RegisterServerCallback(...)
	end
end

if Config.UsePlayerStats then
    if Config.Framework ~= "standalone" then
        registerServerCallback("aty_icehud:getPlayerData", function(src, cb)
            local ping = GetPlayerPing(src)
            local cash
            local bank
    
            if Config.Framework == "esx" then
                local xPlayer = Framework.GetPlayerFromId(src)
                cash = xPlayer.getAccount('bank').money
                bank = xPlayer.getAccount('money').money
            elseif Config.Framework == "qb" then
                local xPlayer = Framework.Functions.GetPlayer(src)
                cash = xPlayer.PlayerData.money["bank"]
                bank = xPlayer.PlayerData.money["cash"]
            end
    
            cb({
                cash = cash,
                bank = bank,
                ping = ping
            })
        end)
    else
        RegisterServerEvent("aty_icehud:server:GetPlayerPing", function()
            local src = source
            local PlayerPing = GetPlayerPing(src)
            TriggerClientEvent("aty_icehud:client:GetPlayerPing", src, PlayerPing)
        end)
    end
end