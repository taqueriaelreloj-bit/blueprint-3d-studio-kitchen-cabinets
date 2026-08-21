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

local function isPullContainer(instance)
    if not instance or instance:IsA("BasePart") then return false end
    local name = string.lower(instance.Name)
    return name:find("pull") ~= nil or name:find("handle") ~= nil
end

local function getPullContainer(part, cabinetModel)
    local current = part.Parent
    while current and current ~= cabinetModel do
        if isPullContainer(current) then return current end
        current = current.Parent
    end
    return nil
end

local function category(obj)
    local path = ancestryText(obj)
    local name = string.lower(obj.Name)
    if path:find("pull") or path:find("handle") or path:find("hinge") then return "hardware" end
    if name:find("leftside") or name:find("rightside") then return "fixedEdge" end
    if name:find("leftstile") or name:find("rightstile") or name:find("stile") then return "fixedEdge" end
    if name == "drawerleft" or name == "drawerright" then return "fixedEdge" end
    if name == "drawerbottom" or name == "drawerback" then return "stretch" end
    if name:find("toprail") or name:find("bottomrail") or name:find("rail") then return "stretch" end
    if name:find("centerpanel") or name == "panel" or path:find("centerpanel") then return "stretch" end
    if name:find("back") then return "stretch" end
    if name:find("toekick") then return "stretch" end
    return "stretch"
end

local function resolveRequestedWidth(model, requested)
    ensureAttributes(model)
    local resolved = clamp(requested, Config.Limits.Width)
    local nominal = model:GetAttribute(Config.NominalWidthAttribute) or resolved
    model:SetAttribute(Config.AdjustedAttribute, math.abs(resolved - nominal) > EPS)
    return resolved
end

local function collectPullGroups(model, pivot)
    local groups = {}
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") then
            local container = getPullContainer(obj, model)
            if container then
                local group = groups[container]
                if not group then
                    group = { parts = {}, minX = math.huge, maxX = -math.huge, minY = math.huge, maxY = -math.huge }
                    groups[container] = group
                end
                local localCf = pivot:ToObjectSpace(obj.CFrame)
                local p = localCf.Position
                table.insert(group.parts, { part = obj, localCf = localCf, size = obj.Size })
                group.minX = math.min(group.minX, p.X)
                group.maxX = math.max(group.maxX, p.X)
                group.minY = math.min(group.minY, p.Y)
                group.maxY = math.max(group.maxY, p.Y)
            end
        end
    end
    for _, group in pairs(groups) do
        group.centerX = (group.minX + group.maxX) / 2
        group.spanX = group.maxX - group.minX
        group.spanY = group.maxY - group.minY
        group.horizontal = group.spanX >= group.spanY
    end
    return groups
end

local function applyPullGroups(groups, pivot, delta, widthScale)
    for _, group in pairs(groups) do
        local groupShiftX = 0
        if math.abs(group.centerX) > EPS then
            groupShiftX = group.centerX > 0 and delta/2 or -delta/2
        end
        for _, saved in ipairs(group.parts) do
            local part = saved.part
            local p = saved.localCf.Position
            local name = string.lower(part.Name)
            local relativeX = p.X - group.centerX
            local newX = p.X + groupShiftX
            local newSize = saved.size
            if group.horizontal then
                newX = group.centerX + groupShiftX + (relativeX * widthScale)
                if name:find("bar") or name:find("rail") or name:find("center") then
                    newSize = Vector3.new(math.max(0.05, saved.size.X * widthScale), saved.size.Y, saved.size.Z)
                end
            end
            part.Size = newSize
            part.CFrame = pivot * CFrame.new(newX, p.Y, p.Z) * (saved.localCf - saved.localCf.Position)
        end
    end
end

local function applyCenterMassWidth(model, targetWidth)
    local pivot = model:GetPivot()
    local _, oldSize = model:GetBoundingBox()
    if oldSize.X <= EPS then return end
    local delta = targetWidth - oldSize.X
    local widthScale = targetWidth / oldSize.X
    local pullGroups = collectPullGroups(model, pivot)

    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA("BasePart") and not getPullContainer(obj, model) then
            local localCf = pivot:ToObjectSpace(obj.CFrame)
            local p = localCf.Position
            local kind = category(obj)
            local newX = p.X
            local newSizeX = obj.Size.X
            if kind == "hardware" then
                if math.abs(p.X) > EPS then newX = p.X + (p.X > 0 and delta/2 or -delta/2) end
            elseif kind == "fixedEdge" then
                if math.abs(p.X) > EPS then newX = p.X + (p.X > 0 and delta/2 or -delta/2) end
            else
                newSizeX = math.max(0.05, obj.Size.X + delta)
            end
            obj.Size = Vector3.new(newSizeX, obj.Size.Y, obj.Size.Z)
            obj.CFrame = pivot * CFrame.new(newX, p.Y, p.Z) * (localCf - localCf.Position)
        end
    end
    applyPullGroups(pullGroups, pivot, delta, widthScale)
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
    model:SetAttribute(Config.HeightAttribute, originalHeight)
    model:SetAttribute(Config.DepthAttribute, originalDepth)
    model:SetAttribute("RequestedWidthInches", requestedWidth)
    model:SetAttribute("WidthErrorInches", finalSize.X - targetWidth)
    return finalSize.X, originalHeight, originalDepth
end

function Transform.ResizeWidthFromSide(model, requestedWidth, side)
    assert(model and model:IsA("Model"), "ResizeWidthFromSide requires a Model")
    assert(side == "Left" or side == "Right", "side must be Left or Right")
    ensureAttributes(model)

    local oldWidth = model:GetAttribute(Config.WidthAttribute) or getModelSize(model).X
    local oldPivot = model:GetPivot()
    local finalWidth, h, d = Transform.ResizeWidth(model, requestedWidth)
    local delta = finalWidth - oldWidth

    -- Keep the opposite cabinet edge anchored while dragging one side.
    -- Right handle moves cabinet center +delta/2; Left handle moves -delta/2.
    local sign = side == "Right" and 1 or -1
    local shift = oldPivot.RightVector * (delta * 0.5 * sign)
    model:PivotTo(model:GetPivot() + shift)

    return finalWidth, h, d
end

function Transform.Resize(model, width, _height, _depth)
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
