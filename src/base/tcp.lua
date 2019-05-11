local states = enum {
	"init", 
	"connecting", 
	"connected", 
	"closed", 
}

local session = class {
	ctor = function (self, session_id, actions)
		self.id = session_id
		self.actions = actions
	end, 

	dispatch = function (self, msg_id, type, msg)
		if self.actions then 
			local action = self.actions[msg_id] or self.actions[type]
			if action then 
				action(msg)
			else 
				print("no handler for message", msg_id, type)
			end
		end
	end, 

	-- 强制关闭响应，收到服务器消息时不再产生调用
	close = function (self)
		self.actions = nil
	end, 
}

return class {
	states = states, 

	EVT_MESSAGE = "EVT_MESSAGE", 

	connecting = {
		getter = function (self)
			return self.state == states.connecting
		end, 
	}, 

	connected = {
		getter = function (self)
			return self.state == states.connected
		end, 
	}, 
	
	error = {
		getter = function (self)
			return self.tcp.error
		end, 
	},

	ctor = function (self)
		local functor = require("base.functor")
		
		self.state = states.init
		self.events = unity.events()
		self.session_id = 1
		self.sessions = { __stub = 0 }
		self.tcp = Fenix.App.GetInstance():AddComponent(Fenix.Net.StreamSessionManager)
		self.tcp.onConnecting = functor.make(self.onConnecting, self)
		self.tcp.onConnected = functor.make(self.onConnected, self)
		self.tcp.onClosed = functor.make(self.onClosed, self)
		self.tcp.onReceived = functor.make(self.onReceived, self)
		self.deserialize = false 
		self.serialize = false

		self:onInit()
	end,

	connect = function (self, ip, port)
		self.tcp:Connect(ip, port)
	end,

	close = function (self)
		self.tcp:Close()
	end,

	send = function (self, obj, actions)
		if not obj then 
			error("tcp send nil")
			return
		end
		
		if actions then 
			local new_session_id = self.session_id + 1
			local new_session = session(new_session_id, actions)

			self.session_id = new_session_id
			self.sessions[new_session_id] = new_session
			self:_send(new_session_id, obj)
			return new_session
		else
			self:_send(0, obj)
		end
	end,

	post = function (self, obj)
		self:send(obj, nil)
	end,

	-- 发送消息, obj可以是pb实例, 或者消息id (这种情况下代表内容为空)
	_send = function (self, new_session_id, obj)
		if self.state == states.connected then 
			if type(obj) == "number" then 
				print("send msg", obj)
				self.tcp:Send(new_session_id, obj, nil)
			else
				local msg_id, data = self.serialize(obj)
				if msg_id then 
					self.tcp:Send(new_session_id, msg_id, data)
				else
					print("msg_id is not registered in protocols map for obj:", obj)
				end
			end
		end		
	end, 
	
	on = function (self, event, handler)
		return self.events:add(event, handler)
	end, 

	off = function (self, event, handler)
		return self.events:remove(event, handler)
	end, 

	onInit = function (self)
		-- 用于子类覆盖初始化功能
	end, 

	onConnecting = function (self)
		self.state = states.connecting
		self.events:dispatch(states.connecting)
	end,

	onConnected = function (self)
		self.state = states.connected
		self.events:dispatch(states.connected)
	end,

	onClosed = function (self)
		self.state = states.closed
		self.events:dispatch(states.closed)
	end,

	onReceived = function (self, session_id, id, msg)
		local obj, type = self.deserialize(id, msg)
		if session_id > 0 then 
			local the_session = self.sessions[session_id]
			if the_session then 
				the_session:dispatch(id, type, obj)
				self.sessions[session_id] = nil
			else 
				print("no such session", session_id)
			end
		else
			self.events:dispatch(self.EVT_MESSAGE, session_id, id, type, obj)
		end
	end,
}
