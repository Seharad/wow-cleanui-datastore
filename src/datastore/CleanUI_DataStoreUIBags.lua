local selectedBags = nil;
local selectedItemType = ALL;
local itemTypes = {};

local sortKeyBags = "BAGS_NAME_ASC";

local filter = nil;

function CleanUI_InitDataStoreUIBags()
    -- bags columns
    local bagsNameColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreBagsFrame, 200, NAME, "BAGS_NAME", nil);
    local bagsLvlColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreBagsFrame, 45, LEVEL_ABBR, "BAGS_LVL", bagsNameColumn);
    local bagsUsageColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreBagsFrame, 110, CUI_DATASTORE_BAGS, "BAGS_USAGE", bagsLvlColumn);
    local bagsFreeColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreBagsFrame, 45, CUI_DATASTORE_FREE, "BAGS_FREE", bagsUsageColumn);
    local bankUsageColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreBagsFrame, 160, CUI_DATASTORE_BANK, "BAGS_BANK_USAGE", bagsFreeColumn);
    local bankFreeColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreBagsFrame, 45, CUI_DATASTORE_FREE, "BAGS_BANK_FREE", bankUsageColumn);
end

function CleanUI_DataStoreUISortBagsBy(sortKey)
    sortKeyBags = sortKey;
    CleanUI_DataStoreUIUpdateBagsData();
end

function CleanUI_DataStoreUIGetSortBagsBy()
    return sortKeyBags;
end

function CleanUI_DataStoreUI_SortBags(a, b)
    if (sortKeyBags == "BAGS_NAME_ASC") then
        return a.name < b.name;
    elseif  (sortKeyBags == "BAGS_NAME_DESC") then
        return a.name > b.name;
    end

    if (sortKeyBags == "BAGS_LVL_ASC") then
        return a.level < b.level;
    elseif  (sortKeyBags == "BAGS_LVL_DESC") then
        return a.level > b.level;
    end

    if (sortKeyBags == "BAGS_USAGE_ASC") then
        return a.bagsslots < b.bagsslots;
    elseif  (sortKeyBags == "BAGS_USAGE_DESC") then
        return a.bagsslots > b.bagsslots;
    end

    if (sortKeyBags == "BAGS_FREE_ASC") then
        return a.bagsfree < b.bagsfree;
    elseif  (sortKeyBags == "BAGS_FREE_DESC") then
        return a.bagsfree > b.bagsfree;
    end

    if (sortKeyBags == "BAGS_BANK_USAGE_ASC") then
        return a.bankslots < b.bankslots;
    elseif  (sortKeyBags == "BAGS_BANK_USAGE_DESC") then
        return a.bankslots > b.bankslots;
    end

    if (sortKeyBags == "BAGS_BANK_FREE_ASC") then
        return a.bankfree < b.bankfree;
    elseif  (sortKeyBags == "BAGS_BANK_FREE_DESC") then
        return a.bankfree > b.bankfree;
    end
end

function CleanUI_DataStoreUIUpdateBagsData()
    CleanUIDataStoreHighlightFrame:Hide();

    -- collect data
    local characters = {};

    local ilevel, icount, itemLink;

    for guid, store in pairs(CleanUIDataStore.Characters) do
        local data = {};
        data.guid = guid;
        data.name = store.baseData.name;
        data.race = store.baseData.race;
        data.class = store.baseData.class.englishClass;
        data.level = store.baseData.level;

        data.bagsfree = 0;
        data.bagsslots = 0;

        data.bankfree = 0;
        data.bankslots = 0;

        data.strbags = "";
        data.strbank = "";

        if (store.bags) then
            -- bags
            for i=1, 5 do
                if (store.bags.usage["ContainerFrame"..i]) then
                    data.bagsfree = data.bagsfree + (store.bags.usage["ContainerFrame"..i].numberOfFreeSlots or 0);
                    data.bagsslots = data.bagsslots + (store.bags.usage["ContainerFrame"..i].numberOfSlots or 0);

                    data.strbags = data.strbags..(store.bags.usage["ContainerFrame"..i].numberOfSlots or 0);
                    if (i ~= 5) then
                        data.strbags = data.strbags.."/";
                    end
                end
            end

            -- bank
            if (store.bags.usage.BankFrame) then
                data.bankfree = store.bags.usage.BankFrame.numberOfFreeSlots or 0;
                data.bankslots = store.bags.usage.BankFrame.numberOfSlots or 0;

                data.strbank = data.strbank..(store.bags.usage.BankFrame.numberOfSlots or 0).."/";
            end

            for i=6, 12 do
                if (store.bags.usage["ContainerFrame"..i]) then
                    data.bankfree = data.bankfree + (store.bags.usage["ContainerFrame"..i].numberOfFreeSlots or 0);
                    data.bankslots = data.bankslots + (store.bags.usage["ContainerFrame"..i].numberOfSlots or 0);

                    data.strbank = data.strbank..(store.bags.usage["ContainerFrame"..i].numberOfSlots or 0);
                    if (i ~= 12) then
                        data.strbank = data.strbank.."/";
                    end
                end
            end
        end

        data.free = data.bagsfree + data.bankfree;
        data.bagsused = data.bagsslots - data.bagsfree;
        data.bankused = data.bankslots - data.bankfree;

        tinsert(characters, data);
    end

    table.sort(characters, function(a,b) return CleanUI_DataStoreUI_SortBags(a, b) end);

    local buttons = CleanUIDataStoreBagsFrame.scrollFrame.buttons;

    local numEntries = #characters;
    local numButtons = #buttons;

    local scrollOffset = HybridScrollFrame_GetOffset(CleanUIDataStoreBagsFrame.scrollFrame);
    local buttonHeight = buttons[1]:GetHeight();
    local displayedHeight = 0;

    local act, index;

    for i=1, numButtons do
        index = i + scrollOffset;
        act = buttons[i];

        if ( index <= numEntries ) then
            act.data = characters[index];

            act:Show();

            -- name + race + class
            act:SetText(CleanUIDS_GetFullName(act.data.name, act.data.race, act.data.class));

            -- level
            act.level:SetText(act.data.level);

            -- bags usage
            act.bagsusage:SetText(act.data.strbags);

            -- bags free
            act.bagsfree:SetText(act.data.bagsfree);

            -- bank usage
            act.bankusage:SetText(act.data.strbank);

            -- bank free
            act.bankfree:SetText(act.data.bankfree);

            -- this isn't a header, hide the header textures
            act:SetNormalTexture("");
            act:SetHighlightTexture("");

            if (act.data.guid == selectedBags) then
                -- reposition highlight frames
                CleanUIDataStoreHighlightFrame:SetParent(act);
                CleanUIDataStoreHighlightFrame:SetPoint("TOPLEFT", act, "TOPLEFT", 0, 0);
                CleanUIDataStoreHighlightFrame:SetPoint("BOTTOMRIGHT", act, "BOTTOMRIGHT", 0, 0);
                CleanUIDataStoreHighlightFrame:Show();
            end
        else
            act:Hide();
        end

        displayedHeight = displayedHeight + buttonHeight;
    end

    HybridScrollFrame_Update(CleanUIDataStoreBagsFrame.scrollFrame, numEntries * buttonHeight, displayedHeight);
end

function CleanUIDataStoreBags_OnEnter(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self);
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

    local guid = self.data.guid;
    local baseData = CleanUIDataStore.Characters[guid].baseData;

    -- name + race + class
    GameTooltip:SetText(CleanUIDS_GetFullName(baseData.name, baseData.race, baseData.class.englishClass).." ("..baseData.level..")");
    GameTooltip:AddLine(CleanUIDS_GetColoredClass(baseData.class.localizedClass, baseData.class.englishClass));
    GameTooltip:AddLine(" ");

    GameTooltip:AddDoubleLine(CUI_DS_ACT_LOCATION..":", HIGHLIGHT_FONT_COLOR_CODE..baseData.locations.actLocation..FONT_COLOR_CODE_CLOSE);
    GameTooltip:AddDoubleLine(CUI_DS_BIND_LOCATION..":", HIGHLIGHT_FONT_COLOR_CODE..baseData.locations.bindLocation..FONT_COLOR_CODE_CLOSE);
    GameTooltip:AddLine(" ");

    GameTooltip:AddDoubleLine(FRIENDS_LIST_REALM, HIGHLIGHT_FONT_COLOR_CODE..baseData.realm..FONT_COLOR_CODE_CLOSE);
    GameTooltip:AddLine(" ");

    -- bag data
    local bagdata;
    local numberOfSlots, numberOfUsedSlots;
    local used = 0;
    local max = 0;
    if (CleanUIDataStore.Characters[guid].bags) then
        GameTooltip:AddLine(HIGHLIGHT_FONT_COLOR_CODE..CUI_DATASTORE_BAGS..":"..FONT_COLOR_CODE_CLOSE);
        for i=1, 5 do
            bagdata = CleanUIDataStore.Characters[guid].bags.usage["ContainerFrame"..i];
            numberOfUsedSlots, numberOfSlots = CleanUIDataStoreBags_AddTooltipBagInfo(bagdata);
            used = used + numberOfUsedSlots;
            max = max + numberOfSlots;
        end

        GameTooltip:AddLine(" ");
        GameTooltip:AddLine(HIGHLIGHT_FONT_COLOR_CODE..CUI_DATASTORE_BANK..":"..FONT_COLOR_CODE_CLOSE);
        bagdata = CleanUIDataStore.Characters[guid].bags.BankFrame;
        numberOfUsedSlots, numberOfSlots = CleanUIDataStoreBags_AddTooltipBagInfo(bagdata);
        used = used + numberOfUsedSlots;
        max = max + numberOfSlots;

        for i=6, 12 do
            bagdata = CleanUIDataStore.Characters[guid].bags.usage["ContainerFrame"..i];
            numberOfUsedSlots, numberOfSlots = CleanUIDataStoreBags_AddTooltipBagInfo(bagdata);
            used = used + numberOfUsedSlots;
            max = max + numberOfSlots;
        end
    end

    GameTooltip:AddLine(" ");
    GameTooltip:AddDoubleLine(TOTAL..":", HIGHLIGHT_FONT_COLOR_CODE..used.."/"..max..FONT_COLOR_CODE_CLOSE);

    GameTooltip:Show();
end

function CleanUIDataStoreBags_AddTooltipBagInfo(bagdata)
    local numberOfSlots = 0;
    local numberOfFreeSlots = 0;
    local numberOfUsedSlots = 0;
    if (bagdata) then
        numberOfSlots = bagdata.numberOfSlots or 0;

        if (numberOfSlots > 0) then
            numberOfFreeSlots = bagdata.numberOfFreeSlots or 0;
            numberOfUsedSlots = numberOfSlots - numberOfFreeSlots;

            local bagName = bagdata.bagName;
            if (not bagdata.bagName or bagdata.bagName == "") then
                bagName = "-";
            end

            GameTooltip:AddDoubleLine(bagdata.bagName, HIGHLIGHT_FONT_COLOR_CODE..numberOfUsedSlots.."/"..numberOfSlots..FONT_COLOR_CODE_CLOSE);
        end
    end

    return numberOfUsedSlots, numberOfSlots;
end

function CleanUIDataStoreBags_OnClick(self, button, down)
    selectedBags = self.data.guid;

    CleanUI_DataStoreUIUpdateBagsData();
    CleanUI_DataStoreUIUpdateBagsSelection();
    CleanUI_DataStoreUIUpdateBagItemData();
end

function CleanUIDataStoreFrame_BagItemTypeDropDown_Initialize(self)
    for i, itemType in ipairs(itemTypes) do
        local info = UIDropDownMenu_CreateInfo();
        info.text = itemType;
        info.value = i;
        info.func = function()
            CleanUIDataStore_ToggleBagItemType(i);
        end
        UIDropDownMenu_AddButton(info);
    end
end

function CleanUIDataStore_ToggleBagItemType(i)
    selectedItemType = i;
    UIDropDownMenu_SetSelectedValue(CleanUIDataStoreBagsFrameInfoItemTypeDropDown, selectedItemType);
    CleanUIDataStoreBagsFrameInfoItemTypeDropDownText:SetText(itemTypes[i]);

    CleanUI_DataStoreUIUpdateBagItemData();
end

function CleanUI_DataStoreUIUpdateBagsSelection()
    local info = CleanUIDataStoreBagsFrame.info;

    if (not selectedBags) then
        info:Hide();
        return;
    end

    info:Show();

    selectedItemType = 1;
    itemTypes = CleanUIDS_GetBagItemTypes(selectedBags);
    UIDropDownMenu_Initialize(CleanUIDataStoreBagsFrameInfoItemTypeDropDown, CleanUIDataStoreFrame_BagItemTypeDropDown_Initialize);
    UIDropDownMenu_SetSelectedValue(CleanUIDataStoreBagsFrameInfoItemTypeDropDown, 1);
    CleanUIDataStoreBagsFrameInfoItemTypeDropDownText:SetText(itemTypes[1]);

    CleanUI_DataStoreUIUpdateBagItemData();
end

function CleanUI_DataStoreUIUpdateBagItemData()
    local ITEMS_PER_ROW = 16;

    -- collect data
    local items = {};

    local bagdata = CleanUIDS_GetBagDataSortedByType(selectedBags);

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

    local buttons = CleanUIDataStoreBagsFrame.info.items.scrollFrame.buttons;

    local numEntries = #items/ITEMS_PER_ROW + 1;
    local numButtons = #buttons;

    local scrollOffset = HybridScrollFrame_GetOffset(CleanUIDataStoreBagsFrame.info.items.scrollFrame);
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
                    if (filter and filter ~= SEARCH and string.len(filter) > 0 and not string.find(itemName, filter)) then
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
                        itemButton.Count:SetText(""..count);
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

    HybridScrollFrame_Update(CleanUIDataStoreBagsFrame.info.items.scrollFrame, numEntries * buttonHeight, displayedHeight);
end

function CleanUI_DataStoreUIBagSearch_OnTextChanged(self, userChanged)
    filter = self:GetText();
    CleanUI_DataStoreUIUpdateBagItemData();
end

