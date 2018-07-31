local PA = _G.ProjectAzilroka
local BrokerLDB = PA:NewModule('BrokerLDB', 'AceEvent-3.0')
PA.BrokerLDB, _G.BrokerLDB = BrokerLDB, BrokerLDB

local _G = _G
local pairs, tinsert, tremove, select, unpack = pairs, tinsert, tremove, select, unpack
local strfind, strsub, strmatch = strfind, strsub, strmatch

BrokerLDB.Title = '|cFF16C3F2Broker|r|cFFFFFFFFLDB|r'
BrokerLDB.Description = 'Provides an overlay on UnitFrames for Boss, Elite, Rare and RareElite'
BrokerLDB.Authors = 'Azilroka    Whiro'

function BrokerLDB:TextUpdate(_, Name, _, Data)
	self.PluginObjects[Name]:SetText(Data)
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
			header = {
				order = 1,
				type = 'header',
				name = BrokerLDB['Title'],
			},
			general = {
				order = 2,
				type = 'group',
				name = PA.ACL['General'],
				guiInline = true,
				get = function(info) return BrokerLDB.db[info[#info]] end,
				set = function(info, value) BrokerLDB.db[info[#info]] = value BrokerLDB:Update() end,
				args = {
					ShowIcon = {
						order = 3,
						type = 'toggle',
						name = PA.ACL['Show Icon'],
					},
					MouseOver = {
						order = 4,
						type = 'toggle',
						name = PA.ACL['MouseOver'],
					},
					ShowText = {
						order = 5,
						type = 'toggle',
						name = PA.ACL['Show Text'],
					},
					PanelHeight = {
						order = 6,
						type = 'range',
						width = 'full',
						name = PA.ACL['Panel Height'],
						min = 20, max = 40, step = 1,
					},
					PanelWidth = {
						order = 8,
						type = 'range',
						width = 'full',
						name = PA.ACL['Panel Width'],
						min = 0, softMin = 140, max = 280, step = 1,
					},
					Font = {
						type = 'select', dialogControl = 'LSM30_Font',
						order = 9,
						name = PA.ACL['Font'],
						values = PA.LSM:HashTable('font'),
					},
					FontSize = {
						order = 10,
						name = FONT_SIZE,
						type = 'range',
						min = 8, max = 22, step = 1,
					},
					FontFlag = {
						name = PA.ACL['Font Outline'],
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

	Options.args.profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(BrokerLDB.data)
	Options.args.profiles.order = -2

	PA.Options.args.BrokerLDB = Options
end

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
	frame.anim.out1:Stop()
	frame:Show()
	frame.anim:Play()
end

function BrokerLDB:AnimSlideOut(frame)
	frame.anim:Finish()
	frame.anim:Stop()
	frame.anim.out1:Play()
end

function BrokerLDB:SlideOut()
	for _, Slides in pairs(self.Whitelist) do
		self:AnimSlideIn(Slides)
	end
	self:AnimSlideIn(self.Frame)
	self.Frame.Text:SetPoint('CENTER', self.Frame, -1, 0)
	self.Frame.Text:SetText('◄')
	self.Slide = 'Out'
end

function BrokerLDB:SlideIn()
	for _, Slides in pairs(self.Buttons) do
		Slides:Hide()
	end
	self.Frame.Text:SetPoint('CENTER', self.Frame, 2, 0)
	self.Frame.Text:SetText('►')
	self.Slide = 'In'
end

function BrokerLDB:Update()
	for Name, Object in PA.LDB:DataObjectIterator() do
		self:New(nil, Name, Object)
	end

	for Key, Slide in pairs(self.Buttons) do
		Slide.Text:SetFont(PA.LSM:Fetch('font', BrokerLDB.db['Font']), BrokerLDB.db['FontSize'], BrokerLDB.db['FontFlag'])
		if BrokerLDB.db['ShowIcon'] and BrokerLDB.db['ShowText'] then
			if BrokerLDB.db['PanelWidth'] == 0 then BrokerLDB.db['PanelWidth'] = 140 end
			Slide:SetSize(BrokerLDB.db['PanelWidth'] + BrokerLDB.db['PanelHeight'], BrokerLDB.db['PanelHeight'])
			Slide.IconBackdrop:Show()
			Slide.IconBackdrop:SetPoint('RIGHT', Slide, 'RIGHT', -2, 0)
			Slide.IconBackdrop:Size(BrokerLDB.db['PanelHeight'] - 4)
			Slide.Text:Show()
			Slide.Text:SetPoint('CENTER', -(BrokerLDB.db['PanelHeight'] / 2), 0)
		elseif BrokerLDB.db['ShowIcon'] then
			BrokerLDB.db['PanelWidth'] = 0
			Slide:SetSize(BrokerLDB.db['PanelHeight'], BrokerLDB.db['PanelHeight'])
			Slide.IconBackdrop:Show()
			Slide.IconBackdrop:Size(BrokerLDB.db['PanelHeight'])
			Slide.IconBackdrop:SetPoint('RIGHT', Slide, 'RIGHT', 0, 0)
			Slide.Text:Hide()
		elseif BrokerLDB.db['ShowText'] then
			if BrokerLDB.db['PanelWidth'] == 0 then BrokerLDB.db['PanelWidth'] = 140 end
			Slide:SetSize(BrokerLDB.db['PanelWidth'], BrokerLDB.db['PanelHeight'])
			Slide.IconBackdrop:Hide()
			Slide.Text:Show()
			Slide.Text:SetPoint('CENTER', 0, 0)
		end
		if Slide.anim then
			local x = BrokerLDB.db["PanelWidth"] + BrokerLDB.db["PanelHeight"]
			Slide.anim.in1:SetOffset(-x, 0)
			Slide.anim.in2:SetOffset(x, 0)
			Slide.anim.out2:SetOffset(-x, 0)
		end
		for _, Blacklisted in pairs(self.Blacklist) do
			if Slide:GetName() == Blacklisted then tremove(self.Whitelist, Key) Slide.Enabled = false return end
		end
	end

	local yOffSet = 0
	for _, Slide in pairs(self.Whitelist) do
		Slide:SetPoint('TOPLEFT', self.Frame, 'TOPRIGHT', 1, yOffSet)
		yOffSet = yOffSet - BrokerLDB.db['PanelHeight'] - 1
	end

	self.Frame:Height((BrokerLDB.db['PanelHeight'] * #self.Whitelist) + (#self.Whitelist - 1))
	if (#self.Buttons == 0 or #self.Whitelist == 0) then
		self.Frame:Hide()
	end

	if not BrokerLDB.db['MouseOver'] then
		UIFrameFadeIn(self.Frame, 0.2, self.Frame:GetAlpha(), 1)
	else
		UIFrameFadeOut(self.Frame, 0.2, self.Frame:GetAlpha(), 0)
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
	tinsert(self.Blacklist, frame:GetName())
	self:SlideIn()
	self:Update()
end

function BrokerLDB:RemoveBlacklistFrame(frame)
	frame.Enabled = true
	local index
	for i, v in pairs(self.Blacklist) do
		if v == frame:GetName() then
			index = i
			break
		end
	end
	tremove(self.Blacklist, index)
	tinsert(self.Whitelist, frame)
	self:SlideIn()
	self:Update()
end

function BrokerLDB:New(_, Name, Object)
	if _G['BrokerLDB_'..Name] then return end
	for _, v in pairs(self.Ignore) do
		if Name == v then return end
	end

	local Frame = CreateFrame('Frame', 'BrokerLDB_'..Name, self.Frame)
	Frame:Hide()
	Frame.pluginName = Name
	Frame.pluginObject = Object

	Frame:SetFrameStrata('BACKGROUND')
	Frame:SetFrameLevel(3)
	Frame:SetTemplate('Transparent')
	self:AnimateSlide(Frame, -150, 0, 1)
	Frame:SetHeight(BrokerLDB.db['PanelHeight'])
	Frame:SetWidth(BrokerLDB.db['PanelWidth'])
	Frame.Enabled = true
	tinsert(self.Buttons, Frame)
	tinsert(self.Whitelist, Frame)

	Frame.Text = Frame:CreateFontString(nil, 'OVERLAY')
	Frame.Text:SetFont(PA.LSM:Fetch('font', BrokerLDB.db['Font']), BrokerLDB.db['FontSize'], BrokerLDB.db['FontFlag'])
	Frame.Text:SetPoint('CENTER', Frame)

	Frame.IconBackdrop = CreateFrame('Frame', nil, Frame)
	Frame.IconBackdrop:SetTemplate()

	Frame.Icon = Frame.IconBackdrop:CreateTexture(nil, 'ARTWORK')
	Frame.Icon:SetInside()
	Frame.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	self.PluginObjects[Name] = Frame.Text

	self:TextUpdate(nil, Name, nil, Object.text or Object.label or Name)
	PA.LDB.RegisterCallback(self, 'LibDataBroker_AttributeChanged_'..Name..'_text', 'TextUpdate')
	if Object.suffix then
		self:ValueUpdate(nil, Name, nil, Object.value or Name, Object)
		PA.LDB.RegisterCallback(self, 'LibDataBroker_AttributeChanged_'..Name..'_value', 'ValueUpdate')
	end

	Frame:SetScript('OnEnter', function(self)
		if self.anim:IsPlaying() then return end
		if self.pluginObject.OnTooltipShow then
			GameTooltip:SetOwner(self, 'ANCHOR_RIGHT' , 2, -(BrokerLDB.db['PanelHeight']))
			GameTooltip:SetTemplate('Transparent')
			GameTooltip:ClearLines()
			self.pluginObject.OnTooltipShow(GameTooltip, self)
			GameTooltip:Show()
		elseif self.pluginObject.OnEnter then
			GameTooltip:SetTemplate('Transparent')
			self.pluginObject.OnEnter(self)
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

function BrokerLDB:BuildProfile()
	self.data = PA.ADB:New('SquareMinimapButtonsDB', {
		profile = {
			['PanelHeight'] = 20,
			['PanelWidth'] = 140,
			['MouseOver'] = false,
			['ShowIcon'] = false,
			['ShowText'] = true,
			['Font'] = 'Tukui Pixel',
			['FontSize'] = 12,
			['FontFlag'] = 'MONOCHROMEOUTLINE',
		},
	})
	self.data.RegisterCallback(self, 'OnProfileChanged', 'SetupProfile')
	self.data.RegisterCallback(self, 'OnProfileCopied', 'SetupProfile')
	self.db = self.data.profile
end

function BrokerLDB:SetupProfile()
	self.db = self.data.profile
end

function BrokerLDB:Initialize()
	BrokerLDB:BuildProfile()
	BrokerLDB:GetOptions()

	BrokerLDB.DropDown = CreateFrame('Frame', 'BrokerLDBDropDown', UIParent, 'UIDropDownMenuTemplate')
	BrokerLDB.Slide = 'In'
	BrokerLDB.EasyMenu = {}

	BrokerLDB.Buttons = {}
	BrokerLDB.PluginObjects = {}

	BrokerLDB.Ignore = {
		'Cork',
	}

	BrokerLDB.Whitelist = {}
	BrokerLDB.Blacklist = {}
	PA.LDB.RegisterCallback(BrokerLDB, 'LibDataBroker_DataObjectCreated', 'New')

	local Frame = CreateFrame('Button', nil, UIParent)
	Frame.Text = Frame:CreateFontString(nil, 'OVERLAY')
	Frame.Text:SetFont(PA.LSM:Fetch('font', 'Arial Narrow'), 12)
	Frame.Text:SetPoint('CENTER', Frame, 0, 0)
	Frame:SetFrameStrata('BACKGROUND')
	Frame:SetWidth(15)
	Frame:SetPoint('LEFT', UIParent, 'LEFT', 1, 0)
	Frame:RegisterForClicks('LeftButtonDown', 'RightButtonDown')
	Frame:SetTemplate('Transparent')
	BrokerLDB:AnimateSlide(Frame, -150, 0, 1)

	Frame:SetScript('OnEnter', function(self) UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1) end)
	Frame:SetScript('OnLeave', function(self)
		if self.Slide == 'In' and BrokerLDB.db['MouseOver'] then
			UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0)
		end
	end)

	Frame:SetScript('OnClick', function(self, btn)
		if self.anim:IsPlaying() then return end
		if btn == 'LeftButton' then
			if BrokerLDB.Slide == 'In' then
				BrokerLDB:SlideOut()
			else
				BrokerLDB:SlideIn()
			end
		else
			EasyMenu(BrokerLDB.EasyMenu, BrokerLDB.DropDown, 'cursor', 0, 0, 'MENU', 2)
		end
	end)

	BrokerLDB.Frame = Frame

	BrokerLDB:Update()
	BrokerLDB:SlideIn()
end