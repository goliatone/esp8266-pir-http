
local exports = function(ip, port, endpoint)

    --- ego trip, create "registry". registry made.
    local registry = {}
    registry.IP = ip
    registry.PORT = port
    registry.ENDPOINT = endpoint

    --- construct payload template,
    --- to be sent during registration
    registry.payload = {}
    registry.payload.status = "online"
    registry.payload.type = "ESP8266"
    registry.payload.tag = "PIR"
    registry.payload.alias = node.chipid()

    function registry.build_post_request(ip, path, value)
        local payload = cjson.encode(value)
        print("ip "..ip.." path "..path.." value "..payload)

        local content = "POST " .. path .. " HTTP/1.1\r\n" ..
        "Host: " .. ip .. "\r\n" ..
        "Connection: close\r\n" ..
        "Content-Type: application/json\r\n" ..
        "Content-Length: " .. string.len(payload) .. "\r\n" ..
        "\r\n" .. payload

        return content
    end

    function registry.register(callback)
        local conn = net.createConnection(net.TCP, 0)
        conn:connect(registry.PORT, registry.IP)

        --- Create HTTP POST raw headers and body
        local request = registry.build_post_request(registry.IP, registry.ENDPOINT, registry.payload)

        conn:send(request, function()
            print("Registration request sent")
            conn:close()

            if(callback) then
                callback()
            end
        end)
    end

    return registry
end

return exports
