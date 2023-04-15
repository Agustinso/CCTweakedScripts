PROTOCOL = "elevator-base"
MDM_SIDE = "front"
MON_SIDE = "bottom"
MAX_FLOOR = 7

local program = {}

function program:send_floor(floor)
    rednet.send(self.serverID, floor, PROTOCOL)
end

function program:setup()
    term.setBackgroundColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    self.width, self.height = term.getSize()
    self.buttonHeight = math.floor(self.height / MAX_FLOOR)
    
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
    local event, side, x, y = os.pullEvent("monitor_touch")
end

function program:draw()
    for i = 0, MAX_FLOOR - 1, 1 do
        local color = colors.orange
        if (i % 2 == 0) then
            color = colors.brown
        end

        local x = 1
        local y = 1 + i * self.buttonHeight
        local w = self.width
        local h = self.buttonHeight

        print("piso " .. i)
        paintutils.drawFilledBox(x, y, w, h, color)
    end
end

if program:setup() then
    program:run()
end
