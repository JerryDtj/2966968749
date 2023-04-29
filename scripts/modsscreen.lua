local env = env
GLOBAL.setfenv(1, GLOBAL) -- Moves us from modding env to global env, keeping the mod env handy in case we need it.

local ModsScreen = function(self)

    local OnControl = self.OnControl
    self.OnControl = function(self, control, down)
        
        if self.mods_page.currentmodtype == "modpacks" then
            if not down then
                if TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
                    if control == CONTROL_MAP then
                        self.mods_page:ModpackCreateNew()
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
        if self.mods_page.currentmodtype == "modpacks" then
            local controller_id = TheInput:GetControllerID()
            local t = {}
        
            table.insert(t,  TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
        
            table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MAP) .. " " .. "New Modpack")
        
            if self.mods_page.updateallenabled then
                table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_INSPECT) .. " " .. STRINGS.UI.MODSSCREEN.UPDATEALL)
            end
        
            table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_PAUSE) .. " " .. STRINGS.UI.MODSSCREEN.APPLY)
        
            return table.concat(t, "  ")
        else
            return GetHelpText(self)
        end
    end

end

env.AddClassPostConstruct("screens/redux/modsscreen", ModsScreen)