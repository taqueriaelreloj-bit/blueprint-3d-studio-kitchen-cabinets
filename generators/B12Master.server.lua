-- Blueprint 3D Studio - Kitchen Cabinets
-- B12 MASTER SHAKER BASE CABINET
-- Roblox Studio generator
-- Units: 1 stud = 1 inch

local W = 12
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
local FRONT_THICKNESS = 0.75
local PANEL_THICKNESS = 0.25

local CABINET_COLOR = Color3.fromRGB(155, 152, 147)
local INTERIOR_COLOR = Color3.fromRGB(194, 154, 105)
local HARDWARE_COLOR = Color3.fromRGB(115, 115, 112)

local function makePart(parent, name, size, pos, color)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Position = pos
    p.Anchored = true
    p.CanCollide = true
    p.Material = Enum.Material.SmoothPlastic
    p.Color = color
    p.Transparency = 0
    p.Reflectance = 0
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function makeShakerFront(parent, name, width, height, centerY, frontZ)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = parent

    local rail = math.min(SHAKER_RAIL, math.max(1.5, width * 0.12))
    local innerW = math.max(0.5, width - rail * 2)
    local innerH = math.max(0.5, height - rail * 2)

    makePart(model, "CenterPanel",
        Vector3.new(innerW, innerH, PANEL_THICKNESS),
        Vector3.new(0, centerY, frontZ + (FRONT_THICKNESS - PANEL_THICKNESS)/2),
        CABINET_COLOR)

    makePart(model, "LeftStile",
        Vector3.new(rail, height, FRONT_THICKNESS),
        Vector3.new(-width/2 + rail/2, centerY, frontZ),
        CABINET_COLOR)

    makePart(model, "RightStile",
        Vector3.new(rail, height, FRONT_THICKNESS),
        Vector3.new(width/2 - rail/2, centerY, frontZ),
        CABINET_COLOR)

    makePart(model, "TopRail",
        Vector3.new(innerW, rail, FRONT_THICKNESS),
        Vector3.new(0, centerY + height/2 - rail/2, frontZ),
        CABINET_COLOR)

    makePart(model, "BottomRail",
        Vector3.new(innerW, rail, FRONT_THICKNESS),
        Vector3.new(0, centerY - height/2 + rail/2, frontZ),
        CABINET_COLOR)

    return model
end

local function makeHorizontalPull(parent, name, length, y, z)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent

    makePart(m, "Bar", Vector3.new(length, 0.35, 0.35), Vector3.new(0, y, z), HARDWARE_COLOR)
    makePart(m, "PostLeft", Vector3.new(0.30, 0.30, 0.75), Vector3.new(-length/2 + 0.65, y, z + 0.30), HARDWARE_COLOR)
    makePart(m, "PostRight", Vector3.new(0.30, 0.30, 0.75), Vector3.new(length/2 - 0.65, y, z + 0.30), HARDWARE_COLOR)
end

local function shiftModel(model, dx)
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Position += Vector3.new(dx, 0, 0)
        end
    end
end

local old = workspace:FindFirstChild("B12_MASTER_SHAKER")
if old then old:Destroy() end

local cabinet = Instance.new("Model")
cabinet.Name = "B12_MASTER_SHAKER"
cabinet.Parent = workspace

local offsetX = 0
local boxHeight = H - TOE_H
local boxCenterY = TOE_H + boxHeight/2
local frontZ = -(D/2 + 0.40)
local frontWidth = W - (REVEAL_SIDE * 2)

-- Finished sides: same exterior color as door/drawer fronts.
makePart(cabinet, "LeftSide", Vector3.new(SIDE, boxHeight, D), Vector3.new(-(W/2-SIDE/2), boxCenterY, 0), CABINET_COLOR)
makePart(cabinet, "RightSide", Vector3.new(SIDE, boxHeight, D), Vector3.new((W/2-SIDE/2), boxCenterY, 0), CABINET_COLOR)

makePart(cabinet, "Bottom", Vector3.new(W-SIDE*2, SIDE, D-BACK), Vector3.new(0, TOE_H+SIDE/2, -BACK/2), INTERIOR_COLOR)
makePart(cabinet, "Back", Vector3.new(W-SIDE*2, boxHeight, BACK), Vector3.new(0, boxCenterY, D/2-BACK/2), INTERIOR_COLOR)
makePart(cabinet, "TopFrontStretcher", Vector3.new(W-SIDE*2, 2, SIDE), Vector3.new(0, H-1, -(D/2-SIDE/2)), INTERIOR_COLOR)
makePart(cabinet, "TopRearStretcher", Vector3.new(W-SIDE*2, 2, SIDE), Vector3.new(0, H-1, D/2-SIDE/2), INTERIOR_COLOR)

-- Recessed toe kick: 4.5" high, 3" back from cabinet face.
local toeFrontZ = -D/2 + TOE_DEPTH
local toePanelCenterZ = toeFrontZ + SIDE/2
local toeRunDepth = D - TOE_DEPTH
local toeRunCenterZ = toeFrontZ + toeRunDepth/2

makePart(cabinet, "ToeKick", Vector3.new(W-SIDE*2, TOE_H, SIDE), Vector3.new(0, TOE_H/2, toePanelCenterZ), CABINET_COLOR)
makePart(cabinet, "ToeKickLeftReturn", Vector3.new(SIDE, TOE_H, toeRunDepth), Vector3.new(-(W/2-SIDE/2), TOE_H/2, toeRunCenterZ), CABINET_COLOR)
makePart(cabinet, "ToeKickRightReturn", Vector3.new(SIDE, TOE_H, toeRunDepth), Vector3.new((W/2-SIDE/2), TOE_H/2, toeRunCenterZ), CABINET_COLOR)

-- Front layout: 1/2" side reveal and 1/2" drawer-to-door gap.
local drawerTop = H - 0.5
local drawerBottom = drawerTop - DRAWER_H
local drawerCenterY = (drawerTop + drawerBottom)/2

local doorTop = drawerBottom - GAP_DRAWER_DOOR
local doorBottom = TOE_H + 0.5
local doorHeight = doorTop - doorBottom
local doorCenterY = (doorTop + doorBottom)/2

local drawerFront = makeShakerFront(cabinet, "DrawerFront", frontWidth, DRAWER_H, drawerCenterY, frontZ)
local doorFront = makeShakerFront(cabinet, "Door", frontWidth, doorHeight, doorCenterY, frontZ)
shiftModel(drawerFront, offsetX)
shiftModel(doorFront, offsetX)

-- Pulls: horizontal and centered.
-- Door pull is centered left-to-right and located on the upper rail.
local pullLength = 3.5
makeHorizontalPull(cabinet, "DrawerPull", pullLength, drawerCenterY, frontZ - 0.65)
local doorPullY = doorTop - SHAKER_RAIL/2
makeHorizontalPull(cabinet, "DoorPull", pullLength, doorPullY, frontZ - 0.65)

-- Drawer box.
local drawerBox = Instance.new("Model")
drawerBox.Name = "DrawerBox"
drawerBox.Parent = cabinet
local drawerInsideWidth = math.max(4, W-SIDE*2-1)
local drawerDepth = 21
local drawerBoxHeight = 4.5

makePart(drawerBox, "DrawerBottom", Vector3.new(drawerInsideWidth, 0.40, drawerDepth), Vector3.new(0, drawerCenterY-drawerBoxHeight/2, 0), INTERIOR_COLOR)
makePart(drawerBox, "DrawerLeft", Vector3.new(0.50, drawerBoxHeight, drawerDepth), Vector3.new(-drawerInsideWidth/2+0.25, drawerCenterY, 0), INTERIOR_COLOR)
makePart(drawerBox, "DrawerRight", Vector3.new(0.50, drawerBoxHeight, drawerDepth), Vector3.new(drawerInsideWidth/2-0.25, drawerCenterY, 0), INTERIOR_COLOR)
makePart(drawerBox, "DrawerBack", Vector3.new(drawerInsideWidth, drawerBoxHeight, 0.50), Vector3.new(0, drawerCenterY, D/2-2), INTERIOR_COLOR)

makePart(cabinet, "AdjustableShelf", Vector3.new(math.max(4,W-SIDE*2-0.5), 0.75, D-2), Vector3.new(0, TOE_H+9, 0.5), INTERIOR_COLOR)

cabinet:SetAttribute("CabinetType", "B12")
cabinet:SetAttribute("Style", "Shaker")
cabinet:SetAttribute("WidthInches", W)
cabinet:SetAttribute("DepthInches", D)
cabinet:SetAttribute("HeightInches", H)
cabinet:SetAttribute("SideRevealInches", REVEAL_SIDE)
cabinet:SetAttribute("DrawerDoorGapInches", GAP_DRAWER_DOOR)
cabinet:SetAttribute("ToeKickHeightInches", TOE_H)
cabinet:SetAttribute("ToeKickRecessInches", TOE_DEPTH)

print("B12 MASTER SHAKER generated")
print("12W x 24D x 34.5H")
print("1/2 inch side reveals; 1/2 inch drawer-door gap")
print("Door pull horizontal, centered, upper rail")
