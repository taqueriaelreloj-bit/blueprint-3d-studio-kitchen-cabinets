-- Blueprint 3D Studio - Kitchen Cabinets
-- Runtime whole-cabinet selection + Resize / Mirror / Rotate panel.
-- IMPORTANT: this client NEVER creates or duplicates cabinet models.

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
highlight.FillTransparency = 0.88
highlight.OutlineTransparency = 0
highlight.Enabled = false
highlight.Parent = workspace.CurrentCamera

local gui = Instance.new("ScreenGui")
gui.Name = "KitchenCabinetEditorGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "EditorPanel"
frame.Size = UDim2.fromOffset(280, 360)
frame.Position = UDim2.new(1, -300, 0, 90)
frame.BackgroundColor3 = Color3.fromRGB(31,31,34)
frame.BorderSizePixel = 0
frame.Visible = true -- Always visible so we can verify the LocalScript is active.
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,10)
corner.Parent = frame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0,12)
padding.PaddingBottom = UDim.new(0,12)
padding.PaddingLeft = UDim.new(0,12)
padding.PaddingRight = UDim.new(0,12)
padding.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0,7)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = frame

local function makeLabel(text,height)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(1,0,0,height or 24)
    l.BackgroundTransparency=1
    l.TextColor3=Color3.fromRGB(235,235,238)
    l.Font=Enum.Font.Gotham
    l.TextSize=14
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.Text=text
    l.Parent=frame
    return l
end

local title=makeLabel("Cabinet Transform",28)
title.Font=Enum.Font.GothamBold
title.TextSize=17

local statusLabel=makeLabel("Editor ready - click any cabinet part",22)
statusLabel.TextColor3=Color3.fromRGB(145,210,160)

local selectedLabel=makeLabel("No cabinet selected",22)
selectedLabel.TextColor3=Color3.fromRGB(180,180,185)

local function numericRow(caption,default)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,34)
    row.BackgroundTransparency=1
    row.Parent=frame

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(0.38,0,1,0)
    lbl.BackgroundTransparency=1
    lbl.Text=caption
    lbl.TextColor3=Color3.fromRGB(225,225,228)
    lbl.Font=Enum.Font.Gotham
    lbl.TextSize=13
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.Parent=row

    local box=Instance.new("TextBox")
    box.Size=UDim2.new(0.62,0,1,0)
    box.Position=UDim2.new(0.38,0,0,0)
    box.BackgroundColor3=Color3.fromRGB(48,48,52)
    box.BorderSizePixel=0
    box.TextColor3=Color3.fromRGB(245,245,247)
    box.Font=Enum.Font.Gotham
    box.TextSize=14
    box.ClearTextOnFocus=false
    box.Text=tostring(default)
    box.Parent=row
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,7)
    c.Parent=box
    return box
end

local widthBox=numericRow("Width", "24.00")
local heightBox=numericRow("Height", "34.50")
local depthBox=numericRow("Depth", "24.00")

local function makeButton(text)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(1,0,0,34)
    b.BackgroundColor3=Color3.fromRGB(64,64,70)
    b.BorderSizePixel=0
    b.TextColor3=Color3.fromRGB(245,245,247)
    b.Font=Enum.Font.GothamMedium
    b.TextSize=13
    b.Text=text
    b.Parent=frame
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,7)
    c.Parent=b
    return b
end

local resizeButton=makeButton("Resize")
local mirrorButton=makeButton("Mirror Left / Right")
local rotateButton=makeButton("Rotate 90°")

-- Recognizes current corrected cabinet models without requiring us to regenerate them.
local function looksLikeCabinet(model)
    if not model or not model:IsA("Model") then return false end
    if model:GetAttribute("KitchenCabinet") == true then return true end
    if model:GetAttribute("WidthInches") ~= nil then return true end

    local upper=string.upper(model.Name)
    if string.match(upper,"^B%d+") or string.find(upper,"SHAKER",1,true) then
        return true
    end

    -- Structural fallback for existing Roblox-built cabinets.
    local left=model:FindFirstChild("LeftSide",true)
    local right=model:FindFirstChild("RightSide",true)
    if left and right and left:IsA("BasePart") and right:IsA("BasePart") then
        return true
    end
    return false
end

local function resolveCabinet(instance)
    local current=instance
    local best=nil
    while current and current ~= workspace do
        if current:IsA("Model") and looksLikeCabinet(current) then
            best=current
        end
        current=current.Parent
    end
    return best
end

local function refreshFields(model)
    local _,size=model:GetBoundingBox()
    widthBox.Text=string.format("%.2f",model:GetAttribute("WidthInches") or size.X)
    heightBox.Text=string.format("%.2f",model:GetAttribute("HeightInches") or size.Y)
    depthBox.Text=string.format("%.2f",model:GetAttribute("DepthInches") or size.Z)
    selectedLabel.Text="Selected: "..model.Name
end

local function selectCabinet(model)
    selectedModel=model
    highlight.Adornee=model
    highlight.Enabled=model ~= nil
    if model then
        statusLabel.Text="Whole cabinet selected"
        statusLabel.TextColor3=Color3.fromRGB(145,210,160)
        editEvent:FireServer(model,"register")
        refreshFields(model)
    else
        statusLabel.Text="Editor ready - click any cabinet part"
        statusLabel.TextColor3=Color3.fromRGB(145,210,160)
        selectedLabel.Text="No cabinet selected"
    end
end

mouse.Button1Down:Connect(function()
    if UserInputService:GetFocusedTextBox() then return end
    local target=mouse.Target
    if not target then
        selectCabinet(nil)
        return
    end
    local cabinet=resolveCabinet(target)
    if cabinet then
        selectCabinet(cabinet)
    else
        statusLabel.Text="Clicked object is not recognized as a cabinet"
        statusLabel.TextColor3=Color3.fromRGB(230,180,120)
        selectCabinet(nil)
    end
end)

resizeButton.MouseButton1Click:Connect(function()
    if not selectedModel then return end
    local w,h,d=tonumber(widthBox.Text),tonumber(heightBox.Text),tonumber(depthBox.Text)
    if not (w and h and d) then
        statusLabel.Text="Enter valid numeric dimensions"
        return
    end
    editEvent:FireServer(selectedModel,"resize",{width=w,height=h,depth=d})
    task.delay(0.15,function()
        if selectedModel and selectedModel.Parent then refreshFields(selectedModel) end
    end)
end)

mirrorButton.MouseButton1Click:Connect(function()
    if selectedModel then editEvent:FireServer(selectedModel,"mirrorX") end
end)

rotateButton.MouseButton1Click:Connect(function()
    if selectedModel then editEvent:FireServer(selectedModel,"rotate90") end
end)

print("KitchenCabinetEditor.client loaded - whole-model selection active")
