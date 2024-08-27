local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
local QS = PA:NewModule('QuestSounds', 'AceEvent-3.0', 'AceTimer-3.0')
local LSM = PA.Libs.LSM

PA.QuestSounds = QS

QS.Title, QS.Description, QS.Authors, QS.Credits, QS.isEnabled = 'QuestSounds', ACL['Audio for Quest Progress & Completions.'], 'Azilroka', 'Yoco', false

local tonumber = tonumber
local PlaySound, PlaySoundFile = PlaySound, PlaySoundFile

function QS:CountCompletedObjectives(questID)
	local Objectives = C_QuestLog.GetQuestObjectives(questID)
	local Completed, Total = 0, 0
	for _, objective in ipairs(Objectives) do
		if objective.finished then
			Completed = Completed + 1
		end
		Total = Total + 1
	end

	return Completed, Total
end

function QS:SetQuest(index)
	QS.QuestID = index
	QS:ScheduleTimer('CheckQuest', .5)
end

function QS:ResetSoundPlayback()
	QS.IsPlaying = false
end

function QS:PlaySoundFile(file)
	QS.QuestID = nil

	if QS.IsPlaying or not file or file == '' then
		return
	end

	QS.IsPlaying = true

	if QS.db.UseSoundID then
		PlaySound(tonumber(file), QS.db.Channel)
	else
		PlaySoundFile(LSM:Fetch('sound', file), QS.db.Channel)
	end

	QS:ScheduleTimer('ResetSoundPlayback', QS.db.Throttle)
end

function QS:CheckQuest()
	if not QS.QuestID then return end

	if PA.Retail and C_QuestLog.ReadyForTurnIn(QS.QuestID) then
		QS:ResetSoundPlayback()
		QS:PlaySoundFile(QS.db.UseSoundID and QS.db.QuestCompleteID or QS.db.QuestComplete)
	else
		QS.ObjectivesCompleted, QS.ObjectivesTotal = QS:CountCompletedObjectives(QS.QuestID)

		if QS.ObjectivesCompleted > QS.ObjectivesTotal then
			QS:PlaySoundFile(QS.db.UseSoundID and QS.db.ObjectiveCompleteID or QS.db.ObjectiveComplete)
		else
			QS:PlaySoundFile(QS.db.UseSoundID and QS.db.ObjectiveProgressID or QS.db.ObjectiveProgress)
		end
	end
end

function QS:UNIT_QUEST_LOG_CHANGED(_, unit)
	if unit ~= 'player' then return end

	QS:ScheduleTimer('CheckQuest', 1)
end

function QS:QUEST_WATCH_UPDATE(_, questID)
	QS:SetQuest(questID)
end

function QS:RegisterSounds()
	if PA.Classic then
		LSM:Register('sound', 'You Will Die!', 'Sound/Creature/CThun/CThunYouWillDIe.ogg')
		LSM:Register('sound', 'Gong Quest Complete', 'Sound/Doodad/G_GongTroll01.ogg')
		LSM:Register('sound', 'Creature Quest Complete', 'Sound/Creature/Chicken/ChickenDeathA.ogg')
		LSM:Register('sound', 'Creature Objective Complete', 'Sound/Creature/Frog/FrogFootstep2.ogg')
		LSM:Register('sound', 'Creature Objective Progress', 'Sound/Creature/Crab/CrabWoundC.ogg')
		LSM:Register('sound', 'Peon Quest Complete', 'Sound/Creature/Peon/PeonBuildingComplete1.ogg')
		LSM:Register('sound', 'Peon Objective Complete', 'Sound/Creature/Peon/PeonReady1.ogg')
		LSM:Register('sound', 'Peon Objective Progress', 'Sound/Creature/Peasant/PeasantWhat3.ogg')
		LSM:Register('sound', 'QuestGuru Quest Complete', 'Sound/Interface/levelup2.ogg')
		LSM:Register('sound', 'QuestGuru Objective Complete', 'Sound/Interface/AuctionWindowClose.ogg')
		LSM:Register('sound', 'QuestGuru Objective Progress', 'Sound/Interface/AuctionWindowOpen.ogg')
	else
		LSM:Register('sound', 'Rubber Ducky', 566121)
		LSM:Register('sound', 'Cartoon FX', 566543)
		LSM:Register('sound', 'Explosion', 566982)
		LSM:Register('sound', 'Shing!', 566240)
		LSM:Register('sound', 'Wham!', 566946)
		LSM:Register('sound', 'Simon Chime', 566076)
		LSM:Register('sound', 'War Drums', 567275)
		LSM:Register('sound', 'Cheer', 567283)
		LSM:Register('sound', 'Humm', 569518)
		LSM:Register('sound', 'Short Circuit', 568975)
		LSM:Register('sound', 'Fel Portal', 569215)
		LSM:Register('sound', 'Fel Nova', 568582)
		LSM:Register('sound', 'You Will Die!', 546633)
		LSM:Register('sound', 'Gong Quest Complete', 565564)
		LSM:Register('sound', 'Gong Objective Complete', 565515)
		LSM:Register('sound', 'Gong Objective Progress', 569179)
		LSM:Register('sound', 'Wacky Quest Complete', 566877)
		LSM:Register('sound', 'Wacky Objectives Complete', 567381)
		LSM:Register('sound', 'Wacky Objective Progress', 566877)
		LSM:Register('sound', 'Creature Quest Complete', 546068)
		LSM:Register('sound', 'Creature Objective Complete', 549326)
		LSM:Register('sound', 'Creature Objective Progress', 546421)
		LSM:Register('sound', 'Peon Quest Complete', 558132)
		LSM:Register('sound', 'Peon Objective Complete', 558137)
		LSM:Register('sound', 'Peon Objective Progress', 558127)
		LSM:Register('sound', 'QuestGuru Quest Complete', 567478)
		LSM:Register('sound', 'QuestGuru Objective Complete', 567499)
		LSM:Register('sound', 'QuestGuru Objective Progress', 567482)
	end
end

function QS:GetOptions()
	local QuestSounds = ACH:Group(QS.Title, QS.Description, nil, nil, function(info) return QS.db[info[#info]] end, function(info, value) QS.db[info[#info]] = value end)
	PA.Options.args.QuestSounds = QuestSounds

	QuestSounds.args.Description = ACH:Description(QS.Description, 0)
	QuestSounds.args.Enable = ACH:Toggle(ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) QS.db[info[#info]] = value if (not QS.isEnabled) then QS:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	QuestSounds.args.General = ACH:Group(ACL['General'], nil, 2)
	QuestSounds.args.General.inline = true
	QuestSounds.args.General.args.Throttle = ACH:Range(ACL['Throttle'], nil, nil, { min = 1, max = 30, step = 1})
	QuestSounds.args.General.args.Channel = ACH:Select(ACL['Channel'], nil, nil, {Master = ACL['Master'], SFX = ACL['SFX'], Ambience = ACL['Ambience'], Dialog = ACL['Dialog']})

	QuestSounds.args.General.args.LSM = ACH:Group(ACL['Sound by LSM'], nil, 1, nil, nil, nil, function() return QS.db.UseSoundID end)
	QuestSounds.args.General.args.LSM.args.QuestComplete = ACH:SharedMediaSound(ACL['Quest Complete'], nil, 1)
	QuestSounds.args.General.args.LSM.args.ObjectiveComplete = ACH:SharedMediaSound(ACL['Objective Complete'], nil, 2)
	QuestSounds.args.General.args.LSM.args.ObjectiveProgress = ACH:SharedMediaSound(ACL['Objective Progress'], nil, 3)

	QuestSounds.args.General.args.ID = ACH:Group(ACL['Sound by SoundID'], nil, 2, nil, function(info) return tostring(QS.db[info[#info]]) end, function(info, value) QS.db[info[#info]] = tonumber(value) end, function() return (not QS.db.UseSoundID) end)
	QuestSounds.args.General.args.ID.args.UseSoundID = ACH:Toggle(ACL['Use Sound ID'], nil, 0, nil, nil, nil, function(info) return QS.db[info[#info]] end, function(info, value) QS.db[info[#info]] = value end, false)
	QuestSounds.args.General.args.ID.args.QuestCompleteID = ACH:Input(ACL['Quest Complete Sound ID'], nil, 1)
	QuestSounds.args.General.args.ID.args.ObjectiveCompleteID = ACH:Input(ACL['Objective Complete Sound ID'], nil, 2)
	QuestSounds.args.General.args.ID.args.ObjectiveProgressID = ACH:Input(ACL['Objective Progress Sound ID'], nil, 3)

	QuestSounds.args.AuthorHeader = ACH:Header(ACL['Authors:'], -4)
	QuestSounds.args.Authors = ACH:Description(QS.Authors, -3, 'large')
	QuestSounds.args.CreditsHeader = ACH:Header(ACL['Image Credits:'], -2)
	QuestSounds.args.Credits = ACH:Description(QS.Credits, -1, 'large')
end

function QS:BuildProfile()
	QS:RegisterSounds()

	PA.Defaults.profile.QuestSounds = {
		Enable = true,
		Throttle = 3,
		Channel = 'SFX',
		QuestComplete = 'Peon Quest Complete',
		ObjectiveComplete = 'Peon Objective Complete',
		ObjectiveProgress = 'Peon Objective Progress',
		UseSoundID = false,
		QuestCompleteID = PA.MyFaction == 'Alliance' and 61525 or 95834,
		ObjectiveCompleteID = 6573,
		ObjectiveProgressID = 9873,
	}
end

function QS:UpdateSettings()
	QS.db = PA.db.QuestSounds
end

function QS:Initialize()
	if QS.db.Enable ~= true then
		return
	end

	local KT = _G.LibStub('AceAddon-3.0'):GetAddon('!KalielsTracker', true)
	local popup = KT and KT.db.profile.soundQuest or PA:IsAddOnEnabled('QuestGuruSounds', PA.MyName)

	if popup then
		_G.StaticPopupDialogs.PROJECTAZILROKA.text = format('%s and QuestSounds will make double sounds. Which one do you want to disable? %s', KT and 'Kaliels Tracker' or 'QuestGuru Sounds', KT and '|n|n(This does not disable Kaliels Tracker)' or '')
		_G.StaticPopupDialogs.PROJECTAZILROKA.button1 = KT and 'KT Quest Sound' or 'QuestGuru Sounds'
		_G.StaticPopupDialogs.PROJECTAZILROKA.button2 = 'Quest Sounds'
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnAccept = function()
			if KT then
				KT.db.profile.soundQuest = false
			else
				_G.C_AddOns.DisableAddOn('QuestGuruSounds')
			end
			_G.ReloadUI()
		end
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnCancel = function() QS.db.Enable = false end
		_G.StaticPopup_Show('PROJECTAZILROKA')
		return
	end

	QS.ObjectivesComplete, QS.ObjectivesTotal, QS.IsPlaying, QS.isEnabled = 0, 0, true, false

	QS:RegisterEvent('UNIT_QUEST_LOG_CHANGED')
	QS:RegisterEvent('QUEST_WATCH_UPDATE')
end
