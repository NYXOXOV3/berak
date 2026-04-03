-- Inventory scanning and management utilities
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemUtility = nil
local TierUtility = nil
local PlayerDataReplion = nil

-- Initialize ItemUtility and TierUtility
local function initUtilities()
    if not ItemUtility then
        local success, util = pcall(function()
            return require(ReplicatedStorage.Shared.ItemUtility)
        end)
        if success then ItemUtility = util end
    end
    
    if not TierUtility then
        local success, util = pcall(function()
            return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TierUtility"))
        end)
        if success then TierUtility = util end
    end
end

-- Get Replion data manager
local function GetPlayerDataReplion()
    if PlayerDataReplion then return PlayerDataReplion end
    
    local ReplionModule = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
    if not ReplionModule then return nil end
    
    local ReplionClient = require(ReplionModule).Client
    PlayerDataReplion = ReplionClient:WaitReplion("Data", 5)
    return PlayerDataReplion
end

-- Get fish name and rarity from item data
function GetFishNameAndRarity(item)
    initUtilities()
    
    local name = item.Identifier or "Unknown"
    local rarity = item.Metadata and item.Metadata.Rarity or "COMMON"
    local itemID = item.Id
    local itemData = nil
    
    if ItemUtility and itemID then
        pcall(function()
            itemData = ItemUtility:GetItemData(itemID)
            if not itemData then
                local numericID = tonumber(item.Id) or tonumber(item.Identifier)
                if numericID then
                    itemData = ItemUtility:GetItemData(numericID)
                end
            end
        end)
    end
    
    if itemData and itemData.Data and itemData.Data.Name then
        name = itemData.Data.Name
    end
    
    if item.Metadata and item.Metadata.Rarity then
        rarity = item.Metadata.Rarity
    elseif itemData and itemData.Probability and itemData.Probability.Chance and TierUtility then
        local tierObj = nil
        pcall(function()
            tierObj = TierUtility:GetTierFromRarity(itemData.Probability.Chance)
        end)
        if tierObj and tierObj.Name then
            rarity = tierObj.Name
        end
    end
    
    return name, rarity
end

-- Get mutation string from item
function GetItemMutationString(item)
    if item.Metadata and item.Metadata.Shiny == true then return "Shiny" end
    return item.Metadata and item.Metadata.VariantId or ""
end

-- Scan entire backpack/inventory
function ScanInventory()
    initUtilities()
    
    local replion = GetPlayerDataReplion()
    if not replion then return { totalCount = 0, items = {} } end
    
    local success, inventoryData = pcall(function()
        return replion:GetExpect("Inventory")
    end)
    
    if not success or not inventoryData or not inventoryData.Items then
        return { totalCount = 0, items = {} }
    end
    
    local fishData = {}
    local totalCount = 0
    
    for _, item in ipairs(inventoryData.Items) do
        if item.Metadata and item.Metadata.Weight then
            local name, rarity = GetFishNameAndRarity(item)
            local mutation = GetItemMutationString(item)
            local count = item.Count or 1
            local favoriteStatus = (item.IsFavorite or item.Favorited) and "⭐" or " "
            local key = name .. rarity .. mutation
            
            if not fishData[key] then
                fishData[key] = {
                    Count = 0,
                    Rarity = rarity,
                    Mutation = mutation,
                    Favorite = favoriteStatus,
                    Name = name,
                    ItemId = item.Id,
                    UUID = item.UUID
                }
            end
            
            fishData[key].Count = fishData[key].Count + count
            totalCount = totalCount + count
        end
    end
    
    -- Convert to sorted array
    local sortedItems = {}
    for _, data in pairs(fishData) do
        table.insert(sortedItems, data)
    end
    
    -- Sort by rarity weight
    local rarityOrder = {
        ["COMMON"] = 1, ["UNCOMMON"] = 2, ["RARE"] = 3, ["EPIC"] = 4,
        ["LEGENDARY"] = 5, ["MYTHIC"] = 6, ["SECRET"] = 7,
        ["TROPHY"] = 8, ["COLLECTIBLE"] = 9, ["DEV"] = 10
    }
    
    table.sort(sortedItems, function(a, b)
        local orderA = rarityOrder[a.Rarity:upper()] or 0
        local orderB = rarityOrder[b.Rarity:upper()] or 0
        return orderA > orderB
    end)
    
    return {
        totalCount = totalCount,
        items = sortedItems
    }
end

-- Get rod options for auto enchant
function GetRodOptions()
    local options = {}
    local replion = GetPlayerDataReplion()
    if not replion then return {"(Gagal memuat Inventory)"} end
    
    local success, inventoryData = pcall(function()
        return replion:GetExpect("Inventory")
    end)
    
    if not success or not inventoryData or not inventoryData["Fishing Rods"] then
        return {"(Tidak ada Rod ditemukan)"}
    end
    
    for _, rod in ipairs(inventoryData["Fishing Rods"]) do
        local rodUUID = rod.UUID
        if typeof(rodUUID) ~= "string" or #rodUUID < 10 then continue end
        
        local rodName, _ = GetFishNameAndRarity(rod)
        if not string.find(rodName, "Rod", 1, true) then continue end
        
        local enchantStatus = ""
        local metadata = rod.Metadata or {}
        local enchants = {}
        if metadata.EnchantId then table.insert(enchants, metadata.EnchantId) end
        
        if #enchants > 0 then
            enchantStatus = " [Enchanted]"
        end
        
        local short = string.sub(rodUUID, 1, 8) .. "..."
        table.insert(options, rodName .. " (" .. short .. ")" .. enchantStatus)
    end
    
    return options
end

-- Get UUID from formatted rod name
function GetUUIDFromFormattedName(formattedName)
    local uuidMatch = formattedName:match("%(([^%)]+)%.%.%.%)")
    if not uuidMatch then return nil end
    
    local replion = GetPlayerDataReplion()
    local Rods = replion:GetExpect("Inventory")["Fishing Rods"] or {}
    
    for _, rod in ipairs(Rods) do
        if string.sub(rod.UUID, 1, 8) == uuidMatch then return rod.UUID end
    end
    return nil
end

-- Get secret fish options for stone creation
function GetSecretFishOptions()
    local options = {}
    local uuidMap = {}
    local replion = GetPlayerDataReplion()
    if not replion then return {}, {} end
    
    local success, inventoryData = pcall(function()
        return replion:GetExpect("Inventory")
    end)
    
    if not success or not inventoryData or not inventoryData.Items then return {}, {} end
    
    for _, item in ipairs(inventoryData.Items) do
        local hasWeight = item.Metadata and item.Metadata.Weight
        local isFishType = item.Type == "Fish" or (item.Identifier and tostring(item.Identifier):lower():find("fish"))
        if not hasWeight and not isFishType then continue end
        
        local _, rarity = GetFishNameAndRarity(item)
        if not rarity or rarity:upper() ~= "SECRET" then continue end
        
        local name = item.Identifier or "Unknown"
        if ItemUtility then
            local itemData = ItemUtility:GetItemData(item.Id)
            if itemData and itemData.Data and itemData.Data.Name then
                name = itemData.Data.Name
            end
        end
        
        if item.Metadata and item.Metadata.Weight then
            name = string.format("%s (%.1fkg)", name, item.Metadata.Weight)
        end
        if item.IsFavorite or item.Favorited then
            name = name .. " [⭐]"
        end
        
        table.insert(options, name)
        uuidMap[name] = item.UUID
    end
    
    table.sort(options)
    return options, uuidMap
end

-- Get items to auto-favorite based on filters
function GetItemsToFavorite(selectedRarities, selectedItemNames, selectedMutations)
    local replion = GetPlayerDataReplion()
    if not replion or not ItemUtility or not TierUtility then return {} end
    
    local success, inventoryData = pcall(function()
        return replion:GetExpect("Inventory")
    end)
    
    if not success or not inventoryData or not inventoryData.Items then return {} end
    
    local itemsToFavorite = {}
    local isRarity = #selectedRarities > 0
    local isName = #selectedItemNames > 0
    local isMutation = #selectedMutations > 0
    if not (isRarity or isName or isMutation) then return {} end
    
    for _, item in ipairs(inventoryData.Items) do
        if item.IsFavorite or item.Favorited then continue end
        local itemUUID = item.UUID
        if typeof(itemUUID) ~= "string" or #itemUUID < 10 then continue end
        
        local name, rarity = GetFishNameAndRarity(item)
        local mutationStr = GetItemMutationString(item)
        
        local match = false
        if isRarity and table.find(selectedRarities, rarity) then match = true end
        if not match and isName and table.find(selectedItemNames, name) then match = true end
        if not match and isMutation and table.find(selectedMutations, mutationStr) then match = true end
        
        if match then table.insert(itemsToFavorite, itemUUID) end
    end
    
    return itemsToFavorite
end

-- Get fish count for auto-sell
function GetFishCount()
    local replion = GetPlayerDataReplion()
    if not replion then return 0 end
    
    local totalFishCount = 0
    local success, inventoryData = pcall(function()
        return replion:GetExpect("Inventory")
    end)
    
    if not success or not inventoryData or not inventoryData.Items or typeof(inventoryData.Items) ~= "table" then
        return 0
    end
    
    for _, item in ipairs(inventoryData.Items) do
        if item.Type == "Fishing Rods" or item.Type == "Boats" or item.Type == "Bait" 
        or item.Type == "Pets" or item.Type == "Chests" or item.Type == "Crates" 
        or item.Type == "Totems" then continue end
        if item.Identifier and (item.Identifier:match("Artifact") or item.Identifier:match("Key") 
        or item.Identifier:match("Token") or item.Identifier:match("Booster") 
        or item.Identifier:match("hourglass")) then continue end
        
        if item.Metadata and item.Metadata.Weight 
        or item.Type == "Fish" 
        or (item.Identifier and item.Identifier:match("fish")) then
            totalFishCount = totalFishCount + (item.Count or 1)
        end
    end
    return totalFishCount
end

return {
    GetFishNameAndRarity = GetFishNameAndRarity,
    GetItemMutationString = GetItemMutationString,
    ScanInventory = ScanInventory,
    GetRodOptions = GetRodOptions,
    GetUUIDFromFormattedName = GetUUIDFromFormattedName,
    GetSecretFishOptions = GetSecretFishOptions,
    GetItemsToFavorite = GetItemsToFavorite,
    GetFishCount = GetFishCount
}