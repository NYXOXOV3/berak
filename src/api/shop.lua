-- Shop and merchant functionality
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local utils = require(script.Parent.utils)
local remotes = require(script.Parent.remotes)
local inventory = require(script.Parent.inventory)

local ShopItems = {
    ["Rods"] = {
        {Name = "Luck Rod", ID = 70, Price = 325},
        {Name = "Carbon Rod", ID = 76, Price = 750},
        {Name = "Grass Rod", ID = 85, Price = 1500},
        {Name = "Demascus Rod", ID = 77, Price = 3000},
        {Name = "Ice Rod", ID = 78, Price = 5000},
        {Name = "Lucky Rod", ID = 4, Price = 15000},
        {Name = "Midnight Rod", ID = 80, Price = 50000},
        {Name = "Steampunk Rod", ID = 6, Price = 215000},
        {Name = "Chrome Rod", ID = 7, Price = 437000},
        {Name = "Flourescent Rod", ID = 255, Price = 715000},
        {Name = "Astral Rod", ID = 5, Price = 1000000},
        {Name = "Ares Rod", ID = 126, Price = 3000000},
        {Name = "Angler Rod", ID = 168, Price = 8000000},
        {Name = "Bamboo Rod", ID = 258, Price = 12000000},
    },
    ["Bobbers"] = {
        {Name = "Floral Bait", ID = 20, Price = 4000000},
        {Name = "Aether Bait", ID = 16, Price = 3700000},
        {Name = "Corrupt Bait", ID = 15, Price = 1148484},
        {Name = "Dark Matter Bait", ID = 8, Price = 630000},
        {Name = "Chroma Bait", ID = 6, Price = 290000},
        {Name = "Nature Bait", ID = 17, Price = 83500},
        {Name = "Midnight Bait", ID = 3, Price = 3000},
        {Name = "Luck Bait", ID = 2, Price = 1000},
        {Name = "Topwater Bait", ID = 10, Price = 100},
    },
    ["Boats"] = {
        {Name = "Mini Yach", ID = 14, Price = 1200000},
        {Name = "Fish Boat", ID = 6, Price = 180000},
        {Name = "Speed Boat", ID = 5, Price = 70000},
        {Name = "Highfield Boat", ID = 4, Price = 25000},
        {Name = "Jetski", ID = 3, Price = 7500},
        {Name = "Kayak", ID = 2, Price = 1100},
        {Name = "Small Boat", ID = 1, Price = 100},
    },
}

local MerchantStaticItems = {
    {Name = "Fluorescent Rod", ID = 1, Identifier = "Fluorescent Rod", Price = 685000},
    {Name = "Hazmat Rod", ID = 2, Identifier = "Hazmat Rod", Price = 1380000},
    {Name = "Singularity Bait", ID = 3, Identifier = "Singularity Bait", Price = 8200000},
    {Name = "Royal Bait", ID = 4, Identifier = "Royal Bait", Price = 425000},
    {Name = "Luck Totem", ID = 5, Identifier = "Luck Totem", Price = 650000},
    {Name = "Shiny Totem", ID = 7, Identifier = "Shiny Totem", Price = 400000},
    {Name = "Mutation Totem", ID = 8, Identifier = "Mutation Totem", Price = 800000}
}

function getDropdownOptions(itemType)
    local options = {}
    for _, item in ipairs(ShopItems[itemType]) do
        local formattedPrice = utils.FormatNumber(item.Price)
        table.insert(options, string.format("%s (%s)", item.Name, formattedPrice))
    end
    return options
end

function getItemID(itemType, dropdownValue)
    local itemName = dropdownValue:match("^([^%s]+%s[^%s]+)")
    if not itemName then itemName = dropdownValue:match("^[^%s]+") end
    for _, item in ipairs(ShopItems[itemType]) do
        if item.Name == itemName then return item.ID end
    end
    return nil
end

function handlePurchase(itemType, selectedValue)
    local itemID = getItemID(itemType, selectedValue)
    local remote = remotes.RemoteCache[itemType == "Rods" and "PurchaseFishingRod" or
                                        itemType == "Bobbers" and "PurchaseBait" or
                                        itemType == "Boats" and "PurchaseBoat"]
    if not remote or not itemID then
        return false, "Invalid selection or remote missing"
    end
    
    local success = pcall(function()
        remote:InvokeServer(itemID)
    end)
    
    return success, success and "Purchase attempted" or "Purchase failed"
end

function GetStaticMerchantOptions()
    local options = {}
    for _, item in ipairs(MerchantStaticItems) do
        local formattedPrice = utils.FormatNumber(item.Price)
        table.insert(options, string.format("%s (%s)", item.Name, formattedPrice))
    end
    return options
end

function GetStaticMerchantItemID(dropdownValue)
    for _, item in ipairs(MerchantStaticItems) do
        if dropdownValue:match("^" .. item.Name:gsub("%%", "%%%%") .. " ") then
            return item.ID, item.Name
        end
    end
    return nil, nil
end

function GetMerchantStockDetails(merchantData)
    local itemDetails = {}
    local MarketItemData = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MarketItemData", 0.1)
    
    if merchantData and merchantData.Items and type(merchantData.Items) == "table" and MarketItemData and inventory.ItemUtility then
        for _, itemID in ipairs(merchantData.Items) do
            local marketData = nil
            for _, data in ipairs(MarketItemData) do
                if data.Id == itemID then marketData = data; break end
            end
            
            if marketData and not marketData.SkinCrate and marketData.Price and marketData.Currency then
                local itemDetail = nil
                pcall(function()
                    itemDetail = inventory.ItemUtility:GetItemDataFromItemType(marketData.Type, marketData.Identifier)
                end)
                
                local name = (itemDetail and itemDetail.Data and itemDetail.Data.Name) or marketData.Identifier or "Unknown Item"
                
                table.insert(itemDetails, {
                    Name = name,
                    ID = itemID,
                    Price = marketData.Price,
                    Currency = marketData.Currency,
                })
            end
        end
    end
    return itemDetails
end

function BuyMerchantItem(itemID, itemName)
    local RF_PurchaseMarketItem = remotes.RemoteCache.PurchaseMarketItem
    if not RF_PurchaseMarketItem then
        return false, "Remote Purchase Market Item tidak ditemukan."
    end
    
    local success, result = pcall(function()
        RF_PurchaseMarketItem:InvokeServer(itemID)
    end)
    
    if success then
        return true, "Purchase attempted: " .. itemName
    else
        return false, "Failed: " .. (result or "Unknown Error")
    end
end

return {
    ShopItems = ShopItems,
    MerchantStaticItems = MerchantStaticItems,
    getDropdownOptions = getDropdownOptions,
    getItemID = getItemID,
    handlePurchase = handlePurchase,
    GetStaticMerchantOptions = GetStaticMerchantOptions,
    GetStaticMerchantItemID = GetStaticMerchantItemID,
    GetMerchantStockDetails = GetMerchantStockDetails,
    BuyMerchantItem = BuyMerchantItem
}