local PA = _G.ProjectAzilroka
local QS = PA:NewModule('QuestSounds', 'AceEvent-3.0', 'AceTimer-3.0')
PA.QS = QS

QS.Title = PA.ACL['|cFF16C3F2Quest|r|cFFFFFFFFSounds|r']
QS.Description = PA.ACL['Audio for Quest Progress & Completions.']
QS.Authors = 'Azilroka'
QS.Credits = 'Yoco'
QS.isEnabled = false

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

function QS:RegisterSounds()
	if PA.Classic then
		PA.LSM:Register('sound', 'You Will Die!', 'Sound/Creature/CThun/CThunYouWillDIe.ogg')
		PA.LSM:Register('sound', 'Gong Quest Complete', 'Sound/Doodad/G_GongTroll01.ogg')
		PA.LSM:Register('sound', 'Creature Quest Complete', 'Sound/Creature/Chicken/ChickenDeathA.ogg')
		PA.LSM:Register('sound', 'Creature Objective Complete', 'Sound/Creature/Frog/FrogFootstep2.ogg')
		PA.LSM:Register('sound', 'Creature Objective Progress', 'Sound/Creature/Crab/CrabWoundC.ogg')
		PA.LSM:Register('sound', 'Peon Quest Complete', 'Sound/Creature/Peon/PeonBuildingComplete1.ogg')
		PA.LSM:Register('sound', 'Peon Objective Complete', 'Sound/Creature/Peon/PeonReady1.ogg')
		PA.LSM:Register('sound', 'Peon Objective Progress', 'Sound/Creature/Peasant/PeasantWhat3.ogg')
		PA.LSM:Register('sound', 'QuestGuru Quest Complete', 'Sound/Interface/levelup2.ogg')
		PA.LSM:Register('sound', 'QuestGuru Objective Complete', 'Sound/Interface/AuctionWindowClose.ogg')
		PA.LSM:Register('sound', 'QuestGuru Objective Progress', 'Sound/Interface/AuctionWindowOpen.ogg')
	else
		PA.LSM:Register('sound', 'Rubber Ducky', 566121)
		PA.LSM:Register('sound', 'Cartoon FX', 566543)
		PA.LSM:Register('sound', 'Explosion', 566982)
		PA.LSM:Register('sound', 'Shing!', 566240)
		PA.LSM:Register('sound', 'Wham!', 566946)
		PA.LSM:Register('sound', 'Simon Chime', 566076)
		PA.LSM:Register('sound', 'War Drums', 567275)
		PA.LSM:Register('sound', 'Cheer', 567283)
		PA.LSM:Register('sound', 'Humm', 569518)
		PA.LSM:Register('sound', 'Short Circuit', 568975)
		PA.LSM:Register('sound', 'Fel Portal', 569215)
		PA.LSM:Register('sound', 'Fel Nova', 568582)
		PA.LSM:Register('sound', 'You Will Die!', 546633)
		PA.LSM:Register('sound', 'Gong Quest Complete', 565564)
		PA.LSM:Register('sound', 'Gong Objective Complete', 565515)
		PA.LSM:Register('sound', 'Gong Objective Progress', 569179)
		PA.LSM:Register('sound', 'Wacky Quest Complete', 566877)
		PA.LSM:Register('sound', 'Wacky Objectives Complete', 567381)
		PA.LSM:Register('sound', 'Wacky Objective Progress', 566877)
		PA.LSM:Register('sound', 'Creature Quest Complete', 546068)
		PA.LSM:Register('sound', 'Creature Objective Complete', 549326)
		PA.LSM:Register('sound', 'Creature Objective Progress', 546421)
		PA.LSM:Register('sound', 'Peon Quest Complete', 558132)
		PA.LSM:Register('sound', 'Peon Objective Complete', 558137)
		PA.LSM:Register('sound', 'Peon Objective Progress', 558127)
		PA.LSM:Register('sound', 'QuestGuru Quest Complete', 567478)
		PA.LSM:Register('sound', 'QuestGuru Objective Complete', 567499)
		PA.LSM:Register('sound', 'QuestGuru Objective Progress', 567482)
	end
end

function QS:GetOptions()
	PA.Options.args.QuestSounds = {
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
			Enable = {
				order = 1,
				type = 'toggle',
				name = PA.ACL['Enable'],
				set = function(info, value)
					QS.db[info[#info]] = value
					if (not QS.isEnabled) then
						QS:Initialize()
					else
						_G.StaticPopup_Show('PROJECTAZILROKA_RL')
					end
				end,
			},
			General = {
				order = 2,
				type = 'group',
				name = PA.ACL['General'],
				guiInline = true,
				args = {
					LSM = {
						order = 1,
						type = 'group',
						name = 'Sound by LSM',
						disabled = function() return QS.db.UseSoundID end,
						args = {
							QuestComplete = {
								type = 'select', dialogControl = 'LSM30_Sound',
								order = 1,
								name = 'Quest Complete',
								values = PA.LSM:HashTable('sound'),
							},
							ObjectiveComplete = {
								type = 'select', dialogControl = 'LSM30_Sound',
								order = 2,
								name = 'Objective Complete',
								values = PA.LSM:HashTable('sound'),
							},
							ObjectiveProgress = {
								type = 'select', dialogControl = 'LSM30_Sound',
								order = 3,
								name = 'Objective Progress',
								values = PA.LSM:HashTable('sound'),
							},
						},
					},
					ID = {
						order = 2,
						type = 'group',
						name = 'Sound by SoundID',
						get = function(info) return tostring(QS.db[info[#info]]) end,
						set = function(info, value) QS.db[info[#info]] = tonumber(value) end,
						disabled = function() return (not QS.db.UseSoundID) end,
						args = {
							UseSoundID = {
								order = 1,
								type = 'toggle',
								get = function(info) return QS.db[info[#info]] end,
								set = function(info, value) QS.db[info[#info]] = value end,
								disabled = false,
								name = PA.ACL['Use Sound ID'],
							},
							QuestCompleteID = {
								order = 2,
								type = 'input',
								name = 'Quest Complete Sound ID',
							},
							ObjectiveCompleteID = {
								order = 3,
								type = 'input',
								name = 'Objective Complete Sound ID',
							},
							ObjectiveProgressID = {
								order = 4,
								type = 'input',
								name = 'Objective Progress Sound ID',
							},
						},
					},
				},
			},
			AuthorHeader = {
				order = -4,
				type = 'header',
				name = PA.ACL['Authors:'],
			},
			Authors = {
				order = -3,
				type = 'description',
				name = QS.Authors,
				fontSize = 'large',
			},
			CreditsHeader = {
				order = -2,
				type = 'header',
				name = PA.ACL['Credits:'],
			},
			Credits = {
				order = -1,
				type = 'description',
				name = QS.Credits,
				fontSize = 'large',
			},
		},
	}
end

function QS:BuildProfile()
	QS:RegisterSounds()

	PA.Defaults.profile.QuestSounds = {
		Enable = false,
		QuestComplete = 'Peon Quest Complete',
		ObjectiveComplete = 'Peon Objective Complete',
		ObjectiveProgress = 'Peon Objective Progress',
		UseSoundID = false,
		QuestCompleteID = PA.MyFaction == 'Alliance' and 61525 or 95834,
		ObjectiveCompleteID = 6573,
		ObjectiveProgressID = 9873,
	}
end

function QS:Initialize()
	QS.db = PA.db.QuestSounds

	if QS.db.Enable ~= true then
		return
	end

	QS.isEnabled = true

	QS.QuestIndex = 0
	QS.ObjectivesComplete = 0
	QS.ObjectivesTotal = 0
	QS.IsPlaying = false

	QS:RegisterEvent('UNIT_QUEST_LOG_CHANGED')
	QS:RegisterEvent('QUEST_WATCH_UPDATE')

	local KT = _G.LibStub('AceAddon-3.0'):GetAddon('!KalielsTracker', true)

	if KT and KT.db.profile.soundQuest then
		_G.StaticPopupDialogs.PROJECTAZILROKA.text = 'Kaliels Tracker Quest Sound and QuestSounds will make double sounds. Which one do you want to disable?\n\n(This does not disable Kaliels Tracker)'
		_G.StaticPopupDialogs.PROJECTAZILROKA.button1 = 'KT Quest Sound'
		_G.StaticPopupDialogs.PROJECTAZILROKA.button2 = 'Quest Sounds'
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnAccept = function()
			KT.db.profile.soundQuest = false
			_G.StaticPopupDialogs.PROJECTAZILROKA.text = PA.ACL['A setting you have changed will change an option for this character only. This setting that you have changed will be uneffected by changing user profiles. Changing this setting requires that you reload your User Interface.']
			_G.StaticPopupDialogs.PROJECTAZILROKA.button1 = _G.ACCEPT
			_G.StaticPopupDialogs.PROJECTAZILROKA.button2 = _G.CANCEL
			_G.StaticPopupDialogs.PROJECTAZILROKA.OnAccept = _G.ReloadUI
			_G.StaticPopupDialogs.PROJECTAZILROKA.OnCancel = nil
		end
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnCancel = function() QS.db['Enable'] = false _G.ReloadUI() end
		_G.StaticPopup_Show('PROJECTAZILROKA')
		return
	end

	if PA:IsAddOnEnabled('QuestGuruSounds', PA.MyName) then
		_G.StaticPopupDialogs.PROJECTAZILROKA.text = 'QuestGuru Sounds and QuestSounds will make double sounds. Which one do you want to disable?'
		_G.StaticPopupDialogs.PROJECTAZILROKA.button1 = 'KT Quest Sound'
		_G.StaticPopupDialogs.PROJECTAZILROKA.button2 = 'Quest Sounds'
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnAccept = function() _G.DisableAddOn('QuestGuruSounds') _G.ReloadUI() end
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnCancel = function() QS.db['Enable'] = false _G.ReloadUI() end
		_G.StaticPopup_Show('PROJECTAZILROKA')
	end
end
