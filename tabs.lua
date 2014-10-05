
local _, ns = ...
local cfg = ns.Config.Chat
								--DEFAULT
_G.CHAT_TAB_SHOW_DELAY = 0.2;   -- 0.2;
_G.CHAT_TAB_HIDE_DELAY = 1;	    -- 1;

_G.CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1.0; -- 1.0;
_G.CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0; -- 0.4;
_G.CHAT_FRAME_TAB_ALERTING_MOUSEOVER_ALPHA = 1.0; -- 1.0;
_G.CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = 1.0; -- 1.0;
_G.CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA = 0.5; -- 0.6;
_G.CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0; -- 0.2;

--	[[	Chat Log Buttons  ]]  --
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

--	[[	Update Tab Text  ]]  --
local function UpdateTabStyle(self, style)
	local fontstring = _G[self:GetName().."Text"]
	fontstring:SetFont('Fonts\\ARIALN.ttf', 12, 'OUTLINE')

	-- Color
	local color = {
		['selected'] = cfg.tab.selectedColor,
		['normal']	 = cfg.tab.normalColor,
		['flash']	 = cfg.tab.flashColor,
	}
	fontstring:SetTextColor(unpack(color[style]))
end

--	[[	Update The Tabs  ]]  --
local function UpdateTabs()
	local chat, tab

	local function Murder(object)
		object.Show = function(...) end
		object:Hide()
	end

	for _, chatName in pairs(CHAT_FRAMES) do
		chat = _G[chatName]
		tab = _G[chatName.."Tab"]

		-- Update Tab Appearance
		if chat == SELECTED_CHAT_FRAME then
			UpdateTabStyle(tab, "selected")
		elseif tab.alerting then
			UpdateTabStyle(tab, "flash")
		else
			UpdateTabStyle(tab, "normal")
		end

		-- Skinning
		if not tab.isFucked and tab then
			-- Hide Textures
			for _, tex in pairs({'','Highlight','Selected'}) do
				_G[tab:GetName()..tex.."Left"]:SetTexture(nil)
				_G[tab:GetName()..tex.."Middle"]:SetTexture(nil)
				_G[tab:GetName()..tex.."Right"]:SetTexture(nil)
			end

			if tab.conversationIcon then
				Murder(tab.conversationIcon)
			end

			-- Hook Tab
			tab:SetScript("OnEnter", function(self)
				UpdateTabStyle(self, "selected")
			end)
			tab:SetScript("OnLeave", UpdateTabs)
			tab.isFucked = true
		end
	end
end

local function SetupHooks()
	local origFCF_Tab_OnClick = FCF_Tab_OnClick
	_G.FCF_Tab_OnClick = function(...)
	    origFCF_Tab_OnClick(...)
	    -- Add Combatlog Buttons
	    LogButtons.combatLog.arg1 = chatTab
	    UIDropDownMenu_AddButton(LogButtons.combatLog)
	    -- Add Chatlog Button
	    LogButtons.chatLog.arg1 = chatTab
	    UIDropDownMenu_AddButton(LogButtons.chatLog)
	    UpdateTabs()
	end

	-- New Window
	hooksecurefunc("FCF_OpenNewWindow", function()
		UpdateTabs()
	end)

	-- New Temp Window
	hooksecurefunc("FCF_OpenTemporaryWindow", function()
		local chat = FCF_GetCurrentChatFrame()
		if _G[chat:GetName().."Tab"]:GetText():match(PET_BATTLE_COMBAT_LOG) then
			FCF_Close(chat)
			return
		end
		UpdateTabs()
	end)
	
	-- Window Close
	hooksecurefunc("FCF_Close", function(self, fallback)
		local frame = fallback or self
		UIParent.Hide(_G[frame:GetName().."Tab"])
		FCF_Tab_OnClick(_G["ChatFrame1Tab"], "LeftButton")
	end)
	
	-- Flash
	hooksecurefunc("FCF_StartAlertFlash", function(chatFrame)
		local tab = _G[chatFrame:GetName().."Tab"]
		UpdateTabStyle(tab, "flash")
		UIFrameFlashStop(tab.glow)
	end)
	hooksecurefunc("FCF_StopAlertFlash", function(chatFrame)
		local tab = _G[chatFrame:GetName().."Tab"]
		UpdateTabStyle(tab, "normal")
	end)
	
	-- noop
	_G.FCFTab_UpdateColors = function() end
	-- Update the tabs
	UpdateTabs()
end

ns.RegisterEvent("PLAYER_LOGIN", SetupHooks)