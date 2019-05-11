--[[
用于提供测试单元，以及标记废弃函数的功能

local t_base = class {}
local t = class {
    typename = "my-tester", 
    super = t_base, 

    foo = function (self, a, b)
        print(a, b)
    end, 

    __features = {
        debug.deprecated("foo", "use foo_v2 instead."), 

        debug.testable {
            run = function (self)
                --print("test run")
            end, 

            fail = function (self)
                error("something wrong")
            end, 

            fail2 = function (self)
                print(1 .. nil)
            end, 

            fail3 = function (self)
                assert(false, "assert failed")
            end, 

            check = function (self)
                assert(self:isSubClassOf(t_base), "isSubClassOf?")
                assert(self.class:isClass(), "isClass?")
                assert(not self:isClass(), "() isClass?")
                assert(not self.class:isClassInstance(), "isClassInstance?")
                assert(self:isClassInstance(), "() isClassInstance?")
            end, 
        }, 
    }, 
}

debug.runtests(t) -- 如果指定了具体类, 那么执行该类的测试, 否则执行所有已经注册的类的测试
t():foo(1, 2)
]]

local __tests = {}
local anonymous_str = "<anonymous-class>"

local __traceback__ = function (...)

end

local test_for = function (cls_lit)
    local cls = type(cls_lit) == "string" and require(cls_lit) or cls_lit
    local methods = __tests[cls]
    if not methods then 
        print("===== TESTS: NONE =====")
        return
    end
    local class_typename = cls.typename or anonymous_str
    print("===== TESTS FOR:", class_typename, "=====")
    local passed = 0
    local total = 0
    local inst = cls.new()
    for method_name, method_fn in pairs(methods) do 
        local time = Time.realtimeSinceStartup
        local status, result = xpcall(function () method_fn(inst) end, function (errmsg)
            local time_str = string.format("[%.3fms]", (Time.realtimeSinceStartup - time) * 1000)
            print(time_str, class_typename .. "." .. method_name, ":fail **", errmsg, "\n", debug.traceback())
        end)
        total = total + 1
        if status then 
            passed = passed + 1
            local time_str = string.format("[%.3fms]", (Time.realtimeSinceStartup - time) * 1000)
            print(time_str, class_typename .. "." .. method_name, ":ok")
        end
    end
    print("===== TESTS END:", class_typename, "(" .. passed .. "/" .. total .. ")", "=====")
end

return {
    testable = function (methods)
        return function (cls)
            __tests[cls] = methods
        end
    end,

    runtests = function (cls_only)
        if cls_only then 
            if type(cls_only) == "table" then 
                for k, v in ipairs(cls_only) do 
                    test_for(v)
                end
            else
                test_for(cls_only)
            end
        else
            for k, v in pairs(__tests) do 
                test_for(k)
            end            
        end
    end, 

    deprecated = function (arg1, arg2) 
        local tp = type(arg1)
        if tp == "table" then 
            return function (cls)
                for k, v in pairs(arg1) do 
                    cls[k] = function (...)
                        print((cls.typename or anonymous_str) .. "." .. k, " is deprecated")
                        v(...)
                    end
                end
            end
        else
            return function (cls)
                local v = cls[arg1]
                cls[arg1] = function (...)
                    print((cls.typename or anonymous_str) .. "." .. arg1, " is deprecated.", arg2 or "")
                    v(...)
                end
            end
        end
    end, 
}
