function(states, event, ...)
    local time = GetTime();  
    local aura_env = aura_env;    
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if not ... then return; end
        local _, sub, _, source, _, _, _, dest, _, _, _, spell, _ = ...;
        if source == WeakAuras.myGUID then
            if sub == "SPELL_SUMMON" and aura_env.summonTable[spell] then
                local entry = aura_env.summonTable[spell];
                aura_env.print(spell, entry.name, 'spawned');
                
                --local health = entry.hpMod and (UnitHealthMax'player' * entry.hpMod) or entry.hpValue;
                if entry.name == "Wild Imp" then
                    if aura_env.hogCast then
                        aura_env.print('imp time to spawn:', time - aura_env.hogCast);
                    end
                    aura_env.demons.imps[dest] = { show = true, hpMod = entry.hpMod, hpVal = entry.hpVal, name = entry.name, duration = entry.duration, casts = aura_env.impCasts, maxCasts = aura_env.impCasts, expirationTime = (time + entry.duration), id = spell, active = time, spawn = time, innerDemon = (spell == 279910) };      
                    aura_env.addToStats(entry);
                    aura_env.assignImpClump(dest);
                    aura_env.updateImps(states);
                    
                    C_Timer.After(entry.duration + 0.1, function() aura_env.updateImps(states); end)
                    C_Timer.After(60, function() aura_env.demons.imps[dest] = nil; end);
                else
                    -- for some reason, fel lord summons 'two' exact demons, even though there is only one,
                    -- so we have to account for it otherwise there would be 2 fel lords in the timers
                    if (spell == 212459 and (not aura_env.felLord or aura_env.felLord < time)) or spell ~= 212459 then
                        aura_env.felLord = time + 0.1; -- basically our 'cooldown' variable
                        aura_env.demons[dest] = { hpMod = entry.hpMod, hpVal = entry.hpVal, name = entry.name, id = spell, duration = entry.duration, expirationTime = time + entry.duration }; -- new demon indexed as GUID
                        C_Timer.After(entry.duration + 0.1, function() aura_env.updateIndividualDemon(states, dest); end)  -- after timer is up, reevaluate the demon table
                        aura_env.addToStats(entry); -- stats module
                        aura_env.updateIndividualDemon(states, dest);
                    end
                    
                    if spell == aura_env.summonTable.tyrant then
                        if not aura_env.checked or aura_env.checked < GetTime() - 1 then
                            aura_env.checked = GetTime()
                            aura_env.getTyrantDuration();
                        end
                        
                        local dur = entry.duration;--aura_env.getTyrantDuration();   
                        aura_env.demons[dest].duration = dur;
                        aura_env.demons[dest].expirationTime = time + dur;
                        
                        local extend = 15; -- i think lol
                        aura_env.tyrantCast = false;
                        
                        if not aura_env.tyrant or aura_env.tyrant < time then
                            aura_env.tyrant = time + extend;
                        else
                            local n = time + extend;
                            aura_env.tyrant = aura_env.tyrant < n and n or aura_env.tyrant;
                        end
                        
                        for k, v in pairs(aura_env.demons) do
                            if k ~= 'imps' and (v.name ~= "Tyrant" and v.name ~= "Nether Portal" and v.name ~= 'Subjugated') and v.duration and v.expirationTime then 
                                v.duration = v.duration + extend;
                                v.expirationTime = v.expirationTime + extend;
                                aura_env.stats.totalTyrantExtension = aura_env.stats.totalTyrantExtension + extend;
                                C_Timer.After(v.expirationTime - GetTime() + 0.1, function() aura_env.updateIndividualDemon(states, k); end) 
                                aura_env.updateIndividualDemon(states, k);
                            end
                        end
                        
                        for _,v in pairs(aura_env.demons.imps) do
                            if v.duration and v.expirationTime then 
                                v.duration = v.duration + extend;
                                v.expirationTime = v.expirationTime + extend;
                            end
                        end
                    end
                end
            elseif sub == "SPELL_AURA_APPLIED" then
                if aura_env.summonTable[spell] then
                    local entry = aura_env.summonTable[spell];
                    if entry.enabled then                        
                        aura_env.demons[dest] = { name = entry.name, id = spell, duration = entry.duration, expirationTime = time + entry.duration }; 
                        aura_env.updateIndividualDemon(states, dest);
                    end
                end
                
                if aura_env.tyrantAnimaPower == spell then
                    aura_env.getTyrantDuration();
                end
            elseif sub == "SPELL_AURA_REMOVED" then
                if spell == 1098 then 
                    for _,v in pairs(aura_env.demons) do
                        if v.id and v.id == spell then
                            v.show = false;
                            v.changed = true; 
                        end
                    end
                end
                if aura_env.tyrantAnimaPower == spell then
                    aura_env.getTyrantDuration();
                end
                
            elseif sub == "SPELL_CAST_SUCCESS" and spell == 196277 then -- implosion
                aura_env.imploded = true;
                aura_env.updateImps(states);                   
            elseif (sub == "UNIT_DIED" or sub == "UNIT_DESTROYED" or sub == "UNIT_DISSIPATES") and (aura_env.demons.imps[dest] or states[dest] or WeakAuras.myGUID == dest) then
                if dest == WeakAuras.myGUID then
                    -- player died, all demons have to be wiped
                    aura_env.demons = {};
                    aura_env.demons.imps = {};
                    aura_env.updateIndividualDemon(states, dest);
                else
                    if aura_env.demons.imps[dest] then 
                        aura_env.demons.imps[dest] = nil; 
                        aura_env.updateImps(states);
                    else
                        aura_env.demons[dest] = nil;
                        aura_env.updateIndividualDemon(states, dest);
                    end                
                end 
            end
            
            if (spell == 105174 or spell == 86040) then 
                if sub == 'SPELL_CAST_SUCCESS' then
                    aura_env.listening = true;
                    aura_env.stats.hogs = aura_env.stats.hogs + 1;
                    aura_env.sampleUnit = nil;
                    
                    aura_env.addImpClump(time);
                    aura_env.hogCast = time;
                elseif sub == 'SPELL_DAMAGE' then
                    if aura_env.listening then
                        aura_env.sampleUnit = dest;
                        aura_env.listening = nil;
                    elseif aura_env.sampleUnit then
                        if aura_env.sampleUnit == dest then
                            aura_env.stats.hornedNightmareProcs = aura_env.stats.hornedNightmareProcs + 1;
                        end
                    end
                end
            end
        else            
            if sub:find("CAST") and aura_env.demons.imps[source] then
                if sub == "SPELL_CAST_SUCCESS" then
                    aura_env.stats.totalFirebolts = aura_env.stats.totalFirebolts + 1;
                    if (not aura_env.tyrant or aura_env.tyrant < time) then
                        aura_env.demons.imps[source].casts = aura_env.demons.imps[source].casts - 1;
                        aura_env.demons.imps[source].castingUntil = nil;
                        aura_env.demons.imps[source].active = time;
                        if aura_env.demons.imps[source].casts <= 0 then -- imp is done for
                            aura_env.demons.imps[source].show = false;
                            aura_env.removeFromImpClump(source);
                            C_Timer.After(aura_env.despawnDelay, function() 
                                    aura_env.demons.imps[source] = nil; 
                                    WeakAuras.ScanEvents("DEMONTIMER_IMP_UPDATE")  end);
                        end
                    else
                        aura_env.stats.totalTyrantFirebolts = aura_env.stats.totalTyrantFirebolts + 1;
                    end
                elseif sub == "SPELL_CAST_START" and aura_env.demons.imps[source] then
                    local haste = 1 + UnitSpellHaste("player") / 100;
                    local castTime = 2 / haste;
                    aura_env.demons.imps[source].castingUntil = time + castTime;
                    aura_env.demons.imps[source].active = time;                    
                    local delay = 0.2;
                    C_Timer.After( castTime + delay, function()     
                            WeakAuras.ScanEvents("DEMONTIMER_IMP_UPDATE", source) 
                    end );
                end
                
                aura_env.updateImps(states);
            end
        end
    elseif event == "DEMONTIMER_IMP_UPDATE" then
        local source = ...;
        if source then
            if aura_env.demons.imps[source] and aura_env.demons.imps[source].castingUntil and aura_env.demons.imps[source].castingUntil < time then
                aura_env.updateImps(states);
            end
        else
            aura_env.updateImps(states);            
        end
    elseif event == "FRAME_UPDATE" then
        if not aura_env.last or aura_env.last < GetTime() - aura_env.config.interval then
            aura_env.updateImps(states);
            aura_env.scanDeCon();
            --  return true;
        end
        --return;
    elseif event == "PLAYER_ENTERING_WORLD" or event == "OPTIONS" or event == "UNIT_PET" then
        aura_env.scanDeCon();
    else
        local _, arg2 = ...;
        aura_env.handleStats(event, arg2);
    end
    return true;
end