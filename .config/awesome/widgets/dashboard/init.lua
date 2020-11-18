local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi

local naughty = require("naughty")

local apps = require("config.apps")

local leftbar = require("widgets.dashboard.sidebar.left")
local rightbar = require("widgets.dashboard.sidebar.right")
local avatar = require("widgets.dashboard.avatar")
local calendar = require("widgets.dashboard.calendar")
local time = require("widgets.dashboard.time")
local storage = require("widgets.dashboard.storage")
local volume = require("widgets.dashboard.volume")
local brightness = require("widgets.dashboard.brightness")
local battery = require("widgets.dashboard.battery")

local dashboard = wibox({
    visible = false, 
    ontop = true, 
    type = "dock", 
    screen = screen.primary, 
    x = 0, 
    y = beautiful.bar_height,
    width = awful.screen.focused().geometry.width, 
    height = awful.screen.focused().geometry.height - beautiful.bar_height,
    bgimage = function(context, cr, width, height) 
        local img = gears.surface(beautiful.wallpaper_blur)

        local w, h = gears.surface.get_size(img)
        local aspect_w = awful.screen.focused().geometry.width / w
        local aspect_h = awful.screen.focused().geometry.height / h

        aspect_h = math.max(aspect_w, aspect_h)
        aspect_w = math.max(aspect_w, aspect_h)
        
        cr:scale(aspect_w, aspect_h)

        -- this only works on my resolution
        -- i didn't figure out how to solve it programmatically
        cr:translate(0, -39)
        --cr:translate(0, -(beautiful.bar_height * h / aspect_h))
        
        cr:set_source_surface(img, 0, 0)
        cr:paint()
    end,
    bg = beautiful.bg_normal
})

local function drawBox(content, width, height)
    local margin = 8
    local padding = 16

    local container = wibox.container.background()
    container.bg = beautiful.bg_normal
    container.forced_width = dpi(width + margin + padding)
    container.forced_height = dpi(height + margin + padding)
    container.shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, dpi(8))
    end

    container:connect_signal("button::press", function()end)
    
    local box = wibox.widget {
        {
            {
                {
                    widget = wibox.widget.separator,
                    color  = '#b8d2f82a',
                    forced_height = dpi(1),
                },
                {
                    {
                        nil,
                        {
                            nil,
                            content,
                            layout = wibox.layout.align.vertical,
                            expand = "none"
                        },
                        layout = wibox.layout.align.horizontal,
                        expand = "none"
                    }, 
                    margins = dpi(padding),
                    widget = wibox.container.margin
                }, 
                layout = wibox.layout.fixed.vertical
            },
            widget = container
        },
        margins = dpi(margin),
        widget = wibox.container.margin
    }

    return box
end

local keygrabber
local function getKeygrabber()
    return awful.keygrabber {
        keypressed_callback = function(_, mod, key) 
            if key == "Escape" then
                dashboard.visible = false
                keygrabber:stop()
                return
            end
            
            -- don't do anything for non-alphanumeric characters or stuff like F1, Backspace, etc
            if key:match("%W") or string.len(key) > 1 and key ~= "Escape" then
                return 
            end

            local launchedAppWithLauncher = false
            -- spawn launcher with input arguments
            awful.spawn.with_line_callback(apps.launcher .. " " .. key, {
                stdout = function(line)
                    -- this line is emitted by debug rofi when an app is launched
                    if string.match(line, "Parsed command") then
                        launchedAppWithLauncher = true
                        dashboard.visible = false
                    end
                end, 
                output_done = function()
                    -- restart the keygrabber when no app was launched
                    if not launchedAppWithLauncher then
                        keygrabber = getKeygrabber()
                        keygrabber:start()
                    end
                end
            })
            keygrabber:stop()
        end,
    }
end

keygrabber = getKeygrabber()

dashboard.toggle = function()
    calendar.reset()
    dashboard.visible = not dashboard.visible

    keygrabber:stop()

    if dashboard.visible then
        keygrabber = getKeygrabber()
        keygrabber:start()
    end
end

-- listen to signal emitted by other widgets
awesome.connect_signal("dashboard::toggle", dashboard.toggle)

dashboard:setup {
    leftbar,
    {
        nil, {
            nil, 
            {
                {
                    drawBox(avatar, 164, 268),
                    layout = wibox.layout.fixed.vertical
                }, 
                {
                    drawBox({
                        volume,
                        brightness, 
                        battery,
                        spacing = dpi(16), 
                        widget = wibox.layout.fixed.vertical
                    }, 200, 114),
                    drawBox(storage(), 200, 114), 
                    layout = wibox.layout.fixed.vertical
                }, 
                {
                    drawBox(time, 200, 48),
                    drawBox(calendar, 260, 180), 
                    layout = wibox.layout.fixed.vertical
                }, 
                layout = wibox.layout.fixed.horizontal
            },
            expand = "none",
            layout = wibox.layout.align.vertical
        }, 
        expand = "none",
        layout = wibox.layout.align.horizontal
    }, 
    rightbar,
    layout = wibox.layout.align.horizontal
}

return dashboard