-- Main entry point for Noxius Hub
-- Loads WindUI and initializes all modules

-- Load WindUI
local WindUI
local ok, result = pcall(function()
    return require("./src/Init")
end)

if ok then
    WindUI = result
else
    if game:GetService("RunService"):IsStudio() then
        WindUI = require(game:GetService("ReplicatedStorage"):WaitForChild("WindUI"):WaitForChild("Init"))
    else
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end
end

-- Cache remotes on startup
local remotes = require(script.Parent.api.remotes)
remotes.CacheRemotes()

-- Setup player connection for anti-idle
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

for i, v in pairs(getconnections(LocalPlayer.Idled)) do
    if v.Disable then v:Disable() elseif v.Disconnect then v:Disconnect() end
end

-- Export for UI modules
return {
    WindUI = WindUI,
    remotes = remotes,
    LocalPlayer = LocalPlayer,
    Players = Players
}