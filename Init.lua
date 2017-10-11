local ProjectAzilroka = LibStub('AceAddon-3.0'):NewAddon('ProjectAzilroka', 'AceEvent-3.0')
_G.ProjectAzilroka = ProjectAzilroka

-- Project Data
ProjectAzilroka.Title = GetAddOnMetadata('ProjectAzilroka', 'Title')
ProjectAzilroka.Version = GetAddOnMetadata('ProjectAzilroka', 'Version')
ProjectAzilroka.Authors = GetAddOnMetadata('ProjectAzilroka', 'Author'):gsub(", ", "    ")

-- Libraries
ProjectAzilroka.LSM = LibStub('LibSharedMedia-3.0')
ProjectAzilroka.LDB = LibStub('LibDataBroker-1.1')

-- WoW Data
ProjectAzilroka.MyClass = select(2, UnitClass('player'))
ProjectAzilroka.MyName = UnitName('player')
ProjectAzilroka.MyRealm = GetRealmName()
ProjectAzilroka.Noop = function() end
ProjectAzilroka.TexCoords = {.08, .92, .08, .92}
ProjectAzilroka.UIScale = UIParent:GetScale()

-- Pixel Perfect
ProjectAzilroka.ScreenWidth, ProjectAzilroka.ScreenHeight = GetPhysicalScreenSize()
ProjectAzilroka.Multiple = 768/ProjectAzilroka.ScreenHeight