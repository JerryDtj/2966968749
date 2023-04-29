local Screen = require "widgets/screen"
local TEMPLATES = require "widgets/redux/templates"
local PopupDialogScreen = require "screens/redux/popupdialog"

local label_width = 200 -- width of the label on the wide fields
local input_width = 500
local field_nudge = -55
local label_height = 40
local space_between = 5
local font_size = 25

local MODPACK_NAME_MAX_LENGTH = 50
local MODPACK_DESCRIPTION_MAX_LENGTH = 1000

local INVALID_CHARACTER_FILTER = [[<>:"/\|?*]]
local invalidcharints = {}
for i = 1, 31 do table.insert(invalidcharints, i) end
INVALID_CHARACTER_FILTER = INVALID_CHARACTER_FILTER..string.char(unpack(invalidcharints))

local NameModpackScreen = Class(Screen, function(self, category, title, confirmstr, onconfirmfn, name, desc)
    assert(onconfirmfn, "NameModpackScreen requires a onconfirmfn")

    Screen._ctor(self, "NameModpackScreen")

    -- self.levelcategory = category
    self.onconfirmfn = onconfirmfn

    self.root = self:AddChild(TEMPLATES.ScreenRoot())
    self.bg = self.root:AddChild(TEMPLATES.BackgroundTint(0.7))

    local buttons = {
        {
            text = STRINGS.UI.CUSTOMIZATIONSCREEN.CANCEL,
            cb = function() self:Close() end,
        },
        {
            text = confirmstr,
            cb = function() self:SaveModpack() end
        }
    }

    self.window = self.root:AddChild(TEMPLATES.CurlyWindow(600, 150, title, buttons))

    self.modpack_name = self.window:AddChild(TEMPLATES.LabelTextbox(STRINGS.UI.CUSTOMIZATIONSCREEN.NAMEPRESET, name or "", label_width, input_width, label_height, space_between, NEWFONT, font_size, field_nudge))
    self.modpack_name.textbox:SetTextLengthLimit(MODPACK_NAME_MAX_LENGTH)
    self.modpack_name.textbox:SetInvalidCharacterFilter(INVALID_CHARACTER_FILTER)
    self.modpack_name:SetPosition(0, 60)

    self.modpack_desc = self.window:AddChild(TEMPLATES.LabelTextbox(STRINGS.UI.CUSTOMIZATIONSCREEN.DESCRIBEPRESET, desc or "", label_width, input_width, label_height, space_between, NEWFONT, font_size, field_nudge))
    self.modpack_desc.textbox:SetTextLengthLimit(MODPACK_DESCRIPTION_MAX_LENGTH)
    self.modpack_desc:SetPosition(0, 10)

    self.default_focus = self.modpack_name

    self:DoFocusHookups()
end)

function NameModpackScreen:SaveModpack()
    local name = self.modpack_name.textbox:GetString()

    if not name or #name:gsub("%s", "") == 0 then
        TheFrontEnd:PushScreen(
            PopupDialogScreen("Missing modpack name", "Seems you forgot to name your new modpack.",
            {
                {
                    text = math.random() < 0.01 and "Oopsie, woopsie" or STRINGS.UI.CUSTOMIZATIONSCREEN.BACK,
                    cb = function()
                        TheFrontEnd:PopScreen()
                    end,
                },
            })
        )
        return
    end

    local desc = self.modpack_desc.textbox:GetString()

    if self.onconfirmfn(name, desc) == false then
        TheFrontEnd:PushScreen(
            PopupDialogScreen("Name taken", "A modpack with the same or similar name already exists! Please pick a new one.",
            {
                {
                    text = STRINGS.UI.CUSTOMIZATIONSCREEN.BACK,
                    cb = function()
                        TheFrontEnd:PopScreen()
                    end,
                },
            })
        )
        return
    else
        self:Close()
    end
end

function NameModpackScreen:Close()
    TheFrontEnd:PopScreen()
end

-- function NameModpackScreen:GetID(name)
--     return "CUSTOM_"..name:upper()
-- end

function NameModpackScreen:DoFocusHookups()
    self.modpack_name:SetFocusChangeDir(MOVE_DOWN, self.modpack_desc.textbox)

    self.modpack_desc:SetFocusChangeDir(MOVE_UP, self.modpack_name.textbox)
    self.modpack_desc:SetFocusChangeDir(MOVE_DOWN, self.window)

    self.window:SetFocusChangeDir(MOVE_UP, self.modpack_desc.textbox)
end

function NameModpackScreen:OnControl(control, down)
    if NameModpackScreen._base.OnControl(self, control, down) then return true end

    if not down then
        if control == CONTROL_CANCEL then
            self:Close()
            return true
        end
    end
end

function NameModpackScreen:GetHelpText()
	local controller_id = TheInput:GetControllerID()
    local t = {}

    table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.CANCEL)

	return table.concat(t, "  ")
end

return NameModpackScreen