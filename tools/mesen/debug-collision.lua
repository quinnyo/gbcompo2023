function AddressToString(addr)
  return string.format("%04X", addr)
end

function Vec2AxisIndex(axis)
  if type(axis) == "number" then
    return axis
  elseif type(axis) == "string" then
    if axis == "x" then
      return 1
    elseif axis == "y" then
      return 2
    end
  end
  error(string.format("Vec2: Invalid axis (%s)", axis))
end

function Vec2(x, y)
  if type(x) ~= type(y) then
    error("Vec2: expects two numbers or no args")
  end
  local vec = { x or 0, y or 0 }
  setmetatable(vec, {
    __index = function(t, k)
      return t[Vec2AxisIndex(k)]
    end,
    __newindex = function(t, k, v)
      t[Vec2AxisIndex(k)] = v
    end,
    __tostring = function(t)
      return string.format("(%02X,%02X)", t[1], t[2])
    end,
  })

  return vec
end

LINE_HEIGHT = 8

local bgColor = 0x7F8C8C8C
local fgColor = 0xD9D9D9
local textColor = 0xFFFFFF
local textBgColor = 0xC8000000
local colliderColor = 0xA0A38373
local colliderSubjectColor = 0xA010D0E0

local mousePrev = emu.getMouseState()
local mouse = emu.getMouseState()

local settings = {
  colliderList = {
    page = -1,
    linesPerPage = 10,
    drawSurface = emu.drawSurface.scriptHud,
    drawScale = 2,
    pos = Vec2(92, 2),
  },
  thingsInfo = {
    page = -1,
    linesPerPage = 10,
    drawSurface = emu.drawSurface.scriptHud,
    drawScale = 2,
    pos = Vec2(2, 2),
    thingFmt = "{index}: {target}{hits} {collider} {position} {drawable}",
  },
  pointerEnabled = false,
}


function readColliderBox(addr, memType)
  local box = {}
  for _, field in ipairs({ "left", "right", "top", "bottom" }) do
    box[field] = emu.read(addr, memType)
    addr = addr + 1
  end
  return box, addr
end

function writeColliderBox(addr, memType, box)
  for _, field in ipairs({ "left", "right", "top", "bottom" }) do
    emu.write(addr, box[field], memType)
    addr = addr + 1
  end
end

function boxPosSize(box)
  return box.left, box.top, box.right - box.left, box.bottom - box.top
end

function boxFromPosSize(x, y, w, h)
  return {
    left = x,
    right = x + w,
    top = y,
    bottom = y + h,
  }
end

function boxToString(box)
  return string.format("%3d,%3d:%3d,%3d", box.left, box.top, box.right, box.bottom)
end

function boxHasPoint(box, x, y)
  if x < box.left or x >= box.right then
    return false
  elseif y < box.top or y >= box.bottom then
    return false
  end
  return true
end

function readColliderStatus(addr, memType)
  local status = {}
  status["result"] = emu.read(addr, memType)
  return status, addr + 1
end

function getColliderCount()
  local label = emu.getLabelAddress("wColliderCount")
  return emu.read(label.address, label.memType)
end

function getColliders()
  local count = getColliderCount()
  local wColliders = emu.getLabelAddress("wColliders")
  local colladdr = wColliders.address
  local wColliderStatus = emu.getLabelAddress("wColliderStatus")
  local stataddr = wColliderStatus.address
  local colliders = {}
  for i = 0, count - 1 do
    local coll = { tag = "pool" }
    local box, nextaddr = readColliderBox(colladdr, wColliders.memType)
    coll["box"] = box
    coll["addr"] = colladdr
    local status, nextstataddr = readColliderStatus(stataddr, wColliderStatus.memType)
    coll["result"] = status["result"]
    table.insert(colliders, coll)
    colladdr = nextaddr
    stataddr = nextstataddr
  end

  local wCollideSubject = emu.getLabelAddress("wCollideSubject")
  local subjBox, _ = readColliderBox(wCollideSubject.address, wCollideSubject.memType)
  local subj = { tag = "subject", box = subjBox, addr = wCollideSubject.address, result = 0xFF }
  table.insert(colliders, subj)

  return colliders
end

function setColliderPosition(label, x, y)
  local box, _ = readColliderBox(label.address, label.memType)
  local _, _, w, h = boxPosSize(box)
  writeColliderBox(label.address, label.memType, boxFromPosSize(x, y, w, h))
end

function pickColliders(colliders, x, y)
  local picked = {}
  for i, coll in ipairs(colliders) do
    if boxHasPoint(coll.box, x, y) then
      coll.picked = true
      table.insert(picked, i)
    else
      coll.picked = nil
    end
  end
  return picked
end

function colliderGetColor(coll)
  if coll.tag == "subject" then
    return colliderSubjectColor
  else
    return colliderColor ~ colorModXY(coll.box.left, coll.box.top)
  end
end

function drawCollider(coll)
  local x, y, w, h = boxPosSize(coll.box)
  local col = colliderGetColor(coll)
  emu.drawRectangle(x, y, w, h, col, true)
  if coll.picked then
    emu.drawRectangle(x, y, w, h, 0x00FFFFFF & col, false)
  end
  if coll.result ~= 255 and coll.result ~= 0 then
    emu.drawLine(x, y, x, y - 4, 0xFF00FF)
  end
end

function CollidersPrintInfo(colliders, cfg)
  cfg = cfg or settings.colliderList
  local header = "Colliders"
  local drawScale = cfg.drawScale
  emu.selectDrawSurface(cfg.drawSurface, drawScale)
  PrintInfoPage(
    cfg.pos.x * drawScale,
    cfg.pos.y * drawScale,
    cfg.page,
    cfg.linesPerPage,
    #colliders,
    function(i)
      return string.format("%2d %s", i - 1, boxToString(colliders[i].box))
    end,
    header
  )
  -- collider hover popout
  local popoutcount = 0
  for i, coll in ipairs(colliders) do
    if coll.picked then
      local x, y = coll.box.left - 2, coll.box.top - 2
      x, y = x * drawScale + popoutcount * 4, y * drawScale - popoutcount * 4
      collx, colly = coll.box.left * drawScale, coll.box.top * drawScale
      local collcol = colliderGetColor(coll)
      emu.drawLine(x, y, collx, colly, collcol)
      emu.drawString(x, y - 8, i .. ":" .. coll.result, textColor, 0x66 | collcol)
      popoutcount = popoutcount + 1
    end
  end
  emu.selectDrawSurface(emu.drawSurface.consoleScreen)
end

ThingStruct = {
  status = 1,
  collider = 1,
  pos = 2,
  draw_mode = 1,
  drawable = 2,
  on_die = "w",
}

ThingFields = { "index", "addr", "void", "target", "hits", "collider", "position", "drawable", }

ThingFieldFormatters = {
  index = function(t)
    return string.format("%2d", t.index)
  end,
  addr = function(t)
    return AddressToString(t.addr)
  end,
  void = function(t)
    return t.status.void and "X" or " "
  end,
  target = function(t)
    return t.status.target and "T" or " "
  end,
  hits = function(t)
    return t.status.hits > 0 and string.format("+%d", t.status.hits) or "**"
  end,
  collider = function(t)
    return string.format("C:%X", t.collider)
  end,
  position = function(t)
    return tostring(t.pos)
  end,
  drawable = function(t)
    local sMode = "OAM"
    if t.draw_mode ~= 0 then
      sMode = string.format("?%2X", t.draw_mode)
    end
    return string.format("%s{%02X,%02X}", sMode, t.drawable[1], t.drawable[2])
  end,
}

function getThings()
  local wThings = emu.getLabelAddress("wThings")
  local wThingsInfo_count = emu.getLabelAddress("wThingsInfo_count")
  local count = emu.read(wThingsInfo_count.address, wThingsInfo_count.memType)
  local addr = wThings.address
  local things = {}
  for i = 1, count do
    local thing, nextaddr = ThingRead(i - 1, addr, wThings.memType)
    table.insert(things, thing)
    addr = nextaddr
  end

  return things
end

function ThingRead(index, addr, memType)
  local thing = {
    index = index,
    addr = addr,
  }
  thing.status = ThingDecodeStatus(emu.read(addr + 0, memType))
  thing.collider = emu.read(addr + 1, memType)
  local x = emu.read(addr + 2, memType)
  local y = emu.read(addr + 3, memType)
  thing.pos = Vec2(x, y)
  thing.draw_mode = emu.read(addr + 4, memType)
  local drawable0 = emu.read(addr + 5, memType)
  local drawable1 = emu.read(addr + 6, memType)
  thing.drawable = { drawable0, drawable1 }
  thing.on_die = emu.readWord(addr + 7, memType)

  thing.format = function(t, fmt)
    local s = fmt
    for i, v in ipairs(ThingFields) do
      s = s:gsub("{" .. v .. "}", ThingFieldFormatters[v](t))
    end
    return s
  end

  setmetatable(thing, {
    __tostring = function(t)
      if t.status.void then
        return "VOID"
      end
      return thing:format("{index}[{addr}]: {void} {target}{hits} {collider} {position} {drawable}")
    end,
  })

  return thing, addr + 9
end

function ThingDecodeStatus(status)
  local t = {
    raw = status,
    hits = status & 0x03,
    target = status & 0x10 ~= 0,
    ev_hit = status & 0x20 ~= 0,
    ev_die = status & 0x40 ~= 0,
    void = status & 0x80 ~= 0,
  }
  setmetatable(t, {
    __tostring = function(t)
      local void = t.void and "X" or " "
      local hits = ""
      for i = 1, 3 do
        if i <= t.hits then
          hits = hits .. "+"
        else
          hits = hits .. " "
        end
      end
      local target = t.target and "TAR" or "   "
      local events = "_"
      if t.ev_die then
        events = "D"
      elseif t.ev_hit then
        events = "H"
      end
      return string.format("%s %s[%s] %s", void, target, hits, events)
    end,
  })
  return t
end

function ThingsPrintInfo(things, cfg)
  cfg = cfg or settings.thingsInfo
  local wThingsInfo_targets = emu.getLabelAddress("wThingsInfo_targets")
  local wThingsInfo_count = emu.getLabelAddress("wThingsInfo_count")
  local thingsCount = emu.read(wThingsInfo_count.address, wThingsInfo_count.memType)
  local thingsAlive = emu.read(wThingsInfo_targets.address, wThingsInfo_targets.memType)
  local header = "Things: " .. thingsAlive .. "/" .. thingsCount
  local drawScale = cfg.drawScale
  emu.selectDrawSurface(cfg.drawSurface, drawScale)
  PrintInfoPage(
    cfg.pos.x * drawScale,
    cfg.pos.y * drawScale,
    cfg.page,
    cfg.linesPerPage,
    #things,
    function(i)
      return things[i]:format(cfg.thingFmt)
    end,
    header
  )
  emu.selectDrawSurface(emu.drawSurface.consoleScreen)
end

function PrintInfoPage(x, y, page, linesPerPage, totalLines, fnGetLine, fixedLines)
  fixedLines = fixedLines or {}
  if type(fixedLines) ~= "table" then
    fixedLines = {tostring(fixedLines)}
  end
  local idx = page * linesPerPage
  if idx >= 0 and idx < totalLines + #fixedLines then
    local lineCount = linesPerPage
    local iend = lineCount + idx + 1
    if iend > totalLines then
      iend = totalLines
      lineCount = iend - idx
    end

    local textWidth = 168
    local textHeight = (lineCount + #fixedLines) * LINE_HEIGHT + 2
    local innerMargin = 2
    local max = Vec2(x + innerMargin * 2 + textWidth, y + innerMargin * 2 + textHeight)
    local w = max.x - x
    local h = max.y - y
    emu.drawRectangle(x, y, w, h, bgColor, true)
    emu.drawRectangle(x, y, w, h, fgColor, false)

    x = x + innerMargin
    y = y + innerMargin

    for _, s in ipairs(fixedLines) do
      emu.drawString(x, y, s, textColor, 0xFF000000)
      y = y + LINE_HEIGHT
    end

    for line = 1, lineCount do
      emu.drawString(x, y + LINE_HEIGHT * (line - 1), fnGetLine(line + idx), textColor, 0xFF000000)
    end
  end
end

function infoPageForward(infoSettings, lineCount)
  local page = infoSettings.page + 1
  if page * infoSettings.linesPerPage > lineCount then
    page = -1
  end
  infoSettings.page = page
end

function drawPointer(x, y)
  local colour = 0x308030E0
  emu.drawPixel(x, y, colour)
  emu.drawPixel(x + 8, y + 8, colour)
  emu.drawPixel(x + 8, y, colour)
  emu.drawPixel(x, y + 8, colour)
  emu.drawPixel(x - 8, y - 8, colour)
  emu.drawPixel(x - 8, y, colour)
  emu.drawPixel(x, y - 8, colour)
  emu.drawPixel(x - 8, y + 8, colour)
  emu.drawPixel(x + 8, y - 8, colour)
end

function colorModXY(x, y)
  return 0xFFFFFF & ((x << 5) ~ (y << 3) ~ (x << 11 ~ y) ~ (x * 17 ~ y * 23) << 17)
end

function msg(s, cat)
  emu.displayMessage(cat or "Collide", s)
  emu.log(s)
end

MainMode = {
  Splash = 0,
  Game = 1,
  LevelSelect = 2,
  SoundTest = 3,
}

function GetMainMode()
  local wMode = emu.getLabelAddress("wMode")
  if wMode then
    return emu.read(wMode.address, wMode.memType)
  end
  return nil
end

function OnEndFrame()
  --Get the emulation state
  local state = emu.getState()

  emu.drawString(0, 0, tostring(GetMainMode()), textColor, 0xC0000000)
  if GetMainMode() ~= MainMode.Game then
    return
  end

  --Get the mouse's state (x, y, left, right, middle)
  mousePrev = mouse
  mouse = emu.getMouseState()
  local mousePressed = {}
  for k, v in pairs(mouse) do
    mousePressed[k] = v and v ~= mousePrev[k]
  end

  local things = getThings()

  local colliders = getColliders()
  pickColliders(colliders, mouse.x, mouse.y)
  for i, coll in ipairs(colliders) do
    drawCollider(coll)
  end

  if mousePressed.right then
    infoPageForward(settings.colliderList, #colliders)
    infoPageForward(settings.thingsInfo, #things)
  end

  if mouse.left then
    local wCollideSubject = emu.getLabelAddress("wCollideSubject")
    setColliderPosition(wCollideSubject, mouse.x, mouse.y)
  end

  CollidersPrintInfo(colliders)
  ThingsPrintInfo(things)

  if mousePressed.middle then
    settings.pointerEnabled = not settings.pointerEnabled
  end
  if settings.pointerEnabled then
    drawPointer(mouse.x, mouse.y)
  end
end

emu.addEventCallback(OnEndFrame, emu.eventType.endFrame)
