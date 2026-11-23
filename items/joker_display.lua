-- JokerDisplay support. The definitions live in jokerdisplay/, one file per items/ file (plus
-- vanilla.lua for changes to base JokerDisplay's vanilla definitions), and share the helpers
-- in jokerdisplay/shared.lua.
-- JokerDisplay loads before Cryptid (much lower priority), so if it's installed its
-- JokerDisplay.Definitions table exists by now; without it nothing here runs.
if JokerDisplay and JokerDisplay.Definitions then
	local jd = assert(SMODS.load_file("jokerdisplay/shared.lua"))()
	for _, file in ipairs({ "vanilla", "misc_joker", "epic", "exotic" }) do
		assert(SMODS.load_file("jokerdisplay/" .. file .. ".lua"))()(jd)
	end
end

return { name = "JokerDisplay" }
