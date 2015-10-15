
local exports = function(ip, port, endpoint)

    --- ego trip, create "self". Self made.
    local self = {}
    self.IP = ip
    self.PORT = port
    self.ENDPOINT = endpoint

    --- construct payload template,
    --- to be sent during registration
    self.payload = {}
    self.payload.status = "online"
    self.payload.type = "ESP8266"
    self.payload.tag = "PIR"
    self.payload.alias = node.chipid()

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

    function self.register(callback)
        local conn = net.createConnection(net.TCP, 0)
        conn:connect(self.PORT, self.IP)

        --- Create HTTP POST raw headers and body
        local request = self.build_post_request(self.IP, self.ENDPOINT, self.payload)

        conn:send(request, function()
            print("Registration request sent")
            conn:close()

            if(callback) then
                callback()
            end
        end)
    end

    return self
end

return exports
