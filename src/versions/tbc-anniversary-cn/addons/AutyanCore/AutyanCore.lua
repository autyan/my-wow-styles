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
  chatAssistant = {
    enabled = true,
    keywordHighlight = true,
    copyLinks = true,
    fastSwitch = true,
    channelBar = true,
    barPosition = nil,
    keywords = {},
  },
  taintLogEnabled = true,
}

local function copyDefaultValue(value)
  if type(value) ~= "table" then
    return value
  end

  local copy = {}
  for key, childValue in pairs(value) do
    copy[key] = copyDefaultValue(childValue)
  end
  return copy
end

local function applyDefaults(target, source)
  for key, value in pairs(source) do
    if target[key] == nil then
      target[key] = copyDefaultValue(value)
    elseif type(value) == "table" and type(target[key]) == "table" then
      applyDefaults(target[key], value)
    end
  end
end

local function db()
  applyDefaults(AutyanCoreDB, defaults)
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

local copyBuffer = {}
local copyBufferNextId = 0
local copyHistory = {}
local chatAssistantFilterInstalled
local configUI
local updateChatSwitchBar
local showCopyPanel
local installChatMouseCopyHooks

local chatAssistantEvents = {
  "CHAT_MSG_SAY",
  "CHAT_MSG_YELL",
  "CHAT_MSG_EMOTE",
  "CHAT_MSG_GUILD",
  "CHAT_MSG_OFFICER",
  "CHAT_MSG_PARTY",
  "CHAT_MSG_PARTY_LEADER",
  "CHAT_MSG_RAID",
  "CHAT_MSG_RAID_LEADER",
  "CHAT_MSG_RAID_WARNING",
  "CHAT_MSG_INSTANCE_CHAT",
  "CHAT_MSG_INSTANCE_CHAT_LEADER",
  "CHAT_MSG_CHANNEL",
  "CHAT_MSG_WHISPER",
  "CHAT_MSG_WHISPER_INFORM",
  "CHAT_MSG_BN_WHISPER",
  "CHAT_MSG_BN_WHISPER_INFORM",
}

local channelPrefixes = {
  s = "/s ",
  say = "/s ",
  y = "/y ",
  yell = "/y ",
  p = "/p ",
  party = "/p ",
  r = "/raid ",
  raid = "/raid ",
  rw = "/rw ",
  g = "/g ",
  guild = "/g ",
  o = "/o ",
  officer = "/o ",
  i = "/i ",
  instance = "/i ",
  bg = "/bg ",
}

local function chatAssistantDb()
  local cfg = db().chatAssistant
  cfg.keywords = cfg.keywords or {}
  return cfg
end

local function escapeColorPipes(text)
  if not text then
    return ""
  end
  return tostring(text):gsub("|", "||")
end

local function escapePattern(text)
  return tostring(text or ""):gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

local function stripChatFormatting(text)
  text = tostring(text or "")
  text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
  text = text:gsub("|r", "")
  text = text:gsub("|T.-|t", "")
  text = text:gsub("|H.-|h(.-)|h", "%1")
  text = text:gsub("||", "|")
  return text
end

local function ensureDefaultChatKeyword()
  local cfg = chatAssistantDb()
  if #cfg.keywords > 0 then
    return
  end

  local playerName = UnitName and UnitName("player")
  if playerName and playerName ~= "" then
    cfg.keywords[1] = playerName
  end
end

local function addCopyBufferText(text)
  copyBufferNextId = copyBufferNextId + 1
  if copyBufferNextId > 999999 then
    copyBufferNextId = 1
  end

  copyBuffer[copyBufferNextId] = text
  copyHistory[#copyHistory + 1] = text
  while #copyHistory > 100 do
    table.remove(copyHistory, 1)
  end
  local oldest = copyBufferNextId - 80
  if oldest > 0 then
    copyBuffer[oldest] = nil
  end
  return copyBufferNextId
end

local function highlightChatKeywords(message)
  local cfg = chatAssistantDb()
  if not cfg.enabled or not cfg.keywordHighlight then
    return message
  end

  local highlighted = message
  for _, keyword in ipairs(cfg.keywords or {}) do
    if keyword and keyword ~= "" then
      local safeKeyword = escapeColorPipes(keyword)
      highlighted = highlighted:gsub(escapePattern(safeKeyword), "|cff33ff99" .. safeKeyword .. "|r")
    end
  end
  return highlighted
end

local function chatCopyLabelFor(event, author, message)
  local channel = event and event:gsub("^CHAT_MSG_", "") or "CHAT"
  local text = stripChatFormatting(message)
  if author and author ~= "" then
    return ("[%s] %s: %s"):format(channel, author, text)
  end
  return ("[%s] %s"):format(channel, text)
end

local function chatAssistantFilter(_, event, message, author, ...)
  local cfg = chatAssistantDb()
  if not cfg.enabled or type(message) ~= "string" then
    return false, message, author, ...
  end

  local output = highlightChatKeywords(message)
  if cfg.copyLinks then
    addCopyBufferText(chatCopyLabelFor(event, author, message))
  end

  return false, output, author, ...
end

local function showCopyPopup(text)
  if not StaticPopupDialogs or not StaticPopup_Show then
    printMsg(stripChatFormatting(text))
    return
  end

  StaticPopupDialogs.AUTYANCORE_COPY_CHAT = StaticPopupDialogs.AUTYANCORE_COPY_CHAT or {
    text = "复制聊天内容",
    button1 = OKAY or "OK",
    hasEditBox = true,
    editBoxWidth = 360,
    maxLetters = 4096,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }

  local dialog = StaticPopup_Show("AUTYANCORE_COPY_CHAT")
  if dialog and dialog.editBox then
    dialog.editBox:SetText(text or "")
    dialog.editBox:HighlightText()
    dialog.editBox:SetFocus()
  end
end

local function installChatAssistantFilters()
  if chatAssistantFilterInstalled then
    if installChatMouseCopyHooks then
      installChatMouseCopyHooks()
    end
    return
  end

  local addFilter = ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter or ChatFrame_AddMessageEventFilter
  if not addFilter then
    return
  end

  for _, event in ipairs(chatAssistantEvents) do
    pcall(addFilter, event, chatAssistantFilter)
  end
  chatAssistantFilterInstalled = true
  if installChatMouseCopyHooks then
    installChatMouseCopyHooks()
  end
end

local function setChatAssistantFlag(key, value)
  chatAssistantDb()[key] = value and true or false
  if key == "enabled" or key == "copyLinks" then
    installChatAssistantFilters()
  end
  if updateChatSwitchBar then
    updateChatSwitchBar()
  end
  if configUI.refresh then
    configUI.refresh()
  end
end

local function openChatWithPrefix(prefix)
  if not chatAssistantDb().fastSwitch then
    printMsg("chat fast switch is disabled")
    return
  end

  local frame = SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME
  local editBox = ChatEdit_ChooseBoxForSend and ChatEdit_ChooseBoxForSend(frame) or ChatFrame1EditBox
  if not editBox then
    printMsg("chat edit box is not available")
    return
  end

  if ChatEdit_ActivateChat then
    ChatEdit_ActivateChat(editBox)
  else
    editBox:Show()
    editBox:SetFocus()
  end
  editBox:SetText(prefix or "")
  editBox:SetCursorPosition(editBox:GetNumLetters())
end

local function listChatKeywords()
  local keywords = chatAssistantDb().keywords or {}
  if #keywords == 0 then
    printMsg("chat keywords: none")
    return
  end

  printMsg("chat keywords:")
  for index, keyword in ipairs(keywords) do
    printMsg(("%d. %s"):format(index, keyword))
  end
end

local function addChatKeyword(keyword)
  keyword = keyword and keyword:match("^%s*(.-)%s*$")
  if not keyword or keyword == "" then
    printMsg("usage: /autyan chat add <keyword>")
    return
  end

  local keywords = chatAssistantDb().keywords
  for _, existing in ipairs(keywords) do
    if existing == keyword then
      printMsg("chat keyword already exists: " .. keyword)
      return
    end
  end
  keywords[#keywords + 1] = keyword
  printMsg("chat keyword added: " .. keyword)
end

local function removeChatKeyword(value)
  value = value and value:match("^%s*(.-)%s*$")
  local index = tonumber(value)
  local keywords = chatAssistantDb().keywords
  if not index or not keywords[index] then
    printMsg("usage: /autyan chat remove <number>")
    return
  end
  local removed = table.remove(keywords, index)
  printMsg("chat keyword removed: " .. tostring(removed))
end

local function handleChatAssistantCommand(input)
  if input ~= "chat" and not input:match("^chat%s+") then
    return false
  end

  local action, rest = input:match("^chat%s+(%S+)%s*(.*)$")
  if not action then
    printMsg("chat commands: /autyan chat on, off, copy, copy on/off, bar reset, bar <x> <y>, add <keyword>, remove <number>, list, say, party, raid, guild, officer, instance, yell")
    return true
  end

  action = action:lower()
  if action == "on" then
    setChatAssistantFlag("enabled", true)
    printMsg("chat assistant enabled")
  elseif action == "off" then
    setChatAssistantFlag("enabled", false)
    printMsg("chat assistant disabled")
  elseif action == "highlight" then
    local value = rest and rest:lower()
    setChatAssistantFlag("keywordHighlight", value ~= "off")
    printMsg("chat keyword highlight " .. (chatAssistantDb().keywordHighlight and "enabled" or "disabled"))
  elseif action == "copy" then
    local value = rest and rest:lower()
    if value == "on" or value == "off" then
      setChatAssistantFlag("copyLinks", value ~= "off")
      printMsg("chat copy panel " .. (chatAssistantDb().copyLinks and "enabled" or "disabled"))
    else
      showCopyPanel()
    end
  elseif action == "fast" then
    local value = rest and rest:lower()
    setChatAssistantFlag("fastSwitch", value ~= "off")
    printMsg("chat fast switch " .. (chatAssistantDb().fastSwitch and "enabled" or "disabled"))
  elseif action == "bar" then
    local value = rest and rest:lower()
    local x, y = rest and rest:match("^(-?%d+)%s+(-?%d+)$")
    if value == "on" or value == "off" then
      setChatAssistantFlag("channelBar", value ~= "off")
      printMsg("chat channel bar " .. (chatAssistantDb().channelBar and "enabled" or "disabled"))
    elseif value == "reset" then
      resetChatSwitchBarPosition()
      printMsg("chat channel bar position reset")
    elseif x and y then
      setChatSwitchBarCoordinate("x", x)
      setChatSwitchBarCoordinate("y", y)
      printMsg(("chat channel bar position: %s %s"):format(x, y))
    else
      printMsg("usage: /autyan chat bar on, off, reset, or <x> <y>")
    end
  elseif action == "add" then
    addChatKeyword(rest)
  elseif action == "remove" or action == "rm" or action == "del" then
    removeChatKeyword(rest)
  elseif action == "list" then
    listChatKeywords()
  elseif channelPrefixes[action] then
    openChatWithPrefix(channelPrefixes[action])
  else
    printMsg("unknown chat command: " .. action)
  end
  return true
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

configUI = {}
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

local copyPanel

local function recentCopyText(limit)
  limit = limit or 40
  local lines = {}
  local startIndex = math.max(1, #copyHistory - limit + 1)
  for index = startIndex, #copyHistory do
    lines[#lines + 1] = copyHistory[index]
  end
  return table.concat(lines, "\n")
end

local function createCopyPanel()
  if copyPanel then
    return copyPanel
  end

  local frame = CreateFrame("Frame", "AutyanCoreCopyPanel", UIParent)
  frame:SetSize(560, 360)
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

  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
  title:SetText("聊天复制")
  title:SetTextColor(0.86, 0.94, 1, 1)

  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
  close:SetScript("OnClick", function() frame:Hide() end)

  local scroll = CreateFrame("ScrollFrame", "AutyanCoreCopyPanelScrollFrame", frame, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -48)
  scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, 48)

  local editBox = CreateFrame("EditBox", "AutyanCoreCopyPanelEditBox", scroll)
  editBox:SetMultiLine(true)
  editBox:SetAutoFocus(false)
  editBox:SetFontObject(ChatFontNormal)
  editBox:SetWidth(500)
  editBox:SetTextInsets(4, 4, 4, 4)
  editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  scroll:SetScrollChild(editBox)
  frame.editBox = editBox

  local recent = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  recent:SetSize(86, 22)
  recent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 14)
  recent:SetText("最近40")
  recent:SetScript("OnClick", function()
    editBox:SetText(recentCopyText(40))
    editBox:HighlightText()
    editBox:SetFocus()
  end)

  local all = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  all:SetSize(86, 22)
  all:SetPoint("LEFT", recent, "RIGHT", 8, 0)
  all:SetText("全部")
  all:SetScript("OnClick", function()
    editBox:SetText(recentCopyText(100))
    editBox:HighlightText()
    editBox:SetFocus()
  end)

  local clear = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  clear:SetSize(86, 22)
  clear:SetPoint("LEFT", all, "RIGHT", 8, 0)
  clear:SetText("清空")
  clear:SetScript("OnClick", function()
    copyHistory = {}
    copyBuffer = {}
    editBox:SetText("")
  end)

  local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  hint:SetPoint("RIGHT", frame, "BOTTOMRIGHT", -18, 24)
  hint:SetText("Ctrl+C 复制，Esc 取消焦点")
  hint:SetTextColor(0.62, 0.68, 0.72, 1)

  frame:Hide()
  copyPanel = frame
  return frame
end

showCopyPanel = function(text)
  local frame = createCopyPanel()
  frame:Show()
  frame.editBox:SetText(text or recentCopyText(40))
  frame.editBox:HighlightText()
  frame.editBox:SetFocus()
end

local function copyTextFromMouseoverLine(frame)
  local lines = frame and (frame.visibleLines or frame.VisibleLines)
  if type(lines) == "table" then
    for _, line in ipairs(lines) do
      if line and line:IsShown() and MouseIsOver and MouseIsOver(line) and line.GetText then
        local text = stripChatFormatting(line:GetText())
        if text and text ~= "" then
          showCopyPanel(text)
          return true
        end
      end
    end
  end
  return false
end

local chatMouseCopyHooks = {}
installChatMouseCopyHooks = function()
  if not chatAssistantDb().copyLinks then
    return
  end

  local count = NUM_CHAT_WINDOWS or 10
  for index = 1, count do
    local frame = _G["ChatFrame" .. index]
    if frame and not chatMouseCopyHooks[frame] then
      frame:EnableMouse(true)
      frame:HookScript("OnMouseUp", function(self, button)
        if button == "LeftButton" and IsShiftKeyDown and IsShiftKeyDown() and chatAssistantDb().copyLinks then
          if not copyTextFromMouseoverLine(self) then
            showCopyPanel()
          end
        end
      end)
      chatMouseCopyHooks[frame] = true
    end
  end
end

local chatSwitchFrame
local chatSwitchButtons = {
  { label = "说", prefix = "/s ", tooltip = "说话" },
  { label = "队", prefix = "/p ", tooltip = "队伍" },
  { label = "团", prefix = "/raid ", tooltip = "团队" },
  { label = "会", prefix = "/g ", tooltip = "公会" },
  { label = "官", prefix = "/o ", tooltip = "官员" },
  { label = "副", prefix = "/i ", tooltip = "副本" },
  { label = "喊", prefix = "/y ", tooltip = "大喊" },
  { label = "拷", copy = true, tooltip = "打开聊天复制面板" },
}

local function defaultChatSwitchAnchor()
  return "TOPLEFT", ChatFrame1 or DEFAULT_CHAT_FRAME or UIParent, "BOTTOMLEFT", 0, -4
end

local function resetChatSwitchBarPosition()
  chatAssistantDb().barPosition = nil
  if updateChatSwitchBar then
    updateChatSwitchBar()
  end
end

local function setChatSwitchBarCoordinate(axis, value)
  value = tonumber(value)
  if not value then
    return
  end

  local cfg = chatAssistantDb()
  local pos = cfg.barPosition
  if not pos then
    pos = { relativeTo = "CHAT", point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = 0, y = -4 }
    cfg.barPosition = pos
  end
  pos[axis] = math.floor(value + (value >= 0 and 0.5 or -0.5))
  if updateChatSwitchBar then
    updateChatSwitchBar()
  end
  if configUI.refresh then
    configUI.refresh()
  end
end

local function getChatSwitchBarCoordinate(axis)
  local pos = chatAssistantDb().barPosition
  if pos then
    return pos[axis] or 0
  end
  return axis == "x" and 0 or -4
end

local function createChatSwitchBar()
  if chatSwitchFrame then
    return chatSwitchFrame
  end

  local frame = CreateFrame("Frame", "AutyanCoreChatSwitchFrame", UIParent)
  frame:SetSize((#chatSwitchButtons * 30) + 8, 26)
  frame:SetFrameStrata("LOW")
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown and IsShiftKeyDown() then
      self:StartMoving()
    end
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    chatAssistantDb().barPosition = {
      relativeTo = "UI",
      point = point or "CENTER",
      relativePoint = relativePoint or "CENTER",
      x = math.floor((x or 0) + ((x or 0) >= 0 and 0.5 or -0.5)),
      y = math.floor((y or 0) + ((y or 0) >= 0 and 0.5 or -0.5)),
    }
  end)

  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  setSolidTexture(bg, 0.025, 0.028, 0.032, 0.72)

  for index, info in ipairs(chatSwitchButtons) do
    local button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    button:SetSize(28, 20)
    button:SetPoint("LEFT", frame, "LEFT", 4 + ((index - 1) * 30), 0)
    button:SetText(info.label)
    button:SetScript("OnClick", function()
      if info.copy then
        showCopyPanel()
      else
        openChatWithPrefix(info.prefix)
      end
    end)
    button:SetScript("OnEnter", function(self)
      if GameTooltip then
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(info.tooltip .. (info.prefix and (" " .. info.prefix) or ""), 1, 1, 1)
        if info.copy then
          GameTooltip:AddLine("Shift + 点击聊天行：复制该行", 0.62, 0.68, 0.72)
        else
          GameTooltip:AddLine("Shift + 拖动：移动频道按钮条", 0.62, 0.68, 0.72)
        end
        GameTooltip:Show()
      end
    end)
    button:SetScript("OnLeave", function()
      if GameTooltip then
        GameTooltip:Hide()
      end
    end)
  end

  chatSwitchFrame = frame
  return frame
end

updateChatSwitchBar = function()
  local cfg = chatAssistantDb()
  local frame = createChatSwitchBar()
  if cfg.enabled and cfg.fastSwitch and cfg.channelBar then
    frame:ClearAllPoints()
    local pos = cfg.barPosition
    if pos and pos.point then
      local relativeFrame = pos.relativeTo == "CHAT" and (ChatFrame1 or DEFAULT_CHAT_FRAME or UIParent) or UIParent
      frame:SetPoint(pos.point, relativeFrame, pos.relativePoint or pos.point, pos.x or 0, pos.y or 0)
    else
      frame:SetPoint(defaultChatSwitchAnchor())
    end
    frame:Show()
  else
    frame:Hide()
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
  makeConfigCheckbox(frame, "AutyanCoreCfgChatAssistant", "聊天助手", function() return chatAssistantDb().enabled end, function(value) setChatAssistantFlag("enabled", value) end, 28, -242)
  makeConfigCheckbox(frame, "AutyanCoreCfgChatHighlight", "关键词高亮", function() return chatAssistantDb().keywordHighlight end, function(value) setChatAssistantFlag("keywordHighlight", value) end, 28, -274)
  makeConfigCheckbox(frame, "AutyanCoreCfgChatCopy", "聊天复制面板", function() return chatAssistantDb().copyLinks end, function(value) setChatAssistantFlag("copyLinks", value) end, 28, -306)
  makeConfigCheckbox(frame, "AutyanCoreCfgChatBar", "频道切换按钮", function() return chatAssistantDb().channelBar end, function(value) setChatAssistantFlag("channelBar", value) end, 158, -306)
  makeConfigCheckbox(frame, "AutyanCoreCfgTaint", "记录 taint 日志", coreGetter("taintLogEnabled"), function(value) setCoreFlag("taintLogEnabled", value) end, 300, -306)

  local fpsTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  fpsTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 30, -346)
  fpsTitle:SetText("FPS 位置")
  fpsTitle:SetTextColor(0.86, 0.94, 1, 1)
  makeConfigEditBox(frame, "AutyanCoreCfgFPSX", "X", function() return db().fps.x end, function(value) setFPSCoordinate("x", value) end, 30, -374)
  makeConfigEditBox(frame, "AutyanCoreCfgFPSY", "Y", function() return db().fps.y end, function(value) setFPSCoordinate("y", value) end, 158, -374)

  local chatBarTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  chatBarTitle:SetPoint("TOPLEFT", frame, "TOPLEFT", 300, -346)
  chatBarTitle:SetText("频道按钮位置")
  chatBarTitle:SetTextColor(0.86, 0.94, 1, 1)
  makeConfigEditBox(frame, "AutyanCoreCfgChatBarX", "X", function() return getChatSwitchBarCoordinate("x") end, function(value) setChatSwitchBarCoordinate("x", value) end, 300, -374)
  makeConfigEditBox(frame, "AutyanCoreCfgChatBarY", "Y", function() return getChatSwitchBarCoordinate("y") end, function(value) setChatSwitchBarCoordinate("y", value) end, 428, -374)

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
  status:SetSize(230, 18)
  status:SetJustifyH("LEFT")
  configUI.status = status

  local resetChatBar = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  resetChatBar:SetSize(96, 22)
  resetChatBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -208, 12)
  resetChatBar:SetText("重置频道")
  resetChatBar:SetScript("OnClick", function()
    resetChatSwitchBarPosition()
    printMsg("chat channel bar position reset")
    configUI.refresh()
  end)

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
    ensureDefaultChatKeyword()
    installChatAssistantFilters()
    applyChatClassColors()
    extendPlayerNameMenus()
    installSocialClassColorHooks()
    after(0.5, applyFPSPosition)
    after(0.5, updateChatSwitchBar)
    after(1, hookPermanentAuraButtons)
    after(1, updateSocialClassColors)
    after(1, installSocialClassColorHooks)
    after(2, extendPlayerNameMenus)
    after(2, updatePermanentAuraText)
  elseif event == "PLAYER_ENTERING_WORLD" then
    installChatAssistantFilters()
    extendPlayerNameMenus()
    installSocialClassColorHooks()
    after(0.5, applyFPSPosition)
    after(0.5, updateChatSwitchBar)
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
  input = input or ""
  input = input:match("^%s*(.-)%s*$") or ""
  local lowerInput = input:lower()

  if handleChatAssistantCommand(input) then
    return
  end

  if lowerInput == "fps" then
    local cfg = db().fps
    printMsg(("FPS anchor: %s UIParent %s %d %d"):format(cfg.point, cfg.relativePoint, cfg.x, cfg.y))
    return
  end

  if lowerInput == "config" or lowerInput == "options" or input == "设置" then
    toggleConfigFrame()
    return
  end

  local x, y = lowerInput:match("^fps%s+(-?%d+)%s+(-?%d+)$")
  if x and y then
    local cfg = db().fps
    cfg.x = tonumber(x)
    cfg.y = tonumber(y)
    applyFPSPosition()
    printMsg(("FPS anchor updated: %d %d"):format(cfg.x, cfg.y))
    return
  end

  if lowerInput == "buffna on" then
    db().permanentAuraText = true
    updatePermanentAuraText()
    printMsg("permanent buff N/A enabled")
    return
  end

  if lowerInput == "buffna off" then
    db().permanentAuraText = false
    for index = 1, 40 do
      hidePermanentAuraText(_G["BuffButton" .. index])
    end
    hidePermanentAuraContainer(BuffFrame and BuffFrame.AuraContainer)
    hidePermanentAuraContainer(BuffFrame)
    printMsg("permanent buff N/A disabled")
    return
  end

  if lowerInput == "buffna debug" then
    local debugLines = {}
    local scanned, permanent = updatePermanentAuraText(debugLines)
    printMsg(("permanent buff scan: %d visible, %d permanent"):format(scanned or 0, permanent or 0))
    for index = 1, math.min(#debugLines, 8) do
      printMsg(debugLines[index])
    end
    return
  end

  if lowerInput == "taint" then
    printTaintEvents()
    return
  end

  if lowerInput == "taint on" then
    setCoreFlag("taintLogEnabled", true)
    printMsg("taint log enabled")
    return
  end

  if lowerInput == "taint off" then
    setCoreFlag("taintLogEnabled", false)
    printMsg("taint log disabled and cleared")
    return
  end

  if lowerInput == "taint clear" then
    db().taintEvents = {}
    printMsg("taint log cleared")
    return
  end

  if lowerInput == "equip debug" then
    if AutyanCore_EquipmentInfoDebug then
      AutyanCore_EquipmentInfoDebug()
    else
      printMsg("equipment module is not loaded")
    end
    return
  end

  printMsg("commands: /autyan config, /autyan chat, /autyan chat bar reset, /autyan chat add <keyword>, /autyan chat list, /autyan fps, /autyan fps <x> <y>, /autyan buffna on, /autyan buffna off, /autyan buffna debug, /autyan taint, /autyan taint on, /autyan taint off, /autyan taint clear, /autyan equip debug")
end

SlashCmdList.AUTYANCORE = function(input)
  local ok, err = pcall(handleAutyanCommand, input)
  if not ok then
    printMsg("command failed: " .. tostring(err))
  end
end

local function makeFastChatSlash(prefix)
  return function()
    openChatWithPrefix(prefix)
  end
end

SLASH_AUTYANCORE_CHATSAY1 = "/acs"
SlashCmdList.AUTYANCORE_CHATSAY = makeFastChatSlash("/s ")

SLASH_AUTYANCORE_CHATPARTY1 = "/acp"
SlashCmdList.AUTYANCORE_CHATPARTY = makeFastChatSlash("/p ")

SLASH_AUTYANCORE_CHATRAID1 = "/acr"
SlashCmdList.AUTYANCORE_CHATRAID = makeFastChatSlash("/raid ")

SLASH_AUTYANCORE_CHATGUILD1 = "/acg"
SlashCmdList.AUTYANCORE_CHATGUILD = makeFastChatSlash("/g ")

SLASH_AUTYANCORE_CHATINSTANCE1 = "/aci"
SlashCmdList.AUTYANCORE_CHATINSTANCE = makeFastChatSlash("/i ")

SLASH_AUTYANCORE_CHATYELL1 = "/acy"
SlashCmdList.AUTYANCORE_CHATYELL = makeFastChatSlash("/y ")
