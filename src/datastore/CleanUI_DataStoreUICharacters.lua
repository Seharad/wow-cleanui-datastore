-- localized names
PowerBarLabel = {};
PowerBarLabel["MANA"] = MANA;
PowerBarLabel["RAGE"] = RAGE;
PowerBarLabel["FOCUS"] = FOCUS;
PowerBarLabel["ENERGY"] = ENERGY;
PowerBarLabel["COMBO_POINTS"] = COMBO_POINTS;
PowerBarLabel["CHI"] = CHI;
PowerBarLabel["RUNES"] = RUNES;
PowerBarLabel["RUNIC_POWER"] = RUNIC_POWER;
PowerBarLabel["SOUL_SHARDS"] = SOUL_SHARDS_POWER;
PowerBarLabel["LUNAR_POWER"] = LUNAR_POWER;
PowerBarLabel["ECLIPSE"] = ECLIPSE;
PowerBarLabel["HOLY_POWER"] = HOLY_POWER;
PowerBarLabel["FURY"] = FURY;
PowerBarLabel["MAELSTROM"] = MAELSTROM;
PowerBarLabel["INSANITY"] = INSANITY;
PowerBarLabel["ALTERNATE"] = ALTERNATE;
PowerBarLabel["ARCANE_CHARGES"] = ARCANE_CHARGES;
PowerBarLabel["PAIN"] = PAIN;

local selectedCharacter = nil;
local sortKeyCharacters = "CHAR_LVL_DESC";

StaticPopupDialogs["CLEANUI_DELETE_GUID"] = {
    text = CUI_DATASTORE_DELETE_CHARACTER,
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        CleanUI_DataStoreUIDeleteData()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

function CleanUI_InitDataStoreUICharacters()
    -- character columns
    local characterNameColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreCharacterFrame, 185, NAME, "CHAR_NAME", nil);
    local characterLvlColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreCharacterFrame, 45, LEVEL_ABBR, "CHAR_LVL", characterNameColumn);
    local characterFactionColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreCharacterFrame, 40, "A/H", "CHAR_FACTION", characterLvlColumn);
    local characterMoneyColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreCharacterFrame, 120, MONEY, "CHAR_MONEY", characterFactionColumn);
    local characterAilColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreCharacterFrame, 55, "aIL", "CHAR_AIL", characterMoneyColumn);
    local characterLastOnlineColumn = CleanUI_DataStoreUI_CreateColumnHeader(CleanUIDataStoreCharacterFrame, 130, LASTONLINE, "CHAR_LASTONLINE", characterAilColumn);
end

function CleanUI_DataStoreUISortCharactersBy(sortKey)
    sortKeyCharacters = sortKey;
    CleanUI_DataStoreUIUpdateCharacterData();
end

function CleanUI_DataStoreUIGetSortCharactersBy()
    return sortKeyCharacters;
end

function CleanUI_DataStoreUI_SortCharacters(a, b)
    if (sortKeyCharacters == "CHAR_NAME_ASC") then
        return a.name < b.name;
    elseif  (sortKeyCharacters == "CHAR_NAME_DESC") then
        return a.name > b.name;
    end

    if (sortKeyCharacters == "CHAR_LVL_ASC") then
        return a.level < b.level;
    elseif  (sortKeyCharacters == "CHAR_LVL_DESC") then
        return a.level > b.level;
    end

    if (sortKeyCharacters == "CHAR_FACTION_ASC") then
        return a.faction < b.faction;
    elseif  (sortKeyCharacters == "CHAR_FACTION_DESC") then
        return a.faction > b.faction;
    end

    if (sortKeyCharacters == "CHAR_MONEY_ASC") then
        return a.money < b.money;
    elseif  (sortKeyCharacters == "CHAR_MONEY_DESC") then
        return a.money > b.money;
    end

    if (sortKeyCharacters == "CHAR_AIL_ASC") then
        return a.ail < b.ail;
    elseif  (sortKeyCharacters == "CHAR_AIL_DESC") then
        return a.ail > b.ail;
    end

    if (sortKeyCharacters == "CHAR_LASTONLINE_ASC") then
        return a.saveTime < b.saveTime;
    elseif  (sortKeyCharacters == "CHAR_LASTONLINE_DESC") then
        return a.saveTime > b.saveTime;
    end
end

function CleanUI_DataStoreUIUpdateCharacterData()
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
        data.faction = store.baseData.englishFaction;
        data.money = store.baseData.money;
        data.saveTime = store.baseData.saveTime;

        if (store.equipment ~= nil) then
            ilevel = 0;
            icount = 0;
            for pos, equipment in pairs(store.equipment) do
                if (equipment.itemLink) then
                    icount = icount + 1;
                    ilevel = ilevel + (CleanUI_GetActualItemLevel(equipment.itemLink) or 0);
                end
            end

            data.ail = ilevel/icount;

            data.professions = store.professions;

            tinsert(characters, data);
        end
    end

    table.sort(characters, function(a,b) return CleanUI_DataStoreUI_SortCharacters(a, b) end);

    local buttons = CleanUIDataStoreCharacterFrame.scrollFrame.buttons;

    local numEntries = #characters;
    local numButtons = #buttons;

    local scrollOffset = HybridScrollFrame_GetOffset(CleanUIDataStoreCharacterFrame.scrollFrame);
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
            act.faction:SetTexture("Interface\\BattlefieldFrame\\Battleground-"..act.data.faction);

            -- money
            act.money:SetText("|cffffffff"..GetCoinTextureString(act.data.money).."|r");

            -- ilevel
            act.ail:SetText(string.format("%.1f", act.data.ail));

            -- last online
            if (act.data.saveTime) then
                if (UnitGUID("player") == act.data.guid) then
                    act.lastOnline:SetText(GREEN_FONT_COLOR_CODE..GUILD_ONLINE_LABEL..FONT_COLOR_CODE_CLOSE);
                else
                    local onlineLabel = string.format(BNET_LAST_ONLINE_TIME, FriendsFrame_GetLastOnline(act.data.saveTime, false));
                    act.lastOnline:SetText(HIGHLIGHT_FONT_COLOR_CODE..onlineLabel..FONT_COLOR_CODE_CLOSE);
                end
            else
                act.lastOnline:SetText(GRAY_FONT_COLOR_CODE..UNKNOWN..FONT_COLOR_CODE_CLOSE);
            end

            -- this isn't a header, hide the header textures
            act:SetNormalTexture("");
            act:SetHighlightTexture("");

            if (act.data.guid == selectedCharacter) then
                -- reposition highlight frames
                CleanUIDataStoreHighlightFrame:SetParent(act);
                CleanUIDataStoreHighlightFrame:ClearAllPoints();
                CleanUIDataStoreHighlightFrame:SetPoint("TOPLEFT", act, "TOPLEFT", 0, 0);
                CleanUIDataStoreHighlightFrame:SetPoint("BOTTOMRIGHT", act, "BOTTOMRIGHT", 0, 0);
                CleanUIDataStoreHighlightFrame:Show();

                act.deleteButton:Show();
            else
                act.deleteButton:Hide();
            end
        else
            act:Hide();
        end

        displayedHeight = displayedHeight + buttonHeight;
    end

    HybridScrollFrame_Update(CleanUIDataStoreCharacterFrame.scrollFrame, numEntries * buttonHeight, displayedHeight);
end

function CleanUI_DataStoreUIDeleteDataYesNo()
    if (not selectedCharacter) then
        return;
    end

    StaticPopup_Show("CLEANUI_DELETE_GUID");
end

function CleanUI_DataStoreUIDeleteData()
    if (not selectedCharacter) then
        return;
    end

    CleanUIDS_DeleteData(selectedCharacter);

    selectedCharacter = nil;
    CleanUI_DataStoreUIUpdateCharacterData();
    CleanUI_DataStoreUIUpdateCharacterSelection();
end

local function professionsPercentage(min, max)
    if (min < max) then
        return HIGHLIGHT_FONT_COLOR_CODE..min.."/"..max..FONT_COLOR_CODE_CLOSE;
    else
        return GREEN_FONT_COLOR_CODE.."100 %"..FONT_COLOR_CODE_CLOSE;
    end
end

function CleanUI_DataStoreUIUpdateCharacterSelection()
    local info = CleanUIDataStoreCharacterFrame.info;

    if (not selectedCharacter) then
        info:Hide();
        return;
    end

    info:Show();

    local guid = selectedCharacter;
    local baseData = CleanUIDataStore.Characters[guid].baseData;

    -- race icon
    local raceEn = baseData.raceEn or "Orc";
    info.raceicon:SetTexture("interface\\AddOns\\CleanUI_DataStore\\skins\\races\\"..strlower(raceEn));
    info.classBackground:SetTexture("interface\\DressupFrame\\DressingRoom"..baseData.class.englishClass);
    info.classBackground:SetAlpha(0.7);

    -- name + title
    info.name:SetText(HIGHLIGHT_FONT_COLOR_CODE..baseData.pvpName..FONT_COLOR_CODE_CLOSE);

    -- level
    info.level:SetText(HIGHLIGHT_FONT_COLOR_CODE..baseData.level..FONT_COLOR_CODE_CLOSE);
    
    local xp = baseData.xp;
    local xpMax = baseData.xpMax;

    if (baseData.level < MAX_PLAYER_LEVEL and xp and xpMax and xp < xpMax) then
        info.xp:SetText(HIGHLIGHT_FONT_COLOR_CODE..BreakUpLargeNumbers(xp).." / "..BreakUpLargeNumbers(xpMax).."    ("..floor( (xp / xpMax) * 100 ).."%)"..FONT_COLOR_CODE_CLOSE);
        info.xp_label:Show();
        info.xp:Show();
    else
        info.xp_label:Hide();
        info.xp:Hide();
    end
 
    -- race/class/pvp
    local classColor = RAID_CLASS_COLORS[baseData.class.englishClass];
    local classColorText = string.format("ff%.2x%.2x%.2x", classColor.r * 255, classColor.g * 255, classColor.b * 255);
    local raceClassPvp = HIGHLIGHT_FONT_COLOR_CODE..baseData.race..FONT_COLOR_CODE_CLOSE..", |c"..classColorText..baseData.class.localizedClass..FONT_COLOR_CODE_CLOSE;

    if (baseData.pvpRank and baseData.pvpRank > 0) then
        local rankName, rankNumber = GetPVPRankInfo(baseData.pvpRank);
        raceClassPvp = raceClassPvp..", "..HIGHLIGHT_FONT_COLOR_CODE..rankName..FONT_COLOR_CODE_CLOSE;
    end

    info.race:SetText(raceClassPvp);

    -- bind location
    info.bindLocation:SetText(HIGHLIGHT_FONT_COLOR_CODE..baseData.locations.actLocation..FONT_COLOR_CODE_CLOSE);

    -- guild

    if (baseData.guild) then
        local guildName = baseData.guild.guildName or "<no guild>";
        local guildRankName = baseData.guild.guildRankName or "<no guild rank>";
        info.guild:SetText(HIGHLIGHT_FONT_COLOR_CODE..guildName.." ("..guildRankName..")"..FONT_COLOR_CODE_CLOSE);
    end

    -- health/power
    info.health_label:SetText(HEALTH..":");
    info.power_label:SetText(PowerBarLabel[baseData.powerTypeString]..":");

    local powerColor = PowerBarColor[baseData.powerTypeString];
    local powerColorText = string.format("ff%.2x%.2x%.2x", powerColor.r * 255, powerColor.g * 255, powerColor.b * 255);
    info.health:SetText("|cff00ff00"..BreakUpLargeNumbers(baseData.health).."|r");
    info.power:SetText("|c"..powerColorText..BreakUpLargeNumbers(baseData.power).."|r");

    -- stats
    info.intellect:SetText(HIGHLIGHT_FONT_COLOR_CODE..BreakUpLargeNumbers(baseData.stat.intellect.base)..FONT_COLOR_CODE_CLOSE);
    info.agility:SetText(HIGHLIGHT_FONT_COLOR_CODE..BreakUpLargeNumbers(baseData.stat.agility.base)..FONT_COLOR_CODE_CLOSE);
    info.stamina:SetText(HIGHLIGHT_FONT_COLOR_CODE..BreakUpLargeNumbers(baseData.stat.stamina.base)..FONT_COLOR_CODE_CLOSE);
    info.strength:SetText(HIGHLIGHT_FONT_COLOR_CODE..BreakUpLargeNumbers(baseData.stat.strength.base)..FONT_COLOR_CODE_CLOSE);

    -- professions
    local professions = CleanUIDataStore.Characters[guid].professions;

    -- first main profession

    if (professions.prof1.name) then
        info.profession1_label:SetText(professions.prof1.name..":");
        info.profession1:SetText(professionsPercentage(professions.prof1.skillLevel, professions.prof1.maxSkillLevel));
        info.profession1_icon:SetTexture(professions.prof1.icon);
        info.profession1_icon:SetTexCoord(0.1, 0.9, 0.1, 0.9);

        if (not info.profession1_frame) then
            info.profession1_frame = CreateFrame("Button");
            info.profession1_frame:SetPoint("TOPLEFT", info.profession1_label, "TOPLEFT", 0, 0);
            info.profession1_frame:SetPoint("BOTTOMRIGHT", info.profession1, "BOTTOMRIGHT", 0, 0);
    
            info.profession1_frame:EnableMouse(true);
        end
    
        info.profession1_frame:SetScript("OnClick", function() 
            C_GuildInfo.QueryGuildMemberRecipes(guid, professions.prof1.skillLine);
        end)
    end

    -- second main profession

    if (professions.prof2.name) then
        info.profession2_label:SetText(professions.prof2.name..":");
        info.profession2:SetText(professionsPercentage(professions.prof2.skillLevel, professions.prof2.maxSkillLevel));
        info.profession2_icon:SetTexture(professions.prof2.icon);
        info.profession2_icon:SetTexCoord(0.1, 0.9, 0.1, 0.9);

        if (not info.profession2_frame) then
            info.profession2_frame = CreateFrame("Button");
            info.profession2_frame:SetPoint("TOPLEFT", info.profession2_label, "TOPLEFT", 0, 0);
            info.profession2_frame:SetPoint("BOTTOMRIGHT", info.profession2, "BOTTOMRIGHT", 0, 0);
    
            info.profession2_frame:EnableMouse(true);
        end
    
        info.profession2_frame:SetScript("OnClick", function() 
            C_GuildInfo.QueryGuildMemberRecipes(guid, professions.prof2.skillLine);
        end)
    end

    -- cooking

    if (professions.cook.name) then
        info.cook_label:SetText(professions.cook.name..":");
        info.cook:SetText(professionsPercentage(professions.cook.skillLevel, professions.cook.maxSkillLevel));
        info.cook_icon:SetTexture(professions.cook.icon);
        info.cook_icon:SetTexCoord(0.1, 0.9, 0.1, 0.9);
    end

    -- fishing

    if (professions.fish.name) then
        info.fish_label:SetText(professions.fish.name..":");
        info.fish:SetText(professionsPercentage(professions.fish.skillLevel, professions.fish.maxSkillLevel));
        info.fish_icon:SetTexture(professions.fish.icon);
        info.fish_icon:SetTexCoord(0.1, 0.9, 0.1, 0.9);
    end

    -- archaeology

    if (professions.arch.name) then
        info.arch_label:SetText(professions.arch.name..":");
        info.arch:SetText(professionsPercentage(professions.arch.skillLevel, professions.arch.maxSkillLevel));
        info.arch_icon:SetTexture(professions.arch.icon);
        info.arch_icon:SetTexCoord(0.1, 0.9, 0.1, 0.9);
    end
end

function CleanUIDataStoreCharacter_OnEnter(self)
    GameTooltip_SetDefaultAnchor(GameTooltip, self);
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

    local guid = self.data.guid;
    local baseData = CleanUIDataStore.Characters[guid].baseData;

    -- name + race + class
    GameTooltip:SetText(CleanUIDS_GetFullName(baseData.name, baseData.race, baseData.class.englishClass).." ("..baseData.level..")");
    GameTooltip:AddLine(CleanUIDS_GetColoredClass(baseData.class.localizedClass, baseData.class.englishClass));
    GameTooltip:AddLine("(GUID: "..guid..")");
    GameTooltip:AddLine(" ");

    GameTooltip:AddDoubleLine(CUI_DS_ACT_LOCATION..":", HIGHLIGHT_FONT_COLOR_CODE..baseData.locations.actLocation..FONT_COLOR_CODE_CLOSE);
    GameTooltip:AddDoubleLine(CUI_DS_BIND_LOCATION..":", HIGHLIGHT_FONT_COLOR_CODE..baseData.locations.bindLocation..FONT_COLOR_CODE_CLOSE);
    GameTooltip:AddLine(" ");

    GameTooltip:AddDoubleLine(FRIENDS_LIST_REALM, HIGHLIGHT_FONT_COLOR_CODE..baseData.realm..FONT_COLOR_CODE_CLOSE);
    GameTooltip:AddLine(" ");

    -- guild
    if (baseData.guild) then
        local guildName = baseData.guild.guildName or "<no guild>";
        local guildRankName = baseData.guild.guildRankName or "<no guild rank>";
        GameTooltip:AddLine(HIGHLIGHT_FONT_COLOR_CODE..guildName.." ("..guildRankName..")"..FONT_COLOR_CODE_CLOSE);
        GameTooltip:AddLine(" ");
    end

    -- rank
    if (baseData.pvpRank and baseData.pvpRank > 0) then
        local rankName, rankNumber = GetPVPRankInfo(baseData.pvpRank);
        GameTooltip:AddDoubleLine(RANK_COLON, HIGHLIGHT_FONT_COLOR_CODE..rankName..FONT_COLOR_CODE_CLOSE);
        GameTooltip:AddLine(" ");
    end

    -- health/power
    local powerColor = PowerBarColor[baseData.powerTypeString];
    local powerColorText = string.format("ff%.2x%.2x%.2x", powerColor.r * 255, powerColor.g * 255, powerColor.b * 255);
    GameTooltip:AddDoubleLine(HEALTH..":", "|cff00ff00"..BreakUpLargeNumbers(baseData.health)..FONT_COLOR_CODE_CLOSE);
    if (PowerBarLabel[baseData.powerTypeString] ~= nil) then
        GameTooltip:AddDoubleLine(PowerBarLabel[baseData.powerTypeString]..":", "|c"..powerColorText..BreakUpLargeNumbers(baseData.power)..FONT_COLOR_CODE_CLOSE);
    end
    GameTooltip:AddLine(" ");

    -- stats

    GameTooltip:AddLine(STATS_LABEL);
    GameTooltip:AddDoubleLine(INTELLECT_COLON, HIGHLIGHT_FONT_COLOR_CODE..BreakUpLargeNumbers(baseData.stat.intellect.base)..FONT_COLOR_CODE_CLOSE);
    GameTooltip:AddDoubleLine(AGILITY_COLON, HIGHLIGHT_FONT_COLOR_CODE..BreakUpLargeNumbers(baseData.stat.agility.base)..FONT_COLOR_CODE_CLOSE);
    GameTooltip:AddDoubleLine(STAMINA_COLON, HIGHLIGHT_FONT_COLOR_CODE..BreakUpLargeNumbers(baseData.stat.stamina.base)..FONT_COLOR_CODE_CLOSE);
    GameTooltip:AddDoubleLine(STRENGTH_COLON, HIGHLIGHT_FONT_COLOR_CODE..BreakUpLargeNumbers(baseData.stat.strength.base)..FONT_COLOR_CODE_CLOSE);

    GameTooltip:AddLine(" ");

    -- professions
    local professions = CleanUIDataStore.Characters[guid].professions;

    GameTooltip:AddLine(TRADE_SKILLS..":");

    if (professions.prof1.name) then
        GameTooltip:AddDoubleLine(professions.prof1.name..":", HIGHLIGHT_FONT_COLOR_CODE.."("..professions.prof1.skillLevel.."/"..professions.prof1.maxSkillLevel..")"..FONT_COLOR_CODE_CLOSE);
    end

    if (professions.prof2.name) then
        GameTooltip:AddDoubleLine(professions.prof2.name..":", HIGHLIGHT_FONT_COLOR_CODE.."("..professions.prof2.skillLevel.."/"..professions.prof2.maxSkillLevel..")"..FONT_COLOR_CODE_CLOSE);
    end

    if (professions.cook.name) then
        GameTooltip:AddDoubleLine(professions.cook.name..":", HIGHLIGHT_FONT_COLOR_CODE.."("..professions.cook.skillLevel.."/"..professions.cook.maxSkillLevel..")"..FONT_COLOR_CODE_CLOSE);
    end

    if (professions.fish.name) then
        GameTooltip:AddDoubleLine(professions.fish.name..":", HIGHLIGHT_FONT_COLOR_CODE.."("..professions.fish.skillLevel.."/"..professions.fish.maxSkillLevel..")"..FONT_COLOR_CODE_CLOSE);
    end

    if (professions.arch.name) then
        GameTooltip:AddDoubleLine(professions.arch.name..":", HIGHLIGHT_FONT_COLOR_CODE.."("..professions.arch.skillLevel.."/"..professions.arch.maxSkillLevel..")"..FONT_COLOR_CODE_CLOSE);
    end


    GameTooltip:AddLine(" ");

    GameTooltip:Show();
end

function CleanUIDataStoreCharacter_OnClick(self, button, down)
    selectedCharacter = self.data.guid;

    CleanUI_DataStoreUIUpdateCharacterData();
    CleanUI_DataStoreUIUpdateCharacterSelection();
end

