
local ADDON_NAME, ns = ...

local cfg = ns.Config
local ChatFrames = { }
local onInit = { }
ns.onInit = onInit

local   _G, type, select, unpack, gsub, format, match =
		_G, type, select, unpack, gsub, format, match

--_G.CHAT_TAB_SHOW_DELAY = 0.2;   -- 0.2;
--_G.CHAT_TAB_HIDE_DELAY = 1;	    -- 1;

----_G.CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1.0; -- 1.0;
--_G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0; -- 0.4;
--_G.CHAT_FRAME_TAB_ALERTING_MOUSEOVER_ALPHA = 1.0; -- 1.0;
--_G.CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = 1.0; -- 1.0;
--_G.CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA = 0.8; -- 0.6;
--_G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0; -- 0.2;

_G.CHAT_FRAME_FADE_OUT_TIME = 0.25
_G.CHAT_FRAME_FADE_TIME = 0.1

_G.CHAT_FLAG_AFK = '[AFK] '
_G.CHAT_FLAG_DND = '[DND] '
_G.CHAT_FLAG_GM = '[GM] '

_G.CHAT_GUILD_GET = '(|Hchannel:Guild|hG|h) %s:\32'
_G.CHAT_OFFICER_GET = '(|Hchannel:o|hO|h) %s:\32'

_G.CHAT_PARTY_GET = '(|Hchannel:party|hP|h) %s:\32'
_G.CHAT_PARTY_LEADER_GET = '(|Hchannel:party|hPL|h) %s:\32'
_G.CHAT_PARTY_GUIDE_GET = '(|Hchannel:party|hDG|h) %s:\32'
_G.CHAT_MONSTER_PARTY_GET = '(|Hchannel:raid|hR|h) %s:\32'

_G.CHAT_RAID_GET = '(|Hchannel:raid|hR|h) %s:\32'
_G.CHAT_RAID_WARNING_GET = '(RW!) %s:\32'
_G.CHAT_RAID_LEADER_GET = '(|Hchannel:raid|hL|h) %s:\32'

_G.CHAT_BATTLEGROUND_GET = '(|Hchannel:Battleground|hBG|h) %s:\32'
_G.CHAT_BATTLEGROUND_LEADER_GET = '(|Hchannel:Battleground|hBL|h) %s:\32'

_G.CHAT_INSTANCE_CHAT_GET = '|Hchannel:INSTANCE_CHAT|h[I]|h %s:\32';
_G.CHAT_INSTANCE_CHAT_LEADER_GET = '|Hchannel:INSTANCE_CHAT|h[IL]|h %s:\32';

local URL_PATTERNS = {	
	{"(%a+)://(%S+)%s?", "%1://%2"},
	{"www%.([_A-Za-z0-9-]+)%.(%S+)%s?", "www.%1.%2"},
	{"([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", "%1@%2%3%4"},
}

--------------------------------------------------------------------------------------------------
-- 		Chat menu & log buttons

local LogButtons = {
    combatLog = {
        text = 'CombatLog',  colorCode = '|cffFFD100', isNotRadio = true,
        func = function()
            if (not LoggingCombat()) then
                LoggingCombat(true)
                DEFAULT_CHAT_FRAME:AddMessage(COMBATLOGENABLED, 1, 1, 0)
            else
                LoggingCombat(false)
                DEFAULT_CHAT_FRAME:AddMessage(COMBATLOGDISABLED, 1, 1, 0)
            end
        end,
        checked = function()
            return LoggingCombat() and true or false
        end
    },
    chatLog = {
        text = 'ChatLog', colorCode = '|cffFFD100', isNotRadio = true,
        func = function()
            if (not LoggingChat()) then
                LoggingChat(true)
                DEFAULT_CHAT_FRAME:AddMessage(CHATLOGENABLED, 1, 1, 0)
            else
                LoggingChat(false)
                DEFAULT_CHAT_FRAME:AddMessage(CHATLOGDISABLED, 1, 1, 0)
            end
        end,
        checked = function()
            return LoggingChat() and true or false
        end
    }
}

hooksecurefunc('ChatFrameMenu_UpdateAnchorPoint', function()
	if (FCF_GetButtonSide(DEFAULT_CHAT_FRAME) == 'right') then
		ChatMenu:ClearAllPoints()
		ChatMenu:SetPoint('BOTTOMRIGHT', ChatFrame1Tab, 'TOPLEFT')
	else
		ChatMenu:ClearAllPoints()
		ChatMenu:SetPoint('BOTTOMLEFT', ChatFrame1Tab, 'TOPRIGHT')
	end
end)

ChatFrame1Tab:RegisterForClicks('AnyUp')
ChatFrame1Tab:HookScript('OnClick', function(self, button)
	if (button == 'MiddleButton' or button == 'Button4' or button == 'Button5') then
		if (ChatMenu:IsShown()) then
			ChatMenu:Hide()
		else
			ChatMenu:Show()
		end
		HideDropDownMenu(1)
	else
		ChatMenu:Hide()
	end
end)

hooksecurefunc("FCF_Tab_OnClick", function()
	-- Add Combatlog Buttons
	LogButtons.combatLog.arg1 = chatTab
	UIDropDownMenu_AddButton(LogButtons.combatLog)
	-- Add Chatlog Button
	LogButtons.chatLog.arg1 = chatTab
	UIDropDownMenu_AddButton(LogButtons.chatLog)
end)

--------------------------------------------------------------------------------------------------
--      Alt click to invite

local origSetItemRef = SetItemRef
function _G.SetItemRef(link, text, button)
	local linkType = gsub(link, 1, 6)
	if (IsAltKeyDown() and linkType == 'player') then
		local name = match(link, 'player:([^:]+)')
		InviteUnit(name)
		return nil
	end

	return origSetItemRef(link,text,button)
end

--------------------------------------------------------------------------------------------------
--      HYPERLINKS
do
	local HyperLinkedFrame
	local linktypes = {
		item = true, 
		enchant = true, 
		spell = true, 
		quest = true, 
		unit = true, 
		talent = true, 
		achievement = true, 
		glyph = true,
		instancelock = true,
	}

	local orig = _G.ChatFrame_OnHyperlinkShow
	function _G.ChatFrame_OnHyperlinkShow(self, link, text, button)
		local type, value = link:match('(%a+):(.+)')
		if (type == 'url') then
			local editBox = _G[self:GetName()..'EditBox']
			if (editBox) then
				editBox:Show()
				editBox:SetText(value)
				editBox:SetFocus()
				editBox:HighlightText()
			end
		else
			orig(self, link, text, button)
		end
	end

	local function OnHyperlinkEnter(self, link, ...)
	    if InCombatLockdown() then return end

	    local linktype = link:match('^([^:]+)')
	    if (linktype and linktypes[linktype]) then
	        ShowUIPanel(GameTooltip)
	        GameTooltip:SetOwner(ChatFrame1, 'ANCHOR_TOPRIGHT', 0, 20)
	        GameTooltip:SetHyperlink(link)
	        GameTooltip:Show()
	        HyperLinkedFrame = self
	    else
	        GameTooltip:Hide()
	    end

	    if (ChatFrames[self].OnHyperlinkEnter) then 
	        return ChatFrames[self].OnHyperlinkEnter(self, link, ...) 
	    end
	end

	local function OnHyperlinkLeave(self, ...)
	    GameTooltip:Hide()
	    HyperLinkedFrame = nil
	    if (ChatFrames[self].OnHyperlinkLeave) then 
	        return ChatFrames[self].OnHyperlinkLeave(self, ...) 
	    end
	end

	local function OnScrollChanged(self)
	    if ( HyperLinkedFrame == self ) then
	        HideUIPanel(GameTooltip)
	        HyperLinkedFrame = false
	    end
	end

	table.insert(onInit, function(self)
		ChatFrames[self].OnHyperlinkEnter = self:GetScript("OnHyperlinkEnter")
		ChatFrames[self].OnHyperlinkLeave = self:GetScript("OnHyperlinkLeave")

		self:SetScript("OnHyperlinkEnter", OnHyperlinkEnter)
		self:SetScript("OnHyperlinkLeave", OnHyperlinkLeave)
		self:HookScript('OnMessageScrollChanged', OnScrollChanged)
	end)
end

--------------------------------------------------------------------------------------------------
-- 		Hide the menu and friend button

FriendsMicroButton:SetAlpha(0)
FriendsMicroButton:EnableMouse(false)
FriendsMicroButton:UnregisterAllEvents()

ChatFrameMenuButton:SetAlpha(0)
ChatFrameMenuButton:EnableMouse(false)

local IsShiftKeyDown = IsShiftKeyDown
-- Improve mousewheel scrolling
hooksecurefunc('FloatingChatFrame_OnMouseScroll', function(self, direction)
	if (direction > 0) then
		if (IsShiftKeyDown()) then
			self:ScrollToTop()
		else
			self:ScrollUp()
			self:ScrollUp()
		end
	elseif (direction < 0)  then
		if (IsShiftKeyDown()) then
			self:ScrollToBottom()
		else
			self:ScrollDown()
			self:ScrollDown()
		end
	end
end)

--------------------------------------------------------------------------------------------------
-- 			Reposit toast frame

BNToastFrame:HookScript('OnShow', function(self)
	BNToastFrame:ClearAllPoints()
	BNToastFrame:SetPoint('BOTTOMLEFT', ChatFrame1EditBox, 'TOPLEFT', 0, 15)
end)

--------------------------------------------------------------------------------------------------
--      Force Class colors
do
	local function EnableClassColorChat()
		for i = 1, 11 do
			ToggleChatColorNamesByClassGroup(true, "CHANNEL"..i)
			local box = _G["ChatConfigChannelSettingsLeftCheckBox"..i.."ColorClasses"]
			if box then
				box:SetChecked(true)
				box:Disable()
			end
		end
		for i = 1, #CHAT_CONFIG_CHAT_LEFT do
			ToggleChatColorNamesByClassGroup(true, CHAT_CONFIG_CHAT_LEFT[i].type)
			local box = _G["ChatConfigChatSettingsLeftCheckBox"..i.."ColorClasses"]
			if box then
				box:SetChecked(true)
				box:Disable()
			end
		end
	end

	hooksecurefunc("ChatConfig_UpdateCheckboxes", function(frame)
		if frame == ChatConfigChatSettingsLeft or frame == ChatConfigChannelSettingsLeft then
			EnableClassColorChat()
		end
	end)
	_G.AbuGlobal.EnableClassColorChat = EnableClassColorChat
end

--------------------------------------------------------------------------------------------------
--      Format Messages
do
	local function colorURL(url)
		return '|cff0099FF|Hurl:'..url..'|h'..url..'|h|r'
	end

	local function AddMessage(self, msg, ...)
		if (type(msg) == 'string') then	
			-- url highlight
			local found, index = 0, 1
			while ((found == 0) and (index <= #URL_PATTERNS)) do
				local pattern = URL_PATTERNS[index]
				msg, found = msg:gsub(pattern[1], colorURL(pattern[2]))
				index = index + 1
			end

			msg = msg:gsub('(|HBNplayer.-|h)%[(.-)%]|h', '%1%2|h')
						:gsub('(|Hplayer.-|h)%[(.-)%]|h', '%1%2|h')
						:gsub('%[(%d0?)%. (.-)%]', '(%1)')
		end
		return ChatFrames[self].AddMessage(self, msg, ...)
	end

	table.insert(onInit, function(self)
		if (self ~= COMBATLOG) then
			ChatFrames[self].AddMessage = self.AddMessage
			self.AddMessage = AddMessage
		end
	end)
end

--------------------------------------------------------------------------------------------------
--      Updating tabs

local SELECTED, FLASHING = 0, 1

local function UpdateTab(self, style)
	if true then return end
	local color
	if (style == SELECTED) then
		color = cfg.tab.selectedColor
	elseif (style == FLASHING) then
		color = cfg.tab.flashColor
	else
		color = cfg.tab.normalColor
	end

	local fontstring = _G[self:GetName().."Text"]
	fontstring:SetFont('Fonts\\ARIALN.ttf', 12, 'OUTLINE')
	fontstring:SetTextColor(color[1], color[2], color[3])
end

local function UpdateTabs()
	if true then return end
	for i = 1, #CHAT_FRAMES do
		local chat = _G[CHAT_FRAMES[i]]
		local tab = _G[CHAT_FRAMES[i].."Tab"]
		-- Update Tab Appearance
		if chat == SELECTED_CHAT_FRAME then
			UpdateTab(tab, SELECTED)
		elseif tab.alerting then
			UpdateTab(tab, FLASHING)
		else
			UpdateTab(tab)
		end
	end
end

--_G.FCFTab_UpdateColors = function() end

--------------------------------------------------------------------------------------------------
--      Mod each chat window

local function SetChatFont(self, size, flags)
	self:SetFont(cfg.chatfont, size, cfg.chatOutline and 'THINOUTLINE')
end

local function StyleChatFrame(self)
	if ChatFrames[self] then return; end
	ChatFrames[self] = { }

	local name = self:GetName()

	if (not cfg.chatOutline) then
		self:SetShadowOffset(1, -1)
	end

	if (cfg.disableFade) then
		self:SetFading(false)
	end

	local _, fontsize = self:GetFont()
	SetChatFont(self, fontsize)
	self:SetClampedToScreen(false)

	self:SetClampRectInsets(0, 0, 0, 0)
	self:SetMaxResize(UIParent:GetWidth(), UIParent:GetHeight())
	self:SetMinResize(150, 25)

	local buttonUp = _G[name..'ButtonFrameUpButton']
	buttonUp:SetAlpha(0)
	buttonUp:EnableMouse(false)

	local buttonDown = _G[name..'ButtonFrameDownButton']
	buttonDown:SetAlpha(0)
	buttonDown:EnableMouse(false)

	local buttonBottom = _G[name..'ButtonFrameBottomButton']
	buttonBottom:SetAlpha(0)
	buttonBottom:EnableMouse(false)

	for _, texture in pairs({
		'Background',
		'TopLeftTexture',
		'BottomLeftTexture',
		'TopRightTexture',
		'BottomRightTexture',
		'LeftTexture',
		'RightTexture',
		'BottomTexture',
		'TopTexture',
	}) do
		_G[name.."ButtonFrame"..texture]:SetTexture(nil)
	end

	local convButton = _G[name..'ConversationButton']
	if (convButton) then
		convButton:SetAlpha(0)
		convButton:EnableMouse(false)
	end

	local chatMinimize = _G[name..'ButtonFrameMinimizeButton']
	if (chatMinimize) then
		chatMinimize:SetAlpha(0)
		chatMinimize:EnableMouse(false)
	end

-- EDITBOXES
	local editbox = _G[name.."EditBox"]
	for k = 6, 11 do
		select(k, editbox:GetRegions()):SetTexture(nil)
	end

	editbox:SetAltArrowKeyMode(false)
	editbox:ClearAllPoints()
	editbox:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 2, 33)
	editbox:SetPoint('BOTTOMRIGHT', self, 'TOPRIGHT', 0, 33)
		
	editbox:SetBackdrop({
		bgFile = 'Interface\\Buttons\\WHITE8x8',
		insets = {
			left = 3, right = 3, top = 2, bottom = 2
		},
	})
	editbox:SetBackdropColor(0, 0, 0, 0.5)

	AbuGlobal.CreateBorder(editbox, 11)
	editbox:SetBorderPadding(-1, -1, -2, -2)

	editbox:HookScript('OnTextChanged', function(self)
		local text = self:GetText()
		if (UnitExists('target') and UnitIsPlayer('target') and UnitIsFriend('player', 'target')) then
			if (text:len() < 5) then
				if (text:sub(1, 4) == '/tt ') then
					local unitname, realm = UnitName('target')
				
					if (unitname) then 
					    unitname = gsub(unitname, ' ', '') 
					end
				
					if (unitname and not UnitIsSameServer('player', 'target')) then
					    unitname = unitname..'-'..gsub(realm, ' ', '')
					end
				
					ChatFrame_SendTell((unitname or 'Invalid target'), ChatFrame1)
				end
			end
		end
	end)

	if (cfg.enableBorderColoring) then
		editbox:SetBorderTextureFile('white')

		hooksecurefunc('ChatEdit_UpdateHeader', function(self)
			local type = self:GetAttribute('chatType')
			if (not type) then
				return
			end

			local info = ChatTypeInfo[type]
			editbox:SetBorderColor(info.r, info.g, info.b)
		end)
	end

-- TABS
	local tab = _G[name.."Tab"]
	for _, tex in pairs({'','Highlight','Selected'}) do
		_G[name.."Tab"..tex.."Left"]:SetTexture(nil)
		_G[name.."Tab"..tex.."Middle"]:SetTexture(nil)
		_G[name.."Tab"..tex.."Right"]:SetTexture(nil)
	end

	if tab.conversationIcon then
		tab.conversationIcon.Show = function(...) end
		tab.conversationIcon:Hide()
	end

	tab.text = _G[name.."Tab".."Text"]
	tab.text:SetFont(cfg.chatfont, 12, 'OUTLINE')
	tab.text:SetJustifyH("CENTER")
	tab.text.GetWidth = tab.text.GetStringWidth

	tab:SetScript("OnEnter", function(self)
		UpdateTab(self, SELECTED)
	end)
	tab:SetScript("OnLeave", UpdateTabs)
	tab:HookScript("OnClick", UpdateTabs)

	hooksecurefunc(tab, "SetAlpha", function(self, a)
		if (a < 0.6) then
			self:SetAlpha(0.6)
		end
	end)

	for i = 1, #onInit do
		onInit[i](self)
	end
end

--------------------------------------------------------------------------------------------------
--      The core

local AbuChat = CreateFrame("Frame")
AbuChat:RegisterEvent("ADDON_LOADED")
AbuChat:RegisterEvent("CHAT_MSG_WHISPER")
AbuChat:RegisterEvent("CHAT_MSG_BN_WHISPER")

local Num_Seen_Chatframes = 1

AbuChat:SetScript("OnEvent", function(self, event, ...)
	if (event == "ADDON_LOADED") then

		local addon = ...
		if (addon == ADDON_NAME) then

			for k,v in pairs(CHAT_FRAMES) do
				local chat = _G[v]
				StyleChatFrame(chat)
			end

			UpdateTabs()

		elseif (addon == 'Blizzard_GMChatUI') then
			GMChatFrame:EnableMouseWheel(true)
			GMChatFrame:SetScript('OnMouseWheel', ChatFrame1:GetScript('OnMouseWheel'))
			GMChatFrame:SetHeight(200)

			GMChatFrameUpButton:SetAlpha(0)
			GMChatFrameUpButton:EnableMouse(false)

			GMChatFrameDownButton:SetAlpha(0)
			GMChatFrameDownButton:EnableMouse(false)

			GMChatFrameBottomButton:SetAlpha(0)
			GMChatFrameBottomButton:EnableMouse(false)
		end

	elseif (event == "CHAT_MSG_WHISPER") or (event == "CHAT_MSG_BN_WHISPER") then
		PlaySoundFile('Sound\\Spells\\Simongame_visual_gametick.wav')
	end
end)

-- hooks
hooksecurefunc("FCF_OpenTemporaryWindow", function()

	local chat = FCF_GetCurrentChatFrame()
	if _G[chat:GetName().."Tab"]:GetText():match(PET_BATTLE_COMBAT_LOG) then
		FCF_Close(chat)
		return
	end

	for k,v in pairs(CHAT_FRAMES) do
		local chat = _G[v]
		StyleChatFrame(chat)
	end

	UpdateTabs()
end)

hooksecurefunc("FCF_SetChatWindowFontSize", function(self, chatframe, size)
	if (not chatFrame) then
		chatframe = FCF_GetCurrentChatFrame()
	end
	SetChatFont(chatframe, size or self.value)
end)

hooksecurefunc("FCF_OpenNewWindow", UpdateTabs)

hooksecurefunc("FCF_Close", function(self, fallback)
	_G[(fallback or self or FCF_GetCurrentChatFrame()):GetName().."Tab"]:Hide()
	FCF_Tab_OnClick(_G["ChatFrame1Tab"], "LeftButton")
end)

hooksecurefunc("FCF_StartAlertFlash", function(self)
	local tab = _G[self:GetName().."Tab"]
	UpdateTab(tab, FLASHING)
	--UIFrameFlashStop(tab.glow)
end)

hooksecurefunc("FCF_StopAlertFlash", function(self)
	local tab = _G[self:GetName().."Tab"]
	UpdateTab(tab)
end)