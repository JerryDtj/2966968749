local env = env
GLOBAL.setfenv(1, GLOBAL) -- Moves us from modding env to global env, keeping the mod env handy in case we need it.

-- lable
STRINGS.NAMES.TAB_LABEL = "Modpacks"
STRINGS.NAMES.TAB_LABEL_DESC = "Enable mods in bulk to easily switch between play styles"

-- button
STRINGS.NAMES.CREATE_PACK_BUTTON = "Create New Modpack"
STRINGS.NAMES.VIEW_PACK_BUTTON = "View mods"
STRINGS.NAMES.UPDATE_PACK_BUTTON = "Sync Modpack"
STRINGS.NAMES.DELETE_PACK_BUTTON = "Delete Modpack"
STRINGS.NAMES.UPDATE_IMAGE_BUTTON = "Change Image"

-- warning
STRINGS.NAMES.NO_MODS_WARING = "This pack has no mods"
STRINGS.NAMES.NO_MODS_CONTENT_WARING = "You have no modpacks, Create a new modpack using the \"Create New Modpack\" button below."
STRINGS.NAMES.NO_MODS_ENABLE_WARING = "No mods in this pack are enabled"
STRINGS.NAMES.SOME_MODS_ENABLE_WARING = "Some mods in this pack are enabled"
STRINGS.NAMES.ALL_MODS_ENABLE_WARING = "All mods in this pack are enabled"

-- confrim 
STRINGS.NAMES.DISABLE_MOD_PACK = "Enable only "
STRINGS.NAMES.DISABLE_MOD_PACK_CONTENT = "This will disable all your mods except the ones in this modpack"
STRINGS.NAMES.DELETE_MOD_PACK = "Delete "
STRINGS.NAMES.DELETEE_MOD_PACK_CONTENT = "Deleting this modpack will remove it permanently and can not be undone!"
STRINGS.NAMES.UPDATE_MOD_PACK = "Sync "
STRINGS.NAMES.UPDATE_MOD_PACK_CONTENT = "Syncing this modpack will update it with the currently enabled mods and configs and can not be reverted!"
STRINGS.NAMES.CONFRIM_BUTTON = "Confirm "
STRINGS.NAMES.UPDATE_PACK_IMAGE_TITLE = "Select New Icon"

-- window
STRINGS.NAMES.CREATE_PACK_WINDOW_TITLE = "Please name this modpack"
STRINGS.NAMES.CREATE_PACK_MISS_NAME_WINDOW_TITLE = "Missing modpack name"
STRINGS.NAMES.CREATE_PACK_MISS_NAME_WINDOW_CONTENT = "Seems you forgot to name your new modpack."
STRINGS.NAMES.CREATE_PACK_REPEAT_NAME_WINDOW_TITLE = "Name taken"
STRINGS.NAMES.CREATE_PACK_REPEAT_NAME_WINDOW_CONTENT = "A modpack with the same or similar name already exists! Please pick a new one."