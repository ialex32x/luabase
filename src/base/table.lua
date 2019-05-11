--移除数组类型的table的元素
function table.removeFromArray(tbl, obj)
    if type(obj) == "function" then
        local func = obj
        for i = 1, #tbl do
            if func(tbl[i]) then
                table.remove(tbl, i)
                return true
            end
        end
    else
        for i = 1, #tbl do
            if tbl[i] == obj then
                table.remove(tbl, i)
                return true
            end
        end
    end

	return false
end

--查找数组类型的table的元素
function table.findInArray(tbl, func)
    for i = 1, #tbl do
        if func(tbl[i]) then
            return tbl[i]
        end
    end

    return nil
end

--查找数组类型的table的元素
function table.findAllInArray(tbl, func)
    local results = {}
    for i = 1, #tbl do
        if func(tbl[i]) then
            table.insert(results, tbl[i])
        end
    end

    return results
end