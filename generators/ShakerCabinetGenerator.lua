-- Shaker Cabinet Generator for Roblox Studio
-- Generates a parametric family of base cabinets.
-- Units: 1 stud = 1 inch

local CABINET_WIDTHS = {9,12,15,18,21,24,27,30,33,36}

local D = 24
local H = 34.5
local SIDE = 0.75
local BACK = 0.50
local TOE_H = 4.5
local TOE_DEPTH = 3.0

local REVEAL_SIDE = 0.5
local GAP_DRAWER_DOOR = 0.5

local DRAWER_H = 6.25
local SHAKER_RAIL = 2.25
local PANEL_DEPTH = 0.25

local CABINET_COLOR = Color3.fromRGB(155, 152, 147)
local INTERIOR_COLOR = Color3.fromRGB(194, 154, 105)
local HARDWARE_COLOR = Color3.fromRGB(115, 115, 112)

local function part(parent, name, size, pos, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Anchored = true
	p.CanCollide = true
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function shakerFront(parent, name, width, height, centerY, z, color)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent

	local rail = math.min(SHAKER_RAIL, math.max(1.5, width * 0.12))

	part(model,"CenterPanel",
		Vector3.new(math.max(0.5,width-rail*2), math.max(0.5,height-rail*2), PANEL_DEPTH),
		Vector3.new(0,centerY,z+PANEL_DEPTH/2), color)

	part(model,"LeftStile",
		Vector3.new(rail,height,0.75),
		Vector3.new(-width/2+rail/2,centerY,z),color)

	part(model,"RightStile",
		Vector3.new(rail,height,0.75),
		Vector3.new(width/2-rail/2,centerY,z),color)

	part(model,"TopRail",
		Vector3.new(math.max(0.5,width-rail*2),rail,0.75),
		Vector3.new(0,centerY+height/2-rail/2,z),color)

	part(model,"BottomRail",
		Vector3.new(math.max(0.5,width-rail*2),rail,0.75),
		Vector3.new(0,centerY-height/2+rail/2,z),color)

	return model
end

local function horizontalPull(parent, name, length, y, z)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	part(m,"Bar",Vector3.new(length,0.35,0.35),Vector3.new(0,y,z),HARDWARE_COLOR)
	part(m,"PostLeft",Vector3.new(0.30,0.30,0.75),Vector3.new(-length/2+0.7,y,z+0.30),HARDWARE_COLOR)
	part(m,"PostRight",Vector3.new(0.30,0.30,0.75),Vector3.new(length/2-0.7,y,z+0.30),HARDWARE_COLOR)
end

local function generateCabinet(W, offsetX)
	local cabinet = Instance.new("Model")
	cabinet.Name = "ShakerBase_B"..tostring(W)
	cabinet.Parent = workspace

	local boxHeight = H - TOE_H
	local boxCenterY = TOE_H + boxHeight/2
	local frontZ = -(D/2 + 0.40)
	local frontWidth = W - (REVEAL_SIDE*2)

	part(cabinet,"LeftSide",
		Vector3.new(SIDE,boxHeight,D),
		Vector3.new(offsetX-(W/2-SIDE/2),boxCenterY,0),
		CABINET_COLOR)

	part(cabinet,"RightSide",
		Vector3.new(SIDE,boxHeight,D),
		Vector3.new(offsetX+(W/2-SIDE/2),boxCenterY,0),
		CABINET_COLOR)

	part(cabinet,"Bottom",
		Vector3.new(W-SIDE*2,SIDE,D-BACK),
		Vector3.new(offsetX,TOE_H+SIDE/2,-BACK/2),
		INTERIOR_COLOR)

	part(cabinet,"Back",
		Vector3.new(W-SIDE*2,boxHeight,BACK),
		Vector3.new(offsetX,boxCenterY,D/2-BACK/2),
		INTERIOR_COLOR)

	part(cabinet,"TopFrontStretcher",
		Vector3.new(W-SIDE*2,2,SIDE),
		Vector3.new(offsetX,H-1,-(D/2-SIDE/2)),
		INTERIOR_COLOR)

	part(cabinet,"TopRearStretcher",
		Vector3.new(W-SIDE*2,2,SIDE),
		Vector3.new(offsetX,H-1,D/2-SIDE/2),
		INTERIOR_COLOR)

	local toeFrontZ = -D/2 + TOE_DEPTH
	local toePanelCenterZ = toeFrontZ + SIDE/2
	local toeRunDepth = D - TOE_DEPTH
	local toeRunCenterZ = toeFrontZ + toeRunDepth/2

	part(cabinet,"ToeKick",
		Vector3.new(W-SIDE*2,TOE_H,SIDE),
		Vector3.new(offsetX,TOE_H/2,toePanelCenterZ),
		CABINET_COLOR)

	part(cabinet,"ToeKickLeftReturn",
		Vector3.new(SIDE,TOE_H,toeRunDepth),
		Vector3.new(offsetX-(W/2-SIDE/2),TOE_H/2,toeRunCenterZ),
		CABINET_COLOR)

	part(cabinet,"ToeKickRightReturn",
		Vector3.new(SIDE,TOE_H,toeRunDepth),
		Vector3.new(offsetX+(W/2-SIDE/2),TOE_H/2,toeRunCenterZ),
		CABINET_COLOR)

	local drawerTop = H - 0.5
	local drawerBottom = drawerTop - DRAWER_H
	local drawerCenterY = (drawerTop + drawerBottom)/2

	local doorTop = drawerBottom - GAP_DRAWER_DOOR
	local doorBottom = TOE_H + 0.5
	local doorHeight = doorTop - doorBottom
	local doorCenterY = (doorTop + doorBottom)/2

	local drawerFront = shakerFront(cabinet,"DrawerFront",frontWidth,DRAWER_H,drawerCenterY,frontZ,CABINET_COLOR)
	local doorFront = shakerFront(cabinet,"Door",frontWidth,doorHeight,doorCenterY,frontZ,CABINET_COLOR)

	for _,mdl in ipairs({drawerFront,doorFront}) do
		for _,obj in ipairs(mdl:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.Position = obj.Position + Vector3.new(offsetX,0,0)
			end
		end
	end

	local drawerPullLen = math.clamp(W * 0.30, 3.0, 5.0)
	horizontalPull(cabinet,"DrawerPull",drawerPullLen,drawerCenterY,frontZ-0.65)

	local doorPullLen = math.clamp(W * 0.30, 3.0, 5.0)
	local doorPullY = doorTop - 1.25
	horizontalPull(cabinet,"DoorPull",doorPullLen,doorPullY,frontZ-0.65)

	for _,obj in ipairs(cabinet:GetDescendants()) do
		if obj:IsA("BasePart") and (obj.Parent.Name=="DrawerPull" or obj.Parent.Name=="DoorPull") then
			obj.Position = obj.Position + Vector3.new(offsetX,0,0)
		end
	end

	local drawerBox = Instance.new("Model")
	drawerBox.Name = "DrawerBox"
	drawerBox.Parent = cabinet
	local drawerInsideWidth = math.max(4,W-SIDE*2-1)
	local drawerDepth = 21
	local drawerBoxHeight = 4.5

	part(drawerBox,"DrawerBottom",
		Vector3.new(drawerInsideWidth,0.40,drawerDepth),
		Vector3.new(offsetX,drawerCenterY-drawerBoxHeight/2,0),
		INTERIOR_COLOR)

	part(drawerBox,"DrawerLeft",
		Vector3.new(0.50,drawerBoxHeight,drawerDepth),
		Vector3.new(offsetX-drawerInsideWidth/2+0.25,drawerCenterY,0),
		INTERIOR_COLOR)

	part(drawerBox,"DrawerRight",
		Vector3.new(0.50,drawerBoxHeight,drawerDepth),
		Vector3.new(offsetX+drawerInsideWidth/2-0.25,drawerCenterY,0),
		INTERIOR_COLOR)

	part(drawerBox,"DrawerBack",
		Vector3.new(drawerInsideWidth,drawerBoxHeight,0.50),
		Vector3.new(offsetX,drawerCenterY,D/2-2),
		INTERIOR_COLOR)

	part(cabinet,"AdjustableShelf",
		Vector3.new(math.max(4,W-SIDE*2-0.5),0.75,D-2),
		Vector3.new(offsetX,TOE_H+9,0.5),
		INTERIOR_COLOR)

	cabinet:SetAttribute("WidthInches",W)
	cabinet:SetAttribute("DepthInches",D)
	cabinet:SetAttribute("HeightInches",H)
	cabinet:SetAttribute("SideReveal",REVEAL_SIDE)
	cabinet:SetAttribute("DrawerDoorGap",GAP_DRAWER_DOOR)
	cabinet:SetAttribute("Style","Shaker")
	return cabinet
end

local folder = workspace:FindFirstChild("GeneratedShakerCabinets")
if folder then folder:Destroy() end

folder = Instance.new("Folder")
folder.Name = "GeneratedShakerCabinets"
folder.Parent = workspace

local cursor = 0
for _,w in ipairs(CABINET_WIDTHS) do
	local m = generateCabinet(w, cursor + w/2)
	m.Parent = folder
	cursor += w + 6
end

print("Generated Shaker base cabinet family: B9-B36")
print("Dimensions use 1 stud = 1 inch")
print("Side reveals: 1/2 inch each side")
print("Gap between drawer and door: 1/2 inch")
