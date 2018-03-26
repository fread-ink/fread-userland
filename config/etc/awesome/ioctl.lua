
ffi = require("ffi")

ffi.cdef[[

int ioctl(int __fd, unsigned long int __request, ...);

int fileno(struct FILE* stream);

]]

-- BEGIN arch dependent
local _IOC_NRBITS = 8
local _IOC_TYPEBITS = 8
local _IOC_SIZEBITS = 14
local _IOC_DIRBITS = 2

local _IOC_NONE = 0
local _IOC_WRITE = 1
local _IOC_READ = 2

local _IOC_NRSHIFT = 0
local _IOC_TYPESHIFT = _IOC_NRSHIFT + _IOC_NRBITS
local _IOC_SIZESHIFT = _IOC_TYPESHIFT + _IOC_TYPEBITS
local _IOC_DIRSHIFT = _IOC_SIZESHIFT + _IOC_SIZEBITS
-- END arch dependent

local _IOC_TYPECHECK = function(t)
  if (ffi.sizeof(t) == ffi.sizeof(t .. '[1]')) and (ffi.sizeof(t) < bit.lshift(1, _IOC_SIZEBITS)) then
    return ffi.sizeof(t)
  else
    error("Invalid size argument for IOC")
  end
end

local _IOC = function(dir, typen, nr, size)
  if type(typen) == 'string'  then
    typen = string.byte(typen)
  end
  return bit.bor(
    bit.lshift(dir, _IOC_DIRSHIFT),
    bit.lshift(typen, _IOC_TYPESHIFT),
    bit.lshift(nr, _IOC_NRSHIFT),
    bit.lshift(size, _IOC_SIZESHIFT)
  )
end

local _IO = function(type, nr)
  return _IOC(_IOC_NONE, type, nr, 0)
end

local _IOR = function (type, nr, size)
  return _IOC(_IOC_READ, type, nr, _IOC_TYPECHECK(size))
end

local _IOW = function(type, nr, size)
  return _IOC(_IOC_WRITE, type, nr, _IOC_TYPECHECK(size))
end

local _IOWR = function (type, nr, size)
  return _IOC(bit.bor(_IOC_READ, _IOC_WRITE), type, nr, _IOC_TYPECHECK(size))
end

local ioctl = function(fd, request, ...)
--  local args = {...}

  local t = type(fd)
  if t == "number" then -- an integer file descriptor
    return ffi.C.ioctl(fd, request, ...)
  elseif t == "userdata" then -- a lua file descriptor
    return ffi.C.ioctl(ffi.C.fileno(fd), request, ...)
  elseif t == "string" then -- a file path
    local fb = io.open(fd, 'rw')
    local ret = ffi.C.ioctl(ffi.C.fileno(fd), request, ...)
    fb:close()
    return ret
  else
    error("Invalid first parameter type")
  end
end

return {
  _IO = _IO,
  _IOR = _IOR,
  _IOW = _IOW,
  _IOWR = _IOWR,
  fileno = ffi.C.fileno,
  ioctl = ioctl,
  _ioctl = ffi.C.ioctl
}