-- Blueprint 3D Studio - Kitchen Cabinets
-- Parametric transform utilities. This module NEVER creates cabinet models.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("KitchenCabinets"):WaitForChild("CabinetConfig"))

local Transform = {}

local EPS = 0.001

local function clamp(value, limits)
    return math.clamp(value, limits.Min, limits.Max)
end

local function getModelSize(model)
    local _, size = model:GetBoundingBox()
    return size
end

local function nominalFromName(model)
    local n = string.upper(model.Name)
    local value = string.match(n, "B(%d+)")
    return value and tonumber(value) or nil
end

local function isStandardWidth(value)
    for _, w in ipairs(Config.StandardBaseWidths or {}) do
        if math.abs(value - w) < EPS then return true end
    end
    return false
end

local function ensureAttributes(model)
    local size = getModelSize(model)
    if model:GetAttribute(Config.WidthAttribute) == nil then model:SetAttribute(Config.WidthAttribute, size.X) end
    if model:GetAttribute(Config.HeightAttribute) == nil then model:SetAttribute(Config.HeightAttribute, size.Y) end
    if model:GetAttribute(Config.DepthAttribute) == nil then model:SetAttribute(Config.DepthAttribute, size.Z) end
    if model:GetAttribute(Config.ModelAttribute) == nil then model:SetAttribute(Config.ModelAttribute, true) end
    if model:GetAttribute(Config.NominalWidthAttribute) == nil then
        model:SetAttribute(Config.NominalWidthAttribute, nominalFromName(model) or size.X)
    end
end

local function ancestryText(obj)
    local names = {}
    local current = obj
    while current and not current:IsA("Workspace") do
        table.insert(names, string.lower(current.Name))
        current = current.Parent
    end
    return table.concat(names, "/")
end

local function category(obj)
    local path = ancestryText(obj)
    if path:find("pull") or path:find("handle") or path:find("hinge") then return "hardware" end
    if path:find("leftside") or path:find("rightside") then return "side" end
    if path:find("back") then return "back" end
    if path:find("stile") then return "stile" end
    if path:find("rail") then return "rail" end
    if path:find("toekick") then return "toe" end
    if path:find("centerpanel") or path:find("panel") then return "panel" end
    return "general"
end

local function resolveRequestedWidth(model, requested)
    ensureAttributes(model)
    requested = clamp(requested, Config.Limits.Width)

    -- Exact standard sizes (B9, B12, B15, etc.) are always allowed.
    -- This lets a designer intentionally convert one standard cabinet width to another.
    if isStandardWidth(requested) then
        model:SetAttribute(Config.NominalWidthAttribute, requested)
        model:SetAttribute(Config.AdjustedAttribute, false)
        return requested, true
    end

    -- Non-standard values are treated as field adjustments around the nominal width.
    local nominal = model:GetAttribute(Config.NominalWidthAttribute) or requested
    local delta = Config.FieldAdjustment.MaxWidthDelta or 2
    local resolved = math.clamp(requested, nominal - delta, nominal + delta)
    model:SetAttribute(Config.AdjustedAttribute, math.abs(resolved - nominal) > EPS)
    return resolved, false
end

local function applyWidthPass(model, targetWidth)
    local pivot = model:GetPivot()
    local _, oldSize = model:GetBoundingBox()
    if oldSize.X <= EPS then return end

    local delta = targetWidth - oldSize.X
    local sx = targetWidth / oldSize.X

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            local localCf = pivot:ToObjectSpace(obj.CFrame)
            local p = localCf.Position
            local old = obj.Size
            local kind = category(obj)

            local newX = p.X * sx
            local newSizeX = old.X * sx

            if kind == "hardware" then
                -- Hardware keeps exact dimensions and only follows position.
                newSizeX = old.X
            elseif kind == "side" then
                -- Cabinet side thickness stays fixed; sides move to the new outer edges.
                newSizeX = old.X
                if math.abs(p.X) > EPS then
                    newX = p.X + (p.X > 0 and delta/2 or -delta/2)
                end
            elseif kind == "stile" then
                -- Stiles keep width and move with their respective left/right edge.
                newSizeX = old.X
                if math.abs(p.X) > EPS then
                    newX = p.X + (p.X > 0 and delta/2 or -delta/2)
                end
            elseif kind == "rail" then
                -- Rails span the changing opening but keep their Y/Z dimensions.
                newSizeX = math.max(0.05, old.X + delta)
            elseif kind == "panel" then
                -- Recessed panels absorb the width change directly.
                newSizeX = math.max(0.05, old.X + delta)
            elseif kind == "back" or kind == "toe" or kind == "general" then
                newSizeX = math.max(0.05, old.X + delta)
            end

            obj.Size = Vector3.new(math.max(0.05,newSizeX), obj.Size.Y, obj.Size.Z)
            obj.CFrame = pivot * CFrame.new(newX, p.Y, p.Z) * (localCf - localCf.Position)
        end
    end
end

local function applyHeightDepthPass(model, targetHeight, targetDepth)
    local pivot = model:GetPivot()
    local _, oldSize = model:GetBoundingBox()
    local sy = targetHeight / oldSize.Y
    local sz = targetDepth / oldSize.Z

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            local localCf = pivot:ToObjectSpace(obj.CFrame)
            local p = localCf.Position
            local old = obj.Size
            local kind = category(obj)
            local newY = p.Y * sy
            local newZ = p.Z * sz
            local sizeY = old.Y * sy
            local sizeZ = old.Z * sz

            if kind == "hardware" then
                sizeY, sizeZ = old.Y, old.Z
            elseif kind == "stile" then
                sizeZ = old.Z
            elseif kind == "rail" then
                sizeY, sizeZ = old.Y, old.Z
            elseif kind == "side" then
                sizeZ = old.Z * sz
            elseif kind == "back" then
                sizeZ = old.Z
            elseif kind == "toe" then
                sizeY = old.Y
            elseif kind == "panel" then
                sizeZ = old.Z
            end

            obj.Size = Vector3.new(obj.Size.X, math.max(0.05,sizeY), math.max(0.05,sizeZ))
            obj.CFrame = pivot * CFrame.new(p.X, newY, newZ) * (localCf - localCf.Position)
        end
    end
end

local function correctExactWidth(model, targetWidth)
    -- Protected fixed-thickness pieces mean one pass can leave a tiny dimensional error.
    -- Iterate using the ACTUAL bounding box until the finished cabinet measures exactly targetWidth.
    for _ = 1, 4 do
        local _, size = model:GetBoundingBox()
        local errorX = targetWidth - size.X
        if math.abs(errorX) <= 0.002 then break end
        applyWidthPass(model, targetWidth)
    end

    local _, finalSize = model:GetBoundingBox()
    return finalSize.X
end

local function resizeAxisAware(model, targetWidth, targetHeight, targetDepth)
    ensureAttributes(model)

    local requestedWidth = targetWidth
    targetWidth = select(1, resolveRequestedWidth(model, targetWidth))
    targetHeight = clamp(targetHeight, Config.Limits.Height)
    targetDepth = clamp(targetDepth, Config.Limits.Depth)

    -- Width is handled independently so the physical bounding box is authoritative.
    applyWidthPass(model, targetWidth)
    correctExactWidth(model, targetWidth)

    -- Height/depth remain independent transforms; width is not touched here.
    local _, afterWidth = model:GetBoundingBox()
    if math.abs(targetHeight - afterWidth.Y) > EPS or math.abs(targetDepth - afterWidth.Z) > EPS then
        applyHeightDepthPass(model, targetHeight, targetDepth)
    end

    local _, finalSize = model:GetBoundingBox()
    model:SetAttribute(Config.WidthAttribute, finalSize.X)
    model:SetAttribute(Config.HeightAttribute, finalSize.Y)
    model:SetAttribute(Config.DepthAttribute, finalSize.Z)
    model:SetAttribute("RequestedWidthInches", requestedWidth)
    model:SetAttribute("WidthErrorInches", finalSize.X - targetWidth)

    return finalSize.X, finalSize.Y, finalSize.Z
end

function Transform.Resize(model, width, height, depth)
    assert(model and model:IsA("Model"), "Resize requires a Model")
    return resizeAxisAware(model, width, height, depth)
end

function Transform.MirrorX(model)
    assert(model and model:IsA("Model"), "MirrorX requires a Model")
    local pivot = model:GetPivot()
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            local localCf = pivot:ToObjectSpace(obj.CFrame)
            local p = localCf.Position
            local x, y, z = localCf:ToOrientation()
            obj.CFrame = pivot * CFrame.new(-p.X, p.Y, p.Z) * CFrame.fromOrientation(x, -y, -z)
        end
    end
    model:SetAttribute(Config.MirroredAttribute, not model:GetAttribute(Config.MirroredAttribute))
end

function Transform.Rotate90(model, quarterTurns)
    assert(model and model:IsA("Model"), "Rotate90 requires a Model")
    model:PivotTo(model:GetPivot() * CFrame.Angles(0, math.rad(90 * (quarterTurns or 1)), 0))
end

function Transform.Register(model)
    assert(model and model:IsA("Model"), "Register requires a Model")
    ensureAttributes(model)
end

return Transform
