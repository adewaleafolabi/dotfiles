local beautiful = require("beautiful")

local button = require("lib.button")

local color = beautiful.red
local color_hover = beautiful.red_light

return button.create_text(color, color_hover, "舘", "Fira Mono 14", function()
    awesome.emit_signal("dashboard::toggle")
end)