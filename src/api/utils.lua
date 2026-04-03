-- Utility functions for Noxius Hub
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function SafeCall(func)
    pcall(func)
end

function SafeFire(func)
    task.spawn(function()
        pcall(func)
    end)
end

function CallRemoteServer(remote, ...)
    if not remote then return false end
    local ok
    if remote:IsA("RemoteFunction") then
        ok = select(1, pcall(function(...)
            remote:InvokeServer(...)
        end, ...))
    elseif remote:IsA("RemoteEvent") then
        ok = select(1, pcall(function(...)
            remote:FireServer(...)
        end, ...))
    else
        ok = select(1, pcall(function(...)
            remote:InvokeServer(...)
        end, ...))
        if not ok then
            ok = select(1, pcall(function(...)
                remote:FireServer(...)
            end, ...))
        end
    end
    return ok
end

function FormatNumber(n)
    if n >= 1000000000 then return string.format("%.1fB", n / 1000000000)
    elseif n >= 1000000 then return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then return string.format("%.1fK", n / 1000)
    else return tostring(n) end
end

function CensorName(name)
    if not name or type(name) ~= "string" or #name < 1 then
        return "N/A"
    end
    if #name <= 3 then
        return name
    end
    local prefix = name:sub(1, 3)
    local censureLength = #name - 3
    local censorString = string.rep("*", censureLength)
    return prefix .. censorString
end

function GetRobloxAssetImage(assetId, cache)
    if not assetId or assetId == 0 then return nil end
    
    if cache and cache[assetId] then
        return cache[assetId]
    end
    
    local url = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png&isCircular=false", assetId)
    local success, response = pcall(game.HttpGet, game, url)
    
    if success then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, response)
        if ok and data and data.data and data.data[1] and data.data[1].imageUrl then
            local finalUrl = data.data[1].imageUrl
            if cache then cache[assetId] = finalUrl end
            return finalUrl
        end
    end
    return nil
end

function GetRarityColor(rarity)
    local r = rarity:upper()
    if r == "SECRET" then return 0xFFD700 end
    if r == "MYTHIC" then return 0x9400D3 end
    if r == "LEGENDARY" then return 0xFF4500 end
    if r == "EPIC" then return 0x8A2BE2 end
    if r == "RARE" then return 0x0000FF end
    if r == "UNCOMMON" then return 0x00FF00 end
    return 0x00BFFF
end

return {
    SafeCall = SafeCall,
    SafeFire = SafeFire,
    CallRemoteServer = CallRemoteServer,
    FormatNumber = FormatNumber,
    CensorName = CensorName,
    GetRobloxAssetImage = GetRobloxAssetImage,
    GetRarityColor = GetRarityColor
}