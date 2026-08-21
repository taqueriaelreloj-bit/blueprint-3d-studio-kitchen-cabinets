-- Blueprint 3D Studio - Kitchen Cabinets
-- Parametric transform utilities. This module NEVER creates cabinet models.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("KitchenCabinets"):WaitForChild("CabinetConfig"))

local Transform = {}

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

local function enforceFieldWidth(model, requested)
    ensureAttributes(model)
    local nominal = model:GetAttribute(Config.NominalWidthAttribute) or requested
    local delta = Config.FieldAdjustment.MaxWidthDelta or 2
    return math.clamp(requested, nominal - delta, nominal + delta)
end

local function resizeAxisAware(model, targetWidth, targetHeight, targetDepth)
    ensureAttributes(model)

    targetWidth = enforceFieldWidth(model, targetWidth)
    targetWidth = clamp(targetWidth, Config.Limits.Width)
    targetHeight = clamp(targetHeight, Config.Limits.Height)
    targetDepth = clamp(targetDepth, Config.Limits.Depth)

    local pivot = model:GetPivot()
    local _, oldSize = model:GetBoundingBox()
    local sx = targetWidth / oldSize.X
    local sy = targetHeight / oldSize.Y
    local sz = targetDepth / oldSize.Z

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            local localCf = pivot:ToObjectSpace(obj.CFrame)
            local p = localCf.Position
            local newPos = Vector3.new(p.X * sx, p.Y * sy, p.Z * sz)
            local old = obj.Size
            local kind = category(obj)
            local newSize

            if kind == "hardware" then
                -- Hardware never scales. It only follows the new cabinet position.
                newSize = old
            elseif kind == "side" then
                -- Side thickness stays fixed; height/depth can follow cabinet dimensions.
                newSize = Vector3.new(old.X, old.Y * sy, old.Z * sz)
            elseif kind == "back" then
                newSize = Vector3.new(old.X * sx, old.Y * sy, old.Z)
            elseif kind == "stile" then
                -- Shaker stile width stays fixed. Height may change.
                newSize = Vector3.new(old.X, old.Y * sy, old.Z)
            elseif kind == "rail" then
                -- Rail height/thickness stay fixed; width changes with cabinet.
                newSize = Vector3.new(old.X * sx, old.Y, old.Z)
            elseif kind == "toe" then
                -- Toe kick width/depth may follow, but height stays fixed.
                newSize = Vector3.new(old.X * sx, old.Y, old.Z * sz)
            elseif kind == "panel" then
                -- Recessed panels absorb most of the dimensional change.
                newSize = Vector3.new(old.X * sx, old.Y * sy, old.Z)
            else
                newSize = Vector3.new(old.X * sx, old.Y * sy, old.Z * sz)
            end

            obj.Size = Vector3.new(math.max(0.05,newSize.X), math.max(0.05,newSize.Y), math.max(0.05,newSize.Z))
            obj.CFrame = pivot * CFrame.new(newPos) * (localCf - localCf.Position)
        end
    end

    model:SetAttribute(Config.WidthAttribute, targetWidth)
    model:SetAttribute(Config.HeightAttribute, targetHeight)
    model:SetAttribute(Config.DepthAttribute, targetDepth)
    model:SetAttribute(Config.AdjustedAttribute,
        math.abs(targetWidth - (model:GetAttribute(Config.NominalWidthAttribute) or targetWidth)) > 0.001)
    return targetWidth, targetHeight, targetDepth
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
