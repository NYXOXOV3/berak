-- Teleportation utilities and location data
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local LOCATIONS = {
    ["Fisherman"] = CFrame.new(-18.065, 9.532, 2734.000, -0.113811, 0.000000, -0.993502, -0.000000, 1.000000, 0.000000, 0.993502, 0.000000, -0.113811),
    ["Sisyphus Statue"] = CFrame.new(-3754.441, -135.074, -895.376, 0.943844, 0, -0.330393, 0, 1, 0, 0.330393, 0, 0.943844),
    ["Coral Reefs"] = CFrame.new(-3030.043, 2.509, 2271.429, 0.304264, -0.000000, 0.952588, -0.000000, 1.000000, -0.000000, -0.952588, -0.000000, 0.304264),
    ["Esoteric Depths"] = CFrame.new(3271.979, -1301.530, 1402.762, -0.981542, -0.000000, -0.191249, -0.000000, 1.000000, -0.000000, 0.191249, -0.000000, -0.981542),
    ["Crater Island 1"] = CFrame.new(990.610, 21.142, 5060.255, 0.998865, 0.000000, -0.047632, -0.000000, 1.000000, -0.000000, 0.047632, 0.000000, 0.998865),
    ["Crater Island 2"] = CFrame.new(1040.036, 55.714, 5131.443, 0.551438, -0.000000, 0.834216, 0.000000, 1.000000, -0.000000, -0.834216, 0.000000, 0.551438),
    ["Lost Isle"] = CFrame.new(-3618.15698, 240.836655, -1317.45801),
    ["Weather Machine"] = CFrame.new(-1488.51196, 83.1732635, 1876.30298),
    ["Tropical Grove"] = CFrame.new(-2132.597, 53.488, 3631.235, -0.664326, -0.000000, 0.747443, -0.000000, 1.000000, -0.000000, -0.747443, -0.000000, -0.664326),
    ["Treasure Room"] = CFrame.new(-3630, -279.074, -1599.287, 0.721647, 0, -0.692261, 0, 1, 0, 0.692261, 0, 0.721647),
    ["Kohana"] = CFrame.new(-663.904236, 3.04580712, 718.796875),
    ["Kohana2"] = CFrame.new(-530.529, 8.750, -72.149, -0.910784, 0, -0.412883, 0, 1, 0, 0.412883, 0, -0.910784),
    ["Underground Cellar"] = CFrame.new(2110.109, -91.199, -699.790, 0.744219, -0.000000, -0.667935, -0.000000, 1.000000, -0.000000, 0.667935, 0.000000, 0.744219),
    ["Ancient Jungle"] = CFrame.new(1837.352, 5.894, -297.224, 0.388620, 0.000000, -0.921398, 0.000000, 1.000000, 0.000000, 0.921398, -0.000000, 0.388620),
    ["Ancient Jungle 2"] = CFrame.new(1468.971, 6.512, -326.397, -0.458676, 0.000000, -0.888603, 0.000000, 1.000000, 0.000000, 0.888603, -0.000000, -0.458676),
    ["Sacred Temple"] = CFrame.new(1459.217, -22.375, -637.787, 0.924266, 0, 0.381750, 0, 1, 0, -0.381750, 0, 0.924266),
    ["Ancient Ruins"] = CFrame.new(6097.176, -585.924, 4644.443, -0.514758, 0, 0.857336, 0, 1, 0, -0.857336, 0, -0.514758),
    ["Megalodon"] = CFrame.new(-1172.987, 7.924, 3620.589, 0.706693, 0, 0.707521, 0, 1, 0, -0.707521, 0, 0.706693),
    ["Pirate Cove"] = CFrame.new(3396.730, 4.192, 3469.213) * CFrame.Angles(-0.000, -1.447, -0.000),
    ["Pirate Treasure Room"] = CFrame.new(3324.07397, -306.475647, 3087.99927, 0.999340534, -1.78439805e-08, 0.0363113917, 2.01013268e-08, 1, -6.18013019e-08, -0.0363113917, 6.24904501e-08, 0.999340534),
    ["Secret Passage"] = CFrame.new(3436.101, -289.845, 3382.640, -0.920254, 0.000000, -0.391321, 0.000000, 1.000000, 0.000000, 0.391321, -0.000000, -0.920254),
    ["Kohana Volcano"] = CFrame.new(-549.192, 20.019, 125.802, 0.955081, 0.000000, -0.296344, -0.000000, 1.000000, 0.000000, 0.296344, -0.000000, 0.955081),
    ["Crystal Depth"] = CFrame.new(5752.219, -907.148, 15343.468, -0.628654, 0.000000, 0.777685, -0.000000, 1.000000, -0.000000, -0.777685, -0.000000, -0.628654),
    ["Lava Basin"] = CFrame.new(950.876, 85.282, -10199.427, 0.105691, -0.000000, 0.994399, -0.000000, 1.000000, -0.000000, -0.994399, -0.000000, 0.105691),
    ["Planetary Observatory"] = CFrame.new(420.372925, 3.673104, 2183.674561, -0.219190, 0.000000, -0.975682, 0.000000, 1.000000, 0.000000, 0.975682, -0.000000, -0.219190),
    ["Underwater City"] = CFrame.new(-3142.405518, -643.484253, -10409.403320, 0.120181, -0.000000, -0.992752, -0.000000, 1.000000, -0.000000, 0.992752, 0.000000, 0.120181),
    ["Swers Area"] = CFrame.new(-1445.962, -1041.589, -10469.594),
}

function TeleportToLookAt(position, lookVector)
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp and typeof(position) == "Vector3" and typeof(lookVector) == "Vector3" then
        local targetCFrame = CFrame.new(position, position + lookVector) * CFrame.new(0, 0.5, 0)
        local tween = TweenService:Create(hrp, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait()
        return true
    end
    return false
end

function TeleportToLocation(locationName)
    local cframe = LOCATIONS[locationName]
    if not cframe then return false end
    
    local character = LocalPlayer.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local tween = TweenService:Create(rootPart, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {CFrame = cframe + Vector3.new(0, 3, 0)})
    tween:Play()
    tween.Completed:Wait()
    return true
end

function GetLocationList()
    local list = {}
    for name, _ in pairs(LOCATIONS) do
        table.insert(list, name)
    end
    table.sort(list)
    return list
end

return {
    TeleportToLookAt = TeleportToLookAt,
    TeleportToLocation = TeleportToLocation,
    LOCATIONS = LOCATIONS,
    GetLocationList = GetLocationList
}