-- Events Tab UI (Ancient Lochness, etc.)
local init = require(script.Parent.init)
local WindUI = init.WindUI
local events = require(script.Parent.api.events)
local players = require(script.Parent.api.players)
local Reg

return function(Window, registry)
    Reg = registry
    
    local Event = Window:Tab({
        Title = "Events",
        Icon = "calendar",
        Locked = false,
    })
    
    local EventSyncThread = nil
    local autoJoinEventActive = false
    local lastPositionBeforeEvent = nil
    local LOCHNESS_POS = CFrame.new(-1488.51196, 83.1732635, 1876.30298).Position
    local LOCHNESS_LOOK = CFrame.new(-1488.51196, 83.1732635, 1876.30298).LookVector
    
    local loknes = Event:Section({
        Title = "Ancient Lochness Event",
        TextSize = 20,
    })
    
    local CountdownParagraph = loknes:Paragraph({
        Title = "Event Countdown: Waiting...",
        Content = "Status: Mencoba sinkronisasi event...",
        Icon = "clock"
    })
    
    local StatsParagraph = loknes:Paragraph({
        Title = "Event Stats: N/A",
        Content = "Timer: N/A\nCaught: N/A\nChance: N/A",
        Icon = "trending-up"
    })
    
    local LochnessToggle
    
    local function UpdateEventStats()
        local gui = events.GetEventGUI()
        
        if not gui then
            CountdownParagraph:SetTitle("Event Countdown: GUI Not Found ❌")
            CountdownParagraph:SetDesc("Pastikan 'Event Tracker' sudah dimuat di workspace.")
            StatsParagraph:SetTitle("Event Stats: N/A")
            StatsParagraph:SetDesc("Timer: N/A\nCaught: N/A\nChance: N/A")
            return false
        end
        
        local countdownText = "N/A"
        local timerText = "N/A"
        local quantityText = "N/A"
        local oddsText = "N/A"
        
        if gui.Countdown then
            countdownText = gui.Countdown.ContentText or gui.Countdown.Text or "N/A"
        end
        if gui.Timer then
            timerText = gui.Timer.ContentText or gui.Timer.Text or "N/A"
        end
        if gui.Quantity then
            quantityText = gui.Quantity.ContentText or gui.Quantity.Text or "N/A"
        end
        if gui.Odds then
            oddsText = gui.Odds.ContentText or gui.Odds.Text or "N/A"
        end
        
        CountdownParagraph:SetTitle("Ancient Lochness Start In:")
        CountdownParagraph:SetDesc(countdownText)
        
        StatsParagraph:SetTitle("Ancient Lochness Stats")
        StatsParagraph:SetDesc(string.format("- Timer: %s\n- Caught: %s\n- Chance: %s",
            timerText, quantityText, oddsText))
        
        local isEventActive = timerText:find("M") and timerText:find("S") and not timerText:match("^0M 0S")
        
        return isEventActive
    end
    
    local function RunEventSyncLoop()
        if EventSyncThread then task.cancel(EventSyncThread) end
        
        EventSyncThread = task.spawn(function()
            local isTeleportedToEvent = false
            
            while true do
                local isEventActive = UpdateEventStats()
                
                if autoJoinEventActive then
                    if isEventActive and not isTeleportedToEvent then
                        if lastPositionBeforeEvent == nil then
                            local hrp = players.GetHRP()
                            if hrp then
                                lastPositionBeforeEvent = {Pos = hrp.Position, Look = hrp.CFrame.LookVector}
                                WindUI:Notify({ Title = "Posisi Disimpan", Content = "Posisi sebelum Event disimpan.", Duration = 2, Icon = "save" })
                            end
                        end
                        
                        players.TeleportToLookAt(LOCHNESS_POS, LOCHNESS_LOOK)
                        isTeleportedToEvent = true
                        WindUI:Notify({ Title = "Auto Join ON", Content = "Teleport ke Ancient Lochness.", Duration = 4, Icon = "zap" })
                        
                    elseif isTeleportedToEvent and not isEventActive and lastPositionBeforeEvent ~= nil then
                        WindUI:Notify({ Title = "Event Selesai", Content = "Menunggu 15 detik sebelum kembali...", Duration = 5, Icon = "clock" })
                        task.wait(15) 
                        
                        players.TeleportToLookAt(lastPositionBeforeEvent.Pos, lastPositionBeforeEvent.Look)
                        lastPositionBeforeEvent = nil
                        isTeleportedToEvent = false
                        WindUI:Notify({ Title = "Teleport Back", Content = "Kembali ke posisi semula.", Duration = 3, Icon = "repeat" })
                    end
                end
                
                task.wait(0.5)
            end
        end)
    end
    
    RunEventSyncLoop()
    
    local LochnessToggle = Reg("tloknes", loknes:Toggle({
        Title = "Auto Join Ancient Lochness Event",
        Desc = "Otomatis Teleport ke event saat aktif, dan kembali saat event berakhir.",
        Value = false,
        Callback = function(state)
            autoJoinEventActive = state
            if state then
                WindUI:Notify({ Title = "Auto Join ON", Content = "Mulai memantau event Ancient Lochness.", Duration = 3, Icon = "check" })
            else
                WindUI:Notify({ Title = "Auto Join OFF", Content = "Pemantauan dihentikan.", Duration = 3, Icon = "x" })
            end
        end
    }))
    
    Event:Divider()
end