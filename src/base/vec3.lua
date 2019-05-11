
return {
    sub = function (a, b)
        return { a[1] - b[1], a[2] - b[2], a[3] - b[3] }
    end, 

    add = function (a, b)
        return { a[1] + b[1], a[2] + b[2], a[3] + b[3] }
    end, 
    
    len = function (a)
        local x, y, z = a[1], a[2], a[3]
        return math.sqrt(x * x + y * y + z * z)
    end, 
}
