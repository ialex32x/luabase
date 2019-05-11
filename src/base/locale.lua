--[[
    使用范例

    -- 直接查询
    print(L"ERR")

    -- ctx 函数化查询
    local ctx = string.ctx { day = "2020-1-1", who = "张三" }
    print(ctx "HELLO")

    -- ctx 查询
    print(string.vctx({day = "today", who = "jack"}, "HELLO"))

    -- 子表查询
    print(L{"CAMP", 1})
]]
return setmetatable({
    languages = {"zhCN", "zhTW", "enUS", "frFR"},
    language = "zhCN", 
    relativePath = "lang/", 
    bundles = {},

    setlanguage = function (self, lang)
        if lang ~= self.language then 
            for k, v in ipairs(self.languages) do 
                if v == lang then 
                    self.language = lang
                    self:reload()
                    return true
                end
            end
        end
        return false
    end, 

    -- 重载所有表
    reload = function (self)
        for k, v in ipairs(self.bundles) do 
            v.values = false
        end
    end, 

    -- 清空所有内容
    clear = function (self)
        self.bundles = {}
    end, 

    -- 确认表存在
    touch = function (self, ...) 
        for i = 1, select("#", ...) do 
            local bundleName = select(i, ...)
            local bi
            for k, v in ipairs(self.bundles) do 
                if v.name == bundleName then 
                    bi = true
                    break
                end
            end
            if not bi then 
                local nt = {
                    name = bundleName, 
                    values = false
                }
                table.insert(self.bundles, nt)
            end
        end
    end, 

    -- 实际载入指定的表
    load = function (self, bundleName)
        self.bundles[bundleName] = self:__load(bundleName) 
    end,

    __load = function (self, bundleName)
        local fullPath = self.relativePath .. bundleName .. "-" .. self.language .. ".lua"
        -- print("load file", fullPath)
        return dofile(fullPath) or {}
    end,

    get = function (self, strid)
        if strid then 
            local value
            for _, bi in ipairs(self.bundles) do 
                local bundleName = bi.name
                local bundleValues = bi.values

                -- print("lookup:", bundleName)
                if not bundleValues then 
                    bundleValues = self:__load(bundleName)
                    bi.values = bundleValues
                end

                if type(strid) == "table" then 
                    value = bundleValues
                    for _, v in ipairs(strid) do 
                        -- print(value, v)
                        value = value[v]
                        if not value then 
                            break
                        end
                    end
                    if value then 
                        return value
                    end
                else 
                    value = bundleValues[strid]
                    if value then 
                        return value
                    end
                end
            end -- end for bundles
        end -- end if strid
    end,
}, {
    __call = function (self, key)
        return self:get(key)
    end, 

    __index = function (self, key)
        return self:get(key)
    end, 
})
