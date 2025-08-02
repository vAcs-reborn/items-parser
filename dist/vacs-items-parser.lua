




LUBU_BUNDLED = true;
LUBU_BUNDLED_AT = 1754142228;



package['preload']['items'] = (function()



















OUTPUT_FILENAME = getGameDirectory() .. '\\moonloader\\vAcs_parsed_items.json';

Items = {
    
    menuList = {
        [MENU_TYPE.DEFAULT] = {},
        [MENU_TYPE.UNIQUE] = {}
    },
    
    maxItemIndex = {
        [MENU_TYPE.DEFAULT] = 0,
        [MENU_TYPE.UNIQUE] = 0
    },
    
    parsed = {},
    activeMenu = MENU_TYPE.NONE,
    activeItemIndex = -1,
    
    currentItem = nil,
    isAnyMenuActive = false
};


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








function Items:attachHandler(UID, model, bone, position, rotation, scale, isArizona)
    Msg('Items:attachHandler', self.activeItemIndex);
    
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
    file:write(u8(encodeJson(Items.parsed)));
    file:close();
end
end);


package['preload']['hooks'] = (function()
SampEvents = require('lib.samp.events');
ArizonaEvents = require('lib.arizona-events');

addEventHandler('onSendPacket', function(id, bs)
    local status, str = CEF:readOutcomingPacket(id, bs, true);
    if (status) then
        if (str == PATTERN.OPEN_MENU) then
            Items.isAnyMenuActive = true;
        elseif (str == PATTERN.CLOSE_MENU) then
            Items.isAnyMenuActive = false;
        end
        if (State ~= STATE.NONE) then
            Msg('Menu status:', tostring(Items.isAnyMenuActive));
        end
    end
end);

addEventHandler('onReceivePacket', function(id, bs)
    local status, event, data = CEF:readIncomingPacket(id, bs, true);
    if (status) then
        if (event == PATTERN.EVENT_ADD_ITEM) then
            Items:cefHandler(data);
        elseif (event == PATTERN.EVENT_OPEN_MENU) then
            Items.menuList = {
                [MENU_TYPE.DEFAULT] = {},
                [MENU_TYPE.UNIQUE] = {}
            };
            Msg('Menu list cleared');
            if (data.title == PATTERN.MENU_TYPE_DEFAULT) then
                Items.activeMenu = MENU_TYPE.DEFAULT
            elseif (data.title == PATTERN.MENU_TYPE_UNIQUE) then
                Items.activeMenu = MENU_TYPE.UNIQUE;
            end
            Msg('Active menu:', Items.activeMenu);

            if (State == STATE.WAITING_FOR_MENU) then
                lua_thread.create(function()
                    wait(500);
                    Msg('Start...');
                    SetState(STATE.WAITING_FOR_CLICK);
                    Items.activeItemIndex = 0; 
                    ClickItem();
                end);
            end
        elseif (event == PATTERN.EVENT_SET_ACTIVE_VIEW) then
            if (State ~= STATE.NONE) then
                Msg('active view = ', data[1]);
            end
        end
    end
end);

function SampEvents.onShowDialog(dialogId, _, title)
    if (State == STATE.WAITING_FOR_DIALOG) then
        if (title:find('Тест%-драйв')) then
            SetState(STATE.WAITING_FOR_MENU);
            Msg('dialog opened, opening menu...');
            sampSendDialogResponse(dialogId, 1, Items.activeMenu == MENU_TYPE.NONE and 1 or 2, nil);
            return false;
        end
    elseif (State == STATE.WAITING_FOR_ITEM_DIALOG) then
        if (title:find(PATTERN.DIALOG_TITLE_ITEM_INFO)) then
            if (Items.currentItem) then
                local newItem = Items.currentItem;
                table.insert(Items.parsed, newItem);
                Msg('Item saved:', Items.activeMenu, Items.menuList[Items.activeMenu][Items.activeItemIndex].title); 
                Items.currentItem = nil;
            else
                Msg('{ff0000} Unable to save item!');
            end
            SetState(STATE.WAITING_FOR_CLICK);
            sampCloseCurrentDialogWithButton(0);
            return false;
        end
    end
end

local function vectorToTable(vector)
    return { vector.x, vector.y, vector.z };
end

function SampEvents.onSetPlayerAttachedObject(playerId, _, _, object)
    if (State ~= STATE.NONE and playerId == MyId()) then
        Items:attachHandler(
            Items.activeItemIndex,
            object.modelId,
            object.bone,
            vectorToTable(object.offset),
            vectorToTable(object.rotation),
            vectorToTable(object.scale),
            false
        );
        print('onSetPlayerAttachedObject');
        SetState(STATE.WAITING_FOR_ITEM_DIALOG);
    end
end

function ArizonaEvents.onArizonaSetPlayerAttachedObject(data)
    if (State ~= STATE.NONE and data.player_id == MyId()) then
         Items:attachHandler(
            Items.activeItemIndex,
            data.object.model_id,
            data.object.bone,
            vectorToTable(data.object.offset),
            vectorToTable(data.object.rotation),
            vectorToTable(data.object.scale),
            true
        );
        print('onArizonaSetPlayerAttachedObject');
        SetState(STATE.WAITING_FOR_ITEM_DIALOG);
    end
end
end);


package['preload']['constants'] = (function()

STATE = {
    NONE = 'NONE',
    WAITING_FOR_DIALOG = 'WAITING_FOR_DIALOG',
    WAITING_FOR_MENU = 'WAITING_FOR_MENU',
    WAITING_FOR_ATTACH = 'WAITING_FOR_ATTACH',
    WAITING_FOR_CLICK = 'WAITING_FOR_CLICK',
    WAITING_FOR_ITEM_DIALOG = 'WAITING_FOR_ITEM_DIALOG'
};


PATTERN = {
    ITEM_CLICK = 'mountain.testDrive.selectVehicle|%d',
    REGEX_PACKET = 'window%.executeEvent%(\'event%.(.+)\', `(.+)`%);',
    EVENT_ADD_ITEM = 'mountain.testDrive.addVehicles',
    EVENT_OPEN_MENU = 'mountain.testDrive.initializeText',
    MENU_TYPE_DEFAULT = 'Примерка аксессуаров (обычных)',
    MENU_TYPE_UNIQUE = 'Примерка аксессуаров (уникальных)',
    DIALOG_TITLE_ITEM_INFO = 'Примерка аксессуара',
    EVENT_SET_ACTIVE_VIEW = 'event.setActiveView',
    OPEN_MENU = 'onActiveViewChanged|MountainTestDrive',
    CLOSE_MENU = 'onActiveViewChanged|null',
    CLOSE_TESTDRIVE = 'mountain.testDrive.close'
};


MENU_TYPE = {
    NONE = 'none',
    DEFAULT = 'default',
    UNIQUE = 'unique'
};


COMMAND = {
    TOGGLE = 'vacs.parser.start',
    SAVE = 'vacs.parser.save'
};

ITEM_CLICK_DELAY = 100;
end);


package['preload']['utils.helpers'] = (function()
function Msg(...)
    local items = {};
    for _, v in pairs({ ... }) do
        table.insert(items, tostring(v));
    end
    local str = table.concat(items, ' ');
    sampAddChatMessage('vAcs Parser // ' .. str, -1);
    print(str);
end


function SetState(newState)
    Msg('State changed from', State, 'to', newState);
    State = newState;
end

function MyId()
    return select(2, sampGetPlayerIdByCharHandle(PLAYER_PED));
end

function TableToString(tbl, indent)
    local function formatTableKey(k)
        local defaultType = type(k);
        if (defaultType ~= 'string') then
            k = tostring(k);
        end
        local useSquareBrackets = k:find('^(%d+)') or k:find('(%p)') or k:find('\\') or k:find('%-');
        return useSquareBrackets == nil and k or ('[%s]'):format(defaultType == 'string' and "'" .. k .. "'" or k);
    end
    local str = { '{' };
    local indent = indent or 0;
    for k, v in pairs(tbl) do
        table.insert(str, ('%s%s = %s,'):format(string.rep("    ", indent + 1), formatTableKey(k), type(v) == "table" and TableToString(v, indent + 1) or (type(v) == 'string' and "'" .. v .. "'" or tostring(v))));
    end
    table.insert(str, string.rep('    ', indent) .. '}');
    return table.concat(str, '\n');
end

function GetMapItemsCount(tbl)
    local count = 0;
    for _ in pairs(tbl) do
        count = count + 1;
    end
    return count;
end
end);


package['preload']['utils.bitstream'] = (function()
CEF = {};








function CEF:readIncomingPacket(id, bs, printString)
    if (id == 220) then
        raknetBitStreamIgnoreBits(bs, 8);
        if (raknetBitStreamReadInt8(bs) == 17) then
            raknetBitStreamIgnoreBits(bs, 32);
            local length = raknetBitStreamReadInt16(bs);
            local encoded = raknetBitStreamReadInt8(bs);
            local str = (encoded ~= 0) and raknetBitStreamDecodeString(bs, length + encoded) or
            raknetBitStreamReadString(bs, length);
            if (printString) then
                print(str);
            end
            if (not str:find(PATTERN.REGEX_PACKET)) then
                goto bad_packet
            end
            local event, json = str:match(PATTERN.REGEX_PACKET);
            
            return true, event, decodeJson(json)[1], json;
        end
    end
    ::bad_packet::
    return false, 'NONE', {}, '[]';
end






function CEF:readOutcomingPacket(id, bs, printString)
    if (id == 220) then
        local id = raknetBitStreamReadInt8(bs);
        local packettype = raknetBitStreamReadInt8(bs);
        local strlen = raknetBitStreamReadInt16(bs);
        local str = raknetBitStreamReadString(bs, strlen);
        if (packettype ~= 0 and packettype ~= 1 and #str > 2) then
            if (printString) then
                print('[SENT]', str);
            end
            return true, str;
        end
    end
    return false, 'NOT_220';
end


function CEF:send(str)
    local bs = raknetNewBitStream();
    raknetBitStreamWriteInt8(bs, 220);
    raknetBitStreamWriteInt8(bs, 18);
    raknetBitStreamWriteInt16(bs, #str);
    raknetBitStreamWriteString(bs, str);
    raknetBitStreamWriteInt32(bs, 0);
    raknetSendBitStream(bs);
    raknetDeleteBitStream(bs);
end
end);


LUBU_ENTRY_POINT = (function()

require('constants');
require('utils.helpers')
require('items');
require('utils.bitstream');
require('hooks');
local encoding = require('encoding');

encoding.default = 'CP1251';
u8 = encoding.UTF8;

State = STATE.NONE;
LastItemClick = os.clock();
local font = renderCreateFont('Trebuchet MS', 10, 5);

function ClickItem()
    local itemIndex = Items.activeItemIndex;
    CEF:send(PATTERN.ITEM_CLICK:format(itemIndex));
    LastItemClick = os.clock();
    Msg('Sent click to item' .. itemIndex)
end

function main()
    while not isSampAvailable() do wait(0) end
    Msg('Loaded, use /' .. COMMAND.TOGGLE);
    sampRegisterChatCommand(COMMAND.TOGGLE, function()
        if (State == STATE.NONE) then
            Msg('Enabled!');
            SetState(STATE.WAITING_FOR_DIALOG);
        else
            State = STATE.NONE;
            Msg('Disabled!');
        end
    end);
    sampRegisterChatCommand(COMMAND.SAVE, function()
        Items:save();
        Msg('Saved items to:', OUTPUT_FILENAME);
    end);
    while true do
        wait(0)
        if (State ~= STATE.NONE) then
            renderFontDrawText(
                font,
                ('Items parser:\n\tState: %s\n\tTimeFromLastClick: %0.3f\n\tActiveItemIndex: %d'):format(State, os.clock() - LastItemClick, Items.activeItemIndex),
                50,
                500,
                0xFFffffff,
                false
            );
            if (State == STATE.WAITING_FOR_CLICK and os.clock() - LastItemClick > 0.2) then
                Msg('Active menu', Items.activeMenu);
                if (not Items.menuList[Items.activeMenu] or not Items.menuList[Items.activeMenu][Items.activeItemIndex + 1]) then
                    Items.activeItemIndex = 0;
                    Msg('Item index out of range -', Items.activeItemIndex, 'of', Items.maxItemIndex[Items.activeMenu], 'menu type is', Items.activeMenu);
                    if (Items.activeMenu == MENU_TYPE.DEFAULT) then
                        Items.activeMenu = MENU_TYPE.UNIQUE
                        CEF:send(PATTERN.CLOSE_TESTDRIVE);
                        SetState(STATE.WAITING_FOR_DIALOG);
                        Msg('Items menu closed. Waiting for Test Drive dialog!');
                    else
                        Items.activeMenu = MENU_TYPE.NONE;
                        SetState(STATE.NONE);
                        Msg('Done! Use /' .. COMMAND.SAVE, 'to save items to JSON file!');
                        if (sampIsDialogActive()) then
                            sampCloseCurrentDialogWithButton(0);
                            CEF:send(PATTERN.CLOSE_TESTDRIVE);
                        end
                    end
                else
                    Items.activeItemIndex = Items.activeItemIndex + 1;
                    Msg(Items.activeItemIndex, TableToString(Items.menuList[Items.activeMenu]));
                    ClickItem();
                    LastItemClick = os.clock();
                end
            end
        end
    end
end
end);
LUBU_ENTRY_POINT();