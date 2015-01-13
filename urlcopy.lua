
local _, ns = ...

-- Highlights URL

local find = string.find
local gsub = string.gsub

local PATTERNS = {	
	{"(%a+)://(%S+)%s?", "%1://%2"},
	{"www%.([_A-Za-z0-9-]+)%.(%S+)%s?", "www.%1.%2"},
	{"([_A-Za-z0-9-%.]+)@([_A-Za-z0-9-]+)(%.+)([_A-Za-z0-9-%.]+)%s?", "%1@%2%3%4"},
}

local function colorURL(url)
	return '|cff0099FF|Hurl:'..url..'|h'..url..'|h|r'
end

local function ScanURL(frame, text, ...)
	local found, index = 0, 1

	while ((found == 0) and (index <= #PATTERNS)) do
		local p = PATTERNS[index]
		index = index + 1
		text, found = text:gsub(p[1], colorURL(p[2]))
	end

	frame.add(frame, text,...)
end

local function EnableURLCopy()
	for _, v in pairs(CHAT_FRAMES) do
		local chat = _G[v]
		if (chat and not chat.hasURLCopy and (chat ~= 'ChatFrame2')) then
			chat.add = chat.AddMessage
			chat.AddMessage = ScanURL
			chat.hasURLCopy = true
		end
	end
end
hooksecurefunc('FCF_OpenTemporaryWindow', EnableURLCopy)

local orig = _G.ChatFrame_OnHyperlinkShow
function _G.ChatFrame_OnHyperlinkShow(frame, link, text, button)
	local type, value = link:match('(%a+):(.+)')
	if (type == 'url') then
		local editBox = _G[frame:GetName()..'EditBox']
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

ns:RegisterEvent("PLAYER_LOGIN", EnableURLCopy)