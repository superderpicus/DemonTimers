function(states, event, ...)
    local time = GetTime();
    local aura_env = aura_env;
    local summonTable = aura_env.summonTable; 

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        if not ... then return; end -- checking for 'dummy' events
        local _, sub, _, source, _, _, _, dest, _, _, _, spell, _ = ...;
        if source == WeakAuras.myGUID then -- source was player unit
            local entry = summonTable[spell];
            if sub == "SPELL_SUMMON" and entry.enabled then  -- summoned unit that is valid on the summon table
                aura_env.print(spell, entry.name, 'spawned'); -- debugging information
                
                if entry.name == "Wild Imp" then -- imps have to be handled differently
                    aura_env.imps[dest] = { show = true, hpMod = entry.hpMod, hpVal = entry.hpVal, name = entry.name, duration = entry.duration, casts = aura_env.impCasts, maxCasts = aura_env.impCasts, expirationTime = (time + entry.duration), id = spell, active = time, spawn = time, innerDemon = (spell == 279910) };      
                    aura_env.addToStats(entry); -- stat module
                    aura_env.assignImpClump(dest); -- assign an imp clump for this imp
                    aura_env.updateSpecificImp(states, dest); -- update new imp clump (create states)
                    -- after the duration has passed, update the imp again to check if it was autohid,
                    -- and after 60 seconds just delete the imp anyway because fuck it
                    C_Timer.After(entry.duration + 0.1, function() aura_env.updateSpecificImp(states, dest) end)
                    C_Timer.After(60, function() aura_env.removeFromImpClump(states, dest); aura_env.imps[dest] = nil; end);
                else
                    -- for some reason, fel lord summons 'two' exact demons, even though there is only one,
                    -- so we have to account for it otherwise there would be 2 fel lords in the timers
                    if spell == 212459 and (not aura_env.felLord or aura_env.felLord < time) then
                        aura_env.felLord = time + 0.1; -- basically our 'cooldown' variable
                    elseif spell == 212459 then
                        return;
                    end

                    aura_env.demons[dest] = { hpMod = entry.hpMod, hpVal = entry.hpVal, name = entry.name, id = spell, duration = entry.duration, expirationTime = time + entry.duration }; -- new demon indexed as GUID
                    C_Timer.After(entry.duration + 0.1, function() aura_env.updateIndividualDemon(states, dest); end)  -- after timer is up, reevaluate the demon
                    aura_env.addToStats(entry); -- stats module
                    aura_env.updateIndividualDemon(states, dest); -- update new demon (create state)
                    
                    -- if tyrant is summoned we have to evaluate all the new demons' timers
                    if spell == aura_env.summonTable.tyrant then
                        -- cooldown for getting tyrant timer, to prevent multi checks in torghast
                        if not aura_env.checked or aura_env.checked < GetTime() - 1 then
                            aura_env.checked = time;
                            aura_env.getTyrantDuration();
                        end
                        
                        local dur = entry.duration; -- tyrant duration
                        local extend = 15; -- tyrant extension timer
                        aura_env.demons[dest].duration = dur; -- duration updated
                        aura_env.demons[dest].expirationTime = time + dur; -- expirationTime updated
                        
                        -- this tyrant variable is set for imps, because they only
                        -- don't expend energy for 15 seconds. In the case of multiple
                        -- tyrant summons, this will use only the longest value
                        if not aura_env.tyrant or aura_env.tyrant < time then
                            aura_env.tyrant = time + extend;
                        else
                            local n = time + extend;
                            aura_env.tyrant = aura_env.tyrant < n and n or aura_env.tyrant;
                        end
                        
                        -- extend demons, as long as they are not on the blacklist
                        for k, v in pairs(aura_env.demons) do
                            if (not aura_env.extensionBlacklist[v.id]) and v.duration and v.expirationTime then
                                v.duration = v.duration + extend;
                                v.expirationTime = v.expirationTime + extend;
                                if aura_env.config.printStats then aura_env.stats.totalTyrantExtension = aura_env.stats.totalTyrantExtension + extend; end -- stats module
                                aura_env.updateIndividualDemon(states, k);
                                C_Timer.After(v.expirationTime - GetTime() + 0.1, function() aura_env.updateIndividualDemon(states, k); end) -- update demons after they expire
                            end
                        end
                        
                        -- 'extend' imps, lol they already last 40 seconds who cares
                        for _,v in pairs(aura_env.imps) do
                            if v.duration and v.expirationTime then
                                v.duration = v.duration + extend;
                                v.expirationTime = v.expirationTime + extend;
                            end
                        end
                    end
                end
            elseif sub == "SPELL_AURA_APPLIED" and summonTable[spell] then -- this will cover nether portal and subjugate
                local entry = summonTable[spell];
                if entry.enabled then
                    -- subjugate was enabled
                    aura_env.demons[dest] = { name = entry.name, id = spell, duration = entry.duration, expirationTime = time + entry.duration }; 
                    aura_env.updateIndividualDemon(states, dest);
                end
            elseif sub == "SPELL_AURA_REMOVED" and summonTable[spell] then -- removed
                -- subjugate doesn's exist anymore
                for _,v in pairs(aura_env.demons) do
                    if v.id and v.id == spell then
                        v.show = false;
                        v.changed = true; 
                    end
                end
            elseif sub == "SPELL_CAST_SUCCESS" and spell == 196277 then -- implosion cast
                aura_env.imploded = true;
                aura_env.updateImps(states);
            elseif (sub == "UNIT_DIED" or sub == "UNIT_DESTROYED" or sub == "UNIT_DISSIPATES") and (aura_env.imps[dest] or states[dest] or WeakAuras.myGUID == dest) then
                if dest == WeakAuras.myGUID then 
                    -- player died, all demons have to be wiped
                    aura_env.demons = {};
                    aura_env.imps = {};
                    aura_env.updateIndividualDemon(states, dest);
                else
                    -- demon died, wipe it
                    if aura_env.imps[dest] then 
                        aura_env.imps[dest] = nil; 
                        aura_env.updateSpecificImp(states, dest)
                    else
                        aura_env.demons[dest] = nil;
                        aura_env.updateIndividualDemon(states, dest);
                    end                
                end 
            end
            
            if (spell == 105174 or spell == 86040) then 
                if sub == 'SPELL_CAST_SUCCESS' then
                    aura_env.addImpClump(time); -- create an imp clump from the HoG
                    -- Tracking horned nightmare for the 'stat' part of the weak aura
                    if (aura_env.config.printStats) then
                        aura_env.listening = true;
                        aura_env.stats.hogs = aura_env.stats.hogs + 1;
                        aura_env.sampleUnit = nil;
                    end
                elseif sub == 'SPELL_DAMAGE' and aura_env.config.printStats then
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
            if summonTable[summonTable.HoGImp].enabled or summonTable[summonTable.IDImp].enabled then
                local tyrantActive = aura_env.tyrant and aura_env.tyrant > time; -- tyrant active boolean
                local timeForTyrant = tyrantActive and aura_env.tyrant - time or -1000000000; -- remaining time on tyrant
                
                if sub == "SPELL_CAST_SUCCESS" and aura_env.imps[source] then
                    if aura_env.config.printStats then aura_env.stats.totalFirebolts = aura_env.stats.totalFirebolts + 1; end
                    if (not tyrantActive) then
                        aura_env.imps[source].casts = aura_env.imps[source].casts - 1;
                        aura_env.imps[source].castingUntil = nil;
                        aura_env.imps[source].active = time;
                        aura_env.updateSpecificImp(states, source);

                        if aura_env.imps[source].casts <= 0 then -- yeet
                            aura_env.imps[source].show = false;
                            aura_env.removeFromImpClump(states, source);
                            C_Timer.After(aura_env.despawnDelay, function() 
                                    aura_env.imps[source] = nil; 
                                    aura_env.updateSpecificImp(states, source) end);
                        end
                    else
                        if aura_env.config.printStats then aura_env.stats.totalTyrantFirebolts = aura_env.stats.totalTyrantFirebolts + 1; end
                    end
                elseif sub == "SPELL_CAST_START" and aura_env.imps[source] then
                    local haste = 1 + UnitSpellHaste("player") / 100;
                    local castTime = 2 / haste;
                    
                    aura_env.imps[source].castingUntil = time + castTime;
                    aura_env.imps[source].active = time;
                    aura_env.updateSpecificImp(states, source);
                    
                    local delay = 0.2;
                    if (not tyrantActive) or (timeForTyrant < (time + castTime)) then
                        C_Timer.After( castTime + delay, function()     
                                --WeakAuras.ScanEvents("DEMONTIMER_IMP_UPDATE", source) 
                                aura_env.updateSpecificImp(states, source); 
                        end );
                    end
                end
            end
        end
    elseif event == "FRAME_UPDATE" then
        if not aura_env.last or aura_env.last < GetTime() - aura_env.config.interval then
            aura_env.updateFillerImps(states);
            --aura_env.updateImps(states);
            aura_env.updateText();
            aura_env.scanDeCon();
        end
    elseif event == "PLAYER_ENTERING_WORLD" or event == "OPTIONS" or event == "UNIT_PET" then
        aura_env.scanDeCon();
    else
        local _, arg2 = ...;
        aura_env.handleStats(event, arg2);
    end
    return true;
end