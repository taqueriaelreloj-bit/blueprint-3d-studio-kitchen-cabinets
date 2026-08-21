-- Blueprint 3D Studio - Kitchen Cabinets
-- Single active server entry point for cabinet editing.
-- This script does NOT generate cabinets and does NOT duplicate existing models.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
    elseif action == "mirrorX" then
        Transform.MirrorX(cabinet)
    elseif action == "rotate90" then
        Transform.Rotate90(cabinet, 1)
    elseif action == "rotateNeg90" then
        Transform.Rotate90(cabinet, -1)
    end
end)

print("Blueprint 3D Studio Kitchen Cabinet Editor loaded: no generators active")
