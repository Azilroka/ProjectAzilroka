local PA = _G.ProjectAzilroka
local TS = PA:NewModule('TargetSounds', 'AceEvent-3.0')
PA.TS = TS

TS.Title = PA.ACL['|cFF16C3F2Target|r|cFFFFFFFFSounds|r']
TS.Description = PA.ACL['Audio for Target Sounds.']
TS.Authors = 'Azilroka'
TS.isEnabled = false

local UnitExists = UnitExists
local UnitIsEnemy = UnitIsEnemy
local UnitIsFriend = UnitIsFriend

local IsReplacingUnit = IsReplacingUnit
local PlaySound = PlaySound

function TS:PLAYER_TARGET_CHANGED()
	if (UnitExists('target') and not IsReplacingUnit()) then
		if ( UnitIsEnemy('target', "player") ) then
			PlaySound(_G.SOUNDKIT.IG_CREATURE_AGGRO_SELECT);
		elseif ( UnitIsFriend("player", 'target') ) then
			PlaySound(_G.SOUNDKIT.IG_CHARACTER_NPC_SELECT);
		else
			PlaySound(_G.SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT);
		end
	else
		PlaySound(_G.SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT)
	end
end

function TS:GetOptions()
	PA.Options.args.TargetSounds = {
		type = 'group',
		name = TS.Title,
		get = function(info) return TS.db[info[#info]] end,
		set = function(info, value) TS.db[info[#info]] = value end,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = TS.Title,
			},
			Enable = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Enable'],
				set = function(info, value)
					TS.db[info[#info]] = value
					if (not TS.isEnabled) then
						TS:Initialize()
					else
						_G.StaticPopup_Show('PROJECTAZILROKA_RL')
					end
				end,
			},
			AuthorHeader = {
				order = -2,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = -1,
				type = 'description',
				name = TS.Authors,
				fontSize = 'large',
			},
		},
	}
end

function TS:BuildProfile()
	PA.Defaults.profile.TargetSounds = { Enable = false }
end

function TS:Initialize()
	TS.db = PA.db.TargetSounds

	if TS.db.Enable ~= true then
		return
	end

	TS.isEnabled = true

	TS:RegisterEvent('PLAYER_TARGET_CHANGED')
end
