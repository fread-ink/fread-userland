-- awesome configuration file for fread.ink

-- add awesome config path to search path
package.path = package.path .. ';/etc/awesome/?.lua'

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")

-- Ensure some client always has the focus
require("awful.autofocus")

-- Widget and layout library
local wibox = require("wibox")

-- Theme handling library
local beautiful = require("beautiful")

-- Notification library
local naughty = require("naughty")


-- {{{ Error handling

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions

-- Themes define colours, icons, font and wallpapers.
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier,
    awful.layout.suit.corner.nw,
    -- awful.layout.suit.corner.ne,
    -- awful.layout.suit.corner.sw,
    -- awful.layout.suit.corner.se,
}

-- }}}

awful.screen.connect_for_each_screen(function(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

end)
-- }}}


-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).

awful.rules.rules = {

    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },


    -- Floating clients.
    { rule_any = {
        instance = {

        },
        class = {
        },

        name = {
          "xterm",
          "Event Tester"  -- xev.
        },
        role = {
        }
      }, properties = {
        floating = true
      }
    }

}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.

client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

end)
-- }}}


-- {{{ Rules
autorun = true
autorunApps =
{
--   "xterm /opt/fread/xev.sh",
}
if autorun then
   for app = 1, #autorunApps do
       awful.spawn(autorunApps[app])
   end
end
-- }}}


-- {{{ XDamage and electronic paper display updates

local epaper = require("epaper")
local epaper_device = "/dev/fb0"

print('Opening epaper device')
epaper.open(epaper_device)

count=0

-- handle client damage
client.connect_signal("damage", function(c, area)
  if area.x >= 0 and area.y >= 0 and area.width > 0 and area.height > 0 then 
    print('Client damage: ' .. area.x .. ' ' .. area.y .. ' ' .. area.width .. ' ' .. area.height)
    ret = epaper.update_partial(area.x, area.y, area.width, area.height)
--    ret =  epaper.update_partial(0, 0, 178, 178)
    print(" returned: " .. ret)
  end
end)

-- handle screen damage
screen.connect_signal("damage", function(s, area)
  if area.x >= 0 and area.y >= 0 and area.width > 0 and area.height > 0 then 
    print('Screen damage: ' .. area.x .. ' ' .. area.y .. ' ' .. area.width .. ' ' .. area.height)
    epaper.update_partial(area.x, area.y, area.width, area.height)
  end
end)

-- }}}
