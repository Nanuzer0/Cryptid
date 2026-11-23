-- Changes to base JokerDisplay itself: its vanilla Joker definitions, the editions it knows
-- about, and the colour of its ^Mult modifier.
return function(jd)
	local defs = JokerDisplay.Definitions

	-- Jokers that check for the first or last hand or discard of the round: show them the way
	-- Panopticon and Labyrinth make them work (see jd.as_played).
	-- Delayed Gratification is left out: it checks discards_used at the end of the round,
	-- which Labyrinth doesn't change.
	for _, key in ipairs({ "j_acrobat", "j_dusk", "j_dna", "j_sixth_sense", "j_trading", "j_burnt" }) do
		local def = defs[key]
		if def then
			for _, field in ipairs({ "calc_function", "retrigger_function" }) do
				if def[field] then
					def[field] = jd.as_played(def[field])
				end
			end
		end
	end

	-- Editions on Jokers, added to the modifiers shown under each Joker (like Foil's +Chips).
	-- JokerDisplay reads vanilla editions through Card:get_edition, which already covers
	-- Cryptid's M (+Mult) and Glass (X Mult), but not Mosaic's X Chips or Astral's ^Mult.
	local editions = JokerDisplay.Edition_Definitions
	if editions then
		editions.e_cry_mosaic = {
			condition_function = function(card)
				return not card.debuff and card.edition and card.edition.cry_mosaic
			end,
			mod_function = function(card)
				return { x_chips = card.edition.x_chips }
			end,
		}
		editions.e_cry_astral = {
			condition_function = function(card)
				return not card.debuff and card.edition and card.edition.cry_astral
			end,
			mod_function = function(card)
				return { e_mult = card.edition.e_mult }
			end,
		}
	end

	-- JokerDisplay draws the ^Mult modifier box (e.g. Astral, or Universe on an Astral Joker) in
	-- the dark edition colour. Use Amulet's ^Mult colour instead, like jd.bonus_text does: Amulet
	-- updates G.C.emult in place, so the box follows its gradient.
	local function recolour(node, from, to)
		if node.config and node.config.colour == from then
			node.config.colour = to
		end
		for _, child in ipairs(node.children or {}) do
			recolour(child, from, to)
		end
	end
	if JokerDisplayBox and JokerDisplayBox.add_modifiers then
		local add_modifiers_ref = JokerDisplayBox.add_modifiers
		function JokerDisplayBox:add_modifiers(...)
			local ret = add_modifiers_ref(self, ...)
			if G.C.emult and G.C.emult ~= G.C.DARK_EDITION and self.modifier_row then
				recolour(self.modifier_row, G.C.DARK_EDITION, G.C.emult)
			end
			return ret
		end
	end
end
