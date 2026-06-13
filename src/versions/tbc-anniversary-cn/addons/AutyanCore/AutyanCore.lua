local addonName = ...

AutyanCoreDB = AutyanCoreDB or {}

local defaults = {
  buffNA = false,
  permanentAuraText = true,
  fps = {
    enabled = true,
    point = "TOPRIGHT",
    relativePoint = "TOPRIGHT",
    x = -330,
    y = -18,
  },
  chatClassColors = true,
  guildClassColors = true,
  taintLogEnabled = true,
}

local function db()
  for key, value in pairs(defaults) do
    if AutyanCoreDB[key] == nil then
      if type(value) == "table" then
        AutyanCoreDB[key] = {}
        for childKey, childValue in pairs(value) do
          AutyanCoreDB[key][childKey] = childValue
        end
      else
        AutyanCoreDB[key] = value
      end
    end
  end

  return AutyanCoreDB
end

local function migrateRiskyDefaults()
  if AutyanCoreDB.buffNA == true and not AutyanCoreDB.buffNAOptIn then
    AutyanCoreDB.buffNA = false
  end
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

local function applyFPSPosition()
  local cfg = db().fps
  if not cfg.enabled then
    return
  end

  local frame = _G.FramerateFrame or _G.FramerateLabel or _G.FramerateText or _G.PerformanceBarFrame
  if not frame then
    return
  end

  frame:ClearAllPoints()
  frame:SetPoint(cfg.point, UIParent, cfg.relativePoint, cfg.x, cfg.y)
end

local function ensurePermanentAuraText(button)
  if not button or button.AutyanPermanentAuraText then
    return
  end

  local text = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
  text:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
  text:SetText("N/A")
  text:SetTextColor(0, 1, 0, 1)
  text:SetShadowColor(0, 0, 0, 1)
  text:SetShadowOffset(1, -1)
  text:Hide()

  button.AutyanPermanentAuraText = text
end

local function hidePermanentAuraText(button)
  if button and button.AutyanPermanentAuraText then
    button.AutyanPermanentAuraText:Hide()
  end
end

local function isFrameLike(value)
  return type(value) == "table" and type(value.GetObjectType) == "function" and type(value.IsShown) == "function"
end

local function hasNoExpiration(expirationTime)
  return not expirationTime or expirationTime == 0
end

local function isInfiniteDuration(duration)
  return duration == math.huge or (type(duration) == "number" and duration >= 31536000)
end

local function isPermanentAuraInfo(info)
  if not info then
    return false
  end

  local expirationTime = info.expirationTime
  local duration = info.duration
  return hasNoExpiration(expirationTime) and (not duration or duration == 0 or isInfiniteDuration(duration))
end

local function getAuraDurationText(button)
  if button.Duration then
    return button.Duration
  end

  ensurePermanentAuraText(button)
  return button.AutyanPermanentAuraText
end

local function applyPermanentAuraButtonText(button)
  if not isFrameLike(button) then
    return false
  end

  local text = getAuraDurationText(button)
  if not text then
    return false
  end

  if not db().permanentAuraText or not button:IsShown() or not isPermanentAuraInfo(button.buttonInfo) then
    if button.AutyanPermanentAuraTextActive then
      text:SetText("")
      text:Hide()
      button.AutyanPermanentAuraTextActive = nil
    end
    return false
  end

  text:SetText("N/A")
  text:SetTextColor(0, 1, 0, 1)
  text:Show()
  button.AutyanPermanentAuraTextActive = true
  return true
end

local function hookAuraButton(button)
  if not isFrameLike(button) or button.AutyanPermanentAuraHooked then
    return false
  end

  if type(button.Update) == "function" then
    hooksecurefunc(button, "Update", applyPermanentAuraButtonText)
  end

  if type(button.UpdateDuration) == "function" then
    hooksecurefunc(button, "UpdateDuration", applyPermanentAuraButtonText)
  end

  button.AutyanPermanentAuraHooked = true
  return true
end

local function forEachAuraButton(container, callback)
  if not container then
    return 0
  end

  local count = 0
  local auraFrames = container.auraFrames or container.activeButtons or container.buttons
  if type(auraFrames) ~= "table" then
    return count
  end

  for key, button in pairs(auraFrames) do
    if isFrameLike(button) then
      callback(button)
      count = count + 1
    elseif isFrameLike(key) then
      callback(key)
      count = count + 1
    end
  end

  return count
end

local function hookPermanentAuraButtons()
  local hooked = 0

  local function hookAndApply(button)
    if hookAuraButton(button) then
      hooked = hooked + 1
    end
    applyPermanentAuraButtonText(button)
  end

  for index = 1, 40 do
    local button = _G["BuffButton" .. index]
    if button then
      hookAndApply(button)
    end
  end

  forEachAuraButton(BuffFrame, hookAndApply)
  forEachAuraButton(BuffFrame and BuffFrame.AuraContainer, hookAndApply)
  forEachAuraButton(DebuffFrame, hookAndApply)
  forEachAuraButton(DebuffFrame and DebuffFrame.AuraContainer, hookAndApply)

  return hooked
end

local function hidePermanentAuraContainer(container)
  forEachAuraButton(container, hidePermanentAuraText)
end

local function updatePermanentAuraText(debugLines)
  hookPermanentAuraButtons()

  local visible = 0
  local permanent = 0

  local function inspect(button)
    if not isFrameLike(button) or not button:IsShown() then
      return
    end

    visible = visible + 1
    local matched = applyPermanentAuraButtonText(button)
    if matched then
      permanent = permanent + 1
    end

    if debugLines then
      local info = button.buttonInfo
      debugLines[#debugLines + 1] = ("buttonInfo=%s duration=%s expiration=%s permanent=%s"):format(
        tostring(info ~= nil),
        tostring(info and info.duration),
        tostring(info and info.expirationTime),
        tostring(matched)
      )
    end
  end

  for index = 1, 40 do
    local button = _G["BuffButton" .. index]
    if button then
      inspect(button)
    end
  end

  forEachAuraButton(BuffFrame, inspect)
  forEachAuraButton(BuffFrame and BuffFrame.AuraContainer, inspect)
  forEachAuraButton(DebuffFrame, inspect)
  forEachAuraButton(DebuffFrame and DebuffFrame.AuraContainer, inspect)

  return visible, permanent
end

local permanentAuraTextPending

local function requestPermanentAuraTextUpdate()
  if permanentAuraTextPending then
    return
  end

  permanentAuraTextPending = true
  after(0.1, function()
    permanentAuraTextPending = nil
    updatePermanentAuraText()
  end)
end

local function applyChatClassColors()
  if not db().chatClassColors then
    return
  end

  local groups = {
    "SAY",
    "YELL",
    "EMOTE",
    "GUILD",
    "OFFICER",
    "PARTY",
    "PARTY_LEADER",
    "RAID",
    "RAID_LEADER",
    "RAID_WARNING",
    "INSTANCE_CHAT",
    "INSTANCE_CHAT_LEADER",
    "CHANNEL",
    "WHISPER",
    "WHISPER_INFORM",
    "BN_WHISPER",
    "BN_WHISPER_INFORM",
  }

  for _, group in ipairs(groups) do
    if SetChatColorNameByClass then
      pcall(SetChatColorNameByClass, group, true)
    end
    if ToggleChatColorNamesByClassGroup then
      pcall(ToggleChatColorNamesByClassGroup, true, group)
    end
  end
end

local function classColorByFile(classFile)
  local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
  if color then
    return color.r, color.g, color.b
  end
  return 1, 1, 1
end

local function classFileByLocalizedName(className)
  if not className then
    return nil
  end

  for classFile, localized in pairs(LOCALIZED_CLASS_NAMES_MALE or {}) do
    if localized == className then
      return classFile
    end
  end
  for classFile, localized in pairs(LOCALIZED_CLASS_NAMES_FEMALE or {}) do
    if localized == className then
      return classFile
    end
  end
  return nil
end

local function setFontStringClassColor(fontString, classFile)
  if not fontString or not classFile then
    return
  end
  fontString:SetTextColor(classColorByFile(classFile))
end

local function updateGuildRosterColors()
  if not db().guildClassColors then
    return
  end

  local offset = 0
  if FauxScrollFrame_GetOffset and GuildListScrollFrame then
    offset = FauxScrollFrame_GetOffset(GuildListScrollFrame)
  end
  local visibleRows = GUILDMEMBERS_TO_DISPLAY or 13

  for row = 1, visibleRows do
    local index = offset + row
    local button = _G["GuildFrameButton" .. row] or _G["GuildFrameGuildStatusButton" .. row]
    local nameText = _G["GuildFrameButton" .. row .. "Name"] or _G["GuildFrameGuildStatusButton" .. row .. "Name"]
    local classText = _G["GuildFrameButton" .. row .. "Class"] or _G["GuildFrameGuildStatusButton" .. row .. "Class"]

    if button and button:IsShown() and nameText and GetGuildRosterInfo then
      local _, _, _, _, class, _, _, _, _, _, classFile = GetGuildRosterInfo(index)
      classFile = classFile or classFileByLocalizedName(class)
      setFontStringClassColor(nameText, classFile)
      setFontStringClassColor(classText, classFile)
    end
  end
end

local function friendInfoByIndex(index)
  if C_FriendList and C_FriendList.GetFriendInfoByIndex then
    local info = C_FriendList.GetFriendInfoByIndex(index)
    if info then
      return info.name, info.className, info.classFile
    end
  end
  if GetFriendInfo then
    local name, _, className = GetFriendInfo(index)
    return name, className, classFileByLocalizedName(className)
  end
  return nil, nil, nil
end

local function updateFriendListColors()
  if not db().guildClassColors then
    return
  end

  local offset = 0
  if FauxScrollFrame_GetOffset and FriendsFrameFriendsScrollFrame then
    offset = FauxScrollFrame_GetOffset(FriendsFrameFriendsScrollFrame)
  end
  local visibleRows = FRIENDS_TO_DISPLAY or 20

  for row = 1, visibleRows do
    local index = offset + row
    local button = _G["FriendsFrameFriendsScrollFrameButton" .. row]
    local nameText = _G["FriendsFrameFriendsScrollFrameButton" .. row .. "Name"]
      or _G["FriendsFrameFriendsScrollFrameButton" .. row .. "ButtonTextName"]
    local classText = _G["FriendsFrameFriendsScrollFrameButton" .. row .. "Class"]

    if button and button:IsShown() then
      local _, className, classFile = friendInfoByIndex(index)
      classFile = classFile or classFileByLocalizedName(className)
      setFontStringClassColor(nameText, classFile)
      setFontStringClassColor(classText, classFile)
    end
  end
end

local function updateWhoListColors()
  if not db().guildClassColors then
    return
  end

  local offset = 0
  if FauxScrollFrame_GetOffset and WhoListScrollFrame then
    offset = FauxScrollFrame_GetOffset(WhoListScrollFrame)
  end
  local visibleRows = WHOS_TO_DISPLAY or 17

  for row = 1, visibleRows do
    local index = offset + row
    local button = _G["WhoFrameButton" .. row]
    local nameText = _G["WhoFrameButton" .. row .. "Name"]
    local classText = _G["WhoFrameButton" .. row .. "Class"]

    if button and button:IsShown() and GetWhoInfo then
      local _, _, _, _, className, _, classFile = GetWhoInfo(index)
      classFile = classFile or classFileByLocalizedName(className)
      setFontStringClassColor(nameText, classFile)
      setFontStringClassColor(classText, classFile)
    end
  end
end

local function updateSocialClassColors()
  updateGuildRosterColors()
  updateFriendListColors()
  updateWhoListColors()
end

local function insertUnitPopupButton(menuName, buttonName, beforeButtonName)
  if not UnitPopupMenus or not UnitPopupButtons or not UnitPopupMenus[menuName] or not UnitPopupButtons[buttonName] then
    return
  end

  local menu = UnitPopupMenus[menuName]
  for _, existing in ipairs(menu) do
    if existing == buttonName then
      return
    end
  end

  local insertIndex = #menu + 1
  for index, existing in ipairs(menu) do
    if existing == beforeButtonName or existing == "CANCEL" then
      insertIndex = index
      break
    end
  end
  table.insert(menu, insertIndex, buttonName)
end

local modernUnitMenusExtended = {}
local function unitPopupTargetName(contextData)
  if not contextData then
    return nil
  end
  if contextData.name and contextData.name ~= "" then
    return contextData.name
  end
  if contextData.unit and UnitExists and UnitExists(contextData.unit) then
    return UnitName(contextData.unit)
  end
  return nil
end

local function addPlayerFriend(name)
  if not name or name == "" then
    return
  end
  if C_FriendList and C_FriendList.AddFriend then
    C_FriendList.AddFriend(name)
  elseif AddFriend then
    AddFriend(name)
  end
end

local function invitePlayerToGuild(name)
  if not name or name == "" then
    return
  end
  if C_GuildInfo and C_GuildInfo.Invite then
    C_GuildInfo.Invite(name)
  elseif GuildInvite then
    GuildInvite(name)
  end
end

local function guildInviteMenuText()
  if CHAT_INVITE_SEND and CHAT_MSG_GUILD then
    return CHAT_INVITE_SEND .. CHAT_MSG_GUILD
  end
  return GUILD_INVITE or "Guild Invite"
end

local function addModernUnitMenuButtons(owner, rootDescription, contextData)
  local name = unitPopupTargetName(contextData)
  if not name then
    return
  end

  rootDescription:CreateDivider()
  rootDescription:CreateButton(ADD_FRIEND or "Add Friend", function()
    addPlayerFriend(name)
  end)
  rootDescription:CreateButton(guildInviteMenuText(), function()
    invitePlayerToGuild(name)
  end)
end

local function extendModernPlayerNameMenus()
  if not Menu or not Menu.ModifyMenu then
    return
  end

  local menus = {
    "MENU_UNIT_PLAYER",
    "MENU_UNIT_FRIEND",
    "MENU_UNIT_PARTY",
    "MENU_UNIT_RAID_PLAYER",
    "MENU_UNIT_TARGET",
    "MENU_UNIT_COMMUNITIES_MEMBER",
  }

  for _, menuName in ipairs(menus) do
    if not modernUnitMenusExtended[menuName] then
      Menu.ModifyMenu(menuName, addModernUnitMenuButtons)
      modernUnitMenusExtended[menuName] = true
    end
  end
end

local function extendPlayerNameMenus()
  if UnitPopupButtons then
    UnitPopupButtons.ADD_FRIEND = UnitPopupButtons.ADD_FRIEND or { text = ADD_FRIEND or "Add Friend", dist = 0 }
    UnitPopupButtons.GUILD_INVITE = UnitPopupButtons.GUILD_INVITE or { text = guildInviteMenuText(), dist = 0 }
  end

  extendModernPlayerNameMenus()

  local menus = {
    "PLAYER",
    "PARTY",
    "RAID_PLAYER",
    "RAID",
    "FRIEND",
    "CHAT_ROSTER",
    "TARGET",
  }

  for _, menuName in ipairs(menus) do
    insertUnitPopupButton(menuName, "ADD_FRIEND", "IGNORE")
    insertUnitPopupButton(menuName, "GUILD_INVITE", "IGNORE")
  end
end

local function recordTaintEvent(event, addon, action)
  local cfg = db()
  cfg.taintEvents = cfg.taintEvents or {}

  local entry = {
    time = date and date("%Y-%m-%d %H:%M:%S") or tostring(GetTime and GetTime() or 0),
    event = tostring(event or "-"),
    addon = tostring(addon or "unknown"),
    action = tostring(action or "unknown"),
  }

  table.insert(cfg.taintEvents, entry)
  while #cfg.taintEvents > 50 do
    table.remove(cfg.taintEvents, 1)
  end

  printMsg(("taint: %s addon=%s action=%s"):format(entry.event, entry.addon, entry.action))
end

local function printTaintEvents()
  local entries = db().taintEvents or {}
  if #entries == 0 then
    printMsg("taint log is empty")
    return
  end

  printMsg(("taint log: %d entries"):format(#entries))
  for index = math.max(1, #entries - 9), #entries do
    local entry = entries[index]
    printMsg(("%02d %s %s addon=%s action=%s"):format(
      index,
      tostring(entry.time or "-"),
      tostring(entry.event or "-"),
      tostring(entry.addon or "-"),
      tostring(entry.action or "-")
    ))
  end
end

local configUI = {}
local configDirty

local function inCombat()
  return InCombatLockdown and InCombatLockdown()
end

local function setSolidTexture(texture, r, g, b, a)
  if texture.SetColorTexture then
    texture:SetColorTexture(r, g, b, a)
  else
    texture:SetTexture("Interface\\Buttons\\WHITE8X8")
    texture:SetVertexColor(r, g, b, a)
  end
end

local function clearTaintEvents()
  db().taintEvents = {}
end

local function applyConfigChange(callback, combatMessage)
  callback()
  if inCombat() then
    configDirty = true
    if combatMessage then
      printMsg(combatMessage)
    end
  end
end

local function setCoreFlag(key, value)
  local cfg = db()
  cfg[key] = value and true or false

  if key == "permanentAuraText" then
    if cfg.permanentAuraText then
      applyConfigChange(updatePermanentAuraText, "战斗中：已保存，战斗结束后刷新永久光环文本。")
    else
      for index = 1, 40 do
        hidePermanentAuraText(_G["BuffButton" .. index])
      end
      hidePermanentAuraContainer(BuffFrame and BuffFrame.AuraContainer)
      hidePermanentAuraContainer(BuffFrame)
    end
  elseif key == "chatClassColors" and cfg.chatClassColors then
    applyChatClassColors()
  elseif key == "guildClassColors" and cfg.guildClassColors then
    updateSocialClassColors()
  elseif key == "taintLogEnabled" and not cfg.taintLogEnabled then
    clearTaintEvents()
  end

  if configUI.refresh then
    configUI.refresh()
  end
end

local function setFPSCoordinate(axis, value)
  value = tonumber(value)
  if not value then
    return
  end

  local cfg = db().fps
  cfg[axis] = math.floor(value + (value >= 0 and 0.5 or -0.5))
  applyConfigChange(applyFPSPosition, "战斗中：已保存，战斗结束后应用 FPS 坐标。")
  if configUI.refresh then
    configUI.refresh()
  end
end

local function setEquipmentFlag(key, value)
  applyConfigChange(function()
    if AutyanCore_SetEquipmentInfoFlag then
      AutyanCore_SetEquipmentInfoFlag(key, value and true or false)
    end
  end, "战斗中：已保存，战斗结束后刷新装备面板。")
  if configUI.refresh then
    configUI.refresh()
  end
end

local function makeConfigDivider(parent, x, y, width)
  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  line:SetSize(width, 1)
  setSolidTexture(line, 0.45, 0.52, 0.58, 0.25)
  return line
end

local function makeConfigCheckbox(parent, name, labelText, getter, setter, x, y)
  local button = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  button:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  button:SetSize(24, 24)
  local label = _G[name .. "Text"]
  if label then
    label:SetText(labelText)
    label:SetTextColor(0.78, 0.86, 0.9, 1)
  end
  button.AutyanGetter = getter
  button:SetScript("OnClick", function(self)
    setter(self:GetChecked())
  end)
  configUI.checkboxes[#configUI.checkboxes + 1] = button
  return button
end

local function makeConfigEditBox(parent, name, labelText, getter, setter, x, y)
  local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y - 4)
  label:SetSize(52, 18)
  label:SetJustifyH("LEFT")
  label:SetText(labelText)
  label:SetTextColor(0.78, 0.86, 0.9, 1)

  local box = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
  box:SetPoint("TOPLEFT", parent, "TOPLEFT", x + 54, y)
  box:SetSize(72, 20)
  box:SetAutoFocus(false)
  box:SetNumeric(false)
  box.AutyanGetter = getter
  box:SetScript("OnEnterPressed", function(self)
    setter(self:GetText())
    self:ClearFocus()
  end)
  box:SetScript("OnEditFocusLost", function(self)
    setter(self:GetText())
  end)
  configUI.editBoxes[#configUI.editBoxes + 1] = box
  return box
end

local function createConfigFrame()
  if configUI.frame then
    return
  end

  configUI.checkboxes = {}
  configUI.editBoxes = {}

  local frame = CreateFrame("Frame", "AutyanCoreConfigFrame", UIParent)
  frame:SetSize(560, 430)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
  frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  setSolidTexture(bg, 0.025, 0.028, 0.032, 0.97)

  local header = frame:CreateTexture(nil, "BORDER")
  header:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
  header:SetSize(1, 54)
  setSolidTexture(header, 0.06, 0.075, 0.085, 0.88)

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -14)
  title:SetText("AutyanCore 设置")
  title:SetTextColor(0.86, 0.94, 1, 1)

  local note = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  note:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
  note:SetSize(450, 18)
  note:SetJustifyH("LEFT")
  note:SetText("战斗中保存配置；受保护或界面刷新相关变更会在脱战后应用。")
  note:SetTextColor(0.62, 0.68, 0.72, 1)

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
  close:SetScript("OnClick", function() frame:Hide() end)

  local coreTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  coreTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 28, -76)
  coreTitle:SetText("核心开关")
  coreTitle:SetTextColor(0.86, 0.94, 1, 1)
  makeConfigDivider(frame, 28, -100, 230)

  local equipTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  equipTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 300, -76)
  equipTitle:SetText("装备面板")
  equipTitle:SetTextColor(0.86, 0.94, 1, 1)
  makeConfigDivider(frame, 300, -100, 230)

  local function coreGetter(key)
    return function()
      return db()[key]
    end
  end
  local function equipGetter(key)
    return function()
      return AutyanCore_GetEquipmentInfoFlag and AutyanCore_GetEquipmentInfoFlag(key)
    end
  end

  makeConfigCheckbox(frame, "AutyanCoreCfgPermanentAuraText", "永久光环 N/A", coreGetter("permanentAuraText"), function(value) setCoreFlag("permanentAuraText", value) end, 28, -114)
  makeConfigCheckbox(frame, "AutyanCoreCfgFPS", "FPS 坐标启用", function() return db().fps.enabled end, function(value) db().fps.enabled = value and true or false; if value then applyFPSPosition() end; configUI.refresh() end, 28, -146)
  makeConfigCheckbox(frame, "AutyanCoreCfgChatClass", "聊天职业染色", coreGetter("chatClassColors"), function(value) setCoreFlag("chatClassColors", value) end, 28, -178)
  makeConfigCheckbox(frame, "AutyanCoreCfgGuildClass", "好友/公会职业染色", coreGetter("guildClassColors"), function(value) setCoreFlag("guildClassColors", value) end, 28, -210)
  makeConfigCheckbox(frame, "AutyanCoreCfgTaint", "记录 taint 日志", coreGetter("taintLogEnabled"), function(value) setCoreFlag("taintLogEnabled", value) end, 28, -306)

  local fpsTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fpsTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -346)
  fpsTitle:SetText("FPS 位置")
  fpsTitle:SetTextColor(0.86, 0.94, 1, 1)
  makeConfigEditBox(frame, "AutyanCoreCfgFPSX", "X", function() return db().fps.x end, function(value) setFPSCoordinate("x", value) end, 30, -374)
  makeConfigEditBox(frame, "AutyanCoreCfgFPSY", "Y", function() return db().fps.y end, function(value) setFPSCoordinate("y", value) end, 158, -374)

  makeConfigCheckbox(frame, "AutyanCoreCfgEquipEnabled", "启用装备信息", equipGetter("enabled"), function(value) setEquipmentFlag("enabled", value) end, 300, -114)
  makeConfigCheckbox(frame, "AutyanCoreCfgEquipCharacter", "角色面板", equipGetter("characterPanel"), function(value) setEquipmentFlag("characterPanel", value) end, 300, -146)
  makeConfigCheckbox(frame, "AutyanCoreCfgEquipInspect", "观察面板", equipGetter("inspectPanel"), function(value) setEquipmentFlag("inspectPanel", value) end, 300, -178)
  makeConfigCheckbox(frame, "AutyanCoreCfgEquipDurability", "耐久百分比", equipGetter("durability"), function(value) setEquipmentFlag("durability", value) end, 300, -210)
  makeConfigCheckbox(frame, "AutyanCoreCfgEquipQuality", "装备品质边框", equipGetter("qualityBorders"), function(value) setEquipmentFlag("qualityBorders", value) end, 300, -242)
  makeConfigCheckbox(frame, "AutyanCoreCfgEquipRepair", "维修费用", equipGetter("repairCost"), function(value) setEquipmentFlag("repairCost", value) end, 300, -274)

  local footer = frame:CreateTexture(nil, "BORDER")
  footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 1, 1)
  footer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
  footer:SetSize(1, 43)
  setSolidTexture(footer, 0.035, 0.04, 0.046, 0.78)

  local status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  status:SetPoint("LEFT", frame, "BOTTOMLEFT", 18, 22)
  status:SetSize(340, 18)
  status:SetJustifyH("LEFT")
  configUI.status = status

  local clearTaint = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  clearTaint:SetSize(96, 22)
  clearTaint:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -104, 12)
  clearTaint:SetText("清空 taint")
  clearTaint:SetScript("OnClick", function()
    clearTaintEvents()
    printMsg("taint log cleared")
    configUI.refresh()
  end)

  local done = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  done:SetSize(82, 22)
  done:SetPoint("LEFT", clearTaint, "RIGHT", 8, 0)
  done:SetText("完成")
  done:SetScript("OnClick", function() frame:Hide() end)

  frame:Hide()
  configUI.frame = frame
end

configUI.refresh = function()
  if not configUI.frame then
    return
  end
  for _, checkbox in ipairs(configUI.checkboxes or {}) do
    checkbox:SetChecked(checkbox.AutyanGetter and checkbox.AutyanGetter() and true or false)
  end
  for _, box in ipairs(configUI.editBoxes or {}) do
    if not box:HasFocus() then
      box:SetText(tostring(box.AutyanGetter and box.AutyanGetter() or ""))
    end
  end
  if configUI.status then
    if inCombat() then
      configUI.status:SetText("战斗中：已保存，脱战后应用需要刷新界面的变更。")
      configUI.status:SetTextColor(0.95, 0.78, 0.42, 1)
    else
      local count = #(db().taintEvents or {})
      configUI.status:SetFormattedText("就绪。taint 日志：%d 条。", count)
      configUI.status:SetTextColor(0.62, 0.68, 0.72, 1)
    end
  end
end

local function toggleConfigFrame()
  createConfigFrame()
  configUI.refresh()
  if configUI.frame:IsShown() then
    configUI.frame:Hide()
  else
    configUI.frame:Show()
    configUI.refresh()
  end
end

local socialHooksInstalled = {}
local function installSocialClassColorHooks()
  if not hooksecurefunc then
    return
  end

  local function hookUpdate(functionName)
    if _G[functionName] and not socialHooksInstalled[functionName] then
      hooksecurefunc(functionName, updateSocialClassColors)
      socialHooksInstalled[functionName] = true
    end
  end

  hookUpdate("GuildFrame_Update")
  hookUpdate("GuildStatus_Update")
  hookUpdate("FriendsFrame_UpdateFriends")
  hookUpdate("FriendsFrame_Update")
  hookUpdate("WhoList_Update")
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("GUILD_ROSTER_UPDATE")
events:RegisterEvent("FRIENDLIST_UPDATE")
events:RegisterEvent("WHO_LIST_UPDATE")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("ADDON_ACTION_BLOCKED")
events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
events:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    local addon = ...
    if addon == "Blizzard_FriendsFrame" or addon == "Blizzard_GuildUI" or addon == "Blizzard_WhoUI" then
      installSocialClassColorHooks()
      after(0, updateSocialClassColors)
    end
  elseif event == "PLAYER_LOGIN" then
    db()
    migrateRiskyDefaults()
    applyChatClassColors()
    extendPlayerNameMenus()
    installSocialClassColorHooks()
    after(0.5, applyFPSPosition)
    after(1, hookPermanentAuraButtons)
    after(1, updateSocialClassColors)
    after(1, installSocialClassColorHooks)
    after(2, extendPlayerNameMenus)
    after(2, updatePermanentAuraText)
  elseif event == "PLAYER_ENTERING_WORLD" then
    extendPlayerNameMenus()
    installSocialClassColorHooks()
    after(0.5, applyFPSPosition)
    after(1, hookPermanentAuraButtons)
    after(1, updateSocialClassColors)
    after(1, installSocialClassColorHooks)
    after(2, updatePermanentAuraText)
  elseif event == "UNIT_AURA" then
    local unit = ...
    if unit == "player" then
      hookPermanentAuraButtons()
      requestPermanentAuraTextUpdate()
    end
  elseif event == "GUILD_ROSTER_UPDATE" then
    after(0, updateSocialClassColors)
  elseif event == "FRIENDLIST_UPDATE" or event == "WHO_LIST_UPDATE" then
    after(0, updateSocialClassColors)
  elseif event == "PLAYER_REGEN_ENABLED" then
    if configDirty then
      configDirty = nil
      applyFPSPosition()
      updatePermanentAuraText()
      updateSocialClassColors()
      if AutyanCore_RefreshEquipmentInfo then
        AutyanCore_RefreshEquipmentInfo()
      end
      if configUI.refresh then
        configUI.refresh()
      end
      printMsg("combat ended: pending config changes applied")
    end
  elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
    local addon, action = ...
    if db().taintLogEnabled then
      recordTaintEvent(event, addon, action)
    end
  end
end)

installSocialClassColorHooks()

SLASH_AUTYANCORE1 = "/autyan"
local function handleAutyanCommand(input)
  input = input and input:lower() or ""

  if input == "fps" then
    local cfg = db().fps
    printMsg(("FPS anchor: %s UIParent %s %d %d"):format(cfg.point, cfg.relativePoint, cfg.x, cfg.y))
    return
  end

  if input == "config" or input == "options" or input == "设置" then
    toggleConfigFrame()
    return
  end

  local x, y = input:match("^fps%s+(-?%d+)%s+(-?%d+)$")
  if x and y then
    local cfg = db().fps
    cfg.x = tonumber(x)
    cfg.y = tonumber(y)
    applyFPSPosition()
    printMsg(("FPS anchor updated: %d %d"):format(cfg.x, cfg.y))
    return
  end

  if input == "buffna on" then
    db().permanentAuraText = true
    updatePermanentAuraText()
    printMsg("permanent buff N/A enabled")
    return
  end

  if input == "buffna off" then
    db().permanentAuraText = false
    for index = 1, 40 do
      hidePermanentAuraText(_G["BuffButton" .. index])
    end
    hidePermanentAuraContainer(BuffFrame and BuffFrame.AuraContainer)
    hidePermanentAuraContainer(BuffFrame)
    printMsg("permanent buff N/A disabled")
    return
  end

  if input == "buffna debug" then
    local debugLines = {}
    local scanned, permanent = updatePermanentAuraText(debugLines)
    printMsg(("permanent buff scan: %d visible, %d permanent"):format(scanned or 0, permanent or 0))
    for index = 1, math.min(#debugLines, 8) do
      printMsg(debugLines[index])
    end
    return
  end

  if input == "taint" then
    printTaintEvents()
    return
  end

  if input == "taint on" then
    setCoreFlag("taintLogEnabled", true)
    printMsg("taint log enabled")
    return
  end

  if input == "taint off" then
    setCoreFlag("taintLogEnabled", false)
    printMsg("taint log disabled and cleared")
    return
  end

  if input == "taint clear" then
    db().taintEvents = {}
    printMsg("taint log cleared")
    return
  end

  if input == "equip debug" then
    if AutyanCore_EquipmentInfoDebug then
      AutyanCore_EquipmentInfoDebug()
    else
      printMsg("equipment module is not loaded")
    end
    return
  end

  printMsg("commands: /autyan config, /autyan fps, /autyan fps <x> <y>, /autyan buffna on, /autyan buffna off, /autyan buffna debug, /autyan taint, /autyan taint on, /autyan taint off, /autyan taint clear, /autyan equip debug")
end

SlashCmdList.AUTYANCORE = function(input)
  local ok, err = pcall(handleAutyanCommand, input)
  if not ok then
    printMsg("command failed: " .. tostring(err))
  end
end
