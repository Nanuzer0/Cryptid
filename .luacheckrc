-- Luacheck configuration for Cryptid (Balatro Mod)
-- Targets Lua 5.1 / LuaJIT compatibility

std = "lua51"
max_line_length = false

-- Allow setting and defining top-level globals
allow_defined = true
allow_defined_top = true

-- Whitelist standard Balatro, Steamodded, Lovely, Talisman, and Cryptid globals
globals = {
	-- Balatro engine / core objects & globals
	"G",
	"love",
	"NFS",
	"HEX",
	"Event",
	"Card",
	"CardArea",
	"UIBox",
	"Moveable",
	"Node",
	"Sprite",
	"UIElement",
	"Emboss",
	"Blind",
	"Back",
	"Tag",
	"Center",
	"Deck",
	"Edition",
	"Sticker",
	"Voucher",
	"SOUND_MANAGER",
	"Card_Character",
	"Particles",
	"DynaText",
	"EMPTY",

	-- Balatro / Steamodded helper functions
	"pseudorandom",
	"pseudorandom_element",
	"pseudoseed",
	"get_pack",
	"poll_edition",
	"localize",
	"loc_colour",
	"sendInfoMessage",
	"sendErrorMessage",
	"sendDebugMessage",
	"sendWarnMessage",
	"add_tag",
	"add_joker",
	"copy_card",
	"create_card",
	"find_joker",
	"get_current_pool",
	"ease_dollars",
	"ease_hands_played",
	"ease_discard",
	"delay",
	"play_sound",
	"stop_sound",
	"check_for_unlock",
	"set_screen_positions",
	"discover_card",
	"generate_card_ui",
	"get_badge_colour",
	"add_round_eval_row",
	"get_stake_col",
	"set_profile_progress",
	"get_blind_amount",
	"get_starting_params",
	"reset_blinds",
	"new_game",
	"init_item_prototypes",
	"main_menu",
	"exit_overlay_menu",
	"open_booster_pack",
	"ease_background_colour",
	"ease_background_colour_blind",
	"ease_colour",
	"ease_value",
	"calculate_context",
	"eval_card",

	-- Steamodded
	"SMODS",

	-- Talisman / Big numbers
	"TALISMAN",
	"Talisman",
	"Big",
	"to_big",
	"to_number",
	"is_big",
	"is_number",

	-- Cryptid
	"Cryptid",
	"Cryptid_config",
	"cry_enable_all",
	"cry_misprintize",
	"cry_format",
	"cry_edition_to_string",
	"cry_joker_display_definition",
	"cry_deep_copy",
	"cry_cross_compat",
	"cry_asc_apply",
	"cry_asc_check",
	"cry_asc_end_round",
	"cry_asc_reset",
	"cry_asc_update_ui",
	"cry_asc_vals",
	"cry_asc_var_desc",
	"cry_asc_var_scale",
	"cry_asc_var_str",
	"cry_asc_var_tab",
	"cry_asc_vars",
	"cry_asc_vars_init",
	"cry_asc_vars_reset",
	"cry_asc_vars_update",
	"cry_asc_vars_write",
	"cry_asc_vars_read",
	"cry_asc_vars_dump",
	"cry_asc_vars_load",

	-- Cross-mod compatibility
	"JokerDisplay",
	"CardSleeves",
	"Spectrallib",
	"Bunco",
	"Betmma",
	"Steamodded",
}

-- Mute benign warnings
unused_args = false
ignore = {
	"212", -- Unused argument
	"213", -- Unused loop variable
	"631", -- Line is too long
	"561", -- Cyclomatic complexity
}
