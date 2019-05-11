-- 参考 cocos 的事件分发的 lua 代码

return class {
    typename = "Events", 

    ctor = function (self)
        self.next_id = 0
        self.listeners = {}
        self.count = {}
    end, 

    -- 获取指定事件的监听者数量
    sizeof = function (self, name)
        local size = self.count[name]
        return size or 0
    end, 

    -- 同 add
    on = function (self, name, listener)
        return self:add(name, listener)
    end, 

    -- 添加监听者, 且该监听者触发一次后自动解除
    once = function (self, name, listener)
        return self:add(name, listener, true)
    end, 

    -- 同 remove
    off = function (self, name, listener)
        return self:remove(name, listener)
    end, 

    -- 添加监听, oneshot 指定是否触发后自动解除
    add = function (self, name, listener, oneshot)
        local list = self.listeners[name]
        if list == nil then 
            list = {}
            self.listeners[name] = list
        end

        local id = tostring(self.next_id)
        self.next_id = self.next_id + 1
        self.count[name] = (self.count[name] or 0) + 1
        list[id] = {
            action = listener, 
            oneshot = oneshot,
        }
        return id
    end, 

    -- 解除监听, del_id 可以传监听 id, 或者监听者对象本身 (传id的效率更高)
    remove = function (self, name, del_id)
        local list = self.listeners[name]
        if list == nil then 
            return false 
        end

        -- 传入参数为 监听器id
        if type(del_id) == "string" then 
            if list[del_id] then 
                list[del_id] = false
                self.count[name] = self.count[name] - 1
                return true
            end
        else
            -- 传入参数为 function
            for id, listener in pairs(list) do
                if listener and listener.action == del_id then 
                    self.count[name] = self.count[name] - 1
                    list[id] = false
                    return true
                end
            end
        end
        return false
    end, 

    -- 清空所有监听
    wipe = function (self)
        self.listeners = {}
        self.count = {}
    end, 

    -- 解除指定名字的所有监听
    clear = function (self, name)
        self.listeners[name] = nil
        self.count[name] = 0
    end, 

    -- 触发事件
    dispatch = function (self, name, ...)
        local list = self.listeners[name]
        if list == nil then
            return
        end
        local garbage

        for id, listener in pairs(list) do
            if listener then 
                if listener.oneshot then 
                    list[id] = false
                    self.count[name] = self.count[name] - 1
                    if not garbage then 
                        garbage = { id }
                    else 
                        table.insert(garbage, id)
                    end
                end
                listener.action(...)
            end
        end

        if garbage then 
            for i = 1, #garbage do 
                local id = garbage[i]
                if not list[id] then 
                    list[id] = nil
                    -- print("collect garbage slot", id)
                end
            end
        end
    end, 
}
