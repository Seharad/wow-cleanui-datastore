DS_CATEGORY = {
    CHARACTER,
    MAIL_LABEL,
    CURRENTLY_EQUIPPED,
    BAGSLOTTEXT,
    GUILD_BANK,
}

local selectedCategory = 1;

function CleanUI_InitDataStoreUI()
    tinsert(UISpecialFrames, CleanUIDataStoreFrame:GetName());
    UIPanelWindows["CleanUIDataStoreFrame"] = { area = "left", pushable = 1, whileDead = 1, width = 675};

    MoneyFrame_SetMaxDisplayWidth(CleanUIDataStoreFrameMoneyFrame, 200);

    local tab, tabButton;

    for i=1, 5 do
        tab = _G["CleanUIDataStoreFrameTab"..i];
        tabButton = _G["CleanUIDataStoreFrameTab"..i.."Button"];

        tabButton.Icon:SetTexCoord(0, 1, 0, 1);

        local icon = nil;
        if (i == 1) then
            icon = "Interface\\ICONS\\Ability_Ambush";
            tabButton.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9);
        elseif (i == 2) then
            icon = "Interface\\MailFrame\\Mail-Icon";
        elseif (i == 3) then
            icon = "Interface\\PaperDollInfoFrame\\UI-GearManager-Button";
            tabButton.Icon:SetTexCoord(0.2, 0.8, 0.2, 0.8);
        elseif (i == 4) then
            icon = "Interface\\BUTTONS\\Button-Backpack-Up";
            tabButton.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9);
        elseif (i == 5) then
            icon = "Interface\\ICONS\\TRADE_ARCHAEOLOGY_CHESTOFTINYGLASSANIMALS";
            tabButton.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9);
        end

        tabButton.Icon:SetTexture(icon);
    end

    CleanUIDataStoreFramePortrait:SetTexture("Interface\\FriendsFrame\\Battlenet-Portrait");
    CleanUIDataStoreFrameTitleText:SetText("Datastore");

    CleanUI_InitDataStoreUICharacters();
    CleanUI_InitDataStoreUIMail();
    CleanUI_InitDataStoreUIEquipment();
    CleanUI_InitDataStoreUIBags();
    CleanUI_InitDataStoreUIGuildBank();

    CleanUI_InitDataStoreSearch();

    CleanUIDataStore_ToggleCategory(selectedCategory);
end

function CleanUI_DataStoreUI_InitScrollFrameWithTemplate(frame, template, update)
    HybridScrollFrame_OnLoad(frame.scrollFrame);
    frame.scrollFrame.update = update;
    HybridScrollFrame_CreateButtons(frame.scrollFrame, template);

    frame.scrollFrame:SetFrameStrata("HIGH");
end

function CleanUI_DataStoreUI_CreateColumnHeader(parent, width, text, sortId, ref)
    local button = CreateFrame("Button", parent:GetName()..sortId, parent, "CleanUIDataStoreColumnButtonTemplate");
    button:SetSize(width, 25);

    if (ref) then
        button:SetPoint("LEFT", ref, "RIGHT", 0, 0);
    else
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, 0);
    end

    button:SetText(text);
    button.sort = sortId;

    return button;
end

function CleanUIDataStore_ToggleDataStoreUI()
    if (not CleanUIDataStoreFrame:IsVisible()) then
        CleanUI_DataStoreCollectAll();
        ShowUIPanel(CleanUIDataStoreFrame);
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);

        -- init data
        CleanUIDataStore_ToggleCategory(selectedCategory);
    else
        CleanUI_HideDataStoreUI();
    end
end

function CleanUI_HideDataStoreUI()
    if (CleanUIDataStoreFrame:IsVisible()) then
        HideUIPanel(CleanUIDataStoreFrame);
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
    end
end

function CleanUIDataStore_HideTooltip(self)
    GameTooltip:FadeOut();
end

function CleanUIDataStore_ToggleCategory(category)
    if (not CleanUIDataStoreFrame:IsVisible()) then
        return;
    end

    selectedCategory = category;

    CleanUI_DataStoreUIUpdateCommon();

    CleanUIDataStoreCharacterFrame:Hide();
    CleanUIDataStoreMailFrame:Hide();
    CleanUIDataStoreEquipmentFrame:Hide();
    CleanUIDataStoreBagsFrame:Hide();
    CleanUIDataStoreGuildBankFrame:Hide();

    if (selectedCategory == 1) then
        CleanUIDataStoreCharacterFrame:Show();
        CleanUI_DataStoreUIUpdateCharacterData();
        CleanUI_DataStoreUIUpdateCharacterSelection();
    elseif (selectedCategory == 2) then
        CleanUIDataStoreMailFrame:Show();
        CleanUI_DataStoreUIUpdateMailData();
    elseif (selectedCategory == 3) then
        CleanUIDataStoreEquipmentFrame:Show();
        CleanUI_DataStoreUIUpdateEquipmentData();
    elseif (selectedCategory == 4) then
        CleanUIDataStoreBagsFrame:Show();
        CleanUI_DataStoreUIUpdateBagsData();
    elseif (selectedCategory == 5) then
        CleanUIDataStoreGuildBankFrame:Show();
        CleanUI_DataStoreUIUpdateGuildBankData();
    end

    CleanUI_DataStoreUpdateSidetabs();
end

function CleanUI_DataStoreUpdateSidetabs()
    local tab, tabButton;

    for i=1, 5 do
        tab = _G["CleanUIDataStoreFrameTab"..i];
        tabButton = _G["CleanUIDataStoreFrameTab"..i.."Button"];

        if (i ~= selectedCategory) then
            tabButton:SetChecked(nil);
        else
            tabButton:SetChecked(1);
        end
    end
end

function CleanUI_DataStoreUIUpdateCommon()
    MoneyFrame_Update(CleanUIDataStoreFrameMoneyFrame:GetName(), CleanUIDS_GetAllMoney());
end

function CleanUIDataStore_SortByColumn(self)

    local column = self.sort;

    local sortKeyCharacters = CleanUI_DataStoreUIGetSortCharactersBy();
    local sortKeyMails = CleanUI_DataStoreUIGetSortMailsBy();
    local sortKeyEquipment = CleanUI_DataStoreUIGetSortEquipmentBy();
    local sortKeyBags = CleanUI_DataStoreUIGetSortBagsBy();

    if (string.find(column, "CHAR_") == 1) then
        if (sortKeyCharacters == column.."_ASC") then
            sortKeyCharacters = column.."_DESC";
        elseif (sortKeyCharacters == column.."_DESC") then
            sortKeyCharacters = column.."_ASC";
        else
            sortKeyCharacters = column.."_DESC";
        end

        CleanUI_DataStoreUISortCharactersBy(sortKeyCharacters);
    end

    if (string.find(column, "MAIL_") == 1) then
        if (sortKeyMails == column.."_ASC") then
            sortKeyMails = column.."_DESC";
        elseif (sortKeyMails == column.."_DESC") then
            sortKeyMails = column.."_ASC";
        else
            sortKeyMails = column.."_DESC";
        end

        CleanUI_DataStoreUISortMailsBy(sortKeyMails);
    end

    if (string.find(column, "EQUIP_") == 1) then
        if (sortKeyEquipment == column.."_ASC") then
            sortKeyEquipment = column.."_DESC";
        elseif (sortKeyEquipment == column.."_DESC") then
            sortKeyEquipment = column.."_ASC";
        else
            sortKeyEquipment = column.."_DESC";
        end

        CleanUI_DataStoreUISortEquipmentBy(sortKeyEquipment);
    end

    if (string.find(column, "BAGS_") == 1) then
        if (sortKeyBags == column.."_ASC") then
            sortKeyBags = column.."_DESC";
        elseif (sortKeyBags == column.."_DESC") then
            sortKeyBags = column.."_ASC";
        else
            sortKeyBags = column.."_DESC";
        end

        CleanUI_DataStoreUISortBagsBy(sortKeyBags);
    end
end
