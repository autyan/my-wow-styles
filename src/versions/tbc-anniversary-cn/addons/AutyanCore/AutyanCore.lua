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
  hidePlayerCastBar = false,
  bigFootAutoJoin = false,
  bigFootChannelBase = "大脚世界频道",
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

local function keepFrameHidden(frame)
  if not frame then
    return
  end

  frame:Hide()
end

local function applyPlayerCastBarVisibility()
  if not db().hidePlayerCastBar then
    return
  end

  local frames = {
    _G.CastingBarFrame,
    _G.PlayerCastingBarFrame,
    _G.PetCastingBarFrame,
  }

  for _, frame in ipairs(frames) do
    if frame then
      frame:UnregisterAllEvents()
      frame:Hide()
      if not frame.AutyanHideCastBarHooked then
        frame:HookScript("OnShow", keepFrameHidden)
        frame.AutyanHideCastBarHooked = true
      end
    end
  end
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

local function extendPlayerNameMenus()
  if UnitPopupButtons then
    UnitPopupButtons.ADD_FRIEND = UnitPopupButtons.ADD_FRIEND or { text = ADD_FRIEND or "Add Friend", dist = 0 }
    UnitPopupButtons.GUILD_INVITE = UnitPopupButtons.GUILD_INVITE or { text = GUILD_INVITE or "Guild Invite", dist = 0 }
  end

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

local function nextBigFootChannelName(channelName)
  local base = db().bigFootChannelBase
  if not channelName or not channelName:find(base, 1, true) then
    return base .. "2"
  end

  local suffix = channelName:match(base .. "(%d+)")
  return base .. tostring((tonumber(suffix) or 1) + 1)
end

local function isOnChannel(channelName)
  local list = { GetChannelList() }
  for index = 2, #list, 3 do
    if list[index] == channelName then
      return true
    end
  end
  return false
end

local function joinBigFootChannel(channelName, manual)
  local cfg = db()
  if not manual and not cfg.bigFootAutoJoin then
    return
  end
  if GetLocale() ~= "zhCN" and GetLocale() ~= "zhTW" then
    return
  end

  channelName = channelName or cfg.bigFootChannelBase
  if GetChannelName(channelName) == 0 and not isOnChannel(channelName) then
    local ok = pcall(JoinTemporaryChannel, channelName)
    if not ok then
      printMsg("failed to join channel: " .. tostring(channelName))
    end
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
    after(0.5, applyPlayerCastBarVisibility)
    after(1, hookPermanentAuraButtons)
    after(1, updateSocialClassColors)
    after(1, installSocialClassColorHooks)
    after(2, extendPlayerNameMenus)
    after(2, function() joinBigFootChannel() end)
    after(2, updatePermanentAuraText)
  elseif event == "PLAYER_ENTERING_WORLD" then
    extendPlayerNameMenus()
    installSocialClassColorHooks()
    after(0.5, applyFPSPosition)
    after(0.5, applyPlayerCastBarVisibility)
    after(1, hookPermanentAuraButtons)
    after(1, updateSocialClassColors)
    after(1, installSocialClassColorHooks)
    after(2, function() joinBigFootChannel() end)
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
  elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
    local addon, action = ...
    recordTaintEvent(event, addon, action)
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

  local x, y = input:match("^fps%s+(-?%d+)%s+(-?%d+)$")
  if x and y then
    local cfg = db().fps
    cfg.x = tonumber(x)
    cfg.y = tonumber(y)
    applyFPSPosition()
    printMsg(("FPS anchor updated: %d %d"):format(cfg.x, cfg.y))
    return
  end

  if input == "joinbf" then
    joinBigFootChannel(db().bigFootChannelBase, true)
    printMsg("joining BigFoot world channel")
    return
  end

  if input == "joinbf2" then
    joinBigFootChannel(nextBigFootChannelName(db().bigFootChannelBase), true)
    printMsg("joining BigFoot fallback channel")
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

  if input == "castbar off" then
    db().hidePlayerCastBar = true
    applyPlayerCastBarVisibility()
    printMsg("Blizzard player cast bar hidden")
    return
  end

  if input == "castbar on" then
    db().hidePlayerCastBar = false
    printMsg("Blizzard player cast bar hide disabled; reload UI to restore it")
    return
  end

  if input == "taint" then
    printTaintEvents()
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

  printMsg("commands: /autyan fps, /autyan fps <x> <y>, /autyan buffna on, /autyan buffna off, /autyan buffna debug, /autyan castbar off, /autyan castbar on, /autyan taint, /autyan taint clear, /autyan equip debug, /autyan joinbf, /autyan joinbf2")
end

SlashCmdList.AUTYANCORE = function(input)
  local ok, err = pcall(handleAutyanCommand, input)
  if not ok then
    printMsg("command failed: " .. tostring(err))
  end
end
