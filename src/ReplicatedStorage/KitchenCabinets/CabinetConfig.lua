-- Blueprint 3D Studio - Kitchen Cabinets
-- Single source of truth for cabinet editing limits and J&K-style behavior.

local Config = {}

Config.Units = "inches"
Config.StudsPerInch = 1

Config.Defaults = {
    Width = 24,
    Height = 34.5,
    Depth = 24,
}

Config.Limits = {
    Width = { Min = 7, Max = 44 },
    Height = { Min = 24, Max = 96 },
    Depth = { Min = 12, Max = 36 },
}

Config.StandardBaseWidths = {9,12,15,18,21,24,27,30,33,36,39,42}

-- Custom center-mass resizing may use any width inside Config.Limits.Width.
-- No legacy +/-2 inch field-adjustment cap.
Config.FieldAdjustment = {
    MaxWidthDelta = nil,
    PreferFillerBeyondDelta = false,
    FreeWidth = true,
}

Config.Fillers = {
    Base = {3,6},
}

Config.SnapIncrements = {0.125, 0.25, 0.5, 1}
Config.DefaultSnap = 0.25

Config.ProtectedDimensions = {
    SideThickness = 0.75,
    BackThickness = 0.50,
    ToeKickHeight = 4.5,
    ToeKickRecess = 3.0,
    ShakerRail = 1.5,
    DrawerDoorGap = 0.5,
}

Config.ModelAttribute = "KitchenCabinet"
Config.WidthAttribute = "WidthInches"
Config.HeightAttribute = "HeightInches"
Config.DepthAttribute = "DepthInches"
Config.NominalWidthAttribute = "NominalWidthInches"
Config.MirroredAttribute = "MirroredX"
Config.AdjustedAttribute = "FieldAdjusted"

return Config
