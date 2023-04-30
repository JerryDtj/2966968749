local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local TEMPLATES = require "widgets/redux/templates"
local AccountItemFrame = require "widgets/redux/accountitemframe"

local ModpackImageSelect = Class(Screen, function(self, modpackname, items, title, onconfirmfn, selected)
    assert(onconfirmfn, "ModpackImageSelect requires a onconfirmfn")

    Screen._ctor(self, "ModpackImageSelect")

    self.onconfirmfn = onconfirmfn

    self.items = items -- See modstab.lua:795

    self.modpackname = modpackname

    self.Close = function()
        TheFrontEnd:PopScreen()
    end

    self.focused = nil
    self.OnClick = function()
        if self.focused == nil or self.focused.modname == nil then return end
        if self.modpackname == nil then print("ModpackImageSelect Warning!!: \"modpackname\" was nil!") return end
        
        local modinfo = KnownModIndex:GetModInfo(self.focused.modname)
        KnownModIndex:ModpackChangeImage(self.modpackname, modinfo.icon_atlas, modinfo.icon)
        TheFrontEnd:GetSound():PlaySound("dontstarve/common/together/reskin_tool")
        self.Close()
    end

    self.optionwidgets = {}
    for i,v in ipairs(self.items) do
        local modinfo = KnownModIndex:GetModInfo(v)
        if modinfo.icon and modinfo.icon_atlas then
            local data = {
                index = i,
                widgetindex = #self.optionwidgets + 1,
                mod = v,
                icon = modinfo.icon,
                icon_atlas = modinfo.icon_atlas,
            }
            table.insert(self.optionwidgets, data)
        end
    end

    self.root = self:AddChild(TEMPLATES.ScreenRoot())

    self.tint = self.root:AddChild(TEMPLATES.BackgroundTint(0.7))

    --throw up the background
    self.bg = self.root:AddChild(TEMPLATES.CurlyWindow(500, 400, STRINGS.NAMES.UPDATE_PACK_IMAGE_TITLE))
    -- self.bg.fill = self.proot:AddChild(Image("images/fepanel_fills.xml", "panel_fill_tall.tex"))
    -- self.bg.fill:SetScale(.47, -.495)
    -- self.bg.fill:SetPosition(8, 10)
    self.bg:SetPosition(0,0,0)

    self.cancel_button = self.root:AddChild(TEMPLATES.BackButton(function() self.Close() end))
    self.cancel_button:SetPosition(-572, -295) -- SetPosition(-572, -310) -- Default button location

    self:CreateScrollList()
end)

function ModpackImageSelect:CreateScrollList()
    local function ScrollWidgetsCtor(context, index)
        local widget = Widget("widget-".. index)

        widget:SetOnGainFocus(function() self.scroll_list:OnWidgetFocus(widget) end)

        widget.item = widget:AddChild(ImageButton("images/ui.xml", "portrait_bg.tex"))
        widget.item.onclick = self.OnClick
        widget.item:SetScale(0.8) --1.2
        local OnFocus = widget.item.OnGainFocus
        widget.item.OnGainFocus = function(...)
            OnFocus(...)
            self.focused = widget.item
            widget:MoveToFront() -- If we pop it out, we want make sure nothing can cover it
        end
        
        widget.item.move_on_click = true
        local opt = widget.item

        opt.modicon = widget.item.image:AddChild(Image())
        opt.modicon:SetScale(0.9) --0.8
        opt.modicon:SetClickable(false)

        -- Get the actual widget (not the root).
        widget.GetWidget = function(_)
            return opt
        end

        widget.focus_forward = opt

        return widget
    end

    local function ApplyDataToWidget(context, widget, data, index)
        widget.data = data
        widget.item:Hide()
        if not data then
            widget.focus_forward = nil
            return
        end

        widget.focus_forward = widget.item
        widget.item:Show()

        local opt = widget.item

        if widget.data.is_selected then
            opt:Select()
        else
            opt:Unselect()
        end

        local modname = data.mod
        local modinfo = KnownModIndex:GetModInfo(modname)
        opt.modname = modname
        opt.modicon:SetTexture(data.icon_atlas, data.icon)
        opt.modicon:SetSize(100, 100)
    end

    self.scroll_list = self.root:AddChild(TEMPLATES.ScrollingGrid(
        self.optionwidgets,
        {
            context = {},
            widget_width  = 100, --150
            widget_height = 100, --150
            num_visible_rows = 3,
            num_columns      = 5,
            item_ctor_fn = ScrollWidgetsCtor,
            apply_fn     = ApplyDataToWidget,
            scrollbar_offset = 20,
            scrollbar_height_offset = -60,
            peek_percent = 0.50,
            allow_bottom_empty_row = false
        }
    ))
    -- self.scroll_list:SetPosition(1000, 500)

    self.default_focus = self.scroll_list
end

return ModpackImageSelect