-- use this file to map the AP item ids to your items
-- first value is the code of the target item and the second is the item type override. The third value is an optional increment multiplier for consumables. (feel free to expand the table with any other values you might need (i.e. special initial values, etc.)!)
-- here are the SM items as an example: https://github.com/Cyb3RGER/sm_ap_tracker/blob/main/scripts/autotracking/item_mapping.lua
BASE_ITEM_ID = 0
ITEM_MAPPING = {
	-- weapons
	[BASE_ITEM_ID + 0x00001] = { { "needle_cannon" } },
	[BASE_ITEM_ID + 0x00002] = { { "magnet_missile" } },
	[BASE_ITEM_ID + 0x00003] = { { "gemini_laser" } },
	[BASE_ITEM_ID + 0x00004] = { { "hard_knuckle" } },
	[BASE_ITEM_ID + 0x00005] = { { "top_spin" } },
	[BASE_ITEM_ID + 0x00006] = { { "search_snake" } },
	[BASE_ITEM_ID + 0x00007] = { { "spark_shock" } },
	[BASE_ITEM_ID + 0x00008] = { { "shadow_blade" } },
	
	-- stage access
	[BASE_ITEM_ID + 0x00101] = { { "needle_man_stage" } },
	[BASE_ITEM_ID + 0x00102] = { { "magnet_man_stage" } },
	[BASE_ITEM_ID + 0x00103] = { { "gemini_man_stage" } },
	[BASE_ITEM_ID + 0x00104] = { { "hard_man_stage" } },
	[BASE_ITEM_ID + 0x00105] = { { "top_man_stage" } },
	[BASE_ITEM_ID + 0x00106] = { { "snake_man_stage" } },
	[BASE_ITEM_ID + 0x00107] = { { "spark_man_stage" } },
	[BASE_ITEM_ID + 0x00108] = { { "shadow_man_stage" } },
	[BASE_ITEM_ID + 0x00111] = { { "doc_needle_stage" } },
	[BASE_ITEM_ID + 0x00113] = { { "doc_gemini_stage" } },
	[BASE_ITEM_ID + 0x00117] = { { "doc_spark_stage" } },
	[BASE_ITEM_ID + 0x00118] = { { "doc_shadow_stage" } },

	-- rush items
	[BASE_ITEM_ID + 0x00011] = { { "rush_coil" } },
	[BASE_ITEM_ID + 0x00012] = { { "rush_marine" } },
	[BASE_ITEM_ID + 0x00013] = { { "rush_jet" } },

	-- filler items
	[BASE_ITEM_ID + 0x00020] = { { "one_up" } },
	[BASE_ITEM_ID + 0x00021] = { { "weapon_energy" } },
	[BASE_ITEM_ID + 0x00022] = { { "health_energy" } },
	[BASE_ITEM_ID + 0x00023] = { { "e_tank" } },
}
