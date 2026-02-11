-- Hauptfenster erstellen
local frame = CreateFrame("Frame", "WTSMasterFrame", UIParent, "BasicFrameTemplateWithInset")
frame:SetSize(400, 340)
frame:SetPoint("CENTER") -- Standardposition
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

-- FUNKTION ZUM SPEICHERN DER POSITION
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    -- Speichere die Position in der Charakter-Config
    if not WTSMaster_Config then WTSMaster_Config = {} end
    WTSMaster_Config.pos = { p = point, rp = relativePoint, x = xOfs, y = yOfs }
end)
frame:SetScript("OnDragStart", frame.StartMoving)
frame:Hide() -- Standardmäßig beim Start ausgeblendet

frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFontObject("GameFontHighlight")
frame.title:SetPoint("LEFT", frame.TitleBg, "LEFT", 5, 0)
frame.title:SetText("WTSMaster - TBC - by derFlanders")

-- GLOBALE VARIABLEN
local selectedChannel = 2
local isDualMode = false
local sections = {
    [1] = { itemID = nil, itemLink = nil, mode = 1 },
    [2] = { itemID = nil, itemLink = nil, mode = 1 }
}

-- --- EVENT: LADEN DER GESPEICHERTEN POSITION ---
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "WTSMaster" then
        -- Falls Config existiert, Position setzen
        if WTSMaster_Config and WTSMaster_Config.pos then
            local pos = WTSMaster_Config.pos
            frame:ClearAllPoints()
            frame:SetPoint(pos.p, UIParent, pos.rp, pos.x, pos.y)
        end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

-- --- FUNKTION: RESET NACH POSTEN ---
local function ResetSection(id)
    sections[id].itemID = nil
    sections[id].itemLink = nil
    _G["WTSM_Slot"..id.."Icon"]:SetTexture(nil)
    _G["WTSM_ItemNameText"..id]:SetText("")
    _G["WTSM_Sec"..id.."_G"]:SetText("")
    _G["WTSM_Sec"..id.."_S"]:SetText("")
    _G["WTSM_Sec"..id.."_C"]:SetText("")
end

-- --- FUNKTION: MODUS WECHSELN ---
local function SetDisplayMode(dual)
    isDualMode = dual
    if dual then
        frame:SetHeight(560)
        WTSM_Line:Show()
        WTSM_Sec2_Group:Show()
        WTSM_BottomGroup:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -475)
        WTSM_ModeBtnSingle:GetFontString():SetTextColor(1, 1, 1)
        WTSM_ModeBtnDual:GetFontString():SetTextColor(1, 1, 0)
    else
        frame:SetHeight(340)
        WTSM_Line:Hide()
        WTSM_Sec2_Group:Hide()
        WTSM_BottomGroup:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -255)
        WTSM_ModeBtnSingle:GetFontString():SetTextColor(1, 1, 0)
        WTSM_ModeBtnDual:GetFontString():SetTextColor(1, 1, 1)
    end
end

-- --- HILFSFUNKTIONEN ---
local function SetTradingItem(secID, id, link)
    if not id or not link then return end
    sections[secID].itemID = id
    sections[secID].itemLink = link
    local name, _, quality = GetItemInfo(link)
    _G["WTSM_Slot"..secID.."Icon"]:SetTexture(GetItemIcon(id))
    local r, g, b = GetItemQualityColor(quality)
    _G["WTSM_ItemNameText"..secID]:SetText(name)
    _G["WTSM_ItemNameText"..secID]:SetTextColor(r, g, b)
end

hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", function(self, button)
    if frame:IsShown() and button == "RightButton" then
        local bag, slot = self:GetParent():GetID(), self:GetID()
        local link = (C_Container and C_Container.GetContainerItemLink(bag, slot)) or GetContainerItemLink(bag, slot)
        if link then
            local id = (C_Container and C_Container.GetContainerItemID(bag, slot)) or GetContainerItemID(bag, slot)
            local targetSec = (not isDualMode or not sections[1].itemID) and 1 or 2
            SetTradingItem(targetSec, id, link)
        end
    end
end)

-- --- MODUS BUTTONS ---
local modeBtnSingle = CreateFrame("Button", "WTSM_ModeBtnSingle", frame, "UIPanelButtonTemplate")
modeBtnSingle:SetSize(80, 22); modeBtnSingle:SetPoint("TOPLEFT", 15, -30); modeBtnSingle:SetText("Single")
modeBtnSingle:SetScript("OnClick", function() SetDisplayMode(false) end)

local modeBtnDual = CreateFrame("Button", "WTSM_ModeBtnDual", frame, "UIPanelButtonTemplate")
modeBtnDual:SetSize(80, 22); modeBtnDual:SetPoint("LEFT", modeBtnSingle, "RIGHT", 5, 0); modeBtnDual:SetText("Dual")
modeBtnDual:SetScript("OnClick", function() SetDisplayMode(true) end)

-- --- SEKTIONEN ---
local function CreateSection(id, yPos)
    local group = CreateFrame("Frame", "WTSM_Sec"..id.."_Group", frame)
    group:SetSize(400, 200); group:SetPoint("TOPLEFT", 0, yPos)

    local function CreateRB(mID, txt, ry, rtIcon)
        local rb = CreateFrame("CheckButton", "WTSM_Sec"..id.."_RB"..mID, group, "UIRadioButtonTemplate")
        rb:SetPoint("TOPLEFT", 20, ry)
        local label = _G[rb:GetName().."Text"]
        label:SetText(txt)
        
        if rtIcon then
            local icon = group:CreateTexture(nil, "OVERLAY")
            icon:SetSize(12, 12)
            icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_"..rtIcon)
            icon:SetPoint("LEFT", label, "RIGHT", 4, 0)
        end

        rb:SetScript("OnClick", function()
            sections[id].mode = mID
            for i=1, 3 do _G["WTSM_Sec"..id.."_RB"..i]:SetChecked(false) end
            rb:SetChecked(true)
        end)
        if mID == 1 then rb:SetChecked(true) end
    end
    
    CreateRB(1, "WTS [Item] (Price), Please whisper!", -10, 1)
    CreateRB(2, "WTS [Item] (Price), /w me!", -30, 2)
    CreateRB(3, "Own (Textfield)", -50, nil)

    local slot = CreateFrame("Button", "WTSM_Slot"..id, group, "ActionButtonTemplate")
    slot:SetPoint("TOPRIGHT", -40, -15); slot:SetSize(40, 40)
    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    slot:SetScript("OnReceiveDrag", function()
        local infoType, itemID, itemLink = GetCursorInfo()
        if infoType == "item" then SetTradingItem(id, itemID, itemLink); ClearCursor() end
    end)
    
    slot:SetScript("OnClick", function(self, btn)
        local infoType, itemID, itemLink = GetCursorInfo()
        if infoType == "item" then SetTradingItem(id, itemID, itemLink); ClearCursor()
        else ResetSection(id) end
    end)

    local nameText = group:CreateFontString("WTSM_ItemNameText"..id, "OVERLAY", "GameFontNormalSmall")
    nameText:SetPoint("TOP", slot, "BOTTOM", 0, -2); nameText:SetWidth(120); nameText:SetJustifyH("CENTER")

    local function CreatePrice(n, icon, x)
        local eb = CreateFrame("EditBox", "WTSM_Sec"..id.."_"..n, group, "InputBoxTemplate")
        eb:SetSize(30, 20); eb:SetPoint("TOPLEFT", x, -80); eb:SetAutoFocus(false); eb:SetNumeric(true)
        local tex = group:CreateTexture(nil, "OVERLAY")
        tex:SetSize(14, 14); tex:SetTexture(icon); tex:SetPoint("LEFT", eb, "RIGHT", 2, 0)
    end
    CreatePrice("G", "Interface\\MoneyFrame\\UI-GoldIcon", 30)
    CreatePrice("S", "Interface\\MoneyFrame\\UI-SilverIcon", 90)
    CreatePrice("C", "Interface\\MoneyFrame\\UI-CopperIcon", 150)

    local bg = CreateFrame("Frame", "WTSM_Sec"..id.."_BG", group, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", 20, -110); bg:SetSize(345, 35)
    bg:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=12, insets={left=3,right=3,top=3,bottom=3}})
    bg:SetBackdropColor(0,0,0,0.5)
    local eb = CreateFrame("EditBox", "WTSM_Sec"..id.."_Text", bg)
    eb:SetMultiLine(true); eb:SetSize(335, 25); eb:SetPoint("TOPLEFT", 5, -5); eb:SetFontObject("ChatFontNormal"); eb:SetAutoFocus(false); eb:SetText("Here you can write your own text!")

    for i=1, 8 do
        local btn = CreateFrame("Button", nil, group)
        btn:SetSize(18, 18); btn:SetPoint("TOPLEFT", bg, "BOTTOMLEFT", (i-1)*22, -2)
        local tex = btn:CreateTexture(nil, "ARTWORK"); tex:SetAllPoints(); tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_"..i)
        btn:SetScript("OnClick", function() eb:Insert("{rt"..i.."}"); eb:SetFocus() end)
    end
end

CreateSection(1, -60)
local line = frame:CreateTexture("WTSM_Line", "ARTWORK")
line:SetHeight(2); line:SetPoint("TOPLEFT", 10, -250); line:SetPoint("TOPRIGHT", -10, -250)
line:SetColorTexture(0.5, 0.5, 0.5, 0.3)
CreateSection(2, -270)

-- --- KANAL & SENDEN ---
local bottomGroup = CreateFrame("Frame", "WTSM_BottomGroup", frame)
bottomGroup:SetSize(400, 80)
local chanLabel = bottomGroup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
chanLabel:SetPoint("TOPLEFT", 25, -5); chanLabel:SetText("Channel:")

local function UpdateChannelButtons(silent)
    for i=1, 2 do
        local btn = _G["WTSM_ChanBtn"..i]
        if selectedChannel == i then 
            btn:GetFontString():SetTextColor(1, 1, 0) 
            if not silent then print("|cffffffffWTSMaster:|r |cff00ff00Channel switch to "..i.."|r") end
        else btn:GetFontString():SetTextColor(1, 1, 1) end
    end
end

for i=1, 2 do
    local btn = CreateFrame("Button", "WTSM_ChanBtn"..i, bottomGroup, "UIPanelButtonTemplate")
    btn:SetSize(30, 20); btn:SetPoint("LEFT", chanLabel, "RIGHT", (i-1)*35 + 5, 0); btn:SetText(i)
    btn:SetScript("OnClick", function() selectedChannel = i; UpdateChannelButtons(false) end)
end

local postBtn = CreateFrame("Button", "WTSM_PostButton", bottomGroup, "UIPanelButtonTemplate")
postBtn:SetSize(160, 25); postBtn:SetPoint("TOP", bottomGroup, "TOP", 0, -35); postBtn:SetText("Post")
postBtn:SetScript("OnClick", function()
    local it = isDualMode and 2 or 1
    local hasPosted = false
    for i=1, it do
        local d = sections[i]
        if d.itemLink then
            local g, s, c = _G["WTSM_Sec"..i.."_G"]:GetText(), _G["WTSM_Sec"..i.."_S"]:GetText(), _G["WTSM_Sec"..i.."_C"]:GetText()
            local p = (g~="" or s~="" or c~="") and (" ("..(g~="" and g.."g " or "")..(s~="" and s.."s " or "")..(c~="" and c.."c" or "")..")") or ""
            local msg = (d.mode == 1 and "WTS "..d.itemLink..p..", Please whisper! {rt1}") or (d.mode == 2 and "WTS "..d.itemLink..p..", /w me! {rt2}") or (d.itemLink..p.." ".._G["WTSM_Sec"..i.."_Text"]:GetText())
            SendChatMessage(msg, "CHANNEL", nil, selectedChannel)
            ResetSection(i)
            hasPosted = true
        end
    end
    if not hasPosted then print("|cffffffffWTSMaster:|r |cff00ff00No Item in Slot!|r") end
end)

-- Initialisierung beim Laden
SetDisplayMode(false)
UpdateChannelButtons(true)

-- Slash Command Definition
SLASH_WTSMASTER1 = "/wtsm"
SlashCmdList["WTSMASTER"] = function() 
    if frame:IsShown() then frame:Hide() else frame:Show() end 
end

-- Lade-Nachricht im Chat (Weiß & Grün)
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_LOGIN")
loadFrame:SetScript("OnEvent", function()
	C_Timer.After(2, function()
        print("|cffffffffWTSMaster:|r |cff00ff00Enabled|r")
        print("|cffffffffWTSMaster:|r |cff00ff00/wtsm|r")
	end)
end)