local env = env
GLOBAL.setfenv(1, GLOBAL) -- Moves us from modding env to global env, keeping the mod env handy in case we need it.

local ServerCreationScreen = function(self)

    local OnControl = self.OnControl
    self.OnControl = function(self, control, down)
        
        if self.tabscreener.active_key == "mods" and self.mods_tab.currentmodtype == "modpacks" then
            if not down then
                if TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
                    if control == CONTROL_MAP then
                        self.mods_tab:ModpackCreateNew()
                        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
                        return true
                    end
                end
            end
        end

        OnControl(self, control, down)
    end

    local GetHelpText = self.GetHelpText
    self.GetHelpText = function(self)
        local controller_id = TheInput:GetControllerID()
        local t = {}

        table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)

        if self.tabscreener.active_key == "mods" and self.mods_tab.currentmodtype == "modpacks" then
            table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MAP) .. " " .. "New Modpack")
        else
            table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_CRAFTING).."/"..TheInput:GetLocalizedControl(controller_id, CONTROL_OPEN_INVENTORY).. " " .. STRINGS.UI.HELP.CHANGE_TAB)
        end

        table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE).." "..(self:CanResume() and STRINGS.UI.SERVERCREATIONSCREEN.RESUME or STRINGS.UI.SERVERCREATIONSCREEN.CREATE))

        return table.concat(t, "  ")
    end

end

env.AddClassPostConstruct("screens/redux/servercreationscreen", ServerCreationScreen)