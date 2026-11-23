-- Shared helpers for Cryptid's JokerDisplay definitions (loaded by items/joker_display.lua).
-- Layouts follow base JokerDisplay's definitions for the closest vanilla Jokers.
local jd = {}

-- Main text for a bonus, by kind:
-- "mult"/"chips": "+N" in Mult/Chips colour (like Joker, Sly Joker)
-- "xmult": "XN" in a box (like The Duo)
-- "xchips": "XN" in a box with a Chips border
-- "emult"/"echips": "^N" in a box in Amulet's ^Mult/^Chips colour
-- N is read from ref_table.ref_value; ref_table defaults to "card.joker_display_values".
-- Returns the text and its text_config (nil for boxes).
function jd.bonus_text(kind, ref_value, ref_table)
	local value = { ref_table = ref_table or "card.joker_display_values", ref_value = ref_value }
	if kind == "mult" or kind == "chips" then
		value.retrigger_type = "mult"
		return { { text = "+" }, value }, { colour = kind == "mult" and G.C.MULT or G.C.CHIPS }
	end
	-- Retriggering ^N or XN twice gives ^(N^2) or X(N^2), so all of them use "exp".
	value.retrigger_type = "exp"
	if kind == "emult" or kind == "echips" then
		-- Amulet keeps G.C.emult/G.C.echips set to the colour chosen in its settings (its gradient,
		-- or the dark edition colour for "classic") and updates them in place, so the box follows it.
		return { { border_nodes = { { text = "^" }, value }, border_colour = G.C[kind] or G.C.DARK_EDITION } }
	end
	if kind == "xchips" then
		return { { border_nodes = { { text = "X" }, value }, border_colour = G.C.CHIPS } }
	end
	return { { border_nodes = { { text = "X" }, value } } }
end

-- A Joker that just shows a value it keeps in card.ability.extra, like Hologram or Square Joker
-- (scaling Jokers, and fixed ones like Cube).
function jd.stat(kind, field)
	local text, text_config = jd.bonus_text(kind, field, "card.ability.extra")
	return { text = text, text_config = text_config }
end

-- How many times scoring cards matching predicate(card) will score in the selected hand,
-- counting retriggers (like Triboulet and Rough Gem do).
function jd.count_scoring(predicate)
	local count = 0
	local text, _, scoring_hand = JokerDisplay.evaluate_hand()
	if text ~= "Unknown" then
		for _, scoring_card in pairs(scoring_hand) do
			if predicate(scoring_card) then
				count = count + JokerDisplay.calculate_card_triggers(scoring_card, scoring_hand)
			end
		end
	end
	return count
end

-- How many times cards held in hand matching predicate(card) will trigger, counting retriggers,
-- like Baron and Shoot the Moon: the cards left in hand once the selected ones are played.
-- Debuffed and face-down cards don't count.
function jd.count_held(predicate)
	local playing = next(G.play.cards)
	local count = 0
	for _, held in ipairs(G.hand and G.hand.cards or {}) do
		if (playing or not held.highlighted) and held.facing ~= "back" and not held.debuff and predicate(held) then
			count = count + JokerDisplay.calculate_card_triggers(held, nil, true)
		end
	end
	return count
end

-- Whether the selected cards (scoring or not) include every rank id in ids.
function jd.hand_has_ranks(ids)
	local found = {}
	for _, hand_card in ipairs(JokerDisplay.current_hand or {}) do
		local id = hand_card:get_id()
		if id then
			found[id] = true
		end
	end
	for _, id in ipairs(ids) do
		if not found[id] then
			return false
		end
	end
	return true
end

-- "(N remaining)" or "(Active!)", the way Loyalty Card and Invisible Joker show a countdown.
function jd.countdown_text(remaining)
	if to_big(remaining) <= to_big(0) then
		return localize("jdis_active")
	end
	return localize({ type = "variable", key = "loyalty_inactive", vars = { remaining } })
end

-- Progress towards something, shown like Invisible Joker: "(done/needed)", then "(Active!)".
-- get(card) returns done, needed and, optionally, whether it's active (default: done >= needed).
function jd.progress(get)
	return {
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "progress" },
			{ text = ")" },
		},
		calc_function = function(card)
			local done, needed, active = get(card)
			if active == nil then
				active = to_big(done) >= to_big(needed)
			end
			card.joker_display_values.is_active = active
			card.joker_display_values.progress = active and localize("jdis_active")
				or (number_format(done) .. "/" .. number_format(needed))
		end,
		style_function = jd.style_active,
	}
end

-- Colours a reminder's value green while active and grey otherwise, like DNA and Loyalty Card.
-- Expects the reminder to be { "(", value, ")" } and card.joker_display_values.is_active.
function jd.style_active(card, _, reminder_text)
	if reminder_text and reminder_text.children and reminder_text.children[2] then
		reminder_text.children[2].config.colour = card.joker_display_values.is_active and G.C.GREEN
			or G.C.UI.TEXT_INACTIVE
	end
end

-- Jokers that retrigger played cards of some ranks, shown like Hack: a reminder of the ranks.
-- args.ids: the rank ids retriggered; args.reminder: e.g. "(7)"; args.amount(joker): retriggers
function jd.rank_retrigger(args)
	return {
		reminder_text = { { text = args.reminder } },
		retrigger_function = function(playing_card, scoring_hand, held_in_hand, joker_card)
			if held_in_hand or not JokerDisplay.in_scoring(playing_card, scoring_hand) then
				return 0
			end
			local id = playing_card:get_id()
			for _, wanted in ipairs(args.ids) do
				if id == wanted then
					return args.amount(joker_card) * JokerDisplay.calculate_joker_triggers(joker_card)
				end
			end
			return 0
		end,
	}
end

-- Jokers that pay out at the end of the round, shown like Cloud 9: "+$N (Round)".
-- dollars(card) gives what it would pay right now.
function jd.round_money(dollars)
	return {
		text = {
			{ text = "+$" },
			{ ref_table = "card.joker_display_values", ref_value = "dollars" },
		},
		text_config = { colour = G.C.GOLD },
		reminder_text = {
			{ ref_table = "card.joker_display_values", ref_value = "localized_text" },
		},
		calc_function = function(card)
			card.joker_display_values.dollars = dollars(card) or 0
			card.joker_display_values.localized_text = "(" .. localize("k_round") .. ")"
		end,
	}
end

-- For jd.round_money: what the Joker's calc_dollar_bonus pays. Only for Jokers whose
-- calc_dollar_bonus just reads the game state (no side effects).
function jd.dollar_bonus(card)
	return card.config.center:calc_dollar_bonus(card)
end

-- The hand name a played hand scores as, from the name JokerDisplay.evaluate_hand gives.
-- Like evaluate_play_intro, a name that isn't a known poker hand ("NULL": no cards, or only
-- cards without a rank) scores as None, even before None is visible and detected as a hand.
-- ://EXPLOIT needs nothing extra: its chosen hand already comes back as the name.
-- "Unknown" is JokerDisplay's own "no hand right now" and stays as it is.
function jd.scored_hand_name(name)
	if name ~= "Unknown" and G.GAME and G.GAME.hands and not G.GAME.hands[name] then
		return "cry_None"
	end
	return name
end

-- Panopticon and Labyrinth work by changing the round's counters only while a hand or discard
-- is calculated: Panopticon sets hands_left to 0 from context.before to context.after (every
-- hand is the last one), Labyrinth sets hands_played and discards_used to 0 (every hand and
-- discard is the first one; see lib/overrides.lua). Displays run outside of that, so
-- jd.as_played(f) wraps a definition function to run with the counters the selected hand or
-- discard will see, and puts the real ones back afterwards (also if f errors).
-- Before a hand is played, the last hand shows as hands_left == 1 (playing it takes one off),
-- which is what vanilla displays like Acrobat and Dusk check for.
local function restore_counters(round, saved, ok, ...)
	for key, value in pairs(saved) do
		round[key] = value
	end
	if not ok then
		error((...), 0)
	end
	return ...
end

function jd.as_played(f)
	return function(...)
		local round = G.GAME and G.GAME.current_round
		if not round then
			return f(...)
		end
		local saved = {}
		if next(SMODS.find_card("j_cry_panopticon")) then
			local last = (G.play and next(G.play.cards)) and 0 or 1
			if round.hands_left > last then
				saved.hands_left = round.hands_left
				round.hands_left = last
			end
		end
		if next(SMODS.find_card("j_cry_maze")) then
			saved.hands_played = round.hands_played
			saved.discards_used = round.discards_used
			round.hands_played = 0
			round.discards_used = 0
		end
		if not next(saved) then
			return f(...)
		end
		return restore_counters(round, saved, pcall(f, ...))
	end
end

-- Whether the selected hand (or the hand being scored) is the last one of the round. The hand
-- being scored has already been taken off hands_left. Call it inside jd.as_played so that
-- Panopticon counts.
function jd.is_last_hand()
	return G.GAME.current_round.hands_left - (next(G.play.cards) and 0 or 1) <= 0
end

-- A chance, shown the way Gros Michel and Bloodstone show theirs: "(N in M)" in a small green
-- row above the display. jd.add_odds(def) adds that row to def, showing
-- card.joker_display_values.odds; set it with jd.odds_text(numerator, denominator).
function jd.odds_text(numerator, denominator)
	return "(" .. localize({ type = "variable", key = "jdis_odds", vars = { numerator, denominator } }) .. ")"
end

function jd.add_odds(def)
	def.extra = { { { ref_table = "card.joker_display_values", ref_value = "odds" } } }
	def.extra_config = { colour = G.C.GREEN, scale = 0.3 }
	return def
end

-- A Joker whose only number is a chance, shown like Hallucination.
-- odds(card) returns the numerator and denominator (from SMODS.get_probability_vars).
function jd.chance(odds)
	return jd.add_odds({
		calc_function = function(card)
			card.joker_display_values.odds = jd.odds_text(odds(card))
		end,
	})
end

-- The value a bonus of this kind has when it doesn't apply.
function jd.neutral(kind)
	return (kind == "mult" or kind == "chips") and 0 or 1
end

-- Jokers that give a fixed bonus when the played hand contains a poker hand, shown like
-- Jolly Joker / Sly Joker / The Duo: the bonus (0 or X1 while it doesn't apply) and "(Hand)".
-- args.kind: any kind jd.bonus_text takes
-- args.value(card), args.hand(card): the bonus and the poker hand key, read from the card
-- args.also: other poker hands that count too
-- args.by_name: compare the hand's name instead of what it contains (None, which contains nothing)
function jd.hand_type(args)
	local text, text_config = jd.bonus_text(args.kind, "bonus")
	return {
		text = text,
		text_config = text_config,
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "localized_text", colour = G.C.ORANGE },
			{ text = ")" },
		},
		calc_function = function(card)
			local hand = args.hand(card)
			local name, poker_hands = JokerDisplay.evaluate_hand()
			local active = false
			if hand and args.by_name then
				active = jd.scored_hand_name(name) == hand
			elseif hand then
				for _, counted in ipairs({ hand, unpack(args.also or {}) }) do
					if poker_hands[counted] and next(poker_hands[counted]) then
						active = true
					end
				end
			end
			card.joker_display_values.bonus = active and args.value(card) or jd.neutral(args.kind)
			card.joker_display_values.localized_text = hand and localize(hand, "poker_hands") or "-"
		end,
	}
end

return jd
