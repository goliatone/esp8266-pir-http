
local exports = function(ip, port, endpoint)
    
    local self = {}
    self.IP = ip
    self.PORT = port
    self.ENDPOINT = endpoint

    self.payload = {}
    self.payload.status = "online"
    self.payload.type = "ESP8266"
    self.payload.tag = "PIR"
    self.payload.alias = node.chipid()

    function build_post_request(path, value)
        payload = cjson.encode(value)
    
        return "POST " .. path .. " HTTP/1.1\r\n" ..
        "Host: " .. IP .. "\r\n" ..
        "Connection: close\r\n" ..
        "Content-Type: application/json\r\n" ..
        "Content-Length: " .. string.len(payload) .. "\r\n" ..
        "\r\n" .. payload
    end

    function self.register()
        conn = net.createConnection(net.TCP, 0)
        conn:connect(self.PORT, self.IP)
    
        --- Create HTTP POST raw headers and body
        request = build_post_request(self.ENDPOINT, self.payload)
    
        conn:send(request, function()
            print("Registration request sent")
            conn:close()
        end)        
    end

    return self
end

return exports