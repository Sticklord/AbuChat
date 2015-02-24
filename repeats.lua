local _, ns = ...

local playerName = UnitName("player")
local cache = { }

local REPEAT_EVENTS = {
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_EMOTE",
	"CHAT_MSG_TEXT_EMOTE",
}

local function HideRepeats(frame, event, message, sender, ...)
	if (sender and sender ~= playerName) and (type(message) == "string" and frame == ChatFrame3) then
		local v = ("%s:%s"):format(sender, message:gsub("%s", ""):lower())

		if cache[v] then
			return true
		end

		if #cache == 20 then
			cache[tremove(cache, 1)] = nil
		end

		tinsert(cache, v)
		cache[v] = true
	end
	return false, message, sender, ...
end

for _, event in ipairs(REPEAT_EVENTS) do
	ChatFrame_AddMessageEventFilter(event, HideRepeats)
end

