-----------------------------------------------------------------------
-- Local Globals ------------------------------------------------------
-----------------------------------------------------------------------
local announceEvents = 0
local bite_history = 0
local is_debug = false
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
    -- Only for clients and only ever do it once
    if not isClient() or announceEvents >= 2 then
        return
    end

    -- First time attempting this always fails, wait for 2nd
    if announceEvents == 0 then
        announceEvents = announceEvents + 1
        return
    end

    -- If you made it this far you're a client and it's the 2nd try
    -- which is the first announcement event
    processGeneralMessage("has connected")
    announceEvents = 2
end

local function checkBites(player)
    -- Count Bites by looping through body parts
    local bodyParts = player:getBodyDamage():getBodyParts()
    local bodyPartIndex = BodyPartType.ToIndex(BodyPartType.MAX) - 1
    local biteCount = 0
    for i = 0, bodyPartIndex do
        if bodyParts:get(i):bitten() then
            biteCount = biteCount + 1
        end 
    end

    -- if the bite count is different than bite history, announce 
    -- we have a new bite
    if biteCount ~= bite_history then 
        HaloMessage("FUCK I'M BIT!", font_red)
    end
    bite_history = biteCount
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
