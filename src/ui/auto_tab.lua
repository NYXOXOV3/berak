-- Automatic Tab UI (Auto Sell, Auto Favorite, Auto Enchant, etc.)
local init = require(script.Parent.init)
local WindUI = init.WindUI
local remotes = require(script.Parent.api.remotes)
local inventory = require(script.Parent.api.inventory)
local shop = require(script.Parent.api.shop)
local fishing = require(script.Parent.api.fishing)
local players = require(script.Parent.api.players)
local Reg

return function(Window, registry)
    Reg = registry
    
    local automatic = Window:Tab({
        Title = "Automatic",
        Icon = "loader",
        Locked = false,
    })
    
    -- Auto Sell Section
    local sellDelay = 50
    local autoSellState = false
    local autoSellThread = nil
    local autoSellMethod = "Delay"
    local autoSellValue = 50
    
    local RF_SellAllItems = remotes.RemoteCache.sell
    
    local function GetFishCount()
        return inventory.GetFishCount()
    end
    
    local function RunAutoSellLoop()
        if autoSellThread then task.cancel(autoSellThread) end
        
        autoSellThread = task.spawn(function()
            while autoSellState do
                if autoSellMethod == "Delay" then
                    if RF_SellAllItems then
                        pcall(function() RF_SellAllItems:InvokeServer() end)
                    end
                    task.wait(math.max(autoSellValue, 1))
                elseif autoSellMethod == "Count" then
                    local currentCount = GetFishCount()
                    if currentCount >= autoSellValue then
                        if RF_SellAllItems then
                            pcall(function() RF_SellAllItems:InvokeServer() end)
                            WindUI:Notify({ Title = "Auto Sell", Content = "Menjual " .. currentCount .. " items.", Duration = 2, Icon = "dollar-sign" })
                            task.wait(2)
                        end
                    end
                    task.wait(1)
                end
            end
        end)
    end
    
    local sellall = automatic:Section({ Title = "Autosell Fish", TextSize = 20 })
    
    local inputElement
    local dropMethod = sellall:Dropdown({
        Title = "Select Method",
        Values = {"Delay", "Count"},
        Value = "Delay",
        Multi = false,
        AllowNone = false,
        Callback = function(val)
            autoSellMethod = val
            if inputElement then
                if val == "Delay" then
                    inputElement:SetTitle("Sell Delay (Seconds)")
                    inputElement:SetPlaceholder("e.g. 50")
                else
                    inputElement:SetTitle("Sell at Item Count")
                    inputElement:SetPlaceholder("e.g. 100")
                end
            end
            if autoSellState then RunAutoSellLoop() end
        end
    })
    
    inputElement = Reg("sellval", sellall:Input({
        Title = "Sell Delay (Seconds)",
        Value = tostring(autoSellValue),
        Placeholder = "50",
        Icon = "hash",
        Callback = function(text)
            local num = tonumber(text)
            if num then autoSellValue = num end
        end
    }))
    
    local CurrentCountDisplay = sellall:Paragraph({ Title = "Current Fish Count: 0", Icon = "package" })
    
    task.spawn(function()
        while true do
            if CurrentCountDisplay and inventory.GetPlayerDataReplion then
                CurrentCountDisplay:SetTitle("Current Fish Count: " .. GetFishCount())
            end
            task.wait(1)
        end
    end)
    
    local togSell = Reg("tsell", sellall:Toggle({
        Title = "Enable Auto Sell",
        Desc = "Menjalankan auto sell sesuai metode di atas.",
        Value = false,
        Callback = function(state)
            autoSellState = state
            if state then
                if not RF_SellAllItems then
                    WindUI:Notify({ Title = "Error", Content = "Remote Sell tidak ditemukan.", Duration = 3, Icon = "x" })
                    return
                end
                local msg = (autoSellMethod == "Delay") and ("Setiap " .. autoSellValue .. " detik.") or ("Saat jumlah >= " .. autoSellValue)
                WindUI:Notify({ Title = "Auto Sell ON (" .. autoSellMethod .. ")", Content = msg, Duration = 3, Icon = "check" })
                RunAutoSellLoop()
            else
                WindUI:Notify({ Title = "Auto Sell OFF", Duration = 3, Icon = "x" })
                if autoSellThread then task.cancel(autoSellThread) autoSellThread = nil end
            end
        end
    }))
    
    automatic:Divider()
    
    -- Auto Favorite/Unfavorite Section
    local autoFavoriteState = false
    local autoUnfavoriteState = false
    local autoFavoriteThread = nil
    local autoUnfavoriteThread = nil
    local selectedRarities = {}
    local selectedItemNames = {}
    local selectedMutations = {}
    
    local RE_FavoriteItem = remotes.RemoteCache.favorite
    
    local function getAutoFavoriteItemOptions()
        local itemNames = {}
        local itemsContainer = game:GetService("ReplicatedStorage"):FindFirstChild("Items")
        if not itemsContainer then return {"(Items container not found)"} end
        
        for _, itemObject in ipairs(itemsContainer:GetChildren()) do
            local itemName = itemObject.Name
            if type(itemName) == "string" and #itemName >= 3 and itemName:sub(1,3) ~= "!!!" then
                table.insert(itemNames, itemName)
            end
        end
        table.sort(itemNames)
        return #itemNames > 0 and itemNames or {"(No items found)"}
    end
    
    local allItemNames = getAutoFavoriteItemOptions()
    
    local function GetItemsToFavorite()
        return inventory.GetItemsToFavorite(selectedRarities, selectedItemNames, selectedMutations)
    end
    
    local function GetItemsToUnfavorite()
        local replion = inventory.GetPlayerDataReplion()
        if not replion or not inventory.ItemUtility or not inventory.TierUtility then return {} end
        
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return {} end
        
        local itemsToUnfavorite = {}
        for _, item in ipairs(inventoryData.Items) do
            if not (item.IsFavorite or item.Favorited) then continue end
            local itemUUID = item.UUID
            if typeof(itemUUID) ~= "string" or #itemUUID < 10 then continue end
            
            local name, rarity = inventory.GetFishNameAndRarity(item)
            local mutationStr = inventory.GetItemMutationString(item)
            
            local passesRarity = #selectedRarities > 0 and table.find(selectedRarities, rarity)
            local passesName = #selectedItemNames > 0 and table.find(selectedItemNames, name)
            local passesMutation = #selectedMutations > 0 and table.find(selectedMutations, mutationStr)
            
            if passesRarity or passesName or passesMutation then
                table.insert(itemsToUnfavorite, itemUUID)
            end
        end
        return itemsToUnfavorite
    end
    
    local function SetItemFavoriteState(itemUUID)
        if RE_FavoriteItem then pcall(function() RE_FavoriteItem:FireServer(itemUUID) end) end
    end
    
    local function RunAutoFavoriteLoop()
        if autoFavoriteThread then task.cancel(autoFavoriteThread) end
        autoFavoriteThread = task.spawn(function()
            while autoFavoriteState do
                local items = GetItemsToFavorite()
                if #items > 0 then
                    WindUI:Notify({ Title = "Auto Favorite", Content = "Mem-favorite " .. #items .. " item...", Duration = 1, Icon = "star" })
                    for _, uuid in ipairs(items) do
                        SetItemFavoriteState(uuid)
                        task.wait(0.5)
                    end
                end
                task.wait(1)
            end
        end)
    end
    
    local function RunAutoUnfavoriteLoop()
        if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) end
        autoUnfavoriteThread = task.spawn(function()
            while autoUnfavoriteState do
                local items = GetItemsToUnfavorite()
                if #items > 0 then
                    WindUI:Notify({ Title = "Auto Unfavorite", Content = "Menghapus favorite dari " .. #items .. " item...", Duration = 1, Icon = "x" })
                    for _, uuid in ipairs(items) do
                        SetItemFavoriteState(uuid)
                        task.wait(0.5)
                    end
                end
                task.wait(1)
            end
        end)
    end
    
    local favsec = automatic:Section({ Title = "Auto Favorite / Unfavorite", TextSize = 20 })
    
    local RarityDropdown = Reg("drer", favsec:Dropdown({
        Title = "by Rarity",
        Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "SECRET"},
        Multi = true, AllowNone = true, Value = false,
        Callback = function(values) selectedRarities = values or {} end
    }))
    
    local ItemNameDropdown = Reg("dtem", favsec:Dropdown({
        Title = "by Item Name",
        Values = allItemNames,
        Multi = true, AllowNone = true, Value = false,
        Callback = function(values) selectedItemNames = values or {} end
    }))
    
    local MutationDropdown = Reg("dmut", favsec:Dropdown({
        Title = "by Mutation",
        Values = {"Shiny", "Gemstone", "Corrupt", "Galaxy", "Holographic", "Ghost", "Lightning", "Fairy Dust", "Gold", "Midnight", "Radioactive", "Stone", "Albino", "Sandy", "Acidic", "Disco", "Frozen", "Noob"},
        Multi = true, AllowNone = true, Value = false,
        Callback = function(values) selectedMutations = values or {} end
    }))
    
    local togglefav = Reg("tvav", favsec:Toggle({
        Title = "Enable Auto Favorite",
        Value = false,
        Callback = function(state)
            autoFavoriteState = state
            if state then
                if autoUnfavoriteState then
                    autoUnfavoriteState = false
                    local unfavToggle = automatic:GetElementByTitle("Enable Auto Unfavorite")
                    if unfavToggle and unfavToggle.Set then unfavToggle:Set(false) end
                    if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) autoUnfavoriteThread = nil end
                end
                WindUI:Notify({ Title = "Auto Favorite ON!", Duration = 3, Icon = "check" })
                RunAutoFavoriteLoop()
            else
                WindUI:Notify({ Title = "Auto Favorite OFF!", Duration = 3, Icon = "x" })
                if autoFavoriteThread then task.cancel(autoFavoriteThread) autoFavoriteThread = nil end
            end
        end
    }))
    
    local toggleunfav = Reg("tunfa", favsec:Toggle({
        Title = "Enable Auto Unfavorite",
        Value = false,
        Callback = function(state)
            autoUnfavoriteState = state
            if state then
                if autoFavoriteState then
                    autoFavoriteState = false
                    local favToggle = automatic:GetElementByTitle("Enable Auto Favorite")
                    if favToggle and favToggle.Set then favToggle:Set(false) end
                    if autoFavoriteThread then task.cancel(autoFavoriteThread) autoFavoriteThread = nil end
                end
                if #selectedRarities == 0 and #selectedItemNames == 0 and #selectedMutations == 0 then
                    WindUI:Notify({ Title = "Peringatan!", Content = "Semua filter kosong. Non-aktifkan toggle ini.", Duration = 5, Icon = "alert-triangle" })
                    return
                end
                WindUI:Notify({ Title = "Auto Unfavorite ON!", Duration = 3, Icon = "check" })
                RunAutoUnfavoriteLoop()
            else
                WindUI:Notify({ Title = "Auto Unfavorite OFF!", Duration = 3, Icon = "x" })
                if autoUnfavoriteThread then task.cancel(autoUnfavoriteThread) autoUnfavoriteThread = nil end
            end
        end
    }))
    
    automatic:Divider()
    
    -- Auto Enchant Section
    local ENCHANT_MAPPING = {
        ["Cursed I"] = 12, ["Big Hunter I"] = 3, ["Empowered I"] = 9, ["Glistening I"] = 1,
        ["Gold Digger I"] = 4, ["Leprechaun I"] = 5, ["Leprechaun II"] = 6,
        ["Mutation Hunter I"] = 7, ["Mutation Hunter II"] = 14, ["Perfection"] = 15,
        ["Prismatic I"] = 13, ["Reeler I"] = 2, ["Stargazer I"] = 8,
        ["Stormhunter I"] = 11, ["Experienced I"] = 10,
    }
    local ENCHANT_NAMES = {}
    for name, _ in pairs(ENCHANT_MAPPING) do table.insert(ENCHANT_NAMES, name) end
    
    local autoEnchantState = false
    local autoEnchantThread = nil
    local selectedRodUUID = nil
    local selectedEnchantNames = {}
    
    local ENCHANT_STONE_ID = 10
    
    local function GetEnchantNameFromId(id)
        id = tonumber(id)
        if not id then return nil end
        for name, eid in pairs(ENCHANT_MAPPING) do
            if eid == id then return name end
        end
        return nil
    end
    
    local function GetRodOptions()
        return inventory.GetRodOptions()
    end
    
    local function GetUUIDFromFormattedName(formattedName)
        return inventory.GetUUIDFromFormattedName(formattedName)
    end
    
    local function CheckIfEnchantReached(rodUUID)
        local replion = inventory.GetPlayerDataReplion()
        local Rods = replion:GetExpect("Inventory")["Fishing Rods"] or {}
        local targetRod = nil
        for _, rod in ipairs(Rods) do
            if rod.UUID == rodUUID then targetRod = rod break end
        end
        if not targetRod then return true end
        
        local metadata = targetRod.Metadata or {}
        local current = {}
        if metadata.EnchantId then table.insert(current, metadata.EnchantId) end
        
        for _, targetName in ipairs(selectedEnchantNames) do
            local targetID = ENCHANT_MAPPING[targetName]
            if targetID and table.find(current, targetID) then return true end
        end
        return false
    end
    
    local function GetFirstStoneUUID()
        local replion = inventory.GetPlayerDataReplion()
        if not replion then return nil end
        local success, inventoryData = pcall(function() return replion:GetExpect("Inventory") end)
        if not success or not inventoryData or not inventoryData.Items then return nil end
        
        for _, item in ipairs(inventoryData.Items) do
            if tonumber(item.Id) == ENCHANT_STONE_ID and item.UUID then
                return item.UUID
            end
        end
        return nil
    end
    
    local function UnequipAllEquippedItems()
        local RE_UnequipItem = remotes.RemoteCache.UnequipItem
        if not RE_UnequipItem then return end
        
        local replion = inventory.GetPlayerDataReplion()
        local EquippedItems = replion:GetExpect("EquippedItems") or {}
        local EquippedSkinUUID = replion:Get("EquippedSkinUUID")
        
        if EquippedSkinUUID and EquippedSkinUUID ~= "" then
            pcall(function() RE_UnequipItem:FireServer(EquippedSkinUUID) end)
            task.wait(0.1)
        end
        
        for _, uuid in ipairs(EquippedItems) do
            pcall(function() RE_UnequipItem:FireServer(uuid) end)
            task.wait(0.05)
        end
    end
    
    local function RunAutoEnchantLoop(rodUUID)
        if autoEnchantThread then task.cancel(autoEnchantThread) end
        autoEnchantThread = task.spawn(function()
            while autoEnchantState do
                if CheckIfEnchantReached(rodUUID) then
                    WindUI:Notify({ Title = "Enchant Selesai!", Content = "Target enchant sudah tercapai.", Duration = 5, Icon = "check" })
                    break
                end
                
                local stoneUUID = GetFirstStoneUUID()
                if not stoneUUID then
                    WindUI:Notify({ Title = "Stone Habis", Content = "Butuh Enchant Stone", Duration = 4, Icon = "x" })
                    break
                end
                
                UnequipAllEquippedItems()
                task.wait(0.5)
                
                local RE_EquipItem = remotes.RemoteCache.EquipItem
                pcall(function() RE_EquipItem:FireServer(rodUUID, "Fishing Rods") end)
                task.wait(0.3)
                pcall(function() RE_EquipItem:FireServer(stoneUUID, "Enchant Stones") end)
                task.wait(0.3)
                
                local RE_ActivateAltar = remotes.RemoteCache.ActivateEnchantingAltar
                if RE_ActivateAltar then pcall(function() RE_ActivateAltar:FireServer() end) end
                
                task.wait(1.2)
            end
            autoEnchantState = false
            local toggle = automatic:GetElementByTitle("Enable Auto Enchant")
            if toggle and toggle.Set then toggle:Set(false) end
        end)
    end
    
    local enchant = automatic:Section({ Title = "Auto Enchant Rod", TextSize = 20 })
    
    local RodDropdown = enchant:Dropdown({
        Title = "Select Rod",
        Desc = "Pilih jenis Rod yang ingin di-enchant.",
        Values = GetRodOptions(),
        Multi = false,
        AllowNone = true,
        Callback = function(formattedName)
            selectedRodUUID = GetUUIDFromFormattedName(formattedName)
            if selectedRodUUID then
                WindUI:Notify({ Title = "Rod Dipilih", Content = "UUID tersimpan.", Duration = 2, Icon = "check" })
            else
                WindUI:Notify({ Title = "Gagal", Content = "Tidak bisa mendapatkan UUID.", Duration = 2, Icon = "x" })
            end
        end
    })
    
    local rodlist = enchant:Button({
        Title = "Re-Check Selected Rod",
        Icon = "refresh-ccw",
        Callback = function()
            RodDropdown:Refresh(GetRodOptions())
            WindUI:Notify({ Title = "List Diperbarui", Duration = 2, Icon = "check" })
        end
    })
    
    local dropenchant = enchant:Dropdown({
        Title = "Enchant To Apply",
        Desc = "Pilih enchant yang diinginkan.",
        Values = ENCHANT_NAMES,
        Multi = true,
        AllowNone = false,
        Callback = function(names) selectedEnchantNames = names or {} end
    })
    
    local autoenc = enchant:Toggle({
        Title = "Enable Auto Enchant",
        Value = false,
        Callback = function(state)
            autoEnchantState = state
            if state then
                if not selectedRodUUID then
                    WindUI:Notify({ Title = "Error", Content = "Pilih Rod terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                    return
                end
                if #selectedEnchantNames == 0 then
                    WindUI:Notify({ Title = "Error", Content = "Pilih minimal satu enchant.", Duration = 3, Icon = "alert-triangle" })
                    return
                end
                RunAutoEnchantLoop(selectedRodUUID)
            else
                if autoEnchantThread then task.cancel(autoEnchantThread) autoEnchantThread = nil end
                WindUI:Notify({ Title = "Auto Enchant OFF!", Duration = 3, Icon = "x" })
            end
        end
    })
    
    automatic:Divider()
    
    -- Second Enchant (minimal)
    local enchant2 = automatic:Section({ Title = "Second Enchant Rod", TextSize = 20 })
    
    local makeStoneState = false
    local makeStoneThread = nil
    local secondEnchantState = false
    local secondEnchantThread = nil
    local selectedSecretFishUUIDs = {}
    local targetStoneAmount = 1
    
    local TRANSCENDED_STONE_ID = 246
    
    local function GetSecretFishOptions()
        return inventory.GetSecretFishOptions()
    end
    
    local secretFishOptions, secretFishUUIDMap = GetSecretFishOptions()
    
    local function RunMakeStoneLoop()
        if makeStoneThread then task.cancel(makeStoneThread) end
        makeStoneThread = task.spawn(function()
            local createdCount = 0
            
            while makeStoneState and createdCount < targetStoneAmount do
                local _, currentMap = GetSecretFishOptions()
                local fishToSacrifice = nil
                for name, uuid in pairs(currentMap) do
                    if table.find(selectedSecretFishUUIDs, name) then
                        fishToSacrifice = uuid
                        break
                    end
                end
                
                if not fishToSacrifice then
                    WindUI:Notify({ Title = "Selesai / Habis", Content = "Tidak ada ikan target tersisa.", Duration = 5, Icon = "check" })
                    break
                end
                
                WindUI:Notify({ Title = "Sacrificing...", Content = "Memproses ikan...", Duration = 1, Icon = "refresh-cw" })
                
                players.UnequipAllEquippedItems()
                task.wait(0.3)
                pcall(function() remotes.RemoteCache.EquipItem:FireServer(fishToSacrifice, "Fish") end)
                task.wait(0.5)
                pcall(function() remotes.RemoteCache.EquipToolFromHotbar:FireServer(2) end)
                task.wait(0.8)
                
                local success = pcall(function() remotes.RemoteCache.CreateTranscendedStone:InvokeServer() end)
                if success then
                    createdCount = createdCount + 1
                    WindUI:Notify({ Title = "Stone Created!", Content = string.format("Total: %d / %d", createdCount, targetStoneAmount), Duration = 2, Icon = "gem" })
                else
                    WindUI:Notify({ Title = "Gagal", Content = "Gagal membuat batu.", Duration = 2, Icon = "x" })
                end
                task.wait(1.5)
            end
            
            makeStoneState = false
            local toggle = automatic:GetElementByTitle("Start Make Stones")
            if toggle and toggle.Set then toggle:Set(false) end
            pcall(function() remotes.RemoteCache.EquipToolFromHotbar:FireServer(0) end)
        end)
    end
    
    local SecretFishDropdown = enchant2:Dropdown({
        Title = "Select Secret Fish (Sacrifice)",
        Desc = "Pilih ikan SECRET untuk dijadikan Transcended Stone.",
        Values = secretFishOptions,
        Multi = true,
        AllowNone = true,
        Callback = function(values)
            selectedSecretFishUUIDs = values or {} 
        end
    })
    
    local butfish = enchant2:Button({
        Title = "Refresh Secret Fish List",
        Icon = "refresh-ccw",
        Callback = function()
            local newOptions, newMap = GetSecretFishOptions()
            secretFishUUIDMap = newMap
            pcall(function() SecretFishDropdown:Refresh(newOptions) end)
            pcall(function() SecretFishDropdown:Set(false) end)
            selectedSecretFishUUIDs = {}
            WindUI:Notify({ Title = "Refreshed", Content = #newOptions .. " ikan secret ditemukan.", Duration = 2, Icon = "check" })
        end
    })
    
    local amountmake = enchant2:Input({
        Title = "Amount to Make",
        Desc = "Berapa banyak batu yang ingin dibuat?",
        Value = "1",
        Placeholder = "1",
        Icon = "hash",
        Callback = function(input)
            targetStoneAmount = tonumber(input) or 1
        end
    })
    
    local togglestone = enchant2:Toggle({
        Title = "Start Make Stones",
        Desc = "Otomatis ubah ikan terpilih menjadi Transcended Stone.",
        Value = false,
        Callback = function(state)
            makeStoneState = state
            if state then
                if #selectedSecretFishUUIDs == 0 then
                    WindUI:Notify({ Title = "Error", Content = "Pilih minimal 1 jenis ikan secret.", Duration = 3, Icon = "alert-triangle" })
                    return
                end
                RunMakeStoneLoop()
            else
                if makeStoneThread then task.cancel(makeStoneThread) end
                WindUI:Notify({ Title = "Stopped", Duration = 2, Icon = "x" })
            end
        end
    })
end