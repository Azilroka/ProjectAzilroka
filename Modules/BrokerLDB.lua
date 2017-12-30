local PA = _G.ProjectAzilroka
local BrokerLDB = LibStub('AceAddon-3.0'):NewAddon('BrokerLDB', 'AceEvent-3.0')
_G.BrokerLDB = BrokerLDB

BrokerLDB.Title = 'Loot Confirm'
BrokerLDB.Authors = 'Azilroka, Infinitron'

local tonumber, strmatch, select = tonumber, strmatch, select

local LDB = LibStub('LibDataBroker-1.1')
local LSM = LibStub('LibSharedMedia-3.0')

local EP = LibStub("LibElvUIPlugin-1.0", true)

local BrokerLDB = CreateFrame('Button', 'BrokerLDB', UIParent)
BrokerLDB.DropDown = CreateFrame('Frame', 'BrokerLDBDropDown', UIParent, 'UIDropDownMenuTemplate')
BrokerLDB.Slide = 'In'
BrokerLDB.Slides = {}
BrokerLDB.Whitelist = {}
BrokerLDB.EasyMenu = {}
BrokerLDB.PluginObjects = {}
BrokerLDB.Title = GetAddOnMetadata(AddOnName, 'Title')
BrokerLDB.Version = GetAddOnMetadata(AddOnName, 'Version')

local Defaults = {
	['PanelHeight'] = 20,
	['PanelWidth'] = 140,
	['MouseOver'] = false,
	['ShowIcon'] = false,
	['ShowText'] = true,
	['Font'] = 'Tukui Pixel',
	['FontSize'] = 12,
	['FontFlag'] = 'MONOCHROMEOUTLINE',
}

BrokerLDBOptions = CopyTable(Defaults)

BrokerLDBBlacklist = {}

function BrokerLDB:TextUpdate(_, Name, _, Data)
	self.PluginObjects[Name]:SetText(data)
end

function BrokerLDB:ValueUpdate(_, Name, _, Data, Object)
	self.PluginObjects[Name]:SetFormattedText('%s %s', Data, Object.suffix)
end

function BrokerLDB:GetOptions()
	local Options = {
		type = 'group',
		name = BrokerLDB['Title'],
		order = 101,
		args = {
			general = {
				order = 1,
				type = 'group',
				name = 'General',
				guiInline = true,
				get = function(info) return BrokerLDBOptions[info[#info]] end,
				set = function(info, value) BrokerLDBOptions[info[#info]] = value BrokerLDB:Update() end,
				args = {
					Reset = {
						order = 0,
						name = 'Reset Settings',
						desc = CONFIRM_RESET_SETTINGS,
						confirm = true,
						type = 'execute',
						func = function() BrokerLDBOptions = CopyTable(Defaults) wipe(BrokerLDBBlacklist) end,
					},
					space = {
						type = 'description',
						name = '',
						order = 1,
					},
					space2 = {
						type = 'description',
						name = '',
						order = 2,
					},
					ShowIcon = {
						order = 3,
						type = 'toggle',
						name = 'Show Icon',
					},
					MouseOver = {
						order = 4,
						type = 'toggle',
						name = 'MouseOver',
					},
					ShowText = {
						order = 5,
						type = 'toggle',
						name = 'Show Text',
					},
					PanelHeight = {
						order = 6,
						type = 'range',
						width = 'full',
						name = 'Panel Height',
						min = 20, max = 40, step = 1,
					},
					PanelWidth = {
						order = 8,
						type = 'range',
						width = 'full',
						name = 'Panel Width',
						min = 0, softMin = 140, max = 280, step = 1,
					},
					Font = {
						type = 'select', dialogControl = 'LSM30_Font',
						order = 9,
						name = 'Font',
						values = AceGUIWidgetLSMlists.font,
					},
					FontSize = {
						order = 10,
						name = 'Font Size',
						type = 'range',
						min = 8, max = 22, step = 1,
					},
					FontFlag = {
						name = 'Font Flag',
						order = 11,
						type = 'select',
						values = {
							['NONE'] = 'None',
							['OUTLINE'] = 'OUTLINE',
							['MONOCHROME'] = 'MONOCHROME',
							['MONOCHROMEOUTLINE'] = 'MONOCROMEOUTLINE',
							['THICKOUTLINE'] = 'THICKOUTLINE',
						},
					},
				},
			},
		},
	}

	if EP then
		local Ace3OptionsPanel = IsAddOnLoaded("ElvUI") and ElvUI[1] or Enhanced_Config[1]
		Ace3OptionsPanel.Options.args.brokerldb = Options
	else
		local ACR, ACD = LibStub("AceConfigRegistry-3.0", true), LibStub("AceConfigDialog-3.0", true)
		if not (ACR or ACD) then return end
		ACR:RegisterOptionsTable("BrokerLDB", Options)
		ACD:AddToBlizOptions("BrokerLDB", "BrokerLDB", nil, "general")
	end
end

local BrokerLDBIgnore = {
	'Cork Tracking',
	'Cork Clams',
	'CorkLauncher',
	'Cork Archaeology digs',
	'Cork Repairs',
	'Cork Minipet',
	'Cork Guild Battle Standard',
	'Cork Glyphs',
	'Cork Lances and Poles',
	'Cork Darkmoon EXP Buff',
	'Cork Quest Starting Items',
	'Cork Well Fed',
	'Cork Blessing of Forgotten Kings',
	'Cork Shadowform',
	'Cork Talents',
	'Cork Inner Fire',
	'Cork Bloated innards',
	'Cork Power Word: Fortitude',
	'Cork Fear Ward',
	'Cork Crates',
	'Cork Combine',
	"Cork Alchemist's Flask",
	'Cork Chakra',
	'TradeSkillMasterMiniMapButton',
}

function BrokerLDB:AnimateSlide(frame, x, y, duration)
	frame.anim = frame:CreateAnimationGroup('Move_In')
	frame.anim.in1 = frame.anim:CreateAnimation('Translation')
	frame.anim.in1:SetDuration(0)
	frame.anim.in1:SetOrder(1)
	frame.anim.in2 = frame.anim:CreateAnimation('Translation')
	frame.anim.in2:SetDuration(duration)
	frame.anim.in2:SetOrder(2)
	frame.anim.in2:SetSmoothing('OUT')
	frame.anim.out1 = frame:CreateAnimationGroup('Move_Out')
	frame.anim.out2 = frame.anim.out1:CreateAnimation('Translation')
	frame.anim.out2:SetDuration(duration)
	frame.anim.out2:SetOrder(1)
	frame.anim.out2:SetSmoothing('IN')
	frame.anim.in1:SetOffset(x, y)
	frame.anim.in2:SetOffset(-x, -y)
	frame.anim.out2:SetOffset(x, y)
	frame.anim.out1:SetScript('OnFinished', function() frame:Hide() end)
end

function BrokerLDB:AnimSlideIn(frame)
	if not frame.anim then
		Animate(frame)
	end

	frame.anim.out1:Stop()
	frame:Show()
	frame.anim:Play()
end

function BrokerLDB:AnimSlideOut(frame)
	if frame.anim then
		frame.anim:Finish()
	end

	frame.anim:Stop()
	frame.anim.out1:Play()
end

function BrokerLDB:SlideOut()
	for _, Slides in pairs(self.Whitelist) do
		self:AnimSlideIn(Slides)
	end
	self:AnimSlideIn(self)
	self.Text:SetPoint('CENTER', self, -1, 0)
	self.Text:SetText('◄')
	self.Slide = 'Out'
end

function BrokerLDB:SlideIn()
	for _, Slides in pairs(self.Slides) do
		self:AnimSlideOut(Slides)
	end
	self:AnimSlideIn(self)
	self.Text:SetPoint('CENTER', self, 2, 0)
	self.Text:SetText('►')
	self.Slide = 'In'
end

function BrokerLDB:Update()
	LDB.RegisterCallback(self, 'LibDataBroker_DataObjectCreated', 'New')
	for Name, Object in LDB:DataObjectIterator() do
		self:New(nil, Name, Object)
	end

	for Key, Slide in pairs(self.Slides) do
		Slide.Text:SetFont(LSM:Fetch('font', BrokerLDBOptions['Font']), BrokerLDBOptions['FontSize'], BrokerLDBOptions['FontFlag'])
		if BrokerLDBOptions['ShowIcon'] and BrokerLDBOptions['ShowText'] then
			if BrokerLDBOptions['PanelWidth'] == 0 then BrokerLDBOptions['PanelWidth'] = 140 end
			Slide:SetSize(BrokerLDBOptions['PanelWidth'] + BrokerLDBOptions['PanelHeight'], BrokerLDBOptions['PanelHeight'])
			Slide.IconBackdrop:Show()
			Slide.IconBackdrop:SetPoint('RIGHT', Slide, 'RIGHT', -2, 0)
			Slide.IconBackdrop:Size(BrokerLDBOptions['PanelHeight'] - 4)
			Slide.Text:Show()
			Slide.Text:SetPoint('CENTER', -(BrokerLDBOptions['PanelHeight'] / 2), 0)
		elseif BrokerLDBOptions['ShowIcon'] then
			BrokerLDBOptions['PanelWidth'] = 0
			Slide:SetSize(BrokerLDBOptions['PanelHeight'], BrokerLDBOptions['PanelHeight'])
			Slide.IconBackdrop:Show()
			Slide.IconBackdrop:Size(BrokerLDBOptions['PanelHeight'])
			Slide.IconBackdrop:SetPoint('RIGHT', Slide, 'RIGHT', 0, 0)
			Slide.Text:Hide()
		elseif BrokerLDBOptions['ShowText'] then
			if BrokerLDBOptions['PanelWidth'] == 0 then BrokerLDBOptions['PanelWidth'] = 140 end
			Slide:SetSize(BrokerLDBOptions['PanelWidth'], BrokerLDBOptions['PanelHeight'])
			Slide.IconBackdrop:Hide()
			Slide.Text:Show()
			Slide.Text:SetPoint('CENTER', 0, 0)
		end
		if Slide.anim then
			local x = BrokerLDBOptions["PanelWidth"] + BrokerLDBOptions["PanelHeight"]
			Slide.anim.in1:SetOffset(-x, 0)
			Slide.anim.in2:SetOffset(x, 0)
			Slide.anim.out2:SetOffset(-x, 0)
		end
		for i, Blacklisted in pairs(BrokerLDBBlacklist) do
			if Slide:GetName() == Blacklisted then tremove(self.Whitelist, Key) Slide.Enabled = false return end
		end
	end

	local yOffSet = 0
	for Key, Slide in pairs(self.Whitelist) do
		Slide:SetPoint('TOPLEFT', self, 'TOPRIGHT', 1, yOffSet)
		yOffSet = yOffSet - BrokerLDBOptions['PanelHeight'] - 1
	end

	self:Height((BrokerLDBOptions['PanelHeight'] * #self.Whitelist) + (#self.Whitelist - 1))
	if (#self.Slides == 0 or #self.Whitelist == 0) then
		self:Hide()
	end

	if not BrokerLDBOptions['MouseOver'] then
		UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1)
	else
		UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0)
	end
end

function BrokerLDB:AddBlacklistFrame(frame)
	frame.Enabled = false
	local index
	for i, v in pairs(self.Whitelist) do
		if v == frame:GetName() then
			index = i
			break
		end
	end
	tremove(self.Whitelist, index)
	tinsert(BrokerLDBBlacklist, frame:GetName())
	self:SlideIn()
	self:Update()
end

function BrokerLDB:RemoveBlacklistFrame(frame)
	frame.Enabled = true
	local index
	for i, v in pairs(BrokerLDBBlacklist) do
		if v == frame:GetName() then
			index = i
			break
		end
	end
	tremove(BrokerLDBBlacklist, index)
	tinsert(self.Whitelist, frame)
	self:SlideIn()
	self:Update()
end

function BrokerLDB:New(Unused, Name, Object)
	if _G['BrokerLDB_'..Name] then return end
	for k, v in pairs(BrokerLDBIgnore) do
		if Name == v then return end
	end

	local Frame = CreateFrame('Frame', 'BrokerLDB_'..Name, self)
	Frame.pluginName = Name
	Frame.pluginObject = Object

	Frame:SetFrameStrata('BACKGROUND')
	Frame:SetFrameLevel(3)
	Frame:SetTemplate('Transparent')
	self:AnimateSlide(Frame, -150, 0, 1)
	Frame:SetHeight(BrokerLDBOptions['PanelHeight'])
	Frame:SetWidth(BrokerLDBOptions['PanelWidth'])
	Frame.Enabled = true
	tinsert(self.Slides, Frame)
	tinsert(self.Whitelist, Frame)

	Frame.Text = Frame:CreateFontString(nil, 'OVERLAY')
	Frame.Text:SetFont(LSM:Fetch('font', BrokerLDBOptions['Font']), BrokerLDBOptions['FontSize'], BrokerLDBOptions['FontFlag'])
	Frame.Text:SetPoint('CENTER', Frame)

	Frame.IconBackdrop = CreateFrame('Frame', nil, Frame)
	Frame.IconBackdrop:SetTemplate()

	Frame.Icon = Frame.IconBackdrop:CreateTexture(nil, 'ARTWORK')
	Frame.Icon:SetInside()
	Frame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	self.PluginObjects[Name] = Frame.Text

	self:TextUpdate(nil, Name, nil, Object.text or Object.label or Name)
	LDB.RegisterCallback(self, 'LibDataBroker_AttributeChanged_'..Name..'_text', 'TextUpdate')
	if Object.suffix then
		self:ValueUpdate(nil, Name, nil, Object.value or Name, Object)
		LDB.RegisterCallback(self, 'LibDataBroker_AttributeChanged_'..Name..'_value', 'ValueUpdate')
	end

	Frame:SetScript('OnEnter', function(self)
		if self.anim:IsPlaying() then return end
		local Object = self.pluginObject
		if Object.OnTooltipShow then
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT' , 2, -(BrokerLDBOptions.PanelHeight))
			GameTooltip:SetTemplate('Transparent')
			GameTooltip:ClearLines()	
			Object.OnTooltipShow(GameTooltip, self)
			GameTooltip:Show()
		elseif Object.OnEnter then
			GameTooltip:SetTemplate('Transparent')
			Object.OnEnter(self)
		end
	end)
	Frame:SetScript('OnLeave', function(self)
		GameTooltip:Hide()
		if self.pluginObject.OnLeave then
			self.pluginObject.OnLeave(self)
		end
	end)
	Frame:SetScript('OnMouseUp', function(self, btn)
		if self.anim:IsPlaying() then return end
		if self.pluginObject.OnClick then
			self.pluginObject.OnClick(self, btn)
		end
	end)
	Frame:SetScript('OnUpdate', function(self) self.Icon:SetTexture(Object.icon) end)
	tinsert(self.EasyMenu, { text = 'Show '..Name, checked = function() return Frame.Enabled end, func = function() if Frame.Enabled then self:AddBlacklistFrame(Frame) else self:RemoveBlacklistFrame(Frame) end self:Update() end } )

	if Object.OnCreate then Object.OnCreate(Object, Frame) end
end


BrokerLDB.Text = BrokerLDB:CreateFontString(nil, 'OVERLAY')
BrokerLDB.Text:SetFont(LSM:Fetch('font', 'Arial Narrow'), 12)
BrokerLDB.Text:SetPoint('CENTER', BrokerLDB, 0, 0)
BrokerLDB:SetFrameStrata('BACKGROUND')
BrokerLDB:SetWidth(15)
BrokerLDB:SetPoint('LEFT', UIParent, 'LEFT', 1, 0)
BrokerLDB:SetMovable(true)
BrokerLDB:SetClampedToScreen(true)
BrokerLDB:SetScript('OnDragStart', BrokerLDB.StartMoving)
BrokerLDB:SetScript('OnDragStop', BrokerLDB.StopMovingOrSizing)
BrokerLDB:RegisterForClicks('LeftButtonDown', 'RightButtonDown')
BrokerLDB:RegisterForDrag('LeftButton')
BrokerLDB:RegisterEvent('PLAYER_LOGIN')
BrokerLDB:AnimateSlide(BrokerLDB, -150, 0, 1)
BrokerLDB:SetScript('OnEvent', function(self, event, addon)
	EP = LibStub("LibElvUIPlugin-1.0", true)
	if self.SetTemplate then
		self:SetTemplate('Transparent')
	end
	if EP then
		EP:RegisterPlugin(AddOnName, self.GetOptions)
	else
		self:GetOptions()
	end
	self:Update()
	self:SlideIn()
	if BrokerLDB_Skada then BrokerLDB_Skada.Text:SetText('Skada') end
	if BrokerLDB_SavedInstances then
		BrokerLDB_SavedInstances.Text:SetText('SavedInstances')
		hooksecurefunc(SavedInstances, 'SkinFrame', function(self, frame, Name)
			if frame.SetTemplate then
				frame:SetTemplate('Transparent')
			end
		end)
	end
	print(format('%s by |cFFFF7D0AAzilroka|r - Version: |cff1784d1%s|r Loaded!', self.Title, self.Version))
	self:UnregisterEvent(event)
end)

BrokerLDB:SetScript('OnEnter', function(self)
	UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1)
end)

BrokerLDB:SetScript('OnLeave', function(self)
	if self.Slide == 'In' and BrokerLDBOptions['MouseOver'] then
		UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0)
	end
end)

BrokerLDB:SetScript('OnClick', function(self, btn)
	if self.anim:IsPlaying() then return end
	if btn == 'LeftButton' then
		if self.Slide == 'In' then
			self:SlideOut()
		else
			self:SlideIn()
		end
	else
		EasyMenu(self.EasyMenu, self.DropDown, 'cursor', 0, 0, 'MENU', 2)
	end
end)