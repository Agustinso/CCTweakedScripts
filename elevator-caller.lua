PROTOCOL = "elevator-base"
SV_HOSTNAME = "controller"

THIS_FLOOR = 0 -- editar en cada piso

MDM_SIDE = "top"
BTN_SIDE = "front"
--MON_SIDE = "bottom"

local caller = {
    controller = nil,
    button = nil,
    currentFloor = nil,
}

function caller:setup()
    rednet.open(MDM_SIDE)
    self.controller = rednet.lookup(PROTOCOL, SV_HOSTNAME)
    if not self.controller then
        printError("Could not find controller")
        return false
    end
    
    self.button = redstone.getInput(BTN_SIDE)
    rednet.send(self.controller, "where", PROTOCOL)
    return true
end

function caller:run()
    local eventData = {os.pullEvent()}
    local event = eventData[1]

    if event == "redstone" then
        self.button = redstone.getInput(BTN_SIDE)
    elseif event == "rednet_message" then
        local sender, message, protocol = eventData[2], eventData[3], eventData[4]
        if protocol == PROTOCOL then
            if sender == SV_HOSTNAME then
                if message and type(message) == "number" then
                    self.currentFloor = message
                elseif message == "moving" then
                    self.currentFloor = -1
                end
            end
        end
    end
    if self.button then
        rednet.send(self.controller, THIS_FLOOR, PROTOCOL)
    end
end

if caller:setup() then
    while true do
        caller:run()
    end
end