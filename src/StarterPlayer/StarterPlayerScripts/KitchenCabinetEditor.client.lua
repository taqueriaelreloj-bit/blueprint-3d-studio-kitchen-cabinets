-- Blueprint 3D Studio - Kitchen Cabinets
-- Runtime cabinet selection + Resize / Mirror / Rotate panel.
-- This client NEVER creates cabinet models.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("KitchenCabinetRemotes")
local editEvent = remotes:WaitForChild("EditCabinet")

local selectedModel = nil
local highlight = Instance.new("Highlight")
highlight.Name = "KitchenCabinetSelection"
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.Enabled = false
highlight.Parent = workspace.CurrentCamera

local gui = Instance.new("ScreenGui")
gui.Name = "KitchenCabinetEditorGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "EditorPanel"
frame.Size = UDim2.fromOffset(270, 330)
frame.Position = UDim2.new(1, -290, 0, 90)
frame.BackgroundColor3 = Color3.fromRGB(31, 31, 34)
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = frame

local function label(text, height)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, height or 24)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(235,235,238)
    l.Font = Enum.Font.Gotham
    l.TextSize = 14
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Text = text
    l.Parent = frame
    return l
end

local title = label("Cabinet Transform", 28)
title.Font = Enum.Font.GothamBold
title.TextSize = 17

local selectedLabel = label("No cabinet selected", 22)
selectedLabel.TextColor3 = Color3.fromRGB(180,180,185)

local function numericRow(caption, default)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1,0,0,34)
    row.BackgroundTransparency = 1
    row.Parent = frame

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.38,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = caption
    lbl.TextColor3 = Color3.fromRGB(225,225,228)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.62,0,1,0)
    box.Position = UDim2.new(0.38,0,0,0)
    box.BackgroundColor3 = Color3.fromRGB(48,48,52)
    box.BorderSizePixel = 0
    box.TextColor3 = Color3.fromRGB(245,245,247)
    box.Font = Enum.Font.Gotham
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.Text = tostring(default)
    box.Parent = row
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,7)
    c.Parent = box
    return box
end

local widthBox = numericRow("Width", "24.00")
local heightBox = numericRow("Height", "34.50")
local depthBox = numericRow("Depth", "24.00")

local function button(text)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1,0,0,34)
    b.BackgroundColor3 = Color3.fromRGB(64,64,70)
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.fromRGB(245,245,247)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.Text = text
    b.Parent = frame
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,7)
    c.Parent = b
    return b
end

local resizeButton = button("Resize")
local mirrorButton = button("Mirror Left / Right")
local rotateButton = button("Rotate 90°")

local function resolveCabinet(instance)
    local current = instance
    while current and current ~= workspace do
        if current:IsA("Model") then
            local namedCabinet = string.match(string.upper(current.Name), "^B%d+") ~= nil
            if current:GetAttribute("KitchenCabinet") == true
                or current:GetAttribute("WidthInches") ~= nil
                or namedCabinet then
                return current
            end
        end
        current = current.Parent
    end
    return nil
end

local function refreshFields(model)
    local _, size = model:GetBoundingBox()
    widthBox.Text = string.format("%.2f", model:GetAttribute("WidthInches") or size.X)
    heightBox.Text = string.format("%.2f", model:GetAttribute("HeightInches") or size.Y)
    depthBox.Text = string.format("%.2f", model:GetAttribute("DepthInches") or size.Z)
    selectedLabel.Text = model.Name
end

local function selectCabinet(model)
    selectedModel = model
    highlight.Adornee = model
    highlight.Enabled = model ~= nil
    frame.Visible = model ~= nil
    if model then
        editEvent:FireServer(model, "register")
        refreshFields(model)
    end
end

mouse.Button1Down:Connect(function()
    if UserInputService:GetFocusedTextBox() then return end
    local target = mouse.Target
    if not target then
        selectCabinet(nil)
        return
    end
    selectCabinet(resolveCabinet(target))
end)

resizeButton.MouseButton1Click:Connect(function()
    if not selectedModel then return end
    local w = tonumber(widthBox.Text)
    local h = tonumber(heightBox.Text)
    local d = tonumber(depthBox.Text)
    if not (w and h and d) then return end
    editEvent:FireServer(selectedModel, "resize", {width=w, height=h, depth=d})
    task.delay(0.15, function()
        if selectedModel and selectedModel.Parent then refreshFields(selectedModel) end
    end)
end)

mirrorButton.MouseButton1Click:Connect(function()
    if selectedModel then editEvent:FireServer(selectedModel, "mirrorX") end
end)

rotateButton.MouseButton1Click:Connect(function()
    if selectedModel then editEvent:FireServer(selectedModel, "rotate90") end
end)
