-- Event tracking (Ancient Lochness, etc.)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local teleport = require(script.Parent.teleport)

-- Event GUI finder (looks for the event tracker UI in workspace)
function GetEventGUI()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    -- Common event GUI names
    local guiNames = {"Event Tracker", "EventTracker", "EventGUI", "Event"}
    for _, name in ipairs(guiNames) do
        local gui = playerGui:FindFirstChild(name)
        if gui then
            -- Look for specific elements
            local countdown = gui:FindFirstChild("Countdown") or gui:FindFirstChild("Timer") or gui:FindFirstChild("Time")
            local timer = gui:FindFirstChild("Timer") or gui:FindFirstChild("Time")
            local quantity = gui:FindFirstChild("Quantity") or gui:FindFirstChild("Caught")
            local odds = gui:FindFirstChild("Odds") or gui:FindFirstChild("Chance")
            
            if countdown or timer then
                return {
                    gui = gui,
                    Countdown = countdown,
                    Timer = timer,
                    Quantity = quantity,
                    Odds = odds
                }
            end
        end
    end
    
    -- Search all descendants
    for _, gui in ipairs(playerGui:GetChildren()) do
        if gui:IsA("ScreenGui") or gui:IsA("Frame") then
            local hasEventElements = false
            for _, child in ipairs(gui:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    local text = child.Text:lower()
                    if text:find("lochness") or text:find("event") or text:find("timer") or text:find("countdown") then
                        hasEventElements = true
                        break
                    end
                end
            end
            if hasEventElements then
                return { gui = gui }
            end
        end
    end
    
    return nil
end

function UpdateEventStats()
    local guiData = GetEventGUI()
    
    if not guiData then
        return false, "Event GUI not found"
    end
    
    local countdownText = "N/A"
    local timerText = "N/A"
    local quantityText = "N/A"
    local oddsText = "N/A"
    
    if guiData.Countdown then
        countdownText = guiData.Countdown.ContentText or guiData.Countdown.Text or "N/A"
    end
    if guiData.Timer then
        timerText = guiData.Timer.ContentText or guiData.Timer.Text or "N/A"
    end
    if guiData.Quantity then
        quantityText = guiData.Quantity.ContentText or guiData.Quantity.Text or "N/A"
    end
    if guiData.Odds then
        oddsText = guiData.Odds.ContentText or guiData.Odds.Text or "N/A"
    end
    
    local isEventActive = timerText:find("M") and timerText:find("S") and not timerText:match("^0M 0S")
    
    return isEventActive, {
        countdown = countdownText,
        timer = timerText,
        quantity = quantityText,
        odds = oddsText
    }
end

-- Ruin Door status checking
local RUIN_DOOR_STATUS = "UNKNOWN"

function GetRuinDoorStatus()
    -- This would check for specific door objects or UI indicators
    -- Implementation depends on actual game structure
    return RUIN_DOOR_STATUS
end

function CheckRuinDoorRequirement()
    -- Check if player has the required items to unlock ruin door
    local inventory = require(script.Parent.inventory)
    local fishData = inventory.ScanInventory()
    
    -- Example: Check for specific fish types
    local hasRequiredFish = false
    for _, item in ipairs(fishData.items) do
        if item.Rarity:upper() == "SECRET" then
            hasRequiredFish = true
            break
        end
    end
    
    return hasRequiredFish
end

return {
    GetEventGUI = GetEventGUI,
    UpdateEventStats = UpdateEventStats,
    GetRuinDoorStatus = GetRuinDoorStatus,
    CheckRuinDoorRequirement = CheckRuinDoorRequirement
}