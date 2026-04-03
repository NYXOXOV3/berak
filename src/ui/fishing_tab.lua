-- Fishing Tab UI
local init = require(script.Parent.init)
local WindUI = init.WindUI
local fishing = require(script.Parent.api.fishing)
local teleport = require(script.Parent.api.teleport)
local players = require(script.Parent.api.players)
local Reg

return function(Window, registry)
    Reg = registry
    
    local farm = Window:Tab({
        Title = "Fishing",
        Icon = "fish",
        Locked = false,
    })
    
    local legitAutoState = false
    local normalInstantState = false
    local blatantInstantState = false
    local normalLoopThread = nil
    local blatantLoopThread = nil
    local normalEquipThread = nil
    local blatantEquipThread = nil
    local legitEquipThread = nil
    local NormalInstantSlider = nil
    local isTeleportFreezeActive = false
    local freezeToggle = nil
    local selectedArea = nil
    local savedPosition = nil
    local lastTimeFishCaught = nil
    local isCaught = false
    local blatantFishCycleCount = 0
    
    local function GetHRP()
        local Character = game.Players.LocalPlayer.Character
        if not Character then
            Character = game.Players.LocalPlayer.CharacterAdded:Wait()
        end
        return Character:WaitForChild("HumanoidRootPart", 5)
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
    
    local remotes = require(script.Parent.api.remotes)
    
    local function checkFishingRemotes(silent)
        local remotesList = {
            remotes.RemoteCache.equip,
            remotes.RemoteCache.charge,
            remotes.RemoteCache.minigame,
            remotes.RemoteCache.CancelFishingInputs,
            remotes.RemoteCache.FishingCompleted,
            remotes.RemoteCache.UpdateAutoFishingState
        }
        for _, remote in ipairs(remotesList) do
            if not remote then
                if not silent then
                    WindUI:Notify({ Title = "Remote Error!", Content = "Beberapa remote fishing tidak ditemukan.", Duration = 5, Icon = "x" })
                end
                return false
            end
        end
        return true
    end
    
    local function disableOtherModes(currentMode)
        pcall(function()
            local toggleLegit = farm:GetElementByTitle("Auto Fish (Legit)")
            local toggleNormal = farm:GetElementByTitle("Normal Instant Fish")
            local toggleBlatant = farm:GetElementByTitle("Instant Fishing (Blatant)")
            if currentMode ~= "legit" and legitAutoState then
                legitAutoState = false
                if toggleLegit and toggleLegit.Set then toggleLegit:Set(false) end
                if legitClickThread then task.cancel(legitClickThread) legitClickThread = nil end
                if legitEquipThread then task.cancel(legitEquipThread) legitEquipThread = nil end
            end
            if currentMode ~= "normal" and normalInstantState then
                normalInstantState = false
                if toggleNormal and toggleNormal.Set then toggleNormal:Set(false) end
                if normalLoopThread then task.cancel(normalLoopThread) normalLoopThread = nil end
                if normalEquipThread then task.cancel(normalEquipThread) normalEquipThread = nil end
            end
            if currentMode ~= "blatant" and blatantInstantState then
                blatantInstantState = false
                if toggleBlatant and toggleBlatant.Set then toggleBlatant:Set(false) end
                if blatantLoopThread then task.cancel(blatantLoopThread) blatantLoopThread = nil end
                if blatantEquipThread then task.cancel(blatantEquipThread) blatantEquipThread = nil end
            end
        end)
        if currentMode ~= "legit" then
            pcall(function() 
                if remotes.RemoteCache.UpdateAutoFishingState then
                    remotes.RemoteCache.UpdateAutoFishingState:InvokeServer(false) 
                end 
            end)
        end
    end
    
    local FishingController = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers"):WaitForChild("FishingController"))
    local AutoFishingController = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers"):WaitForChild("AutoFishingController"))
    local AutoFishState = { IsActive = false, MinigameActive = false }
    local SPEED_LEGIT = 0.05
    local legitClickThread = nil
    
    local function performClick()
        if FishingController then
            FishingController:RequestFishingMinigameClick()
            task.wait(SPEED_LEGIT)
        end
    end
    
    local originalRodStarted = FishingController.FishingRodStarted
    FishingController.FishingRodStarted = function(self, arg1, arg2)
        originalRodStarted(self, arg1, arg2)
        if AutoFishState.IsActive and not AutoFishState.MinigameActive then
            AutoFishState.MinigameActive = true
            if legitClickThread then task.cancel(legitClickThread) end
            legitClickThread = task.spawn(function()
                while AutoFishState.IsActive and AutoFishState.MinigameActive do
                    performClick()
                end
            end)
        end
    end
    
    local originalFishingStopped = FishingController.FishingStopped
    FishingController.FishingStopped = function(self, arg1)
        originalFishingStopped(self, arg1)
        if AutoFishState.MinigameActive then
            AutoFishState.MinigameActive = false
        end
    end
    
    local function ensureServerAutoFishingOn()
        if remotes.RemoteCache.UpdateAutoFishingState then
            pcall(function() remotes.RemoteCache.UpdateAutoFishingState:InvokeServer(true) end)
        end
    end
    
    local function ToggleAutoClick(shouldActivate)
        if not FishingController then return end
        AutoFishState.IsActive = shouldActivate
        local playerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        local fishingGui = playerGui:FindFirstChild("Fishing") and playerGui.Fishing:FindFirstChild("Main")
        local chargeGui = playerGui:FindFirstChild("Charge") and playerGui.Charge:FindFirstChild("Main")
        if shouldActivate then
            pcall(function() remotes.RemoteCache.equip:FireServer(1) end)
            ensureServerAutoFishingOn()
            if fishingGui then fishingGui.Visible = false end
            if chargeGui then chargeGui.Visible = false end
            WindUI:Notify({ Title = "Auto Fish Legit ON!", Content = "Auto-Equip Protection Active.", Duration = 3, Icon = "check" })
        else
            if legitClickThread then task.cancel(legitClickThread) legitClickThread = nil end
            AutoFishState.MinigameActive = false
            if fishingGui then fishingGui.Visible = true end
            if chargeGui then chargeGui.Visible = true end
            WindUI:Notify({ Title = "Auto Fish Legit OFF!", Duration = 3, Icon = "x" })
        end
    end
    
    local autofish = farm:Section({ Title = "Auto Fishing", TextSize = 20, FontWeight = Enum.FontWeight.SemiBold })
    
    Reg("klikd", autofish:Slider({
        Title = "Legit Click Speed (Delay)",
        Step = 0.01,
        Value = { Min = 0.01, Max = 0.5, Default = SPEED_LEGIT },
        Callback = function(value) SPEED_LEGIT = tonumber(value) or 0.05 end
    }))
    
    Reg("legit", autofish:Toggle({
        Title = "Auto Fish (Legit)",
        Value = false,
        Callback = function(state)
            if not checkFishingRemotes() then return false end
            disableOtherModes("legit")
            legitAutoState = state
            ToggleAutoClick(state)
            if state then
                if legitEquipThread then task.cancel(legitEquipThread) end
                legitEquipThread = task.spawn(function()
                    while legitAutoState do
                        pcall(function() remotes.RemoteCache.equip:FireServer(1) end)
                        task.wait(0.1)
                    end
                end)
            else
                if legitEquipThread then task.cancel(legitEquipThread) legitEquipThread = nil end
            end
        end
    }))
    
    farm:Divider()
    
    local normalCompleteDelay = 1.50
    NormalInstantSlider = Reg("normalslid", autofish:Slider({
        Title = "Normal Complete Delay",
        Step = 0.05,
        Value = { Min = 0.5, Max = 5.0, Default = normalCompleteDelay },
        Callback = function(value) normalCompleteDelay = tonumber(value) or 1.50 end
    }))
    
    local function runNormalInstant()
        if not normalInstantState then return end
        if not checkFishingRemotes(true) then normalInstantState = false return end
        local timestamp = os.time() + os.clock()
        pcall(function() remotes.RemoteCache.charge:InvokeServer(timestamp) end)
        pcall(function() remotes.RemoteCache.minigame:InvokeServer(-139.630452165, 0.99647927980797) end)
        task.wait(normalCompleteDelay)
        pcall(function() remotes.RemoteCache.FishingCompleted:FireServer() end)
        task.wait(0.000000001)
        pcall(function() remotes.RemoteCache.CancelFishingInputs:InvokeServer() end)
    end
    
    Reg("tognorm", autofish:Toggle({
        Title = "Normal Instant Fish",
        Value = false,
        Callback = function(state)
            if not checkFishingRemotes() then return end
            disableOtherModes("normal")
            normalInstantState = state
            if state then
                normalLoopThread = task.spawn(function()
                    while normalInstantState do
                        runNormalInstant()
                        task.wait(0.000000001)
                    end
                end)
                if normalEquipThread then task.cancel(normalEquipThread) end
                normalEquipThread = task.spawn(function()
                    while normalInstantState do
                        pcall(function() remotes.RemoteCache.equip:FireServer(1) end)
                        task.wait(0.000000001)
                    end
                end)
                WindUI:Notify({ Title = "Auto Fish ON", Content = "Auto-Equip Protection Active.", Duration = 3, Icon = "fish" })
            else
                if normalLoopThread then task.cancel(normalLoopThread) normalLoopThread = nil end
                if normalEquipThread then task.cancel(normalEquipThread) normalEquipThread = nil end
                pcall(function() remotes.RemoteCache.equip:FireServer(0) end)
                WindUI:Notify({ Title = "Auto Fish OFF", Duration = 3, Icon = "x" })
            end
        end
    }))
    
    farm:Divider()
    
    local blatant = farm:Section({ Title = "Blatant Mode", TextSize = 20 })
    local completeDelay = 3.055
    local cancelDelay = 0.3
    local loopInterval = 1.715
    _G.PahajiHub_BlatantActive = false
    
    task.spawn(function()
        local S1, FishingController = pcall(function() return require(game:GetService("ReplicatedStorage").Controllers.FishingController) end)
        if S1 and FishingController then
            local Old_Charge = FishingController.RequestChargeFishingRod
            local Old_Cast = FishingController.SendFishingRequestToServer
            FishingController.RequestChargeFishingRod = function(...) if _G.PahajiHub_BlatantActive then return end return Old_Charge(...) end
            FishingController.SendFishingRequestToServer = function(...) if _G.PahajiHub_BlatantActive then return false, "Blocked by PahajiHub" end return Old_Cast(...) end
        end
    end)
    
    local mt = getrawmetatable(game)
    local old_namecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if _G.PahajiHub_BlatantActive and not checkcaller() then
            if method == "InvokeServer" and (self.Name == "RequestFishingMinigameStarted" or self.Name == "ChargeFishingRod" or self.Name == "UpdateAutoFishingState") then return nil end
            if method == "FireServer" and self.Name == "FishingCompleted" then return nil end
        end
        return old_namecall(self, ...)
    end)
    setreadonly(mt, true)
    
    local function SuppressGameVisuals(active)
        local Succ, TextController = pcall(function() return require(game.ReplicatedStorage.Controllers.TextNotificationController) end)
        if Succ and TextController then
            if active then
                if not TextController._OldDeliver then TextController._OldDeliver = TextController.DeliverNotification end
                TextController.DeliverNotification = function(self, data)
                    if data and data.Text and (string.find(tostring(data.Text), "Auto Fishing") or string.find(tostring(data.Text), "Reach Level")) then return end
                    return TextController._OldDeliver(self, data)
                end
            elseif TextController._OldDeliver then
                TextController.DeliverNotification = TextController._OldDeliver
                TextController._OldDeliver = nil
            end
        end
    end
    
    Reg("blatantint", blatant:Input({ Title = "Blatant Interval", Value = tostring(loopInterval), Icon = "fast-forward", Callback = function(input) local newInterval = tonumber(input) if newInterval and newInterval >= 0.5 then loopInterval = newInterval end end }))
    Reg("blatantcom", blatant:Input({ Title = "Complete Delay", Value = tostring(completeDelay), Icon = "loader", Callback = function(input) local newDelay = tonumber(input) if newDelay and newDelay >= 0.5 then completeDelay = newDelay end end }))
    Reg("blatantcanc", blatant:Input({ Title = "Cancel Delay", Value = tostring(cancelDelay), Icon = "clock", Callback = function(input) local newDelay = tonumber(input) if newDelay and newDelay >= 0.1 then cancelDelay = newDelay end end }))
    
    local function runBlatantInstant()
        if not blatantInstantState then return end
        if not checkFishingRemotes(true) then blatantInstantState = false return end
        task.spawn(function()
            local startTime = os.clock()
            local timestamp = os.time() + os.clock()
            pcall(function() remotes.RemoteCache.charge:InvokeServer(timestamp) end)
            task.wait(0.001)
            pcall(function() remotes.RemoteCache.minigame:InvokeServer(-139.6379699707, 0.99647927980797) end)
            local completeWaitTime = completeDelay - (os.clock() - startTime)
            if completeWaitTime > 0 then task.wait(completeWaitTime) end
            pcall(function() remotes.RemoteCache.FishingCompleted:FireServer() end)
            task.wait(cancelDelay)
            pcall(function() remotes.RemoteCache.CancelFishingInputs:InvokeServer() end)
        end)
    end
    
    Reg("blatantt", blatant:Toggle({
        Title = "Instant Fishing (Blatant)",
        Value = false,
        Callback = function(state)
            if not checkFishingRemotes() then return end
            disableOtherModes("blatant")
            blatantInstantState = state
            _G.PahajiHub_BlatantActive = state
            SuppressGameVisuals(state)
            if state then
                if remotes.RemoteCache.UpdateAutoFishingState then 
                    pcall(function() remotes.RemoteCache.UpdateAutoFishingState:InvokeServer(true) end) 
                    task.wait(0.1) 
                    pcall(function() remotes.RemoteCache.UpdateAutoFishingState:InvokeServer(true) end) 
                end
                blatantLoopThread = task.spawn(function() while blatantInstantState do runBlatantInstant() task.wait(loopInterval) end end)
                if blatantEquipThread then task.cancel(blatantEquipThread) end
                blatantEquipThread = task.spawn(function() while blatantInstantState do pcall(function() remotes.RemoteCache.equip:FireServer(1) end) task.wait(0.1) end end)
                WindUI:Notify({ Title = "Blatant Mode ON", Duration = 3, Icon = "zap" })
            else
                if remotes.RemoteCache.UpdateAutoFishingState then pcall(function() remotes.RemoteCache.UpdateAutoFishingState:InvokeServer(false) end) end
                if blatantLoopThread then task.cancel(blatantLoopThread) blatantLoopThread = nil end
                if blatantEquipThread then task.cancel(blatantEquipThread) blatantEquipThread = nil end
                WindUI:Notify({ Title = "Blatant Mode OFF", Duration = 2, Icon = "x" })
            end
        end
    }))
    
    local areafish = farm:Section({ Title = "Fishing Area", TextSize = 20 })
    
    local AreaNames = {}
    for name, _ in pairs(teleport.LOCATIONS) do
        table.insert(AreaNames, name)
    end
    table.sort(AreaNames)
    
    local choosearea = areafish:Dropdown({
        Title = "Choose Area",
        Values = AreaNames,
        AllowNone = true,
        Value = nil,
        Callback = function(option) selectedArea = option end
    })
    
    freezeToggle = areafish:Toggle({
        Title = "Teleport & Freeze at Area (Fix Server Lag)",
        Desc = "Teleport -> Tunggu Sync Server -> Freeze.",
        Value = false,
        Callback = function(state)
            isTeleportFreezeActive = state
            local hrp = GetHRP()
            if not hrp then 
                if freezeToggle and freezeToggle.Set then freezeToggle:Set(false) end 
                return 
            end
            if state then
                if not selectedArea then 
                    WindUI:Notify({ Title = "Aksi Gagal", Content = "Pilih Area dulu di Dropdown!", Duration = 3, Icon = "alert-triangle" }) 
                    if freezeToggle and freezeToggle.Set then freezeToggle:Set(false) end 
                    return 
                end
                local areaData
                if selectedArea == "Custom: Saved" and savedPosition then 
                    areaData = savedPosition 
                else 
                    local cf = teleport.LOCATIONS[selectedArea] 
                    areaData = { Pos = cf.Position, Look = cf.LookVector } 
                end
                if not areaData or not areaData.Pos or not areaData.Look then 
                    WindUI:Notify({ Title = "Aksi Gagal", Content = "Data area tidak valid.", Duration = 3, Icon = "alert-triangle" }) 
                    if freezeToggle and freezeToggle.Set then freezeToggle:Set(false) 
                    return 
                end
                hrp.Anchored = false
                TeleportToLookAt(areaData.Pos, areaData.Look)
                WindUI:Notify({ Title = "Syncing Zone...", Content = "Menahan posisi agar server update...", Duration = 1.5, Icon = "wifi" })
                task.spawn(function()
                    local startTime = os.clock()
                    while (os.clock() - startTime) < 1.5 and isTeleportFreezeActive do
                        if hrp and hrp.Parent then 
                            hrp.Velocity = Vector3.new(0,0,0) 
                            hrp.AssemblyLinearVelocity = Vector3.new(0,0,0) 
                            hrp.CFrame = CFrame.new(areaData.Pos, areaData.Pos + areaData.Look) * CFrame.new(0, 0.5, 0) 
                        end
                        game:GetService("RunService").Heartbeat:Wait()
                    end
                    if isTeleportFreezeActive and hrp and hrp.Parent then 
                        hrp.Anchored = true 
                        WindUI:Notify({ Title = "Ready to Fish", Content = "Posisi dikunci & Zona terupdate.", Duration = 2, Icon = "check" }) 
                    end
                end)
            else
                if hrp then hrp.Anchored = false end
                WindUI:Notify({ Title = "Unfrozen", Content = "Gerakan kembali normal.", Duration = 2, Icon = "unlock" })
            end
        end
    })
    
    local teleto = areafish:Button({
        Title = "Teleport to Chosen Area",
        Icon = "corner-down-right",
        Callback = function()
            if not selectedArea then 
                WindUI:Notify({ Title = "Teleport Gagal", Content = "Pilih Area dulu di Dropdown.", Duration = 3, Icon = "alert-triangle" }) 
                return 
            end
            local areaData
            if selectedArea == "Custom: Saved" and savedPosition then 
                areaData = savedPosition 
            else 
                local cf = teleport.LOCATIONS[selectedArea] 
                areaData = { Pos = cf.Position, Look = cf.LookVector } 
            end
            if isTeleportFreezeActive and freezeToggle then 
                freezeToggle:Set(false) 
                task.wait(0.1) 
            end
            TeleportToLookAt(areaData.Pos, areaData.Look)
        end
    })
    
    farm:Divider()
    
    local savepos = areafish:Button({
        Title = "Save Current Position",
        Icon = "map-pin",
        Callback = function()
            local hrp = GetHRP()
            if hrp then
                savedPosition = { Pos = hrp.Position, Look = hrp.CFrame.LookVector }
                teleport.LOCATIONS["Custom: Saved"] = CFrame.new(savedPosition.Pos, savedPosition.Pos + savedPosition.Look)
                local newValues = {}
                for name, _ in pairs(teleport.LOCATIONS) do table.insert(newValues, name) end
                table.sort(newValues)
                pcall(function() choosearea:Refresh(newValues) end)
                WindUI:Notify({ Title = "Posisi Disimpan!", Content = "Gunakan 'Custom: Saved' di dropdown.", Duration = 3, Icon = "save" })
            else
                WindUI:Notify({ Title = "Gagal Simpan", Duration = 3, Icon = "x" })
            end
        end
    })
    
    local teletosave = areafish:Button({
        Title = "Teleport to SAVED Pos",
        Icon = "navigation",
        Callback = function()
            if not savedPosition then 
                WindUI:Notify({ Title = "Teleport Gagal", Content = "Belum ada posisi yang disimpan.", Duration = 3, Icon = "alert-triangle" }) 
                return 
            end
            if isTeleportFreezeActive and freezeToggle then 
                freezeToggle:Set(false) 
                task.wait(0.1) 
            end
            TeleportToLookAt(savedPosition.Pos, savedPosition.Look)
        end
    })
    
    local UBSection = farm:Section({ Title = "Ultra Blatant 3N", TextSize = 20 })
    
    local function castRod()
        utils.SafeCall(function()
            utils.CallRemoteServer(remotes.RemoteCache.CancelFishingInputs)
            task.wait(0.7)
            utils.CallRemoteServer(remotes.RemoteCache.charge)
            utils.CallRemoteServer(remotes.RemoteCache.minigame, -911.1024780273438, 0.9, os.clock())
        end)
    end
    
    local function equipRod()
        utils.CallRemoteServer(remotes.RemoteCache.equip, 1)
        if fishing.Config.autoFishing or fishing.Config.AutoCatch then
            utils.CallRemoteServer(remotes.RemoteCache.UpdateAutoFishingState, true)
        end
    end
    
    function UB_init()
        local success = true
        fishing.UB_init()
        return success
    end
    
    function UB_start()
        fishing.UB_start()
        WindUI:Notify({ Title = "UB Instant ON", Duration = 3, Icon = "check" })
    end
    
    function UB_stop()
        fishing.UB_stop()
        WindUI:Notify({ Title = "UB Instant OFF", Duration = 3, Icon = "x" })
    end
    
    local function onToggleUB(value)
        if value then
            fishing.Config.HookNotif = true
            equipRod()
            castRod()
            UB_start()
        else
            UB_stop()
            fishing.Config.HookNotif = false
        end
    end
    
    UBSection:Input({
        Title = "Complete Delay",
        Placeholder = "Current: " .. tostring(fishing.Config.UB.Settings.CompleteDelay),
        Icon = "loader",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then fishing.Config.UB.Settings.CompleteDelay = num end
        end
    })
    
    UBSection:Input({
        Title = "Cancel Delay",
        Placeholder = "Current: " .. tostring(fishing.Config.UB.Settings.CancelDelay),
        Icon = "clock",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then fishing.Config.UB.Settings.CancelDelay = num end
        end
    })
    
    UBSection:Input({
        Title = "Notification Duration",
        Placeholder = "Current: " .. tostring(fishing.Config.UB.Settings.NotificationDuration),
        Icon = "bell",
        Callback = function(Value)
            local num = tonumber(Value)
            if num then fishing.Config.UB.Settings.NotificationDuration = num end
        end
    })
    
    UBSection:Toggle({
        Title = "Enable Blatant 3N",
        Value = false,
        Icon = "zap",
        Callback = function(Value)
            if Value then
                onToggleUB(true)
            else
                onToggleUB(false)
            end
        end
    })
    
    UBSection:Toggle({
        Title = "Auto Fishing (Ingame)",
        Value = fishing.Config.autoFishing,
        Icon = "fish",
        Callback = function(Value)
            fishing.Config.autoFishing = Value
            if Value then
                utils.CallRemoteServer(remotes.RemoteCache.UpdateAutoFishingState, true)
                WindUI:Notify({ Title = "Auto Fishing ON", Duration = 3, Icon = "check" })
            else
                WindUI:Notify({ Title = "Auto Fishing OFF", Duration = 3, Icon = "x" })
            end
        end
    })
    
    UB_init()
    
    task.spawn(function()
        while true do
            task.wait(3)
            if not fishing.Config.isFarming or not fishing.Config.isMinig then
                if fishing.Config.UB.Active and lastTimeFishCaught ~= nil and os.clock() - lastTimeFishCaught >= 5 and blatantFishCycleCount > 1 then
                    needCast = true
                    saveCount = 0
                    blatantFishCycleCount = 0
                    lastTimeFishCaught = os.clock()
                    onToggleUB(false)
                    task.wait(0.5)
                    onToggleUB(true)
                end
            end
        end
    end)
end