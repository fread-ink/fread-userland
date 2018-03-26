#!/usr/bin/env luajit

local epaper = require("epaper")

local filepath = "/dev/fb0"

if #arg >= 1 then
  filepath = arg[1]
end

epaper.open(filepath)

ret = epaper.update_partial(0, 0, 400, 400)

print("ioctl return value: " .. ret)
epaper.close()
