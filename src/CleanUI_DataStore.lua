-- functions

function CleanUIDataStore_OnLoad()
    local delay = 0.1;

    CleanUI_StartDelay(delay, CleanUI_InitDataStore);
    CleanUI_StartDelay(delay, CleanUI_InitDataStoreUI);
end

CleanUIDataStore_OnLoad();
