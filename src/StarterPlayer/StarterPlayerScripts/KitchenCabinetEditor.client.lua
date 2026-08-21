-- Blueprint 3D Studio - Kitchen Cabinets
-- Runtime whole-cabinet selection + Width Resize / Mirror / Rotate.
-- IMPORTANT: this client NEVER creates or duplicates cabinet models.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("KitchenCabinetRemotes")
local editEvent = remotes:WaitForChild("EditCabinet")

local selectedModel = nil
local SNAP = 0.25
local dragStartWidth = nil
local dragStartProxyCFrame = nil
local dragStartProxySize = nil
local dragSide = nil
local dragPreviewWidth = nil

local highlight = Instance.new("Highlight")
highlight.Name = "KitchenCabinetSelection"
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.FillTransparency = 0.88
highlight.OutlineTransparency = 0
highlight.Enabled = false
highlight.Parent = workspace.CurrentCamera

-- Client-only proxy for resize handles. During drag ONLY this proxy changes.
-- The real cabinet is transformed once on release so geometry never accumulates errors.
local handleProxy = Instance.new("Part")
handleProxy.Name = "KitchenCabinetWidthHandleProxy"
handleProxy.Anchored = true
handleProxy.CanCollide = false
handleProxy.CanTouch = false
handleProxy.CanQuery = false
handleProxy.Transparency = 1
handleProxy.Size = Vector3.new(1,1,1)
handleProxy.Parent = workspace

local widthHandles = Instance.new("Handles")
widthHandles.Name = "KitchenCabinetWidthHandles"
widthHandles.Style = Enum.HandlesStyle.Resize
widthHandles.Faces = Faces.new(Enum.NormalId.Left, Enum.NormalId.Right)
widthHandles.Adornee = handleProxy
widthHandles.Visible = false
widthHandles.Parent = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "KitchenCabinetEditorGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Name = "EditorPanel"
frame.Size = UDim2.fromOffset(280, 390)
frame.Position = UDim2.new(1, -300, 0, 90)
frame.BackgroundColor3 = Color3.fromRGB(31,31,34)
frame.BorderSizePixel = 0
frame.Visible = true
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

local dragHelp=makeLabel("Select cabinet, then drag LEFT / RIGHT handle",32)
dragHelp.TextColor3=Color3.fromRGB(165,190,235)
dragHelp.TextWrapped=true

local function numericRow(caption,default,editable)
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
    box.BackgroundColor3=editable == false and Color3.fromRGB(39,39,42) or Color3.fromRGB(48,48,52)
    box.BorderSizePixel=0
    box.TextColor3=editable == false and Color3.fromRGB(145,145,150) or Color3.fromRGB(245,245,247)
    box.Font=Enum.Font.Gotham
    box.TextSize=14
    box.ClearTextOnFocus=false
    box.Text=tostring(default)
    box.TextEditable=editable ~= false
    box.Parent=row
    local c=Instance.new("UICorner")
    c.CornerRadius=UDim.new(0,7)
    c.Parent=box
    return box
end

local widthBox=numericRow("Width", "24.00", true)
local heightBox=numericRow("Height", "34.50", false)
local depthBox=numericRow("Depth", "24.00", false)

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

local resizeButton=makeButton("Set Exact Width")
local mirrorButton=makeButton("Mirror Left / Right")
local rotateButton=makeButton("Rotate 90°")

local function looksLikeCabinet(model)
    if not model or not model:IsA("Model") then return false end
    if model:GetAttribute("KitchenCabinet") == true then return true end
    if model:GetAttribute("WidthInches") ~= nil then return true end
    local upper=string.upper(model.Name)
    if string.match(upper,"^B%d+") or string.find(upper,"SHAKER",1,true) then return true end
    local left=model:FindFirstChild("LeftSide",true)
    local right=model:FindFirstChild("RightSide",true)
    return left and right and left:IsA("BasePart") and right:IsA("BasePart")
end

local function resolveCabinet(instance)
    local current=instance
    local best=nil
    while current and current ~= workspace do
        if current:IsA("Model") and looksLikeCabinet(current) then best=current end
        current=current.Parent
    end
    return best
end

local function syncHandleProxy(model)
    if not model or not model.Parent then
        widthHandles.Visible=false
        return
    end
    local boxCf,size=model:GetBoundingBox()
    handleProxy.CFrame=boxCf
    handleProxy.Size=size
    widthHandles.Visible=true
end

local function refreshFields(model)
    local _,size=model:GetBoundingBox()
    widthBox.Text=string.format("%.2f",model:GetAttribute("WidthInches") or size.X)
    heightBox.Text=string.format("%.2f",model:GetAttribute("HeightInches") or size.Y)
    depthBox.Text=string.format("%.2f",model:GetAttribute("DepthInches") or size.Z)
    selectedLabel.Text="Selected: "..model.Name
    syncHandleProxy(model)
end

local function selectCabinet(model)
    selectedModel=model
    highlight.Adornee=model
    highlight.Enabled=model ~= nil
    if model then
        statusLabel.Text="Whole cabinet selected"
        statusLabel.TextColor3=Color3.fromRGB(145,210,160)
        editEvent:FireServer(model,"register")
        task.delay(0.05,function()
            if selectedModel==model and model.Parent then refreshFields(model) end
        end)
    else
        widthHandles.Visible=false
        statusLabel.Text="Editor ready - click any cabinet part"
        statusLabel.TextColor3=Color3.fromRGB(145,210,160)
        selectedLabel.Text="No cabinet selected"
    end
end

mouse.Button1Down:Connect(function()
    if UserInputService:GetFocusedTextBox() then return end
    if dragSide then return end
    local target=mouse.Target
    if not target then selectCabinet(nil) return end
    local cabinet=resolveCabinet(target)
    if cabinet then
        selectCabinet(cabinet)
    else
        statusLabel.Text="Clicked object is not recognized as a cabinet"
        statusLabel.TextColor3=Color3.fromRGB(230,180,120)
        selectCabinet(nil)
    end
end)

local function snapWidth(value)
    return math.floor((value / SNAP) + 0.5) * SNAP
end

widthHandles.MouseButton1Down:Connect(function(face)
    if not selectedModel then return end
    if face ~= Enum.NormalId.Left and face ~= Enum.NormalId.Right then return end

    local _,size=selectedModel:GetBoundingBox()
    dragStartWidth=selectedModel:GetAttribute("WidthInches") or size.X
    dragStartProxyCFrame=handleProxy.CFrame
    dragStartProxySize=handleProxy.Size
    dragSide=face == Enum.NormalId.Right and "Right" or "Left"
    dragPreviewWidth=dragStartWidth
    statusLabel.Text="Dragging width preview..."
end)

widthHandles.MouseDrag:Connect(function(face,distance)
    if not selectedModel or not dragStartWidth or not dragSide then return end

    -- Roblox Handles distance is measured outward from whichever face is dragged,
    -- so positive distance means wider on BOTH left and right handles.
    local target=snapWidth(dragStartWidth + distance)
    target=math.clamp(target,7,44)
    dragPreviewWidth=target
    widthBox.Text=string.format("%.2f",target)
    statusLabel.Text=string.format("Preview width %.2f in",target)

    -- Preview only. Keep the opposite edge fixed visually.
    local delta=target-dragStartWidth
    local sign=dragSide=="Right" and 1 or -1
    handleProxy.Size=Vector3.new(target,dragStartProxySize.Y,dragStartProxySize.Z)
    handleProxy.CFrame=dragStartProxyCFrame + dragStartProxyCFrame.RightVector*(delta*0.5*sign)
end)

widthHandles.MouseButton1Up:Connect(function()
    if not selectedModel or not dragSide then return end

    local finalWidth=dragPreviewWidth or dragStartWidth
    local finalSide=dragSide

    -- Clear drag state before server mutation so normal selection logic cannot
    -- accidentally treat the transformation as another drag step.
    dragStartWidth=nil
    dragStartProxyCFrame=nil
    dragStartProxySize=nil
    dragPreviewWidth=nil
    dragSide=nil

    if finalWidth then
        -- ONE authoritative geometry operation. This prevents the repeated
        -- center-mass transforms that previously produced the L-shaped cabinet.
        editEvent:FireServer(selectedModel,"resizeWidthFromSide",{width=finalWidth,side=finalSide})
    end

    task.delay(0.15,function()
        if selectedModel and selectedModel.Parent then
            refreshFields(selectedModel)
            statusLabel.Text="Width resize complete"
        end
    end)
end)

resizeButton.MouseButton1Click:Connect(function()
    if not selectedModel then return end
    local w=tonumber(widthBox.Text)
    if not w then
        statusLabel.Text="Enter a valid width"
        return
    end
    editEvent:FireServer(selectedModel,"resize",{width=w,height=34.5,depth=24})
    task.delay(0.15,function()
        if selectedModel and selectedModel.Parent then refreshFields(selectedModel) end
    end)
end)

mirrorButton.MouseButton1Click:Connect(function()
    if selectedModel then
        editEvent:FireServer(selectedModel,"mirrorX")
        task.delay(0.1,function() if selectedModel and selectedModel.Parent then syncHandleProxy(selectedModel) end end)
    end
end)

rotateButton.MouseButton1Click:Connect(function()
    if selectedModel then
        editEvent:FireServer(selectedModel,"rotate90")
        task.delay(0.1,function() if selectedModel and selectedModel.Parent then syncHandleProxy(selectedModel) end end)
    end
end)

print("KitchenCabinetEditor.client loaded - safe width drag preview active")
