Assets = { 
    Asset("ATLAS", "images/config_checkbox.xml"), 
    Asset("IMAGE", "images/config_checkbox.tex"), 

    Asset("ATLAS", "images/create.xml"), 
    Asset("IMAGE", "images/create.tex"), 

    Asset("ATLAS", "images/edit.xml"), 
    Asset("IMAGE", "images/edit.tex"), 

    -- Asset("ATLAS", "images/config_checkbox_normal_check.xml"), 
    -- Asset("IMAGE", "images/config_checkbox_normal_check.tex"), 

    -- Asset("ATLAS", "images/config_checkbox_focus.xml"), 
    -- Asset("IMAGE", "images/config_checkbox_focus.tex"), 

    -- Asset("ATLAS", "images/config_checkbox_focus_check.xml"), 
    -- Asset("IMAGE", "images/config_checkbox_focus_check.tex"), 
}

local userlang = GLOBAL.Profile:GetLanguageID()
local modlanguage = GetModConfigData("language")
local isCh
if modlanguage == "auto" then
    isCh = userlang == GLOBAL.LANGUAGE.CHINESE_T or userlang == GLOBAL.LANGUAGE.CHINESE_S
else
    isCh = modlanguage == "ch"
end
modimport(isCh and "utils/strings_ch.lua" or "utils/strings_eng.lua")

-- modimport("scripts/modpackversionupgrades")
modimport("scripts/servercreationscreen")
modimport("scripts/modpackindex")
modimport("scripts/modsscreen")
modimport("scripts/modstab")
