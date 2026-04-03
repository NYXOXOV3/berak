-- Discord webhook handling
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local utils = require(script.Parent.utils)
local inventory = require(script.Parent.inventory)

local ImageURLCache = {}

function sendExploitWebhook(url, username, embed_data)
    local payload = {
        username = username,
        embeds = {embed_data},
        allowed_mentions = {
            parse = { "users", "roles" }
        } 
    }
    
    local json_data = HttpService:JSONEncode(payload)
    
    if typeof(request) == "function" then
        local success, response = pcall(function()
            return request({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = json_data
            })
        end)
        
        if success and (response.StatusCode == 200 or response.StatusCode == 204) then
            return true, "Sent"
        elseif success and response.StatusCode then
            return false, "Failed: " .. response.StatusCode
        elseif not success then
            return false, "Error: " .. tostring(response)
        end
    end
    return false, "No Request Func"
end

function onFishObtained(itemId, metadata, fullData, webhookConfig)
    local success, results = pcall(function()
        local dummyItem = {Id = itemId, Metadata = metadata}
        local fishName, fishRarity = inventory.GetFishNameAndRarity(dummyItem)
        local fishRarityUpper = fishRarity:upper()
        
        local fishWeight = string.format("%.2fkg", metadata.Weight or 0)
        local mutationString = inventory.GetItemMutationString(dummyItem)
        local mutationDisplay = mutationString ~= "" and mutationString or "N/A"
        local itemData = inventory.ItemUtility and inventory.ItemUtility:GetItemData(itemId)
        
        local assetId = nil
        if itemData and itemData.Data then
            local iconRaw = itemData.Data.Icon or itemData.Data.ImageId
            if iconRaw then
                assetId = tonumber(string.match(tostring(iconRaw), "%d+"))
            end
        end
        
        local imageUrl = assetId and utils.GetRobloxAssetImage(assetId, ImageURLCache)
        if not imageUrl then
            imageUrl = "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png"
        end
        
        local basePrice = itemData and itemData.SellPrice or 0
        local sellPrice = basePrice * (metadata.SellMultiplier or 1)
        local formattedSellPrice = string.format("%s$", utils.FormatNumber(sellPrice))
        
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local caughtStat = leaderstats and leaderstats:FindFirstChild("Caught")
        local caughtDisplay = caughtStat and utils.FormatNumber(caughtStat.Value) or "N/A"
        
        -- Get current coins
        local currentCoins = 0
        local replion = inventory.GetPlayerDataReplion()
        
        if replion then
            local success_curr, CurrencyConfig = pcall(function()
                return require(game:GetService("ReplicatedStorage").Modules.CurrencyUtility.Currency)
            end)
            
            if success_curr and CurrencyConfig and CurrencyConfig["Coins"] then
                currentCoins = replion:Get(CurrencyConfig["Coins"].Path) or 0
            else
                currentCoins = replion:Get("Coins") or replion:Get({"Coins"}) or 0
            end
        else
            if leaderstats then
                local coinStat = leaderstats:FindFirstChild("Coins") or leaderstats:FindFirstChild("C$")
                currentCoins = coinStat and coinStat.Value or 0
            end
        end
        
        local formattedCoins = utils.FormatNumber(currentCoins)
        local playerName = LocalPlayer.DisplayName or LocalPlayer.Name
        local censoredPlayerName = utils.CensorName(playerName)
        
        -- Check if should notify based on filters
        local isUserFilterMatch = false
        if #webhookConfig.SelectedRarityCategories > 0 and table.find(webhookConfig.SelectedRarityCategories, fishRarityUpper) then
            isUserFilterMatch = true
        end
        
        if #webhookConfig.SelectedWebhookItemNames > 0 and table.find(webhookConfig.SelectedWebhookItemNames, fishName) then
            isUserFilterMatch = true
        end
        
        if webhookConfig.NotifyOnMutation and (metadata.Shiny or metadata.VariantId) then
            isUserFilterMatch = true
        end
        
        -- Send private webhook if enabled and matches filter
        if webhookConfig.isWebhookEnabled and webhookConfig.WEBHOOK_URL ~= "" and isUserFilterMatch then
            local title_private = string.format("<:TEXTURENOBG:1438662703722790992> PahajiHub | Webhook\n\n<a:ChipiChapa:1438661193857503304> New Fish Caught! (%s)", fishName)
            
            local embed = {
                title = title_private,
                description = string.format("Found by **%s**.", censoredPlayerName),
                color = utils.GetRarityColor(fishRarityUpper),
                fields = {
                    { name = "<a:ARROW:1438758883203223605> Fish Name", value = string.format("`%s`", fishName), inline = true },
                    { name = "<a:ARROW:1438758883203223605> Rarity", value = string.format("`%s`", fishRarityUpper), inline = true },
                    { name = "<a:ARROW:1438758883203223605> Weight", value = string.format("`%s`", fishWeight), inline = true },
                    { name = "<a:ARROW:1438758883203223605> Mutation", value = string.format("`%s`", mutationDisplay), inline = true },
                    { name = "<a:coines:1438758976992051231> Sell Price", value = string.format("`%s`", formattedSellPrice), inline = true },
                    { name = "<a:coines:1438758976992051231> Current Coins", value = string.format("`%s`", formattedCoins), inline = true },
                },
                thumbnail = { url = imageUrl },
                footer = {
                    text = string.format("PahajiHub Webhook • Total Caught: %s • %s", caughtDisplay, os.date("%Y-%m-%d %H:%M:%S"))
                }
            }
            
            local success_send, message = sendExploitWebhook(webhookConfig.WEBHOOK_URL, webhookConfig.WEBHOOK_USERNAME, embed)
            
            if webhookConfig.UpdateWebhookStatus then
                if success_send then
                    webhookConfig.UpdateWebhookStatus("Webhook Aktif", "Terkirim: " .. fishName, "check")
                else
                    webhookConfig.UpdateWebhookStatus("Webhook Gagal", "Error: " .. message, "x")
                end
            end
        end
        
        -- Global webhook for rare fish
        local GLOBAL_RARITY_FILTER = {"SECRET", "TROPHY", "COLLECTIBLE", "DEV"}
        local isGlobalTarget = false
        for _, r in ipairs(GLOBAL_RARITY_FILTER) do
            if fishRarityUpper == r then
                isGlobalTarget = true
                break
            end
        end
        
        if isGlobalTarget and webhookConfig.GLOBAL_WEBHOOK_URL ~= "" then
            local title_global = string.format("<:TEXTURENOBG:1438662703722790992> PahajiHub | Global Tracker\n\n<a:globe:1438758633151266818> GLOBAL CATCH! %s", fishName)
            
            local globalEmbed = {
                title = title_global,
                description = string.format("Pemain **%s** baru saja menangkap ikan **%s**!", censoredPlayerName, fishRarityUpper),
                color = utils.GetRarityColor(fishRarityUpper),
                fields = {
                    { name = "<a:ARROW:1438758883203223605> Rarity", value = string.format("`%s`", fishRarityUpper), inline = true },
                    { name = "<a:ARROW:1438758883203223605> Weight", value = string.format("`%s`", fishWeight), inline = true },
                    { name = "<a:ARROW:1438758883203223605> Mutation", value = string.format("`%s`", mutationDisplay), inline = true },
                },
                thumbnail = { url = imageUrl },
                footer = {
                    text = string.format("Noxius Community | Player: %s | %s", censoredPlayerName, os.date("%Y-%m-%d %H:%M:%S"))
                }
            }
            
            sendExploitWebhook(webhookConfig.GLOBAL_WEBHOOK_URL, webhookConfig.GLOBAL_WEBHOOK_USERNAME, globalEmbed)
        end
    end)
    
    if not success then
        warn("[PahajiHub Webhook] Error processing fish data:", results)
    end
end

function SetupFishNotificationHook(webhookConfig)
    local REObtainedNewFishNotification = require(script.Parent.remotes).GetServerRemote("RE/ObtainedNewFishNotification")
    if REObtainedNewFishNotification then
        REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, metadata, fullData)
            utils.SafeCall(function()
                onFishObtained(itemId, metadata, fullData, webhookConfig)
            end)
        end)
    end
end

function GetWebhookItemOptions()
    local itemNames = {}
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local itemsContainer = ReplicatedStorage:FindFirstChild("Items")
    if itemsContainer then
        for _, itemObject in ipairs(itemsContainer:GetChildren()) do
            local itemName = itemObject.Name
            if type(itemName) == "string" and #itemName >= 3 and itemName:sub(1, 3) ~= "!!!" then
                table.insert(itemNames, itemName)
            end
        end
    end
    table.sort(itemNames)
    return itemNames
end

return {
    sendExploitWebhook = sendExploitWebhook,
    onFishObtained = onFishObtained,
    SetupFishNotificationHook = SetupFishNotificationHook,
    GetWebhookItemOptions = GetWebhookItemOptions,
    GetRarityColor = utils.GetRarityColor,
    CensorName = utils.CensorName,
    FormatNumber = utils.FormatNumber
}