CEF = {};

---@param id number
---@param bs any
---@param printString boolean
---@return boolean status
---@return string event
---@return table data
---@return string json
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
            -- print(event, json)
            return true, event, decodeJson(json)[1], json;
        end
    end
    ::bad_packet::
    return false, 'NONE', {}, '[]';
end

---@param id number
---@param bs any
---@param printString boolean
---@return boolean status
---@return string str
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

---@param str string
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