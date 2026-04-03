-- Shop Tab UI
local init = require(script.Parent.init)
local WindUI = init.WindUI
local shop = require(script.Parent.api.shop)
local teleport = require(script.Parent.api.teleport)
local remotes = require(script.Parent.api.remotes)
local Reg

return function(Window, registry)
    Reg = registry
    
    local shopTab = Window:Tab({
        Title = "Shop",
        Icon = "shopping-bag",
        Locked = false,
    })
    
    local MerchantButtons = {}
    
    local MerchantReplion = nil
    local UpdateCleanupFunction = nil
    local MainDisplayElement = nil
    local UpdateThread = nil
    
    local selectedStaticItemName = nil
    local autoBuySelectedState = false
    local autoBuyStockState = false
    local autoBuyThread = nil
    
    local function FormatNumber(n)
        if n >= 1000000000 then return string.format("%.1fB", n / 1000000000)
        elseif n >= 1000000 then return string.format("%.1fM", n / 1000000)
        elseif n >= 1000 then return string.format("%.1fK", n / 1000)
        else return tostring(n) end
    end
    
    local ShopItems = shop.ShopItems
    local MerchantStaticItems = shop.MerchantStaticItems
    
    local RF_PurchaseBait = remotes.RemoteCache.PurchaseBait
    local RF_PurchaseFishingRod = remotes.RemoteCache.PurchaseFishingRod
    local RF_PurchaseBoat = remotes.RemoteCache.PurchaseBoat
    local RF_PurchaseMarketItem = remotes.RemoteCache.PurchaseMarketItem
    local RF_PurchaseWeatherEvent = remotes.RemoteCache.PurchaseWeatherEvent
    
    local ShopRemotes = {
        ["Rods"] = RF_PurchaseFishingRod,
        ["Bobbers"] = RF_PurchaseBait,
        ["Boats"] = RF_PurchaseBoat,
    }
    
    local function GetStaticMerchantOptions()
        return shop.GetStaticMerchantOptions()
    end
    
    local function GetStaticMerchantItemID(dropdownValue)
        return shop.GetStaticMerchantItemID(dropdownValue)
    end
    
    local function getDropdownOptions(itemType)
        return shop.getDropdownOptions(itemType)
    end
    
    local function getItemID(itemType, dropdownValue)
        return shop.getItemID(itemType, dropdownValue)
    end
    
    local function handlePurchase(itemType, selectedValue)
        local success, message = shop.handlePurchase(itemType, selectedValue)
        if success then
            WindUI:Notify({ Title = "Purchase Attempted!", Duration = 3, Icon = "check" })
        else
            WindUI:Notify({ Title = "Purchase Error", Duration = 4, Icon = "x" })
        end
    end
    
    local function ClearOldMerchantButtons()
        for _, btn in ipairs(MerchantButtons) do
            if btn and type(btn) == "table" and btn.Destroy then
                pcall(function()
                    btn:Destroy()
                end)
            end
        end
        MerchantButtons = {}
    end
    
    local function CreateStockListString(itemDetails)
        local list = {"--- CURRENT STOCK ---"}
        if #itemDetails == 0 then
            table.insert(list, "Stok Item unik kosong saat ini.")
            return table.concat(list, "\n")
        end
        
        for _, item in ipairs(itemDetails) do
            local formattedPrice = FormatNumber(item.Price)
            local currency = item.Currency or "Coins"
            table.insert(list, string.format(" • %s: %s %s", item.Name, formattedPrice, currency))
        end
        
        return table.concat(list, "\n")
    end
    
    local function RedrawMerchantButtons(itemDetails)
        ClearOldMerchantButtons()
        
        if #itemDetails > 0 then
            for _, item in ipairs(itemDetails) do
                local formattedPrice = FormatNumber(item.Price)
                local currency = item.Currency or "Coins"
                
                local newButton = shopTab:Button({
                    Title = string.format("BUY: %s", item.Name),
                    Desc = string.format("Price: %s %s", formattedPrice, currency),
                    Icon = "shopping-cart",
                    Callback = function()
                        local success, message = shop.BuyMerchantItem(item.ID, item.Name)
                        if success then
                            WindUI:Notify({ Title = "Purchase Attempted!", Content = "Mencoba membeli: " .. item.Name, Duration = 1.5, Icon = "check" })
                        else
                            WindUI:Notify({ Title = "Purchase Failed", Content = message, Duration = 2, Icon = "x" })
                        end
                    end
                })
                table.insert(MerchantButtons, newButton)
            end
        else
            local noStockIndicator = shopTab:Paragraph({
                Title = "No Buyable Items",
                Desc = "Tidak ada tombol yang tersedia.",
                Icon = "info",
            })
            table.insert(MerchantButtons, noStockIndicator)
        end
    end
    
    local function GetReplions()
        if MerchantReplion then return true end
        local ReplionModule = game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("Replion", 10)
        if not ReplionModule then return false end
        local ReplionClient = require(ReplionModule).Client
        MerchantReplion = ReplionClient:WaitReplion("Merchant", 5)
        return MerchantReplion
    end
    
    local function getNextRefreshTimeString()
        local serverTime = workspace:GetServerTimeNow()
        local secondsInDay = 86400
        local nextRefreshTime = (math.floor(serverTime / secondsInDay) + 1) * secondsInDay
        local timeRemaining = math.max(nextRefreshTime - serverTime, 0)
        local h = math.floor(timeRemaining / 3600)
        local m = math.floor((timeRemaining % 3600) / 60)
        local s = math.floor(timeRemaining % 60)
        return string.format("Next Refresh: %dH, %dM, %dS", h, m, s)
    end
    
    local function GetMerchantStockDetails(merchantData)
        return shop.GetMerchantStockDetails(merchantData)
    end
    
    local function RunMerchantSyncLoop(mainDisplay)
        if UpdateThread then task.cancel(UpdateThread) end
        
        local initialDetails = GetMerchantStockDetails(MerchantReplion.Data)
        RedrawMerchantButtons(initialDetails)
        
        local stockUpdateConnection = MerchantReplion:OnChange("Items", function(newItems)
            local currentDetails = GetMerchantStockDetails(MerchantReplion.Data)
            RedrawMerchantButtons(currentDetails)
            
            local timeString = getNextRefreshTimeString()
            local stockListString = CreateStockListString(currentDetails)
            mainDisplay:SetTitle(timeString .. "\n" .. stockListString)
        end)
        
        local isRunning = true
        
        UpdateThread = task.spawn(function()
            while isRunning do
                local timeString = getNextRefreshTimeString()
                local currentDetails = GetMerchantStockDetails(MerchantReplion.Data)
                local stockListString = CreateStockListString(currentDetails)
                
                mainDisplay:SetTitle(timeString .. "\n" .. stockListString)
                
                task.wait(1)
            end
            if stockUpdateConnection then stockUpdateConnection:Disconnect() end
            ClearOldMerchantButtons()
        end)
        
        return function()
            isRunning = false
            if UpdateThread then task.cancel(UpdateThread) UpdateThread = nil end
            if stockUpdateConnection then stockUpdateConnection:Disconnect() end
            ClearOldMerchantButtons()
        end
    end
    
    local function ToggleMerchantSync(state, mainDisplay)
        if state then
            task.spawn(function()
                if not GetReplions() then
                    WindUI:Notify({ Title = "Sync Gagal", Content = "Gagal memuat Replion Merchant.", Duration = 4, Icon = "x", })
                    mainDisplay:SetTitle("Sync Gagal: Merchant Replion missing/timeout.")
                    mainDisplay:SetDesc("Toggle OFF dan coba lagi.")
                    return
                end
                
                WindUI:Notify({ Title = "Sync ON!", Content = "Memulai live update stok dan tombol beli.", Duration = 2, Icon = "check", })
                mainDisplay:SetDesc("Waktu refresh dihitung akurat dari server.")
                UpdateCleanupFunction = RunMerchantSyncLoop(mainDisplay)
            end)
            
            return true
        else
            WindUI:Notify({ Title = "Sync OFF!", Duration = 3, Icon = "x", })
            
            if UpdateCleanupFunction then
                UpdateCleanupFunction()
                UpdateCleanupFunction = nil
            end
            
            mainDisplay:SetTitle("Merchant Live Data OFF.")
            mainDisplay:SetDesc("Toggle ON untuk melihat status live.")
            ClearOldMerchantButtons()
            
            return false
        end
    end
    
    local merchant = shopTab:Section({
        Title = "Traveling Merchant",
        TextSize = 20,
    })
    shopTab:Divider()
    
    MainDisplayElement = merchant:Paragraph({
        Title = "Merchant Live Data OFF.",
        Desc = "Toggle ON untuk melihat status live.",
        Icon = "clock"
    })
    
    local tlive = merchant:Toggle({
        Title = "Live Stock & Buy Actions",
        Icon = "rotate-ccw",
        Value = true,
        Callback = function(state)
            return ToggleMerchantSync(state, MainDisplayElement)
        end,
    })
    
    local tcurst = merchant:Toggle({
        Title = "Auto Buy Current Stock",
        Value = false,
        Callback = function(state)
            autoBuyStockState = state
            if state then
                -- Run auto buy loop
                WindUI:Notify({ Title = "Auto Buy Stock ON", Duration = 3, Icon = "check" })
            else
                if autoBuyThread then task.cancel(autoBuyThread) autoBuyThread = nil end
                WindUI:Notify({ Title = "Auto Buy Stock OFF", Duration = 3, Icon = "x" })
            end
        end
    })
    
    local telemerc = merchant:Button({ 
        Title = "Teleport To Merchant Shop", 
        Icon = "mouse-pointer-click", 
        Callback = function() 
            local cf = CFrame.new(-127.747, 2.718, 2759.031)
            local look = Vector3.new(-0.920, 0, -0.392)
            players.TeleportToLookAt(cf.Position, look)
        end 
    })
    
    shopTab:Divider()
    
    -- Purchase sections
    local prod = shopTab:Section({ Title = "Purchase Rods", TextSize = 20, })
    shopTab:Divider()
    local rodOptions = getDropdownOptions("Rods")
    local droprod = prod:Dropdown({ Title = "Select Rod", Values = rodOptions, Value = false, Callback = function(value) selectedRodName = value end })
    local butrod = prod:Button({ Title = "Purchase Selected Rod", Icon = "mouse-pointer-click", Callback = function() handlePurchase("Rods", selectedRodName) end })
    
    local pbait = shopTab:Section({ Title = "Purchase Bobbers", TextSize = 20, })
    shopTab:Divider()
    local bobberOptions = getDropdownOptions("Bobbers")
    local dbait = pbait:Dropdown({ Title = "Select Bobber", Values = bobberOptions, Value = false, Callback = function(value) selectedBobberName = value end })
    local butbait = pbait:Button({ Title = "Purchase Selected Bobber", Icon = "mouse-pointer-click", Callback = function() handlePurchase("Bobbers", selectedBobberName) end })
    
    local pboat = shopTab:Section({ Title = "Purchase Boats", TextSize = 20, })
    shopTab:Divider()
    local boatOptions = getDropdownOptions("Boats")
    local dboat = pboat:Dropdown({ Title = "Select Boat", Values = boatOptions, Value = false, Callback = function(value) selectedBoatName = value end })
    local butboat = pboat:Button({ Title = "Purchase Selected Boat", Icon = "mouse-pointer-click", Callback = function() handlePurchase("Boats", selectedBoatName) end })
    
    local ptele = shopTab:Section({ Title = "Shop Teleports", TextSize = 20, })
    shopTab:Divider()
    local buttele = ptele:Button({ Title = "Skin Crate Shop", Icon = "mouse-pointer-click", Callback = function() 
        local cf = CFrame.new(79.038, 17.284, 2869.537)
        local look = Vector3.new(-0.893, -0.000, 0.450)
        players.TeleportToLookAt(cf.Position, look)
    end })
    local bututil = ptele:Button({ Title = "Utility Shop", Icon = "mouse-pointer-click", Callback = function() 
        local cf = CFrame.new(-41.260, 20.460, 2877.561)
        local look = Vector3.new(-0.893, -0.000, 0.450)
        players.TeleportToLookAt(cf.Position, look)
    end })
end