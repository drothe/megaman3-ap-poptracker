-- this is an example/default implementation for AP autotracking
-- it will use the mappings defined in item_mapping.lua and location_mapping.lua to track items and locations via their ids
-- it will also keep track of the current index of on_item messages in CUR_INDEX
-- addition it will keep track of what items are local items and which one are remote using the globals LOCAL_ITEMS and GLOBAL_ITEMS
-- this is useful since remote items will not reset but local items might
-- if you run into issues when touching A LOT of items/locations here, see the comment about Tracker.AllowDeferredLogicUpdate in autotracking.lua
ScriptHost:LoadScript("scripts/autotracking/item_mapping.lua")
ScriptHost:LoadScript("scripts/autotracking/location_mapping.lua")
-- used for hint tracking to quickly map hint status to a value from the Highlight enum
HINT_STATUS_MAPPING = {}
if Highlight then
	HINT_STATUS_MAPPING = {
		[20] = Highlight.Avoid,
		[40] = Highlight.None,
		[10] = Highlight.NoPriority,
		[0] = Highlight.Unspecified,
		[30] = Highlight.Priority,
	}
end

CUR_INDEX = -1
LOCAL_ITEMS = {}
GLOBAL_ITEMS = {}

-- gets the data storage key for hints for the current player
-- returns nil when not connected to AP
function getHintDataStorageKey()
	if AutoTracker:GetConnectionState("AP") ~= 3 or Archipelago.TeamNumber == nil or Archipelago.TeamNumber == -1 or Archipelago.PlayerNumber == nil or Archipelago.PlayerNumber == -1 then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print("Tried to call getHintDataStorageKey while not connect to AP server")
		end
		return nil
	end
	return string.format("_read_hints_%s_%s", Archipelago.TeamNumber, Archipelago.PlayerNumber)
end

function getDocRobotStatusKey()
	return string.format("MM3_DOC_STATUS_%s_%s", Archipelago.TeamNumber, Archipelago.PlayerNumber)
end

-- gets the data storage key for hints for the current player
-- returns nil when not connected to AP
function getRetrievedStorageKeys()
	if AutoTracker:GetConnectionState("AP") ~= 3 or Archipelago.TeamNumber == nil or Archipelago.TeamNumber == -1 or Archipelago.PlayerNumber == nil or Archipelago.PlayerNumber == -1 then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print("Tried to call getRetrievedStorageKeys while not connect to AP server")
		end
		return nil
	end
	keys = {
		string.format("MM3_LAST_WILY_%s_%s", Archipelago.TeamNumber, Archipelago.PlayerNumber),
		getDocRobotStatusKey()
	}

	return keys
end

-- resets an item to its initial state
function resetItem(item_code, item_type)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: resetting item %s of type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = false
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			obj.CurrentStage = 0
			obj.Active = false
		elseif item_type == "consumable" then
			obj.AcquiredCount = 0
		elseif item_type == "custom" then
			-- your code for your custom lua items goes here
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: tried to reset static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"resetItem: tried to reset composite_toggle item %s but composite_toggle cannot be accessed via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("resetItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("resetItem: could not find item object for code %s", item_code))
	end
end

-- advances the state of an item
function incrementItem(item_code, item_type, multiplier)
	local obj = Tracker:FindObjectForCode(item_code)
	if obj then
		item_type = item_type or obj.Type
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: code: %s, type %s", item_code, item_type))
		end
		if item_type == "toggle" or item_type == "toggle_badged" then
			obj.Active = true
		elseif item_type == "progressive" or item_type == "progressive_toggle" then
			if obj.Active then
				obj.CurrentStage = obj.CurrentStage + 1
			else
				obj.Active = true
			end
		elseif item_type == "consumable" then
			obj.AcquiredCount = obj.AcquiredCount + obj.Increment * multiplier
		elseif item_type == "custom" then
			-- your code for your custom lua items goes here
		elseif item_type == "static" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: tried to increment static item %s", item_code))
		elseif item_type == "composite_toggle" and AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format(
				"incrementItem: tried to increment composite_toggle item %s but composite_toggle cannot be access via lua." ..
				"Please use the respective left/right toggle item codes instead.", item_code))
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("incrementItem: unknown item type %s for code %s", item_type, item_code))
		end
	elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("incrementItem: could not find object for code %s", item_code))
	end
end

-- apply everything needed from slot_data, called from onClear
function apply_slot_data(slot_data)
	-- put any code here that slot_data should affect (toggling setting items for example)
end

-- TODO: Can we support a "cleared + inaccessible" state here?
function stage_cleared(robot)
    if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
        print(string.format("stage_cleared() called for %s", robot))
    end
    local clearobj = Tracker:FindObjectForCode(robot.."_cleared")
    clearobj.Active = true
end

function get_enabled_locs()
    -- Snake Man 1Up / E-Tank
    local etank = 0x225
    -- Snake Man Weapon / Health Energy
    local energypickup = 0x224

    local etanks_enabled = 0
    local energypickups_enabled = 0
    for _, i in ipairs(Archipelago.CheckedLocations) do
        if i == etank then
            etanks_enabled = 1
        elseif i == energypickup then
            energypickups_enabled = 1
        end
    end
    for _, i in ipairs(Archipelago.MissingLocations) do
        if i == etank then
            etanks_enabled = 1
        elseif i == energypickup then
            energypickups_enabled = 1
        end
    end
    return etanks_enabled, energypickups_enabled
end


-- called right after an AP slot is connected
function onClear(slot_data)
	-- use bulk update to pause logic updates until we are done resetting all items/locations
	Tracker.BulkUpdate = true
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onClear, slot_data:\n%s", dump_table(slot_data)))
	end
	CUR_INDEX = -1
	-- reset locations
	for _, mapping_entry in pairs(LOCATION_MAPPING) do
		for _, location_table in ipairs(mapping_entry) do
			if location_table then
				local location_code = location_table[1]
				if location_code then
					if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
						print(string.format("onClear: clearing location %s", location_code))
					end
					if location_code:sub(1, 1) == "@" then
						local obj = Tracker:FindObjectForCode(location_code)
						if obj then
							obj.AvailableChestCount = obj.ChestCount
							if obj.Highlight then
								obj.Highlight = Highlight.None
							end
						elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
							print(string.format("onClear: could not find location object for code %s", location_code))
						end
					else
						-- reset hosted item
						local item_type = location_table[2]
						resetItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping location_table with no location_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty location_table"))
			end
		end
	end
	-- reset items
	for _, mapping_entry in pairs(ITEM_MAPPING) do
		for _, item_table in ipairs(mapping_entry) do
			if item_table then
				local item_code = item_table[1]
				local item_type = item_table[2]
				if item_code then
					resetItem(item_code, item_type)
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onClear: skipping item_table with no item_code"))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping empty item_table"))
			end
		end
	end
	apply_slot_data(slot_data)
	LOCAL_ITEMS = {}
	GLOBAL_ITEMS = {}
	-- manually run snes interface functions after onClear in case we need to update them (i.e. because they need slot_data)
	if PopVersion < "0.20.1" or AutoTracker:GetConnectionState("SNES") == 3 then
		-- add snes interface functions here
	end
	-- setup data storage tracking for hint tracking
	local data_strorage_keys = {}
	if PopVersion >= "0.32.0" then
		data_strorage_keys = getRetrievedStorageKeys()
		-- data_strorage_keys = { getHintDataStorageKey() }
		table.insert(data_strorage_keys, getHintDataStorageKey())
	end

	-- subscribes to the data storage keys for updates
	-- triggers callback in the SetNotify handler on update
	Archipelago:SetNotify(data_strorage_keys)
	-- gets the current value for the data storage keys
	-- triggers callback in the Retrieved handler when result is received
	Archipelago:Get(data_strorage_keys)
	Tracker.BulkUpdate = false

	Tracker:FindObjectForCode("etanks").CurrentStage, Tracker:FindObjectForCode("energypickups").CurrentStage = get_enabled_locs()

	-- We already have all the information we need to add weakness logic in slot_data.
	-- from apworld:
	-- bosses: dict[str, int] = {
	--     "Needle Man": 0,
	--     "Magnet Man": 1,
	--     "Gemini Man": 2,
	--     "Hard Man": 3,
	--     "Top Man": 4,
	--     "Snake Man": 5,
	--     "Spark Man": 6,
	--     "Shadow Man": 7,
	--     "Doc Robot (Metal)": 8,
	--     "Doc Robot (Quick)": 9,
	--     "Doc Robot (Air)": 10,
	--     "Doc Robot (Crash)": 11,
	--     "Doc Robot (Flash)": 12,
	--     "Doc Robot (Bubble)": 13,
	--     "Doc Robot (Wood)": 14,
	--     "Doc Robot (Heat)": 15,
	--     "Break Man": 16,
	--     "Kamegoro Maker": 17,
	--     "Yellow Devil MK-II": 18,
	--     "Holograph Mega Man": 19,
	--     "Wily Machine 3": 20,
	--     "Gamma": 21
	-- }
	-- weapons_to_id: dict[str, int] = {
	--     "Mega Buster": 0,
	--     "Needle Cannon": 1,
	--     "Magnet Missile": 2,
	--     "Gemini Laser": 3,
	--     "Hard Knuckle": 4,
	--     "Top Spin": 5,
	--     "Search Snake": 6,
	--     "Spark Shot": 7,
	--     "Shadow Blade": 8,
	-- }
	-- weapon_damage: dict[int, list[int]] = {
	--     "0": [1, 2, 1, 1, 2, 1, 1, 1, 1, 1, 2, 2, 1, 1, 1, 1, 1, 3, 1, 1, 1, 0, ],  # Mega Buster
	--     "1": [4, 1, 1, 0, 2, 4, 2, 1, 0, 1, 1, 2, 4, 2, 4, 2, 0, 3, 1, 1, 1, 0, ],  # Needle Cannon
	--     "2": [1, 4, 2, 4, 1, 0, 0, 1, 4, 2, 4, 1, 1, 0, 0, 1, 0, 3, 1, 0, 1, 0, ],  # Magnet Missile
	--     "3": [7, 2, 4, 1, 0, 1, 1, 1, 1, 4, 2, 0, 4, 1, 1, 1, 0, 3, 1, 1, 1, 0, ],  # Gemini Laser
	--     "4": [0, 2, 2, 4, 7, 2, 2, 2, 4, 1, 2, 7, 0, 2, 2, 2, 0, 1, 5, 4, 7, 4, ],  # Hard Knuckle
	--     "5": [1, 1, 2, 0, 4, 2, 1, 7, 0, 1, 1, 4, 1, 1, 2, 7, 0, 1, 0, 7, 0, 2, ],  # Top Spin
	--     "6": [1, 1, 5, 0, 1, 4, 0, 1, 0, 4, 1, 1, 1, 0, 4, 1, 0, 1, 0, 7, 4, 2, ],  # Search Snake
	--     "7": [0, 7, 1, 0, 1, 1, 4, 1, 2, 1, 4, 1, 0, 4, 1, 1, 0, 0, 0, 0, 7, 0, ],  # Spark Shot
	--     "8": [2, 7, 2, 0, 1, 2, 4, 4, 2, 2, 0, 1, 2, 4, 2, 4, 0, 1, 3, 2, 2, 2, ],  # Shadow Blade
	-- }

	-- slot_data["weapon_damage"][weapon_idx][boss_idx]
	WEAPON_DAMAGE = slot_data["weapon_damage"]
end

-- called when an item gets collected
function onItem(index, item_id, item_name, player_number)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onItem: %s, %s, %s, %s, %s", index, item_id, item_name, player_number, CUR_INDEX))
	end
	if not AUTOTRACKER_ENABLE_ITEM_TRACKING then
		return
	end
	if index <= CUR_INDEX then
		return
	end
	local is_local = player_number == Archipelago.PlayerNumber
	CUR_INDEX = index
	local mapping_entry = ITEM_MAPPING[item_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onItem: could not find item mapping for id %s", item_id))
		end
		return
	end
	for _, item_table in pairs(mapping_entry) do
		if item_table then
			local item_code = item_table[1]
			local item_type = item_table[2]
			local multiplier = item_table[3] or 1
			if item_code then
				incrementItem(item_code, item_type, multiplier)
				-- keep track which items we touch are local and which are global
				if is_local then
					if LOCAL_ITEMS[item_code] then
						LOCAL_ITEMS[item_code] = LOCAL_ITEMS[item_code] + 1
					else
						LOCAL_ITEMS[item_code] = 1
					end
				else
					if GLOBAL_ITEMS[item_code] then
						GLOBAL_ITEMS[item_code] = GLOBAL_ITEMS[item_code] + 1
					else
						GLOBAL_ITEMS[item_code] = 1
					end
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onClear: skipping item_table with no item_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onClear: skipping empty item_table"))
		end
	end
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("local items: %s", dump_table(LOCAL_ITEMS)))
		print(string.format("global items: %s", dump_table(GLOBAL_ITEMS)))
	end
	-- track local items via snes interface
	if PopVersion < "0.20.1" or AutoTracker:GetConnectionState("SNES") == 3 then
		-- add snes interface functions for local item tracking here
	end
end

-- called when a location gets cleared
function onLocation(location_id, location_name)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onLocation: %s, %s", location_id, location_name))
	end
	if not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
	local mapping_entry = LOCATION_MAPPING[location_id]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: could not find location mapping for id %s", location_id))
		end
		return
	end
	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			if location_code then
				local obj = Tracker:FindObjectForCode(location_code)
				if obj then
					if location_code:sub(1, 1) == "@" then
						obj.AvailableChestCount = obj.AvailableChestCount - 1
					else
						-- increment hosted item
						local item_type = location_table[2]
						incrementItem(location_code, item_type)
					end
				elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
					print(string.format("onLocation: could not find object for code %s", location_code))
				end
			elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
				print(string.format("onLocation: skipping location_table with no location_code"))
			end
		elseif AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("onLocation: skipping empty location_table"))
		end
	end

	--handle stage clear events
    if location_id == 0x00001 then
        stage_cleared("needle_man")
    end
    if location_id == 0x00002 then
        stage_cleared("magnet_man")
    end
    if location_id == 0x00003 then
        stage_cleared("gemini_man")
    end
    if location_id == 0x00004 then
        stage_cleared("hard_man")
    end
    if location_id == 0x00005 then
        stage_cleared("top_man")
    end
    if location_id == 0x00006 then
        stage_cleared("snake_man")
    end
    if location_id == 0x00007 then
        stage_cleared("spark_man")
    end
    if location_id == 0x00008 then
        stage_cleared("shadow_man")
    end

	-- TODO: This should probably be tied to MM3_LAST_WILY
    if location_id == 0x0000f then
        stage_cleared("break_man")
    end

	-- TODO: Move handling to datastorage using MM3_LAST_WILY
    if location_id == 0x00009 then
        Tracker:FindObjectForCode("wily_1_cleared").Active = true
    end
    if location_id == 0x0000A then
        Tracker:FindObjectForCode("wily_2_cleared").Active = true
    end
    if location_id == 0x0000B then
        Tracker:FindObjectForCode("wily_3_cleared").Active = true
    end
	-- Kind of a hack - there's not boss of the refight stage, so I'm just using the last powerup
    if location_id == 0x0027F then
        Tracker:FindObjectForCode("wily_4_cleared").Active = true
    end
    if location_id == 0x0000D then
        Tracker:FindObjectForCode("wily_5_cleared").Active = true
    end
end

-- called when a locations is scouted
function onScout(location_id, location_name, item_id, item_name, item_player)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onScout: %s, %s, %s, %s, %s", location_id, location_name, item_id, item_name,
			item_player))
	end
	-- not implemented yet :(
end

-- called when a bounce message is received
function onBounce(json)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print(string.format("called onBounce: %s", dump_table(json)))
	end
	-- your code goes here
end

-- NEEDLE + GEMINI = 5
-- SPARK + GEMINI = 68
-- SPARK + GEMINI + SHADOW = 196
DOC_STAGE_CODES = {
    NEEDLE = 0x1,
    GEMINI = 0x4, 
    SPARK = 0x40,
    SHADOW = 0x80
}

-- called whenever Archipelago:Get returns data from the data storage or
-- whenever a subscribed to (via Archipelago:SetNotify) key in data storgae is updated
-- oldValue might be nil (always nil for "_read" prefixed keys and via retrieved handler (from Archipelago:Get))
function onDataStorageUpdate(key, value, oldValue)
	if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
		print("Data storage update: %s = %s (old: %s)", key, value, oldValue)
	end
	--if you plan to only use the hints key, you can remove this if
	if key == getHintDataStorageKey() then
		onHintsUpdate(value)
	end
	if key == getDocRobotStatusKey() then
		if value & DOC_STAGE_CODES.NEEDLE == DOC_STAGE_CODES.NEEDLE then
			stage_cleared("doc_needle")
		end
		if value & DOC_STAGE_CODES.GEMINI == DOC_STAGE_CODES.GEMINI then
			stage_cleared("doc_gemini")
		end
		if value & DOC_STAGE_CODES.SPARK == DOC_STAGE_CODES.SPARK then
			stage_cleared("doc_spark")
		end
		if value & DOC_STAGE_CODES.SHADOW == DOC_STAGE_CODES.SHADOW then
			stage_cleared("doc_shadow")
		end
	end
end

-- called whenever the hints key in data storage updated
-- NOTE: this should correctly handle having multiple mapped locations in a section.
--       if you only map sections 1 to 1 you can simplfy this. for an example see
--       https://github.com/Cyb3RGER/sm_ap_tracker/blob/main/scripts/autotracking/archipelago.lua
function onHintsUpdate(hints)
	-- Highlight is only supported since version 0.32.0
	if PopVersion < "0.32.0" or not AUTOTRACKER_ENABLE_LOCATION_TRACKING then
		return
	end
	local player_number = Archipelago.PlayerNumber
	-- get all new highlight values per section
	local sections_to_update = {}
	for _, hint in ipairs(hints) do
		-- we only care about hints in our world
		if hint.finding_player == player_number then
			updateHint(hint, sections_to_update)
		end
	end
	-- update the sections
	for location_code, highlight_code in pairs(sections_to_update) do
		-- find the location object
		local obj = Tracker:FindObjectForCode(location_code)
		-- check if we got the location and if it supports Highlight
		if obj and obj.Highlight then
			obj.Highlight = highlight_code
		end
	end
end

-- update section highlight based on the hint
function updateHint(hint, sections_to_update)
	-- get the highlight enum value for the hint status
	local hint_status = hint.status
	local highlight_code = nil
	if hint_status then
		highlight_code = HINT_STATUS_MAPPING[hint_status]
	end
	if not highlight_code then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("updateHint: unknown hint status %s for hint on location id %s", hint.status,
				hint.location))
		end
		-- try to "recover" by checking hint.found (older AP versions without hint.status)
		if hint.found == true then
			highlight_code = Highlight.None
		elseif hint.found == false then
			highlight_code = Highlight.Unspecified
		else
			return
		end
	end
	-- get the location mapping for the location id
	local mapping_entry = LOCATION_MAPPING[hint.location]
	if not mapping_entry then
		if AUTOTRACKER_ENABLE_DEBUG_LOGGING_AP then
			print(string.format("updateHint: could not find location mapping for id %s", hint.location))
		end
		return
	end
	--get the "highest" highlight value pre section
	for _, location_table in pairs(mapping_entry) do
		if location_table then
			local location_code = location_table[1]
			-- skip hosted items, they don't support Highlight
			if location_code and location_code:sub(1, 1) == "@" then
				-- see if we already set a Highlight for this section
				local existing_highlight_code = sections_to_update[location_code]
				if existing_highlight_code then
					-- make sure we only replace None or "increase" the highlight but never overwrite with None
					-- this so sections with mulitple mapped locations show the "highest" Highlight and
					-- only show no Highlight when all hints are found
					if existing_highlight_code == Highlight.None or (existing_highlight_code < highlight_code and highlight_code ~= Highlight.None) then
						sections_to_update[location_code] = highlight_code
					end
				else
					sections_to_update[location_code] = highlight_code
				end
			end
		end
	end
end

-- add AP callbacks
-- un-/comment as needed
Archipelago:AddClearHandler("clear handler", onClear)
if AUTOTRACKER_ENABLE_ITEM_TRACKING then
	Archipelago:AddItemHandler("item handler", onItem)
end
if AUTOTRACKER_ENABLE_LOCATION_TRACKING then
	Archipelago:AddLocationHandler("location handler", onLocation)
end
Archipelago:AddRetrievedHandler("retrieved handler", onDataStorageUpdate)
Archipelago:AddSetReplyHandler("set reply handler", onDataStorageUpdate)
-- Archipelago:AddScoutHandler("scout handler", onScout)
-- Archipelago:AddBouncedHandler("bounce handler", onBounce)
