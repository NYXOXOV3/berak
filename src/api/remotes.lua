-- Remote function getters and caching
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local net = ReplicatedStorage:WaitForChild("Packages", 10):WaitForChild("_Index", 10):WaitForChild("sleitnick_net@0.2.0", 10):WaitForChild("net", 10)

local RemoteCache = {}

function GetServerRemote(targetName)
    local allRemotes = net:GetChildren()
    for i, remote in ipairs(allRemotes) do
        if remote.Name == targetName then
            local actualRemote = allRemotes[i + 1]
            return actualRemote
        end
    end
    return nil
end

function GetServerRemoteReverse(targetName)
    local allRemotes = net:GetChildren()
    for i, remote in ipairs(allRemotes) do
        if remote.Name == targetName then
            local actualRemote = allRemotes[i - 1]
            return actualRemote
        end
    end
    return nil
end

-- Cache frequently used remotes
function CacheRemotes()
    RemoteCache = {
        equip = GetServerRemote("RF/EquipToolFromHotbar"),
        unequip = GetServerRemote("RE/UnequipToolFromHotbar"),
        CancelFishingInputs = GetServerRemote("RF/CancelFishingInputs"),
        charge = GetServerRemote("RF/ChargeFishingRod"),
        minigame = GetServerRemote("RF/RequestFishingMinigameStarted"),
        UpdateAutoFishingState = GetServerRemote("RF/UpdateAutoFishingState"),
        sell = GetServerRemote("RF/SellAllItems"),
        favorite = GetServerRemote("RE/FavoriteItem"),
        fishNotif = GetServerRemote("RE/ObtainedNewFishNotification"),
        systemMessageEvent = GetServerRemote("RE/DisplaySystemMessage"),
        SpawnTotem = GetServerRemote("RE/SpawnTotem"),
        TextNotification = GetServerRemote("RE/TextNotification"),
        UpdateFishingRadar = GetServerRemote("RF/UpdateFishingRadar"),
        EquipOxygenTank = GetServerRemote("RF/EquipOxygenTank"),
        UnequipOxygenTank = GetServerRemote("RF/UnequipOxygenTank"),
        PurchaseBait = GetServerRemote("RF/PurchaseBait"),
        PurchaseFishingRod = GetServerRemote("RF/PurchaseFishingRod"),
        PurchaseBoat = GetServerRemote("RF/PurchaseBoat"),
        PurchaseMarketItem = GetServerRemote("RF/PurchaseMarketItem"),
        PurchaseWeatherEvent = GetServerRemote("RF/PurchaseWeatherEvent"),
        CreateTranscendedStone = GetServerRemote("RF/CreateTranscendedStone"),
        ActivateSecondEnchantingAltar = GetServerRemote("RE/ActivateSecondEnchantingAltar"),
        EquipItem = GetServerRemote("RE/EquipItem"),
        ActivateEnchantingAltar = GetServerRemote("RE/ActivateEnchantingAltar"),
    }
    return RemoteCache
end

return {
    GetServerRemote = GetServerRemote,
    CacheRemotes = CacheRemotes,
    RemoteCache = RemoteCache
}