local MAJOR_VERSION = "LibNihilistUITags-1.0"
local MINOR_VERSION = 1

if not _G.LibStub then
	error(MAJOR_VERSION .. " requires LibStub")
end

local NihilistLib = _G.LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not NihilistLib then
	return
end

local strsplit = _G.strsplit
local CreateFrame = _G.CreateFrame

NihilistLib.registeredTags = {}
NihilistLib.registeredEvents = {}
NihilistLib.registeredTagStrings = {}

local mouseoverSeen = {}
local E
local function NTags_OnEnter(self)
	if not E then
		E = _G.ElvUI[1]
	end
	if (mouseoverSeen[self]) then
		E:UIFrameFadeIn(self, 0.2, 0, 1)
	end
end

local function NTags_OnLeave(self)
	if not E then
		E = _G.ElvUI[1]
	end
	if (mouseoverSeen[self]) then
		E:UIFrameFadeOut(self, 0.2, 1, 0)
	end
end

function NihilistLib:RegisterTag(tag, evaluationFunc, events)
	if not events then
		events = ""
	end

	local _events = {strsplit(" ", events)}

	self.registeredTags[tag] = {evaluationFunc = evaluationFunc, events = _events}
	for _, event in ipairs(_events) do
		if (event ~= "") then
			if (not self.registeredEvents[event]) then
				self.driverFrame:RegisterEvent(event)
				self.registeredEvents[event] = 0
			end
			self.registeredEvents[event] = self.registeredEvents[event] + 1
		end
	end
end

function NihilistLib:UnregisterTag(tag)
	if (not self.registeredTags[tag]) then
		return
	end
	local events = self.registeredTags[tag].events
	for _, event in ipairs(events) do
		self.registeredEvents[event] = self.registeredEvents[event] - 1
		if (self.registeredEvents[event] == 0) then
			self.driverFrame:UnregisterEvent(event)
			self.registeredEvents[event] = nil
		end
	end
	self.registeredTags[tag] = nil
end

function NihilistLib:RegisterFontString(key, fs)
	if (not self.registeredTagStrings[key]) then
		self.registeredTagStrings[key] = {}
	end
	self.registeredTagStrings[key].fs = fs
	self.registeredTagStrings[key].backingText = ""
	local frame = fs:GetParent()
	frame:HookScript(
		"OnEnter",
		function()
			if (not NihilistLib.registeredTagStrings[key]) then
				return
			end
			NTags_OnEnter(fs)
		end
	)
	frame:HookScript(
		"OnLeave",
		function()
			if (not NihilistLib.registeredTagStrings[key]) then
				return
			end
			NTags_OnLeave(fs)
		end
	)
	-- We own this fs, so only we should change the text
	fs.blzSetText = fs.SetText
	fs.SetText = function()
	end
end

function NihilistLib:UnregisterFontString(key)
	if (not self.registeredTagStrings[key]) then
		return
	end
	local fs = self.registeredTagStrings[key].fs
	fs.SetText = fs.blzSetText
	fs.blzSetText = nil
	self.registeredTagStrings[key] = nil
end

function NihilistLib:Tag(key, tagStr)
	if (not self.registeredTagStrings[key]) then
		return
	end
	self.registeredTagStrings[key].backingText = tagStr
	NihilistLib:UpdateTagStrings()
end

NihilistLib.driverFrame = CreateFrame("Frame")
NihilistLib.driverFrame:SetScript(
	"OnEvent",
	function()
		NihilistLib:UpdateTagStrings()
	end
)

local CurrentFS, CurrentKey
NihilistLib.tagDirector = {}
setmetatable(
	NihilistLib.tagDirector,
	{
		__index = function(_, key)
			if (NihilistLib.registeredTags[key]) then
				local res = NihilistLib.registeredTags[key].evaluationFunc(CurrentFS)
				if (res) then
					NihilistLib.registeredTags[key].cachedResult = res
					return res
				end
				return NihilistLib.registeredTags[key].cachedResult
			end
			return nil
		end
	}
)

NihilistLib:RegisterTag(
	"mouseover",
	function()
		local key = CurrentKey
		mouseoverSeen[key] = true
		return ""
	end
)

function NihilistLib:UpdateTagStrings()
	for k, v in pairs(self.registeredTagStrings) do
		CurrentKey = k
		CurrentFS = v.fs
		mouseoverSeen[k] = false
		v.fs:blzSetText(v.backingText:gsub("%[([^%]]+)%]", self.tagDirector))
		if (mouseoverSeen[k]) then
			if (not v.fs:IsMouseOver()) then
				NTags_OnLeave(v.fs)
			else
				NTags_OnEnter(v.fs)
			end
		end
	end
end

function NihilistLib:UpdateTagString(key)
	local _t = self.registeredTagStrings[key]
	CurrentKey = key
	CurrentFS = _t.fs
	mouseoverSeen[key] = false
	_t.fs:blzSetText(_t.backingText:gsub("%[([^%]]+)%]", self.tagDirector))
	if (mouseoverSeen[key]) then
		if (not _t.fs:IsMouseOver()) then
			NTags_OnLeave(_t.fs)
		else
			NTags_OnEnter(_t.fs)
		end
	end
end
