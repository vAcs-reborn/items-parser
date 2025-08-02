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
        Msg('Menu status:', tostring(Items.isAnyMenuActive));
    end
end);

addEventHandler('onReceivePacket', function(id, bs)
    local status, event, data = CEF:readIncomingPacket(id, bs, true);
    if (status) then
        print(event);
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
                    Items.activeItemIndex = Items.activeMenu == MENU_TYPE.DEFAULT and 798 or 1188;
                    ClickItem();
                end);
            end
        elseif (event == PATTERN.EVENT_SET_ACTIVE_VIEW) then
            Msg('active view = ', data[1])
        end
    end
end);

addEventHandler('onScriptTerminate', function(scr)
    if (scr == thisScript()) then
        
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
                Msg('Item saved:', Items.activeMenu, Items.menuList[Items.activeMenu][Items.activeItemIndex].title); ---@diagnostic disable-line
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

function SampEvents.onSetPlayerAttachedObject(playerId, index, create, object)
    if (playerId == MyId()) then
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
    if (data.player_id == MyId()) then
         Items:attachHandler(
            Items.activeItemIndex,
            data.object.modelId,
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