-- Tools Tab UI (Backpack scanner, utilities, etc.)
local init = require(script.Parent.init)
local WindUI = init.WindUI
local inventory = require(script.Parent.api.inventory)
local players = require(script.Parent.api.players)
local remotes = require(script.Parent.api.remotes)
local utils = require(script.Parent.api.utils)
local Reg

return function(Window, registry)
    Reg = registry
    
    local utility = Window:Tab({
        Title = "Tools",
        Icon = "box",
        Locked = false,
    })
    
    -- Backpack Scanner
    local backpack = utility:Section({ Title = "Backpack Scanner", TextSize = 20 })
    local FishScanDisplay = backpack:Paragraph({
        Title = "Status: Scan untuk melihat detail item...",
        Desc = "Klik tombol 'Scan Backpack' untuk mendapatkan daftar ikan di inventaris Anda.",
        Icon = "clipboard-list"
    })
    
    local function RunBackpackScan()
        local fishData = inventory.ScanInventory()
        local totalCount = fishData.totalCount
        
        if totalCount == 0 then
            FishScanDisplay:SetTitle("Scan Gagal: Inventaris kosong atau error.")
            FishScanDisplay:SetDesc("Pastikan inventory dapat diakses.")
            return
        end
        
        local details = {"\n**--- FISH DETAILS (" .. totalCount .. " items) ---**"}
        
        local rarityOrder = {
            ["COMMON"] = 1, ["UNCOMMON"] = 2, ["RARE"] = 3, ["EPIC"] = 4,
            ["LEGENDARY"] = 5, ["MYTHIC"] = 6, ["SECRET"] = 7,
            ["TROPHY"] = 8, ["COLLECTIBLE"] = 9, ["DEV"] = 10
        }
        
        table.sort(fishData.items, function(a, b)
            local orderA = rarityOrder[a.Rarity:upper()] or 0
            local orderB = rarityOrder[b.Rarity:upper()] or 0
            return orderA > orderB
        end)
        
        for _, item in ipairs(fishData.items) do
            local mutationString = item.Mutation ~= "" and string.format(" [%s]", item.Mutation) or ""
            table.insert(details, string.format("%s %s%s (%s) x%d", item.Favorite, item.Name, mutationString, item.Rarity, item.Count))
        end
        
        FishScanDisplay:SetTitle(string.format("Scan Selesai! Total Ikan: %d", totalCount))
        FishScanDisplay:SetDesc(table.concat(details, "\n"))
        WindUI:Notify({ Title = "Backpack Scanned!", Content = "Lihat detail di UI.", Duration = 3, Icon = "package" })
    end
    
    local scanow = backpack:Button({ Title = "Scan Backpack Now", Icon = "search", Callback = RunBackpackScan })
    
    utility:Divider()
    
    -- Misc utilities
    local misc = utility:Section({ Title = "Misc. Area", TextSize = 20})
    
    local RF_UpdateFishingRadar = remotes.RemoteCache.UpdateFishingRadar
    
    local tfishradar = misc:Toggle({
        Title = "Enable Fishing Radar",
        Desc = "ON/OFF Fishing Radar",
        Value = false,
        Icon = "compass",
        Callback = function(state)
            if not RF_UpdateFishingRadar then
                WindUI:Notify({ Title = "Error", Content = "Remote 'RF/UpdateFishingRadar' tidak ditemukan.", Duration = 3, Icon = "x" })
                return false
            end
            pcall(function() RF_UpdateFishingRadar:InvokeServer(state) end)
            if state then
                WindUI:Notify({ Title = "Fishing Radar ON", Content = "Fishing Radar diaktifkan.", Duration = 3, Icon = "check" })
            else
                WindUI:Notify({ Title = "Fishing Radar OFF", Content = "Fishing Radar dinonaktifkan.", Duration = 3, Icon = "x" })
            end
        end
    })
    
    local RF_EquipOxygenTank = remotes.RemoteCache.EquipOxygenTank
    local RF_UnequipOxygenTank = remotes.RemoteCache.UnequipOxygenTank
    
    local ttank = Reg("infox", misc:Toggle({
        Title = "Equip Oxygen Tank",
        Desc = "infinite oxygen",
        Value = false,
        Icon = "life-buoy",
        Callback = function(state)
            if state then
                if not RF_EquipOxygenTank then
                    WindUI:Notify({ Title = "Error", Duration = 3, Icon = "x" })
                    return false
                end
                pcall(function() RF_EquipOxygenTank:InvokeServer(105) end)
                WindUI:Notify({ Title = "Oxygen Tank Equipped", Duration = 3, Icon = "check" })
            else
                if not RF_UnequipOxygenTank then
                    WindUI:Notify({ Title = "Error", Duration = 3, Icon = "x" })
                    return true
                end
                pcall(function() RF_UnequipOxygenTank:InvokeServer() end)
                WindUI:Notify({ Title = "Oxygen Tank Unequipped", Content = "Oxygen Tank dilepas.", Duration = 3, Icon = "x" })
            end
        end
    }))
    
    local DisableNotificationConnection = nil
    
    local notif = Reg("togglenot", misc:Toggle({
        Title = "Remove Fish Notification Pop-up",
        Value = false,
        Icon = "slash",
        Callback = function(state)
            local PlayerGui = init.LocalPlayer:WaitForChild("PlayerGui")
            local SmallNotification = PlayerGui:FindFirstChild("Small Notification")
            
            if not SmallNotification then
                SmallNotification = PlayerGui:WaitForChild("Small Notification", 5)
                if not SmallNotification then
                    WindUI:Notify({ Title = "Error", Duration = 3, Icon = "x" })
                    return false
                end
            end
            
            if state then
                DisableNotificationConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    SmallNotification.Enabled = false
                end)
                WindUI:Notify({ Title = "Pop-up Diblokir", Duration = 3, Icon = "check" })
            else
                if DisableNotificationConnection then
                    DisableNotificationConnection:Disconnect()
                    DisableNotificationConnection = nil
                end
                SmallNotification.Enabled = true
                WindUI:Notify({ Title = "Pop-up Diaktifkan", Content = "Notifikasi kembali normal.", Duration = 3, Icon = "x" })
            end
        end
    }))
    
    local isNoAnimationActive = false
    local originalAnimateScript = nil
    
    local function DisableAnimations()
        local character = init.LocalPlayer.Character or init.LocalPlayer.CharacterAdded:Wait()
        local animateScript = character:FindFirstChild("Animate")
        if animateScript and animateScript:IsA("LocalScript") and animateScript.Enabled then
            originalAnimateScript = animateScript.Enabled
            animateScript.Enabled = false
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                animator:Destroy()
            end
        end
    end
    
    local function EnableAnimations()
        local character = init.LocalPlayer.Character or init.LocalPlayer.CharacterAdded:Wait()
        local animateScript = character:FindFirstChild("Animate")
        if animateScript then
            animateScript.Enabled = originalAnimateScript or true
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid and not humanoid:FindFirstChildOfClass("Animator") then
            Instance.new("Animator").Parent = humanoid
        end
    end
    
    local function OnCharacterAdded(newCharacter)
        if isNoAnimationActive then
            task.wait(0.2)
            DisableAnimations()
        end
    end
    
    init.LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)
    
    local anim = Reg("Toggleanim", misc:Toggle({
        Title = "No Animation",
        Value = false,
        Icon = "skull",
        Callback = function(state)
            isNoAnimationActive = state
            if state then
                DisableAnimations()
                WindUI:Notify({ Title = "No Animation ON!", Duration = 3, Icon = "zap" })
            else
                EnableAnimations()
                WindUI:Notify({ Title = "No Animation OFF!", Duration = 3, Icon = "x" })
            end
        end
    }))
    
    local VFXControllerModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers").VFXController)
    local originalVFXHandle = VFXControllerModule.Handle
    local isVFXDisabled = false
    
    local tskin = Reg("toggleskin", misc:Toggle({
        Title = "Remove Skin Effect",
        Value = false,
        Icon = "slash",
        Callback = function(state)
            isVFXDisabled = state
            if state then
                VFXControllerModule.Handle = function(...) end
                VFXControllerModule.RenderAtPoint = function(...) end
                VFXControllerModule.RenderInstance = function(...) end
                local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
                if cosmeticFolder then
                    pcall(function() cosmeticFolder:ClearAllChildren() end)
                end
                WindUI:Notify({ Title = "No Skin Effect ON", Duration = 3, Icon = "eye-off" })
            else
                VFXControllerModule.Handle = originalVFXHandle
            end
        end
    }))
    
    local CutsceneController = nil
    local OldPlayCutscene = nil
    local isNoCutsceneActive = false
    
    pcall(function()
        CutsceneController = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers"):WaitForChild("CutsceneController"))
        if CutsceneController and CutsceneController.Play then
            OldPlayCutscene = CutsceneController.Play
            CutsceneController.Play = function(self, ...)
                if isNoCutsceneActive then
                    return 
                end
                return OldPlayCutscene(self, ...)
            end
        end
    end)
    
    local tcutscen = Reg("tnocut", misc:Toggle({
        Title = "No Cutscene",
        Value = false,
        Icon = "film",
        Callback = function(state)
            isNoCutsceneActive = state
            if not CutsceneController then
                WindUI:Notify({ Title = "Gagal Hook", Content = "Module CutsceneController tidak ditemukan.", Duration = 3, Icon = "x" })
                return
            end
            if state then
                WindUI:Notify({ Title = "No Cutscene ON", Content = "Animasi tangkapan dimatikan.", Duration = 3, Icon = "video-off" })
            else
                WindUI:Notify({ Title = "No Cutscene OFF", Content = "Animasi kembali normal.", Duration = 3, Icon = "video" })
            end
        end
    }))
    
    local defaultMaxZoom = init.LocalPlayer.CameraMaxZoomDistance or 128
    local zoomLoopConnection = nil
    
    local tzoom = Reg("infzoom", misc:Toggle({
        Title = "Infinite Zoom Out",
        Value = false,
        Icon = "maximize",
        Callback = function(state)
            if state then
                defaultMaxZoom = init.LocalPlayer.CameraMaxZoomDistance
                init.LocalPlayer.CameraMaxZoomDistance = 100000
                if zoomLoopConnection then zoomLoopConnection:Disconnect() end
                zoomLoopConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    init.LocalPlayer.CameraMaxZoomDistance = 100000
                end)
                WindUI:Notify({ Title = "Zoom Unlocked", Content = "Sekarang bisa zoom out sejauh mungkin.", Duration = 3, Icon = "maximize" })
            else
                if zoomLoopConnection then 
                    zoomLoopConnection:Disconnect() 
                    zoomLoopConnection = nil
                end
                init.LocalPlayer.CameraMaxZoomDistance = defaultMaxZoom
                WindUI:Notify({ Title = "Zoom Normal", Content = "Limit zoom dikembalikan.", Duration = 3, Icon = "minimize" })
            end
        end
    }))
    
    local t3d = Reg("t3drend", misc:Toggle({
        Title = "Disable 3D Rendering",
        Value = false,
        Callback = function(state)
            local PlayerGui = init.LocalPlayer:WaitForChild("PlayerGui")
            local Camera = workspace.CurrentCamera
            
            if state then
                if not _G.BlackScreenGUI then
                    _G.BlackScreenGUI = Instance.new("ScreenGui")
                    _G.BlackScreenGUI.Name = "PahajiHub_BlackBackground"
                    _G.BlackScreenGUI.IgnoreGuiInset = true
                    _G.BlackScreenGUI.DisplayOrder = -999 
                    _G.BlackScreenGUI.Parent = PlayerGui
                    
                    local Frame = Instance.new("Frame")
                    Frame.Size = UDim2.new(1, 0, 1, 0)
                    Frame.BackgroundColor3 = Color3.new(0, 0, 0)
                    Frame.BorderSizePixel = 0
                    Frame.Parent = _G.BlackScreenGUI
                    
                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, 0, 0.1, 0)
                    Label.Position = UDim2.new(0, 0, 0.1, 0)
                    Label.BackgroundTransparency = 1
                    Label.Text = "Saver Mode Active"
                    Label.TextColor3 = Color3.fromRGB(60, 60, 60)
                    Label.TextSize = 16
                    Label.Font = Enum.Font.GothamBold
                    Label.Parent = Frame
                end
                
                _G.BlackScreenGUI.Enabled = true
                _G.OldCamType = Camera.CameraType
                Camera.CameraType = Enum.CameraType.Scriptable
                Camera.CFrame = CFrame.new(0, 100000, 0) 
                
                WindUI:Notify({ Title = "Saver Mode ON", Duration = 3, Icon = "battery-charging" })
            else
                if _G.OldCamType then
                    Camera.CameraType = _G.OldCamType
                else
                    Camera.CameraType = Enum.CameraType.Custom
                end
                
                if init.LocalPlayer.Character and init.LocalPlayer.Character:FindFirstChild("Humanoid") then
                    Camera.CameraSubject = init.LocalPlayer.Character.Humanoid
                end
                
                if _G.BlackScreenGUI then
                    _G.BlackScreenGUI.Enabled = false
                end
                
                WindUI:Notify({ Title = "Saver Mode OFF", Content = "Visual kembali normal.", Duration = 3, Icon = "eye" })
            end
        end
    }))
    
    local isBoostActive = false
    local originalLightingValues = {}
    
    local function ToggleFPSBoost(enabled)
        isBoostActive = enabled
        local Lighting = game:GetService("Lighting")
        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        
        if enabled then
            if not next(originalLightingValues) then
                originalLightingValues.GlobalShadows = Lighting.GlobalShadows
                originalLightingValues.FogEnd = Lighting.FogEnd
                originalLightingValues.Brightness = Lighting.Brightness
                originalLightingValues.ClockTime = Lighting.ClockTime
                originalLightingValues.Ambient = Lighting.Ambient
                originalLightingValues.OutdoorAmbient = Lighting.OutdoorAmbient
            end
            
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Explosion") then
                        v.Enabled = false
                    elseif v:IsA("Beam") or v:IsA("Light") then
                        v.Enabled = false
                    elseif v:IsA("Decal") or v:IsA("Texture") then
                        v.Transparency = 1 
                    end
                end
            end)
            
            pcall(function()
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") then effect.Enabled = false end
                end
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                Lighting.Brightness = 0
                Lighting.ClockTime = 14
                Lighting.Ambient = Color3.new(0, 0, 0)
                Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
            end)
            
            if Terrain then
                pcall(function()
                    Terrain.WaterWaveSize = 0
                    Terrain.WaterWaveSpeed = 0
                    Terrain.WaterReflectance = 0
                    Terrain.WaterTransparency = 1
                    Terrain.Decoration = false
                end)
            end
            
            pcall(function()
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
                settings().Rendering.TextureQuality = Enum.TextureQuality.Low
            end)
            
            if type(setfpscap) == "function" then pcall(function() setfpscap(100) end) end 
            if type(collectgarbage) == "function" then collectgarbage("collect") end
            
            WindUI:Notify({ Title = "FPS Boost", Content = "Maximum FPS mode enabled (Minimal Graphics).", Duration = 3, Icon = "zap" })
        else
            pcall(function()
                if originalLightingValues.GlobalShadows ~= nil then
                    Lighting.GlobalShadows = originalLightingValues.GlobalShadows
                    Lighting.FogEnd = originalLightingValues.FogEnd
                    Lighting.Brightness = originalLightingValues.Brightness
                    Lighting.ClockTime = originalLightingValues.ClockTime
                    Lighting.Ambient = originalLightingValues.Ambient
                    Lighting.OutdoorAmbient = originalLightingValues.OutdoorAmbient
                end
                settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
                
                for _, effect in pairs(Lighting:GetChildren()) do
                    if effect:IsA("PostEffect") then effect.Enabled = true end
                end
            end)
            
            if type(setfpscap) == "function" then pcall(function() setfpscap(60) end) end
            
            WindUI:Notify({ Title = "FPS Boost", Content = "Graphics reset to default/automatic. Rejoin recommended.", Duration = 3, Icon = "rotate-ccw" })
        end
    end
    
    local tfps = Reg("togfps", misc:Toggle({
        Title = "FPS Ultra Boost",
        Value = false,
        Callback = function(state)
            ToggleFPSBoost(state)
        end
    }))
    
    utility:Divider()
    
    -- Server Management
    local serverm = utility:Section({ Title = "Server Management", TextSize = 20})
    
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    
    local brejoin = serverm:Button({
        Title = "Rejoin Server",
        Desc = "Masuk ulang ke server ini (Refresh game).",
        Icon = "rotate-cw",
        Callback = function()
            WindUI:Notify({ Title = "Rejoining...", Content = "Tunggu sebentar...", Duration = 3, Icon = "loader" })
            
            if syn and syn.queue_on_teleport then
                syn.queue_on_teleport('loadstring(game:HttpGet("URL_SCRIPT_KAMU_DISINI"))()')
            elseif queue_on_teleport then
                queue_on_teleport('loadstring(game:HttpGet("URL_SCRIPT_KAMU_DISINI"))()')
            end
            
            if #game.Players:GetPlayers() <= 1 then
                game.Players.LocalPlayer:Kick("\n[PahajiHub] Rejoining...")
                task.wait()
                TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
            end
        end
    })
    
    local bhop = serverm:Button({
        Title = "Server Hop (Random)",
        Desc = "Pindah ke server lain secara acak.",
        Icon = "arrow-right-circle",
        Callback = function()
            WindUI:Notify({ Title = "Hopping...", Content = "Mencari server baru...", Duration = 3, Icon = "search" })
            
            task.spawn(function()
                local PlaceId = game.PlaceId
                local JobId = game.JobId
                
                local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true"
                local req = game:HttpGet(string.format(sfUrl, PlaceId))
                local body = HttpService:JSONDecode(req)
                
                if body and body.data then
                    local servers = {}
                    for _, v in ipairs(body.data) do
                        if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= JobId then
                            table.insert(servers, v.id)
                        end
                    end
                    
                    if #servers > 0 then
                        local randomServerId = servers[math.random(1, #servers)]
                        WindUI:Notify({ Title = "Server Found", Content = "Teleporting...", Duration = 3, Icon = "plane" })
                        TeleportService:TeleportToPlaceInstance(PlaceId, randomServerId, game.Players.LocalPlayer)
                    else
                        WindUI:Notify({ Title = "Gagal Hop", Content = "Tidak menemukan server lain yang cocok.", Duration = 3, Icon = "x" })
                    end
                else
                    WindUI:Notify({ Title = "API Error", Content = "Gagal mengambil daftar server.", Duration = 3, Icon = "alert-triangle" })
                end
            end)
        end
    })
    
    local hoplow = serverm:Button({
        Title = "Server Hop (Low Player)",
        Desc = "Mencari server yang sepi (cocok buat farming).",
        Icon = "user-minus",
        Callback = function()
            WindUI:Notify({ Title = "Searching Low Server...", Content = "Mencari server sepi...", Duration = 3, Icon = "search" })
            
            task.spawn(function()
                local PlaceId = game.PlaceId
                local JobId = game.JobId
                
                local sfUrl = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"
                local req = game:HttpGet(string.format(sfUrl, PlaceId))
                local body = HttpService:JSONDecode(req)
                
                if body and body.data then
                    for _, v in ipairs(body.data) do
                        if type(v) == "table" and v.maxPlayers > v.playing and v.id ~= JobId and v.playing >= 1 then
                            WindUI:Notify({ Title = "Low Server Found!", Content = "Players: " .. tostring(v.playing), Duration = 3, Icon = "check" })
                            TeleportService:TeleportToPlaceInstance(PlaceId, v.id, game.Players.LocalPlayer)
                            return
                        end
                    end
                    WindUI:Notify({ Title = "Gagal", Content = "Tidak ada server sepi ditemukan.", Duration = 3, Icon = "x" })
                else
                    WindUI:Notify({ Title = "API Error", Content = "Gagal mengambil daftar server.", Duration = 3, Icon = "alert-triangle" })
                end
            end)
        end
    })
    
    local copyjobid = serverm:Button({
        Title = "Copy Current Job ID",
        Desc = "Salin ID Server ini ke clipboard.",
        Icon = "copy",
        Callback = function()
            local jobId = game.JobId
            setclipboard(jobId)
            WindUI:Notify({ Title = "Copied!", Content = "Job ID disalin ke clipboard.", Duration = 3, Icon = "check" })
        end
    })
    
    local targetJoinID = ""
    
    local injobid = serverm:Input({
        Title = "Target Job ID",
        Desc = "Paste Job ID server tujuan di sini.",
        Value = "",
        Placeholder = "Paste Job ID here...",
        Icon = "keyboard",
        Callback = function(text)
            targetJoinID = text
        end
    })
    
    local joinid = serverm:Button({
        Title = "Join Server by ID",
        Desc = "Teleport ke Job ID yang dimasukkan di atas.",
        Icon = "log-in",
        Callback = function()
            if targetJoinID == "" then
                WindUI:Notify({ Title = "Error", Content = "Masukkan Job ID dulu di kolom input!", Duration = 3, Icon = "alert-triangle" })
                return
            end
            
            if targetJoinID == game.JobId then
                WindUI:Notify({ Title = "Info", Content = "Kamu sudah berada di server ini!", Duration = 3, Icon = "info" })
                return
            end
            
            WindUI:Notify({ Title = "Joining...", Content = "Mencoba masuk ke server ID...", Duration = 3, Icon = "plane" })
            
            local success, err = pcall(function()
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, targetJoinID, game.Players.LocalPlayer)
            end)
            
            if not success then
                WindUI:Notify({ Title = "Gagal", Content = "ID Server Salah / Server Penuh / Expired.", Duration = 5, Icon = "x" })
            end
        end
    })
end