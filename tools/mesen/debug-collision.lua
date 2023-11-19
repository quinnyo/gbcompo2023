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
  },
  thingsInfo = {
    page = -1,
    linesPerPage = 10,
    drawSurface = emu.drawSurface.scriptHud,
    drawScale = 2,
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
  local sr = box.right == box.left and "-" or box.right
  local sb = box.bottom == box.top and "-" or box.bottom
  return "{" .. box.left .. ":" .. sr .. ", " .. box.top .. ":" .. sb .. "}"
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

function printCollidersInfo(colliders)
  local drawScale = settings.colliderList.drawScale
  emu.selectDrawSurface(settings.colliderList.drawSurface, drawScale)
  printInfoPage(
    4,
    4,
    settings.colliderList.page,
    settings.colliderList.linesPerPage,
    #colliders,
    function(i)
      return i - 1 .. ": " .. boxToString(colliders[i].box)
    end
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

function getThings()
  local wThings = emu.getLabelAddress("wThings")
  local wThingsInfo_count = emu.getLabelAddress("wThingsInfo_count")
  local count = emu.read(wThingsInfo_count.address, wThingsInfo_count.memType)
  local addr = wThings.address
  local things = {}
  for i = 1, count do
    local thing, nextaddr = readThing(addr, wThings.memType)
    table.insert(things, thing)
    addr = nextaddr
  end

  return things
end

function readThing(addr, memType)
  local thing = { addr = addr }
  thing.status = emu.read(addr + 0, memType)
  thing.collider = emu.read(addr + 1, memType)
  local x = emu.read(addr + 2, memType)
  local y = emu.read(addr + 3, memType)
  thing.pos = { x, y }
  thing.draw_mode = emu.read(addr + 4, memType)
  local drawable0 = emu.read(addr + 5, memType)
  local drawable1 = emu.read(addr + 6, memType)
  thing.drawable = { drawable0, drawable1 }
  thing.on_die = emu.readWord(addr + 7, memType)

  return thing, addr + 9
end


function thingDecodeStatus(status)
  local t = {
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

function thingToString(t)
  local pos = "x" .. t.pos[1] .. ", y" .. t.pos[2]
  local collider = "C" .. t.collider
  local drawable = "(" .. t.draw_mode .. "/OAM) " .. t.drawable[1] .. "/" .. t.drawable[2]
  return tostring(thingDecodeStatus(t.status)) .. ", " .. collider .. ", " .. pos .. ", " .. drawable
end

function printThingsInfo(things)
  local wThingsInfo_targets = emu.getLabelAddress("wThingsInfo_targets")
  local wThingsInfo_count = emu.getLabelAddress("wThingsInfo_count")
  local thingsCount = emu.read(wThingsInfo_count.address, wThingsInfo_count.memType)
  local thingsAlive = emu.read(wThingsInfo_targets.address, wThingsInfo_targets.memType)
  local header = "Things: " .. thingsAlive .. "/" .. thingsCount
  local drawScale = settings.thingsInfo.drawScale
  emu.selectDrawSurface(settings.thingsInfo.drawSurface, drawScale)
  printInfoPage(
    4,
    96,
    settings.thingsInfo.page,
    settings.thingsInfo.linesPerPage,
    #things,
    function(i)
      return i - 1 .. " [" .. things[i].addr .. "] " ..thingToString(things[i])
    end,
    header
  )
  emu.selectDrawSurface(emu.drawSurface.consoleScreen)
end

function printInfoPage(x, y, page, linesPerPage, totalLines, fnGetLine, fixedLines)
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

    local w, h = 220, (lineCount + #fixedLines) * 8 + 8
    emu.drawRectangle(x, y, w, h, bgColor, true, 1)
    emu.drawRectangle(x, y, w, h, fgColor, false, 1)

    x = x + 4
    y = y + 4

    for _, s in ipairs(fixedLines) do
      emu.drawString(x, y, s, textColor, 0xC0000000)
      y = y + 8
    end

    for line = 1, lineCount do
      emu.drawString(x, y + 8 * (line - 1), fnGetLine(line + idx), textColor, 0xFF000000)
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

  printCollidersInfo(colliders)
  printThingsInfo(things)

  if mousePressed.middle then
    settings.pointerEnabled = not settings.pointerEnabled
  end
  if settings.pointerEnabled then
    drawPointer(mouse.x, mouse.y)
  end
end

emu.addEventCallback(OnEndFrame, emu.eventType.endFrame)
