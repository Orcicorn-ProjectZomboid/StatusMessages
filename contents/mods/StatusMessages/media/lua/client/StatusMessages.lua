-----------------------------------------------------------------------
-- Local Globals ------------------------------------------------------
-----------------------------------------------------------------------
local is_debug = true;                             -- <-- DEBUG MODE ON/OFF (Console messages)
local time_loaded = 0;                              -- 0: First connect, 1: In-Game Load, 2+: Redundancy
local bite_history = 0;                             -- Bite count since last update
local scratch_history = 0;                          -- Scratch count since last update
local font_white = HaloTextHelper.getColorWhite();  -- White halo message
local font_red = HaloTextHelper.getColorRed();      -- Red halo message
local font_green = HaloTextHelper.getColorGreen();  -- Green halo message

-----------------------------------------------------------------------
-- Functions ----------------------------------------------------------
-----------------------------------------------------------------------
local function HaloMessage(message, color)
    --  @desc       Adds a simple text message above the player's head
    --  @params     optional    string      The text to show above the head
    --  @params     required    object      The color to be used (defaults to white)      
    
    -- If no color, default to white
    if color == nil then
        color = font_white;
    end
    
    -- Can't call debug from here for some reason, do it manually
    if is_debug == true then
        print("DEBUG: HALO: " .. message);
    end

    -- Add status message to player halo text
    HaloTextHelper.addText(getSpecificPlayer(0), message, color);
end


local function debug(message)
    --  @desc       Adds console messages when the script is running in debug mode (see is_debug)
    --  @params     required        string      The message to print to the console
    if is_debug == true then
        print(message);
    end
end


local function printEvent(event, ...)
    -- Debug event parameters for development purposes
    -- Serves no purpose on distributed addons
    print("--------------------------------------")
    local d = {select(1,...)} -- convert the ... argument to a table
    for i, v in ipairs(d) do d[i] = tostring(v) end -- convert each to a string representation
    print("-- "..event .. "("..table.concat(d, ", ")..")");
    print("--");
    print("--");
end

-----------------------------------------------------------------------
-- Event Handlers -----------------------------------------------------
-----------------------------------------------------------------------
local function announceLogin()
    -- @desc        When connecting to a multiplayer server send a message to the chat window
    --              after connection has succeeded letting others know you have arrived
    -- @event       OnGameTimeLoaded()
    -- @params      none

    -- If not a client or already announced, abort asap
    if not isClient() or time_loaded >= 2 then
        return;
    end

    -- Event triggers more than once. First time it triggers is when
    -- client is loaded and this is too soon to send a message. Wait for
    -- the second trigger which is in-world loaded. Any subsequent trigger
    -- is not our concern
    if time_loaded == 0 then 
        time_loaded = 1;
    elseif time_loaded == 1 then
        processGeneralMessage(getText("IGUI_ChatText_Connected"));
        time_loaded = 2;
    end
end


local function checkBites(player)
    -- @desc        When the player character damage is updated, check for new bites and scratches
    -- @event       OnPlayerUpdate()
    -- @params      IsoGameCharacter class
    
    -- Loop through body parts and count the current bites and scratches
    local bodyParts = player:getBodyDamage():getBodyParts();
    local bodyPartIndex = BodyPartType.ToIndex(BodyPartType.MAX) - 1;
    local biteCount = 0;
    local scratchCount = 0;
    for i = 0, bodyPartIndex do
        if bodyParts:get(i):bitten() then
            biteCount = biteCount + 1;
        end 
        if bodyParts:get(i):scratched() then
            scratchCount = scratchCount + 1;
        end 
    end

    debug("Bites: Current " .. biteCount .. " vs History " .. bite_history);
    debug("Scratches: Current " .. scratchCount .. " vs History " .. scratch_history);

    -- If there is atleast one bite and it is different from the last update
    -- then say I'm bit. if you're online, add that to the chat messages too
    if biteCount > 0 then 
        if biteCount ~= bite_history then 
            -- Oopsie, we're bit!
            HaloMessage(getText("IGUI_PlayerText_Bite"), font_red);
            -- If we're online, warn others
            if isClient() and time_loaded >= 2 then
                processGeneralMessage(getText("IGUI_ChatText_Bite"));
            end
        end
    end
    bite_history = biteCount;

    -- If there is atleast one scratch and it is greater than the last time
    -- we checked, we have a new scratch. Just a simple halo message is fine
    if scratchCount > 0 then 
        if scratchCount > scratch_history then
            HaloMessage(getText("IGUI_PlayerText_Scratch"), font_green);
        end 
    end
    scratch_history = scratchCount;
end


local function weatherPeriodStop(weatherperiod)
    -- @desc        When a weather storm has finished, just make a simple halo message about it
    -- @event       OnWeatherPeriodStop()
    -- @params      WeatherPeriod class
    debug("Weather Stop");
    HaloMessage(getText("IGUI_PlayerText_WeatherClear"));
end


local function weatherPeriodStart(WeatherPeriod)
    -- @desc        When a weather storm begins, make a halo message about it
    -- @event       OnWeatherPeriodStart()
    -- @params      WeatherPeriod class

    local msg = ""
    if WeatherPeriod:hasBlizzard() then
        msg = getText("IGUI_PlayerText_WeatherBlizzard");
    end
    if WeatherPeriod:hasHeavyRain() then
        msg = getText("IGUI_PlayerText_WeatherHeavyRain");
    end
    if WeatherPeriod:hasStorm() then
        msg = getText("IGUI_PlayerText_WeatherStorm");
    end
    if WeatherPeriod:hasTropical() then
        msg = getText("IGUI_PlayerText_WeatherTropical");
    end

    if msg ~= "" then
        HaloMessage(msg);
    end
end


local function weaponMessages(character, weapon)
    -- @desc        After each attack, see if the player needs to know something is wrong
    -- @event       OnWeaponSwing
    -- @params      IsoGameCharacter, HandWeapon

    -- Local Player only, Weapon must exist and weapon needs ammo
    -- No longer checking for weapon:isRanged() as some mods act strangely so just check for ammo
    if character:isLocalPlayer() then
        if weapon ~= nil then
            if weapon:getAmmoType() ~= nil then
                -- Get Bullet count
                bullets = weapon:getCurrentAmmoCount();
                if weapon:isRoundChambered() then
                    bullets = bullets + 1;
                end
                -- STATUS: Jammed
                if weapon:isJammed() then
                    debug("Weapon is jammed");
                    HaloMessage(getText("IGUI_PlayerText_WeaponJam"), font_red);
                end
                -- STATUS: Reload
                if bullets < 1 then
                    debug("Weapon needs reloading");
                    HaloMessage(getText("IGUI_PlayerText_WeaponReload"));
                end
                -- STATUS: Rack
                if weapon:haveChamber() and weapon:isRoundChambered() == false and bullets > 0 then
                    debug("Weapon needs to be racked");
                    HaloMessage(getText("IGUI_PlayerText_WeaponRack"));
                end
            end 
        end
    end
end


-----------------------------------------------------------------------
-- Event Bindings -----------------------------------------------------
-----------------------------------------------------------------------
Events.OnWeatherPeriodStart.Add(weatherPeriodStart);            -- Storm beings
Events.OnWeatherPeriodStop.Add(weatherPeriodStop)               -- Storm Ends
Events.OnWeaponSwing.Add(weaponMessages)                        -- Weapon attack finishes
Events.OnGameTimeLoaded.Add(announceLogin)                      -- Connection
Events.OnPlayerUpdate.Add(checkBites)                           -- Damage taken

--DEBUG: Event Parameters
--Events.OnWeaponSwing.Add(function(...) printEvent("OnWeaponSwing", ...) end)
