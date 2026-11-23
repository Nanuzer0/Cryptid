-- JokerDisplay definitions for items/misc_joker.lua.
return function(jd)
	local defs = JokerDisplay.Definitions

	local function extra(field)
		return function(card)
			return type(card.ability.extra) == "table" and card.ability.extra[field] or nil
		end
	end
	local extra_type = extra("type")

	-- Hand-type Jokers (Jolly Joker family). "the" (The), "undefined" and "nebulous" need the
	-- None hand itself; the WholeDeck ones need all 52 cards.
	local hand_type_jokers = {
		-- X Mult
		duos = { kind = "xmult", value = extra("Xmult"), also = { "Full House" } },
		home = { kind = "xmult", value = extra("Xmult") },
		nuts = { kind = "xmult", value = extra("Xmult") },
		quintet = { kind = "xmult", value = extra("Xmult") },
		unity = { kind = "xmult", value = extra("Xmult") },
		swarm = { kind = "xmult", value = extra("Xmult") },
		stronghold = { kind = "xmult", value = extra("Xmult") },
		wtf = { kind = "xmult", value = extra("Xmult") },
		clash = { kind = "xmult", value = extra("Xmult") },
		the = { kind = "xmult", value = extra("Xmult"), by_name = true },
		words_cant_even = { kind = "xmult", value = extra("x_mult") },
		-- ^Mult
		annihalation = { kind = "emult", value = extra("emult") },
		-- +Mult
		giggly = { kind = "mult", value = extra("t_mult") },
		nutty = { kind = "mult", value = extra("t_mult") },
		manic = { kind = "mult", value = extra("t_mult") },
		silly = { kind = "mult", value = extra("t_mult") },
		delirious = { kind = "mult", value = extra("t_mult") },
		wacky = { kind = "mult", value = extra("t_mult") },
		kooky = { kind = "mult", value = extra("t_mult") },
		bonkers = { kind = "mult", value = extra("t_mult") },
		fuckedup = { kind = "mult", value = extra("t_mult") },
		foolhardy = { kind = "mult", value = extra("t_mult") },
		undefined = { kind = "mult", value = extra("t_mult"), by_name = true },
		-- +Chips
		dubious = { kind = "chips", value = extra("t_chips") },
		shrewd = { kind = "chips", value = extra("t_chips") },
		tricksy = { kind = "chips", value = extra("t_chips") },
		foxy = { kind = "chips", value = extra("t_chips") },
		savvy = { kind = "chips", value = extra("t_chips") },
		subtle = { kind = "chips", value = extra("t_chips") },
		discreet = { kind = "chips", value = extra("t_chips") },
		adroit = { kind = "chips", value = extra("t_chips") },
		penetrating = { kind = "chips", value = extra("t_chips") },
		treacherous = { kind = "chips", value = extra("t_chips") },
		nebulous = { kind = "chips", value = extra("t_chips"), by_name = true },
		many_lost_minds = { kind = "chips", value = extra("chips") },
	}
	for key, args in pairs(hand_type_jokers) do
		args.hand = args.hand or extra_type
		defs["j_cry_" .. key] = jd.hand_type(args)
	end

	-- Filler keeps its values outside ability.extra, like vanilla's The Duo.
	defs.j_cry_filler = jd.hand_type({
		kind = "xmult",
		value = function(card)
			return card.ability.x_mult
		end,
		hand = function(card)
			return card.ability.type
		end,
	})

	-- Values that are just shown as they are (scaling Jokers like Hologram/Square Joker, and
	-- fixed ones). Some only score while above X1/+0; showing X1/+0 then is the same.
	local stats = {
		cube = { "chips", "chips" },
		big_cube = { "xchips", "x_chips" },
		wee_fib = { "mult", "mult" },
		cursor = { "chips", "chips" },
		fspinner = { "chips", "chips" },
		whip = { "xmult", "x_mult" },
		chili_pepper = { "xmult", "Xmult" },
		eternalflame = { "xmult", "x_mult" },
		jimball = { "xmult", "x_mult" },
		krustytheclown = { "xmult", "x_mult" },
		antennastoheaven = { "xchips", "x_chips" },
	}
	for key, stat in pairs(stats) do
		defs["j_cry_" .. key] = jd.stat(stat[1], stat[2])
	end

	-- Dropshot: like Castle, with the suit it currently wants.
	local dropshot = jd.stat("xmult", "x_mult")
	dropshot.reminder_text = {
		{ text = "(" },
		{ ref_table = "card.joker_display_values", ref_value = "suit" },
		{ text = ")" },
	}
	dropshot.calc_function = function(card)
		local target = G.GAME.current_round.cry_dropshot_card
		card.joker_display_values.suit = target and target.suit and localize(target.suit, "suits_plural") or "-"
	end
	dropshot.style_function = function(_, _, reminder_text)
		local target = G.GAME.current_round.cry_dropshot_card
		if reminder_text and reminder_text.children[2] and target and target.suit and G.C.SUITS[target.suit] then
			reminder_text.children[2].config.colour = lighten(G.C.SUITS[target.suit], 0.35)
		end
	end
	defs.j_cry_dropshot = dropshot

	-- Happy House: like Loyalty Card. ^Mult once more than `trigger` hands have been played.
	defs.j_cry_happyhouse = {
		text = jd.bonus_text("emult", "e_mult"),
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "countdown" },
			{ text = ")" },
		},
		calc_function = function(card)
			local state = card.ability.immutable
			-- The selected hand counts once it's played; a hand being scored already counts.
			local hands = state.check + (next(G.play.cards) and 0 or 1)
			local remaining = state.trigger + 1 - hands
			card.joker_display_values.is_active = to_big(remaining) <= to_big(0)
			card.joker_display_values.e_mult = card.joker_display_values.is_active and state.mult or 1
			card.joker_display_values.countdown = jd.countdown_text(remaining)
		end,
		style_function = jd.style_active,
	}

	-- Queen's Gambit: like Sixth Sense. A Joker for each Queen destroyed by a Royal Flush.
	defs.j_cry_queens_gambit = {
		text = {
			{ text = "+" },
			{ ref_table = "card.joker_display_values", ref_value = "count" },
		},
		text_config = { colour = G.C.RARITY[3] },
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "localized_text", colour = G.C.ORANGE },
			{ text = ")" },
		},
		calc_function = function(card)
			local name, _, scoring_hand = JokerDisplay.evaluate_hand()
			local royal = name == "Straight Flush"
			local queens = 0
			for _, scoring_card in pairs(scoring_hand or {}) do
				local id = scoring_card:get_id() or 0
				if id < 10 then
					royal = false
				end
				if id == 12 then
					queens = queens + 1
				end
			end
			card.joker_display_values.count = royal and queens or 0
			card.joker_display_values.localized_text = localize("Royal Flush", "poker_hands")
		end,
	}

	-- Triplet Rhythm: like Card Sharp. X Mult when exactly three 3s score.
	defs.j_cry_triplet_rhythm = {
		text = jd.bonus_text("xmult", "x_mult"),
		reminder_text = { { text = "(3,3,3)" } },
		calc_function = function(card)
			local _, _, scoring_hand = JokerDisplay.evaluate_hand()
			local threes = 0
			for _, scoring_card in pairs(scoring_hand or {}) do
				if scoring_card:get_id() == 3 then
					threes = threes + 1
				end
			end
			card.joker_display_values.x_mult = threes == 3 and card.ability.extra.Xmult or 1
		end,
	}

	-- Lucky Joker: like Business Card. $N each time a Lucky card triggers (which is random).
	defs.j_cry_lucky_joker = {
		text = {
			{ ref_table = "card.joker_display_values", ref_value = "count", retrigger_type = "mult" },
			{ text = "x", scale = 0.35 },
			{ text = "$", colour = G.C.GOLD },
			{ ref_table = "card.ability.extra", ref_value = "dollars", colour = G.C.GOLD },
		},
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "localized_text", colour = G.C.ORANGE },
			{ text = ")" },
		},
		calc_function = function(card)
			card.joker_display_values.count = jd.count_scoring(function(scoring_card)
				return SMODS.has_enhancement(scoring_card, "m_lucky")
			end)
			card.joker_display_values.localized_text = localize({ type = "name_text", set = "Enhanced", key = "m_lucky" })
		end,
	}

	-- Pickle: the Tags it gives when a blind is skipped.
	defs.j_cry_pickle = {
		text = {
			{ ref_table = "card.joker_display_values", ref_value = "tags" },
		},
		text_config = { colour = G.C.FILTER },
		calc_function = function(card)
			local tags = math.min(card.ability.immutable.max_tags, card.ability.extra.tags)
			card.joker_display_values.tags =
				localize({ type = "variable", key = to_big(tags) == to_big(1) and "a_tag" or "a_tags", vars = { tags } })
		end,
	}

	-- Nice: like Walkie Talkie. +Chips when the played cards include a 6 and a 9.
	defs.j_cry_nice = {
		text = jd.bonus_text("chips", "chips"),
		text_config = { colour = G.C.CHIPS },
		reminder_text = { { text = "(6,9)" } },
		calc_function = function(card)
			card.joker_display_values.chips = jd.hand_has_ranks({ 6, 9 }) and card.ability.extra.chips or 0
		end,
	}

	-- Garden of Forking Paths: $N when the played cards include an Ace and a 7.
	defs.j_cry_gardenfork = {
		text = {
			{ text = "+$" },
			{ ref_table = "card.joker_display_values", ref_value = "dollars" },
		},
		text_config = { colour = G.C.GOLD },
		reminder_text = { { text = "(A,7)" } },
		calc_function = function(card)
			card.joker_display_values.dollars = jd.hand_has_ranks({ 14, 7 }) and card.ability.extra.money or 0
		end,
	}

	-- Seal the Deal: like DNA. Active on the last hand of the round (every hand with Panopticon).
	defs.j_cry_seal_the_deal = {
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "active_text" },
			{ text = ")" },
		},
		calc_function = jd.as_played(function(card)
			-- The hand being scored has already been taken off hands_left.
			local hands_left = G.GAME.current_round.hands_left - (next(G.play.cards) and 0 or 1)
			card.joker_display_values.is_active = hands_left <= 0
			card.joker_display_values.active_text =
				localize("jdis_" .. (card.joker_display_values.is_active and "active" or "inactive"))
		end),
		style_function = jd.style_active,
	}

	-- Chad: retriggers the leftmost Joker (shown on that Joker's numbers).
	defs.j_cry_chad = {
		retrigger_joker_function = function(retriggered, chad)
			if G.jokers and retriggered == G.jokers.cards[1] and retriggered ~= chad then
				return math.min(chad.ability.immutable.max_retriggers, chad.ability.extra.retriggers)
			end
			return 0
		end,
	}

	-- Waluigi: like Baseball Card. Every Joker gives X Mult, shown on each of them.
	defs.j_cry_waluigi = {
		mod_function = function(card, waluigi)
			if card.ability.set ~= "Joker" then
				return {}
			end
			return { x_mult = waluigi.ability.extra.Xmult ^ JokerDisplay.calculate_joker_triggers(waluigi) }
		end,
	}

	-- Light Up the Night: like Triboulet. X Mult for each scoring 2 and 7.
	defs.j_cry_lightupthenight = {
		text = jd.bonus_text("xmult", "x_mult"),
		reminder_text = { { text = "(2,7)" } },
		calc_function = function(card)
			local count = jd.count_scoring(function(scoring_card)
				return scoring_card:get_id() == 2 or scoring_card:get_id() == 7
			end)
			card.joker_display_values.x_mult = card.ability.extra.xmult ^ count
		end,
	}

	-- Card retriggers, like Hack.
	local function capped_retriggers(joker)
		return math.min(joker.ability.immutable.max_retriggers, joker.ability.extra.retriggers)
	end
	defs.j_cry_nosound = jd.rank_retrigger({ ids = { 7 }, reminder = "(7)", amount = capped_retriggers })
	defs.j_cry_weegaming = jd.rank_retrigger({ ids = { 2 }, reminder = "(2)", amount = capped_retriggers })

	-- AP Joker: like Card Sharp. X Mult against Boss Blinds.
	defs.j_cry_apjoker = {
		text = jd.bonus_text("xmult", "x_mult"),
		calc_function = function(card)
			local boss = G.GAME.blind and Cryptid.is_boss_blind(G.GAME.blind)
			card.joker_display_values.x_mult = boss and card.ability.extra.x_mult or 1
		end,
	}

	-- Red Bloon: pays out after its rounds run out.
	defs.j_cry_redbloon = {
		text = {
			{ text = "+$" },
			{ ref_table = "card.ability.extra", ref_value = "money" },
		},
		text_config = { colour = G.C.GOLD },
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "countdown" },
			{ text = ")" },
		},
		calc_function = function(card)
			card.joker_display_values.countdown = jd.countdown_text(card.ability.extra.rounds_remaining)
		end,
	}

	-- End-of-round money, like Cloud 9.
	defs.j_cry_compound_interest = jd.round_money(function(card)
		if to_big(G.GAME.dollars) <= to_big(0) then
			return 0
		end
		return math.max(0, math.floor(0.01 * to_big(card.ability.extra.percent) * G.GAME.dollars))
	end)
	defs.j_cry_magnet = jd.round_money(function(card)
		local values = card.ability.extra
		if to_big(#G.jokers.cards) <= to_big(values.slots) then
			return to_big(values.money) * values.Xmoney
		end
		return values.money
	end)
end
