local selectedMailCharacter = nil;
local sortKeyMails = "MAIL_TOTAL_DESC";
local selectedMail = nil;

function CleanUI_InitDataStoreUIMail()
    -- mail columns
    local mailNameColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreMailFrame, 185, NAME, "MAIL_NAME", nil);
    local mailTotalColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreMailFrame, 60, TOTAL, "MAIL_TOTAL", mailNameColumn);
    local mailItemsColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreMailFrame, 100, ITEMS, "MAIL_ITEMS", mailTotalColumn);

    MoneyFrame_SetMaxDisplayWidth(CleanUIDataStoreMailFrameMoneyFrame, 180);
end

function CleanUI_DataStoreUISortMailsBy(sortKey)
    sortKeyMails = sortKey;
    CleanUI_DataStoreUIUpdateMailData();
end

function CleanUI_DataStoreUIGetSortMailsBy()
    return sortKeyMails;
end

function CleanUI_DataStoreUI_SortMails(a, b)
    if (sortKeyMails == "MAIL_NAME_ASC") then
        return a.name < b.name;
    elseif  (sortKeyMails == "MAIL_NAME_DESC") then
        return a.name > b.name;
    end

    if (sortKeyMails == "MAIL_TOTAL_ASC") then
        return a.total < b.total;
    elseif  (sortKeyMails == "MAIL_TOTAL_DESC") then
        return a.total > b.total;
    end

    if (sortKeyMails == "MAIL_ITEMS_ASC") then
        return a.countItems < b.countItems;
    elseif  (sortKeyMails == "MAIL_ITEMS_DESC") then
        return a.countItems > b.countItems;
    end

    return false;
end

function CleanUI_DataStoreUIUpdateMailData()
    CleanUIDataStoreHighlightFrame:Hide();

    -- collect data
    local characters = {};

    for guid, store in pairs(CleanUIDataStore.Characters) do
        local data = {};
        data.guid = guid;
        data.name = store.baseData.name;
        data.race = store.baseData.race;
        data.class = store.baseData.class.englishClass;

        data.countExpiringMail, data.countExpiredMail = CleanUIDS_CountExpiringMail(guid);

        if (store.mail and #(store.mail) > 0) then
            data.total = #(store.mail);
            data.countItems = 0;

            data.mails = {};
            for m = 1, #(store.mail) do
                data.mails[m] = {};
                data.countItems = data.countItems + (store.mail[m].hasItem or 0);
            end
        else
            data.total = 0;
            data.countItems = 0;
        end

        tinsert(characters, data);
    end

    table.sort(characters, function(a,b) return CleanUI_DataStoreUI_SortMails(a, b) end);

    local buttons = CleanUIDataStoreMailFrame.scrollFrame.buttons;

    local numEntries = #characters;
    local numButtons = #buttons;

    local scrollOffset = HybridScrollFrame_GetOffset(CleanUIDataStoreMailFrame.scrollFrame);
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

            -- wenn keine Mails vorhanden sind
            if (act.data.total == 0) then
                act.total:SetText(GRAY_FONT_COLOR_CODE..act.data.total..FONT_COLOR_CODE_CLOSE);
                act.items:SetText("");
            end

            -- mindestens ein Mail
            if (act.data.total > 0) then
                local text = GREEN_FONT_COLOR_CODE..act.data.total..FONT_COLOR_CODE_CLOSE;

                if (act.data.countExpiringMail > 0) then
                    text = text.."/"..RED_FONT_COLOR_CODE..act.data.countExpiringMail..FONT_COLOR_CODE_CLOSE;
                end

                if (act.data.countExpiredMail > 0) then
                    text = text.."/"..GRAY_FONT_COLOR_CODE..act.data.countExpiredMail..FONT_COLOR_CODE_CLOSE;
                end

                act.total:SetText(text);
                act.items:SetText(HIGHLIGHT_FONT_COLOR_CODE..act.data.countItems..FONT_COLOR_CODE_CLOSE);
            end

            -- this isn't a header, hide the header textures
            act:SetNormalTexture("");
            act:SetHighlightTexture("");

            if (act.data.guid == selectedMailCharacter) then
                -- reposition highlight frames
                CleanUIDataStoreHighlightFrame:SetParent(act);
                CleanUIDataStoreHighlightFrame:ClearAllPoints();
                CleanUIDataStoreHighlightFrame:SetPoint("TOPLEFT", act, "TOPLEFT", 0, 0);
                CleanUIDataStoreHighlightFrame:SetPoint("BOTTOMRIGHT", act, "BOTTOMRIGHT", 0, 0);
                CleanUIDataStoreHighlightFrame:Show();
            end
        else
            act:Hide();
        end

        displayedHeight = displayedHeight + buttonHeight;
    end

    HybridScrollFrame_Update(CleanUIDataStoreMailFrame.scrollFrame, numEntries * buttonHeight, displayedHeight);
end

function CleanUIDataStoreMail_OnEnter(self)
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

    -- mail data
    local store = CleanUIDataStore.Characters[guid].mail;

    if (store and #store > 0) then
        GameTooltip:AddLine(" ");

        local expireDiff, timestring, fontColorCode, sender;
        for i=1, #store do
            -- expires
            expireDiff = store[i].expireDate - time();
            timestring = FriendsFrame_GetLastOnline(expireDiff, true);

            timestring = timestring or "unknown";
            sender = store[i].sender or "unknown";

            fontColorCode = HIGHLIGHT_FONT_COLOR_CODE;

            if (expireDiff < (5 * 24 * 60 * 60)) then -- f�nf Tage
                fontColorCode = RED_FONT_COLOR_CODE;
            end

            if (expireDiff > 0) then
                if (store[i].wasReturned) then -- wurde schon einmal zur�ck geschickt
                    GameTooltip:AddDoubleLine(store[i].subject, fontColorCode..string.format(CUI_DATASTORE_LABEL_DELETE, timestring)..FONT_COLOR_CODE_CLOSE);
                else
                    GameTooltip:AddDoubleLine(store[i].subject, fontColorCode..string.format(CUI_DATASTORE_LABEL_SEND_BACK, timestring, sender)..FONT_COLOR_CODE_CLOSE);
                end
            else
                if (store[i].wasReturned) then -- wurde schon einmal zur�ck geschickt
                    GameTooltip:AddDoubleLine(store[i].subject, fontColorCode..CUI_DATASTORE_LABEL_DELETED..FONT_COLOR_CODE_CLOSE);
                else
                    GameTooltip:AddDoubleLine(store[i].subject, fontColorCode..string.format(CUI_DATASTORE_LABEL_SENT_BACK, sender)..FONT_COLOR_CODE_CLOSE);
                end
            end
        end
    end

    GameTooltip:Show();
end

function CleanUIDataStoreMail_OnClick(self, button, down)

    selectedMailCharacter = self.data.guid;

    CleanUI_DataStoreUIUpdateMailData();
    CleanUI_DataStoreUIUpdateMailSelection();
end

function CleanUI_DataStoreUIUpdateMailSelection()
    local info = CleanUIDataStoreMailFrame.info;

    if (not selectedMailCharacter) then
        info:Hide();
        return;
    end

    -- Mail Daten z�hlen
    local data = CleanUIDataStore.Characters[selectedMailCharacter].mail;

    if (not data or #data == 0) then
        info:Hide();
        return;
    end

    info:Show();

    -- Daten laden
    selectedMail = nil;
    CleanUI_DataStoreUIUpdateMailSubjectData();
    CleanUI_DataStoreUIUpdateMailSubjectSelection();
end

function CleanUI_DataStoreUIUpdateMailSubjectData()
    CleanUIDataStoreHighlightFrame2:Hide();

    -- collect data
    local mails = {};

    local store = CleanUIDataStore.Characters[selectedMailCharacter].mail;

    for i=1, #store do
        local data = {};
        data.index = i;
        data.packageIcon = store[i].packageIcon;
        data.stationeryIcon = store[i].stationeryIcon;
        data.sender = store[i].sender;
        data.subject = store[i].subject;
        data.messageText = store[i].messageText;
        data.expireDate = store[i].expireDate;
        data.wasReturned = store[i].wasReturned;
        data.hasItem = store[i].hasItem;

        data.money = store[i].money;
        data.CODAmount = store[i].CODAmount;

        if (data.hasItem) then
            data.items = store[i].items;
        end

        tinsert(mails, data);
    end

    local buttons = CleanUIDataStoreMailFrame.info.subject.scrollFrame.buttons;

    local numEntries = #mails;
    local numButtons = #buttons;

    local scrollOffset = HybridScrollFrame_GetOffset(CleanUIDataStoreMailFrame.info.subject.scrollFrame);
    local buttonHeight = buttons[1]:GetHeight();
    local displayedHeight = 0;

    local act, index, name, classColor, classColorText;
    local name;

    for i=1, numButtons do
        index = i + scrollOffset;
        act = buttons[i];

        if ( index <= numEntries ) then
            act.data = mails[index];

            act:Show();

            -- subject
            if (CleanUIDS_CheckMail(act.data)) then
                act:SetText(RED_FONT_COLOR_CODE..act.data.subject..FONT_COLOR_CODE_CLOSE);
            else
                act:SetText(HIGHLIGHT_FONT_COLOR_CODE..act.data.subject..FONT_COLOR_CODE_CLOSE);
            end

            if (act.data.packageIcon) then
                act.icon:SetTexture(act.data.packageIcon);
            else
                act.icon:SetTexture(act.data.stationeryIcon);
            end

            act.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);

            -- this isn't a header, hide the header textures
            act:SetNormalTexture("");
            act:SetHighlightTexture("");

            if (selectedMail and act.data.index == selectedMail.index) then
                -- reposition highlight frames
                CleanUIDataStoreHighlightFrame2:SetParent(act);
                CleanUIDataStoreHighlightFrame2:SetPoint("TOPLEFT", act, "TOPLEFT", 0, 0);
                CleanUIDataStoreHighlightFrame2:SetPoint("BOTTOMRIGHT", act, "BOTTOMRIGHT", 0, 0);
                CleanUIDataStoreHighlightFrame2:Show();
            end
        else
            act:Hide();
        end

        displayedHeight = displayedHeight + buttonHeight;
    end

    HybridScrollFrame_Update(CleanUIDataStoreMailFrame.info.subject.scrollFrame, numEntries * buttonHeight, displayedHeight);
end

function CleanUI_DataStoreUIUpdateMailSubjectSelection()
    local frame = CleanUIDataStoreMailFrame.info.content;

    if (not selectedMail) then
        frame:Hide();
        return;
    end

    frame:Show();

    local sender = selectedMail.sender or "unknown";

    -- subject
    if (CleanUIDS_CheckMail(selectedMail)) then
        frame.subject:SetText(RED_FONT_COLOR_CODE..selectedMail.subject..FONT_COLOR_CODE_CLOSE);
    else
        frame.subject:SetText(HIGHLIGHT_FONT_COLOR_CODE..selectedMail.subject..FONT_COLOR_CODE_CLOSE);
    end

    -- from
    frame.from:SetText(HIGHLIGHT_FONT_COLOR_CODE..sender..FONT_COLOR_CODE_CLOSE);

    -- expires
    local expireDiff = selectedMail.expireDate - time();
    local timestring = FriendsFrame_GetLastOnline(expireDiff, true);

    if (expireDiff > 0) then
        if (selectedMail.wasReturned) then
            frame.expires:SetText(HIGHLIGHT_FONT_COLOR_CODE..string.format(CUI_DATASTORE_LABEL_DELETE, timestring)..FONT_COLOR_CODE_CLOSE);
        else
            frame.expires:SetText(HIGHLIGHT_FONT_COLOR_CODE..string.format(CUI_DATASTORE_LABEL_SEND_BACK, timestring, sender)..FONT_COLOR_CODE_CLOSE);
        end
    else
        if (selectedMail.wasReturned) then
            frame.expires:SetText(HIGHLIGHT_FONT_COLOR_CODE..CUI_DATASTORE_LABEL_DELETED..FONT_COLOR_CODE_CLOSE);
        else
            frame.expires:SetText(HIGHLIGHT_FONT_COLOR_CODE..string.format(CUI_DATASTORE_LABEL_SENT_BACK, sender)..FONT_COLOR_CODE_CLOSE);
        end
    end

    -- message text
    frame.messageText:SetText(HIGHLIGHT_FONT_COLOR_CODE..(selectedMail.messageText or "")..FONT_COLOR_CODE_CLOSE);

    -- items darstellen + tooltip
    local itemButton, itemButtonBorder, itemRarity;
    local r, g, b;
    for i=1, 12 do
        itemButton = _G["CleanUIDataStoreMailFrameItem"..i];

        if (selectedMail.hasItem and i <= selectedMail.hasItem) then
            itemButton:Show();
            SetItemButtonCount(itemButton, selectedMail.items[i].count);
            SetItemButtonTexture(itemButton, selectedMail.items[i].texture);
            itemButton.itemLink = selectedMail.items[i].itemLink;

            if (not itemButton.qualityBorder) then
                itemButtonBorder = itemButton:GetNormalTexture();
                itemButtonBorder:SetTexture();

                itemButton.qualityBorder = itemButton:CreateTexture("ARTWORK");
                itemButton.qualityBorder:SetAllPoints(itemButtonBorder);
            end

            if (itemButton.itemLink) then
                _, _, itemRarity = GetItemInfo(itemButton.itemLink);
            end

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

    frame.amountType:Show();
    CleanUIDataStoreMailFrameMoneyFrame:Show();

    if (selectedMail.money > 0) then
        frame.amountType:SetText(MONEY_COLON);
        MoneyFrame_Update("CleanUIDataStoreMailFrameMoneyFrame", selectedMail.money);
    elseif (selectedMail.CODAmount > 0) then
        frame.amountType:SetText(COD_AMOUNT);
        MoneyFrame_Update("CleanUIDataStoreMailFrameMoneyFrame", selectedMail.CODAmount);
    else
        frame.amountType:Hide();
        CleanUIDataStoreMailFrameMoneyFrame:Hide();
    end
end

function CleanUIDataStoreMailSubject_OnEnter(self)
end

function CleanUIDataStoreMailItem_OnEnter(self)
    if (not self.itemLink) then
        return;
    end

    GameTooltip_SetDefaultAnchor(GameTooltip, self);
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

    GameTooltip:SetHyperlink(self.itemLink);

    GameTooltip:Show();
end

function CleanUIDataStoreMailSubject_OnClick(self, button, down)
    selectedMail = self.data;

    CleanUI_DataStoreUIUpdateMailSubjectData();
    CleanUI_DataStoreUIUpdateMailSubjectSelection();
end
