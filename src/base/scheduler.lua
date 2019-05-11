--[[
	使用范例
	
        self.scheduler:create(1, 0, function (timer)
            print("timer1 ticked", timer.repeated, self.scheduler.time)
            if timer.repeated == 3 then 
                timer.enabled = false
            end
        end)
        self.scheduler:create(0.5, 0, function (timer)
            print("timer2 ticked", timer.repeated, self.scheduler.time)
            if timer.repeated == 2 then 
                timer.enabled = false
            end
        end)
        self.scheduler:create(1.5, 0, function (timer)
            print("timer3 ticked", timer.repeated, self.scheduler.time)
            if timer.repeated == 2 then 
                self.scheduler:create(0, 2, function (_timer)
                    print("_timer ticked", _timer.repeated, self.scheduler.time)
                end)
            end
            if timer.repeated == 5 then 
                timer.enabled = false
            end
        end)

        local my_timer_class = self.scheduler:make(function (self)
            print("customized timer actived")
        end)
        my_timer_class:create(2, 2)
        my_timer_class:create(1, 1)
]]

return class {

	ctor = function (self)
		self.timers = {}
		self.time = 0
		self.size = 0
	end,

	-- 创建基础定时器
	create = function (self, interval, repeats, handler, immediate)
		local timer = require("base.timer").new(self, interval, repeats, handler, immediate)

		timer.enabled = true
		return timer
	end, 

	make = function (self, handler, immediate)
		return class {
			super = require("base.timer"), 
			create = function (class_self, interval, repeats)
				local timer = class_self.new(self, interval, repeats, immediate)

				timer.enabled = true
				return timer
			end, 
			onActived = handler, 
		}
	end, 

	clear = function (self)
		local iter = self.head
		if iter ~= nil then 
			local copy = {}
			while iter ~= nil do 
				table.insert(copy, iter)
				iter = iter.next
			end
			for _, timer in ipairs(copy) do 
				timer.enabled = false
			end
		end
		if self.executing ~= nil then 
			self.executing.enabled = false
		end
	end, 

	destroy = function (self)
		self:clear()
	end, 

	print = function (self, title, timer)
		local iter = self.head
		local str = ""
		print(title, timer:tostring_s())

		str = str .. "$$" .. self.size .. "$$ "
		while iter ~= nil do 
			str = str .. iter:tostring() .. " ** "
			iter = iter.next
		end
		print(str)
	end, 

	add = function (self, timer)
		local iter = self.head
		local last = nil
		self.size = self.size + 1
		while iter ~= nil do 
			if timer.time < iter.time then 
				local previous = iter.previous
				if previous ~= nil then 
					previous.next = timer
				end
				iter.previous = timer
				timer.next = iter
				timer.previous = previous
				if self.head == iter then 
					self.head = timer
				end
				-- self:print("add", timer)
				return 
			end
			last = iter
			iter = iter.next
		end

		if last == nil then 
			self.head = timer
		else
			last.next = timer
			timer.previous = last
		end
		-- self:print("add", timer)
	end, 

	remove = function (self, timer)
		local previous = timer.previous
		local next = timer.next
		local contains = false
		if previous ~= nil then 
			previous.next = next
			contains = true
		end
		if next ~= nil then 
			next.previous = previous
			contains = true
		end
		if contains then 
			self.size = self.size - 1
			if timer == self.head then 
				self.head = next
			end
			timer.previous = nil 
			timer.next = nil
			-- self:print("remove", timer)
		end
	end, 

	contains = function (self, timer)
		if timer.scheduler ~= self then 
			return false
		end
		if timer ~= self.head then 
			if timer.next == nil and timer.previous == nil then 
				return false
			end
		end
		return true
	end, 

	update = function (self, dt)
		self.time = self.time + dt
		local node = self.head

		while node ~= nil do 
			if node.time > self.time then 
				break
			end
			self.executing = node
			node.time = node.time + node.interval
			self:remove(node)
			node:active()
			if node.enabled and not self:contains(node) then 
				self:add(node)
			end
			self.executing = nil
			node = self.head
		end
	end, 
}
