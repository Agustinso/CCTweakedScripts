PROTOCOL = "elevator-base"
SV_HOSTNAME = "controller"
MDM_SIDE = "back"
MON_SIDE = "bottom"
MAX_FLOOR = 7

CLEAR_COLOR = colors.black
BG1_COLOR   = colors.gray
BG2_COLOR   = colors.lightGray
TEXT_COLOR  = colors.blue
CUR_COLOR   = colors.cyan




CAT_COLOR = colors.orange
CAT_BG    = colors.brown

CAT = {}
CAT[1] = [[       ]]
CAT[2] = [[    /\ ]]
CAT[3] = [[\  ( ')]]
CAT[4] = [[/ /  ) ]]
CAT[5] = [[\(__)| ]]

local program = {}

function program:setup()
    local monitor = peripheral.wrap(MON_SIDE)
    if monitor then
        self.monitor = monitor
        self.monitor.setTextScale(1)
        self.monitor.setBackgroundColor(CLEAR_COLOR)
        self.monitor.clear()
        self.monitor.setCursorPos(1,1)
        self.computer = term.current()
        self.first_draw = true
    else
        printError("Cannot find monitor")
        return false
    end

    rednet.open(MDM_SIDE)
    local serverID = rednet.lookup(PROTOCOL, SV_HOSTNAME)

    if serverID then
        self.serverID = serverID
        rednet.send(serverID, "elevator", PROTOCOL)
    else
        printError("Cannot find sv")
        return false
    end

    self.selected = -1
    self.currentFloor = -1

    term.clear()
    term.setCursorPos(1,1)
    return true
end


function program:run()
    while true do
        self:update()
        self:draw()
        os.sleep(0.01)
    end
end

function program:update()
    if self.first_draw then
        self.first_draw = false
        return
    end
    rednet.send(self.serverID, "where", PROTOCOL)
    local event, side, x, y = os.pullEvent()
    --print(event)
    if event == "monitor_touch" then
        print(x,y)
        if (y <= MAX_FLOOR) then
            self.selected = y - 1
            rednet.send(self.serverID, self.selected, PROTOCOL)
        end
    elseif event == "rednet_message" then
        local sender, message, protocol = side, x, y
        if protocol == PROTOCOL then
            if message and type(message) == "number" then
                self.currentFloor = message
            end
        end
    end
end


function program:draw()
    for i = 0, MAX_FLOOR-1, 1 do
        local color = BG1_COLOR
        if (i % 2 == 0) then
            color = BG2_COLOR
        end
        if (i == self.curentFloor) then
            color = CLEAR_COLOR
        end
        if self.selected == i then
            color = CUR_COLOR
        end
        local text = ""
        if (i == 0) then
            text = "Superf."
        else
            text = "Piso -" .. i
        end
        local current = term.redirect(self.monitor)
        term.setCursorPos(1, i+1)
        term.setBackgroundColor(color)
        term.setTextColor(TEXT_COLOR)
        term.write(text)
        term.redirect(current)
    end
    -- catito
    local current = term.redirect(self.monitor)
    local x,y = term.getCursorPos()
    term.setBackgroundColor(CAT_BG)
    term.setTextColor(CAT_COLOR)
    for i, catito in ipairs(CAT) do
        term.setCursorPos(1, y + i)
        term.write(catito)
    end
    
    term.redirect(current)
end


if program:setup() then
    program:run()
end
