-- put logic functions here using the Lua API: https://github.com/black-sliver/PopTracker/blob/master/doc/PACKS.md#lua-interface
-- don't be afraid to use custom logic functions. it will make many things a lot easier to maintain, for example by adding logging.
-- to see how this function gets called, check: locations/locations.json
-- example:
function has_more_then_n_consumable(n)
    local count = Tracker:ProviderCountForCode('consumable')
    local val = (count > tonumber(n))
    if ENABLE_DEBUG_LOG then
        print(string.format("called has_more_then_n_consumable: count: %s, n: %s, val: %s", count, n, val))
    end
    if val then
        return 1 -- 1 => access is in logic
    end
    return 0 -- 0 => no access
end


-- function has(item, amount)
--     local count = Tracker:ProviderCountForCode(item)
--     amount = tonumber(amount)
--     if not amount then
--         return count > 0
--     else
--         return count >= amount
--     end
-- end

function has(item)
    local item_obj = Tracker:FindObjectForCode(item)
    return item_obj.Active
end

function has_rush_vertical()
    return has("rush_jet") or has("rush_coil")
end

function can_traverse_long_water()
    return has("rush_jet") or has("rush_marine")
end

WEAPONS = {
    MEGA_BUSTER = "0",
    NEEDLE_CANNON = "1",
    MAGNET_MISSILE = "2",
    GEMINI_LASER = "3",
    HARD_KNUCKLE = "4",
    TOP_SPIN = "5",
    SEARCH_SNAKE = "6",
    SPARK_SHOCK = "7",
    SHADOW_BLADE = "8"
}

WEAPON_CHECKS = {
    [WEAPONS.MEGA_BUSTER] = function() return true end, -- buster is always on
    [WEAPONS.NEEDLE_CANNON] = function() return has("needle_cannon") end,
    [WEAPONS.MAGNET_MISSILE] = function() return has("magnet_missile") end,
    [WEAPONS.GEMINI_LASER] = function() return has("gemini_laser") end,
    [WEAPONS.HARD_KNUCKLE] = function() return has("hard_knuckle") end,
    [WEAPONS.TOP_SPIN] = function() return has("top_spin") end,
    [WEAPONS.SEARCH_SNAKE] = function() return has("search_snake") end,
    [WEAPONS.SPARK_SHOCK] = function() return has("spark_shock") end,
    [WEAPONS.SHADOW_BLADE] = function() return has("shadow_blade") end,
}

BOSSES = {
    NEEDLE_MAN = 0,
    MAGNET_MAN = 1,
    GEMINI_MAN = 2, 
    HARD_MAN = 3,
    TOP_MAN = 4,
    SNAKE_MAN = 5,
    SPARK_MAN = 6,
    SHADOW_MAN = 7,
    DOC_ROBOT_METAL = 8,
    DOC_ROBOT_QUICK = 9,
    DOC_ROBOT_AIR = 10,
    DOC_ROBOT_CRASH = 11,
    DOC_ROBOT_FLASH = 12,
    DOC_ROBOT_BUBBLE = 13,
    DOC_ROBOT_WOOD = 14,
    DOC_ROBOT_HEAT = 15,
    BREAK_MAN = 16,
    KAMEGORO_MAKER = 17,
    YELLOW_DEVIL_MK2 = 18,
    HOLO_MEGA_MAN = 19,
    WILY_MACHINE = 20,
    GAMMA = 21
}

local function getBossID(name)
    -- Returns the ID if found, otherwise returns nil
    return BOSSES[name]
end

WEAPON_DAMAGE = {
    [WEAPONS.MEGA_BUSTER]       = {1, 2, 1, 1, 2, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 3, 1, 1, 1, 0},
    [WEAPONS.NEEDLE_CANNON]     = {4, 1, 1, 0, 2, 4, 2, 1, 0, 1, 1, 2, 4, 2, 4, 2, 0, 3, 1, 1, 1, 0},
    [WEAPONS.MAGNET_MISSILE]    = {1, 4, 2, 4, 1, 0, 0, 1, 4, 2, 4, 1, 1, 0, 0, 1, 0, 3, 1, 0, 1, 0},
    [WEAPONS.GEMINI_LASER]      = {7, 2, 4, 1, 0, 1, 1, 1, 1, 4, 2, 0, 4, 1, 1, 1, 0, 3, 1, 1, 1, 0},
    [WEAPONS.HARD_KNUCKLE]      = {0, 2, 2, 4, 7, 2, 2, 2, 4, 1, 2, 7, 0, 2, 2, 2, 0, 1, 5, 4, 7, 4},
    [WEAPONS.TOP_SPIN]          = {1, 1, 2, 0, 4, 2, 1, 7, 0, 1, 1, 4, 1, 1, 2, 7, 0, 1, 0, 7, 0, 2},
    [WEAPONS.SEARCH_SNAKE]      = {1, 1, 5, 0, 1, 4, 0, 1, 0, 4, 1, 1, 1, 0, 4, 1, 0, 1, 0, 7, 4, 2},
    [WEAPONS.SPARK_SHOCK]       = {0, 7, 1, 0, 1, 1, 4, 1, 2, 1, 4, 1, 0, 4, 1, 1, 0, 0, 0, 0, 7, 0},
    [WEAPONS.SHADOW_BLADE]      = {2, 7, 2, 0, 1, 2, 4, 4, 2, 2, 0, 1, 2, 4, 2, 4, 0, 1, 3, 2, 2, 2},
}

function has_weakness_for(boss_name)
    boss_idx = getBossID(boss_name) + 1  -- stupid LUA indexing from stupid 1
    print(string.format("Checking weaknesses for %s", boss_idx))
    for weapon_idx, damageList in pairs(WEAPON_DAMAGE) do
        if WEAPON_CHECKS[tostring(weapon_idx)]() then
            print(string.format("Weapon %s does %s damage to boss %d", weapon_idx, damageList[boss_idx], boss_idx))
            -- Vanilla rules consider Magnet and Top as buster-weak even though it's just 2, approxomate that
            if weapon_idx == WEAPONS.MEGA_BUSTER and damageList[boss_idx] >= 2 then
                return true
            end
            -- Normal weakness logic
            if damageList[boss_idx] >= 4 then
                return true
            end
        end
    end

    return false
end