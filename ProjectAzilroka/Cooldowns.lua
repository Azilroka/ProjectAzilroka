local PA, ACL, ACH = unpack(_G.ProjectAzilroka)
local LSM = PA.Libs.LSM

--Lua functions
local next, floor, tinsert, mod = next, floor, tinsert, mod

--WoW API / Variables
local GetTime, CreateFrame, hooksecurefunc = GetTime, CreateFrame, hooksecurefunc

local ICON_SIZE = 36 --the normal size for an icon (don't change this)
local FONT_SIZE = 20 --the base font size to use at a scale of 1
local MIN_SCALE = 0.5 --the minimum scale we want to show cooldown counts at, anything below this will be hidden
local MIN_DURATION = 1.5 --the minimum duration to show cooldown text for

PA.TimeColors = {} -- 0:days 1:hours 2:minutes 3:seconds 4:expire 5:mmss 6:hhmm 7:modRate 8:targetAura 9:expiringAura 10-14:targetAura
PA.TimeIndicatorColors = {} -- same color indexes
PA.TimeThreshold = 3

for i = 0, 14 do
	PA.TimeColors[i] = { r = 1, g = 1, b = 1 }
	PA.TimeIndicatorColors[i] = '|cffffffff'
end

PA.TimeFormats = { -- short / indicator color
	-- special options (3, 4): rounding
	[0] = {'%dd', '%d%sd|r', '%.0fd', '%.0f%sd|r'},
	[1] = {'%dh', '%d%sh|r', '%.0fh', '%.0f%sh|r'},
	[2] = {'%dm', '%d%sm|r', '%.0fm', '%.0f%sm|r'},
	-- special options (3, 4): show seconds
	[3] = {'%d', '%d', '%ds', '%d%ss|r'},
	[4] = {'%.1f', '%.1f', '%.1fs', '%.1f%ss|r'},

	[5] = {'%d:%02d', '%d%s:|r%02d'}, -- mmss
}

PA.TimeFormats[6] = PA:CopyTable({}, PA.TimeFormats[5]) -- hhmm
PA.TimeFormats[7] = PA:CopyTable({}, PA.TimeFormats[3]) -- modRate

do
	local YEAR, DAY, HOUR, MINUTE = 31557600, 86400, 3600, 60
	function PA:GetTimeInfo(sec, threshold, hhmm, mmss, modRate)
		if sec < MINUTE then
			if modRate then
				return sec, 7, 0.5 / modRate
			elseif sec > threshold then
				return sec, 3, 0.5
			else
				return sec, 4, 0.1
			end
		elseif mmss and sec < mmss then
			return sec / MINUTE, 5, 1, mod(sec, MINUTE)
		elseif hhmm and sec < (hhmm * MINUTE) then
			return sec / HOUR, 6, 30, mod(sec, HOUR) / MINUTE
		elseif sec < HOUR then
			local mins = mod(sec, HOUR) / MINUTE
			return mins, 2, mins > 2 and 30 or 1
		elseif sec < DAY then
			local hrs = mod(sec, DAY) / HOUR
			return hrs, 1, hrs > 1 and 60 or 30
		else
			local days = mod(sec, YEAR) / DAY
			return days, 0, days > 1 and 120 or 60
		end
	end
end

function PA:Cooldown_UnbuggedTime(timer)
	if timer.buggedTime then
		return time() - GetTime()
	else
		return GetTime()
	end
end

function PA:Cooldown_TextThreshold(cd, now)
	if cd.parent and cd.parent.textThreshold and cd.endTime then
		return (cd.endTime - now) >= cd.parent.textThreshold
	end
end

function PA:Cooldown_BelowScale(cd)
	if cd.parent then
		if cd.parent.hideText then return true end
		if cd.parent.skipScale then return end
	end

	return cd.fontScale and (cd.fontScale < MIN_SCALE)
end

function PA:Cooldown_OnUpdate(elapsed)
	local forced = elapsed == -1
	if forced then
		self.nextUpdate = 0
	elseif self.nextUpdate > 0 then
		self.nextUpdate = self.nextUpdate - elapsed
		return
	end

	if not PA:Cooldown_TimerEnabled(self) then
		PA:Cooldown_TimerStop(self)
		return 2
	else
		local now = PA:Cooldown_UnbuggedTime(self)
		if self.endCooldown and now >= self.endCooldown then
			PA:Cooldown_TimerStop(self)
		elseif PA:Cooldown_BelowScale(self) then
			self.text:SetText('')
			if not forced then
				self.nextUpdate = 500
			end
		elseif self.endTime then
			local timeLeft = (self.endTime - now) / (self.modRate or 1)
			if PA:Cooldown_TextThreshold(self, timeLeft) then
				self.text:SetText('')
				if not forced then
					self.nextUpdate = 1
				end
			else
				local value, id, nextUpdate, remainder = PA:GetTimeInfo(timeLeft, self.threshold, self.hhmmThreshold, self.mmssThreshold, self.modRate ~= 1 and self.modRate)
				if not forced then self.nextUpdate = nextUpdate end

				local style = PA.TimeFormats[id]
				if style then
					local opt = (id < 3 and self.roundTime) or ((id == 3 or id == 4 or id == 7) and self.showSeconds)
					local which = (self.textColors and 2 or 1) + (opt and 2 or 0)
					if self.textColors then
						self.text:SetFormattedText(style[which], value, self.textColors[id], remainder)
					else
						self.text:SetFormattedText(style[which], value, remainder)
					end
				end

				local color = not self.skipTextColor and self.timeColors[id]
				if color then self.text:SetTextColor(color.r, color.g, color.b) end
			end
		end
	end
end

function PA:Cooldown_OnSizeChanged(cd, width, force)
	local scale = width and (floor(width + 0.5) / ICON_SIZE)

	-- dont bother updating when the fontScale is the same, unless we are passing the force arg
	if scale and (scale == cd.fontScale) and (force ~= true) then return end
	cd.fontScale = scale

	-- this is needed because of skipScale variable, we wont allow a font size under the minscale
	if cd.fontScale and (cd.fontScale < MIN_SCALE) then
		scale = MIN_SCALE
	end

	if cd.customFont then -- override font
		cd.text:SetFont(cd.customFont, (scale * cd.customFontSize), cd.customFontOutline)
	elseif scale then -- default, no override
		cd.text:SetFont(PA.Libs.LSM:Fetch('font', PA.Libs.LSM:GetDefault('font')), (scale * FONT_SIZE), 'OUTLINE')
	end
end

function PA:Cooldown_TimerEnabled(cd)
	if cd.forceEnabled then
		return true
	elseif cd.forceDisabled then
		return false
	elseif cd.reverseToggle ~= nil then
		return cd.reverseToggle
	else
		return PA.db.Cooldown.Enable
	end
end

function PA:Cooldown_TimerUpdate(cd)
	PA.Cooldown_OnUpdate(cd, -1)
	cd:Show()
end

function PA:Cooldown_TimerStop(cd)
	cd:Hide()
end

function PA:Cooldown_Options(timer, db, parent)
	local threshold, colors, icolors, hhmm, mmss, fonts
	if parent and db.override then
		threshold = db.threshold
		icolors = db.useIndicatorColor and PA.TimeIndicatorColors[parent.CooldownOverride]
		colors = PA.TimeColors[parent.CooldownOverride]
	end

	if db.checkSeconds then
		hhmm, mmss = db.hhmmThreshold, db.mmssThreshold
	end

	timer.timeColors = colors or PA.TimeColors
	timer.threshold = threshold or PA.db.Cooldown.threshold or PA.TimeThreshold
	timer.textColors = icolors or (PA.db.Cooldown.useIndicatorColor and PA.TimeIndicatorColors)
	timer.hhmmThreshold = hhmm or (PA.db.Cooldown.checkSeconds and PA.db.Cooldown.hhmmThreshold)
	timer.mmssThreshold = mmss or (PA.db.Cooldown.checkSeconds and PA.db.Cooldown.mmssThreshold)
	timer.hideBlizzard = db.hideBlizzard or PA.db.Cooldown.hideBlizzard
	timer.roundTime = PA.db.Cooldown.roundTime
	timer.showModRate = db.showModRate

	if db.reverse ~= nil then
		timer.reverseToggle = (PA.db.Cooldown.Enable and not db.reverse) or (db.reverse and not PA.db.Cooldown.Enable)
	else
		timer.reverseToggle = nil
	end

	if (db ~= PA.db.Cooldown) and db.fonts and db.fonts.enable then
		fonts = db.fonts -- custom fonts override default fonts
	elseif PA.db.Cooldown.fonts and PA.db.Cooldown.fonts.enable then
		fonts = PA.db.Cooldown.fonts -- default global font override
	end

	if fonts and fonts.enable then
		timer.customFont = LSM:Fetch('font', fonts.font)
		timer.customFontSize = fonts.fontSize
		timer.customFontOutline = fonts.fontOutline
	else
		timer.customFont = nil
		timer.customFontSize = nil
		timer.customFontOutline = nil
	end
end

function PA:CreateCooldownTimer(parent)
	local timer = CreateFrame('Frame', nil, parent)
	timer:Hide()
	timer:SetAllPoints()
	timer.parent = parent
	parent.timer = timer

	local text = timer:CreateFontString(nil, 'OVERLAY')
	text:SetPoint('CENTER', 1, 1)
	text:SetJustifyH('CENTER')
	timer.text = text

	-- can be used to modify elements created from this function
	if parent.CooldownPreHook then
		parent.CooldownPreHook(parent)
	end

	-- cooldown override settings
	local db = (parent.CooldownOverride and PA.db[parent.CooldownOverride]) or PA.db
	if db and db.Cooldown then
		PA:Cooldown_Options(timer, db.Cooldown, parent)
	end

	PA:ToggleBlizzardCooldownText(parent, timer)

	-- keep an eye on the size so we can rescale the font if needed
	PA:Cooldown_OnSizeChanged(timer, parent:GetWidth())
	parent:SetScript('OnSizeChanged', function(_, width)
		PA:Cooldown_OnSizeChanged(timer, width)
	end)

	-- keep this after Cooldown_OnSizeChanged
	timer:SetScript('OnUpdate', PA.Cooldown_OnUpdate)

	return timer
end

PA.RegisteredCooldowns = {}
function PA:OnSetCooldown(start, duration, modRate)
	if (not self.forceDisabled) and (start and duration) and (duration > MIN_DURATION) then
		local timer = self.timer or PA:CreateCooldownTimer(self)
		timer.start = start
		timer.modRate = timer.showModRate and modRate or 1
		timer.duration = duration * (not timer.showModRate and modRate or 1)

		local now = GetTime()
		if start <= (now + 1) then -- this second is for Target Aura
			timer.endTime = start + duration
			timer.buggedTime = nil
		else -- https://github.com/Stanzilla/WoWUIBugs/issues/47
			local startup = time() - now
			local cdtime = (2 ^ 32) * 0.001 - start
			local startTime = startup - cdtime
			timer.endTime = startTime + duration
			timer.buggedTime = true
		end

		timer.endCooldown = timer.endTime - 0.05
		timer.paused = nil -- a new cooldown was called

		PA:Cooldown_TimerUpdate(timer)
	elseif self.timer then
		PA:Cooldown_TimerStop(self.timer)
	end
end

function PA:RegisterCooldown(cooldown)
	if not cooldown.isHooked then
		hooksecurefunc(cooldown, 'SetCooldown', PA.OnSetCooldown)
		cooldown.isHooked = true
	end

	if not cooldown.isRegisteredCooldown then
		local module = (cooldown.CooldownOverride or 'global')
		if not PA.RegisteredCooldowns[module] then PA.RegisteredCooldowns[module] = {} end

		tinsert(PA.RegisteredCooldowns[module], cooldown)
		cooldown.isRegisteredCooldown = true
	end
end

function PA:ToggleBlizzardCooldownText(cd, timer, request)
	-- we should hide the blizzard cooldown text when ours are enabled
	if timer and cd and cd.SetHideCountdownNumbers then
		local forceHide = cd.hideText or timer.hideBlizzard
		if request then
			return forceHide or PA:Cooldown_TimerEnabled(timer)
		else
			cd:SetHideCountdownNumbers(forceHide or PA:Cooldown_TimerEnabled(timer))
		end
	end
end

function PA:UpdateCooldownOverride(module)
	local cooldowns = (module and PA.RegisteredCooldowns[module])
	if (not cooldowns) or not next(cooldowns) then return end

	for _, parent in next, cooldowns do
		local db = (parent.CooldownOverride and PA.db[parent.CooldownOverride]) or PA.db
		if db and db.Cooldown then
			local timer = parent.isHooked and parent.isRegisteredCooldown and parent.timer
			local cd = timer or parent

			-- cooldown override settings
			PA:Cooldown_Options(cd, db.Cooldown, parent)

			-- update font on cooldowns
			if timer and cd then -- has a parent, these are timers from RegisterCooldown
				PA:Cooldown_OnSizeChanged(cd, parent:GetWidth(), true)

				PA:ToggleBlizzardCooldownText(parent, cd)
			elseif cd.text and cd.customFont then
				cd.text:SetFont(cd.customFont, cd.customFontSize, cd.customFontOutline)
			end
		end
	end
end

do
	local function RGB(db) return PA:CopyTable({r = 1, g = 1, b = 1}, db) end
	local function HEX(db) return PA:RGBToHex(db.r, db.g, db.b) end

	function PA:GetCooldownColors(db)
		if not db then db = PA.db.Cooldown end -- just incase someone calls this without a first arg use the global

		return
		--> time colors (0 - 7) <-- 7 is mod rate, which is different from text colors (as mod rate has no indicator)
		RGB(db.daysColor), RGB(db.hoursColor), RGB(db.minutesColor), RGB(db.secondsColor), RGB(db.expiringColor), RGB(db.mmssColor), RGB(db.hhmmColor), RGB(db.modRateColor),
		--> text colors (0 - 7) <--
		HEX(db.daysIndicator), HEX(db.hoursIndicator), HEX(db.minutesIndicator), HEX(db.secondsIndicator), HEX(db.expireIndicator), HEX(db.mmssColorIndicator), HEX(db.hhmmColorIndicator)
	end
end

function PA:UpdateCooldownSettings(module)
	local db, timeColors, textColors, _ = PA.db.Cooldown, PA.TimeColors, PA.TimeIndicatorColors

	-- update the module timecolors if the config called it but ignore 'global' and 'all':
	-- global is the main call from config, all is the core file calls
	local isModule = module and (module ~= 'global' and module ~= 'all') and PA.db[module] and PA.db[module].cooldown
	if isModule then
		if not timeColors[module] then timeColors[module] = {} end
		if not textColors[module] then textColors[module] = {} end
		db, timeColors, textColors = PA.db[module].Cooldown, timeColors[module], textColors[module]
	end

	--> color for TIME that has X remaining <--
	timeColors[0], timeColors[1], timeColors[2], timeColors[3], timeColors[4], timeColors[5], timeColors[6], timeColors[7], -- daysColor, hoursColor, minutesColor, secondsColor, expiringColor, mmssColor [MM:SS], hhmmColor [HH:MM], modRateColor
	--> color for TEXT that has X remaining <--
	textColors[0], textColors[1], textColors[2], textColors[3], textColors[4], textColors[5], textColors[6], -- daysIndicator, hoursIndicator, minutesIndicator, secondsIndicator, expireIndicator, mmssColorIndicator, hhmmColorIndicator
	_ = PA:GetCooldownColors(db)

	if isModule then
		PA:UpdateCooldownOverride(module)
	elseif module == 'global' then -- this is only a call from the config change
		for key in next, PA.RegisteredCooldowns do
			PA:UpdateCooldownOverride(key)
		end
	end

	-- okay update the other override settings if it was one of the core file calls
	if module and (module == 'all') then
		PA:UpdateCooldownSettings('OzCooldowns')
		PA:UpdateCooldownSettings('iFilger')
	end
end

local function profile(db)
	return (db == 'global' and PA.db.Cooldown) or PA.db[db].Cooldown
end

local function group(order, db, label)
	local main = ACH:Group(label, nil, order, nil, function(info) local t = (profile(db))[info[#info]] return t.r, t.g, t.b, t.a end, function(info, r, g, b) local t = (profile(db))[info[#info]] t.r, t.g, t.b = r, g, b PA:UpdateCooldownSettings(db) end)
	PA.Options.args.Cooldown.args[db] = main

	local mainArgs = main.args
	mainArgs.showModRate = ACH:Toggle(ACL["Display Modified Rate"], nil, 1, nil, nil, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value PA:UpdateCooldownSettings(db) end)
	mainArgs.reverse = ACH:Toggle(ACL["Reverse Toggle"], ACL["Reverse Toggle will enable Cooldown Text on this module when the global setting is disabled and disable them when the global setting is enabled."], 5, nil, nil, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value PA:UpdateCooldownSettings(db) end)
	mainArgs.hideBlizzard = ACH:Toggle(ACL["Force Hide Blizzard Text"], ACL["This option will force hide Blizzard's cooldown text if it is enabled at [Interface > ActionBars > Show Numbers on Cooldown]."], 6, nil, nil, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value PA:UpdateCooldownSettings(db) end, nil, function() if db == 'global' then return PA.db.Cooldown.Enable else return (PA.db.Cooldown.Enable and not profile(db).reverse) or (not PA.db.Cooldown.Enable and profile(db).reverse) end end)

	local seconds = ACH:Group(ACL["Text Threshold"], nil, 3, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value PA:UpdateCooldownSettings(db) end, function() return not (profile(db)).checkSeconds end)
	seconds.inline = true
	seconds.args.checkSeconds = ACH:Toggle(ACL["Enable"], ACL["This will override the global cooldown settings."], 1, nil, nil, nil, nil, nil, false)
	seconds.args.mmssThreshold = ACH:Range(ACL["MM:SS Threshold"], ACL["Threshold (in seconds) before text is shown in the MM:SS format. Set to -1 to never change to this format."], 2, { min = -1, max = 10800, step = 1 })
	seconds.args.hhmmThreshold = ACH:Range(ACL["HH:MM Threshold"], ACL["Threshold (in minutes) before text is shown in the HH:MM format. Set to -1 to never change to this format."], 3, { min = -1, max = 1440, step = 1 })
	mainArgs.secondsGroup = seconds

	local fonts = ACH:Group(ACL["Fonts"], nil, 4, nil, function(info) return (profile(db)).fonts[info[#info]] end, function(info, value) (profile(db)).fonts[info[#info]] = value PA:UpdateCooldownSettings(db) end, function() return not (profile(db)).fonts.enable end)
	fonts.inline = true
	fonts.args.enable = ACH:Toggle(ACL["Enable"], ACL["This will override the global cooldown settings."], 1, nil, nil, nil, nil, nil, false)
	fonts.args.font = ACH:SharedMediaFont(ACL["Font"], nil, 2)
	fonts.args.fontSize = ACH:Range(ACL["Font Size"], nil, 3, { min = 10, max = 50, step = 1 })
	fonts.args.fontOutline = ACH:FontFlags(ACL["Font Outline"], nil, 4)
	mainArgs.fontGroup = fonts

	local colors = ACH:Group(ACL["Color Override"], nil, 5, nil, nil, nil, function() return not (profile(db)).override end)
	colors.inline = true
	colors.args.override = ACH:Toggle(ACL["Enable"], ACL["This will override the global cooldown settings."], 1, nil, nil, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value PA:UpdateCooldownSettings(db) end, false)
	colors.args.threshold = ACH:Range(ACL["Low Threshold"], ACL["Threshold before text turns red and is in decimal form. Set to -1 for it to never turn red"], 2, { min = -1, max = 20, step = 1 }, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value PA:UpdateCooldownSettings(db) end)
	mainArgs.colorGroup = colors

	local tColors = ACH:Group(ACL["Threshold Colors"], nil, 3)
	tColors.args.modRateColor = ACH:Color(ACL["Modified Rate"], ACL["Color when the text is using a modified timer rate."], 2, nil, nil, nil, nil, nil, not PA.Retail)
	tColors.args.expiringColor = ACH:Color(ACL["Expiring"], ACL["Color when the text is about to expire."], 3)
	tColors.args.secondsColor = ACH:Color(ACL["Seconds"], ACL["Color when the text is in the seconds format."], 4)
	tColors.args.minutesColor = ACH:Color(ACL["Minutes"], ACL["Color when the text is in the minutes format."], 5)
	tColors.args.hoursColor = ACH:Color(ACL["Hours"], ACL["Color when the text is in the hours format."], 6)
	tColors.args.daysColor = ACH:Color(ACL["Days"], ACL["Color when the text is in the days format."], 7)
	tColors.args.mmssColor = ACH:Color(ACL["MM:SS"], nil, 8)
	tColors.args.hhmmColor = ACH:Color(ACL["HH:MM"], nil, 9)
	mainArgs.colorGroup.args.timeColors = tColors

	local iColors = ACH:Group(ACL["Time Indicator Colors"], nil, 4, nil, nil, nil, function() return not (profile(db)).useIndicatorColor end)
	iColors.args.useIndicatorColor = ACH:Toggle(ACL["Use Indicator Color"], nil, 0, nil, nil, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value PA:UpdateCooldownSettings(db) end, false)
	iColors.args.expireIndicator = ACH:Color(ACL["Expiring"], ACL["Color when the text is about to expire"], 1)
	iColors.args.secondsIndicator = ACH:Color(ACL["Seconds"], ACL["Color when the text is in the seconds format."], 2)
	iColors.args.minutesIndicator = ACH:Color(ACL["Minutes"], ACL["Color when the text is in the minutes format."], 3)
	iColors.args.hoursIndicator = ACH:Color(ACL["Hours"], ACL["Color when the text is in the hours format."], 4)
	iColors.args.daysIndicator = ACH:Color(ACL["Days"], ACL["Color when the text is in the days format."], 5)
	iColors.args.hhmmColorIndicator = ACH:Color(ACL["MM:SS"], nil, 6)
	iColors.args.mmssColorIndicator = ACH:Color(ACL["HH:MM"], nil, 7)
	mainArgs.colorGroup.args.indicatorColors = iColors

	if db == 'global' then
		mainArgs.reverse = nil
		mainArgs.colorGroup.args.override = nil
		mainArgs.colorGroup.disabled = nil
		mainArgs.colorGroup.name = ACL["COLORS"]

		mainArgs.roundTime = ACH:Toggle(ACL["Round Timers"], nil, 2, nil, nil, nil, function(info) return (profile(db))[info[#info]] end, function(info, value) (profile(db))[info[#info]] = value PA:UpdateCooldownSettings(db) end)

		-- keep these two in this order
		PA.Options.args.Cooldown.args.hideBlizzard = mainArgs.hideBlizzard
		mainArgs.hideBlizzard = nil
	else
		mainArgs.reverse = nil
		mainArgs.hideBlizzard = nil
		mainArgs.fontGroup = nil
	end
end

PA.Options.args.Cooldown = ACH:Group('Cooldown Text', nil, 0, 'tab', function(info) return PA.db.Cooldown[info[#info]] end, function(info, value) PA.db.Cooldown[info[#info]] = value PA:UpdateCooldownSettings('global') end)
PA.Options.args.Cooldown.args.intro = ACH:Description(ACL['Adjust Cooldown Settings.'], 0)
PA.Options.args.Cooldown.args.Enable = ACH:Toggle(ACL["Enable"], ACL["Display cooldown text on anything with the cooldown spiral."], 1)

group(5, 'global', ACL["Global"])
group(6, 'OzCooldowns', ACL.OzCooldowns)
group(7, 'iFilger', ACL.iFilger)
