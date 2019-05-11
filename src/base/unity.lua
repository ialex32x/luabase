
-- UnityEngine
Time = UnityEngine.Time
Camera = UnityEngine.Camera
Vector2 = UnityEngine.Vector2
Vector3 = UnityEngine.Vector3
Transform = UnityEngine.Transform
Quaternion = UnityEngine.Quaternion
GameObject = UnityEngine.GameObject
Object = UnityEngine.Object
Random = UnityEngine.Random
Application = UnityEngine.Application
Input = UnityEngine.Input
Screen = UnityEngine.Screen
KeyCode = UnityEngine.KeyCode
WaitForSeconds = UnityEngine.WaitForSeconds

-- Fenix <csharp>
MathUtils = Fenix.MathUtils
ObjectCaches = Fenix.ObjectCaches
AssetHelper = Fenix.Assets.AssetHelper
PrefabLoader = Fenix.Assets.PrefabLoader
WaitForInstantiate = Fenix.Assets.AssetHelper.WaitForInstantiate

-- Fenix <lua>
class = require("base.class")
enum = require("base.enum")
locale = require("base.locale")
L = locale
setlocale = function (lang) locale:setlanguage(lang) end

-- logger = require("base.logger")
functor = require("base.functor")
CreateFrame = require("ui.frame").CreateFrame

require("base.json")

-- 将k表中指定的key, 从f表中复制到t表 (t[k] = f[k])
if not table.copy_from_once then 
    table.copy_from_once = function (t, f, k)
        if type(k) == "table" then 
            for _, v in ipairs(k) do 
                if not t[v] then 
                    t[v] = f[v]
                end
            end
        else
            if not t[k] then 
                t[k] = f[k]
            end
        end
    end
end

-- 将 table 格式化成字符串方式返回
if not table.tostring then 
    table.tostring = function (t, depth)
        local tab = string.rep("    ", (depth or 1) - 1) 
        local str = "\n" .. tab .. "{\n"
        for k, v in pairs(t) do 
            local value_str 
            if type(v) == "table" then 
                value_str = table.tostring(v, (depth or 1) + 1)
            else 
                value_str = tostring(v)
            end
            str = str .. tab .. "    " .. "[" .. tostring(k) .. "] = " .. value_str .. ", \n"
        end
        str = str .. tab .. "}\n"
        return str
    end
end

-- lua extensions
if not string.split then 
    string.split = function (strVal, delim)
        assert(type(delim) == "string" and string.len(delim) > 0, "bad delimiter")
        local start = 1
        local results = {}
        -- find each instance of a string followed by the delimiter
        while true do
            local pos = string.find(strVal, delim, start, true) -- plain find
            if not pos then
                break
            end
            table.insert(results, string.sub(strVal, start, pos - 1))
            start = pos + string.len(delim)
        end 
        -- insert final one(after last delimiter)
        table.insert(results, string.sub(strVal, start))
        return results
    end 
end

if not string.ctx then 
    string.ctx = function (ctx)
        return function (key)
            return string.replace_varobj(locale(key), ctx)
        end
    end
    string.vctx = function (ctx, key)
        return string.replace_varobj(locale(key), ctx)
    end
end

if not string.toVec2 then 
    string.toVec2 = function (strVal)
        local xy = string.split(strVal, ",")
        xy[1] = tonumber(xy[1])
        xy[2] = tonumber(xy[2])
        return xy
    end
end

if not string.toVec3 then 
    string.toVec3 = function (strVal)
        local xy = string.split(strVal, ",")
        xy[1] = tonumber(xy[1])
        xy[2] = tonumber(xy[2])
        xy[3] = tonumber(xy[3])
        return xy
    end
end
-- print(unpack(string.toVec3("1,2,3")))

if not string.cache then 
    local cache = {}
    string.cache = function (strVal)
        if strVal == nil then 
            return -1 
        end 
        local index = cache[strVal]
        if index == nil then
            index = ObjectCaches.AddSharedObject(strVal)
            cache[strVal] = index
        end
        return index
    end
end

-- 用法范例:
-- local data = { name = "Tom", age = 20, city = "Shanghai" }
-- print(string.replace_var("你好, 我是{name}. 今年{age}岁. 住在{city}.", function (name)
--     return data[name]
-- end))
-- print(string.replace_var("test ((name)) = (name).", function (name)
--     return "John"
-- end, {"(", ")"}))
if not string.replace_var then 
    string.replace_var = function (text, handler, enclosures)
        return (string.gsub(text, enclosures or "%b{}", function (name)
            return handler(string.sub(name, 2, -2))
        end))
    end
end

if not string.replace_varobj then 
    string.replace_varobj = function (text, obj, enclosures)
        return string.replace_var(text, function (name) 
            local val = obj[name]
            return type(val) == "function" and val() or val
        end, enclosures)
    end
end

if not math.epsilon then 
    math.epsilon = 0.001
end

if not math.rotate then 
    math.rotate = function (vec, degree)
        local angle = math.rad(-degree)
        return { 
            vec[1] * math.cos(angle) - vec[2] * math.sin(angle), 
            vec[1] * math.sin(angle) + vec[2] * math.cos(angle)
        }
    end
end

if not math.div then 
    math.div = function (a, b)
        return b == 0 and 1 or (a / b)
    end
end

if not math.clamp then 
    math.clamp = function (value, min, max)
        return value < min and min or (value > max and max or value)
    end
end

if not math.lerp then 
    math.lerp = function (from, to, ratio)
        return from + (to - from) * ratio
    end
end

if not debug.log then 
    debug.log = print
end

if not debug.profile then 
    debug.profile = function (title, call)
        local time = Time.realtimeSinceStartup
        call()
        debug.log(title, "in", (Time.realtimeSinceStartup - time) * 1000, "ms")
    end
end

table.copy_from_once(debug, require("base.test"), {"testable", "runtests", "deprecated"})

local __uid = 0
local __layers = {}
local __masks = {}
local __self 

__self = {
    events = require("base.events"), 
    list = require("base.list"), 
    pool = require("base.pool"), 
    scheduler = require("base.scheduler"), 
    properties = require("base.properties"), 

    -- 产生一个全局递增序列号
    id = function ()
        __uid = __uid + 1
        return __uid
    end, 

    -- 批量调用所有对象的 destroy
    destroy = function (...)
        for i = 1, select("#", ...) do 
            local obj = select(i, ...)
            if obj and obj.destroy then 
                pcall(function ()
                    obj:destroy()
                end)
            end
        end
    end, 

    print = function (...)
        local str = ""
        for i = 1, select("#", ...) do 
            local obj = select(i, ...)
            local tp = type(obj)
            
            if tp == "table" then 
                for k, v in ipairs(obj) do 
                    str = str .. ", " .. tostring(v)
                end
            else
                str = str .. " " .. tostring(obj)
            end
        end
        print(str)
    end, 

    gc = function ()
        collectgarbage()
        Fenix.App.CollectGarbage()
    end, 

    -- 加载并构造
    new = function (cls, ...)
        return require(cls)(...)
    end, 

    material = function (assetPath)
        return __self.asset(assetPath, UnityEngine.Material)
    end, 

    prefab = function (assetPath)
        return __self.asset(assetPath, UnityEngine.GameObject)
    end, 

    text = function (assetPath)
        return __self.asset(assetPath, UnityEngine.TextAsset)
    end, 

    asset = function (assetPath, assetType)
        return require("base.asset")(assetPath, assetType)
    end,

    assets = function (assets)
        return require("base.assets")(assets)
    end, 

    -- 用uobject包装一个对象
    object = function (native)
        return __self.new("base.uobject", native)
    end, 

    -- 实例化prefab 并用uobject包装
    instantiate = function (prefab)
        return __self.new("base.uobject", Object.Instantiate(prefab))
    end, 

    -- 包装一个表，对该表的无效取值统一返回给定的默认值
    values = function (...)
        local argc = select("#", ...)
        if argc == 1 then 
            local tb = select(1, ...)
            local default_val = tb and tb[1]
            return setmetatable(tb, { 
                __index = function (self, index)
                    return default_val
                end, 
            })
        end
        if argc == 2 then 
            local tb = select(1, ...)
            local default_val = select(2, ...)
            return setmetatable(tb, { 
                __index = function (self, index)
                    return default_val
                end, 
            })
        end
    end, 

    -- 返回一个安全函数表, 对该表取无效值将不会产生执行失败
    functions = function (tb, err)
        return setmetatable(tb, { 
            __index = function (self, index)
                return function () 
                    if err then 
                        print("you've called an invalid script:", index)
                    end
                end
            end, 
        })
    end, 

    -- 提供了layer make的求值 （并在lua缓存）
    -- unity.mask.Default == 1 << valueOf("Default")
    mask = setmetatable({}, {
        __index = function (self, name)
            local find = __masks[name]
            if find == nil then 
                find = Fenix.ConvertUtils.shift(__self.layers[name])
                __masks[name] = find
            end
            return find
        end, 
    }), 

    masks = function (...)
        return __self.layers(...)
    end,

    layer = setmetatable({}, {
        __index = function (self, name)
            return __self.layers[name]
        end, 
    }), 

    -- 提供了字符串到layer值的查询（并在lua缓存）
    -- unity.layers.Default == valueOf("Default")
    -- unity.layers("Default", "UI") == 1 << valueOf("Default") || 1 << valueOf("UI")
    layers = setmetatable({}, {
        __index = function (self, name)
            local find = __layers[name]
            if find == nil then 
                find = UnityEngine.LayerMask.NameToLayer(name)
                __layers[name] = find
            end
            return find
        end, 

        __call = function (self, ...)
            local lv = 0
            local sbor = Fenix.ConvertUtils.sbor
            for i = 1, select("#", ...) do 
                lv = sbor(lv, self[(select(i, ...))])
            end
            return lv
        end, 
    }), 

    deactivator = function (names)
        return function ()
            __self.deactive(names)
        end
    end, 

    deactive = function (names)
        if type(names) == "table" then 
            for k, v in ipairs(names) do 
                local go = GameObject.Find(v)
                if go then 
                    go:SetActive(false)
                end
            end
        else
            local go = GameObject.Find(names)
            if go then 
                go:SetActive(false)
            end
        end
    end, 

    -- 重新载入
    reload = function (name)
        package.loaded[name] = nil
        package.preloaded[name] = nil
        return require(name)
    end, 

    -- 载入模块（即使不存在也不会报错，直接返回nil)
    require = function (name)
        local status, results = pcall(function (mod) return require(mod) end, name)
        -- print(name, status, results)
        return status and results or nil
    end, 

    addSearchPath = function (...)
        for i = 1, select("#", ...) do 
            local path = select(i, ...)
            if type(path) == "string" then 
                SLuaExtensions.AddSearchPath(path)
            else 
                for k, v in ipairs(path) do 
                    SLuaExtensions.AddSearchPath(v)
                end
            end
        end
    end, 

    clamp = function (val, min, max) 
        if val < min then 
            return min
        elseif val > max then 
            return max
        end
        return val
    end,

    lerp = function (v1, v2, ratio)
        local v3 = {}
        for i = 1, #v1 do 
            table.insert(v3, math.lerp(v1[i], v2[i], ratio))
        end
        return v3
    end, 

    lerp2 = function (v1, v2, ratio)
        local v3 = {x = math.lerp(v1.x, v2.x, ratio), y = math.lerp(v1.y, v2.y, ratio)}
        return v3
    end, 
}

return __self
