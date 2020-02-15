local _, ns = ...

local pUF = ns.pUF
local Private = ns.pUF.Private

local argcheck = Private.argcheck
local error = Private.error
local petExists = Private.petExists

local elements = {}
local activeElements = {}
pUF.elements = elements
_G.pUF = pUF

local frame_metatable = {
	__index = CreateFrame("Button")
}
Private.frame_metatable = frame_metatable

local NT = LibStub("LibNihilistUITags-1.0")

for k, v in next, {
	--[[ frame:EnableElement(name, unit)
	Used to activate an element for the given unit frame.

	* self - unit frame for which the element should be enabled
	* name - name of the element to be enabled (string)
	* unit - unit to be passed to the element's Enable function. Defaults to the frame's unit (string?)
	--]]
	EnableElement = function(self, name, petOwner, petIndex)
		argcheck(name, 2, "string")
		argcheck(petOwner, 3, "number")
		argcheck(petIndex, 4, "number")

		local element = elements[name]
		if (not element or self:IsElementEnabled(name)) then
			return
		end

		if not petOwner then
			petOwner, petIndex = unpack(self.petInfo)
		end

		if (element.enable(self, petOwner, petIndex)) then
			activeElements[self][name] = true

			if (element.update) then
				table.insert(self.__elements, element.update)
			end
		end
	end,
	--[[ frame:DisableElement(name)
	Used to deactivate an element for the given unit frame.

	* self - unit frame for which the element should be disabled
	* name - name of the element to be disabled (string)
	--]]
	DisableElement = function(self, name)
		argcheck(name, 2, "string")

		local enabled = self:IsElementEnabled(name)
		if (not enabled) then
			return
		end

		local update = elements[name].update
		for k, func in next, self.__elements do
			if (func == update) then
				table.remove(self.__elements, k)
				break
			end
		end

		activeElements[self][name] = nil

		return elements[name].disable(self)
	end,
	--[[ frame:IsElementEnabled(name)
	Used to check if an element is enabled on the given frame.

	* self - unit frame
	* name - name of the element (string)
	--]]
	IsElementEnabled = function(self, name)
		argcheck(name, 2, "string")

		local element = elements[name]
		if (not element) then
			return
		end

		local active = activeElements[self]
		return active and active[name]
	end,
	Enable = function(self)
		self:Show()
	end,
	Disable = function(self)
		self:Hide()
	end,
	Tag = function(self, key, fs)
		fs.petInfo = self.petInfo
		NT:RegisterFontString(key, fs)
	end,
	UpdateAllElements = function(self, event)
		local petOwner, petIndex = unpack(self.petInfo)
		if (not petExists(petOwner, petIndex)) then
			return
		end

		assert(type(event) == "string", "Invalid argument 'event' in UpdateAllElements.")

		if (self.PreUpdate) then
			--[[ Callback: frame:PreUpdate(event)
			Fired before the frame is updated.

			* self  - the unit frame
			* event - the event triggering the update (string)
			--]]
			self:PreUpdate(event)
		end

		for _, func in next, self.__elements do
			func(self, event, petOwner, petIndex)
		end

		if (self.PostUpdate) then
			--[[ Callback: frame:PostUpdate(event)
			Fired after the frame is updated.

			* self  - the unit frame
			* event - the event triggering the update (string)
			--]]
			self:PostUpdate(event)
		end
	end
} do
	frame_metatable.__index[k] = v
end

local objects = {}
pUF.objects = objects

local styles = {}
local style

local function initObject(petOwner, petIndex, style, styleFunc)
	local object = {}
	local objectPetInfo = {petOwner, petIndex}

	object.__elements = {}
	object.style = style
	object = setmetatable(object, frame_metatable)
	object.petInfo = objectPetInfo

	tinsert(objects, object)

	local enable = function()
		object:Enable()
	end
	local disable = function()
		object:Disable()
	end

	activeElements[object] = {}

	styleFunc(object, petOwner, petIndex)

	for element in next, elements do
		object:EnableElement(element, petOwner, petIndex)
	end

	object:RegisterEvent("PET_BATTLE_OPENING_START", enable)
	object:RegisterEvent("PET_BATTLE_CLOSE", disable)
end

function pUF:RegisterStyle(name, func)
	argcheck(name, 2, "string")
	argcheck(func, 3, "function", "table")

	if (styles[name]) then
		return error("Style [%s] already registered.", name)
	end
	if (not style) then
		style = name
	end

	styles[name] = func
end

function pUF:SetActiveStyle(name)
	argcheck(name, 2, "string")
	if (not styles[name]) then
		return error("Style [%s] does not exist.", name)
	end

	style = name
end

local function walkObject(object, petOwner, petIndex)
	local parent = object:GetParent()
	local style = parent.style or style
	local styleFunc = styles[style]

	return initObject(petOwner, petIndex, style, styleFunc)
end

local function generateName(petOwner, petIndex)
	return "battlepetO" .. petOwner .. "I" .. petIndex
end

function pUF:Spawn(petOwner, petIndex, overrideName)
	argcheck(petOwner, 2, "number")
	argcheck(petIndex, 3, "number")
	if (not style) then
		return error("Unable to create frame. No styles have been registered.")
	end

	local name = overrideName or generateName(petOwner, petIndex)
	local object = CreateFrame("Button", name, UIParent)

	walkObject(object, petOwner, petIndex)

	return object
end

function pUF:AddElement(name, update, enable, disable, override) -- ElvUI Changed added override
	argcheck(name, 2, "string")
	argcheck(update, 3, "function", "nil")
	argcheck(enable, 4, "function", "nil")
	argcheck(disable, 5, "function", "nil")

	if not override then
		if (elements[name]) then
			return error("Element [%s] is already registered.", name)
		end
	end

	elements[name] = {
		update = update,
		enable = enable,
		disable = disable
	}
end
