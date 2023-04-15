IDS = {}
PROTOCOL = "elevator-base"
SV_HOSTNAME = "controller"

CLUTCH_SIDE = "right"
GEARSH_SIDE = "left"
SENSOR_SIDE = "bottom"

GEAR_UP = false
GEAR_DOWN = true

CLUTCH_OFF = true
CLUTCH_ON = false

MAX_FLOOR = 7 -- 0->7

FLOOR_SIGNAL = {
--Signal  Floor
	[6]  = 7,
	[7]  = 6,
	[8]  = 5,
	[9]  = 4,
	[10] = 3,
	[11] = 2,
	[12] = 1,
	[13] = 0,
}

local controller = {
	currentFloor = nil,
	targetFloor  = nil,
	movingFloor  = nil,

	moving = nil,
	lowering = nil,

	sensor = nil,
}

function controller:setup()
    term.clear()
    term.setCursorPos(1,1)

    print("Starting elevator controller...")
	rednet.open("back")
	rednet.host(PROTOCOL, SV_HOSTNAME)
	print("Serving protocol", PROTOCOL, "as", SV_HOSTNAME)

	if redstone.getAnalogInput(SENSOR_SIDE) == 0 then
		print("Carriage is not in a floor, sending up...")
	end

	while redstone.getAnalogInput(SENSOR_SIDE) == 0 do
		redstone.setOutput(CLUTCH_SIDE, CLUTCH_ON)
		redstone.setOutput(GEARSH_SIDE, GEAR_UP)
		sleep(0.1)
	end
	redstone.setOutput(CLUTCH_SIDE, CLUTCH_OFF)
	print("Done.")

	self.sensor = redstone.getAnalogInput(SENSOR_SIDE)

	self.currentFloor = FLOOR_SIGNAL[self.sensor]
	self.targetFloor = self.currentFloor
	self.movingFloor = self.currentFloor
	self.lowering = true
	self.moving = false
	
	term.clear()
	
	return true
end

function controller:run()
	while true do
		local eventData = {os.pullEvent()}
		self:processEvents(eventData)

		self:update()
		self:actuate()
		self:display()
	end
end


function controller:processEvents(data)
	local event = data[1]

	if event == "rednet_message" then
		local sender, message, protocol = data[2], data[3], data[4]
		if protocol ~= nil then
			if protocol == PROTOCOL then
				if message == "connect" then
					table.insert(IDS, sender)
				elseif message == "where" then
					rednet.send(sender, self.currentFloor, PROTOCOL)
				elseif message and type(message) == "number" then
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
	elseif event == "redstone" then
		self.sensor = redstone.getAnalogInput(SENSOR_SIDE)
	end
end

function controller:update()
	if self.currentFloor ~= self.targetFloor then
		self.moving = true
		self.lowering = self.currentFloor < self.targetFloor
		self.movingFloor = self.currentFloor
	end

	if self.moving then
		if FLOOR_SIGNAL[self.sensor] then
			self.movingFloor = FLOOR_SIGNAL[self.sensor]
		end
		if self.movingFloor == self.targetFloor then
			self.moving = false
			self.targetFloor = self.currentFloor
		--[[
		else
			if (self.movingFloor > self.targetFloor) and self.lowering then
				printError(" LOWER FLOOR:", self.movingFloor, self.targetFloor)
				self.moving = false
			elseif (self.movingFloor < self.targetFloor) and not self.lowering then
				printError(" GREATER FLOOR:", self.movingFloor, self.targetFloor)
				self.moving = false
			end
		--]]
		end
	end
end

function controller:actuate()
	if self.moving then
		local gearDir = GEAR_UP
		if self.lowering then
			gearDir = GEAR_DOWN
		end
		redstone.setOutput(GEARSH_SIDE, gearDir)
		redstone.setOutput(CLUTCH_SIDE, CLUTCH_ON)
	else
		redstone.setOutput(CLUTCH_SIDE, CLUTCH_OFF)
	end
end

function controller:display()
	term.setCursorPos(1,1)
	print("Current:", self.currentFloor)
	term.setCursorPos(1,2)
	print("Target:", self.targetFloor)
	term.setCursorPos(1,3)
	local text = "    "
	if self.moving then
		if self.lowering then
			text = "down["..self.movingFloor.."]"
		else
			text = "up["..self.movingFloor.."]"
		end
	end
	print("Moving:", self.moving, text)
	term.setCursorPos(1,4)
	if FLOOR_SIGNAL[self.sensor] then
		print("Sensor:",self.sensor,"(floor "..FLOOR_SIGNAL[self.sensor]..")")
	end
end


if controller:setup() then
	controller:run()
else
	printError("COULD NOT SETUP. DONT MAKE MISTAKES.")
end