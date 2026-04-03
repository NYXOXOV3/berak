-- Player Tab UI
local init = require(script.Parent.init)
local WindUI = init.WindUI
local players = require(script.Parent.api.players)
local Reg

return function(Window, registry)
    Reg = registry
    
    local player = Window:Tab({
        Title = "Player",
        Icon = "user",
        Locked = false,
    })
    
    local movement = player:Section({
        Title = "Movement",
        TextSize = 20,
    })
    
    local SliderSpeed = Reg("Walkspeed", movement:Slider({
        Title = "WalkSpeed",
        Step = 1,
        Value = { Min = 16, Max = 200, Default = 16 },
        Callback = function(value)
            local speedValue = tonumber(value) or 16
            local Humanoid = players.GetHumanoid()
            if Humanoid then
                Humanoid.WalkSpeed = math.clamp(speedValue, 16, 200)
            end
        end,
    }))
    
    local SliderJump = Reg("slidjump", movement:Slider({
        Title = "JumpPower",
        Step = 1,
        Value = { Min = 50, Max = 200, Default = 50 },
        Callback = function(value)
            local jumpValue = tonumber(value) or 50
            local Humanoid = players.GetHumanoid()
            if Humanoid then
                Humanoid.JumpPower = math.clamp(jumpValue, 50, 200)
            end
        end,
    }))
    
    local reset = movement:Button({
        Title = "Reset Movement",
        Icon = "rotate-ccw",
        Locked = false,
        Callback = function()
            local Humanoid = players.GetHumanoid()
            if Humanoid then
                Humanoid.WalkSpeed = 16
                Humanoid.JumpPower = 50
                SliderSpeed:Set(16)
                SliderJump:Set(50)
                WindUI:Notify({
                    Title = "Movement Direset",
                    Content = "WalkSpeed & JumpPower Reset to default",
                    Duration = 3,
                    Icon = "check",
                })
            end
        end
    })
    
    local freezeplr = Reg("frezee", movement:Toggle({
        Title = "Freeze Player",
        Desc = "Membekukan karakter di posisi saat ini (Anti-Push).",
        Value = false,
        Callback = function(state)
            local character = init.LocalPlayer.Character
            if not character then return end
            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Anchored = state
                if state then
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.Velocity = Vector3.new(0, 0, 0)
                    WindUI:Notify({ Title = "Player Frozen", Content = "Posisi dikunci (Anchored).", Duration = 2, Icon = "lock" })
                else
                    WindUI:Notify({ Title = "Player Unfrozen", Content = "Gerakan kembali normal.", Duration = 2, Icon = "unlock" })
                end
            end
        end
    }))
    
    local ability = player:Section({
        Title = "Abilities",
        TextSize = 20,
    })
    
    local infjump = Reg("infj", ability:Toggle({
        Title = "Infinite Jump",
        Value = false,
        Callback = function(state)
            if state then
                WindUI:Notify({ Title = "Infinite Jump ON!", Duration = 3, Icon = "check" })
                _G.InfinityJumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
                    local Humanoid = players.GetHumanoid()
                    if Humanoid and Humanoid.Health > 0 then
                        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            else
                WindUI:Notify({ Title = "Infinite Jump OFF!", Duration = 3, Icon = "check" })
                if _G.InfinityJumpConnection then
                    _G.InfinityJumpConnection:Disconnect()
                    _G.InfinityJumpConnection = nil
                end
            end
        end
    }))
    
    local noclipConnection = nil
    local isNoClipActive = false
    local noclip = Reg("nclip", ability:Toggle({
        Title = "No Clip",
        Value = false,
        Callback = function(state)
            isNoClipActive = state
            local character = init.LocalPlayer.Character
            if not character then character = init.LocalPlayer.CharacterAdded:Wait() end
            if state then
                WindUI:Notify({ Title = "No Clip ON!", Duration = 3, Icon = "check" })
                noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                    if isNoClipActive and character and character.Parent then
                        for _, part in ipairs(character:GetDescendants()) do
                            if part:IsA("BasePart") and part.CanCollide then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            else
                WindUI:Notify({ Title = "No Clip OFF!", Duration = 3, Icon = "x" })
                if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
                if character and character.Parent then
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            end
        end
    }))
    
    local flyConnection = nil
    local isFlying = false
    local flySpeed = 60
    local bodyGyro, bodyVel
    local flytog = Reg("flym", ability:Toggle({
        Title = "Fly Mode",
        Value = false,
        Callback = function(state)
            local character = init.LocalPlayer.Character
            if not character then character = init.LocalPlayer.CharacterAdded:Wait() end
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 2)
            local humanoid = character:WaitForChild("Humanoid", 2)
            if state then
                WindUI:Notify({ Title = "Fly Mode ON!", Duration = 3, Icon = "check" })
                isFlying = true
                bodyGyro = Instance.new("BodyGyro")
                bodyGyro.P = 9e4
                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bodyGyro.CFrame = humanoidRootPart.CFrame
                bodyGyro.Parent = humanoidRootPart
                bodyVel = Instance.new("BodyVelocity")
                bodyVel.Velocity = Vector3.zero
                bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bodyVel.Parent = humanoidRootPart
                local cam = workspace.CurrentCamera
                local jumpPressed = false
                _G.FlyJump = game:GetService("UserInputService").JumpRequest:Connect(function()
                    if isFlying then jumpPressed = true task.delay(0.2, function() jumpPressed = false end) end
                end)
                flyConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    if not isFlying or not humanoidRootPart or not bodyGyro or not bodyVel then return end
                    bodyGyro.CFrame = cam.CFrame
                    local moveDir = humanoid.MoveDirection
                    if jumpPressed then
                        moveDir = moveDir + Vector3.new(0, 1, 0)
                    elseif game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) then
                        moveDir = moveDir - Vector3.new(0, 1, 0)
                    end
                    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * flySpeed end
                    bodyVel.Velocity = moveDir
                end)
            else
                WindUI:Notify({ Title = "Fly Mode OFF!", Duration = 3, Icon = "x" })
                isFlying = false
                if flyConnection then flyConnection:Disconnect() flyConnection = nil end
                if _G.FlyJump then _G.FlyJump:Disconnect() _G.FlyJump = nil end
                if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
                if bodyVel then bodyVel:Destroy() bodyVel = nil end
            end
        end
    }))
    
    local walkOnWaterConnection = nil
    local isWalkOnWater = false
    local waterPlatform = nil
    local walkon = Reg("walkwat", ability:Toggle({
        Title = "Walk on Water",
        Value = false,
        Callback = function(state)
            if state then
                WindUI:Notify({ Title = "Walk on Water ON!", Duration = 3, Icon = "check" })
                isWalkOnWater = true
                if not waterPlatform then
                    waterPlatform = Instance.new("Part")
                    waterPlatform.Name = "WaterPlatform"
                    waterPlatform.Anchored = true
                    waterPlatform.CanCollide = true
                    waterPlatform.Transparency = 1 
                    waterPlatform.Size = Vector3.new(15, 1, 15)
                    waterPlatform.Parent = workspace
                end
                walkOnWaterConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    local character = init.LocalPlayer.Character
                    if not isWalkOnWater or not character then return end
                    local hrp = character:FindFirstChild("HumanoidRootPart")
                    if not hrp then return end
                    if not waterPlatform or not waterPlatform.Parent then
                        waterPlatform = Instance.new("Part")
                        waterPlatform.Name = "WaterPlatform"
                        waterPlatform.Anchored = true
                        waterPlatform.CanCollide = true
                        waterPlatform.Transparency = 1 
                        waterPlatform.Size = Vector3.new(15, 1, 15)
                        waterPlatform.Parent = workspace
                    end
                    local rayParams = RaycastParams.new()
                    rayParams.FilterDescendantsInstances = {workspace.Terrain} 
                    rayParams.FilterType = Enum.RaycastFilterType.Include
                    rayParams.IgnoreWater = false
                    local result = workspace:Raycast(hrp.Position + Vector3.new(0, 5, 0), Vector3.new(0, -500, 0), rayParams)
                    if result and result.Material == Enum.Material.Water then
                        local waterSurfaceHeight = result.Position.Y
                        waterPlatform.Position = Vector3.new(hrp.Position.X, waterSurfaceHeight, hrp.Position.Z)
                        if hrp.Position.Y < (waterSurfaceHeight + 2) and hrp.Position.Y > (waterSurfaceHeight - 5) then
                            if not game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
                                hrp.CFrame = CFrame.new(hrp.Position.X, waterSurfaceHeight + 3.2, hrp.Position.Z)
                            end
                        end
                    else
                        waterPlatform.Position = Vector3.new(hrp.Position.X, -500, hrp.Position.Z)
                    end
                end)
            else
                WindUI:Notify({ Title = "Walk on Water OFF!", Duration = 3, Icon = "x" })
                isWalkOnWater = false
                if walkOnWaterConnection then walkOnWaterConnection:Disconnect() walkOnWaterConnection = nil end
                if waterPlatform then waterPlatform:Destroy() waterPlatform = nil end
            end
        end
    }))
    
    local other = player:Section({
        Title = "Other",
        TextSize = 20,
    })
    
    local isHideActive = false
    local hideConnection = nil
    local customName = ".gg/PahajiHub"
    local customLevel = "Lvl. 969" 
    
    local custname = Reg("cfakennme", other:Input({
        Title = "Custom Fake Name",
        Desc = "Nama samaran yang akan muncul di atas kepala player.",
        Value = customName,
        Placeholder = "Hidden User",
        Icon = "user-x",
        Callback = function(text)
            customName = text
        end
    }))
    
    local custlvl = Reg("cfkelvl", other:Input({
        Title = "Custom Fake Level",
        Desc = "Level samaran (misal: 'Lvl. 100' atau 'Max').",
        Value = customLevel,
        Placeholder = "Lvl. 999",
        Icon = "bar-chart-2",
        Callback = function(text)
            customLevel = text
        end
    }))
    
    local hideusn = Reg("hideallusr", other:Toggle({
        Title = "Hide All Usernames (Streamer Mode)",
        Value = false,
        Callback = function(state)
            isHideActive = state
            pcall(function()
                game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, not state)
            end)
            if state then
                WindUI:Notify({ Title = "Hide Name ON", Content = "Nama & Level disamarkan.", Duration = 3, Icon = "eye-off" })
                if hideConnection then hideConnection:Disconnect() end
                hideConnection = game:GetService("RunService").RenderStepped:Connect(function()
                    for _, plr in ipairs(game.Players:GetPlayers()) do
                        if plr.Character then
                            local hum = plr.Character:FindFirstChild("Humanoid")
                            if hum and hum.DisplayName ~= customName then 
                                hum.DisplayName = customName 
                            end
                            for _, obj in ipairs(plr.Character:GetDescendants()) do
                                if obj:IsA("BillboardGui") then
                                    for _, lbl in ipairs(obj:GetDescendants()) do
                                        if lbl:IsA("TextLabel") or lbl:IsA("TextButton") then
                                            if lbl.Visible then
                                                local txt = lbl.Text
                                                if txt:find(plr.Name) or txt:find(plr.DisplayName) then
                                                    if txt ~= customName then
                                                        lbl.Text = customName
                                                    end
                                                elseif txt:match("%d+") or txt:lower():find("lvl") or txt:lower():find("level") then
                                                    if #txt < 15 and txt ~= customLevel then 
                                                        lbl.Text = customLevel
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            else
                WindUI:Notify({ Title = "Hide Name OFF", Content = "Tampilan dikembalikan.", Duration = 3, Icon = "eye" })
                if hideConnection then hideConnection:Disconnect() hideConnection = nil end
                for _, plr in ipairs(game.Players:GetPlayers()) do
                    if plr.Character then
                        local hum = plr.Character:FindFirstChild("Humanoid")
                        if hum then hum.DisplayName = plr.DisplayName end
                    end
                end
            end
        end
    }))
    
    local STUD_TO_M = 0.28
    local espEnabled = false
    local espConnections = {}
    
    local function removeESP(targetPlayer)
        if not targetPlayer then return end
        local data = espConnections[targetPlayer]
        if data then
            if data.distanceConn then pcall(function() data.distanceConn:Disconnect() end) end
            if data.charAddedConn then pcall(function() data.charAddedConn:Disconnect() end) end
            if data.billboard and data.billboard.Parent then pcall(function() data.billboard:Destroy() end) end
            espConnections[targetPlayer] = nil
        else
            if targetPlayer.Character then
                for _, v in ipairs(targetPlayer.Character:GetChildren()) do
                    if v.Name == "PahajiHubESP" and v:IsA("BillboardGui") then pcall(function() v:Destroy() end) end
                end
            end
        end
    end
    
    local function createESP(targetPlayer)
        if not targetPlayer or not targetPlayer.Character or targetPlayer == init.LocalPlayer then return end
        removeESP(targetPlayer)
        local char = targetPlayer.Character
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
        if not hrp then return end
        local BillboardGui = Instance.new("BillboardGui")
        BillboardGui.Name = "PahajiHubESP"
        BillboardGui.Adornee = hrp
        BillboardGui.Size = UDim2.new(0, 140, 0, 40)
        BillboardGui.AlwaysOnTop = true
        BillboardGui.StudsOffset = Vector3.new(0, 2.6, 0)
        BillboardGui.Parent = char
        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(1, 0, 1, 0)
        Frame.BackgroundTransparency = 1
        Frame.BorderSizePixel = 0
        Frame.Parent = BillboardGui
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Parent = Frame
        NameLabel.Size = UDim2.new(1, 0, 0.6, 0)
        NameLabel.Position = UDim2.new(0, 0, 0, 0)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = tostring(targetPlayer.DisplayName or targetPlayer.Name)
        NameLabel.TextColor3 = Color3.fromRGB(255, 230, 230)
        NameLabel.TextStrokeTransparency = 0.7
        NameLabel.Font = Enum.Font.GothamBold
        NameLabel.TextScaled = true
        local DistanceLabel = Instance.new("TextLabel")
        DistanceLabel.Parent = Frame
        DistanceLabel.Size = UDim2.new(1, 0, 0.4, 0)
        DistanceLabel.Position = UDim2.new(0, 0, 0.6, 0)
        DistanceLabel.BackgroundTransparency = 1
        DistanceLabel.Text = "0.0 m"
        DistanceLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
        DistanceLabel.Font = Enum.Font.GothamSemibold
        DistanceLabel.TextScaled = true
        espConnections[targetPlayer] = { billboard = BillboardGui }
        local distanceConn = game:GetService("RunService").RenderStepped:Connect(function()
            if not espEnabled or not hrp or not hrp.Parent then removeESP(targetPlayer) return end
            local localChar = init.LocalPlayer.Character
            local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")
            if localHRP then
                local distStuds = (localHRP.Position - hrp.Position).Magnitude
                local distMeters = distStuds * STUD_TO_M
                DistanceLabel.Text = string.format("%.1f m", distMeters)
            end
        end)
        espConnections[targetPlayer].distanceConn = distanceConn
        local charAddedConn = targetPlayer.CharacterAdded:Connect(function()
            task.wait(0.8)
            if espEnabled then createESP(targetPlayer) end
        end)
        espConnections[targetPlayer].charAddedConn = charAddedConn
    end
    
    local espplay = Reg("esp", other:Toggle({
        Title = "Player ESP",
        Value = false,
        Callback = function(state)
            espEnabled = state
            if state then
                WindUI:Notify({ Title = "ESP Aktif", Duration = 3, Icon = "eye" })
                for _, plr in ipairs(game.Players:GetPlayers()) do
                    if plr ~= init.LocalPlayer then createESP(plr) end
                end
                espConnections["playerAddedConn"] = game.Players.PlayerAdded:Connect(function(plr)
                    task.wait(1)
                    if espEnabled then createESP(plr) end
                end)
                espConnections["playerRemovingConn"] = game.Players.PlayerRemoving:Connect(function(plr)
                    removeESP(plr)
                end)
            else
                WindUI:Notify({ Title = "ESP Nonaktif", Content = "Semua marker ESP dihapus.", Duration = 3, Icon = "eye-off" })
                for plr, _ in pairs(espConnections) do
                    if plr and typeof(plr) == "Instance" then removeESP(plr) end
                end
                if espConnections["playerAddedConn"] then espConnections["playerAddedConn"]:Disconnect() end
                if espConnections["playerRemovingConn"] then espConnections["playerRemovingConn"]:Disconnect() end
                espConnections = {}
            end
        end
    }))
    
    local respawnin = other:Button({
        Title = "Reset Character (In Place)",
        Icon = "refresh-cw",
        Callback = function()
            local character = init.LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not character or not hrp or not humanoid then
                WindUI:Notify({ Title = "Gagal Reset", Content = "Karakter tidak ditemukan!", Duration = 3, Icon = "x" })
                return
            end
            local lastPos = hrp.Position
            WindUI:Notify({ Title = "Reset Character...", Content = "Respawning di posisi yang sama...", Duration = 2, Icon = "rotate-cw" })
            humanoid:TakeDamage(999999)
            init.LocalPlayer.CharacterAdded:Wait()
            task.wait(0.5)
            local newChar = init.LocalPlayer.Character
            local newHRP = newChar:WaitForChild("HumanoidRootPart", 5)
            if newHRP then
                newHRP.CFrame = CFrame.new(lastPos + Vector3.new(0, 3, 0))
                WindUI:Notify({ Title = "Character Reset Sukses!", Content = "Kamu direspawn di posisi yang sama ✅", Duration = 3, Icon = "check" })
            else
                WindUI:Notify({ Title = "Gagal Reset", Content = "HumanoidRootPart baru tidak ditemukan.", Duration = 3, Icon = "x" })
            end
        end
    })
end