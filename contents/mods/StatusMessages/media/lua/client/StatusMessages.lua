-----------------------------------------------------------------------
-- Local Globals ------------------------------------------------------
-----------------------------------------------------------------------
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
        msg = "Looks like rain"
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
    local player = getPlayer()

    -- Multiplayer fix: Only show halo messages for the player character
    -- ignore all messages from nearby multi-players
    if character == player then
        -- If the weapon is ranged... ranged messages
        if weapon:isRanged() then
            -- Jammed?
            if weapon:isJammed() then
                HaloMessage("FUCKING JAMMED!", font_red)
            end
            -- Reload?
            if weapon:isRoundChambered() ~= true then
                HaloMessage("Need to reload")
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
--DEBUG: Event Parameters
--Events.OnWeaponSwing.Add(function(...) printEvent("OnWeaponSwing", ...) end)
