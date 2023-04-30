GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

Assets = { 
    Asset("ATLAS", "images/config_checkbox.xml"), 
    Asset("IMAGE", "images/config_checkbox.tex"), 

    Asset("ATLAS", "images/create.xml"), 
    Asset("IMAGE", "images/create.tex"), 

    -- Asset("ATLAS", "images/config_checkbox_normal_check.xml"), 
    -- Asset("IMAGE", "images/config_checkbox_normal_check.tex"), 

    -- Asset("ATLAS", "images/config_checkbox_focus.xml"), 
    -- Asset("IMAGE", "images/config_checkbox_focus.tex"), 

    -- Asset("ATLAS", "images/config_checkbox_focus_check.xml"), 
    -- Asset("IMAGE", "images/config_checkbox_focus_check.tex"), 
}

-- modimport("scripts/modpackversionupgrades")
modimport("scripts/servercreationscreen")
modimport("scripts/modpackindex")
modimport("scripts/modsscreen")
modimport("scripts/modstab")

local language = GetModConfigData("language")
local isCh = language == "ch"
modimport(isCh and "utils/strings_ch.lua" or "utils/strings_eng.lua")