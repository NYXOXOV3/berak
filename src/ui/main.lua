-- UI Main - Window setup and shared helpers
local init = require(script.Parent.init)
local WindUI = init.WindUI
local remotes = init.remotes

local Window = WindUI:CreateWindow({
    Title = "Noxius | Community",
    Author = "Noxius Fish It",
    Folder = "ftgshub",
    Icon = "solar:folder-2-bold-duotone",
    Theme = "Violet",
    IconSize = 44,
    NewElements = true,
    HideSearchBar = false,
    OpenButton = { Enabled = false },
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

-- Time/Runtime tags
local TimeTag = Window:Tag({
    Title = "00:00:00",
    Icon = "solar:clock-circle-bold-duotone",
    Color = Color3.fromHex("#1c1c1c"),
    Border = true,
})

local RuntimeTag = Window:Tag({
    Title = "00:00:00",
    Icon = "solar:stopwatch-bold-duotone",
    Color = Color3.fromHex("#1c1c1c"),
    Border = true,
})

local StartTime = tick()

game:GetService("RunService").Heartbeat:Connect(function()
    TimeTag:SetTitle(os.date("%H:%M:%S"))
    
    local Elapsed = tick() - StartTime
    local Hours = math.floor(Elapsed / 3600)
    local Minutes = math.floor((Elapsed % 3600) / 60)
    local Seconds = math.floor(Elapsed % 60)
    
    RuntimeTag:SetTitle(string.format("%02d:%02d:%02d", Hours, Minutes, Seconds))
end)

Window:EditOpenButton({Enabled = false})

-- Custom toggle button (existing code)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoxiusCustomToggle"
ScreenGui.Parent = game:GetService("CoreGui")

local ButtonRezise = Instance.new("ImageButton")
ButtonRezise.Parent = ScreenGui
ButtonRezise.BorderSizePixel = 0
ButtonRezise.Draggable = true
ButtonRezise.BackgroundColor3 = Color3.fromRGB(200, 0, 255)
ButtonRezise.Image = "rbxassetid://77194008928196"
ButtonRezise.Size = UDim2.new(0, 47, 0, 47)
ButtonRezise.Position = UDim2.new(0.13, 0, 0.03, 0)
ButtonRezise.Visible = true

local corner = Instance.new("UICorner", ButtonRezise)
corner.CornerRadius = UDim.new(0, 8)

local neon = Instance.new("UIStroke", ButtonRezise)
neon.Thickness = 2
neon.Color = Color3.fromRGB(200, 0, 255)
neon.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local windowVisible = true
ButtonRezise.MouseButton1Click:Connect(function()
    if windowVisible then
        Window:Close()
    else
        Window:Open()
    end
    windowVisible = not windowVisible
end)

return {
    Window = Window,
    TimeTag = TimeTag,
    RuntimeTag = RuntimeTag,
    ScreenGui = ScreenGui,
    ButtonRezise = ButtonRezise
}