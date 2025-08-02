---@diagnostic disable:lowercase-global
require('constants');
require('utils.helpers')
require('items');
require('utils.bitstream');
require('hooks');

State = STATE.NONE;
LastItemClick = os.clock();

function ClickItem()
    local itemIndex = Items.activeItemIndex;
    CEF:send(PATTERN.ITEM_CLICK:format(itemIndex));
    LastItemClick = os.clock();
    Msg('Sent click to item' .. itemIndex)
end

local font = renderCreateFont('Trebuchet MS', 10, 5);

function main()
    while not isSampAvailable() do wait(0) end
    Msg('Loaded, use', COMMAND.TOGGLE);
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
            if (Items.activeMenu == MENU_TYPE.NONE) then
                SetState(STATE.NONE);
                Msg('{ffff00} Page is NONE, stopped!');
            end
            if (State == STATE.WAITING_FOR_CLICK and os.clock() - LastItemClick > 0.2) then 
                if (not Items.menuList[Items.activeMenu][Items.activeItemIndex + 1]) then
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
        
        if (wasKeyPressed(49)) then
            CEF:send(PATTERN.CLOSE_TESTDRIVE);
        end
    end
end