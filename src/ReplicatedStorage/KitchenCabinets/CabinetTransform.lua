-- Blueprint 3D Studio - Kitchen Cabinets
-- Width-only parametric transform utilities for base cabinets.
-- Resize NEVER scales height/depth and NEVER creates cabinet models.

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
    local value = string.match(string.upper(model.Name), "B(%d+)")
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
    if path:find("stile") then return "stile" end
    if path:find("rail") then return "rail" end
    if path:find("centerpanel") or path:find("panel") then return "panel" end
    if path:find("back") then return "back" end
    if path:find("toekick") then return "toe" end
    return "general"
end

local function resolveRequestedWidth(model, requested)
    ensureAttributes(model)
    requested = clamp(requested, Config.Limits.Width)
    if isStandardWidth(requested) then
        model:SetAttribute(Config.NominalWidthAttribute, requested)
        model:SetAttribute(Config.AdjustedAttribute, false)
        return requested
    end
    local nominal = model:GetAttribute(Config.NominalWidthAttribute) or requested
    local delta = Config.FieldAdjustment.MaxWidthDelta or 2
    local resolved = math.clamp(requested, nominal - delta, nominal + delta)
    model:SetAttribute(Config.AdjustedAttribute, math.abs(resolved - nominal) > EPS)
    return resolved
end

local function applyCenterMassWidth(model, targetWidth)
    local pivot = model:GetPivot()
    local _, oldSize = model:GetBoundingBox()
    if oldSize.X <= EPS then return end

    local delta = targetWidth - oldSize.X

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            local localCf = pivot:ToObjectSpace(obj.CFrame)
            local p = localCf.Position
            local kind = category(obj)
            local newX = p.X
            local newSizeX = obj.Size.X

            if kind == "hardware" then
                -- Pulls/hinges keep exact size; centered hardware stays centered.
                -- Off-center hardware follows its nearest edge without stretching.
                if math.abs(p.X) > EPS then
                    newX = p.X + (p.X > 0 and delta/2 or -delta/2)
                end
            elseif kind == "side" or kind == "stile" then
                -- Fixed edge material: preserve thickness and move outward/inward by half delta.
                if math.abs(p.X) > EPS then
                    newX = p.X + (p.X > 0 and delta/2 or -delta/2)
                end
            else
                -- Center-mass rule: add/remove material through the middle span.
                -- Y/Z dimensions and positions are intentionally untouched.
                newSizeX = math.max(0.05, obj.Size.X + delta)
            end

            obj.Size = Vector3.new(newSizeX, obj.Size.Y, obj.Size.Z)
            obj.CFrame = pivot * CFrame.new(newX, p.Y, p.Z) * (localCf - localCf.Position)
        end
    end
end

local function correctExactWidth(model, targetWidth)
    for _ = 1, 6 do
        local _, size = model:GetBoundingBox()
        local errorX = targetWidth - size.X
        if math.abs(errorX) <= 0.002 then break end
        applyCenterMassWidth(model, targetWidth)
    end
    local _, finalSize = model:GetBoundingBox()
    return finalSize
end

function Transform.ResizeWidth(model, requestedWidth)
    assert(model and model:IsA("Model"), "ResizeWidth requires a Model")
    ensureAttributes(model)

    local originalHeight = model:GetAttribute(Config.HeightAttribute) or getModelSize(model).Y
    local originalDepth = model:GetAttribute(Config.DepthAttribute) or getModelSize(model).Z
    local targetWidth = resolveRequestedWidth(model, requestedWidth)

    applyCenterMassWidth(model, targetWidth)
    local finalSize = correctExactWidth(model, targetWidth)

    model:SetAttribute(Config.WidthAttribute, finalSize.X)
    -- Base cabinet resize is WIDTH ONLY. Preserve the original logical H/D.
    model:SetAttribute(Config.HeightAttribute, originalHeight)
    model:SetAttribute(Config.DepthAttribute, originalDepth)
    model:SetAttribute("RequestedWidthInches", requestedWidth)
    model:SetAttribute("WidthErrorInches", finalSize.X - targetWidth)

    return finalSize.X, originalHeight, originalDepth
end

function Transform.Resize(model, width, _height, _depth)
    -- Compatibility entry point used by the existing UI/server.
    -- Height/depth arguments are intentionally ignored for base cabinets.
    return Transform.ResizeWidth(model, width)
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
