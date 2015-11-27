local http = {}

function http.parseUrl(url)
    local components = {}

    components.scheme = string.match(url, "([^:]*):")
    components.host = string.match(url, components.scheme.."://([^:/]*)[:/]?")
    components.port = string.match(url, components.scheme.."://"..components.host..":([%d]*)")

    baseUrl = components.scheme.."://"..components.host

    if components.port ~= nil then
        baseUrl = baseUrl..":"..components.port
    end

    components.pathAndQueryString = string.sub(url, string.len(baseUrl) + 1)

    return components
end

local unescape = function (s)
    s = string.gsub(s, "+", " ")
    s = string.gsub(s, "%%(%x%x)", function (h)
        return string.char(tonumber(h, 16))
    end)
    return s
end

function http.parseQuerystring(payload)
    local _GET = {}
    local parameters = string.match(payload, "^GET (.*) HTTP/%d.%d")
    if parameters ~= nil then
        for k, v in string.match(parameters, "([_%w]+)=([^%&]+)&*") do
            _GET[k] = unescape(v)
        end
    end
    return _GET
end

function http.get(url, callback)
    http.sendContent("GET", url, nil, nil, callback)
end

function http.post(url, content, contentType, callback)
    http.sendContent("POST", url, content, contentType, callback)
end

function http.sendContent(method, url, contentToSend, contentType, callback)
    local components = http.parseUrl(url)

    if components.port == nil then
        components.port = 80
    else
        components.port = tonumber(components.port)
    end

    if components.pathAndQueryString == nil or components.pathAndQueryString == "" then
        components.pathAndQueryString = "/"
    end

    if contentType == nil then
        contentType = "application/x-www-form-urlencoded"
    end

    local conn=net.createConnection(net.TCP, false)

    conn:on("connection", function(conn)
        conn:send(method.." "..components.pathAndQueryString.." HTTP/1.1\r\nHost: "..components.host.."\r\n"
            .."Accept: */*\r\n")


        if contentToSend ~= nil then
            conn:send("Content-Type: "..contentType.."\r\n");
            conn:send("Content-Length: "..string.len(contentToSend).."\r\n\r\n")
            conn:send(contentToSend)
        else
            conn:send("\r\n")
        end

    end)

    conn:on("receive", function(conn, payload)
        local data = {}

        data.status = string.match(payload, "HTTP/%d.%d (%d+)")

        local location = string.find(payload, "\r\n\r\n")

        if location ~= nil then
            data.content = string.sub(payload, location + 4)
        end

        payload = nil

        collectgarbage()

        conn:close()
        conn = nil

        callback(data)

        data = nil
    end)
    conn:connect(components.port, components.host)
end

return http
