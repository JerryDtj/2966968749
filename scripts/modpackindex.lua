local env = env
GLOBAL.setfenv(1, GLOBAL)

local function CollectSettings(config)
	local settings = {}
	for i,v in pairs(config) do
		table.insert(settings, {name = v.name, label = v.label, saved = v.saved,--[[options = v.options, default = v.default]]})
	end
	-- print(PrintTable(settings))
	return settings
end

KnownModIndex.modpacks = {}
	-- test_pack = { -- It goes a little something like this
	-- 	name = "Test pack", 
	-- 	description = "A test pack",
	-- 	author = "Niko",
	-- 	mods = {
	-- 		["workshop-829064383"] = {
	-- 			fancyname = "More players!",
	-- 			config = {
	-- 				default = 12,
	-- 				name = "server_size",
	-- 				label = "Maximum server size",
	-- 			},
	-- 		},
	-- 	},
	-- 	icon = "combinedstatus.tex",
	-- 	icon_atlas = "../mods/workshop-376333686/combinedstatus.xml",
	-- 	is_client = true,
	--  allowconfig = true
	-- },

KnownModIndex.ModpackCreate = function(self, name, fancyname, desc, author, icon, icon_atlas, is_client, moddata, allow_config)
	-- print(is_client, name, fancyname, desc, moddata, author, icon, icon_atlas)

	name = name or fancyname
	name = string.lower(name:gsub(" ", "_"))
	fancyname = fancyname or name
	assert(fancyname ~= nil, "ModpackCreate Error!!: name(#3) and fancyname(#4) can not both be nil!")
	if self.modpacks[name] ~= nil then print("ModpackCreate Warning!!: pack with name \""..name.."\" already exists!") return false end --Not a valid modpack
	if is_client == nil then
		is_client = true
	end
	if allow_config == nil then
		allow_config = true
	end
	if author == nil then
		author = TheNet:GetLocalUserName()
	end
	local missingmods = moddata == nil

	local packdata = {
		name = fancyname, -- If we got to this point fancyname shouldn't be nil
		description = desc or "",
		author = author, -- Fine as nil
		mods = moddata or {}, -- Maybe add a interpretor for various syntaxes for ease of use.
		allow_config = allow_config, -- Handled
		icon = icon, -- Find as nil
		icon_atlas = icon_atlas, -- Find as nil
		is_client = is_client, -- Handled
		version = tonumber(env.modinfo.version) -- No user control over this value is needed
	}

	self.modpacks[name] = packdata
	if missingmods then
		self:ModpackUpdate(name, is_client)
	end

	return self.modpacks[name]
end

KnownModIndex.ModpackDelete = function(self, packname)
	if self.modpacks[packname] == nil then return end --Not a valid modpack

	local data = self.modpacks[packname]
	self.modpacks[packname] = nil

	return data
end

KnownModIndex.ModpackEnable = function(self, packname)
	if self.modpacks[packname] == nil then return end --Not a valid modpack

	local newenabled = {}

	for modname, data in pairs(self.modpacks[packname].mods) do
		if not self:IsModEnabled(modname) then
			self:Enable(modname)
			newenabled[modname] = true
		else
			newenabled[modname] = false
		end
		if self.modpacks[packname].allow_config and data.config ~= nil and self:HasModConfigurationOptions(modname) then
			local settings = CollectSettings(data.config)
			KnownModIndex:SaveConfigurationOptions(function() end, modname, settings, self.modpacks[packname].is_client)
		end
	end

	return newenabled
end

KnownModIndex.ModpackDisable = function(self, packname)
	if self.modpacks[packname] == nil then return end --Not a valid modpack

	local newdisabled = {}

	for modname, config in pairs(self.modpacks[packname].mods) do
		if self:IsModEnabled(modname) then
			self:Disable(modname)
			newdisabled[modname] = true
		else
			newdisabled[modname] = false
		end
	end

	return newdisabled
end

KnownModIndex.ModpackEnableOnly = function(self, packname, is_client)
	if self.modpacks[packname] == nil then return end --Not a valid modpack

	local allmods = is_client and self:GetClientModNames() or self:GetServerModNames()
	for i, modname in pairs(allmods) do
		if self:IsModEnabled(modname) and modname ~= env.modname then -- Only disable enabled mods for optimisation and skip our own mod for user convinience
			self:Disable(modname)
		end
	end
	-- self:DisableAllMods()
	self:ModpackEnable(packname)
end

KnownModIndex.ModpackUpdate = function(self, packname, is_client) -- Replace modpack's data with currently selected mods and configs
	if self.modpacks[packname] == nil then return end --Not a valid modpack
	local allmods = is_client and self:GetClientModNames() or self:GetServerModNames()
	local mods = {}
	for i, modname in pairs(allmods) do
		if self:IsModEnabled(modname) then
			if modname ~= env.modname then -- Skip our mod so we don't disable the modpacks mod when disabling a modpack
				mods[modname] = {}
				mods[modname].config = {}
				mods[modname].fancyname = self:GetModFancyName(modname)
				if self:HasModConfigurationOptions(modname) then
					mods[modname].config = CollectSettings(self:GetModConfigurationOptions_Internal(modname))
				end
			end
		end
	end
	self.modpacks[packname].mods = mods
end

KnownModIndex.ModpackSetAllowConfig = function(self, packname, config)
	if self.modpacks[packname] == nil then return end --Not a valid modpack
	if config == nil then config = not self.modpacks[packname].allow_config end
	self.modpacks[packname].allow_config = config
	return self.modpacks[packname].allow_config
end

KnownModIndex.ModpackGetAllowConfig = function(self, packname)
	if self.modpacks[packname] == nil then return end --Not a valid modpack
	return self.modpacks[packname].allow_config
end

KnownModIndex.ModpackChangeImage = function(self, packname, icon_atlas, icon)
	if self.modpacks[packname] == nil then return end --Not a valid modpack
	if icon_atlas == nil or icon == nil then return end

	self.modpacks[packname].icon_atlas = icon_atlas
	self.modpacks[packname].icon = icon

	return true
end

KnownModIndex.IsModpackEnabled = function(self, packname)
	if self.modpacks[packname] == nil then return end --Not a valid modpack
	local has_disabled = false -- Only has disabled, disabled
	local has_enabled = false -- Only has enabled, enabled
	-- both, partially. neither, how!?
	local empty = true
	for modname, config in pairs(self.modpacks[packname].mods) do
		empty = false
		if self:IsModEnabled(modname) then
			has_enabled = true
		else
			has_disabled = true
		end
	end

	local extra = nil
	if empty then
		extra = "EMPTY"
	elseif has_disabled and has_enabled then
		extra = "PARTIAL"
	end
	return not has_disabled and has_enabled, extra -- Is enabled, extra details
end

KnownModIndex.IsClientModpack = function(self, packname)
	return self.modpacks[packname] and self.modpacks[packname].is_client
end

KnownModIndex.ModpackExists = function(self, packname)
	return self.modpacks[packname] ~= nil
end

KnownModIndex.GetModpackFancyName = function(self, packname)
	if self.modpacks[packname] == nil then return packname end --Not a valid modpack
	return self.modpacks[packname].name
end

KnownModIndex.GetModpackInfo = function(self, packname)
	if self.modpacks[packname] == nil then return end --Not a valid modpack
	return self.modpacks[packname]
end

KnownModIndex.GetModpacks = function(self)
	return self.modpacks
end

KnownModIndex.GetModpackNamesTable = function(self, is_client)
	local names = {}
	for name, data in pairs(self.modpacks) do
		if is_client == nil or is_client == data.is_client then
			table.insert(names, {modname = name})
		end
	end
	return names
end

local _Save = KnownModIndex.Save --Taken from MIM and tweaked for modpacks
KnownModIndex.Save = function(self, callback)
	local data = DataDumper({modpacks = self.modpacks}, nil, true)
	SavePersistentString("modpacks", data, ENCODE_SAVES)

	_Save(self, callback)
end

KnownModIndex.LoadModpacksFromFile = function(self) --Taken from MIM and tweaked for modpacks
	TheSim:GetPersistentString("modpacks", function(load_success, str)
		if load_success == true then
			local success, data = RunInSandboxSafe(str)
			if success and string.len(str) > 0 and data ~= nil then
				self.modpacks = data.modpacks
				print("loaded modpacks")
			else
				print("Warning!!: Could not load modpacks")
				if string.len(str) > 0 then
					print("  File str is ["..str.."]")
				end
			end
		else
			print("Warning!!: Could not load modpacks")
		end
	end)
end

KnownModIndex:LoadModpacksFromFile()

-- Not needed yet
-- KnownModIndex.ModpacksCheckForVersionDiff = function(self)
-- 	print("Checking for modpack updates...")
-- 	local modversion = tonumber(env.modinfo.version)
-- 	if modversion == nil then return end -- Bail, but this should never happen anyway.

-- 	local updatequeue = {}
-- 	local updatesneeded = false

-- 	for name, data in pairs(self.modpacks) do
-- 		local packversion = data.version
-- 		-- data.version = data.version or modversion
-- 		if packversion < modversion then
-- 			updatequeue[name] = packversion
-- 			updatesneeded = true
-- 		end
-- 	end
	
-- 	if updatesneeded then
-- 		print("Modpack updates needed, updating...")
-- 		for name, packversion in pairs(updatequeue) do
-- 			print("  Updating modpack \""..name.."\" from version "..packversion.." to "..modversion)
-- 			local updated = false
-- 			for i, upgrade in ipairs(ModpackVersionUpgrades) do
-- 				if upgrade.version > packversion then -- Skip any upgrade version below the modpack version
-- 					if upgrade.version > modversion then break end -- Bail if the upgrade is past current mod version
-- 					self.modpacks[name] = upgrade.fn(self.modpacks[name])
-- 					updated = true
-- 				end
-- 			end
-- 			if updated == true then
-- 				self.modpacks[name].version = modversion
-- 			else
-- 				print("  Failed to update modpack \""..name.."\", Upgrade for "..modversion.." does not exist")
-- 			end
-- 		end
-- 	else
-- 		print("All modpacks are up to date.")
-- 	end
-- end

-- KnownModIndex:ModpacksCheckForVersionDiff()