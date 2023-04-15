IDS = {}
PROTOCOL = "elevator-base"

CLUTCH_SIDE = "right"
GEARSH_SIDE = "left"
SENSOR_SIDE = "top"

GEAR_UP = true
GEAR_DOWN = false

CLUTCH_OFF = true
CLUTCH_ON = false

MAX_FLOOR = 7
STOPED_THRESHOLD = 100

local server = {}


function server:setup()
    rednet.open("back")
    rednet.host(PROTOCOL, "server")
    
    term.clear()
    term.setCursorPos(1,1)

    self.currentFloor = 0
    self.sensorDetected = false
    self.sensorLast = -1
    self.sensorStoped = false
    self.moving = false
    self.lowering = true
    self.moving_floor = -1
    self.targetFloor = 0
    self.restarting = true

    return true
end

function server:run()
    while true do
        local timeout = os.startTimer(0.1)
        self:processEvents()
        self:processRedstone()
        self:processMovement()
        self:actuate()
        self:display()
    end
end

function server:processEvents()
    if self.restarting then
        return
    end

    local event, sender, message, protocol = os.pullEvent()
    if event == "rednet_message" then
        if protocol ~= nil then
            if protocol == PROTOCOL then
                if message == "connect" then
                    table.insert(IDS, sender)
                elseif message == "where" then
                    rednet.send(sender, self.currentFloor, PROTOCOL)
                elseif message and type(message) == "number" then
                    --print(message)
                    if self.moving then
                        rednet.send(sender, "moving", PROTOCOL)
                    else
                        self.targetFloor = message
                    end
                end
            end
        else
            print("Received message from " .. sender .. " with message " .. tostring(message))
        end
    end
end

function server:processRedstone()
    local currentSignal = redstone.getInput(SENSOR_SIDE)
    if currentSignal then
        if self.sensorDetected then
            if (os.epoch() - self.sensorLast) > STOPED_THRESHOLD then
                self.sensorLast = -1
                self.sensorStoped = true
            end
        else
            self.sensorDetected = true
            self.sensorLast = os.epoch()
            if self.lowering then
                self.moving_floor = self.moving_floor + 1
            else
                self.moving_floor = self.moving_floor - 1
            end
        end
    else
        self.sensorStoped = false
        if self.sensorDetected then
            self.sensorDetected = false
        end
    end
end

function server:processMovement()
    if self.restarting then
        return
    end

    if self.moving then
        if self.moving_floor == self.targetFloor then
            self.moving = false
            self.currentFloor = self.targetFloor
        elseif self.sensorStoped then
            self.moving = false
            self.currentFloor = self.moving_floor + 1
        end
    else
        if self.targetFloor ~= self.currentFloor then
            self.moving = true
            self.moving_floor = self.currentFloor
            if self.targetFloor > self.currentFloor then
                self.lowering = true
            else
                self.lowering = false
            end
        end
    end
end

function server:actuate()
    if self.restarting then
        redstone.setOutput(GEARSH_SIDE, GEAR_DOWN)
        redstone.setOutput(CLUTCH_SIDE, CLUTCH_ON)
        if self.sensorStoped then
            self.restarting = false
            print("Listening")
        end
    end
    if not self.moving then
        redstone.setOutput(CLUTCH_SIDE, CLUTCH_OFF)
        return
    end


    local dir = GEAR_UP
    if self.lowering then
        dir = GEAR_DOWN
    end

    redstone.setOutput(GEARSH_SIDE, dir)
    redstone.setOutput(CLUTCH_SIDE, CLUTCH_ON)
end

function server:display()
    --term.clear()
    term.setCursorPos(1,1)

    print("Moving  :", self.moving)
    print("CurrentF:", self.currentFloor)
    print("TargetF :", self.targetFloor)
    print("MovingF :", self.moving)
    print("SensorSt:", self.sensorStoped)
    print("SensorPw:", self.sensorDetected)
end

if server:setup() then
    print("Starting.")
    server:run()
end

