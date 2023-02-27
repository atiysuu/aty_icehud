local login = false -- PREVENTS HUD FROM VIEWING WITHOUT SELECTING THE PLAYER CHARACTER -- 

if Config.Framework == "esx" then
    ESX = exports['es_extended']:getSharedObject()
elseif Config.Framework == "qb" then
    QBCore = exports['qb-core']:GetCoreObject()
end

if Config.UseCarHud then
    -- EJECTS EACH PLAYER FROM THE CAR --
    RegisterServerEvent('aty_icehud:server:EjectPlayer')
    AddEventHandler('aty_icehud:server:EjectPlayer', function(table, velocity)
    for i=1, #table do
            if table[i] then
                TriggerClientEvent("aty_icehud:client:EjectPlayer", table[i], velocity)
            end
        end
    end)
end

if Config.UsePlayerStats then
    -- GETS PLAYER PING --
    RegisterServerEvent("aty_icehud:server:GetPlayerPing", function()
        local src = source
        local PlayerPing = GetPlayerPing(src)
        TriggerClientEvent("aty_icehud:client:GetPlayerPing", src, PlayerPing)
    end)


    if Config.Framework == "esx" then
        -- GETS PLAYER MONEY FOR ESX --
        RegisterServerEvent("aty_icehud:server:GetPlayerMoney", function()
            local src = source
            local xPlayer = ESX.GetPlayerFromId(src)
            if not xPlayer then return end
            local PlayerBank = xPlayer.getAccount('bank').money
            local PlayerCash = xPlayer.getAccount('money').money
    
            TriggerClientEvent("aty_icehud:client:GetPlayerMoney", src, PlayerCash, PlayerBank)
        end)
    elseif Config.Framework == "qb" then
        -- GETS PLAYER MONEY FOR QBCORE --
        RegisterServerEvent("aty_icehud:server:GetPlayerMoney", function()
            local src = source
            local xPlayer = QBCore.Functions.GetPlayer(src)
            if not xPlayer then return end
            local PlayerBank = xPlayer.PlayerData.money["bank"]
            local PlayerCash = xPlayer.PlayerData.money["cash"]
    
            TriggerClientEvent("aty_icehud:client:GetPlayerMoney", src, PlayerCash, PlayerBank)
        end)
    end
end