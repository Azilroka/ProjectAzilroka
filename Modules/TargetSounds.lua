local PA = _G.ProjectAzilroka
local TS = PA:NewModule('TargetSounds', 'AceEvent-3.0')
PA.TS = TS

TS.Title = PA.ACL['|cFF16C3F2Target|r|cFFFFFFFFSounds|r']
TS.Description = PA.ACL['Audio for Target Sounds.']
TS.Authors = 'Azilroka'

function TS:PLAYER_TARGET_CHANGED()
	if (UnitExists('target') and not IsReplacingUnit()) then
		if ( UnitIsEnemy('target', "player") ) then
			PlaySound(SOUNDKIT.IG_CREATURE_AGGRO_SELECT);
		elseif ( UnitIsFriend("player", 'target') ) then
			PlaySound(SOUNDKIT.IG_CHARACTER_NPC_SELECT);
		else
			PlaySound(SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT);
		end
	end
end

function TS:BuildProfile()
	PA.Defaults.profile['TargetSounds'] = {
		['Enable'] = false,
	}

	PA.Options.args.general.args.TargetSounds = {
		type = 'toggle',
		name = TS.Title,
		desc = TS.Description,
	}
end

function TS:Initialize()
	TS.db = PA.db['QuestSounds']

	if TS.db.Enable ~= true then
		return
	end

	--TS:GetOptions()

	TS:RegisterEvent('PLAYER_TARGET_CHANGED')
end
