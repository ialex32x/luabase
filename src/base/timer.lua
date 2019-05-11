local uid = 1

return class {
	ctor = function (self, scheduler, interval, repeats, handler, immediate)
        self.uid = uid
        uid = uid + 1
        self.scheduler = scheduler
        self.handler = handler
        self.interval = math.max(0.001, interval)
        self.repeats = repeats
        self.immediate = immediate
	end,

    tostring_s = function (self)
        return self.time .. "#" .. self.uid 
    end, 

    tostring = function (self)
        local str = ""
        
        if self.previous then 
            str = str .. "<" .. self.previous:tostring_s() .. ".="
        end
        str = str .. "[" .. self:tostring_s() .. "]"
        if self.next then 
            str = str .. "=." .. self.next:tostring_s() .. ">"
        end
        return str
    end, 

    destroy = function (self)
        self.enabled = false
        self.scheduler = nil
        self.handler = nil
    end, 

    active = function (self)
        if self._enabled then 
            self.repeated = self.repeated + 1
            if self.handler then 
                self.handler(self)
            end
            local onActived = self.onActived
            if onActived then 
                onActived(self)
            end
            if self.repeats > 0 and self.repeated >= self.repeats then 
                self.enabled = false
            end
        end
    end, 

    enabled = {
        getter = function (self)
            return self._enabled
        end, 

        setter = function (self, value)
            if self._enabled ~= value then 
                self._enabled = value
                if value then 
                    self.accumulate = 0
                    self.repeated = 0
                    self.start = self.scheduler.time
                    self.time = self.immediate and self.start or (self.start + self.interval)
                    self.scheduler:add(self)
                else
                    self.scheduler:remove(self)
                end
            end
        end, 
    }, 
}
