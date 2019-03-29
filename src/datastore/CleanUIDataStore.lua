local version = 1.2;

StaticPopupDialogs["CLEANUI_CHECK_MAILBOX"] = {
    text = CUI_DATASTORE_MAILBOX_WARNING,
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        CleanUI_DataStoreGotoMail()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

-- saved variables
CleanUIDataStore = {};
local guid = nil;

local inv_slots = {
    (GetInventorySlotInfo("HeadSlot")),
    (GetInventorySlotInfo("NeckSlot")),
    (GetInventorySlotInfo("ShoulderSlot")),
    (GetInventorySlotInfo("BackSlot")),
    (GetInventorySlotInfo("ChestSlot")),
    (GetInventorySlotInfo("WristSlot")),
    (GetInventorySlotInfo("HandsSlot")),
    (GetInventorySlotInfo("WaistSlot")),
    (GetInventorySlotInfo("LegsSlot")),
    (GetInventorySlotInfo("FeetSlot")),
    (GetInventorySlotInfo("Finger0Slot")),
    (GetInventorySlotInfo("Finger1Slot")),
    (GetInventorySlotInfo("Trinket0Slot")),
    (GetInventorySlotInfo("Trinket1Slot")),
    (GetInventorySlotInfo("MainHandSlot")),
    (GetInventorySlotInfo("SecondaryHandSlot")),
}

local slotNames = {
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

function CleanUI_InitDataStore()
    if (not CleanUIDataStore.version or CleanUIDataStore.version < version) then
        CleanUIDataStore = {};
        cui_debug("DataStore version upgraded.");
    end

    CleanUIDataStore.version = version;

    -- create data
    guid = UnitGUID("player");

    if (not CleanUIDataStore.Characters) then
        CleanUIDataStore.Characters = {};
    end

    if (not CleanUIDataStore.Characters[guid]) then
        CleanUIDataStore.Characters[guid] = {};
    end

    CleanUI_StartDelay(3, CleanUI_CollectCharacterData);
    CleanUI_StartDelay(3, CleanUI_CollectProfessionsData);
    CleanUI_StartDelay(5, CleanUI_DataStoreCheckData);

    CleanUI_StartDelay(3, CleanUI_RegisterDataStoreEvents);
    CleanUI_StartDelay(3, CleanUI_DataStoreHookEvents);
end

function CleanUI_DataStoreCheckData()
    local hasExpiringMail, expireDate, wasReturned, sender, expireDiff;
    local text, name, timestring;

    local showMessage = false;

    for lguid, store in pairs(CleanUIDataStore.Characters) do
        hasExpiringMail, expireDate, wasReturned, sender = CleanUIDS_HasExpiringMail(lguid);

        if (hasExpiringMail) then
            showMessage = true;
            expireDiff = expireDate - time();

            name = store.baseData.name.." ("..store.baseData.realm..")";

            timestring = FriendsFrame_GetLastOnline(expireDiff, true);

            sender = sender or "unknown";
            timestring = timestring or "unknown";

            if (expireDiff >= 0) then
                if (wasReturned) then
                    text = string.format(CUI_DATASTORE_MAILBOX_DELETE, sender, timestring);
                else
                    text = string.format(CUI_DATASTORE_MAILBOX_SEND_BACK, sender, timestring);
                end

                cui_info(HIGHLIGHT_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE);
            end
        end
    end

    if (showMessage) then
        StaticPopup_Show("CLEANUI_CHECK_MAILBOX");
    end
end

function CleanUI_DataStoreGotoMail()
    CleanUIDataStore_ToggleDataStoreUI();
    CleanUIDataStore_ToggleCategory(2);
end

function CleanUIDataStore_MouseOver(button)
    CleanUIDataStore_ShowTooltip(button);
end

function CleanUIDataStore_MouseOut(button)
    GameTooltip:FadeOut();
end

function CleanUIDataStore_ShowTooltip(button)
    GameTooltip_SetDefaultAnchor(GameTooltip, button);
    CleanUIDataStore_CreateTooltip(GameTooltip);
end

function CleanUIDataStore_CreateTooltip(tooltip)
    tooltip:SetText("|cffffffffDataStore|r");
    tooltip:Show();
end

function CleanUI_RegisterDataStoreEvents()
    local frame = CreateFrame("Frame");

    frame:RegisterEvent("ADDON_LOADED");
    
    frame:RegisterEvent("BAG_UPDATE");

    frame:RegisterEvent("GUILDBANKFRAME_OPENED");
    frame:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED");
    frame:RegisterEvent("PLAYERREAGENTBANKSLOTS_CHANGED");
    
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");

    frame:RegisterEvent("PLAYER_LEVEL_UP");
    frame:RegisterEvent("PLAYER_MONEY");

    frame:RegisterEvent("PLAYER_UPDATE_RESTING");

    frame:RegisterEvent("SKILL_LINES_CHANGED");

    frame:RegisterEvent("TRADE_UPDATE");

    frame:RegisterEvent("MAIL_INBOX_UPDATE");

    --frame:RegisterAllEvents();

    frame:HookScript("OnEvent", CleanUI_DataStoreOnEvent);
end

function CleanUI_DataStoreHookEvents()
    hooksecurefunc("ToggleCharacter", CleanUI_CollectCharacterData);
    hooksecurefunc("ContainerFrame_Update", CleanUI_CollectBagData);  
    hooksecurefunc("BankFrame_ShowPanel", CleanUI_CollectBagData);  

    GameTooltip:HookScript("OnTooltipSetItem", CleanUI_DataStore_Tooltip_OnTooltipSetItem);
    ItemRefTooltip:HookScript("OnTooltipSetItem", CleanUI_DataStore_Tooltip_OnTooltipSetItem);
    
    hooksecurefunc(GameTooltip, "SetCurrencyToken", CleanUI_DataStore_Tooltip_SetCurrencyToken);
    hooksecurefunc(GameTooltip, "SetCurrencyByID", CleanUI_DataStore_Tooltip_SetCurrencyByID);
    hooksecurefunc(GameTooltip, "SetCurrencyTokenByID", CleanUI_DataStore_Tooltip_SetCurrencyTokenByID);
    hooksecurefunc(GameTooltip, "SetBackpackToken", CleanUI_DataStore_Tooltip_SetBackpackToken);
end

function CleanUI_DataStoreOnEvent(self, event, ...)    
    if (event == "ADDON_LOADED") then
        local addonName = ...;
    end
        
    if (event == "PLAYER_LEVEL_UP" or
        event == "PLAYER_MONEY" or
        event == "PLAYER_UPDATE_RESTING") then
        CleanUI_CollectCharacterData();
    end

    if (event == "SKILL_LINES_CHANGED") then
        CleanUI_DataStoreCollectAll();
    end

    if (event == "BAG_UPDATE") then
        CleanUI_CollectBagData();
    end

    if (event == "TRADE_UPDATE") then
        CleanUI_CollectProfessionsData();
    end

    if (event == "MAIL_SHOW" or
        event == "MAIL_INBOX_UPDATE" or
        event == "MAIL_SEND_SUCCESS" or
        event == "MAIL_CLOSED") then
        CleanUI_CollectMailData();
    end

    if (event == "PLAYER_EQUIPMENT_CHANGED") then
        CleanUI_CollectEquipmentData();
    end

    if (event == "GUILDBANKFRAME_OPENED" or
        event == "GUILDBANKBAGSLOTS_CHANGED") then
        CleanUI_CollectGuildBankData();
    end

    if (event == "PLAYERREAGENTBANKSLOTS_CHANGED") then
        CleanUI_CollectBagData();
    end
end

function CleanUI_DataStoreCollectAll()
    CleanUI_CollectCharacterData()
    CleanUI_CollectBagData();
    CleanUI_CollectEquipmentData();
    CleanUI_CollectGuildBankData();
end

function CleanUI_CollectCharacterData()
    if (not CleanUIDataStore.Characters[guid]) then
        CleanUIDataStore.Characters[guid] = {};
    end

    CleanUIDataStore.Characters[guid].baseData = {};
    local data = CleanUIDataStore.Characters[guid].baseData;

    data.saveTime = time();

    -- base data
    data.name =  UnitName("player");
    data.realm = GetRealmName();
    data.level = UnitLevel("player");
    data.xp = UnitXP("player");
    data.xpMax = UnitXPMax("player");
    data.sex = UnitSex("player");

    local englishFaction, localizedFaction = UnitFactionGroup("player");
    data.englishFaction = englishFaction;
    data.localizedFaction = localizedFaction;

    local max_health = UnitHealthMax("player");
    local powerType, powerTypeString = UnitPowerType("player");
    local maxpower = UnitPowerMax("player" , powerType);
    data.health = max_health;
    data.powerType = powerType;
    data.powerTypeString = powerTypeString;
    data.power = maxpower;

    local ispvp = GetPVPDesired();
    data.ispvp = ispvp;

    local pvpName = UnitPVPName("player");
    --local pvpRank = UnitPVPRank("player");
    data.pvpName = pvpName;
    --data.pvpRank = pvpRank;

    local race, raceEn = UnitRace("player");
    data.race = race;
    data.raceEn = raceEn;

    local titleID = GetCurrentTitle();
    data.titleID = titleID;

    local guildName, guildRankName, guildRankIndex = GetGuildInfo("player");
    data.guild = {};
    data.guild.guildName = guildName;
    data.guild.guildRankName = guildRankName;
    data.guild.guildRankIndex = guildRankIndex;

    local localizedClass, englishClass, classIndex = UnitClass("player");
    data.class = {};
    data.class.localizedClass = localizedClass;
    data.class.englishClass = englishClass;
    data.class.classIndex = classIndex;

    data.locations = {};
    data.locations.bindLocation = GetBindLocation();
    data.locations.actLocation = GetMinimapZoneText();

    local money = GetMoney();
    data.money = money;

    local resting = IsResting();
    local xpExhaustion = GetXPExhaustion();
    local id, name, mult = GetRestState();
    data.resting = {};
    data.resting.resting = resting;
    data.resting.xpExhaustion = xpExhaustion;
    data.resting.id = id;
    data.resting.name = name;
    data.resting.mult = mult;

    data.stat = {};
    data.stat.strength = {};
    local base, stat, posBuff, negBuff = UnitStat("player", LE_UNIT_STAT_STRENGTH);
    data.stat.strength.base = base;
    data.stat.strength.stat = stat;
    data.stat.strength.posBuff = posBuff;
    data.stat.strength.negBuff = negBuff;

    data.stat.agility = {};
    base, stat, posBuff, negBuff = UnitStat("player", LE_UNIT_STAT_AGILITY);
    data.stat.agility.base = base;
    data.stat.agility.stat = stat;
    data.stat.agility.posBuff = posBuff;
    data.stat.agility.negBuff = negBuff;

    data.stat.intellect = {};
    base, stat, posBuff, negBuff = UnitStat("player", LE_UNIT_STAT_INTELLECT);
    data.stat.intellect.base = base;
    data.stat.intellect.stat = stat;
    data.stat.intellect.posBuff = posBuff;
    data.stat.intellect.negBuff = negBuff;

    data.stat.stamina = {};
    base, stat, posBuff, negBuff = UnitStat("player", LE_UNIT_STAT_STAMINA);
    data.stat.stamina.base = base;
    data.stat.stamina.stat = stat;
    data.stat.stamina.posBuff = posBuff;
    data.stat.stamina.negBuff = negBuff;

    CleanUI_CollectCurrencyData();
    CleanUI_CollectProfessionsData();
    CleanUI_CollectEquipmentData();
end

function CleanUI_CollectCurrencyData()
    if (not CleanUIDataStore.Characters[guid]) then
        CleanUIDataStore.Characters[guid] = {};
    end

    CleanUIDataStore.Characters[guid].currency = {};

    local listSize = GetCurrencyListSize();    
    local data;
    
    for i = 1, listSize do
        data = {};
        data.name, data.isHeader, data.isExpanded, data.isUnused, data.isWatched, data.count, icon, data.maximum, data.hasWeeklyLimit, data.currentWeeklyAmount = GetCurrencyListInfo(i);
        if (data.count and data.count > 0 and not data.isUnused) then
            CleanUIDataStore.Characters[guid].currency[data.name] = data;
        end
    end
end

function CleanUI_CollectProfessionsData()
    if (not CleanUIDataStore.Characters[guid]) then
        CleanUIDataStore.Characters[guid] = {};
    end

    CleanUIDataStore.Characters[guid].professions = {};

    local data = CleanUIDataStore.Characters[guid].professions;

    data.prof1 = {};
    data.prof2 = {};
    data.arch = {};
    data.fish = {};
    data.cook = {};
    data.firstAid = {};

    local prof1, prof2, arch, fish, cook, firstAid = GetProfessions();

    CleanUI_CollectProfessionsDataForSkill(data.prof1, prof1);
    CleanUI_CollectProfessionsDataForSkill(data.prof2, prof2);
    CleanUI_CollectProfessionsDataForSkill(data.arch, arch);
    CleanUI_CollectProfessionsDataForSkill(data.fish, fish);
    CleanUI_CollectProfessionsDataForSkill(data.cook, cook);
    CleanUI_CollectProfessionsDataForSkill(data.firstAid, firstAid);
end

function CleanUI_CollectProfessionsDataForSkill(data, index)
    if (index) then
        data.name, data.icon, data.skillLevel, data.maxSkillLevel, data.numAbilities, data.spelloffset, data.skillLine, data.skillModifier = GetProfessionInfo(index);
    end
end

function CleanUI_CollectEquipmentData()
    if (not CleanUIDataStore.Characters[guid]) then
        CleanUIDataStore.Characters[guid] = {};
    end

    CleanUIDataStore.Characters[guid].equipment = {};
    local data = CleanUIDataStore.Characters[guid].equipment;

    local slotId;
    local itemLink, quality, texture, gem1, gem2, gem3, currentDurability, maximumDurability;
    for i = 1, #inv_slots do
        slotId = inv_slots[i];
        data[i] = {};

        data[i].name = slotNames[i];

        itemLink = GetInventoryItemLink("player", slotId);
        data[i].itemLink = itemLink;

        currentDurability, maximumDurability = GetInventoryItemDurability(slotId);
        data[i].currentDurability = currentDurability;
        data[i].maximumDurability = maximumDurability;
    end
end

function CleanUI_CollectMailData()
    if (not CleanUIDataStore.Characters[guid]) then
        CleanUIDataStore.Characters[guid] = {};
    end

    CleanUIDataStore.Characters[guid].mail = {};
    local data = CleanUIDataStore.Characters[guid].mail;

    -- collect mail data
    local numMessages, totalMessages = GetInboxNumItems();

    local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM;
    local messageText;
    local itemName, itemID, itemTexture, itemCount, itemQuality, itemLink;

    local expireDate;
    local currentTime = time();

    for i = 1, totalMessages do
        packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft, hasItem, wasRead, wasReturned, textCreated, canReply, isGM = GetInboxHeaderInfo(i);
        messageText = GetInboxText(i);
        expireDate = currentTime + (daysLeft * 24 * 60 * 60);

        data[i] = {};

        data[i].packageIcon = packageIcon;
        data[i].stationeryIcon = stationeryIcon;
        data[i].sender = sender;
        data[i].subject = subject;
        data[i].messageText = messageText;
        data[i].money = money;
        data[i].CODAmount = CODAmount;
        data[i].expireDate = expireDate;
        data[i].hasItem = hasItem;
        data[i].wasRead = wasRead;
        data[i].wasReturned = wasReturned;
        data[i].textCreated = textCreated;
        data[i].canReply = canReply;
        data[i].isGM = isGM;

        if (data[i].hasItem) then
            data[i].items = {};

            for j = 1, data[i].hasItem do
                data[i].items[j] = {};

                itemName, itemID, itemTexture, itemCount = GetInboxItem(i, j);
                itemLink = GetInboxItemLink(i, j);

                data[i].items[j].name = itemName;
                data[i].items[j].texture = itemTexture;
                data[i].items[j].count = itemCount;
                data[i].items[j].itemLink = itemLink;
            end
        end
    end
end

function CleanUI_CollectBagData()
    if (not CleanUIDataStore.Characters[guid]) then
        CleanUIDataStore.Characters[guid] = {};
    end

    -- nicht resetten, sonst sind die Bankdaten weg
    if (not CleanUIDataStore.Characters[guid].bags) then
        CleanUIDataStore.Characters[guid].bags = {};
    end

    local data = CleanUIDataStore.Characters[guid].bags;

    -- nicht resetten, sonst sind die Bankdaten weg
    if (not data.usage) then
        data.usage = {};
    end

    local numberOfSlots, numberOfFreeSlots;
    local bagName;

    -- bags
    data.bagitems = {};
    for id = 0, 4 do
        numberOfSlots, numberOfFreeSlots = CleanUI_AddBagData(id, _G["ContainerFrame"..(id + 1)], data.bagitems);
        bagName = GetBagName(id);
        CleanUI_AddBagUsage(numberOfSlots, numberOfFreeSlots, bagName, data.usage, "ContainerFrame"..(id + 1));
    end

    if (BankFrame:IsVisible()) then
        --bank bags
        data.bankitems = {};
        for id = 5, 11 do
            numberOfSlots, numberOfFreeSlots = CleanUI_AddBagData(id, _G["ContainerFrame"..(id + 1)], data.bankitems);
            bagName = GetBagName(id);
            CleanUI_AddBagUsage(numberOfSlots, numberOfFreeSlots, bagName, data.usage, "ContainerFrame"..(id + 1));
        end

        -- bank
        numberOfSlots, numberOfFreeSlots = CleanUI_AddBagData(BANK_CONTAINER, BankFrame, data.bankitems);
        bagName = "Bank";
        CleanUI_AddBagUsage(numberOfSlots, numberOfFreeSlots, bagName, data.usage, "BankFrame");
        
        CleanUI_CollectReagentBankData();
    end
end

function CleanUI_CollectReagentBankData()   
    local data = CleanUIDataStore.Characters[guid].bags;
         
    -- reagent bank
    local itemButton;
    for slot=1, 98, 1 do
        itemButton = ReagentBankFrame["Item"..(slot)];
        CleanUI_AddReagent(data.bankitems, itemButton);
    end
end

function CleanUI_AddReagent(data, button)
    if (not button) then
        return;
    end

    local inventoryID = button:GetInventorySlot();
    
    local itemLink = GetInventoryItemLink("player", inventoryID);
    
    local itemTexture, itemCount;
    if (itemLink) then
        itemTexture = GetInventoryItemTexture("player", inventoryID) 
        itemCount = GetInventoryItemCount("player", inventoryID);

        if (data[itemLink]) then
            data[itemLink].itemCount = data[itemLink].itemCount + itemCount;
        else
            data[itemLink] = {};
            data[itemLink].itemCount = itemCount;
        end
    end
end

function CleanUI_AddBagUsage(numberOfSlots, numberOfFreeSlots, bagName, data, id)
    data[id] = {};
    data[id].bagName = bagName;
    data[id].numberOfSlots = numberOfSlots;
    data[id].numberOfFreeSlots = numberOfFreeSlots;
end

function CleanUI_AddBagData(id, container, data)
    local numberOfSlots, numberOfFreeSlots, itemLink, itemName, itemTexture, itemCount;

    if (container) then
        numberOfSlots = GetContainerNumSlots(id);
        numberOfFreeSlots = GetContainerNumFreeSlots(id);

        for slot=1, numberOfSlots, 1 do
            itemLink = GetContainerItemLink(id, slot);

            if (itemLink) then
                itemTexture, itemCount = GetContainerItemInfo(id, slot);

                if (data[itemLink]) then
                    data[itemLink].itemCount = data[itemLink].itemCount + itemCount;
                else
                    data[itemLink] = {};
                    data[itemLink].itemCount = itemCount;
                end
            end
        end
    end

    return numberOfSlots, numberOfFreeSlots;
end

function CleanUI_CollectGuildBankData()
    if (not CleanUIDataStore["GuildBank"]) then
        CleanUIDataStore["GuildBank"] = {};
    end

    if (not GuildBankFrame or not GuildBankFrame:IsVisible()) then
        return;
    end

    local gbdata = CleanUIDataStore["GuildBank"];

    local guildName = GetGuildInfo("player");

    if (not gbdata[guildName]) then
        gbdata[guildName] = {};
    end

    local data = gbdata[guildName];

    if (not data.tabs) then
        data.tabs = {};
    end

    data.money = GetGuildBankMoney();
    
    for tab = 1, 10 do
        local name, icon, isViewable, canDeposit, numWithdrawals, remainingWithdrawals = GetGuildBankTabInfo(tab);
       
        if (name) then        
            local itemLink, itemTexture, itemCount;
            if (isViewable) then
                data.tabs[tab] = {};
                data.tabs[tab].name = name;
                data.tabs[tab].icon = icon;
                data.tabs[tab].text = GetGuildBankText(tab);
        
                data.tabs[tab].items = {};
        
                for slot=1, 98 do
                    itemLink = GetGuildBankItemLink(tab, slot);
                    itemTexture, itemCount = GetGuildBankItemInfo(tab, slot);
        
                    if (itemLink) then
                        if (data.tabs[tab].items[itemLink]) then
                            data.tabs[tab].items[itemLink].itemCount = data.tabs[tab].items[itemLink].itemCount + itemCount;
                        else
                            data.tabs[tab].items[itemLink] = {};
                            data.tabs[tab].items[itemLink].itemCount = itemCount;
                        end
                    end
                end
            end
        end
    end
end

function CleanUI_DataStore_GetIdFromLink(link)
    if (link) then
        return tonumber(link:match("item:(%d+)"));
    end
end

function CleanUIDS_DeleteData(guid)
    CleanUIDataStore.Characters[guid] = nil;
end

-- data access
function CleanUIDS_GetAllMoney()
    local money = 0;

    local baseData;
    for guid, data in pairs(CleanUIDataStore.Characters) do
        baseData = CleanUIDataStore.Characters[guid].baseData;

        if (baseData) then
            money = money + baseData.money;
        end
    end

    return money;
end

function CleanUIDS_GetGuildNames()
    local gbdata = CleanUIDataStore["GuildBank"];

    local names = {};

    if (not gbdata) then
        return names;
    end

    for name, data in pairs(gbdata) do
        tinsert(names, name);
    end

    return names;
end

function CleanUIDS_HasExpiringMail(guid)
    local expires = nil;
    local wasReturned = nil;

    local data = CleanUIDataStore.Characters[guid].mail;
    local check;

    if (data) then
        local expireDiff;
        for i = 1, #data do
            check = CleanUIDS_CheckMail(data[i]);

            if (check) then
                return 1, data[i].expireDate, data[i].wasReturned, data[i].sender;
            end
        end
    end

    return nil;
end

function CleanUIDS_CountExpiringMail(guid)
    local expires = nil;
    local wasReturned = nil;

    local data = CleanUIDataStore.Characters[guid].mail;

    local countExpiring = 0;
    local countExpired = 0;

    local check;

    if (data) then
        local expireDiff;
        for i = 1, #data do
            check = CleanUIDS_CheckMail(data[i]);

            if (check == 1) then
                countExpiring = countExpiring + 1;
            elseif (check == 2) then
                countExpired = countExpired + 1;
            end
        end
    end

    return countExpiring, countExpired;
end

function CleanUIDS_CheckMail(data)
    local expireDiff = data.expireDate - time();

    if (expireDiff <= 0) then
        return 2;
    end

    if (expireDiff > 0 and expireDiff < (5 * 24 * 60 * 60)) then -- f�nf Tage
        return 1;
    end

    return nil;
end

function CleanUIDS_GetFullName(name, race, class)
    local fullname = name.." ("..race..")";
    classColor = RAID_CLASS_COLORS[class];
    classColorText = string.format("ff%.2x%.2x%.2x", classColor.r * 255, classColor.g * 255, classColor.b * 255);
    return "|c"..classColorText..fullname.."|r";
end

function CleanUIDS_GetColoredClass(localizedClass, class)
    local fullname = localizedClass;
    classColor = RAID_CLASS_COLORS[class];
    classColorText = string.format("ff%.2x%.2x%.2x", classColor.r * 255, classColor.g * 255, classColor.b * 255);
    return "|c"..classColorText..fullname.."|r";
end

function CleanUIDS_GetBagItemTypes(guid)
    local itemTypes = {};
    tinsert(itemTypes, ALL);

    local bags = CleanUIDataStore.Characters[guid].bags;

    if (not bags) then
        return itemTypes;
    end

    local data = CleanUIDS_GetBagDataSortedByType(guid);

    for itemType, data in pairs(data) do
        tinsert(itemTypes, itemType);
    end

    return itemTypes;
end

function CleanUIDS_GetBagDataSortedByType(guid)
    local bagdata = {};

    local bags = CleanUIDataStore.Characters[guid].bags;

    if (not bags) then
        return bagdata;
    end

    if (bags.bagitems) then
        for itemLink, data in pairs(bags.bagitems) do
            CleanUIDS_AppendItemByType(bagdata, itemLink, data);
        end
    end

    if (bags.bankitems) then
        for itemLink, data in pairs(bags.bankitems) do
            CleanUIDS_AppendItemByType(bagdata, itemLink, data);
        end
    end

    return bagdata;
end

function CleanUIDS_GetGuildBankItemTypes(guildname)
    local itemTypes = {};
    tinsert(itemTypes, ALL);

    local data = CleanUIDS_GetGuildBankDataSortedByType(guildname);

    for itemType, data in pairs(data) do
        tinsert(itemTypes, itemType);
    end

    return itemTypes;
end

function CleanUIDS_GetGuildBankDataSortedByType(guildname)
    local guilddata = {};

    local tabs = CleanUIDataStore["GuildBank"][guildname].tabs;

    if (not tabs) then
        return guilddata;
    end

    for i, tabdata in ipairs(tabs) do
        for itemLink, data in pairs(tabdata.items) do
            CleanUIDS_AppendItemByType(guilddata, itemLink, data);
        end
    end

    return guilddata;
end

function CleanUIDS_AppendItemByType(table, itemLink, data)
    local itemTexture = data.itemTexture;
    local itemCount = data.itemCount;

    local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType = GetItemInfo(itemLink);

    if (not itemName) then
        return;
    end

    if (not table[itemType]) then
        table[itemType] = {};
    end

    local typeTable = table[itemType];

    if (typeTable[itemLink]) then
        typeTable[itemLink].itemCount = typeTable[itemLink].itemCount + itemCount;
    else
        typeTable[itemLink] = {};

        typeTable[itemLink].itemTexture = itemTexture;
        typeTable[itemLink].itemCount = itemCount;
    end
end

function CleanUIDS_SearchByName(name)
    local foundData = {};

    if (not name or name=="") then
        return foundData;
    end

    local data = CleanUIDS_SearchByName_CollectData(name);

    local index = 1;
    local itemLink;

    for id, count in pairs(data) do
        _, itemLink = GetItemInfo(id);
        foundData[index] = { link=itemLink, count=count};
        index = index + 1;
    end

    return foundData;
end

function CleanUIDS_SearchByName_CollectData(name)
    data = {};

    local id, charname, bagdata, foundName;

    for guid, store in pairs(CleanUIDataStore.Characters) do
        -- characters
        charname = store.baseData.name;

        -- equipped
        for pos, equipment in pairs(store.equipment) do
            if (equipment.itemLink) then
                foundName = GetItemInfo(equipment.itemLink);

                if (foundName and findPatternInString(foundName, name)) then
                    id = CleanUI_DataStore_GetIdFromLink(equipment.itemLink);

                    if (data[id]) then
                        data[id] = data[id] + 1;
                    else
                        data[id] = 1;
                    end
                end
            end
        end

        -- mail data
        if (store.mail) then
            for pm, maildata in pairs(store.mail) do
                if (maildata and maildata.items) then
                    for pos, itemdata in pairs(maildata.items) do
                        if (itemdata.itemLink) then
                            foundName = GetItemInfo(itemdata.itemLink);

                            if (foundName and findPatternInString(foundName, name)) then
                                id = CleanUI_DataStore_GetIdFromLink(itemdata.itemLink);

                                if (data[id]) then
                                    data[id] = data[id] + 1;
                                else
                                    data[id] = 1;
                                end
                            end
                        end
                    end
                end
            end
        end

        if (store.bags) then
            -- bags
            if (store.bags.bagitems) then
                for itemLink, bagdata in pairs(store.bags.bagitems) do
                    foundName = GetItemInfo(itemLink);

                    if (foundName and findPatternInString(foundName, name)) then
                        id = CleanUI_DataStore_GetIdFromLink(itemLink);

                        if (data[id]) then
                            data[id] = data[id] + bagdata.itemCount;
                        else
                            data[id] = bagdata.itemCount;
                        end
                    end
                end
            end

            -- bank
            if (store.bags.bankitems) then
                for itemLink, bankdata in pairs(store.bags.bankitems) do
                    foundName = GetItemInfo(itemLink);

                    if (foundName and findPatternInString(foundName, name)) then
                        id = CleanUI_DataStore_GetIdFromLink(itemLink);

                        if (data[id]) then
                            data[id] = data[id] + bankdata.itemCount;
                        else
                            data[id] = bankdata.itemCount;
                        end
                    end
                end
            end
        end
    end

    -- guild bank
    if (CleanUIDataStore.GuildBank) then
        for name, guilddata in pairs(CleanUIDataStore.GuildBank) do
            for t, tabdata in pairs(guilddata.tabs) do
                for itemLink, itemdata in pairs(tabdata.items) do
                    foundName = GetItemInfo(itemLink);

                    if (foundName and findPatternInString(foundName, name)) then
                        id = CleanUI_DataStore_GetIdFromLink(itemLink);

                        if (data[id]) then
                            data[id] = data[id] + itemdata.itemCount;
                        else
                            data[id] = itemdata.itemCount;
                        end
                    end
                end
            end
        end
    end

    return data;
end

function findPatternInString(str, ptr)
    str = string.lower(str);
    ptr = string.lower(ptr);
    return string.find(str, ptr);
end

function CleanUI_GetActualItemLevel(itemlink)
    local effectiveILvl, isPreview, baseILvl = GetDetailedItemLevelInfo(itemlink);
    return effectiveILvl;
end
