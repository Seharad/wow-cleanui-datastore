local foundData = {};

function CleanUI_InitDataStoreSearch()
    local searchFrame = CreateFrame("Frame", "CleanUIDataStoreSearchFrame", CleanUIDataStoreFrame, "CleanUIDataStoreSearchFrameTemplate");
    --CleanUI_SetBackdrop(searchFrame);
    searchFrame:SetSize(265, 550);
    searchFrame:ClearAllPoints();
    searchFrame:SetPoint("BOTTOMLEFT", CleanUIDataStoreFrame, "BOTTOMRIGHT", 60, 0);

    -- create gui
    HybridScrollFrame_OnLoad(CleanUIDataStoreSearchFrame.scrollFrame);
    CleanUIDataStoreSearchFrame.scrollFrame.update = CleanUI_DataStoreSearch_OnUpdate;
    HybridScrollFrame_CreateButtons(CleanUIDataStoreSearchFrame.scrollFrame, "CleanUIDataStoreSearchEntryTemplate");



    CleanUIDataStoreSearchFramePortrait:SetTexture("Interface\\MailFrame\\Mail-Icon");
    CleanUIDataStoreSearchFrameTitleText:SetText("Search");

    CleanUI_DataStoreSearch_OnUpdate();
end

function CleanUI_DataStore_Search(name)
    if (not CleanUIDataStoreSearchFrame:IsVisible()) then
        CleanUIDataStoreSearchFrame:Show();
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
    end

    -- do search here
    foundData = CleanUIDS_SearchByName(name);
    CleanUI_DataStoreSearch_OnUpdate();
end

function CleanUI_DataStore_ToggleSearch()
    if (not CleanUIDataStoreSearchFrame:IsVisible()) then
        CleanUIDataStoreSearchFrame:Show();
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
    else
        CleanUIDataStoreSearchFrame:Hide();
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
    end
end

function CleanUIDataStoreSearchItem_OnEnter(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self);
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

    GameTooltip:SetHyperlink(self.itemLink);

    GameTooltip:Show();
end

function CleanUIDataStoreSearchItem_OnLeave(self)
    GameTooltip:FadeOut();
end

function CleanUI_DataStoreSearch_OnUpdate()
    if (not CleanUIDataStoreSearchFrame) then
        return;
    end

    -- update frame
    CleanUIDataStoreSearchFrame.scrollFrame.highlightFrame:Hide();

    local buttons = CleanUIDataStoreSearchFrame.scrollFrame.buttons;

    local numEntries = #foundData;
    local numButtons = #buttons;

    local scrollOffset = HybridScrollFrame_GetOffset(CleanUIDataStoreSearchFrame.scrollFrame);
    local buttonHeight = buttons[1]:GetHeight();
    local displayedHeight = 0;

    local entry;
    local data;

    local itemButton, itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice;
    local itemButtonBorder;

    for i=1, numButtons do
        local entryIndex = i + scrollOffset;
        entry = buttons[i];
        itemButton = entry.itemButton;

        if ( entryIndex <= numEntries ) then
            itemLink = foundData[entryIndex].link;

            entry:Show();
            entry.index = entryIndex;
            entry.itemLink = itemLink;

            itemButton.itemLink = itemLink;

            -- button data
            itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemLink);

            if (itemRarity) then
                local r, g, b, hex = GetItemQualityColor(itemRarity);
                entry:SetText("|c"..hex..itemName..FONT_COLOR_CODE_CLOSE);
            else
                entry:SetText(itemName);
            end

            -- item
            SetItemButtonTexture(itemButton, itemTexture);

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
            count = foundData[entryIndex].count;

            if (count > 1) then
                itemButton.Count:SetText(""..count);
                itemButton.Count:Show();
            else
                itemButton.Count:Hide();
            end

            -- this isn't a header, hide the header textures
            entry:SetNormalTexture("");
            entry:SetHighlightTexture("");

            if (entryIndex == selectedIndex) then
                -- reposition highlight frames
                CleanUIDataStoreSearchFrame.scrollFrame.highlightFrame:SetParent(entry);
                CleanUIDataStoreSearchFrame.scrollFrame.highlightFrame:SetAllPoints(entry.name);
                CleanUIDataStoreSearchFrame.scrollFrame.highlightFrame:Show();
            end
        else
            entry:Hide();
        end

        displayedHeight = displayedHeight + buttonHeight;
    end

    HybridScrollFrame_Update(CleanUIDataStoreSearchFrame.scrollFrame, numEntries * buttonHeight, displayedHeight);
end
