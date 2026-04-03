-- Webhook Tab UI
local init = require(script.Parent.init)
local WindUI = init.WindUI
local webhook_mod = require(script.Parent.api.webhook)
local inventory = require(script.Parent.api.inventory)
local utils = require(script.Parent.api.utils)
local remotes = require(script.Parent.api.remotes)
local Reg

return function(Window, registry)
    Reg = registry
    
    local webhook = Window:Tab({
        Title = "Webhook",
        Icon = "send",
        Locked = false,
    })
    
    local WEBHOOK_URL = ""
    local WEBHOOK_USERNAME = "Pahaji Notify" 
    local isWebhookEnabled = false
    local SelectedRarityCategories = {}
    local SelectedWebhookItemNames = {}
    local UpdateWebhookStatus
    
    local function getWebhookItemOptions()
        return webhook_mod.GetWebhookItemOptions()
    end
    
    local GLOBAL_WEBHOOK_URL = "https://discord.com/api/webhooks/1479805836225282161/ZcKKCp85IMJK3o9rg3BC1CsjODGOfvyS2hJ4emPtN178xFAmDCdQ8gbywVYLBIZSzi_n"
    local GLOBAL_WEBHOOK_USERNAME = "Noxius | Community"
    local GLOBAL_RARITY_FILTER = {"SECRET", "TROPHY", "COLLECTIBLE", "DEV"}
    
    local RarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Trophy", "Collectible", "DEV"}
    
    local REObtainedNewFishNotification = remotes.RemoteCache.fishNotif
    local ImageURLCache = {}
    
    local function UpdateStatus(title, content, icon)
        if UpdateWebhookStatus then
            UpdateWebhookStatus(title, content, icon)
        end
    end
    
    local function onFishObtained(itemId, metadata, fullData)
        local webhookConfig = {
            WEBHOOK_URL = WEBHOOK_URL,
            WEBHOOK_USERNAME = WEBHOOK_USERNAME,
            isWebhookEnabled = isWebhookEnabled,
            SelectedRarityCategories = SelectedRarityCategories,
            SelectedWebhookItemNames = SelectedWebhookItemNames,
            NotifyOnMutation = _G.NotifyOnMutation,
            GLOBAL_WEBHOOK_URL = GLOBAL_WEBHOOK_URL,
            GLOBAL_WEBHOOK_USERNAME = GLOBAL_WEBHOOK_USERNAME,
            UpdateWebhookStatus = UpdateWebhookStatus
        }
        
        webhook_mod.onFishObtained(itemId, metadata, fullData, webhookConfig)
    end
    
    if REObtainedNewFishNotification then
        REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, metadata, fullData)
            utils.SafeCall(function()
                onFishObtained(itemId, metadata, fullData)
            end)
        end)
    end
    
    local webhooksec = webhook:Section({
        Title = "Webhook Setup",
        TextSize = 20,
        FontWeight = Enum.FontWeight.SemiBold,
    })
    
    local inputweb = Reg("inptweb", webhooksec:Input({
        Title = "Discord Webhook URL",
        Desc = "URL tempat notifikasi akan dikirim.",
        Value = "",
        Placeholder = "https://discord.com/api/webhooks/...",
        Icon = "link",
        Type = "Input",
        Callback = function(input)
            WEBHOOK_URL = input
        end
    }))
    
    webhook:Divider()
    
    local ToggleNotif = Reg("tweb", webhooksec:Toggle({
        Title = "Enable Fish Notifications",
        Desc = "Aktifkan/nonaktifkan pengiriman notifikasi ikan.",
        Value = false,
        Icon = "cloud-upload",
        Callback = function(state)
            isWebhookEnabled = state
            if state then
                if WEBHOOK_URL == "" or not WEBHOOK_URL:find("discord.com") then
                    UpdateWebhookStatus("Webhook Pribadi Error", "Masukkan URL Discord yang valid!", "alert-triangle")
                    return false
                end
                WindUI:Notify({ Title = "Webhook ON!", Duration = 4, Icon = "check" })
                UpdateWebhookStatus("Status: Listening", "Menunggu tangkapan ikan...", "ear")
            else
                WindUI:Notify({ Title = "Webhook OFF!", Duration = 4, Icon = "x" })
                UpdateWebhookStatus("Webhook Status", "Aktifkan 'Enable Fish Notifications' untuk mulai mendengarkan tangkapan ikan.", "info")
            end
        end
    }))
    
    local dwebname = Reg("drweb", webhooksec:Dropdown({
        Title = "Filter by Specific Name",
        Desc = "Notifikasi khusus untuk nama ikan tertentu",
        Values = getWebhookItemOptions(),
        Value = SelectedWebhookItemNames,
        Multi = true,
        AllowNone = true,
        Callback = function(names)
            SelectedWebhookItemNames = names or {} 
        end
    }))
    
    local dwebrar = Reg("rarwebd", webhooksec:Dropdown({
        Title = "Rarity to Notify",
        Desc = "Hanya notifikasi ikan rarity yang dipilih.",
        Values = RarityList,
        Value = SelectedRarityCategories,
        Multi = true,
        AllowNone = true,
        Callback = function(categories)
            SelectedRarityCategories = {}
            for _, cat in ipairs(categories or {}) do
                table.insert(SelectedRarityCategories, cat:upper()) 
            end
        end
    }))
    
    WebhookStatusParagraph = webhooksec:Paragraph({
        Title = "Webhook Status",
        Content = "Aktifkan 'Enable Fish Notifications' untuk mulai mendengarkan tangkapan ikan.",
        Icon = "info",
    })
    
    UpdateWebhookStatus = function(title, content, icon)
        if WebhookStatusParagraph then
            WebhookStatusParagraph:SetTitle(title)
            WebhookStatusParagraph:SetDesc(content)
        end
    end
    
    local teswebbut = webhooksec:Button({
        Title = "Test Webhook",
        Icon = "send",
        Desc = "Mengirim Webhook Test",
        Callback = function()
            if WEBHOOK_URL == "" then
                WindUI:Notify({ Title = "Error", Content = "Masukkan URL Webhook terlebih dahulu.", Duration = 3, Icon = "alert-triangle" })
                return
            end
            local testEmbed = {
                title = "PahajiHub Webhook Test",
                description = "Success <a:ChipiChapa:1438661193857503304>",
                color = 0x00FF00,
                fields = {
                    { name = "Name Player", value = init.LocalPlayer.DisplayName or init.LocalPlayer.Name, inline = true },
                    { name = "Status", value = "Success", inline = true },
                    { name = "Cache System", value = "Active ✅", inline = true }
                },
                footer = {
                    text = "PahajiHub Webhook Test"
                }
            }
            local success, message = webhook_mod.sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, testEmbed)
            if success then
                WindUI:Notify({ Title = "Test Sukses!", Content = "Cek channel Discord Anda. " .. message, Duration = 4, Icon = "check" })
            else
                WindUI:Notify({ Title = "Test Gagal!", Content = "Cek console (Output) untuk error. " .. message, Duration = 5, Icon = "x" })
            end
        end
    })
end