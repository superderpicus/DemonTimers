function(states, event, ...)
    local time = GetTime();
    local aura_env = aura_env;
    local summonTable = aura_env.summonTable;
    if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
        if not ... then return; end -- checking for 'dummy' events that TSU gives you
        local _, sub, _, source, _, _, _, dest, _, _, _, spell, _ = ...; -- CLEU parameters
        if source == WeakAuras.myGUID then -- source was player unit
            if sub == 'SPELL_SUMMON' then
                local entry = summonTable[spell]; -- create summontable object now for use later
                aura_env.addDemon(entry and entry.name or '');
                if entry and entry.enabled then
                    if entry.name ~= 'Wild Imp' then -- entry is not imp
                        if spell == 212459 then -- fel lord is dumb, and it spawns '2' demons at the exact same time so we have to account for that
                            if (aura_env.felLord and aura_env.felLord > time) then return; else aura_env.felLord = time + 0.1 end; 
                        end
                        aura_env.spawnDemon(states, time, dest, spell); -- create demon state 
                    else -- entry is imp
                        aura_env.spawnImp(states, time, dest, spell); -- create imp state
                        C_Timer.After(2, function() aura_env.updateSpecificImp(states, dest) end); -- this will be required for checking that the imps are active
                        C_Timer.After(entry.duration + 15, function() aura_env.removeFromImpClump(states, dest); end); -- after 1 min~ delete the imp because we dont want stragglers
                    end -- end if entry is not imp
                end -- end if enabled
                
                -- tyrant was summoned, extend all demons
                if spell == 265187 then
                    -- tyrant value for imps
                    if not aura_env.tyrant or aura_env.tyrant < time then
                        aura_env.tyrant = time + 15;
                    else
                        local n = time + 15;
                        aura_env.tyrant = aura_env.tyrant < n and n or aura_env.tyrant;
                    end
                    
                    local duration = aura_env.getTyrantDuration(); -- have to account for soul platter anima power
                    states[dest].duration = duration; -- reset duration of tyrant
                    states[dest].expirationTime = time + duration; -- reset expiration time of tyrant
                    
                    for k,v in pairs(states) do
                        if (not aura_env.blacklist[v.spellID]) and (not aura_env.blacklist[k]) and v.duration and v.expirationTime then
                            v.duration = v.duration + 15;
                            v.expirationTime = v.expirationTime + 15;
                            if v.name ~= aura_env.summonTable[104317].name then
                                aura_env.addStat('tyrantExtensionTime', 15);
                            end
                            v.changed = true;
                        end -- end if
                    end -- end for loop
                end -- end tyrant
            elseif sub == 'SPELL_AURA_APPLIED' then -- subjugate ??
                local entry = summonTable[spell];
                if entry and entry.enabled then
                    aura_env.spawnDemon(states, time, dest, spell);
                end
            elseif sub == 'SPELL_AURA_REMOVED' and summonTable[spell] then -- idr what this is for
                if states[spell] then states[spell] = { show = false, changed = true } end
            elseif sub == 'SPELL_CAST_SUCCESS' and spell == 105174 then -- hand of guldan 
                aura_env.addStat('total_hogs', 1);
                aura_env.listening = true;
                aura_env.sampleUnit = nil;

                if aura_env.summonTable[104317].enabled then aura_env.impClumps[time] = {}; end -- create imp clump

                aura_env.latest_hog = time;
                aura_env.impClumps[time].expected = 3;
            elseif sub == 'SPELL_CAST_SUCCESS' and spell == 196277 then -- implosion
                aura_env.implode(states); -- implosion has to be handled
            elseif sub == 'SPELL_DAMAGE' and spell == 86040 then
                    if aura_env.listening then
                        aura_env.sampleUnit = dest;
                        aura_env.listening = nil;
                    elseif aura_env.sampleUnit then
                        if aura_env.sampleUnit == dest then
                            aura_env.addStat('horned_procs', 1);                            
                            aura_env.impClumps[aura_env.latest_hog].expected = 6;                            
                        end
                    end
                end
            return true;
        else -- source not player
            if sub == 'UNIT_DIED' or sub == 'UNIT_DISSIPATES' or sub == 'UNIT_DESTROYED' then
                if dest == WeakAuras.myGUID then -- player died
                    -- if the player dies, all the pets die too
                    for _,v in pairs(states) do
                        v.show = false;
                        v.changed = true;
                    end
                    return true;
                elseif states[dest] then -- a demon died
                    states[dest] = { show = false, changed = true }; -- hide state
                    return true;
                elseif aura_env.imps[dest] then -- imp died
                    aura_env.removeFromImpClump(states, dest); -- remove accordingly
                    return true;
                end
            elseif (sub == 'SPELL_CAST_START' or sub == 'SPELL_CAST_SUCCESS') and aura_env.imps[source] then
                aura_env.impCast(states, source, sub);
                return true;
            end
        end
    elseif event == 'PLAYER_SPECIALIZATION_CHANGED' then -- player swapped spec, or talent
        if not select(4, GetTalentInfo(6, 2, 1)) then -- inner demons
            aura_env.deleteID(states);
        end
    elseif event == 'JAILERS_TOWER_LEVEL_UPDATE' or event == 'PLAYER_ENTERING_WORLD' then
        -- wipe demons
        for _,v in pairs(states) do
            v.show = false;
            v.changed = true; 
        end
    elseif event == 'UNIT_SPELLCAST_SENT' then
        local unit, _, _, spell = ...;
        if unit == 'player' and spell == 196277 then
            aura_env.pending = GetSpellCount(196277);
        end
    else -- throttled every frame for updating specific things
        if not aura_env.last or aura_env.last < time - aura_env.config.general.interval then
            aura_env.last = time; -- throttle timer
            aura_env.setText(); -- debugging text
            aura_env.updateFillerImps(states); -- filler imp states
            aura_env.scanDeCon(states); -- demonic consumption / sac souls scan
            return true;
        end
        
        if not aura_env.impCheck or aura_env.impCheck < time - aura_env.config.general.impInterval then
            aura_env.impCheck = time;
            aura_env.tick(states); -- tick is a new experimental update system im using
        end
    end
end

function(event, ...)
    if not aura_env.config.stats then return; end
    local m = aura_env.config.statsMode;
    
    if event:find('CHALLENGE') and m == 3 then
        --local keyLevel = C_ChallengeMode.GetActiveKeystoneInfo() ;
        if event == 'CHALLENGE_MODE_START' then
            local mapID = ...;
            aura_env.startStats(mapID);
        else
            aura_env.endStats();
        end
    elseif event:find('ENCOUNTER') and m == 2 then
        if event == 'ENCOUNTER_START' then
            local _, name = ...;
            aura_env.startStats(name);
        else
            aura_env.endStats();
        end
    elseif event:find('REGEN') and m == 1 then
        if event == 'PLAYER_REGEN_DISABLED' then
            aura_env.startStats();
        else
            aura_env.endStats();
        end
    elseif event == 'DEMON_TIMERS_FORCE_START' then
        aura_env.startStats('demon timers test');
    elseif event == 'DEMON_TIMERS_FORCE_END' then
        aura_env.endStats(); 
    end
end