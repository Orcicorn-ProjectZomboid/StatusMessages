-----------------------------------------------------------------------
-- Local Globals ------------------------------------------------------
-----------------------------------------------------------------------
local is_debug = false                              -- <-- DEBUG MODE ON/OFF (Console messages)
local time_loaded = 0                               -- 0: First connect, 1: In-Game Load, 2+: Redundancy
local bite_history = 0                              -- Bite count since last update
local scratch_history = 0                           -- Scratch count since last update
local font_white = HaloTextHelper.getColorWhite()
local font_red = HaloTextHelper.getColorRed()
local font_green = HaloTextHelper.getColorGreen()

-----------------------------------------------------------------------
-- Functions ----------------------------------------------------------
-----------------------------------------------------------------------
local function HaloMessage(message, color)
    -- If no color, default to white
    if color == nil then
        color = font_white
    end
    -- Can't call debug from here for some reason, do it manually
    if is_debug == true then
        print("DEBUG: HALO: " .. message)
    end
    -- Add status message to player halo text
    HaloTextHelper.addText(getSpecificPlayer(0), message, color)
end

local function debug(message)
    -- Print debug messages if enabled
    if is_debug == true then
        print(message)
    end
end

local function printEvent(event, ...)
    -- Debugging event parameters
    print("--------------------------------------")
    local d = {select(1,...)} -- convert the ... argument to a table
    for i, v in ipairs(d) do d[i] = tostring(v) end -- convert each to a string representation
    print("-- "..event .. "("..table.concat(d, ", ")..")")
    print("--")
    print("--")
end

-----------------------------------------------------------------------
-- Event Handlers -----------------------------------------------------
-----------------------------------------------------------------------
local function announceLogin()
    -- If not a client or already announced, abort asap
    if not isClient() or time_loaded >= 2 then
        return
    end

    -- Event triggers more than once. First time it triggers is when
    -- client is loaded and this is too soon to send a message. Wait for
    -- the second trigger which is in-world loaded. Any subsequent trigger
    -- is not our concern
    if time_loaded == 0 then 
        time_loaded = 1
    elseif time_loaded == 1 then
        processGeneralMessage("has connected")
        time_loaded = 2
    end
end

local function checkBites(player)
    -- Count Bites by looping through body parts
    local bodyParts = player:getBodyDamage():getBodyParts()
    local bodyPartIndex = BodyPartType.ToIndex(BodyPartType.MAX) - 1
    local biteCount = 0
    local scratchCount = 0
    for i = 0, bodyPartIndex do
        if bodyParts:get(i):bitten() then
            biteCount = biteCount + 1
        end 
        if bodyParts:get(i):scratched() then
            scratchCount = scratchCount + 1
        end 
    end

    debug("Bites: " .. biteCount)
    debug("Scratches: " .. scratchCount)

    -- If there is atleast one bite and it is different from the last update
    -- then say I'm bit. if you're online, add that to the chat messages too
    if biteCount > 0 then 
        if biteCount ~= bite_history then 
            -- Oopsie, we're bit!
            HaloMessage("FUCK I'M BIT!", font_red)
            -- If we're online, warn others
            if isClient() and time_loaded >= 2 then
                processGeneralMessage("has been bit")
            end
        end
        bite_history = biteCount
    end

    -- Scratched?
    if scratchCount > 0 then 
        if scratchCount > scratch_history then
            HaloMessage("Just a scratch", font_green)
        end 
    end
    scratch_history = scratchCount
end

local function weatherPeriodStop(weatherperiod)
    debug("Weather Stop")
    HaloMessage("Finally clearing up")
end

local function weatherPeriodStart(WeatherPeriod)
    local msg = ""
    if WeatherPeriod:hasBlizzard() then
        msg = "Uh oh, a Blizzard"
    end
    if WeatherPeriod:hasHeavyRain() then
        msg = "Looks like heavy rain"
    end
    if WeatherPeriod:hasStorm() then
        msg = "Feels like a Thunderstorm"
    end
    if WeatherPeriod:hasTropical() then
        msg = "Oh fuck, a tropical storm"
    end

    if msg ~= "" then
        HaloMessage(msg)
    end
end
local function weaponMessages(character, weapon)
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
                    HaloMessage("FUCKING JAMMED!", font_red);
                end
                -- STATUS: Reload
                if bullets < 1 then
                    debug("Weapon needs reloading");
                    HaloMessage("Need to reload")
                end
                -- STATUS: Rack
                if weapon:haveChamber() and weapon:isRoundChambered() == false and bullets > 0 then
                    debug("Weapon needs to be racked");
                    HaloMessage("Need to rack")
                end
            end 
        end
    end
end


-----------------------------------------------------------------------
-- Event Bindings -----------------------------------------------------
-----------------------------------------------------------------------
Events.OnWeatherPeriodStart.Add(weatherPeriodStart)
Events.OnWeatherPeriodStop.Add(weatherPeriodStop)
Events.OnWeaponSwing.Add(weaponMessages)
Events.OnGameTimeLoaded.Add(announceLogin)
Events.OnPlayerUpdate.Add(checkBites)
--DEBUG: Event Parameters
--Events.OnWeaponSwing.Add(function(...) printEvent("OnWeaponSwing", ...) end)
