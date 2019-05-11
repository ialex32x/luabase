
return {
    member = function (obj, mem)
        return function (...)
            obj[mem](obj, ...)
        end
    end, 

    -- 正向追加参数
    make = function (fn, obj)
        return function (...)
            fn(obj, ...)
        end
    end, 

    -- 逆向追加参数
    rmake = function (fn, obj)
        return function (...)
            local args = { ... }
            table.insert(args, obj)
            fn(unpack(args))
        end
    end, 

    assign = function (obj, key, value)
        return function ()
            obj[key] = value
        end
    end, 
}
