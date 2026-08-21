-- Blueprint 3D Studio - Kitchen Cabinets
-- B12 MASTER SHAKER BASE CABINET v2
-- Units: 1 stud = 1 inch

local W, D, H = 12, 24, 34.5
local SIDE, BACK = 0.75, 0.50
local TOE_H, TOE_DEPTH = 4.5, 3.0
local REVEAL_SIDE, GAP_DRAWER_DOOR = 0.5, 0.5
local DRAWER_H = 6.25
local SHAKER_RAIL = 1.75
local FRONT_THICKNESS = 0.75
local PANEL_THICKNESS = 0.25

local CABINET_COLOR = Color3.fromRGB(155,152,147)
local INTERIOR_COLOR = Color3.fromRGB(194,154,105)
local HARDWARE_COLOR = Color3.fromRGB(85,85,82)

local function part(parent,name,size,pos,color)
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

-- Build the Shaker front with NO overlapping coplanar frame pieces.
-- Top/bottom rails span the full width; stiles fit only between the rails.
local function shakerFront(parent,name,width,height,centerY,z)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent

    local rail = math.min(SHAKER_RAIL, math.max(1.35,width*0.145))
    local innerW = math.max(0.5,width-rail*2)
    local innerH = math.max(0.5,height-rail*2)

    -- recessed center panel sits behind the face frame
    part(m,"CenterPanel",
        Vector3.new(innerW,innerH,PANEL_THICKNESS),
        Vector3.new(0,centerY,z + (FRONT_THICKNESS/2 + PANEL_THICKNESS/2)),
        CABINET_COLOR)

    -- full-width rails
    part(m,"TopRail",
        Vector3.new(width,rail,FRONT_THICKNESS),
        Vector3.new(0,centerY+height/2-rail/2,z),
        CABINET_COLOR)
    part(m,"BottomRail",
        Vector3.new(width,rail,FRONT_THICKNESS),
        Vector3.new(0,centerY-height/2+rail/2,z),
        CABINET_COLOR)

    -- stiles only between rails: no overlapping corners / no z-fighting
    part(m,"LeftStile",
        Vector3.new(rail,innerH,FRONT_THICKNESS),
        Vector3.new(-width/2+rail/2,centerY,z),
        CABINET_COLOR)
    part(m,"RightStile",
        Vector3.new(rail,innerH,FRONT_THICKNESS),
        Vector3.new(width/2-rail/2,centerY,z),
        CABINET_COLOR)

    return m,rail
end

local function horizontalPull(parent,name,length,y,z)
    local m = Instance.new("Model")
    m.Name = name
    m.Parent = parent

    -- slightly thicker hardware so it reads cleanly in Studio
    part(m,"Bar",Vector3.new(length,0.42,0.42),Vector3.new(0,y,z),HARDWARE_COLOR)
    local postX = math.max(0.45,length/2-0.60)
    part(m,"PostLeft",Vector3.new(0.34,0.34,0.70),Vector3.new(-postX,y,z+0.30),HARDWARE_COLOR)
    part(m,"PostRight",Vector3.new(0.34,0.34,0.70),Vector3.new(postX,y,z+0.30),HARDWARE_COLOR)
end

local old = workspace:FindFirstChild("B12_MASTER_SHAKER")
if old then old:Destroy() end

local cabinet = Instance.new("Model")
cabinet.Name = "B12_MASTER_SHAKER"
cabinet.Parent = workspace

local boxHeight = H-TOE_H
local boxCenterY = TOE_H+boxHeight/2
local frontZ = -(D/2+0.50)
local frontWidth = W-(REVEAL_SIDE*2)

-- finished exterior sides
part(cabinet,"LeftSide",Vector3.new(SIDE,boxHeight,D),Vector3.new(-(W/2-SIDE/2),boxCenterY,0),CABINET_COLOR)
part(cabinet,"RightSide",Vector3.new(SIDE,boxHeight,D),Vector3.new((W/2-SIDE/2),boxCenterY,0),CABINET_COLOR)
part(cabinet,"Bottom",Vector3.new(W-SIDE*2,SIDE,D-BACK),Vector3.new(0,TOE_H+SIDE/2,-BACK/2),INTERIOR_COLOR)
part(cabinet,"Back",Vector3.new(W-SIDE*2,boxHeight,BACK),Vector3.new(0,boxCenterY,D/2-BACK/2),INTERIOR_COLOR)
part(cabinet,"TopFrontStretcher",Vector3.new(W-SIDE*2,2,SIDE),Vector3.new(0,H-1,-(D/2-SIDE/2)),INTERIOR_COLOR)
part(cabinet,"TopRearStretcher",Vector3.new(W-SIDE*2,2,SIDE),Vector3.new(0,H-1,D/2-SIDE/2),INTERIOR_COLOR)

-- recessed toe kick
local toeFrontZ = -D/2+TOE_DEPTH
local toeRunDepth = D-TOE_DEPTH
part(cabinet,"ToeKick",Vector3.new(W-SIDE*2,TOE_H,SIDE),Vector3.new(0,TOE_H/2,toeFrontZ+SIDE/2),CABINET_COLOR)
part(cabinet,"ToeKickLeftReturn",Vector3.new(SIDE,TOE_H,toeRunDepth),Vector3.new(-(W/2-SIDE/2),TOE_H/2,toeFrontZ+toeRunDepth/2),CABINET_COLOR)
part(cabinet,"ToeKickRightReturn",Vector3.new(SIDE,TOE_H,toeRunDepth),Vector3.new((W/2-SIDE/2),TOE_H/2,toeFrontZ+toeRunDepth/2),CABINET_COLOR)

-- exact front spacing
local drawerTop = H-0.5
local drawerBottom = drawerTop-DRAWER_H
local drawerCenterY = (drawerTop+drawerBottom)/2
local doorTop = drawerBottom-GAP_DRAWER_DOOR
local doorBottom = TOE_H+0.5
local doorHeight = doorTop-doorBottom
local doorCenterY = (doorTop+doorBottom)/2

local _,drawerRail = shakerFront(cabinet,"DrawerFront",frontWidth,DRAWER_H,drawerCenterY,frontZ)
local _,doorRail = shakerFront(cabinet,"Door",frontWidth,doorHeight,doorCenterY,frontZ)

-- both pulls horizontal and centered.
-- door pull centerline is centered vertically on its TOP Shaker rail.
local pullLength = 3.5
local hardwareZ = frontZ-(FRONT_THICKNESS/2)-0.42
horizontalPull(cabinet,"DrawerPull",pullLength,drawerCenterY,hardwareZ)
horizontalPull(cabinet,"DoorPull",pullLength,doorTop-doorRail/2,hardwareZ)

-- drawer box
local drawerBox = Instance.new("Model")
drawerBox.Name = "DrawerBox"
drawerBox.Parent = cabinet
local drawerInsideWidth = W-SIDE*2-1
local drawerDepth,drawerBoxHeight = 21,4.5
part(drawerBox,"DrawerBottom",Vector3.new(drawerInsideWidth,0.40,drawerDepth),Vector3.new(0,drawerCenterY-drawerBoxHeight/2,0),INTERIOR_COLOR)
part(drawerBox,"DrawerLeft",Vector3.new(0.50,drawerBoxHeight,drawerDepth),Vector3.new(-drawerInsideWidth/2+0.25,drawerCenterY,0),INTERIOR_COLOR)
part(drawerBox,"DrawerRight",Vector3.new(0.50,drawerBoxHeight,drawerDepth),Vector3.new(drawerInsideWidth/2-0.25,drawerCenterY,0),INTERIOR_COLOR)
part(drawerBox,"DrawerBack",Vector3.new(drawerInsideWidth,drawerBoxHeight,0.50),Vector3.new(0,drawerCenterY,D/2-2),INTERIOR_COLOR)
part(cabinet,"AdjustableShelf",Vector3.new(W-SIDE*2-0.5,0.75,D-2),Vector3.new(0,TOE_H+9,0.5),INTERIOR_COLOR)

cabinet:SetAttribute("CabinetType","B12")
cabinet:SetAttribute("Style","Shaker")
cabinet:SetAttribute("WidthInches",W)
cabinet:SetAttribute("DepthInches",D)
cabinet:SetAttribute("HeightInches",H)
cabinet:SetAttribute("SideRevealInches",REVEAL_SIDE)
cabinet:SetAttribute("DrawerDoorGapInches",GAP_DRAWER_DOOR)
cabinet:SetAttribute("ToeKickHeightInches",TOE_H)
cabinet:SetAttribute("ToeKickRecessInches",TOE_DEPTH)
cabinet:SetAttribute("MasterVersion","2")

print("B12 MASTER SHAKER v2 generated")
print("Pulls: horizontal + centered; door pull on upper rail")
