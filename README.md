## ESP8266 PIR motion detector

This is a sample project using the ESP8266 NodeMCU devkit board.

It uses a cheap PIR sensor to detect movement and ping a service through HTTP POSTs with movement updates.

The only challenge was to find a 3v to 5v booster to power the PIR from the board itself.


### TODO

* Proper config object:
    * Wrap configuration in a table
    * Remove global constants
    * Pass config object to each module

* AP Configuration Page:
    * HTML server to configure WiFi credentials
    * Add device's UUID
    * Custom configuration options

---

Using ESPbootloader from [sebastianhodapp][1]

[1]: https://github.com/sebastianhodapp/ESPbootloader

More instructions to come...
