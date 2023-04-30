local env = env
GLOBAL.setfenv(1, GLOBAL) -- Moves us from modding env to global env, keeping the mod env handy in case we need it.

local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local PopupDialogScreen = require "screens/redux/popupdialog"
local TEMPLATES = require "widgets/redux/templates"
local Menu = require "widgets/menu"
local TextListPopup = require "screens/redux/textlistpopup"
local NameModpackScreen = require "screens/namemodpackscreen"
local ModpackImageSelect = require "screens/modpackimageselect"

-------------------------------------------------------------------------- --Taken from modstab.lua and modified slightly
local alpasortcache = {} 
local function alphasort(moda, modb)
    if not moda then return false end
    if not modb then return true end

    local moda_sort = alpasortcache[moda.modname]
    local modb_sort = alpasortcache[modb.modname]
    if not moda_sort then
        local fancy = KnownModIndex:GetModpackFancyName(moda.modname)
		-- local mods = KnownModIndex:GetModpackInfo(moda.modname).mods
		-- local fancymods = ""
		-- for mod, data in pairs(mods) do
		-- 	if data ~= nil and data.fancyname ~= nil then
		-- 		fancymods = fancymods..data.fancyname
		-- 	end
		-- end
        moda_sort = {
            -- fav = Profile:IsModFavorited(moda.modname),
            name = string.lower(fancy):gsub('%W','')..fancy
        }
        alpasortcache[moda.modname] = moda_sort
    end
    if not modb_sort then
        local fancy = KnownModIndex:GetModpackFancyName(modb.modname)
		-- local mods = KnownModIndex:GetModpackInfo(modb.modname).mods
		-- local fancymods = ""
		-- for mod, data in pairs(mods) do
		-- 	if data ~= nil and data.fancyname ~= nil then
		-- 		fancymods = fancymods..data.fancyname
		-- 	end
		-- end
        modb_sort = {
            -- fav = Profile:IsModFavorited(modb.modname),
            name = string.lower(fancy):gsub('%W','')..fancy
        }
        alpasortcache[modb.modname] = modb_sort
    end

    -- if moda_sort.fav ~= modb_sort.fav then
    --     return moda_sort.fav
    -- end
    return moda_sort.name < modb_sort.name
end

local function CompareModnamesTable( t1, t2 )
    if #t1 ~= #t2 then
        return false
    end
    for i = 1, #t1 do
        if t1[i].modname ~= t2[i].modname then
            return false
        end
    end
    return true
end
--------------------------------------------------------------------------


env.AddClassPostConstruct("widgets/redux/modfilterbar", function(self)
	local function statusfilter(modname)
		if self.modstab.subscreener.active_key == "modpacks" then
			return KnownModIndex:IsModpackEnabled(modname)
		elseif self.modstab.subscreener.active_key == "mimmods" then -- Needs to be fixed on their end, for now this will do nothing.
			return KnownModIndex:IsMiMEnabled(modname)
		else
			return KnownModIndex:IsModEnabled(modname)
		end
	end
	local function newenabled(modname) return statusfilter(modname) end
	local function newdisabled(modname) return not statusfilter(modname) end
	local _AddModStatusFilter = self.AddModStatusFilter
	self.AddModStatusFilter = function(self, text_fmt, enabled_tex, disabled_tex, both_tex, id, enabledfilterfn, disabledfilterfn)
		return _AddModStatusFilter(self, text_fmt, enabled_tex, disabled_tex, both_tex, id, newenabled, newdisabled)
	end
end)

local function ModsTabPostInit(self)
	self.clientmodpacknames = {}
	self.servermodpacknames = {}


	-- Page setup
	local label = STRINGS.NAMES.TAB_LABEL
	local tooltip = STRINGS.NAMES.TAB_LABEL_DESC
	local button = self.subscreener:MenuButton(label, "modpacks", tooltip, self.tooltip)
	self.subscreener.menu:AddCustomItem(button)
	self.subscreener.sub_screens.modpacks = self.mods_page

	if self.settings.is_configuring_server then
		self.subscreener.buttons.modpacks.image:SetSize(3, 3)
		self.subscreener.menu:SetPosition(-444, 130) -- Normal is: Client(-445, -130, 0) Server(-444, 170, 0)
		
		for _, widget in pairs(self.subscreener.buttons.modpacks:GetChildren()) do -- There has got to be an easier, less hacky way to do this
			if widget.name == "Image" then -- Is either the selector or the hover texture
				if widget.atlas == "images/ui.xml" then -- Selector
					widget:SetScale(50, 20, 1)
					widget:SetPosition(-60, 0)
				else -- Hover texture
					widget:SetScale(0.35, 0.6, 0.6)
					widget:SetPosition(-65, 0)
				end
			end
		end
	end
		

	-- self.modpackoptionwidgets_client = OptionWidget()
	-- self.modpackoptionwidgets_server = OptionWidget()
	self.modpackoptionwidgets_client = {}
	self.modpackoptionwidgets_server = {}


	-- Widget buttons
	self.ModpackEnableOnly = function(self, widget_idx)
		local items_table = self.settings.is_configuring_server and self.modpackoptionwidgets_server or self.modpackoptionwidgets_client
		local idx = items_table[widget_idx].index
		local modname = self.settings.is_configuring_server and self.servermodpacknames[idx].modname or self.clientmodpacknames[idx].modname
		local fancyname = KnownModIndex:GetModpackFancyName(modname)
		TheFrontEnd:PushScreen(PopupDialogScreen(
			STRINGS.NAMES.DISABLE_MOD_PACK..fancyname.."?", STRINGS.NAMES.DISABLE_MOD_PACK_CONTENT, 
			{
				{text=STRINGS.NAMES.CONFRIM_BUTTON, cb = function() 
					KnownModIndex:ModpackEnableOnly(modname, not self.settings.is_configuring_server) 
					self.mods_scroll_list:RefreshView() 
					if self.servercreationscreen.DirtyFromMods then
						self.servercreationscreen:DirtyFromMods(self.slotnum)
					end
					TheFrontEnd:PopScreen() 
				end},
				{text=STRINGS.UI.MODSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() end}
			}
		))
	end
	self.ModpackToggleConfig = function(self, widget_idx)
		local items_table = self.settings.is_configuring_server and self.modpackoptionwidgets_server or self.modpackoptionwidgets_client
		local idx = items_table[widget_idx].index
		local modname = self.settings.is_configuring_server and self.servermodpacknames[idx].modname or self.clientmodpacknames[idx].modname
		local suc KnownModIndex:ModpackSetAllowConfig(modname)
		self.mods_scroll_list:RefreshView()
		return suc
	end
	


	-- Mod list setup
	local SetModsList = self._SetModsList
	self._SetModsList = function(self, listtype, forcescroll)
		------------------------------------------------------------------------------------
		local scroll_to = forcescroll or self.currentmodtype ~= listtype
		local function ShowLastClickedDetails(last_modname, modnames_list)
			local idx = #modnames_list > 0 and 1 or nil
			for i,v in metaipairs(modnames_list) do
				if last_modname == v.mod.modname then
					idx = i
					break
				end
			end
			local is_client = modnames_list == self.optionwidgets_client or modnames_list == self.modpackoptionwidgets_client
			self:ShowModDetails(idx, is_client)
	
			if scroll_to and idx then
				-- On switching tabs, scroll the window to the selected item. (Can't do
				-- on ShowModDetails since it would snap on each click.)
				self.mods_scroll_list:ScrollToDataIndex(idx)
			end
		end
		------------------------------------------------------------------------------------

		if not self.needstorefresh then
			if self.lastlisttype ~= listtype then
				if listtype == "modpacks" or self.lastlisttype == "modpacks" then
					self.needstorefresh = true
					self:RefreshModFilter(self.modfilterbar:_ConstructFilter())
					self:DoFocusHookups()
				end
			end
		else
			self.needstorefresh = false
		end

		if not self.needstorefresh then
			-- local _ScrollToDataIndex = self.mods_scroll_list.ScrollToDataIndex
			-- self.mods_scroll_list.ScrollToDataIndex = function() end --Sigh...
			--
			SetModsList(self, listtype, false)
			--
			-- self.mods_scroll_list.ScrollToDataIndex = _ScrollToDataIndex
			if listtype == "modpacks" then
				local modpackoptionwidgets = self.settings.is_configuring_server and self.modpackoptionwidgets_server or self.modpackoptionwidgets_client
				self.mods_scroll_list:SetItemsData(modpackoptionwidgets)
				local modpacknames = self.settings.is_configuring_server and self.servermodpacknames or self.clientmodpacknames
				if #modpacknames > 0 then
		            self.modfilterbar:Show()
		        else
		            self.modfilterbar:Hide()
		        end
				local last_modpack_modname = self.settings.is_configuring_server and self.last_modpack_modname_server or self.last_modpack_modname_client
				local optionwidgets_modpack = self.settings.is_configuring_server and self.modpackoptionwidgets_server or self.modpackoptionwidgets_client
				ShowLastClickedDetails(last_modpack_modname, optionwidgets_modpack)
		    end
		end

		self.lastlisttype = listtype
		self.currentmodtype = listtype
												--MIM support *thumbs up*
		if self.currentmodtype == "client" or self.currentmodtype == "mimmods" or self.currentmodtype == "modpacks" then
			self.modfilterbar:ShowFilter("statusfilter")
		else
			if not self.settings.is_configuring_server then
				self.modfilterbar:HideFilter("statusfilter")
			end
		end
	end


	-- Button Setup
	local hovertext_top = {
        offset_x = 2,
        offset_y = 45,
    }
	local ModpackRemove = function()
		local modpackname = self.currentmodname
		local fancyname = KnownModIndex:GetModpackFancyName(modpackname)
		TheFrontEnd:PushScreen(PopupDialogScreen(
			STRINGS.NAMES.DELETE_MOD_PACK..fancyname.."?", STRINGS.NAMES.DELETEE_MOD_PACK_CONTENT, 
			{
				{text=STRINGS.NAMES.CONFRIM_BUTTON, cb = function() KnownModIndex:ModpackDelete(modpackname) self.modfilterbar.cachedmodnames[modpackname] = nil TheFrontEnd:PopScreen() end },
				{text=STRINGS.UI.MODSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() end}
			}
		))
	end
	self.modpackdeletebutton = TEMPLATES.IconButton("images/button_icons.xml", "delete.tex", STRINGS.NAMES.DELETE_PACK_BUTTON, false, false, function() ModpackRemove() end, hovertext_top)
	local ModpackSyncMods = function()
		local modpackname = self.currentmodname
		local fancyname = KnownModIndex:GetModpackFancyName(modpackname)
		local is_client = not self.settings.is_configuring_server
		TheFrontEnd:PushScreen(PopupDialogScreen(
			STRINGS.NAMES.UPDATE_MOD_PACK..fancyname.."?", STRINGS.NAMES.UPDATE_MOD_PACK_CONTENT, 
			{
				{text=STRINGS.NAMES.CONFRIM_BUTTON, cb = function() KnownModIndex:ModpackUpdate(modpackname, is_client) self.modfilterbar.cachedmodnames[modpackname] = nil TheFrontEnd:PopScreen() end },
				{text=STRINGS.UI.MODSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() end}
			}
		))
	end
	self.modpacksyncbutton = TEMPLATES.IconButton("images/button_icons.xml", "undo.tex", STRINGS.NAMES.UPDATE_PACK_BUTTON, false, false, function() ModpackSyncMods() end, hovertext_top)
	local ModpackViewMods = function()
		local modpackname = self.currentmodname
		local mods_list = {}
		local function BuildOptionalModLink(mod_name)
			if PLATFORM == "WIN32_STEAM" or PLATFORM == "LINUX_STEAM" or PLATFORM == "OSX_STEAM" then -- Console mod support when?
				local link_fn, is_generic_url = ModManager:GetLinkForMod(mod_name)
				if is_generic_url then
					return nil
				else
					return link_fn
				end
			else
				return nil
			end
		end
		mods_list = {}
		for mod, data in pairs(KnownModIndex:GetModpackInfo(modpackname).mods) do
			table.insert(mods_list, {
				text = data.fancyname,
				onclick = BuildOptionalModLink(mod),
			})
		end

		TheFrontEnd:PushScreen(TextListPopup(mods_list, STRINGS.UI.SERVERLISTINGSCREEN.MODSTITLE))
	end
	self.modpackviewbutton = TEMPLATES.IconButton("images/button_icons.xml", "owned_filter_on.tex", STRINGS.NAMES.VIEW_PACK_BUTTON, false, false, function() ModpackViewMods() end, hovertext_top)

	self.modpack_selectedmodmenu = self.mods_page:AddChild(Menu({
		{ widget = self.modpackdeletebutton, },
		{ widget = self.modpacksyncbutton, },
		{ widget = self.modpackviewbutton, },
	}, 65, true))
	self.modpack_selectedmodmenu:SetPosition(self.selectedmodmenu:GetPosition())
	self.modpack_selectedmodmenu:MoveToFront()

	self.ModpackCreateNew = function(self)
		local is_client = not self.settings.is_configuring_server
		TheFrontEnd:PushScreen(
			NameModpackScreen(
				nil,
				STRINGS.NAMES.CREATE_PACK_WINDOW_TITLE,
				STRINGS.NAMES.CONFRIM_BUTTON,
				function(name, description) -- OnConfirm
					return KnownModIndex:ModpackCreate(nil, name, description, nil, nil, nil, is_client, nil)
				end,
				"",-- Filler default name
				"" -- Filler default description
			)
		)
	end
	self.modpackcreatebutton = TEMPLATES.IconButton("images/create.xml", "create.tex", STRINGS.NAMES.CREATE_PACK_BUTTON, false, false, function() self:ModpackCreateNew() end, hovertext_top)
	self.modpacknilbutton = TEMPLATES.IconButton("images/create.xml", "create.tex", STRINGS.NAMES.VIEW_PACK_BUTTON, false, false, function() end, hovertext_top)
	self.modpacknilbutton:Hide()

	self.allmodpacksmenu = self.mods_page:AddChild(Menu({
		{ widget = self.modpacknilbutton, }, -- for some cheeky low-effort repositioning
		{ widget = self.modpackcreatebutton, },
	}, 65, true))
	self.allmodpacksmenu:SetPosition(-420, -323)
	self.servercreationscreen:RepositionModsButtonMenu(self.allmodpacksmenu, self.modpack_selectedmodmenu)

	local SwapConfigButton = function(to)
		if to then
			self.modconfigbutton:Show()
			self.modpackdeletebutton:Hide()
		else
			self.modconfigbutton:Hide()
			local modpacknames = self.settings.is_configuring_server and self.servermodpacknames or self.clientmodpacknames
			if not (#modpacknames > 0) then return end
			self.modpackdeletebutton:Show()
		end
	end
	local SwapUpdateButton = function(to)
		if to then
			self.modupdatebutton:Show()
			self.modpacksyncbutton:Hide()
		else
			self.modupdatebutton:Hide()
			local modpacknames = self.settings.is_configuring_server and self.servermodpacknames or self.clientmodpacknames
			if not (#modpacknames > 0) then return end
			self.modpacksyncbutton:Show()
		end
	end
	local SwapLinkButton = function(to)
		if to then
			self.modlinkbutton:Show()
			self.modpackviewbutton:Hide()
		else
			self.modlinkbutton:Hide()
			local modpacknames = self.settings.is_configuring_server and self.servermodpacknames or self.clientmodpacknames
			if not (#modpacknames > 0) then return end
			self.modpackviewbutton:Show()
		end
	end
	local SwapUpdateAllButton = function(to)
		if to then
			self.updateallbutton:Show()
			self.modpackcreatebutton:Hide()
		else
			self.updateallbutton:Hide()
			self.modpackcreatebutton:Show()
		end
	end
	local SwapCleanAllButton = function(to)
		if to then
			self.cleanallbutton:Show()
		else
			self.cleanallbutton:Hide()
		end
	end



	local ModpackChangeImage = function()
		local modpackname = self.currentmodname
		TheFrontEnd:PushScreen(
			ModpackImageSelect(
				modpackname,
				KnownModIndex:GetModNames(),
				"",
				function() return end,
				nil
			)
		)
	end

	local ShowModDetails = self.ShowModDetails
	self.ShowModDetails = function(self, widget_idx, client_mod)
		if self.detailimage.changeimagebutton == nil then
			self.detailimage.changeimagebutton = self.detailimage:AddChild(TEMPLATES.IconButton(
				"images/edit.xml", 
				"edit.tex", 
				STRINGS.NAMES.UPDATE_IMAGE_BUTTON, 
				false, 
				false, 
				function() ModpackChangeImage() end, 
				{offset_x = 2, offset_y = -45}
			))
		end
		self.detailimage.changeimagebutton:SetScale(0.5)
		self.detailimage.changeimagebutton:SetPosition(30, -30)

		if self.currentmodtype == "modpacks" then
			local items_table = client_mod and self.modpackoptionwidgets_client or self.modpackoptionwidgets_server
			local modnames_versions = client_mod and self.clientmodpacknames or self.servermodpacknames

			if items_table and #items_table > 0 then
				for i, data in metaipairs(items_table) do
					data.is_selected = false
				end
				if items_table[widget_idx] then
					items_table[widget_idx].is_selected = true
				end
				self.mods_scroll_list:RefreshView()
			end
			local idx = items_table[widget_idx] and items_table[widget_idx].index or nil
			local modname = idx and modnames_versions[idx] and modnames_versions[idx].modname or nil
			self.currentmodname = modname
			if client_mod then
				self.last_modpack_modname_client = self.currentmodname
			else
				self.last_modpack_modname_server = self.currentmodname
			end
			local modinfo = modname and KnownModIndex:GetModpackInfo(modname) or {}

			-- local iconinfo = modname and self.infoprefabs[modname] or {} -- Niko: Is this needed?
			local icon, icon_atlas = modinfo.icon, modinfo.icon_atlas
			if icon and icon_atlas then
				self.detailimage:SetTexture(icon_atlas, icon)
			else
				self.detailimage:SetTexture("images/ui.xml", "portrait_bg.tex")
			end
			self.detailimage:SetSize(unpack(self.detailimage._align.size))

			local align = self.detailtitle._align
			self.detailtitle:SetMultilineTruncatedString(modinfo.name or modname or "", align.maxlines, align.width, align.maxchars, true)
			local w,h = self.detailtitle:GetRegionSize()
			self.detailtitle:SetPosition((w or 0)/2 - align.x, align.y)

			align = self.detailauthor._align
			self.detailauthor:SetTruncatedString(modname and string.format(STRINGS.UI.MODSSCREEN.AUTHORBY, modinfo.author or "unknown") or "", align.width, align.maxchars, true)
			w, h = self.detailauthor:GetRegionSize()
			self.detailauthor:SetPosition((w or 0)/2 - align.x, align.y)

			align = self.detaildesc._align
			self.detaildesc:SetMultilineTruncatedString(modinfo.description or "", align.maxlines, align.width, align.maxchars, true)
			w, h = self.detaildesc:GetRegionSize()
			self.detaildesc:SetPosition((w or 0)/2 - 190, 90 - .5 * (h or 0))

			self.detailcompatibility:SetString(modname and STRINGS.UI.MODSSCREEN.COMPATIBILITY_DST or "")

			-- if modname and KnownModIndex:HasModConfigurationOptions(modname) then
			-- 	self:EnableConfigButton()
			-- else
			-- 	self:DisableConfigButton()
			-- end

			if modname then
				local enabled, extra = KnownModIndex:IsModpackEnabled(modname)
				local modStatus = enabled and "WORKING_NORMALLY" or "DISABLED_MANUAL"

				if extra then
					if extra == "EMPTY" then
						self.detailwarning:SetColour(242/255, 99/255, 99/255, 1)
						self.detailwarning:SetString(STRINGS.NAMES.NO_MODS_WARING)
					else
						self.detailwarning:SetColour(.6,.6,.6,1)
						self.detailwarning:SetString(STRINGS.NAMES.SOME_MODS_ENABLE_WARING)
					end
				elseif modStatus == "WORKING_NORMALLY" then
					self.detailwarning:SetString(STRINGS.NAMES.ALL_MODS_ENABLE_WARING)
					self.detailwarning:SetColour(59/255, 222/255, 99/255, 1)
				-- elseif modStatus == "DISABLED_ERROR" then
				-- 	self.detailwarning:SetColour(242/255, 99/255, 99/255, 1) --(242/255, 99/255, 99/255, 1)--0.9,0.3,0.3,1)
				-- 	self.detailwarning:SetString(STRINGS.UI.MODSSCREEN.DISABLED_ERROR)
				elseif modStatus == "DISABLED_MANUAL" then
					self.detailwarning:SetString(STRINGS.NAMES.NO_MODS_ENABLE_WARING)
					self.detailwarning:SetColour(.6,.6,.6,1)
				end
			else
				self.detailwarning:SetString("")
			end

			self.modlinkbutton:Unselect()
			if not modname then
				self.modlinkbutton:ClearHoverText()
			end

			SwapConfigButton(false)
			SwapUpdateButton(false)
			SwapLinkButton(false)
			SwapUpdateAllButton(false)
			SwapCleanAllButton(false)
			self.detailimage.changeimagebutton:Show()
		else
			ShowModDetails(self, widget_idx, client_mod)

			SwapConfigButton(true)
			SwapUpdateButton(true)
			SwapLinkButton(true)
			SwapUpdateAllButton(true)
			SwapCleanAllButton(true)
			self.detailimage.changeimagebutton:Hide()
		end
	end


	-- Filters and sorting
	local UpdateModsOrder = self.UpdateModsOrder
	self.UpdateModsOrder = function(self, force_refresh)
		local curr_modpacknames_client = KnownModIndex:GetModpackNamesTable(true)
		local curr_modpacknames_server = KnownModIndex:GetModpackNamesTable(false)
		table.sort(curr_modpacknames_client, alphasort)
		table.sort(curr_modpacknames_server, alphasort)
		alpasortcache = {}
		
		if self.currentmodtype == "modpacks" then
			self.modfilterbar:ShowFilter("statusfilter")
		end

		local need_to_update = force_refresh
		if not CompareModnamesTable( self.clientmodpacknames, curr_modpacknames_client) or
			not CompareModnamesTable( self.servermodpacknames, curr_modpacknames_server) or
			self.forceupdatemodsorder then
			need_to_update = true
		end
		self.forceupdatemodsorder = nil

		--If nothing has changed bail out and leave the ui alone
		if not need_to_update or (self.mods_scroll_list and self.mods_scroll_list.dragging) then
			UpdateModsOrder(self, force_refresh)
			return
		end
		
		self.clientmodpacknames = curr_modpacknames_client
		self.servermodpacknames = curr_modpacknames_server

		self.modpackoptionwidgets_client = {}
		for i,v in ipairs(self.clientmodpacknames) do
			if self.mods_filter_fn(v.modname) then -- May need to update self.mods_filter_fn

				local data = {
					index = i,
					widgetindex = #self.modpackoptionwidgets_client + 1,
					mod = v, -- pack
					is_modpack = true,
					is_client_mod = true,
				}

				table.insert(self.modpackoptionwidgets_client, data)
			end
		end

		self.modpackoptionwidgets_server = {}
		for i,v in ipairs(self.servermodpacknames) do
			if self.mods_filter_fn(v.modname) then -- May need to update self.mods_filter_fn

				local data = {
					index = i,
					widgetindex = #self.modpackoptionwidgets_server + 1,
					mod = v, -- pack
					is_modpack = true,
					is_client_mod = false,
				}

				table.insert(self.modpackoptionwidgets_server, data)
			end
		end

		UpdateModsOrder(self, force_refresh)
	end


	-- Advanced Searching functionality
	local search_match = function( search, str )
		search = search:gsub(" ", "")
		str = str:gsub(" ", "")
	
		--Simple find in strings for multi word search
		if string.find( str, search, 1, true ) ~= nil then
			return true
		end
		local sub_len = string.len(search)
	
		if sub_len > 3 then
			if do_search_subwords( search, str, sub_len, 1 ) then return true end
	
			--Try again with 1 fewer character
			if do_search_subwords( search, str, sub_len - 1, 1 ) then return true end
		end
	
		return false
	end

	self.modfilterbar.cachedmodnames = {}

	local Searchfn = self.modfilterbar.filters.SEARCH
	self.modfilterbar.filters.SEARCH = function(modname) -- modname here means modpack name
		local result = Searchfn(modname)
		if result == false and KnownModIndex:ModpackExists(modname) then
			local search_str = TrimString(string.upper(self.modfilterbar.search_box.textbox:GetString()))

			if self.modfilterbar.cachedmodnames[modname] == nil then
				self.modfilterbar.cachedmodnames[modname] = {name = {}, fancy = {}}
				local mods = KnownModIndex:GetModpackInfo(modname).mods
				for mod, data in pairs(mods) do
					table.insert(self.modfilterbar.cachedmodnames[modname].name, mod)
					if data ~= nil and data.fancyname ~= nil then
						table.insert(self.modfilterbar.cachedmodnames[modname].fancy, data.fancyname)
					end
				end
			end

			for i, fancy in ipairs(self.modfilterbar.cachedmodnames[modname].fancy) do
				if search_match(search_str, string.upper(fancy)) then
					return true
				end
			end

			for i, mod in ipairs(self.modfilterbar.cachedmodnames[modname].name) do
				if search_match(search_str, string.upper(mod)) then
					return true
				end
			end

		end
		return result
	end


	-- Widget buttons and detail panel population
	local _ApplyDataToWidget = self.mods_scroll_list.update_fn
	self.mods_scroll_list.update_fn = function(context, widget, data, index)

		_ApplyDataToWidget(context, widget, data, index)
		if data == nil then return end

		local modname = data.mod.modname
		local opt = widget.moditem

		local controlneedsupdate = false

		-- Slide in our custom buttons, yeah?
		-- self.ModpackEnableOnly = function()
		-- 	self:enableonly_current(widget.data.widgetindex)
		-- end
		if opt.enableonly == nil then
			opt.enableonly = opt.backing:AddChild(ImageButton("images/button_icons.xml", "refresh.tex", "refresh.tex", "refresh.tex", nil, nil, {1,1}, {0,0}))
			opt.enableonly:SetPosition(100, -22, 0)
			opt.enableonly:SetScale(.1)
			opt.enableonly:SetOnClick(function() self:ModpackEnableOnly(widget.data.widgetindex) end)
			opt.enableonly:SetHelpTextMessage("") -- button nested in a button doesn't need extra helptext
			opt.enableonly.scale_on_focus = false

			controlneedsupdate = true
		end

		-- self.ModpackToggleConfig = function()
		-- 	opt:SetModConfigEnabled(self:modpackallowconfig_current(widget.data.widgetindex))
		-- end
		if opt.modpackallowconfig == nil then
			opt.modpackallowconfig = opt.backing:AddChild(ImageButton())
			opt.modpackallowconfig:SetPosition(60, -22)
			opt.modpackallowconfig:SetScale(0.66)
			opt.modpackallowconfig:SetOnClick(function() self:ModpackToggleConfig(widget.data.widgetindex) end)
			opt.modpackallowconfig:SetHelpTextMessage("")

			opt.SetModConfigEnabled = function(_, should_enable)
				if should_enable then
					opt.modpackallowconfig:SetTextures("images/config_checkbox.xml", "config_checkbox_normal_check.tex", "config_checkbox_focus_check.tex", "config_checkbox_normal.tex", nil, nil, {1,1}, {0,0})
				else
					opt.modpackallowconfig:SetTextures("images/config_checkbox.xml", "config_checkbox_normal.tex", "config_checkbox_focus.tex", "config_checkbox_normal_check.tex", nil, nil, {1,1}, {0,0})
				end
			end

			controlneedsupdate = true
		end

		if controlneedsupdate == true then
			local old_OnControl = opt.backing.OnControl
			opt.backing.OnControl = function(_, control, down)
				if opt.enableonly.focus and opt.enableonly:OnControl(control, down) then return true end
				if opt.modpackallowconfig.focus and opt.modpackallowconfig:OnControl(control, down) then return true end

				-- Normal button logic
				if old_OnControl(_, control, down) then return true end

				if self.currentmodtype ~= "modpacks" then return end
				if not down then
					if control == CONTROL_OPEN_CRAFTING then -- Left Trigger
						if widget.data ~= nil then
							self:ModpackToggleConfig(widget.data.widgetindex)
							TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
							return true
						end
					end
					if control == CONTROL_OPEN_INVENTORY then -- Right Trigger
						if widget.data ~= nil then
							self:ModpackEnableOnly(widget.data.widgetindex)
							TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
							return true
						end
					end
				end
			end

			local GetHelpText = opt.GetHelpText
			opt.GetHelpText = function()
				local controller_id = TheInput:GetControllerID()
				local t = nil
				local default = nil

				if GetHelpText ~= nil then 
					default = GetHelpText()
				end

				if self.currentmodtype == "modpacks" then
					t = {}
					
					table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_CRAFTING).." ".."Toggle Config") -- Left Trigger

					table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_INVENTORY).." ".."Enable Only") -- Right Trigger
					-- table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_1) .. " " .. STRINGS.UI.HELP.TOGGLE)
					
					-- return table.concat(t, "  ")
				end

				if t ~= nil then
					t = table.concat(t, "  ")

					return t.."  "..default
				else
					return default
				end
			end
		end

		if data and data.is_modpack then
			local modinfo = KnownModIndex:GetModpackInfo(modname)
			local enabled, extra = KnownModIndex:IsModpackEnabled(modname)
			local modstatus = enabled and "WORKING_NORMALLY" or "DISABLED_MANUAL"

			local _FinishClick = opt.FinishClick
			opt.FinishClick = function(...)
				_FinishClick(...)
				self.last_mod_click_time = GetTimeReal()
			end

			widget.moditem:SetModReadOnly(false)
			opt:SetMod(modname, modinfo, modstatus, KnownModIndex:IsModpackEnabled(modname), nil--[[Profile:IsModFavorited(modname)]])
			opt:SetModConfigEnabled(KnownModIndex:ModpackGetAllowConfig(modname))

			-- if widget.data.is_selected then
			-- 	opt:Select()
			-- else
			-- 	opt:Unselect()
			-- end

			opt.setfavorite:Hide()
			opt.enableonly:Show()
			opt.modpackallowconfig:Show()

			if extra then -- A quick fix
				if extra == "EMPTY" then
					opt.status:SetColour(242/255, 99/255, 99/255, 1)
					opt.status:SetString("Empty")
				else -- Partial
					opt.status:SetColour(.6,.6,.6,1)
					opt.status:SetString("Partially Enabled")
				end
			end
		else
			opt.setfavorite:Show()
			opt.enableonly:Hide()
			opt.modpackallowconfig:Hide()
		end
	end


	-- Nice display for when no modpacks exist
	local Refresh = self.detailpanel.Refresh
	self.detailpanel.Refresh = function(_)
		if self.currentmodtype == "modpacks" then
			local modpacknames = self.settings.is_configuring_server and self.servermodpacknames or self.clientmodpacknames
			local num_mods = #modpacknames

			if num_mods > 0 then
				self.modpackviewbutton:Show()
				self.modpacksyncbutton:Show()
				self.modpackdeletebutton:Show()

				self.detailpanel.whenfull:Show()
				self.detailpanel.whenempty:Hide()
			else
				self.modpackviewbutton:Hide()
				self.modpacksyncbutton:Hide()
				self.modpackdeletebutton:Hide()

				self.detailpanel.whenfull:Hide()
				self.detailpanel.whenempty:Show()
	
				local no_mods
				if IsRail() then
					no_mods =  "test_no_mods"
					self.modlinkbutton:Select()
				else
					no_mods = STRINGS.NAMES.NO_MODS_CONTENT_WARING
				end
	
				self.detaildesc_empty:SetString(no_mods)
				self:DisableConfigButton()
				self:DisableUpdateButton("uptodate")
				self.modlinkbutton:ClearHoverText()
			end
		else
			-- self.modpackviewbutton:Hide()
			-- self.modpacksyncbutton:Hide()
			-- self.modpackdeletebutton:Hide()

			Refresh(_)
		end
	end


	-- Detail panel populating
	local EnableCurrent = self.EnableCurrent
	self.EnableCurrent = function(self, widget_idx)
		if self.currentmodtype == "modpacks" then
			local items_table = self.settings.is_configuring_server and self.modpackoptionwidgets_server or self.modpackoptionwidgets_client
			local modpacknames = self.settings.is_configuring_server and self.servermodpacknames or self.clientmodpacknames
			local idx = items_table[widget_idx].index
			local modname = modpacknames[idx].modname

			local modinfo = KnownModIndex:GetModpackInfo(modname)
			if modname then
				self:OnConfirmEnable(false, modname)
			end
			self:ShowModDetails(widget_idx, self.settings.is_configuring_server and self.currentmodtype == "server" or self.currentmodtype == "client")
			self:UpdateModsOrder(true)
			self.mods_scroll_list:RefreshView()
		else
			EnableCurrent(self, widget_idx)
		end
	end


	-- Enable/Disable functionality hijacking
	local OnConfirmEnable = self.OnConfirmEnable
	self.OnConfirmEnable = function(self, restart, modname)
		if self.subscreener.active_key == "modpacks" then
			if KnownModIndex:IsModpackEnabled(modname) then
				KnownModIndex:ModpackDisable(modname)
			else
				KnownModIndex:ModpackEnable(modname)
			end
			if self.servercreationscreen.DirtyFromMods then
				self.servercreationscreen:DirtyFromMods(self.slotnum)
			end
		else
			OnConfirmEnable(self, restart, modname)
		end
	end


	local DoFocusHookups = self.DoFocusHookups
	self.DoFocusHookups = function(self)
		DoFocusHookups(self)
		if self.currentmodtype == "modpacks" then
			local tomiddlecol = self.subscreener:GetActiveSubscreenFn()
		
			self.subscreener.menu:SetFocusChangeDir(MOVE_DOWN, self.modpackcreatebutton)
		
			if self.mods_scroll_list then
				self.mods_scroll_list:SetFocusChangeDir(MOVE_RIGHT, self.modpack_selectedmodmenu)
				self.mods_scroll_list:SetFocusChangeDir(MOVE_UP, self.modfilterbar)
			end
			if self.modfilterbar then
				self.modfilterbar:SetFocusChangeDir(MOVE_DOWN, tomiddlecol)
				self.modfilterbar:SetFocusChangeDir(MOVE_RIGHT, self.detailimage.changeimagebutton)

				self.detailimage.changeimagebutton:SetFocusChangeDir(MOVE_LEFT, self.modfilterbar)
			end
			self.detailimage.changeimagebutton:SetFocusChangeDir(MOVE_RIGHT, self.modpack_selectedmodmenu)
			self.detailimage.changeimagebutton:SetFocusChangeDir(MOVE_DOWN, self.modpack_selectedmodmenu)
		
			self.allmodpacksmenu:SetFocusChangeDir(MOVE_UP, self.subscreener.menu)
			self.allmodpacksmenu:SetFocusChangeDir(MOVE_RIGHT, tomiddlecol)
		
			self.modpack_selectedmodmenu:SetFocusChangeDir(MOVE_LEFT, tomiddlecol)
			self.modpack_selectedmodmenu:SetFocusChangeDir(MOVE_UP, self.detailimage.changeimagebutton)
		end
	end

end

env.AddClassPostConstruct("widgets/redux/modstab", ModsTabPostInit)