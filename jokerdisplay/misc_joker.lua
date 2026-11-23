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
		unjust_dagger = { "xmult", "x_mult" },
		monkey_dagger = { "chips", "chips" },
		pirate_dagger = { "xchips", "x_chips" },
		mondrian = { "xmult", "x_mult" },
		wheelhope = { "xmult", "x_mult" },
		kittyprinter = { "xmult", "Xmult" },
		clicked_cookie = { "chips", "chips" },
		zooble = { "mult", "mult" },
		pizza_slice = { "xmult", "xmult" },
		fading_joker = { "xmult", "xmult" },
		poor_joker = { "mult", "mult" },
		keychange = { "xmult", "xm" },
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
			card.joker_display_values.is_active = jd.is_last_hand()
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
	defs.j_cry_morse = jd.round_money(jd.dollar_bonus)
	defs.j_cry_kidnap = jd.round_money(jd.dollar_bonus)
	defs.j_cry_tax_fraud = jd.round_money(jd.dollar_bonus)

	-- Sapling: like Invisible Joker. Counts scored enhanced cards until it can be sold for a Joker.
	defs.j_cry_sapling = jd.progress(function(card)
		return card.ability.immutable.score, card.ability.extra.req
	end)

	-- Space Globe: its X Chips, and the hand that scales it (like The Duo's reminder).
	local spaceglobe = jd.stat("xchips", "x_chips")
	spaceglobe.reminder_text = jd.hand_reminder()
	spaceglobe.calc_function = function(card)
		card.joker_display_values.localized_text = jd.hand_name(card.ability.extra.type)
	end
	defs.j_cry_spaceglobe = spaceglobe

	-- Meteor Shower, Exoplanet, Stardust and Universe: a bonus for each scoring and held card with
	-- their edition, shown like Shoot the Moon, plus the same bonus on each Joker with it (shown on
	-- those Jokers, like Baseball Card).
	local function edition_bonus(kind, field, edition)
		local function has_edition(other)
			return other.edition and other.edition[edition]
		end
		local text, text_config = jd.bonus_text(kind, "bonus")
		return {
			text = text,
			text_config = text_config,
			reminder_text = {
				{ text = "(" },
				{ ref_table = "card.joker_display_values", ref_value = "localized_text", colour = G.C.ORANGE },
				{ text = ")" },
			},
			calc_function = function(card)
				local count = jd.count_scoring(has_edition) + jd.count_held(has_edition)
				local value = card.ability.extra[field]
				card.joker_display_values.bonus = jd.neutral(kind) == 0 and value * count or value ^ count
				card.joker_display_values.localized_text =
					localize({ type = "name_text", set = "Edition", key = "e_" .. edition })
			end,
			mod_function = function(other, joker)
				if other == joker or other.ability.set ~= "Joker" or not has_edition(other) then
					return {}
				end
				local value = joker.ability.extra[field]
				local triggers = JokerDisplay.calculate_joker_triggers(joker)
				if kind == "mult" or kind == "chips" then
					return { [kind] = value * triggers }
				end
				return { [kind == "xmult" and "x_mult" or "e_mult"] = value ^ triggers }
			end,
		}
	end
	defs.j_cry_meteor = edition_bonus("chips", "chips", "foil")
	defs.j_cry_exoplanet = edition_bonus("mult", "mult", "holo")
	defs.j_cry_stardust = edition_bonus("xmult", "xmult", "polychrome")
	defs.j_cry_universe = edition_bonus("emult", "emult", "cry_astral")

	-- RNJoker: its ability is random (rerolled every Ante). The display shows what that ability
	-- adds to the score right now, its end-of-round money, or its retriggers; other abilities
	-- (creating cards, hand size) show nothing. The layout can't change per card, so the bonus
	-- is plain text ("+N" or "XN") coloured by kind, without the X Mult box.
	local rnj_kinds = {
		plus_mult = { prefix = "+", colour = G.C.MULT, adds = true },
		plus_chips = { prefix = "+", colour = G.C.CHIPS, adds = true },
		x_mult = { prefix = "X", colour = G.C.MULT },
		x_chips = { prefix = "X", colour = G.C.CHIPS },
		money = { prefix = "+$", colour = G.C.GOLD },
	}
	local function rnj_ability(card)
		local abilities = card.ability.abilities
		return abilities and abilities[1] or {}, type(card.ability.extra) == "table" and card.ability.extra or {}
	end
	-- The suit/rank/face condition on cards; "odds" (random) and no condition always pass.
	local function rnj_card_matches(ability, playing_card)
		if ability.cond == "suit" then
			return playing_card:is_suit(ability.suit)
		elseif ability.cond == "rank" then
			return playing_card:get_id() == ability.rank
		elseif ability.cond == "face" then
			return playing_card:is_face()
		end
		return true
	end
	-- Whether a joker_main ability's condition holds for the selected hand.
	local function rnj_hand_matches(ability, state)
		if ability.cond == "first" then
			return G.GAME.current_round.hands_played == 0
		elseif ability.cond == "last" then
			return jd.is_last_hand()
		elseif ability.cond == "poker_hand" then
			local _, poker_hands = JokerDisplay.evaluate_hand()
			return poker_hands[ability.poker_hand] and next(poker_hands[ability.poker_hand]) and true or false
		elseif ability.cond == "or_more" then
			return #(JokerDisplay.current_hand or {}) >= (state.cond_value or 0)
		elseif ability.cond == "or_less" then
			return #(JokerDisplay.current_hand or {}) <= (state.cond_value or 0)
		end
		return true
	end
	defs.j_cry_rnjoker = jd.add_odds({
		text = {
			{ ref_table = "card.joker_display_values", ref_value = "prefix" },
			{ ref_table = "card.joker_display_values", ref_value = "bonus" },
		},
		reminder_text = {
			{ ref_table = "card.joker_display_values", ref_value = "reminder" },
		},
		calc_function = jd.as_played(function(card)
			local ability, state = rnj_ability(card)
			local kind = rnj_kinds[ability.stat]
			local values = card.joker_display_values
			values.prefix, values.bonus, values.reminder, values.odds = "", "", "", ""
			values.colour = kind and kind.colour
			local repeats = ability.context == "repetition_play" or ability.context == "repetition_hand"
			if ability.cond == "odds" and (kind or repeats) then
				values.odds = jd.odds_text(SMODS.get_probability_vars(card, 1, state.cond_value or 0, "RNJoker"))
			end
			if not kind then
				return
			end
			local value = state.value or 0
			values.prefix = kind.prefix
			if ability.stat == "money" then
				values.bonus = value > 0 and value or 0
				values.reminder = "(" .. localize("k_round") .. ")"
				return
			end
			-- Every scoring ability also gives its value in joker_main; there the condition
			-- only applies to abilities that belong to joker_main.
			local count = (ability.context ~= "joker_main" or rnj_hand_matches(ability, state)) and 1 or 0
			if not ability.scale_value then
				local function matches(playing_card)
					return rnj_card_matches(ability, playing_card)
				end
				if ability.context == "individual_play" then
					count = count + jd.count_scoring(matches)
				elseif ability.context == "individual_hand_score" then
					count = count + jd.count_held(matches)
				end
			end
			count = count * JokerDisplay.calculate_joker_triggers(card)
			values.bonus = kind.adds and value * count or value ^ count
		end),
		style_function = function(card, text)
			local colour = card.joker_display_values.colour
			if colour and text and text.children then
				for _, child in ipairs(text.children) do
					child.config.colour = colour
				end
			end
		end,
		-- other_joker abilities: the bonus on each matching Joker, like Baseball Card.
		mod_function = function(other, rnj)
			local ability, state = rnj_ability(rnj)
			local kind = rnj_kinds[ability.stat]
			if not kind or ability.context ~= "other_joker" or other.ability.set ~= "Joker" then
				return {}
			end
			local rarity = other.config.center.rarity
			if (ability.cond == "uncommon" and rarity ~= 2) or (ability.cond == "rare" and rarity ~= 3) then
				return {}
			end
			local value = state.value or 0
			local triggers = JokerDisplay.calculate_joker_triggers(rnj)
			local keys = { plus_mult = "mult", plus_chips = "chips", x_mult = "x_mult", x_chips = "x_chips" }
			return { [keys[ability.stat]] = kind.adds and value * triggers or value ^ triggers }
		end,
		retrigger_function = function(playing_card, scoring_hand, held_in_hand, rnj)
			local ability = rnj_ability(rnj)
			if ability.context == "repetition_play" then
				if held_in_hand or not JokerDisplay.in_scoring(playing_card, scoring_hand) then
					return 0
				end
			elseif ability.context ~= "repetition_hand" or not held_in_hand then
				return 0
			end
			return rnj_card_matches(ability, playing_card) and JokerDisplay.calculate_joker_triggers(rnj) or 0
		end,
	})

	-- Coin: like Misprint, the range of money it can give when a Joker is sold.
	defs.j_cry_coin = {
		text = {
			{ text = "+$" },
			{ ref_table = "card.joker_display_values", ref_value = "range" },
		},
		text_config = { colour = G.C.GOLD },
		calc_function = function(card)
			local money = card.ability.extra.money
			local most = Card.get_gameset(card) ~= "modest" and card.ability.immutable.money_mod or 4
			card.joker_display_values.range = number_format(money) .. "-" .. number_format(to_big(money) * most)
		end,
	}

	-- Old Blueprint: like Blueprint, it copies the Joker to its right.
	defs.j_cry_oldblueprint = {
		reminder_text = {
			{ text = "(" },
			{ ref_table = "card.joker_display_values", ref_value = "blueprint_compat", colour = G.C.RED },
			{ text = ")" },
		},
		calc_function = function(card)
			local copied_joker, copied_debuff = JokerDisplay.calculate_blueprint_copy(card)
			card.joker_display_values.blueprint_compat = localize("k_incompatible")
			JokerDisplay.copy_display(card, copied_joker, copied_debuff)
		end,
		get_blueprint_joker = function(card)
			for i = 1, #G.jokers.cards do
				if G.jokers.cards[i] == card then
					return G.jokers.cards[i + 1]
				end
			end
			return nil
		end,
	}

	-- Night: like Acrobat. ^Mult on the last hand of the round (every hand with Panopticon).
	defs.j_cry_night = {
		text = jd.bonus_text("emult", "e_mult"),
		calc_function = jd.as_played(function(card)
			card.joker_display_values.e_mult = jd.is_last_hand() and card.ability.extra.mult or 1
		end),
	}

	-- Bus Driver: like Gros Michel. +Mult, or -Mult if the chance fails.
	defs.j_cry_busdriver = jd.add_odds({
		text = {
			{ text = "+" },
			{ ref_table = "card.ability.extra", ref_value = "mult", retrigger_type = "mult" },
		},
		text_config = { colour = G.C.MULT },
		calc_function = function(card)
			-- The same numbers as its description.
			local prob = cry_prob(card.ability.cry_prob, card.ability.extra.odds, card.ability.cry_rigged)
			local odds = math.max(1, card.ability.extra.odds)
			card.joker_display_values.odds = jd.odds_text(odds - 1 / prob, odds)
		end,
	})

	-- Membership Card: X Mult for each member of the Cryptid Discord.
	defs.j_cry_membershipcard = {
		text = jd.bonus_text("xmult", "x_mult"),
		calc_function = function(card)
			-- The member count is read from a web response, so it can be a string.
			local x_mult = to_big(card.ability.extra.Xmult_mod) * (tonumber(Cryptid.member_count) or 0)
			card.joker_display_values.x_mult = x_mult > to_big(1) and x_mult or 1
		end,
	}

	-- Old Invisible Joker: duplicates a Joker on the 4th Joker sold. Its own messages count
	-- "N/4", so it's active once 3 have been sold.
	defs.j_cry_oldinvisible = jd.progress(function(card)
		return card.ability.extra, 4, card.ability.extra >= 3
	end)

	-- Card retriggers, like Sock and Buskin.
	local function retrigger_scoring(predicate)
		return {
			retrigger_function = function(playing_card, scoring_hand, held_in_hand, joker_card)
				if held_in_hand or not JokerDisplay.in_scoring(playing_card, scoring_hand) or not predicate(playing_card) then
					return 0
				end
				return capped_retriggers(joker_card) * JokerDisplay.calculate_joker_triggers(joker_card)
			end,
		}
	end
	defs.j_cry_exposed = retrigger_scoring(function(playing_card)
		return not playing_card:is_face()
	end)
	defs.j_cry_mask = retrigger_scoring(function(playing_card)
		return playing_card:is_face()
	end)
	defs.j_cry_sock_and_sock = retrigger_scoring(function(playing_card)
		return SMODS.has_enhancement(playing_card, "m_cry_abstract")
	end)

	-- Digital Hallucinations: like Hallucination, its chance.
	defs.j_cry_digitalhallucinations = jd.chance(function(card)
		return SMODS.get_probability_vars(card, 1, card.ability.odds, "Digital Hallucinations")
	end)

	-- Broken Home: like Gros Michel. X Mult, and its chance to be destroyed.
	local brokenhome = jd.add_odds(jd.stat("xmult", "Xmult"))
	brokenhome.calc_function = function(card)
		card.joker_display_values.odds =
			jd.odds_text(SMODS.get_probability_vars(card, 1, card.ability.extra.odds, "Broken Home"))
	end
	defs.j_cry_brokenhome = brokenhome

	-- Pizza: like Invisible Joker. Rounds until selling it gives the slices.
	defs.j_cry_pizza = jd.progress(function(card)
		local values = card.ability.extra
		return values.rounds_needed - values.rounds_left, values.rounds_needed
	end)

	-- Thalia: X Mult from the rarities among your Jokers.
	defs.j_cry_thalia = {
		text = jd.bonus_text("xmult", "x_mult"),
		calc_function = function(card)
			card.joker_display_values.x_mult = card.config.center:calc_xmult(card)
		end,
	}
end
