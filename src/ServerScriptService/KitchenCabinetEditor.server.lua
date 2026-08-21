-- Blueprint 3D Studio - Kitchen Cabinets
-- Single active server entry point for cabinet editing.
-- This script does NOT generate cabinets and does NOT duplicate existing models.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Keep ONLY the approved single-door base cabinet family in the generated cabinet folder.
-- This removes complete extra cabinet MODELS only; it never deletes child parts from a kept cabinet.
local APPROVED_SINGLE_DOOR = {
    B9 = true,
    B12 = true,
    B15 = true,
    B18 = true,
    B21 = true,
}

local function cabinetCodeFromName(name)
    local upper = string.upper(name)
    return string.match(upper, "_?(B%d+)$") or string.match(upper, "^(B%d+)$")
end

local function cleanupGeneratedCabinets()
    local generated = workspace:FindFirstChild("GeneratedShakerCabinets")
    if not generated then
        warn("Cabinet cleanup skipped: Workspace.GeneratedShakerCabinets not found")
        return
    end

    local kept = {}
    local removed = {}

    for _, child in ipairs(generated:GetChildren()) do
        if child:IsA("Model") then
            local code = cabinetCodeFromName(child.Name)
            if code and APPROVED_SINGLE_DOOR[code] and not kept[code] then
                kept[code] = child
            else
                table.insert(removed, child.Name)
                child:Destroy()
            end
        end
    end

    local missing = {}
    for code in pairs(APPROVED_SINGLE_DOOR) do
        if not kept[code] then
            table.insert(missing, code)
        end
    end
    table.sort(missing)

    print("Single-door cabinet cleanup complete. Kept: B9, B12, B15, B18, B21")
    if #removed > 0 then
        print("Removed extra cabinet models: " .. table.concat(removed, ", "))
    end
    if #missing > 0 then
        warn("Approved cabinet models missing from Workspace: " .. table.concat(missing, ", "))
    end
end

cleanupGeneratedCabinets()

local folder = ReplicatedStorage:FindFirstChild("KitchenCabinetRemotes")
if not folder then
    folder = Instance.new("Folder")
    folder.Name = "KitchenCabinetRemotes"
    folder.Parent = ReplicatedStorage
end

local editEvent = folder:FindFirstChild("EditCabinet")
if not editEvent then
    editEvent = Instance.new("RemoteEvent")
    editEvent.Name = "EditCabinet"
    editEvent.Parent = folder
end

local Transform = require(ReplicatedStorage:WaitForChild("KitchenCabinets"):WaitForChild("CabinetTransform"))

local function resolveCabinet(instance)
    local current = instance
    while current and current ~= workspace do
        if current:IsA("Model") then
            local width = current:GetAttribute("WidthInches")
            local namedCabinet = string.match(string.upper(current.Name), "^B%d+") ~= nil
            if current:GetAttribute("KitchenCabinet") == true or width ~= nil or namedCabinet then
                return current
            end
        end
        current = current.Parent
    end
    return nil
end

editEvent.OnServerEvent:Connect(function(player, target, action, payload)
    if typeof(target) ~= "Instance" then return end
    local cabinet = resolveCabinet(target)
    if not cabinet then return end

    if action == "register" then
        Transform.Register(cabinet)
    elseif action == "resize" and typeof(payload) == "table" then
        local w = tonumber(payload.width)
        local h = tonumber(payload.height)
        local d = tonumber(payload.depth)
        if w and h and d then
            Transform.Resize(cabinet, w, h, d)
        end
    elseif action == "resizeWidthFromSide" and typeof(payload) == "table" then
        local w = tonumber(payload.width)
        local side = payload.side
        if w and (side == "Left" or side == "Right") then
            Transform.ResizeWidthFromSide(cabinet, w, side)
        end
    elseif action == "mirrorX" then
        Transform.MirrorX(cabinet)
    elseif action == "rotate90" then
        Transform.Rotate90(cabinet, 1)
    elseif action == "rotateNeg90" then
        Transform.Rotate90(cabinet, -1)
    end
end)

print("Blueprint 3D Studio Kitchen Cabinet Editor loaded: no generators active")
