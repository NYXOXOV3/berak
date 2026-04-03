-- Configuration management (save/load)
local HttpService = game:GetService("HttpService")
local CONFIG_DIR = "ftgshub_configs/"

function EnsureConfigDir()
    if not isfolder(CONFIG_DIR) then
        makefolder(CONFIG_DIR)
    end
end

function SaveConfig(configName, elementRegistry)
    EnsureConfigDir()
    
    if not configName or configName == "" or configName == "None" then
        return false, "Invalid config name"
    end
    
    local safeName = configName:gsub("[^%w_%.%-]", "")
    if safeName == "" then
        safeName = "config_" .. tostring(math.random(1000, 9999))
    end
    
    local targetPath = CONFIG_DIR .. safeName .. ".json"
    local configData = {}
    
    for id, element in pairs(elementRegistry) do
        pcall(function()
            configData[id] = element.Value
        end)
    end
    
    local success, err = pcall(function()
        writefile(targetPath, HttpService:JSONEncode(configData))
    end)
    
    if success then
        return true, targetPath
    else
        return false, err
    end
end

function LoadConfig(configName, elementRegistry)
    EnsureConfigDir()
    
    if not configName or configName == "" or configName == "None" then
        return false, "Invalid config name"
    end
    
    local path = CONFIG_DIR .. configName .. ".json"
    
    if not isfile(path) then
        return false, "File not found: " .. configName
    end
    
    local content = readfile(path)
    local success, decodedData = pcall(function()
        return HttpService:JSONDecode(content)
    end)
    
    if not success or not decodedData then
        return false, "Invalid JSON data"
    end
    
    local realData = decodedData
    if decodedData["__elements"] then
        realData = decodedData["__elements"]
    end
    
    local changeCount = 0
    
    for id, itemData in pairs(realData) do
        local element = elementRegistry[id]
        
        if element then
            local finalValue = itemData
            
            if type(itemData) == "table" and itemData.value ~= nil then
                finalValue = itemData.value
            end
            
            local currentVal = element.Value
            local isDifferent = false
            
            if type(finalValue) == "table" then
                isDifferent = true
            elseif currentVal ~= finalValue then
                isDifferent = true
            end
            
            if isDifferent then
                pcall(function()
                    element:Set(finalValue)
                end)
                changeCount = changeCount + 1
            end
        end
    end
    
    return true, changeCount
end

function DeleteConfig(configName)
    EnsureConfigDir()
    
    if not configName or configName == "" or configName == "None" or configName == "pahajihub" then
        return false, "Cannot delete default or invalid config"
    end
    
    local path = CONFIG_DIR .. configName .. ".json"
    
    if isfile(path) then
        delfile(path)
        return true, "Deleted: " .. configName
    else
        return false, "File not found"
    end
end

function ListConfigs()
    EnsureConfigDir()
    
    local configs = {}
    local success, files = pcall(listfiles, CONFIG_DIR)
    
    if success then
        for _, file in ipairs(files) do
            if string.find(file, "%.json$") then
                local name = string.gsub(string.gsub(file, CONFIG_DIR, ""), "%.json", "")
                table.insert(configs, name)
            end
        end
    end
    
    table.sort(configs)
    return configs
end

return {
    SaveConfig = SaveConfig,
    LoadConfig = LoadConfig,
    DeleteConfig = DeleteConfig,
    ListConfigs = ListConfigs,
    CONFIG_DIR = CONFIG_DIR
}