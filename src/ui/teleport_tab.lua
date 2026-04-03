-- Teleport Tab UI
local init = require(script.Parent.init)
local WindUI = init.WindUI
local teleport = require(script.Parent.api.teleport)
local players = require(script.Parent.api.players)
local Reg

return function(Window, registry)
    Reg = registry
    
    local teleportTab = Window:Tab({
        Title = "Teleport",
        Icon = "map-pin",
        Locked = false,
    })
    
    local LocalPlayer = init.LocalPlayer
    local selectedTargetPlayer = nil
    local selectedTargetArea = nil
    local autoEventTargetName = nil
    local autoEventTeleportState = false
    local autoEventTeleportThread = nil
    
    local function GetHRP()
        local char = LocalPlayer.Character
        if not char then return nil end
        return char:FindFirstChild("HumanoidRootPart")
    end
    
    local function TeleportToLookAt(position, lookVector)
        local hrp = GetHRP()
        if hrp and typeof(position) == "Vector3" and typeof(lookVector) == "Vector3" then
            local TweenService = game:GetService("TweenService")
            local targetCFrame = CFrame.new(position, position + lookVector) * CFrame.new(0, 0.5, 0)
            local tween = TweenService:Create(hrp, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
            tween:Play()
            tween.Completed:Wait()
            WindUI:Notify({ Title = "Teleport Sukses!", Duration = 3, Icon = "map-pin" })
        else
            WindUI:Notify({ Title = "Teleport Gagal", Duration = 3, Icon = "x" })
        end
    end
    
    local function GetPlayerListOptions()
        local options = {}
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(options, player.Name)
            end
        end
        return options
    end
    
    local function GetTargetHRP(playerName)
        local targetPlayer = game.Players:FindFirstChild(playerName)
        if not targetPlayer then return nil end
        local character = targetPlayer.Character
        if character then
            return character:FindFirstChild("HumanoidRootPart")
        end
        return nil
    end
    
    local teleplay = teleportTab:Section({
        Title = "Teleport to Player",
        TextSize = 20,
    })
    
    local PlayerDropdown = teleplay:Dropdown({
        Title = "Select Target Player",
        Values = GetPlayerListOptions(),
        AllowNone = true,
        Callback = function(name)
            selectedTargetPlayer = name
        end
    })
    
    local listplaytel = teleplay:Button({
        Title = "Refresh Player List",
        Icon = "refresh-ccw",
        Callback = function()
            local newOptions = GetPlayerListOptions()
            pcall(function() PlayerDropdown:Refresh(newOptions) end)
            task.wait(0.1)
            pcall(function() PlayerDropdown:Set(false) end)
            selectedTargetPlayer = nil
            WindUI:Notify({ Title = "List Diperbarui", Content = string.format("%d pemain ditemukan.", #newOptions), Duration = 2, Icon = "check" })
        end
    })
    
    local teletoplay = teleplay:Button({
        Title = "Teleport to Player (One-Time)",
        Content = "Teleport satu kali ke lokasi pemain yang dipilih.",
        Icon = "corner-down-right",
        Callback = function()
            local hrp = GetHRP()
            local targetHRP = GetTargetHRP(selectedTargetPlayer)
            
            if not selectedTargetPlayer then
                WindUI:Notify({ Title = "Error", Content = "Pilih pemain target terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                return
            end
            
            if hrp and targetHRP then
                local targetPos = targetHRP.Position + Vector3.new(0, 5, 0)
                local targetCFrame = CFrame.new(targetPos, targetHRP.Position)
                local TweenService = game:GetService("TweenService")
                local tween = TweenService:Create(hrp, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
                tween:Play()
                tween.Completed:Wait()
                WindUI:Notify({ Title = "Teleport Sukses", Content = "Teleported ke " .. selectedTargetPlayer, Duration = 3, Icon = "user-check" })
            else
                WindUI:Notify({ Title = "Error", Content = "Gagal menemukan target atau karakter Anda.", Duration = 3, Icon = "x" })
            end
        end
    })
    
    teleportTab:Divider()
    
    local telearea = teleportTab:Section({
        Title = "Teleport to Fishing Area",
        TextSize = 20,
    })
    
    local AreaNames = {}
    for name, _ in pairs(teleport.LOCATIONS) do
        table.insert(AreaNames, name)
    end
    table.sort(AreaNames)
    
    local AreaDropdown = telearea:Dropdown({
        Title = "Select Target Area",
        Values = AreaNames,
        AllowNone = true,
        Callback = function(name)
            selectedTargetArea = name
        end
    })
    
    local butelearea = telearea:Button({
        Title = "Teleport to Area (One-Time)",
        Content = "Teleport satu kali ke area yang dipilih.",
        Icon = "corner-down-right",
        Callback = function()
            if not selectedTargetArea or not teleport.LOCATIONS[selectedTargetArea] then
                WindUI:Notify({ Title = "Error", Content = "Pilih area target terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                return
            end
            local cf = teleport.LOCATIONS[selectedTargetArea]
            TeleportToLookAt(cf.Position, cf.LookVector)
        end
    })
    
    teleportTab:Divider()
    
    local televent = teleportTab:Section({
        Title = "Auto Teleport Event",
        TextSize = 20,
    })
    
    local eventsList = { 
        "Shark Hunt", "Ghost Shark Hunt", "Worm Hunt", "Black Hole", "Shocked", 
        "Ghost Worm", "Meteor Rain", "Megalodon Hunt", "Treasure Event"
    }
    
    local dropvent = televent:Dropdown({
        Title = "Select Target Event",
        Content = "Pilih event yang ingin di-monitor secara otomatis.",
        Values = eventsList,
        AllowNone = true,
        Value = false,
        Callback = function(option)
            autoEventTargetName = option
            if autoEventTeleportState then
                autoEventTeleportState = false
                if autoEventTeleportThread then task.cancel(autoEventTeleportThread) autoEventTeleportThread = nil end
                local toggle = teleportTab:GetElementByTitle("Enable Auto Event Teleport")
                if toggle then toggle:Set(false) end
            end
        end
    })
    
    local tovent = televent:Button({
        Title = "Teleport to Chosen Event (Once)",
        Icon = "corner-down-right",
        Callback = function()
            if not autoEventTargetName then
                WindUI:Notify({ Title = "Error", Content = "Pilih event dulu di dropdown!", Duration = 3, Icon = "alert-triangle" })
                return
            end
            WindUI:Notify({ Title = "Searching...", Content = "Mencari keberadaan event...", Duration = 2, Icon = "search" })
            if autoEventTargetName == "Megalodon Hunt" then
                -- Implement Megalodon teleport logic
                WindUI:Notify({ Title = "Info", Content = autoEventTargetName .. " belum support auto teleport.", Duration = 3, Icon = "info" })
            else
                WindUI:Notify({ Title = "Info", Content = autoEventTargetName .. " belum support auto teleport.", Duration = 3, Icon = "info" })
            end
        end
    })
    
    local function RunAutoEventTeleportLoop()
        if autoEventTeleportThread then task.cancel(autoEventTeleportThread) end
        autoEventTeleportThread = task.spawn(function()
            while autoEventTeleportState do
                if autoEventTargetName == "Megalodon Hunt" then
                    -- Implement Megalodon detection and teleport
                end
                task.wait(8)
            end
        end)
    end
    
    local togventel = televent:Toggle({
        Title = "Enable Auto Event Teleport",
        Content = "Secara otomatis mencari dan teleport ke event yang dipilih.",
        Value = false,
        Callback = function(state)
            if not autoEventTargetName then
                WindUI:Notify({ Title = "Error", Content = "Pilih Event Target terlebih dahulu di dropdown.", Duration = 3, Icon = "alert-triangle" })
                return
            end
            autoEventTeleportState = state
            if state then
                WindUI:Notify({ Title = "Auto Event TP ON", Content = "Mencari " .. autoEventTargetName, Duration = 3, Icon = "check" })
                RunAutoEventTeleportLoop()
            else
                if autoEventTeleportThread then task.cancel(autoEventTeleportThread) autoEventTeleportThread = nil end
                WindUI:Notify({ Title = "Auto Event TP OFF", Duration = 3, Icon = "x" })
            end
        end
    })
end