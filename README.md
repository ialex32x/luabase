# luabase 
lua class 等一些写法的封装 <br/>
其中一部分利用了slua __base 的特定用法, 只适用于使用 slua 的项目, 其余大部分是通用的 <br/>
class 是参考 cocos2dx-lua 中实现的class进行了一些修改的版本 <br/>

## enum 
```lua
    local MyEnumType = enum { 
        "a",  -- 自动分配值 (数字)
        "b", 
        "c", 
        ["d"] = "test", -- 强制指定字符串作为值
        ["e"] = 1,      -- 强制指定数字值
    }
    print(MyEnumType.a, MyEnumType.d)
    assert(MyEnumType.a == MyEnumType.a)
    assert(MyEnumType.a ~= MyEnumType.e)
    assert(MyEnumType.d.class == MyEnumType)
    print(MyEnumType.b.rawValue) -- 取得实际值
    print(MyEnumType.rawValue(2) == MyEnumType.b)
```

## class 
```lua
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

    local Shape = class {
        foo = function (self)
            print("Shape.foo")
        end, 
    }
```