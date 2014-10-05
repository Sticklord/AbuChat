local _, ns = ...

-- Forces class colorored chat

function ns.EnableClassColorChat()
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
		ns.EnableClassColorChat()
	end
end)

ns.RegisterEvent("PLAYER_ENTERING_WORLD", ns.EnableClassColorChat)