
local _, ns = ...
setmetatable(ns, { __index = ABUADDONS })
local cfg = ns.Config.Chat

local _G = _G
local type = type
local select = select
local unpack = unpack

local gsub = string.gsub
local format = string.format

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

local AddMessage = ChatFrame1.AddMessage
local function FCF_AddMessage(self, text, ...)
    if (type(text) == 'string') then
        text = gsub(text, '(|HBNplayer.-|h)%[(.-)%]|h', '%1%2|h')
        text = gsub(text, '(|Hplayer.-|h)%[(.-)%]|h', '%1%2|h')
        text = gsub(text, '%[(%d0?)%. (.-)%]', '(%1)')
    end

    return AddMessage(self, text, ...)
end

-- Hide the menu and friend button
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

-- Reposit toast frame
BNToastFrame:HookScript('OnShow', function(self)
    BNToastFrame:ClearAllPoints()
    BNToastFrame:SetPoint('BOTTOMLEFT', ChatFrame1EditBox, 'TOPLEFT', 0, 15)
end)

local function ModChat(self)
    local chat = _G[self]

    if (not cfg.chatOutline) then
        chat:SetShadowOffset(1, -1)
    end

    if (cfg.disableFade) then
        chat:SetFading(false)
    end

    local font, fontsize, fontflags = chat:GetFont()
    chat:SetFont(font, fontsize, cfg.chatOutline and 'THINOUTLINE' or fontflags)
    chat:SetClampedToScreen(false)

    chat:SetClampRectInsets(0, 0, 0, 0)
    chat:SetMaxResize(UIParent:GetWidth(), UIParent:GetHeight())
    chat:SetMinResize(150, 25)

    if (self ~= 'ChatFrame2') then
        chat.AddMessage = FCF_AddMessage
    end

    local buttonUp = _G[self..'ButtonFrameUpButton']
    buttonUp:SetAlpha(0)
    buttonUp:EnableMouse(false)

    local buttonDown = _G[self..'ButtonFrameDownButton']
    buttonDown:SetAlpha(0)
    buttonDown:EnableMouse(false)

    local buttonBottom = _G[self..'ButtonFrameBottomButton']
    buttonBottom:SetAlpha(0)
    buttonBottom:EnableMouse(false)

    for _, texture in pairs({
        'ButtonFrameBackground',
        'ButtonFrameTopLeftTexture',
        'ButtonFrameBottomLeftTexture',
        'ButtonFrameTopRightTexture',
        'ButtonFrameBottomRightTexture',
        'ButtonFrameLeftTexture',
        'ButtonFrameRightTexture',
        'ButtonFrameBottomTexture',
        'ButtonFrameTopTexture',
    }) do
        _G[self..texture]:SetTexture(nil)
    end

        -- Modify the editbox
    local editbox = _G[self.."EditBox"]
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
    ns.CreateBorder(editbox, 11)
    editbox:SetBorderPadding(-1, -1, -2, -2)

    if (cfg.enableBorderColoring) then
        editbox:SetBorderTextureFile('white')

        hooksecurefunc('ChatEdit_UpdateHeader', function(editBox)
            local type = editBox:GetAttribute('chatType')
            if (not type) then
                return
            end

            local info = ChatTypeInfo[type]
            editbox:SetBorderColor(info.r, info.g, info.b)
        end)
    end
end

local function SetChatStyle()
    for _, v in pairs(CHAT_FRAMES) do
        local chat = _G[v]
        if (chat and not chat.hasModification) then
            ModChat(chat:GetName())

            local convButton = _G[chat:GetName()..'ConversationButton']
            if (convButton) then
                convButton:SetAlpha(0)
                convButton:EnableMouse(false)
            end

            local chatMinimize = _G[chat:GetName()..'ButtonFrameMinimizeButton']
            if (chatMinimize) then
                chatMinimize:SetAlpha(0)
                chatMinimize:EnableMouse(0)
            end

            chat.hasModification = true
        end
    end
end
hooksecurefunc('FCF_OpenTemporaryWindow', SetChatStyle)
SetChatStyle()

-- Chat menu, just a middle click on the chatframe 1 tab
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

-- Modify the GM Chat
local function ModGMChat(_, event, ...)
    if (... == 'Blizzard_GMChatUI') then
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
end
ns.RegisterEvent("ADDON_LOADED", ModGMChat)

-- Add a sound notification on incoming whispers
local function Pling()
    PlaySoundFile('Sound\\Spells\\Simongame_visual_gametick.wav')
end
ns.RegisterEvent("CHAT_MSG_WHISPER", Pling)
ns.RegisterEvent("CHAT_MSG_BN_WHISPER", Pling)