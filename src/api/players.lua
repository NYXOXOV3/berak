-- Player and character utilities
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function GetHumanoid()
    local character = LocalPlayer.Character
    if not character then
        character = LocalPlayer.CharacterAdded:Wait()
    end
    return character:WaitForChild("Humanoid", 3)
end

function GetHRP()
    local char = LocalPlayer.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

function TeleportToLookAt(position, lookVector, notify)
    local hrp = GetHRP()
    if hrp and typeof(position) == "Vector3" and typeof(lookVector) == "Vector3" then
        local TweenService = game:GetService("TweenService")
        local targetCFrame = CFrame.new(position, position + lookVector) * CFrame.new(0, 0.5, 0)
        local tween = TweenService:Create(hrp, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait()
        return true
    end
    return false
end

function DisableAnimations()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local animateScript = character:FindFirstChild("Animate")
    if animateScript and animateScript:IsA("LocalScript") and animateScript.Enabled then
        animateScript.Enabled = false
    end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        animator:Destroy()
    end
end

function EnableAnimations()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local animateScript = character:FindFirstChild("Animate")
    if animateScript then
        animateScript.Enabled = true
    end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and not humanoid:FindFirstChildOfClass("Animator") then
        Instance.new("Animator").Parent = humanoid
    end
end

function GetPlayerListOptions()
    local options = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(options, player.Name)
        end
    end
    return options
end

function GetTargetHRP(playerName)
    local targetPlayer = game.Players:FindFirstChild(playerName)
    if not targetPlayer then return nil end
    local character = targetPlayer.Character
    if character then
        return character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

return {
    GetHumanoid = GetHumanoid,
    GetHRP = GetHRP,
    TeleportToLookAt = TeleportToLookAt,
    DisableAnimations = DisableAnimations,
    EnableAnimations = EnableAnimations,
    GetPlayerListOptions = GetPlayerListOptions,
    GetTargetHRP = GetTargetHRP
}