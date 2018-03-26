
ffi = require("ffi")
ioctl = require("ioctl")

ffi.cdef[[

// pulled from linux/mxcfb.h

struct mxcfb_rect {
        uint32_t top;
        uint32_t left;
        uint32_t width;
        uint32_t height;
};

struct mxcfb_alt_buffer_data {
        uint32_t phys_addr;
        uint32_t width; // width of entire buffer
        uint32_t height; // height of entire buffer
        struct mxcfb_rect alt_update_region; // region within buffer to update
};

struct mxcfb_update_data {
        struct mxcfb_rect update_region;
        uint32_t waveform_mode; // one of WAVEFORM_MODE_*
        uint32_t update_mode; // UPDATE_MODE_PARTIAL or UPDATE_MODE_FULL
        uint32_t update_marker; // unique number to return when done
        uint32_t hist_bw_waveform_mode; // same as waveform_mode
        uint32_t hist_gray_waveform_mode; // same as waveform_mode
        int temp; // TEMP_USE_PAPYRUS
        unsigned int flags;
        struct mxcfb_alt_buffer_data alt_buffer_data;
};

]]

local UPDATE_MODE_PARTIAL = 0x0
local UPDATE_MODE_FULL = 0x1

local WAVEFORM_MODE_INIT = 0x0 -- Screen goes to white (clears) 
local WAVEFORM_MODE_DU = 0x1 -- Grey->white/grey->black 
local WAVEFORM_MODE_GC16 = 0x2 -- High fidelity (flashing)
local WAVEFORM_MODE_GC4 = WAVEFORM_MODE_GC16 -- For compatibility
local WAVEFORM_MODE_GC16_FAST = 0x3	-- Medium fidelity
local WAVEFORM_MODE_A2 = 0x4 -- Faster but even lower fidelity
local WAVEFORM_MODE_GL16 = 0x5 -- High fidelity from white transition
local WAVEFORM_MODE_GL16_FAST = 0x6 -- Medium fidelity from white transition
local WAVEFORM_MODE_DU4 = 0x7 -- Medium fidelity 4 level of gray direct update
local WAVEFORM_MODE_AUTO = 257 -- no idea

local TEMP_USE_AMBIENT = 0x1000
local TEMP_USE_PAPYRUS = 0X1001

--local MXCFB_SEND_UPDATE = ioctl._IOW('F', 0x2E, "struct mxcfb_update_data")
local MXCFB_SEND_UPDATE = 0x4048462e
local MXCFB_WAIT_FOR_UPDATE_COMPLETE = ioctl._IOW('F', 0x2F, "uint32_t")

local mxcfb_rect = ffi.typeof("struct mxcfb_rect")
local mxcfb_alt_buffer_data = ffi.typeof("struct mxcfb_alt_buffer_data")
local mxcfb_update_data = ffi.typeof("struct mxcfb_update_data")

local mxcfb_rect_pointer = ffi.typeof("struct mxcfb_rect[1]")
local mxcfb_alt_buffer_data_pointer = ffi.typeof("struct mxcfb_alt_buffer_data[1]")
local mxcfb_update_data_pointer = ffi.typeof("struct mxcfb_update_data[1]")


local fb_dev = nil
local fb_dev_fd = nil

local open_framebuffer = function(fb_path)
  if not fb_path then
    fb_path = "/dev/fb0"
  end
  if fb_dev then
    error("framebuffer already open")
  end
  fb_dev = io.open(fb_path, 'w')
  if not fb_dev then
    error("Error opening framebuffer device")
  end
  fb_dev_fd = ioctl.fileno(fb_dev)
  return fb_dev
end

local close_framebuffer = function()
  if fb_dev then
    local ret = fb_dev:close()
    if not ret then
      error("Error closing framebuffer device")
    end
    fb_dev = nil
    fb_dev_fd = nil
    return ret
  end
  return nil
end

local update_partial = function(x, y, width, height)
  if not fb_dev_fd then
    error("framebuffer not open")
  end

--  local update_data = mxcfb_update_data_pointer()
  local update_data = ffi.new("struct mxcfb_update_data[1]")

  update_data[0].update_region.top = ffi.new("unsigned int", y)
  update_data[0].update_region.left = ffi.new("unsigned int", x)
  update_data[0].update_region.width = ffi.new("unsigned int", width)
  update_data[0].update_region.height = ffi.new("unsigned int", height)

  update_data[0].update_mode = ffi.new("unsigned int", UPDATE_MODE_FULL)
  update_data[0].update_marker = ffi.new("unsigned int", 42)
  update_data[0].waveform_mode = ffi.new("unsigned int", WAVEFORM_MODE_DU)
  update_data[0].hist_bw_waveform_mode = ffi.new("unsigned int", WAVEFORM_MODE_DU)
  update_data[0].hist_gray_waveform_mode = ffi.new("unsigned int", WAVEFORM_MODE_DU)
  update_data[0].temp = ffi.new("int", TEMP_USE_PAPYRUS)
  update_data[0].flags = ffi.new("unsigned int", 0)

--  update_data.alt_buffer_data.phys_addr = 0
--  update_data.alt_buffer_data.width = 0
--  update_data.alt_buffer_data.height = 0

--  update_data.alt_buffer_data.alt_update_region.top = 0
--  update_data.alt_buffer_data.alt_update_region.left = 0
--  update_data.alt_buffer_data.alt_update_region.width = 0
--  update_data.alt_buffer_data.alt_update_region.height = 0

  return ioctl._ioctl(ffi.new("int", fb_dev_fd), ffi.new("int", MXCFB_SEND_UPDATE), update_data)
end

-- fidelity can be:
--   0: lowest fidelity, fastest updates
--   1: medium fidelity, medium speed
--   2: highest fidelity, slowest updates
local update_full = function(fidelity)
  error("update_full not yet implemented")
end

return {
  open = open_framebuffer,
  close = close_framebuffer,
  update_partial = update_partial,
  update_full = update_full
}
