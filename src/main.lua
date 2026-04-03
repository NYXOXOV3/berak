-- Main entry point - loads all UI modules
local init = require(script.Parent.init)
local WindUI = init.WindUI

-- Element registry for config saving
local ElementRegistry = {}

function Reg(id, element)
    ElementRegistry[id] = element
    return element
end

-- Load UI tab modules
local player_tab = require(script.Parent.src.ui.player_tab)
local fishing_tab = require(script.Parent.src.ui.fishing_tab)
local auto_tab = require(script.Parent.src.ui.auto_tab)
local teleport_tab = require(script.Parent.src.ui.teleport_tab)
local shop_tab = require(script.Parent.src.ui.shop_tab)
local events_tab = require(script.Parent.src.ui.events_tab)
local tools_tab = require(script.Parent.src.ui.tools_tab)
local webhook_tab = require(script.Parent.src.ui.webhook_tab)
local config_tab = require(script.Parent.src.ui.config_tab)

-- Initialize all tabs with Window and Reg
player_tab(WindUI, Reg)
fishing_tab(WindUI, Reg)
auto_tab(WindUI, Reg)
teleport_tab(WindUI, Reg)
shop_tab(WindUI, Reg)
events_tab(WindUI, Reg)
tools_tab(WindUI, Reg)
webhook_tab(WindUI, Reg)
config_tab(WindUI, Reg)

-- About tab (static content)
local about = WindUI:Tab({
    Title = "About",
    Icon = "solar:info-square-bold-duotone",
    Locked = false,
})

about:Section({
    Title = "Join Discord Server Noxius Community",
    TextSize = 20,
})

about:Paragraph({
    Title = "Noxius Community",
    Desc = "Join Our Community Discord Server to get the latest updates, support, and connect with other users!",
    Image = "rbxassetid://77194008928196",
    ImageSize = 24,
    Buttons = {{
        Title = "Copy Link",
        Icon = "solar:link-bold-duotone",
        Callback = function()
            setclipboard("https://discord.gg/noxius")
            WindUI:Notify({
                Title = "Link Disalin!",
                Content = "Link Discord Noxius berhasil disalin.",
                Duration = 3,
                Icon = "solar:copy-bold-duotone",
            })
        end,
    }}
})

about:Divider()
 
about:Section({
    Title = "What's New?",
    TextSize = 24,
    FontWeight = Enum.FontWeight.SemiBold,
})

about:Image({
    Image = "rbxassetid://77194008928196",
    AspectRatio = "16:9",
    Radius = 9,
})

about:Space()

about:Paragraph({
    Title = "Version 1.0.0",
    Desc = "- 28 Nov 2025 Release Premium Version",
})

about:Paragraph({
    Title = "Version 1.0.1",
    Desc = "[~] Fix stuck at farming artifact\n[~] Fix auto sell issue\n[~] Fix Legit Fishing Stuck Issue\n[~] Fix & change method kaitun mode\n[+] Add missing mutation\n[+] add auto trade by coin\n[+] Add filter by name at webhook",
})

about:Paragraph({
    Title = "Version 1.0.2",
    Desc = "[~] Fix 3D Rendering Force Close Issue\n[~] Fix Teleport & Freeze Detect Old Position\n[~] Improve Load UI\n[+] Add Freeze Player\n[+] Add Detect Enchant Perfection On Blatant Mode\n[+] Add Auto Spawn 9 Totem\n[+] Bring Back 3 Setting On Blatant Mode",
})

-- Keybind setup
WindUI:SetToggleKey(Enum.KeyCode.F)

print("Noxius Hub modular version loaded successfully!")
print("ElementRegistry has " .. #ElementRegistry .. " registered elements")