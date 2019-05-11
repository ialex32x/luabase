--[[
    logger("日志内容") -- 等价于 logger.default.debug(...)
    logger.sys("日志内容") -- 等价于 logger.sys.base(...)
    logger.sys.base("日志内容") -- 等价于 logger.sys.base.debug(...)

    logger.mod("模块名") -- 定义新模块
    logger.mod("模块名").cat("新类别") -- 定义新类别

    local log = logger.get("模块", "类别") -- 获取模块:类别
    log(...)
    log.warn(...)

    --
    DEBUG, INFO, WARN, ERROR, FATAL, DISABLE
    -- 
]]

local enum = require("base.enum")

local levels = enum {
    ["INFO"] = 0,
    ["DEBUG"] = 1,
    ["WARN"] = 2,
    ["ERROR"] = 3,
    ["FATAL"] = 4,
    ["DISABLE"] = 5,
}

local all_module_tab = {}
local out_level = levels.INFO
local app_logger = UnityEngine.Debug

local __string = function (mod, cat, text)
    return "[" .. mod .. "][" .. cat .. "] " .. text
end

local category_mute = {}

local function is_category_open(name)
    return not category_mute[name] 
end

local function concat_all(...)
    -- local argc = select("#", ...)
    local argv = {...}
    local argc = #argv

    if argc == 1 then
        return argv[1] 
    end
    local str = ""
    for i = 1, argc do
        str = str .. " " .. tostring(argv[i]) 
    end
    return str
end

local function define_category(module, category)
    local category_tab = {}
    local method_def

    method_def = {
        on = function () 
            category_mute[category] = false
        end, 

        off = function ()
            category_mute[category] = true
        end, 

        debug = function (...)
            if out_level and out_level <= levels.DEBUG and is_category_open(category) then 
                app_logger.Log(__string(module, category, concat_all(...)))
            end
        end, 

        info = function (...)
            if out_level and out_level <= levels.INFO and is_category_open(category) then 
                app_logger.Log(__string(module, category, concat_all(...)))
            end
        end, 

        log = function (...)
            if out_level and out_level <= levels.INFO and is_category_open(category) then 
                app_logger.Log(__string(module, category, concat_all(...)))
            end
        end, 

        warn = function (...)
            if out_level and out_level <= levels.WARN and is_category_open(category) then 
                app_logger.LogWarning(__string(module, category, concat_all(...)))
            end
        end, 

        error = function (...)
            if out_level and out_level <= levels.ERROR and is_category_open(category) then 
                app_logger.LogError(__string(module, category, concat_all(...)))
            end
        end, 

        fatal = function (...)
            if out_level and out_level <= levels.FATAL and is_category_open(category) then 
                app_logger.LogError(__string(module, category, concat_all(...)))
            end
        end, 

        __index = function (self, k)
            return rawget(method_def, k)
        end, 

        __call = function (self, ...)
            if out_level and out_level <= levels.DEBUG and is_category_open(category) then 
                app_logger.Log(__string(module, category, concat_all(...)))
            end 
        end, 
    }
    setmetatable(category_tab, method_def)
    return category_tab
end

local function define_module(name, category_name)
    local module_tab = all_module_tab[name]
    if module_tab ~= nil then
        return module_tab  
    end
    module_tab = {}
    all_module_tab[name] = module_tab
    if type(category_name) == "table" then 
        for k,v in pairs(category_name) do
            module_tab[k] = define_category(module_tab, v) 
        end
    elseif type(category_name) == "string" then 
        module_tab[category_name] = define_category(module_tab, category_name) 
    end
    local default_cat = module_tab["base"] or define_category(module_tab, "base")
    module_tab.category = function (cat_name)
        local cat = module_tab[cat_name] 

        if cat then
            return cat 
        end
        cat = define_category(module_tab, cat_name)
        module_tab[cat_name] = cat
        return cat
    end
    module_tab.cat = module_tab.category
    setmetatable(module_tab, {
        __index = function (self, k)
            return default_cat[k]
        end, 

        __call = function (self, ...)
            default_cat(...)
        end, 
    })
    return module_tab
end

local lua_logger

lua_logger = {
    levels = levels,

    off = function ()
        for k, v in pairs(all_category) do 
            category_mute[k] = true
        end
    end, 

    get_level = function ()
        return out_level
    end, 

    set_level = function (level)
        if type(level) == "string" then
            out_level = levels[level]
        else
            out_level = level
        end
    end,

    module = function (mod_name)
        local mod = rawget(lua_logger, mod_name)
        if mod == nil then
            mod = define_module(mod_name)
            rawset(lua_logger, mod_name, mod) 
        end
        return mod
    end,

    get = function (mod_name, cat_name)
        return lua_logger.mod(mod_name).cat(cat_name)
    end, 

    sys     = define_module("系统"), 
    locale  = define_module("本地化"), 
    net     = define_module("网络", {send = "发送", recv = "接受"}),
    ui 		= define_module("UI", {main = "主界面", battle = "战斗界面", test = "界面测试"}), 
    default = define_module("默认"),
}
lua_logger.mod = lua_logger.module
setmetatable(lua_logger, {
    __index = function (self, k)
        return rawget(self, "default")[k]
    end, 

    __call = function (self, ...)
        self.default.base(...)
    end,
})

return lua_logger