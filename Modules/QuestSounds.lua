local PA = _G.ProjectAzilroka
local QS = PA:NewModule('QuestSounds', 'AceEvent-3.0', 'AceTimer-3.0')
PA.QS = QS

QS.Title = '|cFF16C3F2Quest|r|cFFFFFFFFSounds|r'
QS.Description = 'Audio for Quest Progress & Completions.'
QS.Authors = 'Azilroka'
QS.Credits = 'Yoco'

local GetNumQuestLeaderBoards, GetQuestLogLeaderBoard, PlaySoundFile = GetNumQuestLeaderBoards, GetQuestLogLeaderBoard, PlaySoundFile

function QS:CountCompletedObjectives(index)
	local Completed, Total = 0, GetNumQuestLeaderBoards(index)
	for i = 1, Total do
		local _, _, Finished = GetQuestLogLeaderBoard(i, index)
		if Finished then
			Completed = Completed + 1
		end
	end

	return Completed, Total
end

function QS:SetQuest(index)
	QS.QuestIndex = index

	QS:ScheduleTimer(function() QS:CheckQuest() end, .5)
end

function QS:ResetSoundPlayback()
	QS.IsPlaying = false
end

function QS:PlaySoundFile(file)
	QS.QuestIndex = 0

	if QS.IsPlaying or file == nil or file == '' then
		return
	end

	QS.IsPlaying = true

	if QS.db.UseSoundID then
		PlaySoundFile(file)
	else
		PlaySoundFile(PA.LSM:Fetch('sound', file))
	end

	QS:ScheduleTimer('ResetSoundPlayback', 3)
end

function QS:CheckQuest()
	if QS.QuestIndex == 0 then
		return
	end

	--local _, _, _, _, _, complete, daily, id = GetQuestLogTitle(index)

	QS.ObjectivesCompleted, QS.ObjectivesTotal = QS:CountCompletedObjectives(QS.QuestIndex)

	if QS.ObjectivesCompleted == QS.ObjectivesTotal then
		QS:ResetSoundPlayback()
		if QS.db.UseSoundID then
			QS:PlaySoundFile(QS.db.QuestCompleteID)
		else
			QS:PlaySoundFile(QS.db.QuestComplete)
		end
	elseif QS.ObjectivesCompleted > QS.ObjectivesTotal then
		if QS.db.UseSoundID then
			QS:PlaySoundFile(QS.db.ObjectiveCompleteID)
		else
			QS:PlaySoundFile(QS.db.ObjectiveComplete)
		end
	else
		if QS.db.UseSoundID then
			QS:PlaySoundFile(QS.db.ObjectiveProgressID)
		else
			QS:PlaySoundFile(QS.db.ObjectiveProgress)
		end
	end
end

function QS:UNIT_QUEST_LOG_CHANGED(_, unit)
	if unit ~= 'player' then
		return
	end

	QS:ScheduleTimer('CheckQuest', 1)
end

function QS:QUEST_WATCH_UPDATE(_, index)
	QS:SetQuest(index)
end

function QS:GetOptions()
	local Options = {
		type = 'group',
		name = QS.Title,
		desc = QS.Description,
		get = function(info) return QS.db[info[#info]] end,
		set = function(info, value) QS.db[info[#info]] = value end,
		args = {
			Header = {
				order = 0,
				type = 'header',
				name = PA:Color(QS.Title),
			},
			general = {
				order = 1,
				type = 'group',
				name = 'Sounds by LSM',
				guiInline = true,
				get = function(info) return QS.db[info[#info]] end,
				set = function(info, value) QS.db[info[#info]] = value end,
				args = {
					QuestComplete = {
						type = "select", dialogControl = 'LSM30_Sound',
						order = 1,
						name = 'Quest Complete',
						values = PA.LSM:HashTable('sound'),
						disabled = function() return QS.db.UseSoundID end,
					},
					ObjectiveComplete = {
						type = "select", dialogControl = 'LSM30_Sound',
						order = 2,
						name = 'Objective Complete',
						values = PA.LSM:HashTable('sound'),
						disabled = function() return QS.db.UseSoundID end,
					},
					ObjectiveProgress = {
						type = "select", dialogControl = 'LSM30_Sound',
						order = 3,
						name = 'Objective Progress',
						values = PA.LSM:HashTable('sound'),
						disabled = function() return QS.db.UseSoundID end,
					},
				},
			},
			soundbyid = {
				order = 2,
				type = 'group',
				name = 'Sound by SoundID',
				guiInline = true,
				get = function(info) return tostring(QS.db[info[#info]]) end,
				set = function(info, value) QS.db[info[#info]] = tonumber(value) end,
				args = {
					UseSoundID = {
						order = 1,
						type = 'toggle',
						get = function(info) return QS.db[info[#info]] end,
						set = function(info, value) QS.db[info[#info]] = value end,
						name = PA.ACL['Use Sound ID'],
					},
					QuestCompleteID = {
						order = 2,
						type = "input",
						name = 'Quest Complete Sound ID',
						disabled = function() return (not QS.db.UseSoundID) end,
					},
					ObjectiveCompleteID = {
						order = 3,
						type = "input",
						name = 'Objective Complete Sound ID',
						disabled = function() return (not QS.db.UseSoundID) end,
					},
					ObjectiveProgressID = {
						order = 4,
						type = "input",
						name = 'Objective Progress Sound ID',
						disabled = function() return (not QS.db.UseSoundID) end,
					},
				},
			},
			AuthorHeader = {
				order = 11,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = 12,
				type = 'description',
				name = QS.Authors,
				fontSize = 'large',
			},
			CreditsHeader = {
				order = 13,
				type = 'header',
				name = PA.ACL['Credits:'],
			},
			Credits = {
				order = 14,
				type = 'description',
				name = QS.Credits,
				fontSize = 'large',
			},
		},
	}

	PA.Options.args.QuestSounds = Options
end

function QS:BuildProfile()
	PA.Defaults.profile['QuestSounds'] = {
		['Enable'] = false,
		['QuestComplete'] = 'Peon Quest Complete',
		['ObjectiveComplete'] = 'Peon Objective Complete',
		['ObjectiveProgress'] = 'Peon Objective Progress',
		['UseSoundID'] = false,
		['QuestCompleteID'] = PA.MyFaction == 'Alliance' and 61525 or 95834,
		['ObjectiveCompleteID'] = 6573,
		['ObjectiveProgressID'] = 9873,
	}

	PA.Options.args.general.args.QuestSounds = {
		type = 'toggle',
		name = QS.Title,
		desc = QS.Description,
	}
end

function QS:RegisterSounds()
	PA.LSM:Register("sound", "Rubber Ducky", [[Sound\Doodad\Goblin_Lottery_Open01.ogg]])
	PA.LSM:Register("sound", "Cartoon FX", [[Sound\Doodad\Goblin_Lottery_Open03.ogg]])
	PA.LSM:Register("sound", "Explosion", [[Sound\Doodad\Hellfire_Raid_FX_Explosion05.ogg]])
	PA.LSM:Register("sound", "Shing!", [[Sound\Doodad\PortcullisActive_Closed.ogg]])
	PA.LSM:Register("sound", "Wham!", [[Sound\Doodad\PVP_Lordaeron_Door_Open.ogg]])
	PA.LSM:Register("sound", "Simon Chime", [[Sound\Doodad\SimonGame_LargeBlueTree.ogg]])
	PA.LSM:Register("sound", "War Drums", [[Sound\Event Sounds\Event_wardrum_ogre.ogg]])
	PA.LSM:Register("sound", "Cheer", [[Sound\Event Sounds\OgreEventCheerUnique.ogg]])
	PA.LSM:Register("sound", "Humm", [[Sound\Spells\SimonGame_Visual_GameStart.ogg]])
	PA.LSM:Register("sound", "Short Circuit", [[Sound\Spells\SimonGame_Visual_BadPress.ogg]])
	PA.LSM:Register("sound", "Fel Portal", [[Sound\Spells\Sunwell_Fel_PortalStand.ogg]])
	PA.LSM:Register("sound", "Fel Nova", [[Sound\Spells\SeepingGaseous_Fel_Nova.ogg]])
	PA.LSM:Register("sound", "You Will Die!", [[Sound\Creature\CThun\CThunYouWillDIe.ogg]])
	PA.LSM:Register("sound", 'Gong Quest Complete', [[Sound\Doodad\G_GongTroll01.ogg]])
	PA.LSM:Register("sound", 'Gong Objective Complete', [[Sound\Doodad\G_BearTrapReverse_Close01.ogg]])
	PA.LSM:Register("sound", 'Gong Objective Progress', [[Sound\Spells\Bonk1.ogg]])
	PA.LSM:Register("sound", 'Wacky Quest Complete', [[Sound\Doodad\Goblin_Lottery_Open02.ogg]])
	PA.LSM:Register("sound", 'Wacky Objectives Complete', [[Sound\Events\UD_DiscoBallSpawn.ogg]])
	PA.LSM:Register("sound", 'Wacky Objective Progress', [[Sound\Doodad\Goblin_Lottery_Open02.ogg]])
	PA.LSM:Register("sound", 'Creature Quest Complete', [[Sound\Creature\Chicken\ChickenDeathA.ogg]])
	PA.LSM:Register("sound", 'Creature Objective Complete', [[Sound\Creature\Frog\FrogFootstep2.ogg]])
	PA.LSM:Register("sound", 'Creature Objective Progress', [[Sound\Creature\Crab\CrabWoundC.ogg]])
	PA.LSM:Register("sound", 'Peon Quest Complete', [[Sound\Creature\Peon\PeonBuildingComplete1.ogg]])
	PA.LSM:Register("sound", 'Peon Objective Complete', [[Sound\Creature\Peon\PeonReady1.ogg]])
	PA.LSM:Register("sound", 'Peon Objective Progress', [[Sound\Creature\Peasant\PeasantWhat3.ogg]])
	PA.LSM:Register("sound", 'QuestGuru Quest Complete', [[Sound\Interface\levelup2.ogg]])
	PA.LSM:Register("sound", 'QuestGuru Objective Complete', [[Sound\Interface\AuctionWindowClose.ogg]])
	PA.LSM:Register("sound", 'QuestGuru Objective Progress', [[Sound\Interface\AuctionWindowOpen.ogg]])
end

function QS:Initialize()
	QS.db = PA.db['QuestSounds']

	if QS.db.Enable ~= true then
		return
	end

	QS:RegisterSounds()

	QS:GetOptions()

	QS.QuestIndex = 0
	QS.ObjectivesComplete = 0
	QS.ObjectivesTotal = 0
	QS.IsPlaying = false

	QS:RegisterEvent('UNIT_QUEST_LOG_CHANGED')
	QS:RegisterEvent('QUEST_WATCH_UPDATE')

	local KT = LibStub("AceAddon-3.0"):GetAddon('!KalielsTracker', true)

	if KT and KT.db.profile.soundQuest then
		StaticPopupDialogs["PROJECTAZILROKA"].text = 'Kaliels Tracker Quest Sound and QuestSounds will make double sounds. Which one do you want to disable?\n\n(This does not disable Kaliels Tracker)'
		StaticPopupDialogs["PROJECTAZILROKA"].button1 = 'KT Quest Sound'
		StaticPopupDialogs["PROJECTAZILROKA"].button2 = 'Quest Sounds'
		StaticPopupDialogs["PROJECTAZILROKA"].OnAccept = function()
			KT.db.profile.soundQuest = false
			StaticPopupDialogs["PROJECTAZILROKA"].text = PA.ACL["A setting you have changed will change an option for this character only. This setting that you have changed will be uneffected by changing user profiles. Changing this setting requires that you reload your User Interface."]
			StaticPopupDialogs["PROJECTAZILROKA"].button1 = ACCEPT
			StaticPopupDialogs["PROJECTAZILROKA"].button2 = CANCEL
			StaticPopupDialogs["PROJECTAZILROKA"].OnAccept = ReloadUI
			StaticPopupDialogs["PROJECTAZILROKA"].OnCancel = nil
		end
		StaticPopupDialogs["PROJECTAZILROKA"].OnCancel = function() QS.db['Enable'] = false ReloadUI() end
		StaticPopup_Show("PROJECTAZILROKA")
		return
	end

	if PA:IsAddOnEnabled('QuestGuruSounds', PA.MyName) then
		StaticPopupDialogs["PROJECTAZILROKA"].text = 'QuestGuru Sounds and QuestSounds will make double sounds. Which one do you want to disable?'
		StaticPopupDialogs["PROJECTAZILROKA"].button1 = 'KT Quest Sound'
		StaticPopupDialogs["PROJECTAZILROKA"].button2 = 'Quest Sounds'
		StaticPopupDialogs["PROJECTAZILROKA"].OnAccept = function() DisableAddOn('QuestGuruSounds') ReloadUI() end
		StaticPopupDialogs["PROJECTAZILROKA"].OnCancel = function() QS.db['Enable'] = false ReloadUI() end
		StaticPopup_Show("PROJECTAZILROKA")
	end
end