-- demon timers by taters
local aura_env = aura_env;
local conf = aura_env.config;
local debug = conf.debug;
aura_env.summonTable = 
{
    -- ID,      duration (s),  name,                        type,                       icon,               order,                              enabled,                        hpMod,         hpValue
    [265187] = {duration = 15, name = "Tyrant",             type = nil,                 icon = nil,         order = tonumber(conf.tyrantOrder), enabled = conf.tyrantEnabled,   hpMod = nil },
    [104317] = {duration = 40, name = "Wild Imp",           type = nil,                 icon = 615097,      order = tonumber(conf.impOrder),    enabled = conf.impEnabled,      hpMod = 0.15 }, -- Regular Imp
    [279910] = {duration = 20, name = "Wild Imp",           type = 'Inner Demon Imp',   icon = 615097,      order = tonumber(conf.impOrder),    enabled = conf.impEnabled,      hpMod = 0.15 }, -- Inner Demons Imp
    [193332] = {duration = 12, name = "Dreadstalker",       type = nil,                 icon = nil,         order = tonumber(conf.dsOrder),     enabled = conf.dsEnabled,       hpMod = 0.4 },
    [264119] = {duration = 15, name = "Vilefiend",          type = nil,                 icon = nil,         order = tonumber(conf.vfOrder),     enabled = conf.vfEnabled,       hpMod = 0.75 },
    -- Inner Demons / Nether Portal
    [268001] = {duration = 15, name = "Ur'zul",             type = 'Misc',              icon = nil,         order = tonumber(conf.miscOrder),   enabled = conf.miscEnabled,     hpMod = 0.75 },
    [267994] = {duration = 15, name = "Shivarra",           type = 'Misc',              icon = nil,         order = tonumber(conf.miscOrder),   enabled = conf.miscEnabled,     hpMod = 0.75 },
    [267988] = {duration = 15, name = "Vicious Hellhound",  type = 'Misc',              icon = nil,         order = tonumber(conf.miscOrder),   enabled = conf.miscEnabled,     hpMod = 0.75 },
    [267992] = {duration = 15, name = "Bilescourge",        type = 'Misc',              icon = nil,         order = tonumber(conf.miscOrder),   enabled = conf.miscEnabled,     hpMod = 0.75 }, 
    [267991] = {duration = 15, name = "Void Terror",        type = 'Misc',              icon = nil,         order = tonumber(conf.miscOrder),   enabled = conf.miscEnabled,     hpMod = 0.75 },
    [267995] = {duration = 15, name = "Wrathguard",         type = 'Misc',              icon = nil,         order = tonumber(conf.miscOrder),   enabled = conf.miscEnabled,     hpMod = 0.75 },
    [267987] = {duration = 15, name = "Illidari Satyr",     type = 'Misc',              icon = 1413871,     order = tonumber(conf.miscOrder),   enabled = conf.miscEnabled,     hpMod = 0.75 },
    [267996] = {duration = 15, name = "Darkhound",          type = 'Misc',              icon = nil,         order = tonumber(conf.miscOrder),   enabled = conf.miscEnabled,     hpMod = 0.75 },
    [267989] = {duration = 15, name = "Eye of Gul'dan",     type = 'Misc',              icon = nil,         order = tonumber(conf.miscOrder),   enabled = conf.miscEnabled,     hpMod = 0.75 },
    [267986] = {duration = 15, name = "Prince Malchezaar",  type = 'Misc',              icon = nil,         order = tonumber(conf.miscOrder),   enabled = conf.miscEnabled,     hpMod = 0.75 },
    -- Grimoire: Felguard
    [111898] = {duration = 17, name = "Grimoire: Felguard", type = nil,                 icon = nil,         order = tonumber(conf.fgOrder),     enabled = conf.fgEnabled,       hpMod = 0.75 },
    -- PvP (Observer / Fel Lord)
    [201996] = {duration = 20, name = "Observer",           type = 'PvP',               icon = nil,         order = tonumber(conf.pvpOrder),    enabled = conf.pvpEnabled,      hpMod = nil,    hpValue = 2678 },
    [212459] = {duration = 15, name = "Fel Lord",           type = 'PvP',               icon = nil,         order = tonumber(conf.pvpOrder),    enabled = conf.pvpEnabled,      hpMod = nil,    hpValue = 11791 },
    -- Nether Portal
    [267218] = {duration = 15, name = "Nether Portal",      type = nil,                 icon = nil,         order = tonumber(conf.npOrder),     enabled = conf.npEnabled,       hpMod = nil },
    -- Subjugation
    [1098] =   {duration = 300, name = "Subjugated",        type = nil,                 icon = 136154,      order = tonumber(conf.subOrder),    enabled = conf.subEnabled,      hpMod = nil },   
    -- Miscellaneous (Non-Summons)
    ['tyrant'] = 265187,
    ['HoGImp'] = 104317,
    ['IDImp'] = 279910,
};
local summonTable = aura_env.summonTable;

aura_env.extensionBlacklist = 
{
    [summonTable[265187].name] = true,
    [summonTable[267218].name] = true,
    [summonTable[1098].name] = true,    
}

-- misc variable definitions
aura_env.demons = {};
aura_env.imps = {};
aura_env.activeImps = {};
aura_env.impCasts = UnitLevel'player' >= 56 and 6 or 5;
aura_env.impCost = UnitLevel'player' >= 56 and 16 or 20;
aura_env.impTimeThresh = tonumber(conf.delay);
aura_env.despawnDelay = conf.despawnDelay;
aura_env.useCastTime = conf.useCastTime;
local showFiller = conf.showFiller;
local oocOnly = conf.nocombatOnly;
local impTimeThresh = aura_env.impTimeThresh;
local impDelay = conf.summonDelay;
local statsEnabled = conf.printStats;
local impClumps = {}; 
-- Handing for the anima power 'Soul Platter', which 
-- makes tyrant last 100% longer. Note that the
-- extension time remains the same at 15s.
aura_env.tyrantAnimaPower = 320936; -- anima power spell ID
aura_env.tyrantBaseDuration = 15;  -- base duration of tyrant is 15s

local function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '\n    ['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '\n} '
    else
       return tostring(o)
    end
 end

local resetStats = function()
    if not statsEnabled then return; end
    aura_env.stats = 
    {
        impsImploded = 0,
        totalFirebolts = 0,
        totalDemonsSummoned = 0,
        totalTyrantExtension = 0,
        totalTyrantFirebolts = 0,
        demons = {},
        hornedNightmareProcs = 0,
        hogs = 0,
    }
end
resetStats();

aura_env.addToStats = function(entry)
    if not statsEnabled then return; end
    aura_env.stats.demons[entry.name] = aura_env.stats.demons[entry.name] or 0;
    aura_env.stats.demons[entry.name] = aura_env.stats.demons[entry.name] + 1;
    aura_env.stats.totalDemonsSummoned = aura_env.stats.totalDemonsSummoned + 1;
    
    if entry.name == 'Dreadstalker' then 
        aura_env.stats.demons[entry.name] = aura_env.stats.demons[entry.name] + 1;
        aura_env.stats.totalDemonsSummoned = aura_env.stats.totalDemonsSummoned + 1;
    end
end

aura_env.handleStats = function(event, boss)    
    if not statsEnabled then return; end
    local mode = conf.printStatsMode;
    
    if (event == 'ENCOUNTER_START' or (mode == 2 and event == 'PLAYER_REGEN_DISABLED')) then        
        resetStats();
    elseif (event == 'ENCOUNTER_END' or (mode == 2 and event == 'PLAYER_REGEN_ENABLED')) then
        local s = aura_env.stats;
        if s.totalDemonsSummoned > 0 then
            local str = format("|cff37ff00Demon Timer Stats: %s|r\n", aura_env.stats.encounter or "");
            if s.totalTyrantExtension > 0 then str = str .. format('|cffffcc00Total Tyrant Extension Time:|r %i seconds\n', s.totalTyrantExtension); end          
            if s.totalFirebolts > 0 then str = str ..  format('|cffffcc00Total Fel Firebolts:|r %i\n', s.totalFirebolts) end
            if s.totalTyrantFirebolts > 0 then str = str .. format('|cffffcc00Total Fel Firebolts During Tyrant:|r %i (%.1f%%)\n', s.totalTyrantFirebolts, s.totalTyrantFirebolts / s.totalFirebolts * 100) end
            if s.impsImploded > 0 then str = str .. format('|cffffcc00Imps Imploded:|r %i\n', s.impsImploded) end
            if s.hornedNightmareProcs > 0 then str = str .. format('|cffffcc00Horned Nightmare Procs:|r %i (%.1f%% of HoGs)\n', s.hornedNightmareProcs, s.hornedNightmareProcs / s.hogs * 100) end
            if s.totalDemonsSummoned > 0 then str = str .. format('|cffffcc00Total Demons Summoned:|r %i\n', s.totalDemonsSummoned) end
            
            local sortedDemons = {};
            for k,v in pairs(aura_env.stats.demons) do
                table.insert(sortedDemons, {k,v});
            end
            
            table.sort(sortedDemons, function(a,b) return a[2] > b[2] end);
            
            for _,v in ipairs(sortedDemons) do
                str = str .. format('   |cffffcc00%s:|r %i (%.1f%%)\n', v[1], v[2], v[2] / s.totalDemonsSummoned * 100);
            end
            
            print(str);
        end
    end
end

-- getTyrantDuration : function to get tyrant duration, based 
-- off of whether you have the anima power or not that doubles it
aura_env.getTyrantDuration = function()
    local x = { GetPlayerAuraBySpellID(aura_env.tyrantAnimaPower); } -- check if the anima power is active
    local dur; -- placeholder variable
    if x and x[3] then -- if buff is active and stacks exist
        dur = aura_env.tyrantBaseDuration * 2; -- buff is active, duration is ~~base * stacks~~ it doesnt stack
    else
        dur = aura_env.tyrantBaseDuration; -- buff is not active, return default duration
    end
    aura_env.summonTable[265187].duration = dur;
end

-- print : function to print a message, however
-- only print when the debug variable is flagged
aura_env.print = function(...)
    if debug then print(...) end -- if debug variable is set to true in options
end

-- updateIndividualDemon : function to update a specific demon's state
aura_env.updateIndividualDemon = function(states, guid)
    local v = aura_env.demons[guid]; -- index demons with guid
    if not v then return; end -- demon is not valid, return early
    local expirationTime = v.expirationTime; -- expirationTime of the demon
    local time = GetTime(); -- current time
    
    if time >= expirationTime then -- if the demon should have expired
        aura_env.demons[guid] = nil; -- delete demon from table
        if states[guid] then states[guid] = { show = false, changed = true }; end
    else 
        -- demon is valid
        states[guid] = 
        {
            show = true,
            changed = true,
            progressType = 'timed',
            duration = v.duration,
            expirationTime = v.expirationTime,
            demonType = summonTable[v.id].type or summonTable[v.id].name,
            name = summonTable[v.id].name,
            col = summonTable[v.id].col,
            icon = summonTable[v.id].icon or GetSpellTexture(v.id),
            order = summonTable[v.id].order,
            autoHide = true,
        }
    end
    -- scan decon updates the decon and sac souls values
    aura_env.scanDeCon();
end

-- isActiveImp : function to check if the imp was active recently
local function isActiveImp(imp)
    if not imp then return; end -- imp is not valid
    local time = GetTime(); -- current time
    
    if not imp.duration then imp = aura_env.imps[imp] end;
    if not imp then return; end
    
    local default = (imp.active and imp.active  + impTimeThresh); -- default time for imp to be considered inactive
    local thresh = aura_env.useCastTime and (imp.castingUntil and imp.castingUntil + 0.1 or default) or default; -- actual threshold to use, either cast time or default 
    return thresh >= time; -- return imp is active or not
end

-- countImps : function to count total imps in the table,
-- as well as the total 'active' imps
local countImps = function()
    local c = 0; -- total table imp count
    local a = 0; -- active imps
    local s = 0; -- to show imps
    local r = GetSpellCount(196277); -- implosion has imp count on icon
    for _, v in pairs(aura_env.imps) do -- iterate imps table
        c = c + 1; -- increment total count
        if isActiveImp(v) then -- check if imp is active
            a = a + 1; -- increment active imp count
        end
        
        if v.show then
            s = s + 1;
        end
    end
    return c, a, r, s; -- return all imp counts
end

aura_env.addImpClump = function(time)
    --[[
          hand of guldan cast
    after a cast the imps spawn after x seconds:
     1st: 0.557~
     2nd: 0.817~
     3rd: 0.952~          -> 0.395~ second window for 3 imps
     4th: 0.952~
     5th: 1.221~
     6th: 1.407~          -> 0.455~ second window for 3 imps   
     --]]
    
    impClumps[time] = {};
    aura_env.print('clump made at', time);
end

aura_env.assignImpClump = function(imp)
    local v = aura_env.imps[imp];
    if not v then return; end
    
    if (not v.innerDemon) then
        for x, _ in pairs(impClumps) do
            local spawnWindow = x + 0.4; -- i picked 0.4 seconds, because imps spawn at seemingly random intervals
            local buffer = 0;
            
            local check = v.spawn - spawnWindow;
            local limit = (impDelay + buffer);
            aura_env.print('spawn window parameters:', check, limit);
            
            if x ~= 'ID' and (check > 0 and check < limit) then
                impClumps[x][imp] = true;
                v.clumpKey = x;
            end
        end
    else      
        local found = impClumps['ID'];
        if found then
            impClumps['ID'][imp] = true;
        else
            impClumps['ID'] = {};
            impClumps['ID'][imp] = true;
        end
        v.clumpKey = 'ID';
    end
end

aura_env.removeFromImpClump = function(states, imp)
    local v = aura_env.imps[imp];
    if not v then return; end
    
    if not v.clumpKey or not impClumps[v.clumpKey] then return; end
    impClumps[v.clumpKey][imp] = nil;
    
    local count = 0;
    for _ in pairs(impClumps[v.clumpKey]) do
        count = count + 1;
    end
    
    if count == 0 then impClumps[v.clumpKey] = nil; end
    --aura_env.updateImpClump(states, v.clumpKey)
end

aura_env.updateSpecificImp = function(states, imp)
    imp = aura_env.imps[imp];
    if not imp then return; end
    aura_env.updateImpClump(states, imp.clumpKey);
end

aura_env.updateImpClump = function(states, clumpKey)
    if not clumpKey then print('clump doesnt exist') return; end
    local currCasts = 0; -- current 'casts' in clump
    local maxCasts = 0; -- max 'casts' in clump
    local c = 0; -- imp count in clump
    local index = nil; -- index is just a sample imp from clump for duration information

    local clump = impClumps[clumpKey];
    if not clump then return; end
    -- iterate the clump
    for x, _ in pairs(clump) do
        local imp = aura_env.imps[ x ]; -- imp object
        if isActiveImp(x) and imp.show then -- imp is 'active' state and should be shown
            currCasts = currCasts + aura_env.imps[ x ].casts; -- increment casts     
            maxCasts =  maxCasts  + aura_env.imps[ x ].maxCasts; -- increment max casts
            c = c + 1; --   increment count
            if not index then index = x; end; -- set index to current imp if it's not set
        end
    end
    
    local spellID = clumpKey == 'ID' and 279910 or 104317; -- impClumps should have a key for inner demons if talented
    if summonTable[spellID].enabled then -- imps are enabled
        if c > 0 and currCasts > 0 then -- imp count is not 0
            -- create / update imp clump state
            states[clumpKey] =
            {
                changed = true,
                show = true,
                name = summonTable[spellID].name,
                icon = summonTable[spellID].icon,
                order = summonTable[spellID].order,
                demonType = summonTable[spellID].type or summonTable[spellID].name,
                spent = c,
                progressType = 'static',
                value = currCasts or 0,-- / c,
                total = maxCasts or 0,-- / c,            
                duration = aura_env.imps[ index ] and aura_env.imps[ index ].duration,
                expirationTime = aura_env.imps[ index ] and aura_env.imps[ index ].expirationTime,
                autoHide = true,
                
                -- text replacement values, you can put %count for example in the text box
                count = c,
                totalCasts = currCasts,
                totalEnergy = ceil(currCasts * aura_env.impCost),
                perImpCasts = ceil(currCasts / c),
                perImpEnergy = ceil((currCasts * aura_env.impCost) / c),
                percent = floor((currCasts / maxCasts * 100) + 0.5),
                maxCasts = maxCasts,
                maxPerImp = aura_env.impCasts,
            };
        else -- 0 imps
            -- hide clump
            states[clumpKey] = { show = false, changed = true }
        end
    end
end

aura_env.updateFillerImps = function(states)
    local _, activeImps, expectedImpCount = countImps();
    local fillerImps = expectedImpCount - activeImps;

    states['filler'] = { show = false, changed = true }; -- reset filler imps

    -- Handle 'filler' imp states
    local combat =  UnitAffectingCombat'player';        
    if showFiller and fillerImps > 0 and (not combat or (not oocOnly and combat)) then
        states['filler'] = 
        {
            show = true,
            changed = true,
            name = summonTable[104317].name,
            icon = summonTable[104317].icon,
            order = summonTable[104317].order,
            demonType = 'Filler',
            progressType = 'static',
            total = 1,
            value = 1,
            filler = fillerImps;
        }
    end
end

local impCState = { 0, 0 };
-- updateImps : function to update the imp states
aura_env.updateImps = function(states)
    aura_env.last = GetTime();
    if summonTable[104317].enabled or summonTable[279910].enabled then        
        local _, _, expectedImpCount = countImps();
        impCState[1] = impCState[2];
        impCState[2] = expectedImpCount;
        
        for k, v in pairs(states) do
            if v.name == "Wild Imp" then
                states[k] = 
                {
                    show = false,
                    changed = true,
                };            
            end
        end
        
        if expectedImpCount == 0 then 
            if aura_env.imploded then
                aura_env.imploded = nil;
                if conf.printStats then aura_env.stats.impsImploded = aura_env.stats.impsImploded + impCState[1]; end
            end
            for k, _ in pairs(aura_env.imps) do
                aura_env.removeFromImpClump(states, k);
            end
            aura_env.imps = {};
            aura_env.scanDeCon();
            return;
        end
            
        for k, _ in pairs(impClumps) do
           aura_env.updateImpClump(states, k);
        end
        
        aura_env.updateFillerImps(states);
    end
    aura_env.scanDeCon();
end   

aura_env.scanDeCon = function()
    if conf.scanDecon then
        local event = "DEMONTIMERS_DECON"; -- demonic consumption event
        local event2 = "SACSOULS_SCAN"; -- sacrificed souls event
        local totalDemons = UnitExists('pet') and 1 or 0; -- total demon count
        local totalhp = UnitHealthMax('pet') or 0; -- total health pool for demons
        
        local playerHP = UnitHealthMax'player'; -- player max hp is what determines demon's hp
        
        for k,v in pairs(aura_env.demons) do
            if k ~= 'imps' and v.name then
                totalhp = totalhp + ((v.hpMod and v.hpMod * playerHP) or v.hpValue or 0);
                totalDemons = totalDemons + 1;        
                
                if v.name == 'Dreadstalker' then
                    totalhp = totalhp + ((v.hpMod and v.hpMod * playerHP) or v.hpValue or 0);
                    totalDemons = totalDemons + 1;
                end
            end 
        end
        
        local impCount = GetSpellCount(196277); -- number of imps on implosion icon        
        -- demonic consumption counting
        totalhp = totalhp + (impCount * UnitHealthMax'player') * aura_env.summonTable[104317].hpMod;
        WeakAuras.ScanEvents(event, math.floor((totalhp * 0.15) / 10))        
        -- sacrificed souls counting
        totalDemons = totalDemons + impCount;
        WeakAuras.ScanEvents(event2, totalDemons);
    end
end

-- Legacy Options
local hor = { 'RIGHT', 'LEFT' };
local ver = { 'DOWN', 'UP' };
local sor = { 'DESC', 'ASC' };

local spacing = conf.spacing or 5;
local perRow = conf.perRow or 5;
local horzontal_growth = conf.hor and hor[conf.hor] or 'RIGHT';
local vertical_growth = conf.ver and ver[conf.ver] or 'DOWN';
local sort_direction = conf.sor and sor[conf.sor] or 'DESC'; 

local sortFunc = function(a, b)
    if a and b then
        if a.state.name == b.state.name then -- same demon type, order by timer or whatever
            if sort_direction == 'DESC' then
                if a.state.progressType == 'static' and (a.state.value and b.state.value) then
                    return a.state.value < b.state.value;
                elseif a.state.progressType == 'timed' and a.state.expirationTime and b.state.expirationTime then
                    return (a.state.expirationTime < b.state.expirationTime);
                end                
            else 
                if a.state.progressType == 'static' and (a.state.value and b.state.value) then
                    return a.state.value > b.state.value;
                elseif a.state.progressType == 'timed' and a.state.expirationTime and b.state.expirationTime then
                    return (a.state.expirationTime > b.state.expirationTime);
                end   
            end            
        else           
            if sort_direction == 'DESC' then
                return (a.state.order < b.state.order);
            else 
                return (a.state.order > b.state.order) 
            end
        end
    end
end

aura_env.sortAndOffset = function()
    local baseX = WeakAuras.regions[aura_env.id].region.xOffset
    local baseY = WeakAuras.regions[aura_env.id].region.yOffset
    local count = 0
    local t = {}    
    for _, v in pairs(WeakAuras.clones[aura_env.id]) do
        table.insert(t, v)
    end    
    
    table.sort(t, sortFunc)    
    
    for _, region in ipairs(t) do
        if region.toShow then
            local column = perRow > 0 and count % perRow or count
            local xOff = (region.width + spacing) * column
            xOff = horzontal_growth == "LEFT" and 0-xOff or xOff
            local row = perRow > 0 and math.floor(count / perRow) or 0
            local yOff = - row * (region.height + spacing)
            yOff = vertical_growth == "UP" and 0-yOff or yOff
            region:SetOffset(baseX + xOff, baseY + yOff)
            count = count + 1
        end
    end
end  

aura_env.getTyrantDuration();

local frameID = aura_env.id .. 'frame';
local fontID = aura_env.id .. 'font';
local font = _G[fontID];

if aura_env.config.debug then
    if not _G[frameID] then
        aura_env.frame = CreateFrame("Frame", frameID);
        aura_env.frame:ClearAllPoints();
        aura_env.frame:SetPoint("TOPLEFT");
        aura_env.frame:SetWidth(1000);
        aura_env.frame:SetHeight(1000);
        aura_env.frame:Show();
    end

    if not _G[fontID] then
        aura_env.font = aura_env.frame:CreateFontString(fontID, "ARTWORK");
        aura_env.font:SetFont("Fonts\\FRIZQT__.ttf", 8, "OUTLINE");
        aura_env.font:SetJustifyV("TOP");
        aura_env.font:SetJustifyH("LEFT");
        aura_env.font:ClearAllPoints();
        aura_env.font:SetAllPoints(aura_env.frame);
        font = _G[fontID];
    end

    if font then
        font:SetText("["..aura_env.id.."] Debugging:\n");
        font:Show();
    end
else
    if font then font:Hide(); end
end

aura_env.setText = function(text)
    if font then 
        font:SetText("["..aura_env.id.."] Debugging:\n"..text);
        font:Show(); 
    end
end

aura_env.updateText = function()
    local text = dump(impClumps);
    aura_env.setText(text or "");
end