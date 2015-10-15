---TODO: Make real module!
local exports = function()

    local self = {}

    function self.build_post_request(ip, path, value)
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

    function self.httpPost(ip, port, endpoint, payload)

        local conn = net.createConnection(net.TCP, 0)
        conn:connect(port, ip)

        --- Create HTTP POST raw headers and body
        local request = self.build_post_request(ip, endpoint, payload)

        print(request)

        conn:send(request, function()
            print("Request sent")
            conn:close()
        end)
    end

    return self
end

return exports
