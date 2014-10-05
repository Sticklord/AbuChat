local _, ns = ...

local playerName
local cache = { }

local REPEAT_EVENTS = {
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_TEXT_EMOTE",
}

local frames = {
	['ChatFrame1'] = true,
	['ChatFrame3'] = true,
}

local function HideRepeats(frame, event, message, sender, ...)
	if (sender and sender:match("%w+") ~= playerName) and (type(message) == "string")
	and ( frame == ChatFrame3 or (frame == ChatFrame1 and event == "CHAT_MSG_YELL")) then
		local t = cache
		local v = ("%s:%s"):format(sender, message:gsub("%s", ""):lower())

		if t[v] == true then
			return true
		end

		if #t == 20 then
			local r = tremove(t, 1)
			t[r] = nil
		end

		tinsert(t, v)
		t[v] = true
	end
	return false, message, sender, ...
end

local function EnableHideRepeats()
	playerName = UnitName("player")
	for _, event in ipairs(REPEAT_EVENTS) do
		ChatFrame_AddMessageEventFilter(event, HideRepeats)
	end
end

ns.RegisterEvent("PLAYER_LOGIN", EnableHideRepeats)