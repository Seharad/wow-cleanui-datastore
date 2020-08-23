--[[

ARMOR

Death Knight - Cloth, Leather, Mail, Plate
Druid - Cloth, Leather
Hunter - Cloth, Leather, Mail (at level 40)
Mage - Cloth
Monk - Cloth, Leather
Paladin - Cloth, Leather, Mail, Plate (at level 40), Shields
Priest - Cloth
Rogue - Cloth, Leather
Shaman - Cloth, Leather, Mail (at level 40), Shields
Warlock - Cloth
Warrior - Cloth, Leather, Mail, Plate (at level 40), Shields

]]

local slotNames = {
    "Item level",
    INVTYPE_HEAD,
    INVTYPE_NECK,
    INVTYPE_SHOULDER,
    INVTYPE_CLOAK,
    INVTYPE_CHEST,
    INVTYPE_WRIST,
    INVTYPE_HAND,
    INVTYPE_WAIST,
    INVTYPE_LEGS,
    INVTYPE_FEET,
    INVTYPE_FINGER,
    INVTYPE_FINGER,
    INVTYPE_TRINKET,
    INVTYPE_TRINKET,
    INVTYPE_WEAPONMAINHAND,
    INVTYPE_WEAPONOFFHAND,
}


local selectedEquipment = nil;
local sortKeyEquipment = "EQUIP_NAME_ASC";

local compareItemLink = nil;
local compareWithItemLink = nil;

local orderBy = 1;

function CleanUI_InitDataStoreUIEquipment()
    -- equipment columns
    local equipNameColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreEquipmentFrame, 185, NAME, "EQUIP_NAME", nil);
    local equipItemsColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreEquipmentFrame, 420, ITEMS, "EQUIP_ITEMS", equipNameColumn);

    UIDropDownMenu_Initialize(CleanUIDataStoreEquipmentFrameOrderDropDown, CleanUIDataStoreFrame_OrderDropDown_Initialize);
end

function CleanUIDataStoreFrame_OrderDropDown_Initialize(self)
    for i, name in ipairs(slotNames) do
        local info = UIDropDownMenu_CreateInfo();
        info.text = name;
        info.value = i;
        info.func = function()
            CleanUIDataStore_SetOrderBy(i);
        end
        UIDropDownMenu_AddButton(info);
    end

    CleanUIDataStore_SetOrderBy(orderBy);
end

function CleanUIDataStore_SetOrderBy(i)
    orderBy = i;

    if (CleanUIDataStoreEquipmentFrameOrderDropDown) then
        UIDropDownMenu_SetSelectedValue(CleanUIDataStoreEquipmentFrameOrderDropDown, orderBy);
        CleanUIDataStoreEquipmentFrameOrderDropDownText:SetText(slotNames[orderBy]);
    end

    CleanUI_DataStoreUIUpdateEquipmentData();
end

function CleanUI_DataStoreUISortEquipmentBy(sortKey)
    sortKeyEquipment = sortKey;
    CleanUI_DataStoreUIUpdateEquipmentData();
end

function CleanUI_DataStoreUIGetSortEquipmentBy()
    return sortKeyEquipment;
end

function CleanUI_DataStoreUI_SortEquipment(a, b)
    if (sortKeyEquipment == "EQUIP_NAME_ASC") then
        return a.name < b.name;
    elseif  (sortKeyEquipment == "EQUIP_NAME_DESC") then
        return a.name > b.name;
    end

    if (sortKeyEquipment == "EQUIP_ITEMS_ASC") then
        return a.itemLevel[orderBy] < b.itemLevel[orderBy];
    elseif  (sortKeyEquipment == "EQUIP_ITEMS_DESC") then
        return a.itemLevel[orderBy] > b.itemLevel[orderBy];
    end

    return false;
end

function CleanUI_DataStoreUIUpdateEquipmentData()
    CleanUIDataStoreHighlightFrame:Hide();

    -- collect data
    local characters = {};

    local actItemLevel, ilevel, icount, itemLink;

    for guid, store in pairs(CleanUIDataStore.Characters) do
        local data = {};
        data.guid = guid;

        if (store.baseData ~= nil) then
            data.name = store.baseData.name;
            data.race = store.baseData.race;
            data.class = store.baseData.class.englishClass;
        end

        data.itemLevel = {};

        if (store.equipment ~= nil) then
            ilevel = 0;
            icount = 0;
            for pos, equipment in pairs(store.equipment) do
                if (equipment.itemLink) then
                    actItemLevel = CleanUI_GetActualItemLevel(equipment.itemLink) or 0;
                    icount = icount + 1;
                    ilevel = ilevel + actItemLevel;

                    data.itemLevel[pos + 1] = actItemLevel;
                else
                    actItemLevel = 0;
                    data.itemLevel[pos + 1] = 0;
                end
            end

            data.itemLevel[1] = ilevel/icount;

            if (store.equipment and #(store.equipment) > 0) then
                data.equipment = {};
                for e = 1, 16 do
                    data.equipment[e] = {};
                    data.equipment[e].name = store.equipment[e].name;
                    data.equipment[e].currentDurability = store.equipment[e].currentDurability;
                    data.equipment[e].maximumDurability = store.equipment[e].maximumDurability;
                    data.equipment[e].itemLink = store.equipment[e].itemLink;
                end
            end

            tinsert(characters, data);
        end
    end

    table.sort(characters, function(a,b) return CleanUI_DataStoreUI_SortEquipment(a, b) end);

    local buttons = CleanUIDataStoreEquipmentFrame.scrollFrame.buttons;

    local numEntries = #characters;
    local numButtons = #buttons;

    local scrollOffset = HybridScrollFrame_GetOffset(CleanUIDataStoreEquipmentFrame.scrollFrame);
    local buttonHeight = buttons[1]:GetHeight();
    local displayedHeight = 0;

    local act, index;
    local itemButton, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice;
    local adjustedItemLevel, itemButtonBorder;

    for i=1, numButtons do
        index = i + scrollOffset;
        act = buttons[i];

        if ( index <= numEntries ) then
            act.data = characters[index];

            act:Show();

            -- name + race + class
            act:SetText(CleanUIDS_GetFullName(act.data.name, act.data.race, act.data.class));

            -- items
            for e = 1, 16 do
                itemButton = _G[act:GetName().."Item"..e];
                itemButton.itemLink = act.data.equipment[e].itemLink;

                if (itemButton.itemLink) then
                    itemButton:Show();
                    _, _, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemButton.itemLink);
                    SetItemButtonTexture(itemButton, itemTexture);

                    if (not itemButton.qualityBorder) then
                        itemButtonBorder = itemButton:GetNormalTexture();
                        itemButtonBorder:SetTexture();

                        itemButton.qualityBorder = itemButton:CreateTexture("ARTWORK");
                        itemButton.qualityBorder:SetPoint("TOPLEFT", itemButtonBorder, "TOPLEFT", 11, -11);
                        itemButton.qualityBorder:SetPoint("BOTTOMRIGHT", itemButtonBorder, "BOTTOMRIGHT", -11, 11);
                    end

                    if (not itemButton.itemLevel) then
                        itemButton.itemLevel = itemButton:CreateFontString(itemButton:GetName().."ItemLevel", "ARTWORK");
                        itemButton.itemLevel:SetFontObject("GameFontNormalSmall");
                        itemButton.itemLevel:SetSize(itemButton:GetWidth(), 10);
                        itemButton.itemLevel:ClearAllPoints();
                        itemButton.itemLevel:SetPoint("TOPRIGHT", -2, -2);
                        itemButton.itemLevel:SetJustifyH("RIGHT");
                    end

                    adjustedItemLevel = CleanUI_GetActualItemLevel(itemButton.itemLink) or 0;
                    itemButton.itemLevel:SetText(ORANGE_FONT_COLOR_CODE..adjustedItemLevel..FONT_COLOR_CODE_CLOSE);

                    -- rarity color
                    r, g, b = 0.5, 0.5, 0.5;

                    if (itemRarity) then
                        r, g, b = GetItemQualityColor(itemRarity);
                    end

                    itemButton.qualityBorder:SetVertexColor(r, g, b);
                else
                    itemButton:Hide();
                end
            end

            -- this isn't a header, hide the header textures
            act:SetNormalTexture("");
            act:SetHighlightTexture("");

            if (act.data.guid == selectedEquipment) then
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

    HybridScrollFrame_Update(CleanUIDataStoreEquipmentFrame.scrollFrame, numEntries * buttonHeight, displayedHeight);
end

function CleanUIDataStoreEquipment_OnEnter(self)
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

    -- item data
    GameTooltip:AddDoubleLine("aIL:", HIGHLIGHT_FONT_COLOR_CODE..string.format("%.1f", self.data.itemLevel[1])..FONT_COLOR_CODE_CLOSE);

    GameTooltip:Show();
end

function CleanUIDataStoreEquipment_OnClick(self, button, down)

    selectedEquipment = self.data.guid;


    CleanUI_DataStoreUIUpdateEquipmentData();
    CleanUI_DataStoreUIUpdateEquipmentSelection();
end

function CleanUIDataStoreEquipmentSlot_OnEnter(self)
    if (not self.itemLink) then
        return;
    end

    GameTooltip_SetDefaultAnchor(GameTooltip, self);
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

    GameTooltip:SetHyperlink(self.itemLink);

    GameTooltip:Show();
end

function CleanUI_DataStoreUIUpdateEquipmentSelection()
end

function CleanUIDataStoreEquipmentSlot_OnClick(self, button, down)
    compareWithItemLink = self.itemLink;

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(compareWithItemLink);

    local itemButton = CleanUIDataStoreEquipmentFrameInfo.ItemButton2;
    itemButton.IconTexture:SetTexture(itemTexture);

    local r, g, b, hex = GetItemQualityColor(itemRarity);
    itemButton.ItemName:SetText("|c"..hex..itemName..FONT_COLOR_CODE_CLOSE);

    itemButton.itemLink = itemLink;

    CleanUI_DataStoreEquipmentCompareLinks();
end

function CleanUI_DataStoreEquipmentOnClick(self, button)
    GameTooltip:Hide();

    local type, id, itemLink = GetCursorInfo();
    ClearCursor();

    if (type ~= "item") then
        return;
    end

    local itemButton = CleanUIDataStoreEquipmentFrameInfo.ItemButton;

    compareItemLink = itemLink;

    if (not compareItemLink or not IsEquippableItem(compareItemLink)) then
        itemButton.itemLink = nil;
        compareItemLink = nil;

        CleanUI_DataStoreEquipmentClearInfo(itemButton);
        return;
    end

    itemButton.itemLink = compareItemLink;
    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(compareItemLink);

    itemButton.MissingText:Hide();
    itemButton.IconTexture:SetTexture(itemTexture);

    local r, g, b, hex = GetItemQualityColor(itemRarity);
    itemButton.ItemName:SetText("|c"..hex..itemName..FONT_COLOR_CODE_CLOSE);

    CleanUI_DataStoreEquipmentCompareLinks();
end

function CleanUI_DataStoreEquipmentClearInfo(itemButton)
    itemButton.MissingText:Show();
    itemButton.IconTexture:SetTexture(nil);
    itemButton.ItemName:SetText("");
    CleanUI_DataStoreEquipmentCompareLinks();
end

function CleanUI_DataStoreEquipmentCompareLinks()

    local message = CleanUI_DataStoreEquipmentCompare();

    if (message) then
        _G["CleanUIDataStoreEquipmentFrameInfoCompInfo"]:SetText(message);

        for i=1, 10 do
            _G["CleanUIDataStoreEquipmentFrameInfoCompValue"..i]:SetText("");
        end
    else
        _G["CleanUIDataStoreEquipmentFrameInfoCompInfo"]:SetText(ITEM_DELTA_DESCRIPTION);
    end
end

function CleanUI_DataStoreEquipmentCompare()
    if (not compareItemLink or not compareWithItemLink) then
        return "";
    end

    local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(compareItemLink);
    local _, _, _, _, _, _, _, _, itemEquipLoc2 = GetItemInfo(compareWithItemLink);

    if (itemEquipLoc ~= itemEquipLoc2) then
        return CUI_DS_WRONG_EQUIP_LOC.." (".._G[itemEquipLoc].."/".._G[itemEquipLoc2]..")";
    end

    local stats1 = GetItemStats(compareWithItemLink);
    local stats2 = GetItemStats(compareItemLink);
    local comp = {};

    for name, value in pairs(stats1) do
        comp[name] = (stats2[name] or 0) - stats1[name];
    end

    for name, value in pairs(stats2) do
        if (not comp[name]) then
            comp[name] = stats2[name];
        end
    end

    local message;
    local index = 1;
    for name, value in pairs(comp) do
        if (value ~= 0) then
            message = value.." ".._G[name];

            if (value > 0) then
                message = GREEN_FONT_COLOR_CODE.."+"..message..FONT_COLOR_CODE_CLOSE;
            else
                message = RED_FONT_COLOR_CODE..message..FONT_COLOR_CODE_CLOSE;
            end

            _G["CleanUIDataStoreEquipmentFrameInfoCompValue"..index]:SetText(message);

            index = index + 1;
        end
    end

    for i=index, 10 do
        _G["CleanUIDataStoreEquipmentFrameInfoCompValue"..i]:SetText("");
    end
end
