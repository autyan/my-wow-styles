local addonName = ...

AutyanCoreDB = AutyanCoreDB or {}
AutyanCoreDB.equipmentInfo = AutyanCoreDB.equipmentInfo or {}
AUTYAN_EQUIPMENT_INFO_LOADED = true

local defaults = {
  enabled = true,
  characterPanel = true,
  inspectPanel = true,
  durability = true,
  qualityBorders = true,
  repairCost = true,
}

for key, value in pairs(defaults) do
  if AutyanCoreDB.equipmentInfo[key] == nil then
    AutyanCoreDB.equipmentInfo[key] = value
  end
end

local function cfg()
  AutyanCoreDB = AutyanCoreDB or {}
  AutyanCoreDB.equipmentInfo = AutyanCoreDB.equipmentInfo or {}
  for key, value in pairs(defaults) do
    if AutyanCoreDB.equipmentInfo[key] == nil then
      AutyanCoreDB.equipmentInfo[key] = value
    end
  end
  return AutyanCoreDB.equipmentInfo
end

local function printMsg(message)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff99ccffAutyanCore|r: " .. message)
  end
end

local function after(delay, callback)
  if C_Timer and C_Timer.After then
    C_Timer.After(delay, callback)
  else
    callback()
  end
end

local inventorySlots = {
  { id = 1, token = "HeadSlot", label = HEADSLOT, durability = true },
  { id = 2, token = "NeckSlot", label = NECKSLOT },
  { id = 3, token = "ShoulderSlot", label = SHOULDERSLOT, durability = true },
  { id = 5, token = "ChestSlot", label = CHESTSLOT, durability = true },
  { id = 6, token = "WaistSlot", label = WAISTSLOT, durability = true },
  { id = 7, token = "LegsSlot", label = LEGSSLOT, durability = true },
  { id = 8, token = "FeetSlot", label = FEETSLOT, durability = true },
  { id = 9, token = "WristSlot", label = WRISTSLOT, durability = true },
  { id = 10, token = "HandsSlot", label = HANDSSLOT, durability = true },
  { id = 11, token = "Finger0Slot", label = FINGER0SLOT },
  { id = 12, token = "Finger1Slot", label = FINGER1SLOT },
  { id = 13, token = "Trinket0Slot", label = TRINKET0SLOT },
  { id = 14, token = "Trinket1Slot", label = TRINKET1SLOT },
  { id = 15, token = "BackSlot", label = BACKSLOT, durability = true },
  { id = 16, token = "MainHandSlot", label = MAINHANDSLOT, durability = true },
  { id = 17, token = "SecondaryHandSlot", label = SECONDARYHANDSLOT, durability = true },
  { id = 18, token = "RangedSlot", label = RANGEDSLOT, durability = true },
}

local qualityColors = {
  [0] = { r = 0.62, g = 0.62, b = 0.62 },
  [1] = { r = 0.82, g = 0.82, b = 0.82 },
  [2] = { r = 0.12, g = 1.00, b = 0.12 },
  [3] = { r = 0.00, g = 0.44, b = 1.00 },
  [4] = { r = 0.64, g = 0.21, b = 0.93 },
  [5] = { r = 1.00, g = 0.50, b = 0.00 },
  [6] = { r = 0.90, g = 0.10, b = 0.10 },
  [7] = { r = 0.90, g = 0.80, b = 0.20 },
}

local statAliases = {
  strength = { "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_STRENGTH" },
  agility = { "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_AGILITY" },
  stamina = { "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_STAMINA" },
  intellect = { "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_INTELLECT" },
  spirit = { "ITEM_MOD_SPIRIT_SHORT", "ITEM_MOD_SPIRIT" },
  attackPower = { "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_ATTACK_POWER" },
  rangedAttackPower = { "ITEM_MOD_RANGED_ATTACK_POWER_SHORT", "ITEM_MOD_RANGED_ATTACK_POWER" },
  spellPower = { "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPELL_POWER", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "ITEM_MOD_SPELL_DAMAGE_DONE" },
  healing = { "ITEM_MOD_HEALING_DONE_SHORT", "ITEM_MOD_HEALING_DONE", "ITEM_MOD_HEALING_SHORT", "ITEM_MOD_HEALING" },
  crit = { "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_CRIT_RATING", "ITEM_MOD_SPELL_CRIT_RATING_SHORT", "ITEM_MOD_SPELL_CRIT_RATING" },
  hit = { "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_HIT_RATING", "ITEM_MOD_SPELL_HIT_RATING_SHORT", "ITEM_MOD_SPELL_HIT_RATING" },
  haste = { "ITEM_MOD_HASTE_RATING_SHORT", "ITEM_MOD_HASTE_RATING", "ITEM_MOD_SPELL_HASTE_RATING_SHORT", "ITEM_MOD_SPELL_HASTE_RATING" },
  spellPen = { "ITEM_MOD_SPELL_PENETRATION_SHORT", "ITEM_MOD_SPELL_PENETRATION" },
  armorPen = { "ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT", "ITEM_MOD_ARMOR_PENETRATION_RATING" },
  expertise = { "ITEM_MOD_EXPERTISE_RATING_SHORT", "ITEM_MOD_EXPERTISE_RATING" },
  defense = { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "ITEM_MOD_DEFENSE_SKILL_RATING" },
  dodge = { "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_DODGE_RATING" },
  parry = { "ITEM_MOD_PARRY_RATING_SHORT", "ITEM_MOD_PARRY_RATING" },
  block = { "ITEM_MOD_BLOCK_RATING_SHORT", "ITEM_MOD_BLOCK_RATING" },
  blockValue = { "ITEM_MOD_BLOCK_VALUE_SHORT", "ITEM_MOD_BLOCK_VALUE" },
}

local statProfiles = {
  physical = {
    title = "近战物理",
    primary = { "agility", "strength", "stamina" },
    offense = { "attackPower", "hit", "crit", "expertise", "haste", "armorPen" },
    rating = { hit = "hit", crit = "crit", haste = "haste", expertise = "expertise" },
  },
  ranged = {
    title = "远程物理",
    primary = { "agility", "stamina", "intellect" },
    offense = { "rangedAttackPower", "attackPower", "hit", "crit", "haste", "armorPen" },
    rating = { hit = "hit", crit = "crit", haste = "haste" },
  },
  caster = {
    title = "法系输出",
    primary = { "intellect", "spirit", "stamina" },
    offense = { "spellPower", "hit", "crit", "haste", "spellPen" },
    rating = { hit = "spellHit", crit = "spellCrit", haste = "spellHaste" },
  },
  healer = {
    title = "治疗",
    primary = { "intellect", "spirit", "stamina" },
    offense = { "healing", "spellPower", "crit", "haste" },
    rating = { crit = "spellCrit", haste = "spellHaste" },
  },
  tank = {
    title = "坦克",
    primary = { "stamina", "strength", "agility" },
    offense = { "defense", "dodge", "parry", "block", "blockValue", "hit", "expertise" },
    rating = { defense = "defense", dodge = "dodge", parry = "parry", block = "block", hit = "hit", expertise = "expertise" },
  },
  balanced = {
    title = "综合",
    primary = { "agility", "strength", "intellect", "stamina", "spirit" },
    offense = { "attackPower", "rangedAttackPower", "spellPower", "healing", "hit", "crit", "haste", "armorPen", "spellPen" },
    rating = { hit = "hit", crit = "crit", haste = "haste" },
  },
}

local statLabels = {
  strength = "力量",
  agility = "敏捷",
  stamina = "耐力",
  intellect = "智力",
  spirit = "精神",
  attackPower = "攻强",
  rangedAttackPower = "远程攻强",
  spellPower = "法强",
  healing = "治疗",
  crit = "暴击",
  hit = "命中",
  haste = "急速",
  spellPen = "法穿",
  armorPen = "破甲",
  expertise = "精准",
  defense = "防御",
  dodge = "闪避",
  parry = "招架",
  block = "格挡",
  blockValue = "格挡值",
}

local ratingBaseValues = {
  expertise = 2.5,
  haste = 10,
  spellHaste = 10,
  hit = 10,
  spellHit = 8,
  crit = 14,
  spellCrit = 14,
  defense = 1.5,
  dodge = 12,
  parry = 15,
  block = 5,
}

local tooltip
local equipmentJobs = {}
local equipmentJobActive = {}

local function scanTooltip()
  if not tooltip then
    tooltip = CreateFrame("GameTooltip", addonName .. "EquipmentScanTooltip", UIParent, "GameTooltipTemplate")
  end
  return tooltip
end

local function getButton(prefix, slot)
  return _G[prefix .. slot.token]
end

local function ensureBorder(button)
  if not button or button.AutyanQualityBorder then
    return button and button.AutyanQualityBorder
  end

  local texture = button:CreateTexture(nil, "OVERLAY")
  texture:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  texture:SetBlendMode("ADD")
  texture:SetSize(68, 68)
  texture:SetPoint("CENTER", button, "CENTER", 0, 0)
  texture:SetAlpha(0.9)
  texture:Hide()
  button.AutyanQualityBorder = texture
  return texture
end

local function getItemInfo(link)
  if not link then
    return nil
  end

  local name, _, quality, itemLevel = GetItemInfo(link)
  if C_Item and C_Item.GetDetailedItemLevelInfo then
    local ok, detailedLevel = pcall(C_Item.GetDetailedItemLevelInfo, link)
    if ok and detailedLevel then
      itemLevel = detailedLevel
    end
  end

  return name, quality, itemLevel
end

local function updateButtonVisuals(prefix, unit)
  if not cfg().enabled then
    return
  end

  for _, slot in ipairs(inventorySlots) do
    local button = getButton(prefix, slot)
    if button then
      local link = GetInventoryItemLink(unit, slot.id)
      local _, quality = getItemInfo(link)
      local border = ensureBorder(button)
      if cfg().qualityBorders and border and quality and quality > 1 then
        local color = qualityColors[quality] or qualityColors[1]
        border:SetVertexColor(color.r, color.g, color.b, 1)
        border:Show()
      elseif border then
        border:Hide()
      end

      if unit == "player" and cfg().durability and slot.durability and button.Count then
        local current, maximum = GetInventoryItemDurability(slot.id)
        if current and maximum and maximum > 0 then
          local percent = math.floor(current / maximum * 100 + 0.5)
          button.Count:SetFormattedText("%d%%", percent)
          button.Count:SetTextColor(percent > 50 and 0.1 or 1, percent > 25 and 1 or 0.1, 0.1)
          button.Count:Show()
          button.AutyanDurabilityText = percent
        elseif button.AutyanDurabilityText then
          button.Count:SetText("")
          button.AutyanDurabilityText = nil
        end
      end
    end
  end
end

local function addStats(totalStats, link)
  if not link or not GetItemStats then
    return
  end

  local stats = GetItemStats(link)
  if not stats then
    return
  end

  for stat, value in pairs(stats) do
    totalStats[stat] = (totalStats[stat] or 0) + value
  end
end

local function itemIdFromLink(link)
  return link and tonumber(link:match("item:(%d+)"))
end

local function requestItemData(link)
  local itemId = itemIdFromLink(link)
  if not itemId or not C_Item then
    return
  end

  if C_Item.RequestLoadItemDataByID then
    pcall(C_Item.RequestLoadItemDataByID, itemId)
  elseif C_Item.RequestLoadItemData then
    pcall(C_Item.RequestLoadItemData, itemId)
  end
end

local function statValue(totalStats, statKey)
  local total = 0
  local aliases = statAliases[statKey]
  if not aliases then
    return totalStats[statKey] or 0
  end

  for _, alias in ipairs(aliases) do
    total = total + (totalStats[alias] or 0)
  end
  return total
end

local function ratingPerConvertedUnit(unit, ratingType)
  local base = ratingBaseValues[ratingType]
  if not base then
    return nil
  end

  local level = UnitLevel(unit or "player") or UnitLevel("player") or 70
  if level < 1 then
    level = UnitLevel("player") or 70
  end

  if level <= 10 then
    return base / 26
  elseif level <= 60 then
    return base * ((level - 8) / 52)
  elseif level <= 70 then
    return base * (82 / (262 - 3 * level))
  end

  return base
end

local function convertedRatingValue(rawValue, unit, ratingType)
  local perUnit = ratingPerConvertedUnit(unit, ratingType)
  if not perUnit or perUnit <= 0 then
    return nil
  end
  return rawValue / perUnit
end

local function signedStatText(value, suffix)
  value = value or 0
  local sign = value >= 0 and "+" or ""
  return sign .. tostring(value) .. (suffix or "")
end

local function formatConvertedStat(totalStats, key, profile, unit)
  local rawValue = statValue(totalStats, key)
  local ratingType = profile.rating and profile.rating[key]
  if not ratingType then
    return signedStatText(rawValue)
  end

  local converted = convertedRatingValue(rawValue, unit, ratingType)
  if not converted then
    return signedStatText(rawValue)
  end

  if ratingType == "expertise" or ratingType == "defense" then
    return ("%+.2f"):format(converted)
  end

  return ("%+.2f%%"):format(converted)
end

local function ensureTalentApi()
  if GetTalentTabInfo and GetTalentInfo then
    return true
  end

  if LoadAddOn then
    pcall(LoadAddOn, "Blizzard_TalentUI")
  end

  return GetTalentTabInfo ~= nil
end

local function getTalentTabCount()
  if GetNumTalentTabs then
    local count = GetNumTalentTabs(false, false)
    if count and count > 0 then
      return count
    end
  end
  return 3
end

local function getTalentTabPoints(tabIndex)
  local value1, value2, value3, _, value5 = GetTalentTabInfo(tabIndex, false, false)
  local name = type(value1) == "string" and value1 or type(value2) == "string" and value2 or nil
  local points = tonumber(value3) or tonumber(value5) or 0
  if points > 0 or not GetNumTalents or not GetTalentInfo then
    return name, points
  end

  local count = GetNumTalents(tabIndex, false, false) or 0
  for talentIndex = 1, count do
    local _, _, _, _, rank = GetTalentInfo(tabIndex, talentIndex, false, false)
    points = points + (tonumber(rank) or 0)
  end

  return name, points
end

local function getPrimaryTalentInfo()
  if not ensureTalentApi() then
    return nil, nil
  end

  local bestIndex, bestName, bestPoints = nil, nil, -1
  for index = 1, getTalentTabCount() do
    local name, points = getTalentTabPoints(index)
    if points > bestPoints then
      bestIndex = index
      bestName = name
      bestPoints = points
    end
  end

  if bestPoints <= 0 then
    return nil, nil
  end
  return bestIndex, bestName
end

local function selectStatProfile(unit)
  local _, classFile = UnitClass(unit)
  local talentIndex = unit == "player" and getPrimaryTalentInfo() or nil

  if classFile == "HUNTER" then
    return statProfiles.ranged
  elseif classFile == "ROGUE" then
    return statProfiles.physical
  elseif classFile == "WARRIOR" then
    return talentIndex == 3 and statProfiles.tank or statProfiles.physical
  elseif classFile == "PALADIN" then
    if talentIndex == 1 then
      return statProfiles.healer
    elseif talentIndex == 2 then
      return statProfiles.tank
    end
    return statProfiles.physical
  elseif classFile == "SHAMAN" then
    if talentIndex == 3 then
      return statProfiles.healer
    elseif talentIndex == 2 then
      return statProfiles.physical
    end
    return statProfiles.caster
  elseif classFile == "DRUID" then
    if talentIndex == 3 then
      return statProfiles.healer
    elseif talentIndex == 2 then
      return statProfiles.physical
    end
    return statProfiles.caster
  elseif classFile == "PRIEST" then
    return talentIndex == 3 and statProfiles.caster or statProfiles.healer
  elseif classFile == "MAGE" or classFile == "WARLOCK" then
    return statProfiles.caster
  end

  return statProfiles.balanced
end

local function getProfileSourceText(unit)
  if unit ~= "player" then
    return "无"
  end

  local _, talentName = getPrimaryTalentInfo()
  return talentName or "无"
end

local function getRepairCost()
  if not cfg().repairCost then
    return 0
  end

  local tip = scanTooltip()
  local total = 0
  for _, slot in ipairs(inventorySlots) do
    if slot.durability then
      tip:SetOwner(UIParent, "ANCHOR_NONE")
      tip:ClearLines()
      local hasItem, _, repairCost = tip:SetInventoryItem("player", slot.id)
      if hasItem and repairCost then
        total = total + repairCost
      end
    end
  end
  tip:Hide()
  return total
end

local characterPanelParent

local function createMoneyFrame(parent)
  if parent.AutyanRepairMoneyFrame then
    return parent.AutyanRepairMoneyFrame
  end

  local frame = CreateFrame("Frame", addonName .. "RepairMoneyFrame", parent, "SmallMoneyFrameTemplate")
  frame:SetPoint("BOTTOMLEFT", CharacterAttributesFrame or parent, "TOPLEFT", 4, 22)
  frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  frame.title:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", -2, 2)
  frame.title:SetText(REPAIR_COST or "Repair Cost")
  frame:SetScript("OnShow", function(self)
    if MoneyFrame_SetType then
      MoneyFrame_SetType(self, "STATIC")
    end
  end)
  parent.AutyanRepairMoneyFrame = frame
  return frame
end

local function hideCharacterEquipmentPanels()
  local parent = characterPanelParent and characterPanelParent()
  if parent and parent.AutyanEquipmentPanel then
    if parent.AutyanEquipmentPanel.statsPanel then
      parent.AutyanEquipmentPanel.statsPanel:Hide()
    end
    parent.AutyanEquipmentPanel:Hide()
  end
  if PaperDollFrame and PaperDollFrame.AutyanRepairMoneyFrame then
    PaperDollFrame.AutyanRepairMoneyFrame:Hide()
  end
end

local function updateRepairCost()
  if not PaperDollFrame or not PaperDollFrame:IsShown() or not cfg().enabled or not cfg().repairCost then
    if PaperDollFrame and PaperDollFrame.AutyanRepairMoneyFrame then
      PaperDollFrame.AutyanRepairMoneyFrame:Hide()
    end
    return
  end

  local moneyFrame = createMoneyFrame(PaperDollFrame)
  local total = getRepairCost()
  if total > 0 then
    MoneyFrame_Update(moneyFrame:GetName(), total)
    moneyFrame:Show()
  else
    moneyFrame:Hide()
  end
end

local function createStatsPanel(parent)
  if parent.AutyanStatsPanel then
    return parent.AutyanStatsPanel
  end

  local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  frame:SetSize(205, 238)
  frame:SetClampedToScreen(true)
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0, 0, 0, 0.86)
  frame:SetBackdropBorderColor(0.45, 0.75, 0.45, 1)

  frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLargeOutline")
  frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
  frame.title:SetText("属性")

  frame.profile = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  frame.profile:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
  frame.profile:SetWidth(170)
  frame.profile:SetJustifyH("LEFT")

  frame.rows = {}
  local previous = frame.profile
  for index = 1, 16 do
    local row = CreateFrame("Frame", nil, frame)
    row:SetSize(176, 15)
    if index == 1 then
      row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -8)
    else
      row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
    end

    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints(row)
    row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    row.bg:SetVertexColor(0.08, 0.18, 0.14, index % 2 == 1 and 0.35 or 0)

    row.label = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.label:SetPoint("LEFT", row, "LEFT", 8, 0)
    row.label:SetWidth(94)
    row.label:SetJustifyH("LEFT")

    row.value = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.value:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.value:SetWidth(64)
    row.value:SetJustifyH("RIGHT")

    frame.rows[index] = row
    previous = row
  end

  parent.AutyanStatsPanel = frame
  return frame
end

local function createEquipmentPanel(parent)
  if parent.AutyanEquipmentPanel then
    return parent.AutyanEquipmentPanel
  end

  local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  frame:SetSize(220, 424)
  frame:SetClampedToScreen(true)
  frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0, 0, 0, 0.78)
  frame:SetBackdropBorderColor(0.45, 0.75, 0.45, 1)
  frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, -12)

  frame.portrait = frame:CreateTexture(nil, "ARTWORK")
  frame.portrait:SetSize(44, 44)
  frame.portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)

  frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLargeOutline")
  frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 72, -18)
  frame.title:SetText("Equipment")

  frame.level = frame:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
  frame.level:SetPoint("TOPLEFT", frame, "TOPLEFT", 72, -42)
  frame.level:SetFont(frame.level:GetFont(), 12, "THINOUTLINE")

  frame.rows = {}
  local previous
  for index, slot in ipairs(inventorySlots) do
    local row = CreateFrame("Button", nil, frame, "BackdropTemplate")
    row:SetSize(184, 20)
    if previous then
      row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
    else
      row:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -68)
    end

    row.label = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.label:SetSize(38, 16)
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.label:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      tile = true,
      tileSize = 8,
      edgeSize = 1,
      insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    row.label:SetBackdropColor(0, 0.9, 0.9, 0.18)
    row.label:SetBackdropBorderColor(0, 0.9, 0.9, 0.22)
    row.label.text = row.label:CreateFontString(nil, "ARTWORK")
    row.label.text:SetFont(UNIT_NAME_FONT, 12, "THINOUTLINE")
    row.label.text:SetPoint("CENTER", row.label, "CENTER", 1, 0)
    row.label.text:SetWidth(34)
    row.label.text:SetText(slot.label or "")
    row.label.text:SetTextColor(0, 0.9, 0.9)

    row.level = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    row.level:SetPoint("LEFT", row.label, "RIGHT", 4, 0)
    row.level:SetWidth(30)
    row.level:SetJustifyH("RIGHT")

    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.level, "RIGHT", 4, 0)
    row.name:SetWidth(108)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)

    row:SetScript("OnEnter", function(self)
      if self.link or (self.levelValue and self.levelValue > 0) then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetInventoryItem(self:GetParent().unit or "player", self.slot.id)
        GameTooltip:Show()
      end
    end)
    row:SetScript("OnLeave", GameTooltip_Hide)

    row.slot = slot
    frame.rows[index] = row
    previous = row
  end

  parent.AutyanEquipmentPanel = frame
  return frame
end

local function positionEquipmentPanel(panel, parent, showStats)
  if not panel or not parent then
    return
  end

  panel:ClearAllPoints()
  if panel.statsPanel then
    panel.statsPanel:ClearAllPoints()
  end

  local uiWidth = UIParent and UIParent:GetWidth()
  local parentRight = parent.GetRight and parent:GetRight()
  local panelWidth = panel:GetWidth() or 220
  local statsWidth = showStats and panel.statsPanel and panel.statsPanel:GetWidth() or 0
  if uiWidth and parentRight and parentRight + panelWidth + statsWidth + 12 > uiWidth then
    panel:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -16, -78)
    if showStats and panel.statsPanel then
      panel.statsPanel:SetPoint("TOPLEFT", panel, "BOTTOMLEFT", 0, -2)
    end
  else
    panel:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    if showStats and panel.statsPanel then
      panel.statsPanel:SetPoint("TOPLEFT", panel, "TOPRIGHT", 0, -1)
    end
  end
end

local function prepareEquipmentPanel(parent, unit)
  if not parent or not cfg().enabled then
    return
  end
  if unit == "player" and not cfg().characterPanel then
    return
  end
  if unit ~= "player" and not cfg().inspectPanel then
    return
  end

  local panel = createEquipmentPanel(parent)
  local showStats = unit == "player"
  if showStats then
    panel.statsPanel = createStatsPanel(panel)
  elseif panel.statsPanel then
    panel.statsPanel:Hide()
  end
  positionEquipmentPanel(panel, parent, showStats)
  local unitName = UnitName(unit) or (unit == "player" and UnitName("player")) or "Unknown"
  local profile = selectStatProfile(unit)
  local _, classFile = UnitClass(unit)
  local classColor = (classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]) or NORMAL_FONT_COLOR

  panel.unit = unit
  panel.title:SetText(unitName or "Equipment")
  panel.title:SetTextColor(classColor.r, classColor.g, classColor.b)
  panel:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 1)
  if panel.statsPanel then
    panel.statsPanel:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 1)
  end
  SetPortraitTexture(panel.portrait, unit)

  return panel, profile, classColor
end

local function clearPanelRows(panel, text)
  for _, row in ipairs(panel.rows) do
    row.link = nil
    row.levelValue = nil
    row.level:SetText("-")
    row.level:SetTextColor(0.55, 0.55, 0.55)
    row.name:SetText(text or row.slot.label or "")
    row.name:SetTextColor(0.55, 0.55, 0.55)
  end
end

local function setPanelLoading(panel, text)
  clearPanelRows(panel, "")
  panel.level:SetText(text or "读取中...")
  panel.level:SetTextColor(1, 0.82, 0)
  panel:Show()
end

local function updateSummary(panel, profile, unit, totalStats, total, count, maxLevel, pending)
  local average = count > 0 and total / count or 0
  if pending and pending > 0 then
    panel.level:SetFormattedText("iLvl %.1f  Max %d  读取中 %d", average, maxLevel, pending)
  else
    panel.level:SetFormattedText("iLvl %.1f  Max %d", average, maxLevel)
  end
  panel.level:SetTextColor(1, 0.82, 0)

  local statsPanel = panel.statsPanel
  if not statsPanel then
    panel:Show()
    return
  end
  statsPanel.title:SetText("属性")
  statsPanel.title:SetTextColor(panel.title:GetTextColor())
  statsPanel.profile:SetFormattedText("%s  %s", profile.title, getProfileSourceText(unit))

  local statKeys = {}
  for _, key in ipairs(profile.primary) do
    statKeys[#statKeys + 1] = key
  end
  for _, key in ipairs(profile.offense) do
    statKeys[#statKeys + 1] = key
  end

  for index, row in ipairs(statsPanel.rows) do
    local key = statKeys[index]
    if key then
      row.label:SetText(statLabels[key] or key)
      row.value:SetText(formatConvertedStat(totalStats, key, profile, unit))
      row:Show()
    else
      row.label:SetText("")
      row.value:SetText("")
      row:Hide()
    end
  end

  statsPanel:SetHeight(70 + math.max(#statKeys, 1) * 15)
  statsPanel:Show()
  panel:Show()
end

local function updateEquipmentRow(row, unit, totalStats, data)
  local slot = row.slot
  local link = data and data.link or GetInventoryItemLink(unit, slot.id)
  row.link = link

  if link then
    requestItemData(link)
  end

  local name, quality, level
  if data then
    name = data.name
    quality = data.quality
    level = data.level
    if data.stats then
      for stat, value in pairs(data.stats) do
        totalStats[stat] = (totalStats[stat] or 0) + value
      end
    end
  else
    name, quality, level = getItemInfo(link)
    addStats(totalStats, link)
  end
  row.levelValue = level

  if level and level > 0 then
    row.level:SetText(tostring(level))
    row.level:SetTextColor(0.1, 0.75, 1)
  else
    row.level:SetText("-")
    row.level:SetTextColor(0.55, 0.55, 0.55)
  end

  if name then
    local color = qualityColors[quality or 1] or qualityColors[1]
    row.name:SetText(name)
    row.name:SetTextColor(color.r, color.g, color.b)
  elseif link then
    row.name:SetText("读取中")
    row.name:SetTextColor(0.72, 0.72, 0.55)
  else
    row.name:SetText(slot.label or "")
    row.name:SetTextColor(0.55, 0.55, 0.55)
  end

  if cfg().qualityBorders and row.label and quality and quality > 1 then
    local color = qualityColors[quality] or qualityColors[1]
    row.label:SetBackdropBorderColor(color.r, color.g, color.b, 0.9)
  elseif row.label then
    row.label:SetBackdropBorderColor(0, 0.9, 0.9, 0.22)
  end

  return link ~= nil and name == nil, level or 0
end

local function readEquipmentSlot(unit, row)
  local link = GetInventoryItemLink(unit, row.slot.id)
  if not link then
    return { link = nil, ready = true, level = 0, stats = {} }
  end

  requestItemData(link)
  local name, quality, level = getItemInfo(link)
  if not name then
    return { link = link, ready = false, level = 0, stats = {} }
  end

  local stats = {}
  addStats(stats, link)
  return {
    link = link,
    ready = true,
    name = name,
    quality = quality,
    level = level or 0,
    stats = stats,
  }
end

local function updateEquipmentPanel(parent, unit)
  local panel, profile = prepareEquipmentPanel(parent, unit)
  if not panel then
    return
  end

  local total, count, maxLevel = 0, 0, 0
  local totalStats = {}
  for index, row in ipairs(panel.rows) do
    local _, level = updateEquipmentRow(row, unit, totalStats)
    if level and level > 0 then
      total = total + level
      count = count + 1
      maxLevel = math.max(maxLevel, level)
    end
  end

  updateSummary(panel, profile, unit, totalStats, total, count, maxLevel, 0)
end

local function startAsyncEquipmentPanel(parent, unit)
  local panel, profile = prepareEquipmentPanel(parent, unit)
  if not panel then
    return
  end

  local token = (equipmentJobs[parent] or 0) + 1
  equipmentJobs[parent] = token
  equipmentJobActive[parent] = true
  setPanelLoading(panel, "读取中...")

  local job = {
    parent = parent,
    unit = unit,
    panel = panel,
    profile = profile,
    token = token,
    tries = 0,
  }

  local function isCurrent()
    return equipmentJobs[parent] == token and parent:IsShown() and UnitExists(unit)
  end

  local function render(data)
    local total, count, maxLevel = 0, 0, 0
    local totalStats = {}

    updateButtonVisuals("Inspect", unit)

    for index, row in ipairs(panel.rows) do
      local _, level = updateEquipmentRow(row, unit, totalStats, data[index])
      if level and level > 0 then
        total = total + level
        count = count + 1
        maxLevel = math.max(maxLevel, level)
      end
    end

    updateSummary(panel, profile, unit, totalStats, total, count, maxLevel, 0)
    equipmentJobActive[parent] = nil
  end

  local function poll()
    if not isCurrent() then
      equipmentJobActive[parent] = nil
      return
    end

    job.tries = job.tries + 1
    local data = {}
    local pending = 0
    for index, row in ipairs(panel.rows) do
      data[index] = readEquipmentSlot(unit, row)
      if not data[index].ready then
        pending = pending + 1
      end
    end

    if pending == 0 or job.tries >= 12 then
      render(data)
      return
    end

    setPanelLoading(panel, ("读取中... %d"):format(pending))
    after(0.12, poll)
  end

  after(0.01, poll)
end

characterPanelParent = function()
  return CharacterFrame or PaperDollFrame
end

local function isCharacterEquipmentVisible()
  if PaperDollFrame and PaperDollFrame:IsShown() then
    return true
  end
  return false
end

local updateInspectEquipment
local inspectUpdatePending

local function requestInspectEquipmentUpdate(delay)
  if inspectUpdatePending then
    return
  end
  if InspectFrame and equipmentJobActive[InspectFrame] then
    return
  end

  inspectUpdatePending = true
  after(delay or 0.15, function()
    inspectUpdatePending = nil
    updateInspectEquipment()
  end)
end

local function updateCharacterEquipment()
  if not isCharacterEquipmentVisible() then
    hideCharacterEquipmentPanels()
    return
  end
  updateButtonVisuals("Character", "player")
  updateRepairCost()
  updateEquipmentPanel(characterPanelParent(), "player")
end

local function hideEquipmentButtonVisuals(prefix)
  for _, slot in ipairs(inventorySlots) do
    local button = getButton(prefix, slot)
    if button then
      if button.AutyanQualityBorder then
        button.AutyanQualityBorder:Hide()
      end
      if button.AutyanDurabilityText and button.Count then
        button.Count:SetText("")
        button.AutyanDurabilityText = nil
      end
    end
  end
end

local function hideInspectEquipmentPanels()
  if InspectFrame and InspectFrame.AutyanEquipmentPanel then
    if InspectFrame.AutyanEquipmentPanel.statsPanel then
      InspectFrame.AutyanEquipmentPanel.statsPanel:Hide()
    end
    InspectFrame.AutyanEquipmentPanel:Hide()
  end
end

function AutyanCore_RefreshEquipmentInfo()
  updateCharacterEquipment()
  requestInspectEquipmentUpdate(0.1)
end

function AutyanCore_GetEquipmentInfoFlag(key)
  return cfg()[key]
end

function AutyanCore_SetEquipmentInfoFlag(key, value)
  local c = cfg()
  if c[key] == nil then
    return
  end

  c[key] = value and true or false

  if key == "enabled" and not c.enabled then
    hideCharacterEquipmentPanels()
    hideInspectEquipmentPanels()
    hideEquipmentButtonVisuals("Character")
    hideEquipmentButtonVisuals("Inspect")
    return
  end

  if key == "characterPanel" and not c.characterPanel then
    hideCharacterEquipmentPanels()
  elseif key == "inspectPanel" and not c.inspectPanel then
    hideInspectEquipmentPanels()
  elseif key == "durability" and not c.durability then
    hideEquipmentButtonVisuals("Character")
  elseif key == "qualityBorders" and not c.qualityBorders then
    hideEquipmentButtonVisuals("Character")
    hideEquipmentButtonVisuals("Inspect")
  elseif key == "repairCost" and not c.repairCost and PaperDollFrame and PaperDollFrame.AutyanRepairMoneyFrame then
    PaperDollFrame.AutyanRepairMoneyFrame:Hide()
  end

  AutyanCore_RefreshEquipmentInfo()
end

function AutyanCore_EquipmentInfoDebug()
  updateCharacterEquipment()
  updateInspectEquipment()

  local c = cfg()
  local parent = characterPanelParent()
  local talentIndex, talentName = getPrimaryTalentInfo()
  printMsg(("equipment debug: loaded=%s enabled=%s character=%s paper=%s head=%s panel=%s inspect=%s talent=%s/%s"):format(
    tostring(AUTYAN_EQUIPMENT_INFO_LOADED),
    tostring(c.enabled),
    tostring(CharacterFrame and CharacterFrame:IsShown()),
    tostring(PaperDollFrame and PaperDollFrame:IsShown()),
    tostring(CharacterHeadSlot and CharacterHeadSlot:IsShown()),
    tostring(parent and parent.AutyanEquipmentPanel ~= nil),
    tostring(InspectFrame and InspectFrame:IsShown()),
    tostring(talentIndex),
    tostring(talentName)
  ))
end

local function inspectUnit()
  if InspectFrame and InspectFrame.unit then
    return InspectFrame.unit
  end
  return "target"
end

updateInspectEquipment = function()
  if not InspectFrame or not InspectFrame:IsShown() then
    return
  end

  local unit = inspectUnit()
  if not UnitExists(unit) then
    return
  end

  startAsyncEquipmentPanel(InspectFrame, unit)
end

local initialized
local function initializeEquipmentInfo()
  if initialized then
    return
  end
  initialized = true

  if PaperDollFrame then
    PaperDollFrame:HookScript("OnShow", function()
      after(0, updateCharacterEquipment)
    end)
    PaperDollFrame:HookScript("OnHide", function()
      hideCharacterEquipmentPanels()
    end)
  end

  if CharacterFrame then
    CharacterFrame:HookScript("OnShow", function()
      after(0, updateCharacterEquipment)
      after(0.25, updateCharacterEquipment)
    end)
    CharacterFrame:HookScript("OnHide", function()
      hideCharacterEquipmentPanels()
    end)
  end

  if InspectFrame then
    InspectFrame:HookScript("OnShow", function()
      requestInspectEquipmentUpdate(0.2)
    end)
  end

  if hooksecurefunc then
    hooksecurefunc("PaperDollItemSlotButton_OnEvent", function()
      after(0, updateCharacterEquipment)
    end)

    if InspectPaperDollItemSlotButton_Update then
      hooksecurefunc("InspectPaperDollItemSlotButton_Update", function()
        requestInspectEquipmentUpdate(0.15)
      end)
    end

    if InspectUnit then
      hooksecurefunc("InspectUnit", function()
        requestInspectEquipmentUpdate(0.5)
      end)
    end

    if CharacterFrame_ShowSubFrame then
      hooksecurefunc("CharacterFrame_ShowSubFrame", function()
        after(0, updateCharacterEquipment)
        after(0.25, updateCharacterEquipment)
      end)
    end
  end

  after(1, updateCharacterEquipment)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("INSPECT_READY")
events:RegisterEvent("CHARACTER_POINTS_CHANGED")
events:RegisterEvent("PLAYER_TALENT_UPDATE")
pcall(events.RegisterEvent, events, "ITEM_DATA_LOAD_RESULT")
pcall(events.RegisterEvent, events, "GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    initializeEquipmentInfo()
  elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "UPDATE_INVENTORY_DURABILITY" or event == "MERCHANT_SHOW" or event == "CHARACTER_POINTS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
    after(0, updateCharacterEquipment)
  elseif event == "INSPECT_READY" then
    requestInspectEquipmentUpdate(0.2)
  elseif (event == "ITEM_DATA_LOAD_RESULT" or event == "GET_ITEM_INFO_RECEIVED") and InspectFrame and InspectFrame:IsShown() then
    requestInspectEquipmentUpdate(0.05)
  end
end)

SLASH_AUTYANCORE_EQUIPMENT1 = "/autyanequip"
SlashCmdList.AUTYANCORE_EQUIPMENT = function(input)
  input = input and input:lower() or ""
  local c = cfg()
  if input == "on" then
    AutyanCore_SetEquipmentInfoFlag("enabled", true)
    printMsg("equipment info enabled")
  elseif input == "off" then
    AutyanCore_SetEquipmentInfoFlag("enabled", false)
    printMsg("equipment info disabled")
  elseif input == "debug" then
    AutyanCore_EquipmentInfoDebug()
  else
    updateCharacterEquipment()
    updateInspectEquipment()
    printMsg("commands: /autyanequip on, /autyanequip off, /autyanequip debug")
  end
end
