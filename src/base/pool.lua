--[[
    使用范例：

    local assetPath = "Assets/Arts/dixing/pool_test.prefab"
    local pool = require("base.pool").new()
    pool:prepare(assetPath, 2)

    local inst1 = pool:instantiate(assetPath)
    local inst2 = pool:instantiate(assetPath)

    print("destroy 1 after 3s")
    coroutine.yield(WaitForSeconds(3))
    inst1:destroy()
    print("inst 3 after 3s")
    coroutine.yield(WaitForSeconds(3))
    local inst3 = pool:instantiate(assetPath)
    print("destroy 3 after 3s")
    coroutine.yield(WaitForSeconds(3))
    inst3:destroy()

    print("destroy pool after 3s: 释放对象池管理的所有实例")
    coroutine.yield(WaitForSeconds(3))
    pool:destroy()
]]

-- local setmetatable = require("fenix.__gc")
local uobject = class {
    ctor = function (self, base, pool)
        self.__base = base
        self.__pool = pool
    end, 

    parent = {
        getter = function (self)
            return self:GetParent()
        end, 
        setter = function (self, newValue)
            self:AttachTo(newValue)
        end,
    }, 

    equals = function (self, other)
        return self.__base == other 
    end, 

    destroy = function (self, is_force_destroy)
        if self.__pool then 
            if is_force_destroy then 
                self.__pool:force_destroy(self)
            else
                self.__pool:destroy(self)
            end
        else
            Object.DestroyImmediate(self)
        end
    end, 
}

local PoolContainerClass = setmetatable({}, {
    __call = function (self, ...)
        return self.new(...)
    end, 
})

local asset_wrap_methods = {
    is_loading = function (self)
        return self._asset and not self._asset.isDone
    end, 

    is_done = function (self)
        return not self:is_loading()
    end, 

    preallocate = function (self)
        if self._asset and self._asset.isDone then 
            local instances = {}
            for i = 1, self._poolSize do 
                local instance = self:instantiate()
                --print(string.format("pool %s %d/%d %s", self._assetPath, i, self._poolSize, tostring(instance)))
                table.insert(instances, instance)
            end

            for _, instance in ipairs(instances) do 
                self:destroy(instance)
            end
        end
    end,

    instantiate = function (self)
        local instance

        -- 尝试从对象池中取对象
        local cache_size = #self._cache
        -- print("cache size:" .. cache_size)
        while cache_size > 0 do
            -- print(string.format("从对象池实例化资源: %s (%d)", self._assetPath, cache_size))
            instance = self._cache[cache_size]
            table.remove(self._cache, cache_size)
            cache_size = cache_size - 1
            if instance ~= nil then 
                break
            end
        end

        -- 否则从原型实例化
        if instance == nil and self._asset ~= nil then 
            local prototype = self._asset:Get()

            if prototype ~= nil then 
                instance = Object.Instantiate(prototype)
                if instance ~= nil then 
                    instance:SetParent(self._container.transform)
                    --print("从原型实例化资源: " .. self._assetPath)
                    local handle = instance:AddComponent(Fenix.Assets.AssetHandle)
                    handle:SetAsset(self._asset)
                    instance = uobject.new(instance, self)
                    self._objects:add(instance)
                end
            else
                -- asset 没有加载完成
                instance = GameObject()
                instance:SetParent(self._container.transform)
                local loader = instance:AddComponent(Fenix.Assets.PrefabLoader)
                instance = uobject.new(instance, self)
                loader:Load(self._assetPath, nil)
                self._objects:add(instance)
            end
        end

        -- 初始化对象
        if instance ~= nil then 
            -- print("instantiate: " .. self._assetPath)
            if self._active then 
                instance:SetActiveEx(true, self._particleSystem)
            end
        end

        return instance
    end, 

    -- 销毁实例，可能进对象池
    destroy = function (self, instance)
        if #self._cache >= self._poolSize then 
            self:force_destroy(instance)
        else
            if self._active then
                instance:SetActiveEx(false, self._particleSystem)
            end
            instance:SetParent(self._container.transform)
            table.insert(self._cache, instance)
            -- print("放进对象池: " .. tostring(instance) .. ", #" .. #self._cache .. "/" .. self._poolSize)
        end
    end, 

    -- 强行销毁实例
    force_destroy = function (self, instance)
        if instance then 
            -- print("实际销毁资源实例: " .. self._assetPath)
            -- print(instance)
            self._objects:remove(instance)
            Object.DestroyImmediate(instance)
        end
    end, 

    -- 释放所有实例
    release = function (self)
        -- print("release #" .. #self._cache)
        self._objects:foreach(function (obj)
            self:force_destroy(obj)
        end)
        self._cache = {}
        self:_remove_ref()
    end, 

    _remove_ref = function (self)
        if self._asset ~= nil then 
            self._asset:RemoveRef()
            self._asset = nil
        end    
    end, 
}

local asset_wrap_metatable = {
    __index = function (self, key)
        return asset_wrap_methods[key]
    end, 
    -- __gc = function (self)
    --     self:_remove_ref()
    -- end, 
}

local pool_wrap_metatable = {
    __index = PoolContainerClass, 
    -- __gc = function (self)
    --     self:release()
    -- end, 
}

local function parse_bool(value, default_value)
    if value == nil then 
        return default_value
    end
    return value
end

local function parse_bool2(value1, value2, default_value)
    if value1 == nil then 
        if value2 == nil then 
            return default_value
        end
        return value2
    end
    return value1
end

local function genAssetWrapper(container, assetPath, poolSize, active, particleSystem)
    local pool_t = {}
    pool_t._container = container
    pool_t._active = parse_bool2(active, container.active, true)
    pool_t._particleSystem = parse_bool(particleSystem, false)
    -- print(assetPath, pool_t._active, pool_t._particleSystem)
    pool_t._assetPath = assetPath
    pool_t._poolSize = poolSize or container.defaultPoolSize
    pool_t._asset = Fenix.App.GetPackageManager():GetAsset(assetPath, GameObject, container.sync)
    pool_t._cache = {}
    pool_t._objects = require("base.list").new()
    setmetatable(pool_t, asset_wrap_metatable)
    return pool_t
end

function PoolContainerClass.new(args)
    local cluster_t = { 
        pools = {}, 
        sync = args.sync or false, 
        active = args.active, 
        transform = args.transform, 
        defaultPoolSize = args.size or 5, 
    }
    setmetatable(cluster_t, pool_wrap_metatable)
    return cluster_t
end

function PoolContainerClass:wait_prepare(assetPath, poolSize, args)
    local pool = self.pools[assetPath]
    if pool == nil then 
        pool = genAssetWrapper(self, assetPath, poolSize, args and args.active, args and args.particleSystem)
        self.pools[assetPath] = pool
        while pool:is_loading() do 
            coroutine.yield(nil)
        end
        pool:preallocate()
    end
    return pool
end

-- active: 是否需要切换 Active 状态
function PoolContainerClass:prepare(assetPath, poolSize, args)
    local pool = self.pools[assetPath]
    if pool == nil then 
        pool = genAssetWrapper(self, assetPath, poolSize, args and args.active, args and args.particleSystem)
        self.pools[assetPath] = pool
        pool:preallocate()
    end
    return pool
end 

-- 释放指定路径资源的对象池
function PoolContainerClass:destroy(...)
    local count = select("#", ...)
    if count == 0 then 
        for _, pool in pairs(self.pools) do 
            pool:release()
        end
        self.pools = {} 
        return
    end
    for i = 1, count do 
        local assetPath = select(i, ...)
        local pool = self:get(assetPath)
        if pool then 
            pool:release()
            self.pools[assetPath] = nil
        end
    end
end 

function PoolContainerClass:get(assetPath)
    return self.pools[assetPath]
end

-- 根据 Fenix.Assets.AssetHandle 查找对象池
function PoolContainerClass:query(handle)
    return handle and self.pools[handle.assetPath]
end

function PoolContainerClass:instantiate(assetPath, optPoolSize)
    if assetPath ~= nil and assetPath ~= "" then 
        return self:prepare(assetPath, optPoolSize):instantiate()
    end
end 

return PoolContainerClass
