using JuMP, CPLEX

# 建立模型
m = Model(CPLEX.Optimizer)

# 已知变量
z = [11,  5,   4,   7,   16,  6,   5,   7,
     13,  6,   5,   7,   12,  5,   4,   6,
     9,   5,   5,   11,  29,  21,  17,  20,
     27,  13,  9,   10,  16,  6,   5,   7,
     11,  5,   5,   6,   12,  7,   7,   10,
     15,  10,  9,   11,  15,  10,  10,  16,
     26,  21,  23,  36,  50,  45,  45,  49,
     57,  43,  40,  44,  52,  43,  42,  45,
     52,  41,  39,  41,  48,  35,  34,  35,
     42,  34,  36,  43,  55,  48,  54,  65,
     80,  70,  74,  85,  101, 89,  88,  90,
     100, 87,  88,  89,  104, 89,  89,  90,
     106, 96,  94,  99,  109, 99,  96,  102] # 需求空闲艇
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
            @constraint(m, x[i] == x[i-1] - 4z[i-1] + b[i-1] + 4(z[i-2] - round(0.2z[i-2], RoundNearestTiesAway)))
        end
        @constraint(m, y[i] == y[i-1] - round(0.2z[i-1], RoundNearestTiesAway) + c[i-1])
        @constraint(m, w[i] == 
            200c[i] + 
            100b[i] + 
            5(x[i] - 4z[i] - a[i] + 4(z[i-1] - round(0.2z[i-1], RoundNearestTiesAway))) + 
            10(y[i] - z[i]) + 
            10(a[i] + b[i]))
    end
end

optimize!(m)

println("\n#---------------------第二题（1-104周）----------------------#")
println(solution_summary(m))
println("周次\t\t购艇\t购手\t养手\t养艇\t训手\t成本")
for i in [12, 26, 52, 78, 101, 102, 103, 104]
    print("第 $i 周, \t")
    l = [c[i], b[i], 
         x[i] - 4z[i] - a[i] + 4(z[i-1] - round(0.2z[i-1], RoundNearestTiesAway)), 
         y[i] - z[i], a[i] + b[i], w[i]]
    for j in l
        print(round(Int, (value(j))), ", \t")
    end
    print("\n")
end
ll = [sum(c), sum(b), 
      sum(x - 4z - a) + sum(4(z[2:n-1] - map(x -> round(x, RoundNearestTiesAway), 0.2z[2:n-1]))), 
      sum(y - z), sum(a + b), sum(w)]
print("1-104周（总计）,")
for i in ll
    print(round(Int, value(i)), ",\t")
end
