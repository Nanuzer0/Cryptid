-- Compatibility with the Balatro Multiplayer mods (MultiplayerAPI, MultiplayerPvP).
-- Everything here must also work when they aren't installed.

-- Whether the player is in a Multiplayer lobby. This includes PvP's practice mode,
-- which runs in a local lobby.
function Cryptid.in_mp_lobby()
	return type(MPAPI) == "table"
		and type(MPAPI.get_current_lobby) == "function"
		and MPAPI.get_current_lobby() ~= nil
end

-- The rest needs MultiplayerAPI, which loads before Cryptid.
if type(MPAPI) ~= "table" or type(MPAPI.get_current_lobby) ~= "function" then
	return
end

Cryptid.mp = {}

local function warn(message)
	sendWarnMessage(message, "Cryptid")
end

-- Shows a message box the way MultiplayerPvP shows its own lobby messages.
local function show_message(text)
	if type(PVP) == "table" and PVP.UI and PVP.UI.UTILS and type(PVP.UI.UTILS.overlay_message) == "function" then
		PVP.UI.UTILS.overlay_message(text)
		return true
	end
end

----------------------------------------------------------------------------------------------------
-- Settings check
--
-- A different Cryptid build or different settings (gameset, disabled items, ...) change the card
-- pools, so the shared seed gives players different shops, packs and bosses. The host puts a
-- summary of their settings in the lobby metadata (the only host -> everyone channel that works),
-- and every other player compares it with their own. Players also compare each other's Cryptid
-- version in the mod lists MultiplayerAPI shares, which is how the host hears about a guest's.
----------------------------------------------------------------------------------------------------

local function current_profile()
	return G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile] or {}
end

-- Order-independent hash of a list of strings (sorts the list in place).
local function hash_strings(list)
	table.sort(list)
	local h = 5381
	for _, s in ipairs(list) do
		for i = 1, #s do
			h = (h * 33 + s:byte(i)) % 4294967296
		end
		h = (h * 33 + 10) % 4294967296
	end
	return string.format("%08x", h)
end

local function own_version()
	-- The same "<id>-<version>" form as MPAPI.collect_installed_mods
	return tostring(SMODS.Mods.Cryptid and SMODS.Mods.Cryptid.version or "UNK")
end

-- A summary of what changes the card pools or the rules. Only strings, numbers and booleans,
-- since it travels in the lobby metadata.
function Cryptid.mp_settings()
	local profile = current_profile()
	-- Every object under Cryptid's gamesets, and whether it's enabled
	local items, seen, enabled = {}, {}, 0
	Cryptid.index_items(function(obj)
		local key = obj.key
		if key and not seen[key] then
			seen[key] = true
			items[#items + 1] = key .. (obj.cry_disabled and "=off" or "=on")
			if not obj.cry_disabled then
				enabled = enabled + 1
			end
		end
	end)
	local overrides = {}
	for key, gameset in pairs(profile.cry_gameset_overrides or {}) do
		overrides[#overrides + 1] = tostring(key) .. "=" .. tostring(gameset)
	end
	-- Every mod's cards, to catch differences Cryptid's own items don't explain
	local centers = {}
	for key in pairs(G.P_CENTERS) do
		centers[#centers + 1] = key
	end
	return {
		version = own_version(),
		gameset = profile.cry_gameset or "mainline",
		experimental = Cryptid_config.experimental and true or false,
		none = profile.cry_none and true or false,
		overrides = hash_strings(overrides),
		items = hash_strings(items),
		enabled_items = enabled,
		centers = hash_strings(centers),
		center_count = #centers,
	}
end

-- What the host publishes in the lobby metadata, under `cry_lobby`.
function Cryptid.mp_lobby_info()
	return { settings = Cryptid.mp_settings() }
end

local function loc_var(key, vars)
	return localize({ type = "variable", key = key, vars = vars })
end

local function on_off(value)
	return localize(value and "cry_mp_on" or "cry_mp_off")
end

local function gameset_name(gameset)
	local name = localize("cry_gameset_" .. tostring(gameset))
	return name ~= "ERROR" and name or tostring(gameset)
end

-- The Cryptid version in a player's mod list: nil when the list isn't known (yet), false when
-- it has no Cryptid.
local function listed_cryptid_version(mods)
	if type(mods) ~= "table" then
		return nil
	end
	for _, entry in ipairs(mods) do
		if type(entry) == "string" and entry:sub(1, 8) == "Cryptid-" then
			return entry:sub(9)
		end
	end
	return false
end

local function compare_settings(problems, ours, host, skip_version)
	if not skip_version and ours.version ~= host.version then
		problems[#problems + 1] = loc_var("cry_mp_diff_version", { ours.version, tostring(host.version) })
	end
	if ours.gameset ~= host.gameset then
		problems[#problems + 1] =
			loc_var("cry_mp_diff_gameset", { gameset_name(ours.gameset), gameset_name(host.gameset) })
	end
	if ours.experimental ~= host.experimental then
		problems[#problems + 1] =
			loc_var("cry_mp_diff_experimental", { on_off(ours.experimental), on_off(host.experimental) })
	end
	if ours.none ~= host.none then
		problems[#problems + 1] = loc_var("cry_mp_diff_none", { on_off(ours.none), on_off(host.none) })
	end
	if ours.overrides ~= host.overrides then
		problems[#problems + 1] = localize("cry_mp_diff_overrides")
	end
	if ours.items ~= host.items then
		problems[#problems + 1] =
			loc_var("cry_mp_diff_items", { ours.enabled_items, tostring(host.enabled_items) })
	elseif ours.centers ~= host.centers then
		problems[#problems + 1] =
			loc_var("cry_mp_diff_centers", { ours.center_count, tostring(host.center_count) })
	end
end

-- Everything that differs between this player and the others, one line each.
function Cryptid.mp_settings_problems(lobby)
	local problems = {}
	local version = own_version()
	local host_cryptid
	for _, player in ipairs(lobby:get_players() or {}) do
		if player.id ~= lobby.player_id then
			local theirs = listed_cryptid_version(player.mods)
			local name = tostring(player.displayName or "?")
			if theirs == false then
				problems[#problems + 1] = loc_var("cry_mp_no_cryptid", { name })
			elseif theirs and theirs ~= version then
				problems[#problems + 1] = loc_var("cry_mp_other_version", { name, theirs, version })
			end
			if player.id == lobby.host_id then
				host_cryptid = theirs
			end
		end
	end
	-- The host's settings, for everyone but the host
	if not lobby.is_host and host_cryptid ~= false then
		local meta = lobby:get_metadata() or {}
		local info = meta.cry_lobby
		if type(info) == "table" and type(info.settings) == "table" then
			-- A version difference with the host is already listed when their mod list is known
			compare_settings(problems, Cryptid.mp_settings(), info.settings, host_cryptid ~= nil)
		elseif next(meta) ~= nil then
			-- The host's metadata is in, without Cryptid's part
			problems[#problems + 1] = localize("cry_mp_host_no_settings")
		end
	end
	return problems
end

-- Checks run on lobby events, but only outside a run (the lobby screen). A private lobby shows
-- the result in a status box under its gamemode and ruleset; other lobbies get a message box,
-- which waits until no other menu is open, once per different set of problems per lobby.
local check = { problems = {} }

local LOBBY_EVENTS = {
	"CONNECTED",
	"SNAPSHOT_APPLIED",
	"METADATA_CHANGED",
	"HOST_CHANGED",
	"PLAYER_JOINED",
	"PLAYER_INFO",
	"PLAYER_LEFT",
}

local function attach(lobby)
	check = { lobby = lobby, dirty = true, problems = {} }
	if type(lobby.on) ~= "function" or type(MPAPI.LobbyEvent) ~= "table" then
		return
	end
	for _, name in ipairs(LOBBY_EVENTS) do
		local event = MPAPI.LobbyEvent[name]
		if event then
			lobby:on(event, function()
				if check.lobby == lobby then
					check.dirty = true
				end
			end)
		end
	end
end

local function run_check()
	check.dirty = false
	local ok, problems = pcall(Cryptid.mp_settings_problems, check.lobby)
	if not ok then
		warn("Multiplayer settings check failed: " .. tostring(problems))
		return
	end
	check.problems = problems
	local text = #problems > 0 and table.concat(problems, "\n") or nil
	if text ~= check.text then
		check.text = text
		check.pending = text
		if text then
			warn("Multiplayer settings differ:\n" .. text)
		end
		-- Rebuild the lobby screen for the status box. MultiplayerPvP rebuilds it on metadata
		-- and roster changes, but not when a player's mod list arrives.
		pcall(MPAPI.refresh_current_view)
	end
end

-- The lobby that shows the status box: it replaces the message box there.
local box_lobby

local function status_text_row(text, scale)
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.02 },
		nodes = { { n = G.UIT.T, config = { text = text, scale = scale, colour = G.C.UI.TEXT_LIGHT, shadow = true } } },
	}
end

-- A small box under the lobby's gamemode and ruleset: green when nothing differs, red with
-- the differences listed. Nothing while the player is alone.
local function status_box(lobby)
	local problems = Cryptid.mp_settings_problems(lobby)
	if #problems == 0 and #(lobby:get_players() or {}) < 2 then
		return nil
	end
	local colour = #problems > 0 and G.C.RED or G.C.GREEN
	local rows = {
		status_text_row(localize(#problems > 0 and "cry_mp_status_differs" or "cry_mp_status_match"), 0.35),
	}
	for _, problem in ipairs(problems) do
		rows[#rows + 1] = status_text_row(problem, 0.28)
	end
	if #problems > 0 then
		rows[#rows + 1] = status_text_row(localize("cry_mp_mismatch_footer"), 0.28)
	end
	return {
		n = G.UIT.R,
		config = { align = "cm", padding = 0.05 },
		nodes = {
			{
				n = G.UIT.C,
				config = {
					align = "cm",
					padding = 0.08,
					r = 0.1,
					colour = mix_colours(colour, G.C.BLACK, 0.3),
					outline = 1.2,
					outline_colour = colour,
					-- The host's own check only covers the others' versions; the guests do the rest
					on_demand_tooltip = lobby.is_host and { text = { localize("cry_mp_status_host_tip") } } or nil,
				},
				nodes = rows,
			},
		},
	}
end

-- MultiplayerPvP builds the gamemode/ruleset banner of a private lobby here (ui/lobby/view.lua)
if type(PVP) == "table" and type(PVP.lobby) == "table" and type(PVP.lobby.build_mode_banner) == "function" then
	local build_mode_banner_ref = PVP.lobby.build_mode_banner
	function PVP.lobby.build_mode_banner(lobby, ...)
		local banner = build_mode_banner_ref(lobby, ...)
		local ok, box = pcall(status_box, lobby)
		if not ok then
			warn("Couldn't build the Cryptid status box: " .. tostring(box))
			return banner
		end
		box_lobby = lobby
		if not box then
			return banner
		end
		return {
			n = G.UIT.R,
			config = { align = "cm" },
			nodes = {
				{
					n = G.UIT.C,
					config = { align = "cm" },
					nodes = { banner or { n = G.UIT.R, config = { minh = 0.2 } }, box },
				},
			},
		}
	end
end

local game_update_ref = Game.update
function Game:update(dt)
	game_update_ref(self, dt)
	local lobby = MPAPI.get_current_lobby()
	if lobby ~= check.lobby then
		if lobby then
			attach(lobby)
		else
			check = { problems = {} }
		end
	end
	if not lobby or G.STAGE == G.STAGES.RUN then
		return
	end
	if check.dirty then
		run_check()
	end
	if check.pending and box_lobby == lobby then
		-- The status box on the lobby screen shows it
		check.pending = nil
	end
	if check.pending and not G.OVERLAY_MENU then
		local text = localize("cry_mp_mismatch_title") .. "\n" .. check.pending .. "\n" .. localize("cry_mp_mismatch_footer")
		check.pending = nil
		local ok, err = pcall(show_message, text)
		if not ok then
			warn("Couldn't show the Multiplayer settings message: " .. tostring(err))
		end
	end
end

-- The host adds Cryptid's part to the lobby metadata whenever MultiplayerPvP publishes it.
if type(PVP) == "table" and type(PVP.pvp_lobby_metadata) == "function" then
	local pvp_lobby_metadata_ref = PVP.pvp_lobby_metadata
	function PVP.pvp_lobby_metadata(gamemode_key, kind, ...)
		local meta = pvp_lobby_metadata_ref(gamemode_key, kind, ...)
		if type(meta) == "table" then
			local ok, info = pcall(Cryptid.mp_lobby_info, kind)
			if ok then
				meta.cry_lobby = info
			else
				warn("Couldn't add Cryptid's lobby metadata: " .. tostring(info))
			end
		end
		return meta
	end
end
