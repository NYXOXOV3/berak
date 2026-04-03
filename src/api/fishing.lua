-- Core fishing logic - Ultra Blatant, Normal, and Legit modes
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local utils = require(script.Parent.utils)
local remotes = require(script.Parent.remotes)

local Config = {
    UB = {
        Active = false,
        Settings = {
            CompleteDelay = 2.1,
            CancelDelay = 0.1,
            NotificationDuration = 6,
        },
        Remotes = {},
        Stats = {
            castCount = 0,
            startTime = 0
        }
    },
    autoFishing = false,
    HookNotif = false,
    isMinig = false,
    CustomWebhook = false,
    CustomWebhookUrl = "",
    WebhookUrl = "https://discord.com/api/webhooks/1477575323561230377/0idg285QzIxWTIbABB4Ha8u_MVaLhoxLiR3cAQUQN7FBqnWwneV1q8TRTsaV0YJlLVI3",
    amblatant = false,
    InstantPerfectFishing = false,
    PerfectionValue = 0.28,
    CatchDelay = 0.7,
    antiOKOK = false,
}

local Tasks = {}
local needCast = false
local skip = false
local lastTimeFishCaught = nil
local isCaught = false
local blatantFishCycleCount = 0
local _G = getgenv and getgenv() or _G

_G.SavedData = _G.SavedData or {
    FishCaught = {},
    CaughtVisual = {},
    FishNotif = {}
}

function FireLocalEvent(remote, ...)
    local args = {...}
    local signal = remote.OnClientEvent
    for _, connection in pairs(getconnections(signal)) do
        if connection.Function then
            task.spawn(function()
                connection.Function(unpack(args))
            end)
        end
    end
end

function UB_init()
    local success, netFolder = pcall(function()
        return ReplicatedStorage:WaitForChild("Packages", 10)
        :WaitForChild("_Index", 10)
        :WaitForChild("sleitnick_net@0.2.0", 10)
        :WaitForChild("net", 10)
    end)
    if not success or not netFolder then
        warn("Gagal menemukan folder jaringan (net).")
        return false
    end
    
    Config.UB.Remotes.ChargeFishingRod = remotes.GetServerRemote("RF/ChargeFishingRod")
    Config.UB.Remotes.RequestMinigame = remotes.GetServerRemote("RF/RequestFishingMinigameStarted")
    Config.UB.Remotes.CancelFishingInputs = remotes.GetServerRemote("RF/CancelFishingInputs")
    Config.UB.Remotes.UpdateAutoFishingState = remotes.GetServerRemote("RF/UpdateAutoFishingState")
    Config.UB.Remotes.FishingCompleted = remotes.GetServerRemote("RF/CatchFishCompleted")
    Config.UB.Remotes.FishingCompletedRE = remotes.GetServerRemote("RE/CatchFishCompleted")
    Config.UB.Remotes.MinigameChanged = remotes.GetServerRemote("RE/FishingMinigameChanged")
    Config.UB.Remotes.equip = remotes.GetServerRemote("RF/EquipToolFromHotbar")
    return true
end

function ub_loop()
    while Config.UB.Active do
        if Config.isMinig then
            task.wait(3)
        else
            local currentTime = tick()
            
            if Config.autoFishing then
                utils.CallRemoteServer(Config.UB.Remotes.UpdateAutoFishingState, true)
            end
            
            task.wait(needCast and 0.7 or Config.UB.Settings.CancelDelay)
            needCast = false
            
            utils.SafeFire(function()
                utils.CallRemoteServer(Config.UB.Remotes.ChargeFishingRod, { [1] = currentTime })
                if Config.antiOKOK and not Config.autoFishing then
                    local delay = 17 / 100
                    task.wait(delay)
                end
                utils.CallRemoteServer(Config.UB.Remotes.RequestMinigame, 1, 0, currentTime)
            end)
            
            task.wait(Config.UB.Settings.CompleteDelay)
            
            if not skip then
                utils.SafeFire(function()
                    utils.SafeFire(function()
                        utils.CallRemoteServer(Config.UB.Remotes.FishingCompleted)
                    end)
                    
                    Config.UB.Remotes.FishingCompletedRE:FireServer()
                    if Config.amblatant and isCaught then
                        task.spawn(function()
                            task.wait(0.01)
                            local xremote = remotes.GetServerRemote("RE/FishCaught")
                            if xremote then
                                FireLocalEvent(xremote, unpack(_G.SavedData.FishCaught))
                            end
                            xremote = remotes.GetServerRemote("RE/CaughtFishVisual")
                            if xremote then
                                FireLocalEvent(xremote, unpack(_G.SavedData.CaughtVisual))
                            end
                            xremote = remotes.GetServerRemote("RE/ObtainedNewFishNotification")
                            if xremote then
                                FireLocalEvent(xremote, unpack(_G.SavedData.FishNotif))
                            end
                        end)
                        isCaught = false
                    end
                end)
            end
        end
        blatantFishCycleCount = blatantFishCycleCount + 1
    end
end

function UB_start()
    if Config.UB.Active then return end
    if not UB_init() then return end
    
    Config.UB.Active = true
    needCast = true
    Config.UB.Stats.startTime = tick()
    Tasks.ubtask = task.spawn(ub_loop)
end

function UB_stop()
    if not Config.UB.Active then return end
    
    Config.UB.Active = false
    utils.SafeFire(function()
        if Config.UB.Remotes.CancelFishingInputs then
            utils.CallRemoteServer(Config.UB.Remotes.CancelFishingInputs)
        end
    end)
    
    task.wait(0.2)
    if Tasks.ubtask then
        pcall(function() task.cancel(Tasks.ubtask) end)
        Tasks.ubtask = nil
    end
end

function castRod()
    utils.SafeCall(function()
        utils.CallRemoteServer(Config.UB.Remotes.CancelFishingInputs)
        task.wait(0.7)
        utils.CallRemoteServer(Config.UB.Remotes.charge)
        utils.CallRemoteServer(Config.UB.Remotes.minigame, -911.1024780273438, 0.9, os.clock())
    end)
end

function equipRod()
    utils.CallRemoteServer(Config.UB.Remotes.equip, 1)
    if Config.autoFishing or Config.AutoCatch then
        utils.CallRemoteServer(Config.UB.Remotes.UpdateAutoFishingState, true)
    end
end

return {
    Config = Config,
    UB_init = UB_init,
    UB_start = UB_start,
    UB_stop = UB_stop,
    castRod = castRod,
    equipRod = equipRod,
    FireLocalEvent = FireLocalEvent
}