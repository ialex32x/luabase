--[[

			local mgr = require("bt.manager").new()
			local seq = require("bt.sequence").new(2, 
				mgr:require("bt.call", 3, function ()
					print("delay call")
				end
			))
			mgr:add("test", seq)
			
			local inst = mgr:get("test")

			if inst:enter() then 
				while inst:update(Time.deltaTime) == inst.states.RUN do 
					coroutine.yield(nil)
				end
			end
			print("end of bt")    
]]

return class {
    typename = "行为管理器", 

    ctor = function (self)
        self.trees = {}
    end, 

    add = function (self, name, tree)
        local bucket = self.trees[name]
        
        if bucket == nil then 
            bucket = {}
            self.trees[name] = bucket
        end
        table.insert(bucket, tree)
        tree.__mgr = self
    end, 

    get = function (self, name, ctx)
        local bucket = self.trees[name]
        if bucket then
            local size = #bucket
            if size > 1 then 
                local tree = table.remove(bucket)
                tree:setContext(ctx)
                return tree
            elseif size == 1 then 
                local tree = bucket[1]:clone()
                tree:setContext(ctx)
                return tree
            end
        end
        return nil
    end, 

    require = function (self, name, ...)
        return require(name).new(...)
    end,

    destroy = function (self)

    end, 
}