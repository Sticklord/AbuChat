
local _, ns = ...
local cfg = ns.Config.Chat

local _G = getfenv(0)
-- Storing original scripts
local origOnEnter, origOnLeave, origOnScroll = {}, {}, {} 
local GameTooltip = GameTooltip
local hyperlinkedFrame

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

local function OnHyperlinkEnter(frame, link, ...)
    if InCombatLockdown() then return end

    local linktype = link:match('^([^:]+)')
    if (linktype and linktypes[linktype]) then
        ShowUIPanel(GameTooltip)
        GameTooltip:SetOwner(ChatFrame1, 'ANCHOR_TOPRIGHT', 0, 20)
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
        hyperlinkedFrame = frame
    else
        GameTooltip:Hide()
    end

    if (origOnEnter[frame]) then 
        return origOnEnter[frame](frame, link, ...) 
    end
end

local function OnHyperlinkLeave(frame, ...)
    GameTooltip:Hide()
    hyperlinkedFrame = nil
    if (origOnLeave[frame]) then 
        return origOnLeave[frame](frame, ...) 
    end
end

local function OnScrollChanged(frame)
    if ( hyperlinkedFrame == frame ) then
        HideUIPanel(GameTooltip)
        hyperlinkedFrame = false
    end
end

local function EnableHyperlink()
    for _, v in pairs(CHAT_FRAMES) do
        local chat = _G[v]
        if (chat and not chat.isEnabledHyperlink) then
            origOnEnter[chat] = chat:GetScript('OnHyperlinkEnter')
            chat:SetScript('OnHyperlinkEnter', OnHyperlinkEnter)

            origOnLeave[chat] = chat:GetScript('OnHyperlinkLeave')
            chat:SetScript('OnHyperlinkLeave', OnHyperlinkLeave)

            chat:HookScript('OnMessageScrollChanged', OnScrollChanged)

            chat.isEnabledHyperlink = true
        end
    end
end

ns:RegisterEvent("PLAYER_LOGIN", EnableHyperlink)

