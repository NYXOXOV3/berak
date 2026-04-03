-- Configuration Tab UI
local init = require(script.Parent.init)
local WindUI = init.WindUI
local config_mod = require(script.Parent.api.config)
local Reg

return function(Window, registry)
    Reg = registry
    
    local SettingsTab = Window:Tab({
        Title = "Configuration",
        Icon = "settings",
        Locked = false,
    })
    
    local ConfigSection = SettingsTab:Section({
        Title = "Config Manager",
        TextSize = 20,
    })
    
    local ConfigDir = config_mod.CONFIG_DIR
    if not isfolder(ConfigDir) then makefolder(ConfigDir) end
    
    local function RefreshConfigList(dropdown)
        local list = {"pahajihub"}
        local success, files = pcall(listfiles, ConfigDir)
        if success then
            for _, file in ipairs(files) do
                if string.find(file, "%.json$") then
                    local name = string.gsub(string.gsub(file, ConfigDir, ""), "%.json", "")
                    if name ~= "pahajihub" then 
                        table.insert(list, name) 
                    end
                end
            end
        end
        pcall(function() dropdown:Refresh(list, true) end)
    end
    
    local SelectedConfigName = "pahajihub"
    
    local ConfigNameInput = ConfigSection:Input({
        Title = "Config Name",
        Desc = "Nama config baru/yang akan disimpan.",
        Value = "pahajihub",
        Placeholder = "e.g. LegitFarming",
        Icon = "file-pen",
        Callback = function(text)
            SelectedConfigName = text
        end
    })
    
    local ConfigDropdown = ConfigSection:Dropdown({
        Title = "Available Configs",
        Desc = "Pilih file config yang ada.",
        Values = {"pahajihub"},
        Value = "pahajihub",
        AllowNone = true,
        Callback = function(val)
            if val and val ~= "None" then
                SelectedConfigName = val
                ConfigNameInput:Set(val)
            end
        end
    })
    
    ConfigSection:Button({
        Title = "Refresh List",
        Icon = "refresh-ccw",
        Callback = function() RefreshConfigList(ConfigDropdown) end
    })
    
    ConfigSection:Divider()
    
    ConfigSection:Button({
        Title = "Save Config",
        Desc = "Simpan settingan saat ini.",
        Icon = "save",
        Color = Color3.fromRGB(0, 255, 127),
        Callback = function()
            if SelectedConfigName == "" or SelectedConfigName == "None" then 
                WindUI:Notify({ Title = "Error", Content = "Nama config tidak boleh kosong.", Duration = 3, Icon = "x" })
                return 
            end
            local safeName = SelectedConfigName:gsub("[^%w_%.%-]", "")
            if safeName == "" then safeName = "config_" .. tostring(math.random(1000, 9999)) end
            
            local success, result = config_mod.SaveConfig(safeName, registry)
            if success then
                WindUI:Notify({ Title = "Saved!", Content = "Config: " .. safeName, Duration = 2, Icon = "check" })
                RefreshConfigList(ConfigDropdown)
            else
                WindUI:Notify({ Title = "Error Write", Content = result, Duration = 4, Icon = "x" })
            end
        end
    })
    
    ConfigSection:Button({
        Title = "Load Config",
        Icon = "download",
        Callback = function()
            if SelectedConfigName == "" or SelectedConfigName == "None" then return end
            local success, result = config_mod.LoadConfig(SelectedConfigName, registry)
            if success then
                WindUI:Notify({ Title = "Loaded!", Content = string.format("Updated: %d settings", result), Duration = 2, Icon = "check" })
            else
                WindUI:Notify({ Title = "Error", Content = result, Duration = 3, Icon = "x" })
            end
        end
    })
    
    ConfigSection:Button({
        Title = "Delete Config",
        Icon = "trash-2",
        Color = Color3.fromRGB(255, 80, 80),
        Callback = function()
            if SelectedConfigName == "" or SelectedConfigName == "pahajihub" or SelectedConfigName == "None" then 
                WindUI:Notify({ Title = "Gagal", Content = "Tidak bisa hapus config default/kosong.", Duration = 3 })
                return 
            end
            
            local success, message = config_mod.DeleteConfig(SelectedConfigName)
            if success then
                WindUI:Notify({ Title = "Deleted", Content = SelectedConfigName .. " dihapus.", Duration = 2, Icon = "trash" })
                RefreshConfigList(ConfigDropdown)
                ConfigNameInput:Set("pahajihub")
                SelectedConfigName = "pahajihub"
            else
                WindUI:Notify({ Title = "Error", Content = message, Duration = 3, Icon = "x" })
            end
        end
    })
end