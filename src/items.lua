---@class Item
---@field name string
---@field UID number
---@field model number
---@field bone number
---@field tags string[]
---@field position number[]
---@field scale number[]
---@field rotation number[]
---@field preview {img: string, color: number}

---@class MenuItem
---@field id number
---@field title string
---@field color number
---@field img string
---@field price number
---@field currency string

OUTPUT_FILENAME = getGameDirectory() .. '\\moonloader\\vAcs_parsed_items.json';

Items = {
    ---@type table<string, table<number, MenuItem[]>>
    menuList = {
        [MENU_TYPE.DEFAULT] = {},
        [MENU_TYPE.UNIQUE] = {}
    },
    ---@type table<string, number>
    maxItemIndex = {
        [MENU_TYPE.DEFAULT] = 0,
        [MENU_TYPE.UNIQUE] = 0
    },
    ---@type table<string, table<number, Item[]>>
    parsed = {},
    activeMenu = MENU_TYPE.NONE,
    activeItemIndex = -1,
    ---@type Item | nil
    currentItem = nil,
    isAnyMenuActive = false
};

---@param data table
function Items:cefHandler(data)
    for _, menuItem in ipairs(data) do
        if (menuItem and self.maxItemIndex[self.activeMenu]) then
            if (menuItem.id > self.maxItemIndex[self.activeMenu]) then
                if (GetMapItemsCount(self.menuList[self.activeMenu]) == 0) then
                    Msg('First item in', self.activeMenu, '=', menuItem.id);
                end
                self.maxItemIndex[self.activeMenu] = menuItem.id;
            end
            self.menuList[self.activeMenu][menuItem.id] = menuItem;
        end
    end
    print('ITEMS SIZE', #self.menuList['default'], #self.menuList['unique']);
end

---@param UID number
---@param model number
---@param bone number
---@param position number[]
---@param rotation number[]
---@param scale number[]
---@param isArizona boolean
function Items:attachHandler(UID, model, bone, position, rotation, scale, isArizona)
    Msg('Items:attachHandler', self.activeItemIndex);
    ---@type MenuItem
    local menuItem = self.menuList[self.activeMenu] and self.menuList[self.activeMenu][self.activeItemIndex];
    
    self.currentItem = menuItem and {
        name = menuItem.title,
        UID = (isArizona and 100000 or 0) + UID,
        model = model,
        bone = bone,
        tags = isArizona and { 'arizona' } or {},
        position = position,
        rotation = rotation,
        scale = scale,
        preview = {
            img = menuItem.img,
            color = menuItem.color
        }
    } or nil;
    print('Current item set to:', TableToString(self.currentItem or {}));
end

function Items:save()
    local file = io.open(OUTPUT_FILENAME, 'w');
    if (not file) then
        return Msg('{ff0000}ERROR: could not open file:', OUTPUT_FILENAME);
    end
    file:write(encodeJson(Items.parsed));
    file:close();
end