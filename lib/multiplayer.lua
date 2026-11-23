-- Compatibility with the Balatro Multiplayer mods (MultiplayerAPI, MultiplayerPvP).
-- Everything here must also work when they aren't installed.

-- Whether the player is in a Multiplayer lobby. This includes PvP's practice mode,
-- which runs in a local lobby.
function Cryptid.in_mp_lobby()
	return type(MPAPI) == "table"
		and type(MPAPI.get_current_lobby) == "function"
		and MPAPI.get_current_lobby() ~= nil
end
