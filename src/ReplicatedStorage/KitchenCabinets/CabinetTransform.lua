-- Blueprint 3D Studio - Kitchen Cabinets
-- Non-generating transform utilities. This module NEVER creates cabinet models.

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

local function ensureAttributes(model)
    local size = getModelSize(model)
    if model:GetAttribute(Config.WidthAttribute) == nil then
        model:SetAttribute(Config.WidthAttribute, size.X)
    end
    if model:GetAttribute(Config.HeightAttribute) == nil then
        model:SetAttribute(Config.HeightAttribute, size.Y)
    end
    if model:GetAttribute(Config.DepthAttribute) == nil then
        model:SetAttribute(Config.DepthAttribute, size.Z)
    end
    if model:GetAttribute(Config.ModelAttribute) == nil then
        model:SetAttribute(Config.ModelAttribute, true)
    end
end

local function isProtectedThicknessPart(part)
    local n = string.lower(part.Name)
    return n:find("pull")
        or n:find("handle")
        or n:find("hinge")
        or n:find("side")
        or n:find("back")
        or n:find("rail")
        or n:find("stile")
end

local function resizeAxisAware(model, targetWidth, targetHeight, targetDepth)
    ensureAttributes(model)

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
            local newSize
            if isProtectedThicknessPart(obj) then
                -- Move protected-detail parts with the cabinet, but do not blindly thicken hardware/frame pieces.
                newSize = Vector3.new(
                    math.max(0.05, old.X * (string.lower(obj.Name):find("side") and 1 or sx)),
                    math.max(0.05, old.Y * sy),
                    math.max(0.05, old.Z * (string.lower(obj.Name):find("back") and 1 or sz))
                )
            else
                newSize = Vector3.new(old.X * sx, old.Y * sy, old.Z * sz)
            end

            obj.Size = newSize
            obj.CFrame = pivot * CFrame.new(newPos) * (localCf - localCf.Position)
        end
    end

    model:SetAttribute(Config.WidthAttribute, targetWidth)
    model:SetAttribute(Config.HeightAttribute, targetHeight)
    model:SetAttribute(Config.DepthAttribute, targetDepth)
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
    quarterTurns = quarterTurns or 1
    model:PivotTo(model:GetPivot() * CFrame.Angles(0, math.rad(90 * quarterTurns), 0))
end

function Transform.Register(model)
    assert(model and model:IsA("Model"), "Register requires a Model")
    ensureAttributes(model)
end

return Transform
