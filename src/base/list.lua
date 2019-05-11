-- 列表，移除的对象在列表中占位不删除，只是产生一个 false 空位，下一次分配时重用

return class {
    -- reuse: 是否重用空位
    ctor = function (self, reuse)
        self.free_slots = {}
        self.use_slots = {}
        self.size = 0
        self.reuse = reuse 
    end, 

    -- 返回新加入的对象
    add = function (self, obj)
        local free_id = self.reuse and #self.free_slots or 0
        if free_id > 0 then 
            local free_slot = self.free_slots[free_id]
            table.remove(self.free_slots, free_id)
            self.use_slots[free_slot] = obj
            obj[self] = free_slot
        else
            table.insert(self.use_slots, obj)
            obj[self] = #self.use_slots
        end
        self.size = self.size + 1
        return obj
    end,  

    -- __index = function (self, slot)
    --     return self.use_slots[slot]
    -- end, 

    get = function (self, slot)
        return self.use_slots[slot]
    end, 

    find = function (self, check)
        for i = 1, #self.use_slots do 
            local obj = self.use_slots[i]
            if obj and check(obj) then 
                return obj
            end
        end
    end, 

    -- 成功移除时返回 true
    remove = function (self, obj)
        local slot = obj[self]
        if slot ~= nil then 
            obj[self] = nil
            self.use_slots[slot] = false
            self.size = self.size - 1
            if self.reuse then
                table.insert(self.free_slots, slot)
            end
            return true
        end
        return false
    end, 

    foreach = function (self, callback)
        local token = { stop = false }
        for i = 1, #self.use_slots do 
            local obj = self.use_slots[i]
            if obj then 
                callback(obj, token)
                if token.stop then 
                    return token.result
                end
            end
        end
        return token.result
    end, 

    clear = function (self)
        for i = 1, #self.use_slots do 
            local obj = self.use_slots[i]
            if obj then 
                local slot = obj[self]
                assert(slot == i, "wrong slot")
                obj[self] = nil
                self.use_slots[slot] = false
                self.size = self.size - 1
                if self.reuse then
                    table.insert(self.free_slots, slot)
                end
            end
        end
    end, 

    -- 对所有元素调用 update(dt)
    update = function (self, dt)
        for i = 1, #self.use_slots do 
            local obj = self.use_slots[i]
            if obj then 
                obj:update(dt)
            end
        end
    end, 

    -- 对所有元素调用 destroy
    destroy = function (self)
        for i = 1, #self.use_slots do 
            local obj = self.use_slots[i]
            if obj then 
                obj:destroy()
            end
        end
    end, 
}