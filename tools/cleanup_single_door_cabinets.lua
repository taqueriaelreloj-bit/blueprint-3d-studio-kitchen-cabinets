-- ONE-TIME ROBLOX STUDIO COMMAND BAR TOOL
-- Keeps only the approved single-door base cabinets: B9, B12, B15, B18, B21.
-- It does NOT touch editor scripts, ReplicatedStorage modules, or individual cabinet parts.
-- Run this in Roblox Studio Command Bar while NOT in Play mode so the cleanup is saved in the place.

local APPROVED = {
    [9] = true,
    [12] = true,
    [15] = true,
    [18] = true,
    [21] = true,
}

local function widthFromModel(model)
    local attr = tonumber(model:GetAttribute("NominalWidthInches")) or tonumber(model:GetAttribute("WidthInches"))
    if attr then
        local rounded = math.floor(attr + 0.5)
        if APPROVED[rounded] then return rounded end
    end

    local upper = string.upper(model.Name)
    local patterns = {
        "SHAKERBASE_B(%d+)",
        "BASE_B(%d+)",
        "^B(%d+)$",
        "_B(%d+)$",
        "B(%d+)",
    }
    for _, pattern in ipairs(patterns) do
        local n = tonumber(string.match(upper, pattern))
        if n then return n end
    end
    return nil
end

local function looksLikeCabinet(model)
    if not model:IsA("Model") then return false end
    if model:GetAttribute("KitchenCabinet") == true then return true end
    if model:GetAttribute("WidthInches") ~= nil then return true end
    local upper = string.upper(model.Name)
    if string.find(upper, "SHAKERBASE", 1, true) or string.match(upper, "^B%d+") then return true end
    return model:FindFirstChild("LeftSide", true) ~= nil and model:FindFirstChild("RightSide", true) ~= nil
end

local candidates = {}
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Model") and looksLikeCabinet(obj) then
        -- Only operate on top-level cabinet models, never nested Door/Drawer models.
        local ancestorCabinet = false
        local p = obj.Parent
        while p and p ~= workspace do
            if p:IsA("Model") and looksLikeCabinet(p) then ancestorCabinet = true break end
            p = p.Parent
        end
        if not ancestorCabinet then table.insert(candidates, obj) end
    end
end

local keepByWidth = {}
local deleted = {}
local kept = {}

for _, model in ipairs(candidates) do
    local width = widthFromModel(model)
    if width and APPROVED[width] and not keepByWidth[width] then
        keepByWidth[width] = model
        table.insert(kept, model.Name .. " (B" .. width .. ")")
    else
        table.insert(deleted, model.Name)
        model:Destroy()
    end
end

print("=== Cabinet cleanup complete ===")
print("Kept:")
for _, name in ipairs(kept) do print("  KEEP  " .. name) end
print("Deleted:")
for _, name in ipairs(deleted) do print("  DELETE " .. name) end

for _, width in ipairs({9,12,15,18,21}) do
    if not keepByWidth[width] then
        warn("Missing approved cabinet B" .. width .. " - no replacement was generated.")
    end
end

print("IMPORTANT: Save the Roblox place now (Ctrl+S).")
