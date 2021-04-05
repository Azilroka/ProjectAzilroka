local PA = _G.ProjectAzilroka
local QS = PA:NewModule('QuestSounds', 'AceEvent-3.0', 'AceTimer-3.0')
PA.QS = QS

QS.Title = PA.ACL['|cFF16C3F2Quest|r|cFFFFFFFFSounds|r']
QS.Description = PA.ACL['Audio for Quest Progress & Completions.']
QS.Authors = 'Azilroka'
QS.Credits = 'Yoco'
QS.isEnabled = false

local PlaySoundFile = PlaySoundFile
local PlaySound = PlaySound

function QS:CountCompletedObjectives()
	local Objectives = C_QuestLog.GetQuestObjectives(QS.QuestID)
	local Completed, Total = 0, #Objectives
	for _, objective in ipairs(Objectives) do
		if objective.finished then
			Completed = Completed + 1
		end
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
		PlaySound(tonumber(file))
	else
		PlaySoundFile(PA.LSM:Fetch('sound', file))
	end

	QS:ScheduleTimer('ResetSoundPlayback', QS.db.Throttle)
end

function QS:CheckQuest()
	if not QS.QuestID then return end

	if C_QuestLog.ReadyForTurnIn(QS.QuestID) then
		QS:ResetSoundPlayback()
		if QS.db.UseSoundID then
			QS:PlaySoundFile(QS.db.QuestCompleteID)
		else
			QS:PlaySoundFile(QS.db.QuestComplete)
		end
	else
		QS.ObjectivesCompleted, QS.ObjectivesTotal = QS:CountCompletedObjectives(QS.QuestID)

		if QS.ObjectivesCompleted > QS.ObjectivesTotal then
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
	local QuestSounds = PA.ACH:Group(QS.Title, QS.Description, nil, nil, function(info) return QS.db[info[#info]] end, function(info, value) QS.db[info[#info]] = value end)
	PA.Options.args.QuestSounds = QuestSounds

	QuestSounds.args.Description = PA.ACH:Description(QS.Description, 0)
	QuestSounds.args.Enable = PA.ACH:Toggle(PA.ACL['Enable'], nil, 1, nil, nil, nil, nil, function(info, value) QS.db[info[#info]] = value if (not QS.isEnabled) then QS:Initialize() else _G.StaticPopup_Show('PROJECTAZILROKA_RL') end end)

	QuestSounds.args.General = PA.ACH:Group(PA.ACL['General'], nil, 2)
	QuestSounds.args.General.inline = true
	QuestSounds.args.General.args.Throttle = PA.ACH:Range(PA.ACL['Throttle'], nil, nil, { min = 1, max = 30, step = 1})

	QuestSounds.args.General.args.LSM = PA.ACH:Group(PA.ACL['Sound by LSM'], nil, 1, nil, nil, nil, function() return QS.db.UseSoundID end)
	QuestSounds.args.General.args.LSM.args.QuestComplete = PA.ACH:SharedMediaSound('Quest Complete', nil, 1)
	QuestSounds.args.General.args.LSM.args.ObjectiveComplete = PA.ACH:SharedMediaSound('Objective Complete', nil, 2)
	QuestSounds.args.General.args.LSM.args.ObjectiveProgress = PA.ACH:SharedMediaSound('Objective Progress', nil, 3)

	QuestSounds.args.General.args.ID = PA.ACH:Group(PA.ACL['Sound by SoundID'], nil, 2, nil, function(info) return tostring(QS.db[info[#info]]) end, function(info, value) QS.db[info[#info]] = tonumber(value) end, function() return (not QS.db.UseSoundID) end)
	QuestSounds.args.General.args.ID.args.UseSoundID = PA.ACH:Toggle(PA.ACL['Use Sound ID'], nil, 0, nil, nil, nil, function(info) return QS.db[info[#info]] end, function(info, value) QS.db[info[#info]] = value end, false)
	QuestSounds.args.General.args.ID.args.QuestCompleteID = PA.ACH:Input('Quest Complete Sound ID', nil, 1)
	QuestSounds.args.General.args.ID.args.ObjectiveCompleteID = PA.ACH:Input('Objective Complete Sound ID', nil, 2)
	QuestSounds.args.General.args.ID.args.ObjectiveProgressID = PA.ACH:Input('Objective Progress Sound ID', nil, 3)

	QuestSounds.args.AuthorHeader = PA.ACH:Header(PA.ACL['Authors:'], -4)
	QuestSounds.args.Authors = PA.ACH:Description(QS.Authors, -3, 'large')
	QuestSounds.args.CreditsHeader = PA.ACH:Header(PA.ACL['Image Credits:'], -2)
	QuestSounds.args.Credits = PA.ACH:Description(QS.Credits, -1, 'large')
end

function QS:BuildProfile()
	QS:RegisterSounds()

	PA.Defaults.profile.QuestSounds = {
		Enable = true,
		Throttle = 3,
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

	local KT = _G.LibStub('AceAddon-3.0'):GetAddon('!KalielsTracker', true)

	if KT and KT.db.profile.soundQuest then
		_G.StaticPopupDialogs.PROJECTAZILROKA.text = 'Kaliels Tracker Quest Sound and QuestSounds will make double sounds. Which one do you want to disable?|n|n(This does not disable Kaliels Tracker)'
		_G.StaticPopupDialogs.PROJECTAZILROKA.button1 = 'KT Quest Sound'
		_G.StaticPopupDialogs.PROJECTAZILROKA.button2 = 'Quest Sounds'
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnAccept = function()
			KT.db.profile.soundQuest = false
			_G.ReloadUI()
		end
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnCancel = function() QS.db.Enable = false end
		_G.StaticPopup_Show('PROJECTAZILROKA')
		return
	end

	if PA:IsAddOnEnabled('QuestGuruSounds', PA.MyName) then
		_G.StaticPopupDialogs.PROJECTAZILROKA.text = 'QuestGuru Sounds and QuestSounds will make double sounds. Which one do you want to disable?'
		_G.StaticPopupDialogs.PROJECTAZILROKA.button1 = 'KT Quest Sound'
		_G.StaticPopupDialogs.PROJECTAZILROKA.button2 = 'Quest Sounds'
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnAccept = function() _G.DisableAddOn('QuestGuruSounds') _G.ReloadUI() end
		_G.StaticPopupDialogs.PROJECTAZILROKA.OnCancel = function() QS.db.Enable = false end
		_G.StaticPopup_Show('PROJECTAZILROKA')
		return
	end

	QS.isEnabled = true

	QS.ObjectivesComplete = 0
	QS.ObjectivesTotal = 0
	QS.IsPlaying = false

	QS:RegisterEvent('UNIT_QUEST_LOG_CHANGED')
	QS:RegisterEvent('QUEST_WATCH_UPDATE')
end
