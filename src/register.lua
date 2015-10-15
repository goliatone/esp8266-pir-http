
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

    function self.register(callback)
        conn = net.createConnection(net.TCP, 0)
        conn:connect(self.PORT, self.IP)

        --- Create HTTP POST raw headers and body
        request = util.build_post_request(self.IP, self.ENDPOINT, self.payload)

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
