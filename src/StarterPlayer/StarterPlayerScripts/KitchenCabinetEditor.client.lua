-- Blueprint 3D Studio - Kitchen Cabinets
-- Runtime whole-cabinet selection + Width Resize / Move+Snap / Mirror / Rotate.
-- IMPORTANT: this client NEVER creates or duplicates cabinet models.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("KitchenCabinetRemotes")
local editEvent = remotes:WaitForChild("EditCabinet")

local selectedModel = nil
local SNAP = 0.25
local CABINET_SNAP = 1.0
local dragStartWidth, dragStartProxyCFrame, dragStartProxySize, dragSide, dragPreviewWidth
local moveMode = false
local moveConnection = nil
local moveStartY = nil

local highlight = Instance.new("Highlight")
highlight.Name = "KitchenCabinetSelection"
highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlight.FillTransparency = 0.88
highlight.OutlineTransparency = 0
highlight.Enabled = false
highlight.Parent = workspace.CurrentCamera

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
gui.DisplayOrder = 20
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Name = "EditorPanel"
frame.Size = UDim2.fromOffset(280, 435)
frame.Position = UDim2.new(1,-300,0,90)
frame.BackgroundColor3 = Color3.fromRGB(31,31,34)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner",frame).CornerRadius=UDim.new(0,10)
local padding=Instance.new("UIPadding",frame)
padding.PaddingTop=UDim.new(0,12); padding.PaddingBottom=UDim.new(0,12); padding.PaddingLeft=UDim.new(0,12); padding.PaddingRight=UDim.new(0,12)
local layout=Instance.new("UIListLayout",frame); layout.Padding=UDim.new(0,7); layout.SortOrder=Enum.SortOrder.LayoutOrder

local function makeLabel(text,height)
    local l=Instance.new("TextLabel",frame); l.Size=UDim2.new(1,0,0,height or 24); l.BackgroundTransparency=1
    l.TextColor3=Color3.fromRGB(235,235,238); l.Font=Enum.Font.Gotham; l.TextSize=14; l.TextXAlignment=Enum.TextXAlignment.Left; l.Text=text
    return l
end
local title=makeLabel("Cabinet Transform",28); title.Font=Enum.Font.GothamBold; title.TextSize=17
local statusLabel=makeLabel("Editor ready - click any cabinet part",22); statusLabel.TextColor3=Color3.fromRGB(145,210,160)
local selectedLabel=makeLabel("No cabinet selected",22); selectedLabel.TextColor3=Color3.fromRGB(180,180,185)
local dragHelp=makeLabel("Resize handles: LEFT / RIGHT only",24); dragHelp.TextColor3=Color3.fromRGB(165,190,235)

local function numericRow(caption,default,editable)
    local row=Instance.new("Frame",frame); row.Size=UDim2.new(1,0,0,34); row.BackgroundTransparency=1
    local lbl=Instance.new("TextLabel",row); lbl.Size=UDim2.new(.38,0,1,0); lbl.BackgroundTransparency=1; lbl.Text=caption
    lbl.TextColor3=Color3.fromRGB(225,225,228); lbl.Font=Enum.Font.Gotham; lbl.TextSize=13; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local box=Instance.new("TextBox",row); box.Size=UDim2.new(.62,0,1,0); box.Position=UDim2.new(.38,0,0,0); box.BorderSizePixel=0
    box.BackgroundColor3=editable==false and Color3.fromRGB(39,39,42) or Color3.fromRGB(48,48,52)
    box.TextColor3=editable==false and Color3.fromRGB(145,145,150) or Color3.fromRGB(245,245,247)
    box.Font=Enum.Font.Gotham; box.TextSize=14; box.ClearTextOnFocus=false; box.Text=tostring(default); box.TextEditable=editable~=false
    Instance.new("UICorner",box).CornerRadius=UDim.new(0,7); return box
end
local widthBox=numericRow("Width","24.00",true)
local heightBox=numericRow("Height","34.50",false)
local depthBox=numericRow("Depth","24.00",false)

local function makeButton(text)
    local b=Instance.new("TextButton",frame); b.Size=UDim2.new(1,0,0,34); b.BackgroundColor3=Color3.fromRGB(64,64,70); b.BorderSizePixel=0
    b.TextColor3=Color3.fromRGB(245,245,247); b.Font=Enum.Font.GothamMedium; b.TextSize=13; b.Text=text
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7); return b
end
local resizeButton=makeButton("Set Exact Width")
local moveButton=makeButton("Move + Snap")
local mirrorButton=makeButton("Mirror Left / Right")
local rotateButton=makeButton("Rotate 90°")

local function looksLikeCabinet(model)
    if not model or not model:IsA("Model") then return false end
    if model:GetAttribute("KitchenCabinet")==true or model:GetAttribute("WidthInches")~=nil then return true end
    local upper=string.upper(model.Name)
    if string.match(upper,"^B%d+") or string.find(upper,"SHAKER",1,true) then return true end
    local left=model:FindFirstChild("LeftSide",true); local right=model:FindFirstChild("RightSide",true)
    return left and right and left:IsA("BasePart") and right:IsA("BasePart")
end
local function resolveCabinet(instance)
    local current=instance; local best=nil
    while current and current~=workspace do if current:IsA("Model") and looksLikeCabinet(current) then best=current end; current=current.Parent end
    return best
end
local function syncHandleProxy(model)
    if not model or not model.Parent then widthHandles.Visible=false; return end
    local cf,size=model:GetBoundingBox(); handleProxy.CFrame=cf; handleProxy.Size=size; widthHandles.Visible=not moveMode
end
local function refreshFields(model)
    local _,size=model:GetBoundingBox()
    widthBox.Text=string.format("%.2f",model:GetAttribute("WidthInches") or size.X)
    heightBox.Text=string.format("%.2f",model:GetAttribute("HeightInches") or size.Y)
    depthBox.Text=string.format("%.2f",model:GetAttribute("DepthInches") or size.Z)
    selectedLabel.Text="Selected: "..model.Name; syncHandleProxy(model)
end
local function stopMove()
    moveMode=false
    if moveConnection then moveConnection:Disconnect(); moveConnection=nil end
    moveButton.Text="Move + Snap"
    if selectedModel then syncHandleProxy(selectedModel) end
end
local function selectCabinet(model)
    stopMove(); selectedModel=model; highlight.Adornee=model; highlight.Enabled=model~=nil
    if model then
        statusLabel.Text="Whole cabinet selected"; statusLabel.TextColor3=Color3.fromRGB(145,210,160); editEvent:FireServer(model,"register")
        task.delay(.05,function() if selectedModel==model and model.Parent then refreshFields(model) end end)
    else widthHandles.Visible=false; statusLabel.Text="Editor ready - click any cabinet part"; selectedLabel.Text="No cabinet selected" end
end

local function snap(v,step) return math.floor(v/step+.5)*step end
local function cabinetBounds(model)
    local cf,size=model:GetBoundingBox(); return cf,size
end
local function snapToCabinets(model,target)
    local cf,size=cabinetBounds(model); local halfX=size.X/2; local halfZ=size.Z/2
    local best=target; local bestDist=CABINET_SNAP
    for _,other in ipairs(workspace:GetDescendants()) do
        if other:IsA("Model") and other~=model and looksLikeCabinet(other) then
            local ocf,osize=cabinetBounds(other)
            if math.abs(target.Z-ocf.Position.Z) <= math.max(size.Z,osize.Z)*.5 then
                local candidates={ocf.Position.X-(osize.X/2)-halfX, ocf.Position.X+(osize.X/2)+halfX}
                for _,x in ipairs(candidates) do local d=math.abs(target.X-x); if d<bestDist then bestDist=d; best=Vector3.new(x,target.Y,target.Z) end end
            end
            if math.abs(target.X-ocf.Position.X) <= math.max(size.X,osize.X)*.5 then
                local candidates={ocf.Position.Z-(osize.Z/2)-halfZ, ocf.Position.Z+(osize.Z/2)+halfZ}
                for _,z in ipairs(candidates) do local d=math.abs(target.Z-z); if d<bestDist then bestDist=d; best=Vector3.new(target.X,target.Y,z) end end
            end
        end
    end
    return best
end

mouse.Button1Down:Connect(function()
    if UserInputService:GetFocusedTextBox() or dragSide or moveMode then return end
    local target=mouse.Target; if not target then selectCabinet(nil); return end
    local cabinet=resolveCabinet(target); if cabinet then selectCabinet(cabinet) else selectCabinet(nil) end
end)

widthHandles.MouseButton1Down:Connect(function(face)
    if not selectedModel or (face~=Enum.NormalId.Left and face~=Enum.NormalId.Right) then return end
    local _,size=selectedModel:GetBoundingBox(); dragStartWidth=selectedModel:GetAttribute("WidthInches") or size.X
    dragStartProxyCFrame=handleProxy.CFrame; dragStartProxySize=handleProxy.Size; dragSide=face==Enum.NormalId.Right and "Right" or "Left"; dragPreviewWidth=dragStartWidth
end)
widthHandles.MouseDrag:Connect(function(_,distance)
    if not selectedModel or not dragStartWidth or not dragSide then return end
    local target=math.clamp(snap(dragStartWidth+distance,SNAP),7,44); dragPreviewWidth=target; widthBox.Text=string.format("%.2f",target)
    local delta=target-dragStartWidth; local sign=dragSide=="Right" and 1 or -1
    handleProxy.Size=Vector3.new(target,dragStartProxySize.Y,dragStartProxySize.Z); handleProxy.CFrame=dragStartProxyCFrame+dragStartProxyCFrame.RightVector*(delta*.5*sign)
end)
widthHandles.MouseButton1Up:Connect(function()
    if not selectedModel or not dragSide then return end
    local finalWidth=dragPreviewWidth or dragStartWidth; local finalSide=dragSide
    dragStartWidth=nil; dragStartProxyCFrame=nil; dragStartProxySize=nil; dragPreviewWidth=nil; dragSide=nil
    editEvent:FireServer(selectedModel,"resizeWidthFromSide",{width=finalWidth,side=finalSide})
    task.delay(.15,function() if selectedModel and selectedModel.Parent then refreshFields(selectedModel); statusLabel.Text="Width resize complete" end end)
end)

resizeButton.MouseButton1Click:Connect(function()
    if not selectedModel then return end; local w=tonumber(widthBox.Text); if not w then return end
    editEvent:FireServer(selectedModel,"resize",{width=w,height=34.5,depth=24}); task.delay(.15,function() if selectedModel then refreshFields(selectedModel) end end)
end)

moveButton.MouseButton1Click:Connect(function()
    if not selectedModel then statusLabel.Text="Select a cabinet first"; return end
    if moveMode then stopMove(); statusLabel.Text="Move cancelled"; return end
    moveMode=true; widthHandles.Visible=false; moveButton.Text="Moving... click to place"
    local pivot=selectedModel:GetPivot(); moveStartY=pivot.Position.Y
    statusLabel.Text="Move cabinet - snaps to 1/4 in grid and nearby cabinets"
    moveConnection=RunService.RenderStepped:Connect(function()
        if not selectedModel or not selectedModel.Parent then stopMove(); return end
        local hit=mouse.Hit.Position
        local pos=Vector3.new(snap(hit.X,SNAP),moveStartY,snap(hit.Z,SNAP))
        pos=snapToCabinets(selectedModel,pos)
        local current=selectedModel:GetPivot(); local rx,ry,rz=current:ToOrientation()
        selectedModel:PivotTo(CFrame.new(pos)*CFrame.fromOrientation(rx,ry,rz))
    end)
end)

UserInputService.InputBegan:Connect(function(input,processed)
    if processed or not moveMode then return end
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        stopMove(); statusLabel.Text="Cabinet placed + snapped"; if selectedModel then syncHandleProxy(selectedModel) end
    elseif input.KeyCode==Enum.KeyCode.Escape then stopMove(); statusLabel.Text="Move ended" end
end)

mirrorButton.MouseButton1Click:Connect(function() if selectedModel then editEvent:FireServer(selectedModel,"mirrorX"); task.delay(.1,function() syncHandleProxy(selectedModel) end) end end)
rotateButton.MouseButton1Click:Connect(function() if selectedModel then editEvent:FireServer(selectedModel,"rotate90"); task.delay(.1,function() syncHandleProxy(selectedModel) end) end end)

print("KitchenCabinetEditor.client loaded - width resize + Move Snap active")
