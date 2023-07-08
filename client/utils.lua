function table_size(tbl)
	local size = 0

	for k, v in pairs(tbl) do
		size = size + 1
	end

	return size
end

function triggerServerCallback(...)
	if Config.Framework == "esx" then
		Framework.TriggerServerCallback(...)
	elseif Config.Framework == "qb" then
		Framework.Functions.TriggerCallback(...)
	end
end