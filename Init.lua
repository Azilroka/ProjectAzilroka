local AddOnName, PA = ...
PA[1] = LibStub('AceAddon-3.0'):NewAddon('ProjectAzilroka', 'AceEvent-3.0')
_G.ProjectAzilroka = PA

-- Libraries
PA.LSM = LibStub('LibSharedMedia-3.0')
PA.LDB = LibStub('LibDataBroker-1.1')
PA.LAB = LibStub('LibActionButton-1.0')
PA.ACR = LibStub('AceConfigRegistry-3.0')
PA.ACD = LibStub('AceConfigDialog-3.0')
PA.EP = LibStub('LibElvUIPlugin-1.0', true)

-- WoW Data
PA.MyClass = select(2, UnitClass('player'))
PA.MyName = UnitName('player')
PA.MyRealm = GetRealmName()
PA.Noop = function() end
PA.TexCoords = {.08, .92, .08, .92}
PA.UIScale = UIParent:GetScale()

-- Pixel Perfect
PA.ScreenWidth, PA.ScreenHeight = GetPhysicalScreenSize()
PA.Multiple = 768/PA.ScreenHeight

-- Project Data
PA.Title = GetAddOnMetadata('ProjectAzilroka', 'Title')
PA.Version = GetAddOnMetadata('ProjectAzilroka', 'Version')
PA.Authors = GetAddOnMetadata('ProjectAzilroka', 'Author'):gsub(", ", "    ")

PA.ElvUI = GetAddOnEnableState(PA.MyName, 'ElvUI') > 0
PA.Tukui = GetAddOnEnableState(PA.MyName, 'Tukui') > 0
PA.AceOptionsPanel = PA.ElvUI and ElvUI[1] or Enhanced_Config[1]