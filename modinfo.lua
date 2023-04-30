local ch = locale == "zh" or locale == "zhr"
-- This information tells other players more about the mod
name = ch and "模组合集" or "Modpacks"
description = ch and 
[[
	描述123
]]
or 
[[
	description
]]
author = "Niko"
version = "1.0" -- This is the version of the template. Change it to your own number.

-- This is the URL name of the mod's thread on the forum; the part after the ? and before the first & in the url
-- forumthread = ""

-- This lets other players know if your mod is out of date, update it to match the current version in the game
api_version = 10

-- Compatible with Don't Starve Together
dst_compatible = true

-- Not compatible with Don't Starve
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

-- Character mods are required by all clients
all_clients_require_mod = false

client_only_mod = true

priority = -1.79769313486231e+308 -- Load last

icon_atlas = "modicon.xml"
icon = "modicon.tex"

-- The mod's tags displayed on the server list
server_filter_tags = {}

configuration_options = {
    {
		name = "language",
		label = ch and "选择语言" or "select language",
		options =
		{
			{description = ch and "中文" or "CN", data = "ch"},
			{description = ch and "英文" or "EN", data = "en"}
		},
		default = "ch"
    }

}
