if Config.UseCarHud then
    RegisterServerEvent('aty_icehud:server:EjectPlayer')
    AddEventHandler('aty_icehud:server:EjectPlayer', function(table, velocity)
    for i=1, #table do
            if table[i] then
                TriggerClientEvent("aty_icehud:client:EjectPlayer", table[i], velocity)
            end
        end
    end)
end