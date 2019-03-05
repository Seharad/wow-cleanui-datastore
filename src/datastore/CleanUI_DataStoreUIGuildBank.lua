local selectedGuild = nil;
local guildNames = nil;
local selectedItemType = ALL;
local itemTypes = {};

local filter = nil;

function CleanUI_InitDataStoreUIGuildBank()
    CleanUI_DataStoreUIUpdateGuildBankData();

    UIDropDownMenu_Initialize(CleanUIDataStoreGuildBankFrameInfoGuildDropDown, CleanUIDataStoreFrame_GuildDropDown_Initialize);

    if (guildNames and #guildNames > 0) then
        CleanUIDataStore_ToggleGuild(1);
    end

    CleanUI_DataStoreUIUpdateGuildBankData();
end

function CleanUIDataStoreFrame_GuildDropDown_Initialize(self)

    guildNames = CleanUIDS_GetGuildNames();

    for i, itemType in ipairs(guildNames) do
        local info = UIDropDownMenu_CreateInfo();
        info.text = itemType;
        info.value = i;
        info.func = function()
            CleanUIDataStore_ToggleGuild(i);
        end
        UIDropDownMenu_AddButton(info);
    end
end

function CleanUIDataStore_ToggleGuild(i)
    selectedGuild = i;
    UIDropDownMenu_SetSelectedValue(CleanUIDataStoreGuildBankFrameInfoGuildDropDown, selectedGuild);
    CleanUIDataStoreGuildBankFrameInfoGuildDropDownText:SetText(guildNames[i]);

    itemTypes = CleanUIDS_GetGuildBankItemTypes(guildNames[i]);
    UIDropDownMenu_Initialize(CleanUIDataStoreGuildBankFrameInfoItemTypeDropDown, CleanUIDataStoreFrame_GuildItemTypeDropDown_Initialize);

    CleanUIDataStore_ToggleGuildItemType(1);

    CleanUI_DataStoreUIUpdateGuildBankData();
end

function CleanUIDataStoreFrame_GuildItemTypeDropDown_Initialize(self)
    for i, itemType in ipairs(itemTypes) do
        local info = UIDropDownMenu_CreateInfo();
        info.text = itemType;
        info.value = i;
        info.func = function()
            CleanUIDataStore_ToggleGuildItemType(i);
        end
        UIDropDownMenu_AddButton(info);
    end
end

function CleanUIDataStore_ToggleGuildItemType(i)
    selectedItemType = i;
    UIDropDownMenu_SetSelectedValue(CleanUIDataStoreGuildBankFrameInfoItemTypeDropDown, selectedItemType);
    CleanUIDataStoreGuildBankFrameInfoItemTypeDropDownText:SetText(itemTypes[i]);

    CleanUI_DataStoreUIUpdateGuildBankData();
end

function CleanUI_DataStoreUIUpdateGuildBankData()
    if (not selectedGuild) then
        return;
    end

    local guildname = guildNames[selectedGuild];

    if (not guildname) then
        return;
    end

    local ITEMS_PER_ROW = 16;

    -- collect data
    local items = {};

    local bagdata = CleanUIDS_GetGuildBankDataSortedByType(guildname);

    for itemType, typeData in pairs(bagdata) do
        if (selectedItemType == 1 or itemTypes[selectedItemType] == itemType) then
            for itemLink, data in pairs(typeData) do
                local itemData = {};
                itemData.itemLink = itemLink;
                itemData.itemCount = data.itemCount;
                tinsert(items, itemData);
            end
        end
    end

    local buttons = CleanUIDataStoreGuildBankFrame.scrollFrame.buttons;

    local numEntries = #items/ITEMS_PER_ROW + 1;
    local numButtons = #buttons;

    local scrollOffset = HybridScrollFrame_GetOffset(CleanUIDataStoreGuildBankFrame.scrollFrame);
    local buttonHeight = buttons[1]:GetHeight();
    local displayedHeight = 0;

    local act, index;

    local itemButton, itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice;
    local adjustedItemLevel, itemButtonBorder;
    local count;

    for i=1, numButtons do
        index = i + scrollOffset;
        act = buttons[i];

        if ( index <= numEntries ) then
            act:Show();

            local start = (index-1) * ITEMS_PER_ROW + 1;
            local ende = start + ITEMS_PER_ROW - 1;

            pos = 1;
            for e = start, ende do
                itemButton = _G[act:GetName().."Item"..pos];
                pos = pos + 1;

                act.data = items[e];

                if (act.data) then
                    itemButton.itemLink = act.data.itemLink;

                    itemButton:Show();
                    itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemButton.itemLink);
                    SetItemButtonTexture(itemButton, itemTexture);

                    -- check filter
                    if (filter and string.len(filter) > 0 and not string.find(itemName, filter)) then
                        itemButton:SetAlpha(0.2);
                    else
                        itemButton:SetAlpha(1.0);
                    end

                    if (not itemButton.qualityBorder) then
                        itemButtonBorder = itemButton:GetNormalTexture();
                        itemButtonBorder:SetTexture();

                        itemButton.qualityBorder = itemButton:CreateTexture("ARTWORK");
                        itemButton.qualityBorder:SetPoint("TOPLEFT", itemButtonBorder, "TOPLEFT", 0, -0);
                        itemButton.qualityBorder:SetPoint("BOTTOMRIGHT", itemButtonBorder, "BOTTOMRIGHT", -0, 0);
                    end

                    itemButton.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);

                    if (not itemButton.itemLevel) then
                        itemButton.itemLevel = itemButton:CreateFontString(itemButton:GetName().."ItemLevel", "ARTWORK");
                        itemButton.itemLevel:SetFontObject("GameFontNormalSmall");
                        itemButton.itemLevel:SetSize(itemButton:GetWidth(), 10);
                        itemButton.itemLevel:ClearAllPoints();
                        itemButton.itemLevel:SetPoint("TOPRIGHT", -2, -2);
                        itemButton.itemLevel:SetJustifyH("RIGHT");
                    end

                    adjustedItemLevel = CleanUI_GetActualItemLevel(itemButton.itemLink);
                    itemButton.itemLevel:SetText(ORANGE_FONT_COLOR_CODE..adjustedItemLevel..FONT_COLOR_CODE_CLOSE);

                    -- rarity color
                    r, g, b = 0.5, 0.5, 0.5;

                    if (itemRarity) then
                        r, g, b = GetItemQualityColor(itemRarity);
                    end

                    itemButton.qualityBorder:SetVertexColor(r, g, b);

                    -- count
                    count = act.data.itemCount;

                    if (count > 1) then
                        itemButton.Count:SetText(""..act.data.itemCount);
                        itemButton.Count:Show();
                    else
                        itemButton.Count:Hide();
                    end
                else
                    itemButton:Hide();
                end
            end
        else
            act:Hide();
        end

        displayedHeight = displayedHeight + buttonHeight;
    end

    HybridScrollFrame_Update(CleanUIDataStoreGuildBankFrame.scrollFrame, numEntries * buttonHeight, displayedHeight);
end

function CleanUI_DataStoreUIGuildSearch_OnTextChanged(self, userChanged)
    filter = self:GetText();
    CleanUI_DataStoreUIUpdateGuildBankData();
end
