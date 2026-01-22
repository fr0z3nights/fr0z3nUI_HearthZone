local addonName, ns = ...

local PREFIX = "|cff00ccff[FHZ]|r "
local function Print(msg)
  print(PREFIX .. tostring(msg or ""))
end

-- Macro text builder (kept short-ish but still readable).
local function BuildMacroRunLine(itemID)
  itemID = tonumber(itemID) or 6948
  return string.format(
    "/run local s,d=GetItemCooldown(%d); s=s+d-GetTime(); local to=(fHZ and fHZ.GetHomeText and fHZ:GetHomeText()) or \"\"; if s>1 then print(format(\"Hearthing in %%d mins to %%s\", s/60, to)) else print(format(\"Hearthing to %%s\", to)) end",
    itemID
  )
end
local MACRO_NAME = "fHZ"

-- Curated hearth-style toys/items (IDs provided by user).
-- Note: Some IDs seen online are often confused/reused in lists; the "All" toggle + search
-- lets you pick any owned toy even if an ID here is wrong.
local CURATED_USE_ITEMS = {
  { id = 263489, label = "Naaru's Enfold" },
  { id = 246565, label = "Cosmic Hearthstone" },
  { id = 245970, label = "P.O.S.T. Master's Express Hearthstone" },
  { id = 236687, label = "Explosive Hearthstone" },
  { id = 235016, label = "Redeployment Module" },
  { id = 228940, label = "Notorious Thread's Hearthstone" },
  { id = 228834, label = "Explosive Hearthstone (alt)" },
  { id = 228833, label = "Redeployment Module (alt)" },
  { id = 213327, label = "Stone of the Hearth (alt)" },
  { id = 212337, label = "Stone of the Hearth" },
  { id = 210629, label = "Deepdweller's Earthen Hearthstone (alt)" },
  { id = 210455, label = "Draenic Hologem" },
  { id = 209035, label = "Hearthstone of the Flame" },
  { id = 208704, label = "Deepdweller's Earthen Hearthstone" },
  { id = 206195, label = "Path of the Naaru" },
  { id = 200630, label = "Ohn'ir Windsage's Hearthstone" },
  { id = 193588, label = "Timewalker's Hearthstone" },
  { id = 190237, label = "Broker Translocation Matrix" },
  { id = 190196, label = "Enlightened Hearthstone" },
  { id = 188952, label = "Dominated Hearthstone" },
  { id = 184353, label = "Kyrian Hearthstone" },
  { id = 183716, label = "Venthyr Sinstone" },
  { id = 183710, label = "Venthyr Sinstone (alt)" },
  { id = 183709, label = "Necrolord Hearthstone (alt)" },
  { id = 183708, label = "Night Fae Hearthstone (alt)" },
  { id = 182773, label = "Necrolord Hearthstone" },
  { id = 180290, label = "Night Fae Hearthstone" },
  { id = 172179, label = "Eternal Traveler's Hearthstone" },
  { id = 168907, label = "Holographic Digitalization Hearthstone" },
  { id = 166747, label = "Brewfest Reveler's Hearthstone" },
  { id = 166746, label = "Fire Eater's Hearthstone" },
  { id = 165802, label = "Noble Gardener's Hearthstone" },
  { id = 165670, label = "Peddlefeet's Lovely Hearthstone" },
  { id = 165669, label = "Lunar Elder's Hearthstone" },
  { id = 163045, label = "Headless Horseman's Hearthstone" },
  { id = 162973, label = "Greatfather Winter's Hearthstone" },
  { id = 142542, label = "Tome of Town Portal" },
  { id =  93672, label = "Dark Portal" },
  { id =  64488, label = "The Innkeeper's Daughter" },
  { id =  54452, label = "Ethereal Portal" },
  -- Hearthstone item (not a toy) is handled separately (6948).
}

local function InCombat()
  return InCombatLockdown and InCombatLockdown() or false
end

local function SafeLower(s)
  return tostring(s or ""):lower()
end

local function GetItemNameByID(itemID)
  if C_Item and C_Item.GetItemNameByID then
    return C_Item.GetItemNameByID(itemID)
  end
  return nil
end

local function GetItemCountByID(itemID)
  if C_Item and C_Item.GetItemCount then
    return C_Item.GetItemCount(itemID) or 0
  end
  return 0
end

local function IsDraeneiPlayer()
  if UnitRace then
    local _, raceFile = UnitRace("player")
    return raceFile == "Draenei"
  end
  return false
end

local function GetCharKey()
  if UnitFullName then
    local name, realm = UnitFullName("player")
    if name and realm and realm ~= "" then
      return tostring(name) .. "-" .. tostring(realm)
    end
  end
  return tostring(UnitName("player") or "") .. "-" .. tostring(GetRealmName() or "")
end

local function EnsureInit()
  -- Per-character DB (SavedVariablesPerCharacter in the .toc)
  if not _G.fr0z3nUI_HearthZoneCharDB then
    _G.fr0z3nUI_HearthZoneCharDB = {}
  end
  local db = _G.fr0z3nUI_HearthZoneCharDB
  local charKey = GetCharKey()

  if db[charKey] == nil then
    db[charKey] = ""
  end

  if type(db.window) ~= "table" then
    db.window = { point = "CENTER", relPoint = "CENTER", x = 0, y = 0 }
  end

  if db.selectedUseItemID ~= nil then
    db.selectedUseItemID = tonumber(db.selectedUseItemID)
  end

  if db.autoRotate ~= nil then
    db.autoRotate = db.autoRotate and true or false
  else
    db.autoRotate = false
  end

  if db.toyShowAll ~= nil then
    db.toyShowAll = db.toyShowAll and true or false
  else
    db.toyShowAll = false
  end

  if db.toyFilter ~= nil then
    db.toyFilter = tostring(db.toyFilter)
  else
    db.toyFilter = ""
  end

  return db, charKey
end

local function HasUseItem(itemID)
  itemID = tonumber(itemID)
  if not itemID then return false end

  -- Draenic Hologem appears to be race-gated / unreliable for non-Draenei.
  if itemID == 210455 and not IsDraeneiPlayer() then
    return false
  end

  if itemID == 6948 then
    return (GetItemCountByID(6948) or 0) > 0
  end
  if PlayerHasToy and PlayerHasToy(itemID) then
    return true
  end
  return (GetItemCountByID(itemID) or 0) > 0
end

local function GetUseItemName(itemID, fallback)
  itemID = tonumber(itemID)
  if not itemID then return tostring(fallback or "") end
  if itemID == 6948 then
    return "Hearthstone"
  end
  return GetItemNameByID(itemID) or tostring(fallback or ("item:" .. tostring(itemID)))
end

local function GetToyCooldownStart(itemID)
  itemID = tonumber(itemID)
  if not itemID then return 0 end
  if PlayerHasToy and PlayerHasToy(itemID) and C_ToyBox and C_ToyBox.GetToyCooldown then
    local startTime, duration = C_ToyBox.GetToyCooldown(itemID)
    startTime = tonumber(startTime) or 0
    duration = tonumber(duration) or 0
    if startTime > 0 and duration > 0 then
      return startTime
    end
    return 0
  end
  if C_Item and C_Item.GetItemCooldown then
    local startTime, duration = C_Item.GetItemCooldown(itemID)
    startTime = tonumber(startTime) or 0
    duration = tonumber(duration) or 0
    if startTime > 0 and duration > 0 then
      return startTime
    end
  end
  return 0
end

local function RollRandomUseItem(db)
  if type(db) ~= "table" then return nil end
  local pool = {}
  for _, e in ipairs(CURATED_USE_ITEMS) do
    local id = tonumber(e.id)
    if id and HasUseItem(id) then
      pool[#pool + 1] = id
    end
  end
  if HasUseItem(6948) then
    pool[#pool + 1] = 6948
  end
  if #pool == 0 then
    return nil
  end
  local pick = pool[math.random(1, #pool)]
  db.selectedUseItemID = pick
  return pick
end

local function BuildMacroText(db)
  local useID = db and tonumber(db.selectedUseItemID)
  if useID and not HasUseItem(useID) then
    useID = nil
  end
  local lines = { BuildMacroRunLine(useID or 6948) }
  if useID and useID > 0 then
    lines[#lines + 1] = "/use item:" .. tostring(useID)
  end
  return table.concat(lines, "\n")
end

local function GetOwnedHearthToys()
  local out = {}

  -- Include the default Hearthstone item if it exists in bags (not a toy).
  local hsCount = GetItemCountByID(6948)
  if hsCount and hsCount > 0 then
    out[#out + 1] = { id = 6948, name = "Hearthstone (item)" }
  end

  if not (C_ToyBox and C_ToyBox.GetNumToys and C_ToyBox.GetToyFromIndex and PlayerHasToy) then
    return out
  end

  local n = C_ToyBox.GetNumToys() or 0
  for i = 1, n do
    local itemID = C_ToyBox.GetToyFromIndex(i)
    if itemID and PlayerHasToy(itemID) then
      if C_Item and C_Item.RequestLoadItemDataByID then
        C_Item.RequestLoadItemDataByID(itemID)
      end
      local name = GetItemNameByID(itemID)
      out[#out + 1] = { id = itemID, name = name or ("Toy " .. tostring(itemID)) }
    end
  end

  table.sort(out, function(a, b)
    return SafeLower(a.name) < SafeLower(b.name)
  end)

  return out
end

local function PassToyFilter(toyName, filterText)
  local ft = SafeLower(filterText)
  if ft == "" then return true end
  local tn = SafeLower(toyName)
  return tn:find(ft, 1, true) ~= nil
end

-- Public API for macros.
-- Preferred: /run fHZ:GetZone()
_G.fHZ = _G.fHZ or {}

function _G.fHZ:GetZone()
  local db, charKey = EnsureInit()
  local bind = GetBindLocation() or ""
  local zone = db[charKey] or ""

  if zone == "" then
    Print(bind)
  else
    Print("|cFFFFD707Home Set To " .. bind .. ", " .. zone)
  end
end

-- Macro-friendly helper (returns text, does not print).
-- Example: /run print("Hearthing to "..(fHZ:GetHomeText() or ""))
function _G.fHZ:GetHomeText()
  local db, charKey = EnsureInit()
  local bind = GetBindLocation() or ""
  local zone = db[charKey] or ""
  if zone == "" then
    return bind
  end
  if bind == "" then
    return zone
  end
  return bind .. ", " .. zone
end

local function GetCurrentDisplayText()
  local db, charKey = EnsureInit()
  local bind = GetBindLocation() or ""
  local zone = db[charKey] or ""
  if zone == "" then
    return bind, "(zone not captured yet — set your hearth once)"
  end
  return bind, zone
end

local function EnsureGUI()
  if _G.fHZ and _G.fHZ._frame then
    return _G.fHZ._frame
  end

  local db = EnsureInit()
  local frame = CreateFrame("Frame", "fHZFrame", UIParent, "BackdropTemplate")
  frame:SetSize(360, 270)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    if self.StartMoving then self:StartMoving() end
  end)
  frame:SetScript("OnDragStop", function(self)
    if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    local db2 = EnsureInit()
    local point, _, relPoint, x, y = self:GetPoint(1)
    db2.window.point = point
    db2.window.relPoint = relPoint
    db2.window.x = math.floor((x or 0) + 0.5)
    db2.window.y = math.floor((y or 0) + 0.5)
  end)

  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.55)
  end

  frame:SetPoint(db.window.point or "CENTER", UIParent, db.window.relPoint or "CENTER", db.window.x or 0,
    db.window.y or 0)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", 10, -8)
  title:SetText("|cff00ccffFHZ|r HearthZone")

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -2, -2)

  local mainWidgets, macrosWidgets = {}, {}
  local function AddWidget(list, w)
    if w then
      list[#list + 1] = w
    end
    return w
  end

  local tabMacros = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  tabMacros:SetSize(72, 18)
  tabMacros:SetPoint("TOPRIGHT", close, "TOPLEFT", -6, -2)
  tabMacros:SetText("Macros")

  local tabHearth = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  tabHearth:SetSize(72, 18)
  tabHearth:SetPoint("TOPRIGHT", tabMacros, "TOPLEFT", -6, 0)
  tabHearth:SetText("Hearth")

  local function SetButtonTooltip(btn, tooltipText)
    if not (btn and tooltipText) then return end
    btn:SetScript("OnEnter", function(self)
      if not GameTooltip then return end
      local tt = tooltipText
      if type(tt) == "function" then
        tt = tt(self)
      end
      if not tt or tt == "" then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      local first = true
      for line in tostring(tt):gmatch("[^\n]+") do
        if first then
          GameTooltip:SetText(line, 1, 1, 1)
          first = false
        else
          GameTooltip:AddLine(line, 0.9, 0.9, 0.9, true)
        end
      end
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
      if GameTooltip then GameTooltip:Hide() end
    end)
  end

  local bindLabel = AddWidget(mainWidgets, frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
  bindLabel:SetPoint("TOPLEFT", 10, -32)
  bindLabel:SetText("Hearth:")

  local bindText = AddWidget(mainWidgets, frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
  bindText:SetPoint("TOPLEFT", 60, -32)
  bindText:SetPoint("TOPRIGHT", -10, -32)
  bindText:SetJustifyH("LEFT")
  bindText:SetText("")

  local zoneLabel = AddWidget(mainWidgets, frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
  zoneLabel:SetPoint("TOPLEFT", 10, -52)
  zoneLabel:SetText("Zone:")

  local zoneText = AddWidget(mainWidgets, frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
  zoneText:SetPoint("TOPLEFT", 60, -52)
  zoneText:SetPoint("TOPRIGHT", -10, -52)
  zoneText:SetJustifyH("LEFT")
  zoneText:SetText("")

  local toyLabel = AddWidget(mainWidgets, frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
  toyLabel:SetPoint("TOPLEFT", 10, -74)
  toyLabel:SetText("Use toy:")

  local toyFilterBox = AddWidget(mainWidgets, CreateFrame("EditBox", nil, frame, "InputBoxTemplate"))
  toyFilterBox:SetSize(140, 18)
  toyFilterBox:SetPoint("TOPLEFT", 10, -94)
  toyFilterBox:SetAutoFocus(false)
  toyFilterBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  local toyShowAll = AddWidget(mainWidgets, CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate"))
  toyShowAll:SetPoint("TOPLEFT", 160, -94)
  if toyShowAll.Text and toyShowAll.Text.SetText then
    toyShowAll.Text:SetText("All")
  elseif toyShowAll.text and toyShowAll.text.SetText then
    toyShowAll.text:SetText("All")
  end

  local toyDrop = AddWidget(mainWidgets, CreateFrame("Frame", "fHZToyDropDown", frame, "UIDropDownMenuTemplate"))
  toyDrop:SetPoint("TOPLEFT", 52, -66)

  local autoRotate = AddWidget(mainWidgets, CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate"))
  autoRotate:SetPoint("TOPLEFT", 210, -94)
  if autoRotate.Text and autoRotate.Text.SetText then
    autoRotate.Text:SetText("Auto")
  elseif autoRotate.text and autoRotate.text.SetText then
    autoRotate.text:SetText("Auto")
  end

  local rollBtn = AddWidget(mainWidgets, CreateFrame("Button", nil, frame, "UIPanelButtonTemplate"))
  rollBtn:SetSize(56, 18)
  rollBtn:SetPoint("TOPLEFT", 276, -94)
  rollBtn:SetText("Roll")

  local UDDM_SetWidth = _G and rawget(_G, "UIDropDownMenu_SetWidth")
  local UDDM_SetText = _G and rawget(_G, "UIDropDownMenu_SetText")
  local UDDM_Initialize = _G and rawget(_G, "UIDropDownMenu_Initialize")
  local UDDM_CreateInfo = _G and rawget(_G, "UIDropDownMenu_CreateInfo")
  local UDDM_AddButton = _G and rawget(_G, "UIDropDownMenu_AddButton")

  if UDDM_SetWidth then UDDM_SetWidth(toyDrop, 200) end

  local function RefreshToyDropText()
    local db2 = EnsureInit()
    local selected = tonumber(db2.selectedUseItemID)
    if not selected then
      if UDDM_SetText then UDDM_SetText(toyDrop, "None") end
      return
    end
    local nm = GetUseItemName(selected)
    if UDDM_SetText then UDDM_SetText(toyDrop, nm or ("item:" .. tostring(selected))) end
  end

  if UDDM_Initialize and UDDM_CreateInfo and UDDM_AddButton then
    UDDM_Initialize(toyDrop, function(self, level)
      level = level or 1
      if level ~= 1 then return end

      local db2 = EnsureInit()
      local selected = tonumber(db2.selectedUseItemID)
      local filterText = tostring(db2.toyFilter or "")

      local shown = 0

      local info = UDDM_CreateInfo()
      info.text = "None"
      info.checked = (selected == nil)
      info.func = function()
        db2.selectedUseItemID = nil
        RefreshToyDropText()
      end
      UDDM_AddButton(info, level)

      -- Curated list: show even if not owned (disabled).
      for _, e in ipairs(CURATED_USE_ITEMS) do
        local id = tonumber(e.id)
        if id then
          local name = GetUseItemName(id, e.label)
          if PassToyFilter(name, filterText) then
            local i3 = UDDM_CreateInfo()
            i3.text = tostring(name)
            i3.checked = (selected == id)
            local owned = HasUseItem(id)
            i3.disabled = owned ~= true
            i3.func = function()
              if not owned then return end
              db2.selectedUseItemID = id
              RefreshToyDropText()
            end
            UDDM_AddButton(i3, level)
            shown = shown + 1
          end
        end
      end

      -- Optionally show all owned toys (big list).
      if db2.toyShowAll then
        local toys = GetOwnedHearthToys()
        for _, t in ipairs(toys) do
          if PassToyFilter(t.name, filterText) then
            local info2 = UDDM_CreateInfo()
            info2.text = tostring(t.name or ("item:" .. tostring(t.id)))
            info2.checked = (selected == tonumber(t.id))
            info2.func = function()
              db2.selectedUseItemID = tonumber(t.id)
              RefreshToyDropText()
            end
            UDDM_AddButton(info2, level)
            shown = shown + 1
          end
        end
      end

      if shown == 0 then
        local none = UDDM_CreateInfo()
        none.text = "(no matches)"
        none.disabled = true
        UDDM_AddButton(none, level)
      end
    end)
  else
    toyLabel:SetText("Use toy: (dropdown unavailable)")
  end

  toyFilterBox:SetScript("OnShow", function(self)
    local db2 = EnsureInit()
    self:SetText(tostring(db2.toyFilter or ""))
  end)
  toyFilterBox:SetScript("OnEnterPressed", function(self)
    local db2 = EnsureInit()
    db2.toyFilter = tostring(self:GetText() or "")
    self:ClearFocus()
    RefreshToyDropText()
  end)
  toyFilterBox:SetScript("OnEditFocusLost", function(self)
    local db2 = EnsureInit()
    db2.toyFilter = tostring(self:GetText() or "")
    RefreshToyDropText()
  end)

  toyShowAll:SetScript("OnShow", function(self)
    local db2 = EnsureInit()
    self:SetChecked(db2.toyShowAll and true or false)
  end)
  toyShowAll:SetScript("OnClick", function(self)
    local db2 = EnsureInit()
    db2.toyShowAll = self:GetChecked() and true or false
    RefreshToyDropText()
  end)

  autoRotate:SetScript("OnShow", function(self)
    local db2 = EnsureInit()
    self:SetChecked(db2.autoRotate and true or false)
  end)
  autoRotate:SetScript("OnClick", function(self)
    local db2 = EnsureInit()
    db2.autoRotate = self:GetChecked() and true or false
  end)

  rollBtn:SetScript("OnClick", function()
    if InCombat() then
      Print("Can't roll in combat.")
      return
    end
    local db2 = EnsureInit()
    local id = RollRandomUseItem(db2)
    if id then
      Print("Rolled: " .. GetUseItemName(id))
    else
      Print("No usable hearth toys found.")
    end
    RefreshToyDropText()
  end)

  local cmdLabel = AddWidget(mainWidgets, frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
  cmdLabel:SetPoint("BOTTOMLEFT", 10, 62)
  cmdLabel:SetText("Macro cmd:")

  local cmdBox = AddWidget(mainWidgets, CreateFrame("EditBox", nil, frame, "InputBoxTemplate"))
  cmdBox:SetSize(180, 18)
  cmdBox:SetPoint("BOTTOMLEFT", 80, 58)
  cmdBox:SetAutoFocus(false)
  do
    local useID = tonumber(db.selectedUseItemID)
    if useID and not HasUseItem(useID) then
      useID = nil
    end
    cmdBox:SetText(BuildMacroRunLine(useID or 6948))
  end
  cmdBox:SetCursorPosition(0)
  cmdBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  cmdBox:SetScript("OnEditFocusGained", function(self)
    self:HighlightText(0, #self:GetText())
  end)
  cmdBox:SetScript("OnMouseUp", function(self)
    self:SetFocus()
    self:HighlightText(0, #self:GetText())
  end)

  -- Transparent click-to-select button over the command box.
  local cmdBtn = AddWidget(mainWidgets, CreateFrame("Button", nil, frame))
  cmdBtn:SetAllPoints(cmdBox)
  cmdBtn:SetScript("OnClick", function()
    local db2 = EnsureInit()
    local useID = tonumber(db2.selectedUseItemID)
    if useID and not HasUseItem(useID) then
      useID = nil
    end
    cmdBox:SetText(BuildMacroRunLine(useID or 6948))
    cmdBox:SetFocus()
    cmdBox:HighlightText(0, #cmdBox:GetText())
  end)

  local macroBtn = AddWidget(mainWidgets, CreateFrame("Button", nil, frame, "UIPanelButtonTemplate"))
  macroBtn:SetSize(110, 20)
  macroBtn:SetPoint("BOTTOMRIGHT", -10, 58)
  macroBtn:SetText("Create Macro")

  local function TryCreateMacro()
    if InCombat() then
      Print("Can't create macros in combat.")
      return
    end
    if type(GetMacroIndexByName) ~= "function" or type(CreateMacro) ~= "function" then
      Print("Macro API unavailable.")
      return
    end
    local db2 = EnsureInit()
    if db2.autoRotate and not db2.selectedUseItemID then
      RollRandomUseItem(db2)
    end
    local body = BuildMacroText(db2)
    local idx = GetMacroIndexByName(MACRO_NAME)
    if idx and idx > 0 then
      if type(EditMacro) == "function" then
        EditMacro(idx, MACRO_NAME, "INV_Misc_QuestionMark", body)
        Print("Updated macro '" .. MACRO_NAME .. "'.")
      else
        Print("Macro '" .. MACRO_NAME .. "' already exists.")
      end
      return
    end
    local ok = CreateMacro(MACRO_NAME, "INV_Misc_QuestionMark", body, false)
    if ok then
      Print("Created macro '" .. MACRO_NAME .. "'.")
    else
      Print("Could not create macro (macro slots full?).")
    end
  end

  macroBtn:SetScript("OnClick", TryCreateMacro)

  local refreshBtn = AddWidget(mainWidgets, CreateFrame("Button", nil, frame, "UIPanelButtonTemplate"))
  refreshBtn:SetSize(70, 18)
  refreshBtn:SetPoint("BOTTOMLEFT", 10, 10)
  refreshBtn:SetText("Refresh")

  -- Macros tab content
  local function GetMacroPerCharSetting()
    local db2 = EnsureInit()
    local w = db2.window or {}
    return w.macroPerChar and true or false
  end

  local macroScopeBtn = AddWidget(macrosWidgets, CreateFrame("Button", nil, frame))
  macroScopeBtn:SetSize(240, 26)
  macroScopeBtn:SetPoint("TOP", 0, -32)

  local macroScopeText = AddWidget(macrosWidgets, macroScopeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"))
  macroScopeText:SetAllPoints(macroScopeBtn)
  macroScopeText:SetJustifyH("CENTER")

  local macroScopeHint = AddWidget(macrosWidgets, frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"))
  macroScopeHint:SetPoint("TOP", macroScopeBtn, "BOTTOM", 0, -2)
  macroScopeHint:SetJustifyH("CENTER")

  local function UpdateMacroScopeUI()
    local perChar = GetMacroPerCharSetting()
    if perChar then
      macroScopeText:SetText("CHARACTER MACRO")
      macroScopeHint:SetText("Click to Switch to Account Macro")
    else
      macroScopeText:SetText("ACCOUNT MACRO")
      macroScopeHint:SetText("Click to Switch to Character Macro")
    end
  end

  macroScopeBtn:SetScript("OnClick", function()
    local db2 = EnsureInit()
    db2.window = db2.window or {}
    db2.window.macroPerChar = not (db2.window.macroPerChar and true or false)
    UpdateMacroScopeUI()
  end)
  macroScopeBtn:SetScript("OnShow", UpdateMacroScopeUI)
  macroScopeHint:SetScript("OnShow", UpdateMacroScopeUI)

  local function CreateOrUpdateNamedMacro(name, body, perCharacter)
    if InCombat() then
      Print("Can't create macros in combat.")
      return
    end
    if type(GetMacroIndexByName) ~= "function" or type(CreateMacro) ~= "function" then
      Print("Macro API unavailable.")
      return
    end
    if type(body) ~= "string" or body == "" then
      Print("Nothing to write for macro '" .. tostring(name) .. "'.")
      return
    end
    local idx = GetMacroIndexByName(name)
    if idx and idx > 0 then
      if type(EditMacro) == "function" then
        EditMacro(idx, name, "INV_Misc_QuestionMark", body)
        Print("Updated macro '" .. tostring(name) .. "'.")
      else
        Print("Macro '" .. tostring(name) .. "' already exists.")
      end
      return
    end
    if perCharacter == nil then
      local db2 = EnsureInit()
      local w = db2.window or {}
      perCharacter = w.macroPerChar and true or false
    else
      perCharacter = perCharacter and true or false
    end

    local ok = CreateMacro(name, "INV_Misc_QuestionMark", body, perCharacter)
    if ok then
      Print("Created macro '" .. tostring(name) .. "'.")
    else
      Print("Could not create macro '" .. tostring(name) .. "' (macro slots full?).")
    end
  end

  local function MacroBody_HS_Garrison()
    return table.concat({
      "#showtooltip item:110560",
      "/run local s,d=GetItemCooldown(110560); s=s+d-GetTime(); print(format(s>1 and \"Hearthing to Garrison in %d mins\" or \"Hearthing to Garrison\", s/60))",
      "/use item:110560",
    }, "\n")
  end

  local function MacroBody_HS_Dalaran()
    return table.concat({
      "#showtooltip item:140192",
      "/run local s,d=GetItemCooldown(140192); s=s+d-GetTime(); print(format(s>1 and \"Hearthing to Dalaran in %d mins\" or \"Hearthing to Dalaran\", s/60))",
      "/use item:140192",
    }, "\n")
  end

  local function MacroBody_HS_Whistle()
    return table.concat({
      "#showtooltip item:141605",
      "/run local s,d=GetItemCooldown(141605); s=s+d-GetTime(); print(format(s>1 and \"Whistle in %d mins\" or \"Whistles\", s/60))",
      "/use item:141605",
      "/use item:205255",
    }, "\n")
  end

  local function MacroBody_HS_Dornogal()
    return table.concat({
      "#showtooltip item:243056",
      "/run local s,d=GetItemCooldown(243056); s=s+d-GetTime(); print(format(s>1 and \"Portal to Dornogal in %d mins\" or \"Portal to Dornogal Opening\", s/60))",
      "/use item:243056",
    }, "\n")
  end

  local function MacroBody_InstanceIO()
    return table.concat({
      "/run LFGTeleport(IsInLFGDungeon())",
      "/run LFGTeleport(IsInLFGDungeon())",
      "/run print(\"Attempting Dungeon Teleport\")",
    }, "\n")
  end

  local function MacroBody_InstanceReset()
    return "/script ResetInstances();"
  end

  local function MacroBody_Rez()
    return table.concat({
      "/use Ancestral Spirit",
      "/cast Redemption",
      "/cast Resurrection",
      "/cast Resuscitate",
      "/cast Return",
      "/cast Revive",
      "/cast Raise Ally",
    }, "\n")
  end

  local function MacroBody_RezCombat()
    return table.concat({
      "/cast Rebirth",
      "/cast Intercession",
      "/cast Raise Ally",
    }, "\n")
  end

  local function MacroBody_ScriptErrors()
    return "/run local k=\"ScriptErrors\"; local v=tonumber(C_CVar.GetCVar(k)) or 0; C_CVar.SetCVar(k, v==1 and 0 or 1); print(\"ScriptErrors \"..(v==1 and \"Disabled\" or \"Enabled\"))"
  end

  local visitTagBox

  local function SanitizeMacroTag(s)
    s = tostring(s or "")
    s = s:gsub("^%s+", ""):gsub("%s+$", "")
    s = s:gsub("%s+", " ")
    if s == "" then return nil end
    if #s > 8 then
      s = s:sub(1, 8)
    end
    return s
  end

  local function GetHomeMacroName(h)
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if faction == "Alliance" then
      return "HM Alliance"
    elseif faction == "Horde" then
      return "HM Horde"
    end
    return "HM Home"
  end

  local function RunHousingMacroCreateHome()
    local db2 = EnsureInit()
    local perCharacter = (db2.window and db2.window.macroPerChar) and true or false
    if InCombat() then
      Print("Can't create macros in combat.")
      return
    end
    local CH = _G and rawget(_G, "C_Housing")
    if not (CH and CH.GetCurrentHouseInfo) then
      Print("Housing API unavailable.")
      return
    end
    if type(CreateMacro) ~= "function" or type(GetMacroIndexByName) ~= "function" then
      Print("Macro API unavailable.")
      return
    end

    local h = CH.GetCurrentHouseInfo()
    if not h then
      Print("Run this in your house to create the Home macro.")
      return
    end

    local macroName = GetHomeMacroName(h)

    local body = "#showtooltip\n" ..
      "/run C_Housing.TeleportHome('" .. tostring(h.neighborhoodGUID) .. "','" .. tostring(h.houseGUID) .. "'," .. tostring(tonumber(h.plotID) or 0) .. ")"

    local idx = GetMacroIndexByName(macroName)
    if idx and idx > 0 then
      if type(EditMacro) == "function" then
        EditMacro(idx, macroName, "INV_MISC_QUESTIONMARK", body)
        Print("Macro '" .. tostring(macroName) .. "' updated!")
      else
        Print("Macro '" .. tostring(macroName) .. "' already exists (EditMacro unavailable).")
      end
      return
    end

    local ok = CreateMacro(macroName, "INV_MISC_QUESTIONMARK", body, perCharacter)
    if ok then
      Print("Macro '" .. tostring(macroName) .. "' created!")
    else
      Print("Could not create macro '" .. tostring(macroName) .. "' (macro slots full?).")
    end
  end

  local function RunHousingMacroCreateVisit()
    local db2 = EnsureInit()
    local perCharacter = (db2.window and db2.window.macroPerChar) and true or false
    if InCombat() then
      Print("Can't create macros in combat.")
      return
    end
    local CH = _G and rawget(_G, "C_Housing")
    if not (CH and CH.GetCurrentHouseInfo) then
      Print("Housing API unavailable.")
      return
    end
    if type(CreateMacro) ~= "function" or type(GetMacroIndexByName) ~= "function" then
      Print("Macro API unavailable.")
      return
    end

    local h = CH.GetCurrentHouseInfo()
    if not h then
      Print("Run this in a friend's house to create the Visit macro.")
      return
    end

    local tag
    if visitTagBox and visitTagBox.GetText then
      tag = SanitizeMacroTag(visitTagBox:GetText())
    end
    if not tag then
      local w = db2.window or {}
      tag = SanitizeMacroTag(w.visitTag)
    end
    if not tag then
      tag = tostring(tonumber(h.plotID) or h.plotID or "")
      if tag == "" then
        tag = "0"
      end
    end

    local macroName = "VS " .. tostring(tag)

    local body = "#showtooltip\n" ..
      "/run C_Housing.VisitHouse('" .. tostring(h.neighborhoodGUID) .. "','" .. tostring(h.houseGUID) .. "'," .. tostring(tonumber(h.plotID) or 0) .. ")"

    local idx = GetMacroIndexByName(macroName)
    if idx and idx > 0 then
      if type(EditMacro) == "function" then
        EditMacro(idx, macroName, "INV_MISC_QUESTIONMARK", body)
        Print("Macro '" .. tostring(macroName) .. "' updated!")
      else
        Print("Macro '" .. tostring(macroName) .. "' already exists (EditMacro unavailable).")
      end
      return
    end

    local ok = CreateMacro(macroName, "INV_MISC_QUESTIONMARK", body, perCharacter)
    if ok then
      Print("Macro '" .. tostring(macroName) .. "' created!")
    else
      Print("Could not create macro '" .. tostring(macroName) .. "' (macro slots full?).")
    end
  end

  local function MakeMacroButton(text, x, y, bodyFn, tooltipText, macroNameOverride, perCharacter)
    local btn = AddWidget(macrosWidgets, CreateFrame("Button", nil, frame, "UIPanelButtonTemplate"))
    btn:SetSize(160, 20)
    btn:SetPoint("TOPLEFT", x, y)
    btn:SetText(text)
    if tooltipText and tooltipText ~= "" then
      SetButtonTooltip(btn, tooltipText)
    end
    btn:SetScript("OnClick", function()
      local macroName = tostring(macroNameOverride or text)
      CreateOrUpdateNamedMacro(macroName, bodyFn(), perCharacter)
    end)
    return btn
  end

  local function MakeActionButton(text, x, y, onClick, tooltipText)
    local btn = AddWidget(macrosWidgets, CreateFrame("Button", nil, frame, "UIPanelButtonTemplate"))
    btn:SetSize(160, 20)
    btn:SetPoint("TOPLEFT", x, y)
    btn:SetText(text)
    if tooltipText and tooltipText ~= "" then
      SetButtonTooltip(btn, tooltipText)
    end
    btn:SetScript("OnClick", onClick)
    return btn
  end

  local visitTagLabel = AddWidget(macrosWidgets, frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"))
  visitTagLabel:SetPoint("TOPLEFT", 185, -200)
  visitTagLabel:SetText("Visit name:")

  visitTagBox = AddWidget(macrosWidgets, CreateFrame("EditBox", nil, frame, "InputBoxTemplate"))
  visitTagBox:SetSize(70, 18)
  visitTagBox:SetPoint("TOPLEFT", 255, -204)
  visitTagBox:SetAutoFocus(false)
  if visitTagBox.SetMaxLetters then
    visitTagBox:SetMaxLetters(8)
  end
  visitTagBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  visitTagBox:SetScript("OnEnterPressed", function(self)
    local db2 = EnsureInit()
    db2.window = db2.window or {}
    db2.window.visitTag = SanitizeMacroTag(self:GetText()) or ""
    self:ClearFocus()
  end)
  visitTagBox:SetScript("OnEditFocusLost", function(self)
    local db2 = EnsureInit()
    db2.window = db2.window or {}
    db2.window.visitTag = SanitizeMacroTag(self:GetText()) or ""
  end)
  visitTagBox:SetScript("OnShow", function(self)
    local db2 = EnsureInit()
    local w = db2.window or {}
    self:SetText(tostring(w.visitTag or ""))
  end)
  SetButtonTooltip(visitTagBox, "Up to 8 characters\nUsed for Visit macro name (VS <name>)")

  -- Left column
  MakeMacroButton("HS 06 Garrison", 10, -86, MacroBody_HS_Garrison)
  MakeMacroButton("HS 07 Dalaran", 10, -108, MacroBody_HS_Dalaran)
  MakeMacroButton("HS 11 Dornogal", 10, -130, MacroBody_HS_Dornogal)
  MakeMacroButton("HS 78 Whistle", 10, -152, MacroBody_HS_Whistle, "Legion/BFA Flight Points\nZaralek Caverns Mitts")
  MakeMacroButton("Instance IO", 10, -174, MacroBody_InstanceIO, "Teleport to/from LFG Instances")

  -- Right column
  MakeMacroButton("Instance Reset", 185, -86, MacroBody_InstanceReset)
  MakeMacroButton("Rez", 185, -108, MacroBody_Rez)
  MakeMacroButton("Rez Combat", 185, -130, MacroBody_RezCombat)
  MakeMacroButton("Script Errors", 185, -152, MacroBody_ScriptErrors)
  MakeActionButton("Home", 185, -174, RunHousingMacroCreateHome, function()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if faction == "Alliance" then
      return "Creates HM Alliance\nRun in your house"
    elseif faction == "Horde" then
      return "Creates HM Horde\nRun in your house"
    end
    return "Creates HM Home\nRun in your house"
  end)
  MakeActionButton("Visit", 185, -226, RunHousingMacroCreateVisit, "Creates VS <name> (or VS <plotID>)\nRun in a friend's house")

  local function SetTab(which)
    local db2 = EnsureInit()
    which = (which == "macros") and "macros" or "hearth"
    db2.window.tab = which

    local showMain = (which == "hearth")
    for _, w in ipairs(mainWidgets) do
      if w and w.Show and w.Hide then
        if showMain then w:Show() else w:Hide() end
      end
    end
    for _, w in ipairs(macrosWidgets) do
      if w and w.Show and w.Hide then
        if showMain then w:Hide() else w:Show() end
      end
    end

    if showMain then
      tabHearth:Disable()
      tabMacros:Enable()
    else
      tabMacros:Disable()
      tabHearth:Enable()
      UpdateMacroScopeUI()
    end
  end

  tabHearth:SetScript("OnClick", function()
    SetTab("hearth")
    if frame and frame:IsShown() then
      -- Keep main view up-to-date when swapping back.
      if frame:GetScript("OnShow") then
        frame:GetScript("OnShow")(frame)
      end
    end
  end)
  tabMacros:SetScript("OnClick", function() SetTab("macros") end)

  local function RefreshUI()
    local bind, zone = GetCurrentDisplayText()
    bindText:SetText(tostring(bind or ""))
    zoneText:SetText(tostring(zone or ""))
    RefreshToyDropText()
    local db2 = EnsureInit()
    do
      local useID = tonumber(db2.selectedUseItemID)
      if useID and not HasUseItem(useID) then
        db2.selectedUseItemID = nil
        useID = nil
      end
      cmdBox:SetText(BuildMacroRunLine(useID or 6948))
    end
    toyShowAll:GetScript("OnShow")(toyShowAll)
    autoRotate:GetScript("OnShow")(autoRotate)
    toyFilterBox:GetScript("OnShow")(toyFilterBox)
  end

  refreshBtn:SetScript("OnClick", RefreshUI)
  frame:SetScript("OnShow", function()
    RefreshUI()
    local db2 = EnsureInit()
    SetTab((db2.window and db2.window.tab) or "hearth")
  end)

  _G.fHZ._frame = frame
  _G.fHZ._refreshUI = RefreshUI
  _G.fHZ._createMacro = TryCreateMacro

  -- Populate immediately so the window isn't blank the first time.
  RefreshUI()
  SetTab((db.window and db.window.tab) or "hearth")

  return frame
end

local function ToggleGUI()
  local frame = EnsureGUI()
  if frame:IsShown() then
    frame:Hide()
  else
    frame:Show()
  end
end

local function SlashHelp()
  Print("/fhz  - toggle window")
  Print("/fhz macro  - create/update a macro named '" .. MACRO_NAME .. "' (uses selected toy if set)")
  Print("/run fHZ:GetZone()")
  Print("/run print(fHZ:GetHomeText())")
end

SLASH_FHZ1 = "/fhz"
SlashCmdList = SlashCmdList or {}
SlashCmdList.FHZ = function(msg)
  msg = tostring(msg or "")
  msg = msg:gsub("^%s+", ""):gsub("%s+$", "")
  local lower = msg:lower()
  if lower == "" then
    ToggleGUI()
    return
  end
  if lower == "macro" then
    EnsureGUI():Show()
    if _G.fHZ and type(_G.fHZ._createMacro) == "function" then
      _G.fHZ._createMacro()
    end
    return
  end
  if lower == "help" or lower == "?" then
    SlashHelp()
    return
  end

  Print("Unknown command: " .. msg)
  SlashHelp()
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_BIND_UPDATE")
f:RegisterEvent("HEARTHSTONE_BOUND")
f:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
f:RegisterEvent("SPELL_UPDATE_COOLDOWN")
f:RegisterEvent("BAG_UPDATE_COOLDOWN")
f:RegisterEvent("TOYS_UPDATED")

local lastSeenCooldownStart = 0
local lastMacroUpdateAt = 0

local function MacroExists()
  return type(GetMacroIndexByName) == "function" and (GetMacroIndexByName(MACRO_NAME) or 0) > 0
end

local function UpdateMacroIfExists()
  if InCombat() then return end
  if type(GetMacroIndexByName) ~= "function" or type(EditMacro) ~= "function" then return end
  local idx = GetMacroIndexByName(MACRO_NAME)
  if not (idx and idx > 0) then return end

  local now = (GetTime and GetTime()) or 0
  if now > 0 and (now - lastMacroUpdateAt) < 0.5 then
    return
  end
  lastMacroUpdateAt = now

  local db = EnsureInit()
  local body = BuildMacroText(db)
  EditMacro(idx, MACRO_NAME, "INV_Misc_QuestionMark", body)
end

local function MaybeRotateAndUpdate(reason)
  local db = EnsureInit()
  if not db.autoRotate then return end
  if not MacroExists() then return end
  if InCombat() then return end

  local id = RollRandomUseItem(db)
  if not id then return end
  UpdateMacroIfExists()

  if reason then
    Print("Auto-rotated macro (" .. tostring(reason) .. "): " .. GetUseItemName(id))
  end
end

local function CheckUsedAndRotate()
  local db = EnsureInit()
  if not db.autoRotate then return end
  if InCombat() then return end
  if not MacroExists() then return end

  local useID = tonumber(db.selectedUseItemID)
  if not useID or useID <= 0 then return end

  local start = GetToyCooldownStart(useID)
  if start > 0 and (lastSeenCooldownStart == 0 or start ~= lastSeenCooldownStart) then
    lastSeenCooldownStart = start
    -- Cooldown just started (or changed). Treat as a use and rotate.
    MaybeRotateAndUpdate("used")
  end
  if start == 0 then
    lastSeenCooldownStart = 0
  end
end

f:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    EnsureInit()
    local rs = math and rawget(math, "randomseed")
    local rr = math and rawget(math, "random")
    if time and rs then
      rs((time() or 0) + (GetServerTime and (GetServerTime() or 0) or 0))
      if rr then rr(); rr() end
    end
    return
  end

  if event == "PLAYER_ENTERING_WORLD" then
    -- Rotate once on entering the world (if enabled) so the macro starts random.
    MaybeRotateAndUpdate("login")
    return
  end

  local db, charKey = EnsureInit()
  if event == "HEARTHSTONE_BOUND" or event == "PLAYER_BIND_UPDATE" then
    db[charKey] = GetRealZoneText() or ""
    if _G.fHZ and type(_G.fHZ._refreshUI) == "function" then
      _G.fHZ._refreshUI()
    end
    return
  end

  if event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" or event == "TOYS_UPDATED" then
    CheckUsedAndRotate()
  end
end)
