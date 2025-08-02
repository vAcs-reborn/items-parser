function Msg(...)
    local items = {};
    for _, v in pairs({ ... }) do
        table.insert(items, tostring(v));
    end
    local str = table.concat(items, ' ');
    sampAddChatMessage('vAcs Parser // ' .. str, -1);
    print(str);
end

---@param newState STATE
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