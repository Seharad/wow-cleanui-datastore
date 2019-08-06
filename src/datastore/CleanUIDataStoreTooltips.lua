local data = nil;

function CleanUI_DataStore_Tooltip_OnTooltipSetItem(tooltip, ...)
    local name, link = tooltip:GetItem();
    
    if (name and link) then
        CleanUI_DataStore_ProcessItemTooltip(tooltip, name, link);
    else
        data = nil;
    end
end

function CleanUI_DataStore_Tooltip_SetCurrencyToken(tooltip, index)
    CleanUI_DataStore_ProcessCurrencyTooltip(index);
end

function CleanUI_DataStore_Tooltip_SetCurrencyByID(tooltip, id)
    --CleanUI_DataStore_ProcessCurrencyTooltip(tooltip, id);
end

function CleanUI_DataStore_Tooltip_SetCurrencyTokenByID(tooltip, id)
    --CleanUI_DataStore_ProcessCurrencyTooltip(tooltip, id);
end

function CleanUI_DataStore_Tooltip_SetBackpackToken(button, index)
    local name = GetBackpackCurrencyInfo(index);
    CleanUI_DataStore_ProcessCurrencyTooltipByName(name);
end

function CleanUI_DataStore_ProcessItemTooltip(tooltip, name, link)
    if (link) then
        if (not data or CleanUI_DataStore_GetIdFromLink(link) ~= CleanUI_DataStore_GetIdFromLink(data.link)) then
            CleanUI_DataStore_Tooltip_CollectItemData(link);
        end

        CleanUI_DataStore_Tooltip_AppendItemData(tooltip, link);
    else
        data = nil;
    end
end

function CleanUI_DataStore_Tooltip_AppendItemData(tooltip, link)
    if (not data or data.count == 0) then
        return;
    end

    local itemId = CleanUI_DataStore_GetIdFromLink(link);
    
    --cui_debug(itemId)
    -- TODO exceptions konfigurierbar machen
    if (not itemId
        or itemId == 6948 -- Ruhestein
        or itemId == 110560 -- Garnisonsruhestein
        or itemId == 140192 -- Dalaran Ruhestein
        or itemId == 109167 -- Findels Plünderang
        or itemId == 141605 -- Pfeife des Flugmeisters
        or itemId == 0 -- unknown
        ) then
        return;
    end
    
    local actCharFullName;
    local actCharInfo;
    local twinkInfo = {};

    local count = 0;
    local equipped = 0;
    local bags = 0;
    local bank = 0;
    local mail = 0;

    local fullname;

    for name, chardata in pairs(data.characters) do
        if (chardata.equipped) then
            equipped = chardata.equipped;
        end
        if (chardata.bags) then
            bags = chardata.bags;
        end
        if (chardata.bank) then
            bank = chardata.bank;
        end
        if (chardata.mail) then
            mail = chardata.mail;
        end

        count = equipped + bags + bank + mail;

        -- nur anzeigen, wenn ein Twink auch was hat
        if (count > 0) then
            -- Twinks
            fullname = CleanUIDS_GetFullName(name, chardata.race, chardata.class)

            local info = ""..count;
            local addInfo = nil;

            -- ausgerüstet
            if (equipped and equipped > 0) then
                if (not addInfo) then
                    addInfo = CUI_DS_EQUIPPED..": "..equipped;
                else
                    addInfo = addInfo..", "..CUI_DS_EQUIPPED..": "..equipped;
                end
            end

            -- Taschen
            if (bags and bags > 0) then
                if (not addInfo) then
                    addInfo = CUI_DS_BAGS..": "..bags;
                else
                    addInfo = addInfo..", "..CUI_DS_BAGS..": "..bags;
                end
            end

            -- Bank
            if (bank and bank > 0) then
                if (not addInfo) then
                    addInfo = CUI_DS_BANK..": "..bank;
                else
                    addInfo = addInfo..", "..CUI_DS_BANK..": "..bank;
                end
            end

            -- Mail
            if (mail and mail > 0) then
                if (not addInfo) then
                    addInfo = CUI_DS_MAIL..": "..mail;
                else
                    addInfo = addInfo..", "..CUI_DS_MAIL..": "..mail;
                end
            end

            -- Tooltip zusammensetzen
            if (addInfo) then
                info = info..HIGHLIGHT_FONT_COLOR_CODE.." ("..addInfo..")"..FONT_COLOR_CODE_CLOSE;
            end
            
            if (UnitName("player") == name) then
                actCharFullName = fullname;
                actCharInfo = info;
            else
                twinkInfo[fullname] = info;
            end
        end
    end

    -- act char
    tooltip:AddLine(" ");
    tooltip:AddDoubleLine(actCharFullName, actCharInfo);
 
    -- twinks
    local countTwinks = 0;
    for name, text in pairs(twinkInfo) do
        countTwinks = countTwinks + 1;
    end
    
    if (countTwinks > 0) then
        tooltip:AddLine(" ");
        tooltip:AddLine("Twinks:");
        for name, text in pairs(twinkInfo) do
            tooltip:AddDoubleLine(name, text);
        end
    end

    -- guild
    local countGuild = 0;
    for name, count in pairs(data.guildbanks) do
        if (count > 0) then
            countGuild = countGuild + count;
        end
    end

    if (countGuild > 0) then
        tooltip:AddLine(" ");
        tooltip:AddLine(GUILD_BANK..":");
    
        for name, count in pairs(data.guildbanks) do
            if (count > 0) then
                tooltip:AddDoubleLine(HIGHLIGHT_FONT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE, count);
            end
        end
    end

    tooltip:AddLine(" ");
    tooltip:AddDoubleLine(CUI_DS_COUNT_TOTAL..":", data.count);
end

function CleanUI_DataStore_Tooltip_CollectItemData(link)
    data = {};
    data.count = 0
    data.id = CleanUI_DataStore_GetIdFromLink(link);
    data.characters = {};
    data.guildbanks = {};

    local charname, bagdata;
    for guid, store in pairs(CleanUIDataStore.Characters) do
        -- characters
        charname = store.baseData.name;
        if (not data.characters[charname]) then
            data.characters[charname] = {};
        end

        data.characters[charname].race = store.baseData.race;
        data.characters[charname].class = store.baseData.class.englishClass;

        data.characters[charname].equipped = 0;
        data.characters[charname].bags = 0;
        data.characters[charname].bank = 0;
        data.characters[charname].mail = 0;

        -- equipped
        for pos, equipment in pairs(store.equipment) do
            if (equipment.itemLink and CleanUI_DataStore_GetIdFromLink(equipment.itemLink) == CleanUI_DataStore_GetIdFromLink(link)) then
                data.characters[charname].equipped = data.characters[charname].equipped + 1;
                data.count = data.count + 1;
            end
        end

        -- mail data
        if (store.mail) then
            for pm, maildata in pairs(store.mail) do
                if (maildata and maildata.items) then
                    for pos, itemdata in pairs(maildata.items) do
                        if (itemdata.itemLink and CleanUI_DataStore_GetIdFromLink(itemdata.itemLink) == CleanUI_DataStore_GetIdFromLink(link)) then
                            data.characters[charname].mail = data.characters[charname].mail + 1;
                            data.count = data.count + 1;
                        end
                    end
                end
            end
        end

        if (store.bags) then
            -- bags
            if (store.bags.bagitems) then
                for itemLink, bagdata in pairs(store.bags.bagitems) do
                    if (CleanUI_DataStore_GetIdFromLink(itemLink) == CleanUI_DataStore_GetIdFromLink(link)) then
                        data.characters[charname].bags = data.characters[charname].bags + bagdata.itemCount;
                        data.count = data.count + bagdata.itemCount;
                    end
                end
            end

            -- bank
            if (store.bags.bankitems) then
                for itemLink, bankdata in pairs(store.bags.bankitems) do
                    if (CleanUI_DataStore_GetIdFromLink(itemLink) == CleanUI_DataStore_GetIdFromLink(link)) then
                        data.characters[charname].bank = data.characters[charname].bank + bankdata.itemCount;
                        data.count = data.count + bankdata.itemCount;
                    end
                end
            end
        end
    end

    -- guild bank
    if (CleanUIDataStore.GuildBank) then
        for name, guilddata in pairs(CleanUIDataStore.GuildBank) do
            if (not data.guildbanks[name]) then
                data.guildbanks[name] = 0;
            end

            for t, tabdata in pairs(guilddata.tabs) do
                for itemLink, itemdata in pairs(tabdata.items) do
                    if (CleanUI_DataStore_GetIdFromLink(itemLink) == CleanUI_DataStore_GetIdFromLink(link)) then
                        data.guildbanks[name] = data.guildbanks[name] + itemdata.itemCount;
                        data.count = data.count + itemdata.itemCount;
                    end
                end
            end
        end
    end
end

function CleanUI_DataStore_ProcessCurrencyTooltip(id)
    local name = GetCurrencyListInfo(id);
    CleanUI_DataStore_ProcessCurrencyTooltipByName(name);
end

function CleanUI_DataStore_ProcessCurrencyTooltipByName(name)

    GameTooltip:AddLine(" ");    
    GameTooltip:AddLine("DataStore:");
    
    local charname, race, class, fullname;
    local currency;
    
    local summe = 0;

    for guid, store in pairs(CleanUIDataStore.Characters) do
        -- characters
        charname = store.baseData.name;
        race = store.baseData.race;
        class = store.baseData.class.englishClass;
        
        fullname = CleanUIDS_GetFullName(charname, race, class);
        
        if (CleanUIDataStore.Characters[guid].currency) then
            currency = CleanUIDataStore.Characters[guid].currency[name];
            
            if (currency and currency.count > 0) then
                local info = ""..currency.count;
                summe = summe + currency.count;
                GameTooltip:AddDoubleLine(fullname, info);
            end
        end
    end

    GameTooltip:AddLine(" ");
    GameTooltip:AddDoubleLine(CUI_DS_COUNT_TOTAL..":", summe);
    
    GameTooltip:Show();
end
