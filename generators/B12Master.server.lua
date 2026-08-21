-- Blueprint 3D Studio - Kitchen Cabinets
-- B12 MASTER SHAKER BASE CABINET v3 CLEAN
-- Units: 1 stud = 1 inch

local W,D,H = 12,24,34.5
local SIDE,BACK = 0.75,0.50
local TOE_H,TOE_DEPTH = 4.5,3.0
local REVEAL = 0.5
local GAP = 0.5
local DRAWER_H = 6.25
local RAIL = 1.50
local FRAME_T = 0.55
local PANEL_T = 0.22
local WHITE = Color3.fromRGB(190,190,188)
local WOOD = Color3.fromRGB(194,154,105)
local METAL = Color3.fromRGB(80,80,78)

local function P(parent,name,size,pos,color)
 local p=Instance.new("Part")
 p.Name=name; p.Size=size; p.Position=pos; p.Anchored=true; p.CanCollide=true
 p.Material=Enum.Material.SmoothPlastic; p.Color=color
 p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=parent; return p
end

local function shaker(parent,name,w,h,cy,faceZ)
 local m=Instance.new("Model"); m.Name=name; m.Parent=parent
 local r=math.min(RAIL,math.max(1.15,w*0.125))
 local iw=w-r*2
 local ih=h-r*2
 -- faceZ is the FRONT center plane. Negative Z is toward viewer.
 -- panel is recessed BEHIND frame, toward cabinet (+Z).
 local panelZ=faceZ + FRAME_T/2 + PANEL_T/2 + 0.08
 P(m,"CenterPanel",Vector3.new(iw,ih,PANEL_T),Vector3.new(0,cy,panelZ),WHITE)
 -- rails full width; stiles terminate between rails = zero overlap
 P(m,"TopRail",Vector3.new(w,r,FRAME_T),Vector3.new(0,cy+h/2-r/2,faceZ),WHITE)
 P(m,"BottomRail",Vector3.new(w,r,FRAME_T),Vector3.new(0,cy-h/2+r/2,faceZ),WHITE)
 P(m,"LeftStile",Vector3.new(r,ih,FRAME_T),Vector3.new(-w/2+r/2,cy,faceZ),WHITE)
 P(m,"RightStile",Vector3.new(r,ih,FRAME_T),Vector3.new(w/2-r/2,cy,faceZ),WHITE)
 return r
end

local function pull(parent,name,len,y,frameZ)
 local m=Instance.new("Model"); m.Name=name; m.Parent=parent
 -- hardware completely in FRONT of frame; no intersection with door
 local z=frameZ-FRAME_T/2-0.42
 P(m,"Bar",Vector3.new(len,0.34,0.34),Vector3.new(0,y,z-0.22),METAL)
 local px=len/2-0.48
 P(m,"PostLeft",Vector3.new(0.26,0.26,0.62),Vector3.new(-px,y,z),METAL)
 P(m,"PostRight",Vector3.new(0.26,0.26,0.62),Vector3.new(px,y,z),METAL)
end

-- Delete every prior test/master model so old geometry cannot remain visible.
for _,obj in ipairs(workspace:GetChildren()) do
 if obj:IsA("Model") and (obj.Name=="B12_MASTER_SHAKER" or obj.Name=="ShakerBase_B12" or obj.Name=="B12") then
  obj:Destroy()
 end
end

local c=Instance.new("Model"); c.Name="B12_MASTER_SHAKER"; c.Parent=workspace
local boxH=H-TOE_H
local boxCY=TOE_H+boxH/2

-- Cabinet carcass. Front is -Z.
P(c,"LeftSide",Vector3.new(SIDE,boxH,D),Vector3.new(-W/2+SIDE/2,boxCY,0),WHITE)
P(c,"RightSide",Vector3.new(SIDE,boxH,D),Vector3.new(W/2-SIDE/2,boxCY,0),WHITE)
P(c,"Bottom",Vector3.new(W-SIDE*2,SIDE,D-BACK),Vector3.new(0,TOE_H+SIDE/2,-BACK/2),WOOD)
P(c,"Back",Vector3.new(W-SIDE*2,boxH,BACK),Vector3.new(0,boxCY,D/2-BACK/2),WOOD)
P(c,"TopFrontStretcher",Vector3.new(W-SIDE*2,1.5,SIDE),Vector3.new(0,H-0.75,-D/2+SIDE/2),WOOD)
P(c,"TopRearStretcher",Vector3.new(W-SIDE*2,1.5,SIDE),Vector3.new(0,H-0.75,D/2-SIDE/2),WOOD)

-- Toe kick is recessed exactly 3 inches.
local toeFace=-D/2+TOE_DEPTH
P(c,"ToeKick",Vector3.new(W-SIDE*2,TOE_H,SIDE),Vector3.new(0,TOE_H/2,toeFace+SIDE/2),WHITE)
local returnDepth=D-TOE_DEPTH
P(c,"ToeKickLeftReturn",Vector3.new(SIDE,TOE_H,returnDepth),Vector3.new(-W/2+SIDE/2,TOE_H/2,toeFace+returnDepth/2),WHITE)
P(c,"ToeKickRightReturn",Vector3.new(SIDE,TOE_H,returnDepth),Vector3.new(W/2-SIDE/2,TOE_H/2,toeFace+returnDepth/2),WHITE)

-- Fronts sit just ahead of carcass.
local faceZ=-D/2-FRAME_T/2-0.06
local fw=W-REVEAL*2
local drawerTop=H-REVEAL
local drawerBottom=drawerTop-DRAWER_H
local drawerCY=(drawerTop+drawerBottom)/2
local doorTop=drawerBottom-GAP
local doorBottom=TOE_H+REVEAL
local doorH=doorTop-doorBottom
local doorCY=(doorTop+doorBottom)/2
local drawerRail=shaker(c,"DrawerFront",fw,DRAWER_H,drawerCY,faceZ)
local doorRail=shaker(c,"Door",fw,doorH,doorCY,faceZ)

-- One pull per front only. Both horizontal and centered X.
pull(c,"DrawerPull",3.5,drawerCY,faceZ)
pull(c,"DoorPull",3.5,doorTop-doorRail/2,faceZ)

-- Internal drawer box and shelf stay behind front.
local db=Instance.new("Model"); db.Name="DrawerBox"; db.Parent=c
local diw=W-SIDE*2-1
local dd=20.5
local dh=4.25
P(db,"Bottom",Vector3.new(diw,0.35,dd),Vector3.new(0,drawerCY-dh/2,0.3),WOOD)
P(db,"Left",Vector3.new(0.45,dh,dd),Vector3.new(-diw/2+0.225,drawerCY,0.3),WOOD)
P(db,"Right",Vector3.new(0.45,dh,dd),Vector3.new(diw/2-0.225,drawerCY,0.3),WOOD)
P(db,"Back",Vector3.new(diw,dh,0.45),Vector3.new(0,drawerCY,D/2-1.5),WOOD)
P(c,"AdjustableShelf",Vector3.new(W-SIDE*2-0.5,0.75,D-2),Vector3.new(0,TOE_H+9,0.5),WOOD)

c:SetAttribute("CabinetType","B12")
c:SetAttribute("Style","Shaker")
c:SetAttribute("WidthInches",W)
c:SetAttribute("DepthInches",D)
c:SetAttribute("HeightInches",H)
c:SetAttribute("SideRevealInches",REVEAL)
c:SetAttribute("DrawerDoorGapInches",GAP)
c:SetAttribute("ToeKickHeightInches",TOE_H)
c:SetAttribute("ToeKickRecessInches",TOE_DEPTH)
c:SetAttribute("MasterVersion","3-clean")
print("B12 MASTER SHAKER v3 CLEAN generated")