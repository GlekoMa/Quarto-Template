using JuMP, GLPK

# 建立模型
m = Model(GLPK.Optimizer)

# 已知变量
z = [11, 5, 4, 7, 16, 6, 5, 7] # 需求空闲艇
n = length(z) # 周数

# 声明变量
@variable(m, x[1:n] >= 0, Int) # 第i周开始时空闲手数
@variable(m, y[1:n] >= 0, Int) # 第i周开始时空闲艇数
@variable(m, a[1:n] >= 0, Int) # 第i周训练熟手数
@variable(m, b[1:n] >= 0, Int) # 第i周购买及训练新手数
@variable(m, c[1:n] >= 0, Int) # 第i周购买及调试艇数
@variable(m, w[1:n] >= 0, Int) # 第i周单周成本

# 目标函数
@objective(m, Min, sum(w))

# 添加约束
@constraint(m, x[1] == 50)
@constraint(m, y[1] == 13)
for i in 1:n
    @constraint(m, 4z[i] <= x[i])
    @constraint(m, z[i] <= y[i])
    @constraint(m, b[i] <= 10a[i])
    if i == 1
        @constraint(m, w[i] == 
        200c[i] + 
        100b[i] + 
        5(x[i] - 4z[i] - a[i]) + 
        10(y[i] - z[i]) + 
        10(a[i] + b[i]))
    else
        if i == 2
            @constraint(m, x[i] == x[i-1] - 4z[i-1] + b[i-1])
        else
            @constraint(m, x[i] == x[i-1] - 4z[i-1] + b[i-1] + 4z[i-2])
        end
        @constraint(m, y[i] == y[i-1] + c[i-1])
        @constraint(m, w[i] == 
            200c[i] + 
            100b[i] + 
            5(x[i] - 4z[i] - a[i] + 4z[i-1]) + 
            10(y[i] - z[i]) + 
            10(a[i] + b[i]))
    end
end

optimize!(m)

println("\n#-------------------------第一题--------------------------#")
println(solution_summary(m))
println("周次\t\t购艇\t购手\t养手\t养艇\t训手\t成本")
for i in 1:8
    print("第 $i 周, \t")
    if i == 1
        l = [c[i], b[i], 
         x[i] - 4z[i] - a[i], 
         y[i] - z[i], a[i] + b[i], w[i]]
        for j in l
            print(round(Int, (value(j))), ", \t")
        end
    else
        l = [c[i], b[i], 
         x[i] - 4z[i] - a[i] + 4z[i-1], 
         y[i] - z[i], a[i] + b[i], w[i]]
        for j in l
            print(round(Int, (value(j))), ", \t")
        end
    end
    print("\n")
end
ll = [sum(c), sum(b), 
      sum(x - 4z - a) + sum(4(z[2:n-1])), 
      sum(y - z), sum(a + b), sum(w)]
print("1-8周（总计）, \t")
for i in ll
    print(round(Int, value(i)), ",\t")
end