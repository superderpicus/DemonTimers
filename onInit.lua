-- demon timers v3 by taters
local aura_env, conf, debug, tonumber = aura_env, aura_env.config, aura_env.config.debug, tonumber;
aura_env.summonTable = 
{
    -- ID,      duration (s),  name,                        type,                       icon,               order,                              enabled,                        hpMod,         hpValue
    [265187] = {duration = 15, name = "Tyrant",             type = nil,                 icon = nil,         order = tonumber(conf.demon.tyrantOrder), enabled = conf.demon.tyrantEnabled,   hpMod = nil },
    [104317] = {duration = 40, name = "Wild Imp",           type = nil,                 icon = 615097,      order = tonumber(conf.demon.impOrder),    enabled = conf.demon.impEnabled,      hpMod = 0.15 }, -- Regular Imp
    [279910] = {duration = 20, name = "Wild Imp",           type = 'Inner Demon Imp',   icon = 615097,      order = tonumber(conf.demon.impOrder),    enabled = conf.demon.impEnabled,      hpMod = 0.15 }, -- Inner Demons Imp
    [193332] = {duration = 12, name = "Dreadstalker",       type = nil,                 icon = nil,         order = tonumber(conf.demon.dsOrder),     enabled = conf.demon.dsEnabled,       hpMod = 0.4 },
    [264119] = {duration = 15, name = "Vilefiend",          type = nil,                 icon = nil,         order = tonumber(conf.demon.vfOrder),     enabled = conf.demon.vfEnabled,       hpMod = 0.75 },
    -- Inner Demons / Nether Portal
    [268001] = {duration = 15, name = "Ur'zul",             type = 'Misc',              icon = nil,         order = tonumber(conf.demon.miscOrder),   enabled = conf.demon.miscEnabled,     hpMod = 0.75 },
    [267994] = {duration = 15, name = "Shivarra",           type = 'Misc',              icon = nil,         order = tonumber(conf.demon.miscOrder),   enabled = conf.demon.miscEnabled,     hpMod = 0.75 },
    [267988] = {duration = 15, name = "Vicious Hellhound",  type = 'Misc',              icon = nil,         order = tonumber(conf.demon.miscOrder),   enabled = conf.demon.miscEnabled,     hpMod = 0.75 },
    [267992] = {duration = 15, name = "Bilescourge",        type = 'Misc',              icon = nil,         order = tonumber(conf.demon.miscOrder),   enabled = conf.demon.miscEnabled,     hpMod = 0.75 }, 
    [267991] = {duration = 15, name = "Void Terror",        type = 'Misc',              icon = nil,         order = tonumber(conf.demon.miscOrder),   enabled = conf.demon.miscEnabled,     hpMod = 0.75 },
    [267995] = {duration = 15, name = "Wrathguard",         type = 'Misc',              icon = nil,         order = tonumber(conf.demon.miscOrder),   enabled = conf.demon.miscEnabled,     hpMod = 0.75 },
    [267987] = {duration = 15, name = "Illidari Satyr",     type = 'Misc',              icon = 1413871,     order = tonumber(conf.demon.miscOrder),   enabled = conf.demon.miscEnabled,     hpMod = 0.75 },
    [267996] = {duration = 15, name = "Darkhound",          type = 'Misc',              icon = nil,         order = tonumber(conf.demon.miscOrder),   enabled = conf.demon.miscEnabled,     hpMod = 0.75 },
    [267989] = {duration = 15, name = "Eye of Gul'dan",     type = 'Misc',              icon = nil,         order = tonumber(conf.demon.miscOrder),   enabled = conf.demon.miscEnabled,     hpMod = 0.75 },
    [267986] = {duration = 15, name = "Prince Malchezaar",  type = 'Misc',              icon = nil,         order = tonumber(conf.demon.miscOrder),   enabled = conf.demon.miscEnabled,     hpMod = 0.75 },
    -- Grimoire: Felguard
    [111898] = {duration = 17, name = "Grimoire: Felguard", type = nil,                 icon = nil,         order = tonumber(conf.demon.fgOrder),     enabled = conf.demon.fgEnabled,       hpMod = 0.75 },
    -- PvP (Observer / Fel Lord)
    [201996] = {duration = 20, name = "Observer",           type = 'PvP',               icon = nil,         order = tonumber(conf.demon.pvpOrder),    enabled = conf.demon.pvpEnabled,      hpMod = nil,    hpValue = 2854 },
    [212459] = {duration = 15, name = "Fel Lord",           type = 'PvP',               icon = nil,         order = tonumber(conf.demon.pvpOrder),    enabled = conf.demon.pvpEnabled,      hpMod = nil,    hpValue = 11791 },
    -- Nether Portal
    [267218] = {duration = 15, name = "Nether Portal",      type = nil,                 icon = nil,         order = tonumber(conf.demon.npOrder),     enabled = conf.demon.npEnabled,       hpMod = nil },
    -- Subjugation
    [1098] =   {duration = 300, name = "Subjugated",        type = nil,                 icon = 136154,      order = tonumber(conf.demon.subOrder),    enabled = conf.demon.subEnabled,      hpMod = nil },
};
local summonTable = aura_env.summonTable;

local impCasts = UnitLevel'player' >= 56 and 6 or 5;
local impCost = UnitLevel'player' >= 56 and 16 or 20;
aura_env.impTimeThresh = tonumber(conf.general.delay);
aura_env.despawnDelay = conf.general.despawnDelay;
aura_env.useCastTime = conf.general.useCastTime;
local showFiller = conf.general.showFiller;
local impMode = conf.general.impMode;
local oocOnly = conf.general.nocombatOnly;
local impTimeThresh = aura_env.impTimeThresh;
local impDelay = conf.general.summonDelay;
aura_env.imps = {};
aura_env.impClumps = {}; 

local statsModule = aura_env.config.stats or true;
local statMode = aura_env.config.statMode or 1;
-- 1 -> PLAYER_REGEN, 2 -> ENCOUNTER_START, 3 -> CHALLENGE_MODE_START
local stats = {};

local resetStats = function()
    stats =  
    {   
        combatName = '',
        tyrantExtensionTime = 0,
        imploded = 0,
        felFirebolts = 0,
        tyrantFelFirebolts = 0,
        demons = 
        {
            [summonTable[265187].name] = 0,
            [summonTable[104317].name] = 0,
            [summonTable[193332].name] = 0,
            [summonTable[265187].name] = 0,
            [summonTable[264119].name] = 0,
            [summonTable[268001].name] = 0,
            [summonTable[267994].name] = 0,
            [summonTable[267988].name] = 0,
            [summonTable[267992].name] = 0,
            [summonTable[267991].name] = 0,
            [summonTable[267995].name] = 0,
            [summonTable[267987].name] = 0,
            [summonTable[267996].name] = 0,
            [summonTable[267989].name] = 0,
            [summonTable[267986].name] = 0,
            [summonTable[111898].name] = 0,
            [summonTable[201996].name] = 0,
            [summonTable[212459].name] = 0,
            [summonTable[267218].name] = 0,
        },
        total_demons = 0,
        horned_procs = 0,
        total_hogs = 0,
        wilfreds_cdr = 0,
        avg_implosive_haste = 0,
    };
end

aura_env.addStat = function(stat, increment)
    if statsModule and stats[stat] then
        stats[stat] = stats[stat] + (increment or 0);
    end
end

aura_env.addDemon = function(name)
    if not statsModule then return; end
    if not name or name == '' then return; end
    if not stats.demons then stats.demons = {}; end
    stats.demons[name] = stats.demons[name] or 0;
    stats.demons[name] = stats.demons[name] + 1;
    aura_env.addStat('total_demons', 1);
    if (name == summonTable[193332].name) then
        stats.demons[name] = stats.demons[name] + 1;    
        aura_env.addStat('total_demons', 1);    
    end
    
    if(name == summonTable[212459].name) then
        stats.demons[name] = stats.demons[name] - 1;
        aura_env.addStat('total_demons', -1);
    end
end

aura_env.startStats = function(name)
    if not statsModule then return; end
    resetStats();
    stats.combatName = (statMode == 2 and name) or (statMode == 3 and C_Map.GetMapInfo(name).name or "Unknown Dungeon");
end

aura_env.endStats = function()
    if not statsModule then return; end
    if not stats or not stats.total_hogs then resetStats(); end
    local sorted_demons = {};
    local name = stats.combatName or 'Demon Timer Stats';
    local output_string = '|cffffcc00' .. name .. ':|r\n';
    local col = '|cffffcc00';
    
    for k,v in pairs(stats.demons or {}) do
        if v > 0 then
            table.insert(sorted_demons, {k,v});
        end
    end
    
    if stats.tyrantExtensionTime > 0 then output_string = output_string .. format('%s%s%is\n', col, 'Tyrant Extension Time:|r ', stats.tyrantExtensionTime); end
    if stats.felFirebolts > 0 then output_string = output_string .. format('%s%s%i\n', col, 'Total Fel Firebolts:|r ', stats.felFirebolts); end
    if stats.tyrantFelFirebolts > 0 then output_string = output_string .. format('%s%s|r %i\n', col, 'Tyranted Fel Firebolts:|r ', stats.tyrantFelFirebolts); end
    if stats.imploded > 0 then output_string = output_string .. format('%s%s%i\n', col, 'Imps Imploded:|r ', stats.imploded); end
    if stats.horned_procs > 0 then output_string = output_string .. format('%s%s%i (%.1f%%)\n', col, 'Horned Nightmare Procs:|r ', stats.horned_procs, (stats.horned_procs / stats.total_hogs) * 100); end
    
    table.sort(sorted_demons, function(a,b) return a[2] > b[2] end);
    local total_demons = stats.total_demons or 0;
    if total_demons > 0 then
        output_string = output_string .. format('%s%s|r %i total\n', col, 'Demon Summary:|r', total_demons); 
        for i = 1, #sorted_demons do
            output_string = output_string .. format('    %s%s|r%i (%.1f%%)\n', col, sorted_demons[i][1] .. ':|r ', sorted_demons[i][2], (sorted_demons[i][2] / total_demons) * 100);
        end
    end
    
    print(output_string);
end

-- debug frame
local frameID = aura_env.id .. 'frame';
local fontID = aura_env.id .. 'font';
local font = _G[fontID];

if debug then
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
    
    font:Show();
else
    if _G[fontID] then _G[fontID]:Hide(); end
end
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
aura_env.setText = function(text)
    local d = dump(aura_env.impClumps);
    if font then font:SetText("["..aura_env.id.."] Debugging:\n".. d) end
end

-- tyrant extension blacklist
aura_env.blacklist = 
{
    [265187] = true,
    [267218] = true,
    [1098] = true,    
};

local auras = 
{
    [267218] = true,
    [1098] = true,
}

-- spawnDemon: function to create a state for the provided demon
aura_env.spawnDemon = function(states, time, dest, spell)
    local entry = summonTable[spell]; -- summon table entry
    local key = auras[spell] and spell or dest; -- key is either spellID if its aura or GUID if its a demon
    
    states[key] = 
    {
        show = true,
        changed = true,
        name = entry.name,
        icon = entry.icon or GetSpellTexture(spell),
        demonType = entry.type or entry.name,
        order = entry.order,
        progressType = 'timed',
        duration = entry.duration,
        expirationTime = entry.duration + time,
        spellID = spell,
        hpMod = entry.hpMod,
        hpVal = entry.hpVal,
        autoHide = true,
    }
end

-- isActiveImp : function to check if the imp was active recently
local function isActiveImp(imp)
    if not imp then return; end -- imp is not valid    
    if not imp.duration then imp = aura_env.imps[imp] end;
    if not imp then return; end
    
    local time = GetTime(); -- current time
    local default = (imp.active and imp.active + impTimeThresh); -- default time for imp to be considered inactive
    local thresh = aura_env.useCastTime and (imp.castingUntil and imp.castingUntil + 0.1 or default) or default; -- actual threshold to use, either cast time or default 
    return thresh >= time; -- return imp is active or not
end

-- countImps : function to count total imps in the table,
-- as well as the total 'active' imps
local function countImps()
    local c = 0; -- total table imp count
    local a = 0; -- active imps
    local s = 0; -- to show imps
    local r = GetSpellCount(196277); -- implosion has imp count on icon
    for k, v in pairs(aura_env.imps) do -- iterate imps table
        c = c + 1; -- increment total count
        if isActiveImp(k) then -- check if imp is active
            a = a + 1; -- increment active imp count
        end
        
        if v.show then
            s = s + 1;
        end
    end
    return c, a, r, s; -- return all imp counts
end

-- assignClump: imps are assigned a clump which is made into a state. 
-- clumps are created by casting HoG
local function assignClump(states, imp, inner)
    local v = aura_env.imps[imp];
    if not v then return; end
    
    local impClumps = aura_env.impClumps;
    
    if (not inner) then
        for x, clump in pairs(impClumps) do
            if x ~= 'ID' then
                local spawnWindow = x + 0.4; -- i picked 0.4 seconds, because imps spawn at seemingly random intervals
                local buffer = 0;
                
                local inClump = 0;
                for k in pairs(clump) do if k ~= 'expected' and k ~= 'update' then inClump = inClump + 1; end end
                
                local check = v.spawn - spawnWindow;
                local limit = (impDelay + buffer);
                
                if  (check > 0 and check < limit) and (inClump < clump.expected) and (not v.clumpKey) then
                    impClumps[x][imp] = true;                    
                    v.clumpKey = x;
                end
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
    aura_env.updateImpClump(states, v.clumpKey);
end

aura_env.spawnImp = function (states, time, dest, spell) 
    local inner = spell == 279910; -- inner demon
    aura_env.imps[dest] = { show = true, active = time, casts = impCasts, maxCasts = impCasts, spawn = time, duration = summonTable[spell].duration, expirationTime = summonTable[spell].duration + time }
    assignClump(states, dest, inner);
end

aura_env.removeFromImpClump = function(states, imp)
    local v = aura_env.imps[imp];
    if not v then return; end
    
    local impClumps = aura_env.impClumps;
    
    if not v.clumpKey or not impClumps[v.clumpKey] then return; end
    impClumps[v.clumpKey][imp] = nil;
    
    local count = 0;
    for k in pairs(impClumps[v.clumpKey]) do
        if k ~= 'update' and k ~= 'expected' then count = count + 1; end
    end
    
    if count == 0 then impClumps[v.clumpKey] = nil; states[v.clumpKey] = { show = false, changed = true} end
end

aura_env.deleteID = function(states)
    local impClumps = aura_env.impClumps;
    for k,_ in pairs(impClumps['ID'] or {}) do
        if aura_env.imps[k] then aura_env.imps[k] = nil; end
    end
    impClumps['ID'] = nil;
    if states['ID'] then states['ID'] = { show = false, changed = true; } end
end

local clumpDelay = conf.impWindow; -- seconds
aura_env.updateSpecificImp = function(states, imp)
    imp = aura_env.imps[imp];
    if not imp then return; end
    if not imp.clumpKey then return; end
    -- imp modes: 1. on cast  2. on tick
    if impMode == 2 then
        local c = aura_env.impClumps[imp.clumpKey];
        if not c then return; end
        if not c.update then c.update = GetTime() + clumpDelay; end
    else
        aura_env.updateImpClump(states, imp.clumpKey);
    end
end

aura_env.updateImpClump = function(states, clumpKey)
    if not clumpKey then return; end
    
    local currCasts = 0; -- current 'casts' in clump
    local maxCasts = 0; -- max 'casts' in clump
    local c = 0; -- imp count in clump
    local index = nil; -- index is just a sample imp from clump for duration information
    local imps = aura_env.imps;    
    local impClumps = aura_env.impClumps;
    local clump = impClumps[clumpKey];
    
    if not clump then return; end
    -- iterate the clump
    for x, _ in pairs(clump) do
        local imp = aura_env.imps[ x ]; -- imp object
        if isActiveImp(x) and imp.show then -- imp is 'active' state and should be shown
            currCasts = currCasts + imps[ x ].casts; -- increment casts     
            maxCasts =  maxCasts  + imps[ x ].maxCasts; -- increment max casts
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
                duration = imps[ index ] and imps[ index ].duration,
                expirationTime = imps[ index ] and imps[ index ].expirationTime,
                autoHide = true,
                
                -- text replacement values, you can put %count for example in the text box
                count = c,
                totalCasts = currCasts,
                totalEnergy = ceil(currCasts * impCost),
                perImpCasts = ceil(currCasts / c),
                perImpEnergy = ceil((currCasts * impCost) / c),
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

aura_env.impCast = function(states, source, sub)
    local imps = aura_env.imps;
    local time = GetTime();
    if sub == 'SPELL_CAST_SUCCESS' then
        if not aura_env.tyrant or aura_env.tyrant < time then
            imps[source].casts = imps[source].casts - 1;
            imps[source].castingUntil = nil;
            imps[source].active = time;
            aura_env.addStat('felFirebolts', 1);
            
            if imps[source].casts <= 0 then -- yeet
                imps[source].show = false;
                aura_env.removeFromImpClump(states, source);
                C_Timer.After(aura_env.despawnDelay,  function() 
                        imps[source] = nil; 
                        aura_env.updateSpecificImp(states, source);
                end);
            end
            
            aura_env.updateSpecificImp(states, source);
        else
            aura_env.addStat('tyrantFelFirebolts', 1);
            aura_env.addStat('felFirebolts', 1);
        end
    elseif sub == "SPELL_CAST_START" then
        local haste = 1 + UnitSpellHaste("player") / 100;
        local castTime = 2 / haste;
        
        imps[source].castingUntil = time + castTime;
        imps[source].active = time;
        aura_env.updateSpecificImp(states, source);
        
        if (not aura_env.tyrant) or (aura_env.tyrant < (time + castTime)) then
            C_Timer.After( castTime + 0.2, function()
                    aura_env.updateSpecificImp(states, source); 
            end );
        end
    end
end

aura_env.implode = function(states)
    aura_env.addStat('imploded', aura_env.pending or 0);
    aura_env.pending = nil;
    for _,v in pairs(states) do
        if v and v.name == 'Wild Imp' then v.show = false; v.changed = true; end
    end
    
    for k,_ in pairs(aura_env.imps) do
        aura_env.removeFromImpClump(states, k);
    end
    
    aura_env.imps = {};
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

-- Handing for the anima power 'Soul Platter', which 
-- makes tyrant last 100% longer. Note that the
-- extension time remains the same at 15s.
aura_env.tyrantAnimaPower = 320936; -- anima power spell ID
-- getTyrantDuration : function to get tyrant duration, based 
-- off of whether you have the anima power or not that doubles it
aura_env.getTyrantDuration = function()
    local x = { GetPlayerAuraBySpellID(aura_env.tyrantAnimaPower); } -- check if the anima power is active
    local dur; -- placeholder variable
    if x and x[3] then -- if buff is active and stacks exist
        dur = summonTable[265187].duration * 2; -- buff is active, duration is ~~base * stacks~~ it doesnt stack
    else
        dur = summonTable[265187].duration -- buff is not active, return default duration
    end
    return dur;
end

aura_env.tick = function(states)
    -- if state should be updated, update it
    if impMode == 2 then
        local time = GetTime(); -- current time
        for k,v in pairs(aura_env.impClumps) do -- iterate clumps
            if v.update and v.update <= time then -- should be updated now
                aura_env.updateImpClump(states, k); -- update clump
                aura_env.impClumps[k].update = nil; -- set it to nil for now
            end
        end
    end
end

local hor = { 'RIGHT', 'LEFT' };
local ver = { 'DOWN', 'UP' };
local sor = { 'DESC', 'ASC' };

local spacing = conf.general.spacing or 5;
local perRow = conf.general.perRow or 5;
local horzontal_growth = conf.general.hor and hor[conf.general.hor] or 'RIGHT';
local vertical_growth = conf.general.ver and ver[conf.general.ver] or 'DOWN';
local sort_direction = conf.general.sor and sor[conf.general.sor] or 'DESC'; 

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
        elseif a.state.order == b.state.order then
            if sort_direction == 'DESC' then
                return (a.state.expirationTime < b.state.expirationTime);
            else 
                return (a.state.expirationTime > b.state.expirationTime) 
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
    local count = 0;
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

aura_env.scanDeCon = function(states)
    if conf.scanDecon then
        local event = "DEMONTIMERS_DECON"; -- demonic consumption event
        local event2 = "SACSOULS_SCAN"; -- sacrificed souls event
        local alive = UnitExists'pet' and UnitHealth'pet' > 0;
        local totalDemons = alive and 1 or 0; -- total demon count        
        local totalhp = 0; -- total health pool for demons
        local playerHP = UnitHealthMax'player'; -- player max hp is what determines demon's hp
        
        local petDeconCap = playerHP;
        local petDecon = alive and UnitHealthMax'pet' or 0;
        if petDecon > petDeconCap then petDecon = petDeconCap end;
        
        for _,v in pairs(states) do
            if v.hpMod or v.hpVal then
                totalhp = totalhp + ((v.hpMod and v.hpMod * playerHP) or v.hpVal or 0);
                totalDemons = totalDemons + 1;
                
                if v.name == 'Dreadstalker' then
                    totalhp = totalhp + ((v.hpMod and v.hpMod * playerHP) or v.hpVal or 0);
                    totalDemons = totalDemons + 1;
                end
            end
        end
        
        local impCount = GetSpellCount(196277); -- number of imps on implosion icon        
        -- demonic consumption counting
        totalhp = totalhp + (impCount * UnitHealthMax'player') * summonTable[104317].hpMod;
        totalhp = totalhp + petDecon;
        WeakAuras.ScanEvents(event, math.floor((totalhp * 0.15) / 10))        
        -- sacrificed souls counting
        totalDemons = totalDemons + impCount;
        WeakAuras.ScanEvents(event2, totalDemons);
        
        aura_env.totalhp = totalhp;
    end
end

