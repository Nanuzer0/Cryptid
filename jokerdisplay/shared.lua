-- Shared helpers for Cryptid's JokerDisplay definitions (loaded by items/joker_display.lua).
-- Layouts follow base JokerDisplay's definitions for the closest vanilla Jokers.
local jd = {}

-- Main text for a fixed bonus, by kind:
-- "mult"/"chips": "+N" in Mult/Chips colour (like Joker, Sly Joker)
-- "xmult": "XN" in a box (like The Duo)
-- "emult"/"echips": "^N" in a box in Amulet's ^Mult/^Chips colour
-- `ref_value` is the field in card.joker_display_values that holds N.
function jd.bonus_text(kind, ref_value)
	local value = { ref_table = "card.joker_display_values", ref_value = ref_value }
	if kind == "mult" or kind == "chips" then
		value.retrigger_type = "mult"
		return { { text = "+" }, value }, { colour = kind == "mult" and G.C.MULT or G.C.CHIPS }
	end
	-- Retriggering ^N or XN twice gives ^(N^2) or X(N^2), so both use "exp".
	value.retrigger_type = "exp"
	if kind == "emult" or kind == "echips" then
		-- Amulet keeps G.C.emult/G.C.echips set to the colour chosen in its settings (its gradient,
		-- or the dark edition colour for "classic") and updates them in place, so the box follows it.
		return { { border_nodes = { { text = "^" }, value }, border_colour = G.C[kind] or G.C.DARK_EDITION } }
	end
	return { { border_nodes = { { text = "X" }, value } } }
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
