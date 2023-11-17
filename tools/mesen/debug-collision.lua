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

function getThings()
  local wMap_things_count = emu.getLabelAddress("wMap_things_count")
  local count = emu.read(wMap_things_count.address, wMap_things_count.memType)
  local wWorld_things = emu.getLabelAddress("wWorld_things")
  local addr = wWorld_things.address
  local things = {}
  for i = 1, count do
    local thing, nextaddr = readThing(addr, wWorld_things.memType)
    table.insert(things, thing)
    addr = nextaddr
  end

  return things
end

function readThing(addr, memType)
  local thing = { addr = addr }
  for _, field in ipairs({ "hits", "y", "x", "t", "attr", "collider" }) do
    thing[field] = emu.read(addr, memType)
    addr = addr + 1
  end
  return thing, addr
end

function thingToString(thing)
  return "H: " ..
  thing.hits ..
  " y: " .. thing.y .. " x: " .. thing.x .. " t: " .. thing.t .. " a: " .. thing.attr .. " C: " .. thing.collider
end

function printThingsInfo(things)
  local drawScale = settings.thingsInfo.drawScale
  emu.selectDrawSurface(settings.thingsInfo.drawSurface, drawScale)
  printInfoPage(
    4,
    96,
    settings.thingsInfo.page,
    settings.thingsInfo.linesPerPage,
    #things,
    function(i)
      return i - 1 .. ": " .. thingToString(things[i])
    end
  )
  emu.selectDrawSurface(emu.drawSurface.consoleScreen)
end

function printInfoPage(x, y, page, linesPerPage, totalLines, fnGetLine)
  local idx = page * linesPerPage
  if idx >= 0 and idx < totalLines then
    local lineCount = linesPerPage
    local iend = lineCount + idx + 1
    if iend > totalLines then
      iend = totalLines
      lineCount = iend - idx
    end
    local w, h = 220, lineCount * 8 + 8

    emu.drawRectangle(x, y, w, h, bgColor, true, 1)
    emu.drawRectangle(x, y, w, h, fgColor, false, 1)

    for line = 1, lineCount do
      emu.drawString(x + 4, y + 4 + 8 * (line - 1), fnGetLine(line + idx), textColor, 0xFF000000)
    end
  end
end

function infoPageForward(infoSettings, lineCount)
  page = infoSettings.page + 1
  if page * infoSettings.linesPerPage > lineCount then
    page = -1
  end
  infoSettings.page = page
end

function drawPointer(x, y)
  emu.drawPixel(x, y, 0x80FFFFFF, 6)
  emu.drawLine(x - 2, y, x - 6, y + 1, 0x80000000)
  emu.drawLine(x, y + 2, x - 1, y + 6, 0x80000000)
  emu.drawLine(x + 2, y - 2, x + 4, y - 4, 0x80000000)
end

function colorModXY(x, y)
  return 0xFFFFFF & ((x << 5) ~ (y << 3) ~ (x << 11 ~ y) ~ (x * 17 ~ y * 23) << 17)
end

function msg(s, cat)
  emu.displayMessage(cat or "Collide", s)
  emu.log(s)
end

bgColor = 0x7F8C8C8C
fgColor = 0xD9D9D9
textColor = 0xFFFFFF
textBgColor = 0xC8000000
colliderColor = 0xA0A38373
colliderSubjectColor = 0xA010D0E0

mousePrev = emu.getMouseState()
mouse = emu.getMouseState()

settings = {
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
}

function printInfo()
  --Get the emulation state
  state = emu.getState()

  --Get the mouse's state (x, y, left, right, middle)
  mousePrev = mouse
  mouse = emu.getMouseState()
  mousePressed = {}
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

  drawPointer(mouse.x, mouse.y)
end

--Register some code (printInfo function) that will be run at the end of each frame
emu.addEventCallback(printInfo, emu.eventType.endFrame)
