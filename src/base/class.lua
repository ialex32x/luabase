--[[
    super 基类 (可以是table, 表示存在多个基类)
    ctor 构造函数, 不提供是自动产生一个空白的

    类关键字
    __index 类本身的查找表
    new 实例创建方法, 或者也可以通过 __call 元方法实例化

    实例关键字
    __base 包装了一个外部实例, 通常用于扩展native class 实例

代码范例
    local uobject = class {}
    assert(uobject.new().class == uobject)
    assert(uobject == uobject.class)

    local c1 = class { typename = "c1" }
    local c2 = class { typename = "c2", super = c1 }
    local c3 = class { typename = "c3", super = c2 }
    local d1 = class { typename = "d1" }
    local d2 = class { typename = "d2" }

    local e1 = class { typename = "e1", supers = {d1, c2} }
    local e2 = class { typename = "e2", super = e1 }

    print(c3:isSubClassOf(c1))
    print(c2:isSubClassOf(c1))
    print(c3():isSubClassOf(c1))

    print(d1:isSubClassOf(c2))
    print(d1():isSubClassOf(c2))

    print(c1:isSubClassOf(c2))
    print(c1():isSubClassOf(c2))

    print("e1")
    print(e1:isSubClassOf(d2))
    print(e1:isSubClassOf(d1))
    print(e1:isSubClassOf(c1))
    print(e1:isSubClassOf(c2))

    print("e2")
    print(e2:isSubClassOf(d2))
    print(e2:isSubClassOf(d1))
    print(e2:isSubClassOf(c1))
    print(e2:isSubClassOf(c2))

    print(e2:isSubClassOf(class.class))

    local fc1 = class {
        ctor = function (self)
            print("构造")
        end, 

        finalize = function (self)
            print("析构") -- 在lua回收此对象时触发
        end, 
    }

    local f1 = fc1()
    f1 = nil
    collectgarbage()
]]
local __run_features = function (cls, feature)
    if type(feature) == "function" then 
        local status, results = pcall(function (c, f) f(c) end, cls, feature)
        if not status then 
            print("add feature failed", cls, feature)
        end
    end
end

local __runtime = {}
local __class = setmetatable({}, {
    __index = __runtime, 

    -- 创建 class 
    __call = function (self, cls)
        local cls_meta = {}

        cls_meta.__call = cls.__call
        if cls.__index ~= nil then 
            -- 如果 class 定义了自己的 __index 尝试代理未知的key请求
            cls_meta.__index = function (self, key)
                local val = cls[key]
                if val ~= nil then 
                    if type(val) == "table" then
                        local getter = val.getter
                        if getter then 
                            return getter(self)
                        end
                    end
                    return val
                end
                val = cls.__index(self, key)
                if val ~= nil then 
                    return val
                end
                local base = rawget(self, "__base")
                if base then
                    if cls.__unsafe then 
                        return base[key]
                    else
                        local status, results = pcall(function (t, k) return t[k] end, base, key) 
                        if status then 
                            return results
                        end
                    end
                end
                return nil
            end
        else
            cls_meta.__index = function (self, key)
                local val = cls[key]
                if val ~= nil then 
                    if type(val) == "table" then
                        local getter = val.getter
                        if getter then 
                            return getter(self)
                        end
                    end
                    return val
                end
                local base = rawget(self, "__base")
                if base then
                    if cls.__unsafe then 
                        return base[key]
                    else
                        local status, results = pcall(function (t, k) return t[k] end, base, key) 
                        if status then 
                            return results
                        end
                    end
                end
                return nil
            end
        end

        cls_meta.__newindex = function (self, key, value)
            local func = cls[key]
            if type(func) == "table" then
                local setter = func.setter
                if type(setter) == "function" then  
                    setter(self, value) 
                    return
                end
                if func.getter ~= nil then
                    -- 只有getter, 没有setter, 视作只读属性
                    return  
                end
            end
            -- HH, 2017.2.6, 尝试操作本地类的属性赋值操作
            -- 注意，如果字段本身存在，但实际执行出现错误，这里逻辑会继续往下，导致在实例table上创建key，
            -- 导致下一次 index 得到的是 instance table 上的 value
            local base = rawget(self, "__base")
            if base then
                local status, results = pcall(function (t, k, v) t[k] = v end, base, key, value) 
                if status then 
                    return 
                end
            end
            rawset(self, key, value)
        end

        local extensions = cls.extensions
        if extensions then 
            local typename = type(extensions)
            if typename == "string" then 
                local extends = dofile(extensions)
                for k, v in pairs(extends) do
                    cls[k] = v
                end
            elseif typename == "table" then 
                for _, extension in ipairs(extensions) do
                    local extends = dofile(extension)
                    for k, v in pairs(extends) do 
                        cls[k] = v
                    end
                end
            end
        end

        local cls_new = function(...)
            local cls_inst = {}
            local instance = setmetatable(cls_inst, cls_meta)
            if cls.finalize then 
                -- print("checkpoint ~finalize")
                local proxy = newproxy(true)
                cls_inst[proxy] = true
                getmetatable(proxy).__gc = function() cls_inst:finalize() end
            end
            instance:ctor(...)
            return instance
        end

        if cls.supers then
            local supers = cls.supers
            setmetatable(cls, {
                __index = function(_, key)
                    for i = 1, #supers do
                        local super_val = supers[i][key]
                        if super_val then return super_val end
                    end
                end, 
                __call = function (self, ...)
                    return cls_new(...)
                end, 
            })
        elseif cls.super then 
            setmetatable(cls, { 
                __index = cls.super,
                __call = function (self, ...)
                    return cls_new(...)
                end, 
            })
        else
            cls.super = __runtime.class
            setmetatable(cls, { 
                __index = __runtime.class, 
                __call = function (self, ...)
                    return cls_new(...)
                end, 
            })  
        end

        if not cls.tostring then 
            local typename = cls["typename"]
            if typename ~= nil then 
                cls.tostring = function (self)
                    return typename .. ":" .. tostring(self)
                end
            else
                cls.tostring = tostring
            end
        end

        cls.class = cls
        cls.new = cls_new

        if cls.__features then 
            if type(cls.__features) == "table" then 
                for k, v in ipairs(cls.__features) do 
                    __run_features(cls, v)
                end
            else
                __run_features(cls, cls.__features)
            end
        end
        return cls
    end, -- end of class __call
})

__runtime.class = __class {
    ctor = function (self)
    end, 

    -- 是否是一个类定义
    isClass = function (self)
        return rawget(self, "class")
    end, 

    -- 是否是一个类实例
    isClassInstance = function (self) 
        return rawget(self, "class") == nil and self.class ~= nil
    end, 

    -- 是否从指定类继承 (实例与类型调用该接口的方式一致)
    isSubClassOf = function (self, other)
        if self.class.supers then 
            for _, super_class in ipairs(self.class.supers) do 
                if super_class == other or (super_class and super_class:isSubClassOf(other)) then 
                    return true
                end
            end
            return false
        else
            local super_class = self.class.super
            return super_class == other or (super_class and super_class:isSubClassOf(other) or false)
        end
    end, 
}

return __class
