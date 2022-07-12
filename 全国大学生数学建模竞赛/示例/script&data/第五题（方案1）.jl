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
     106, 96,  94,  99,  109, 99,  96,  102,
     113, 103, 102, 109, 121, 112, 112, 119] # 需求空闲艇
n = 104 # 旧周数
nn = length(z) # 新周数

temp = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 
        22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 
        34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 
        48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61,
        62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 
        76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 
        90, 91, 92, 93,94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104,
        106, 107, 108, 109, 110, 111, 112] # 不包括105



#----------------------------------------------------------------#
N = 4
#------------艇-----------
ĉ = [0, 5, 10, 1000]
û = [0, 1000, 1900, 160300]
@variable(m, 0 <= c[1:nn] <= 1000, Int) # 第i周购买及调试艇数
@variable(m, u[1:(nn-1)])
@variable(m, 0 <= λ[1:N, 1:(nn-1)] <= 1)
for k in temp
    if k > n
        @constraints(m, begin
        c[k] == sum(ĉ[i] * λ[i, k-1] for i in 1:N)
        u[k-1] == sum(û[i] * λ[i, k-1] for i in 1:N)
        sum(λ[:, k-1]) == 1
        λ[:,k-1] in SOS2()
        end)
    else
        @constraints(m, begin
        c[k] == sum(ĉ[i] * λ[i, k] for i in 1:N)
        u[k] == sum(û[i] * λ[i, k] for i in 1:N)
        sum(λ[:, k]) == 1
        λ[:,k] in SOS2()
        end)
    end
end
#------------手-----------
b̂ = [0, 20, 40, 1000]
v̂ = [0, 2000, 3800, 80600]
N = length(ĉ)
@variable(m, 0 <= b[1:nn] <= 1000, Int) # 第i周购买及训练新手数
@variable(m, v[1:(nn-1)])
@variable(m, 0 <= μ[1:N, 1:(nn-1)] <= 1)
for k in temp
    if k > n
        @constraints(m, begin
        b[k] == sum(b̂[i] * μ[i, k-1] for i in 1:N)
        v[k-1] == sum(v̂[i] * μ[i, k-1] for i in 1:N)
        sum(μ[:, k-1]) == 1
        μ[:,k-1] in SOS2()
        end)
    else
    @constraints(m, begin
        b[k] == sum(b̂[i] * μ[i, k] for i in 1:N)
        v[k] == sum(v̂[i] * μ[i, k] for i in 1:N)
        sum(μ[:, k]) == 1
        μ[:,k] in SOS2()
        end)
    end
end
#----------------------------------------------------------------#

# 声明变量
@variable(m, x[1:n] >= 0, Int) # 第i周开始时空闲手数
@variable(m, y[1:n] >= 0, Int) # 第i周开始时空闲艇数
@variable(m, a[1:n] >= 0, Int) # 第i周训练熟手数
@variable(m, w[1:nn] >= 0, Int) # 第i周单周成本

# 目标函数
@objective(m, Min, sum(w))

# 添加约束
@constraint(m, x[1] == 50)
@constraint(m, y[1] == 13)
for i in 1:n
    @constraint(m, 4z[i] <= x[i])
    @constraint(m, z[i] <= y[i])
    @constraint(m, b[i] <= 20a[i])
    if i == 1
        @constraint(m, w[i] == 
        u[i] + 
        v[i] + 
        5(x[i] - 4z[i] - a[i]) + 
        10(y[i] - z[i]) + 
        10(a[i] + b[i]))
    else
        if i == 2
            @constraint(m, x[i] == x[i-1] - 4z[i-1] + b[i-1])
        else
            @constraint(m, x[i] == x[i-1] - 4z[i-1] + b[i-1] + 4(z[i-2] - round(0.1z[i-2], RoundNearestTiesAway)))
        end
        @constraint(m, y[i] == y[i-1] - round(0.1z[i-1], RoundNearestTiesAway) + c[i-1])
        @constraint(m, w[i] == 
            u[i] + 
            v[i] + 
            5(x[i] - 4z[i] - a[i] + 4(z[i-1] - round(0.1z[i-1], RoundNearestTiesAway))) + 
            10(y[i] - z[i]) + 
            10(a[i] + b[i]))
    end
end
#-----------------------------------------------------#
# 第105周
@variable(m, xxx >= 0, Int)
@variable(m, yyy >= 0, Int)
@constraint(m, 4z[105] <= xxx)
@constraint(m, z[105] <= yyy)
@constraint(m, xxx == b[105] + x[105-1] - 4z[105-1] + b[105-1] + 4(z[105-2] - round(0.2z[105-2], RoundNearestTiesAway)))
@constraint(m, yyy == c[105] + x[105-1] - round(0.1z[105-1], RoundNearestTiesAway) + c[105-1] + c[105])


@constraint(m, w[105] == 
            300c[105] + 
            150b[105] + 
            5(xxx - 4z[105] + 4(z[105-1] - round(0.2z[105-1], RoundNearestTiesAway))) + 
            10(yyy - z[105]))

# 后7周
@variable(m, xx[1:(nn-n-1)] >= 0, Int) # 第105+ii周开始时空闲手数
@variable(m, yy[1:(nn-n-1)] >= 0, Int) # 第105+ii周开始时空闲艇数
@variable(m, aa[1:(nn-n-1)] >= 0, Int) # 第105+ii周训练熟手数

for i in 1:(nn-n-1)
    @constraint(m, 4z[n+1+i] <= xx[i])
    @constraint(m, z[n+1+i] <= yy[i])
    @constraint(m, b[n+1+i] <= 20aa[i])
    if i == 1
        @constraint(m, xx[i] == xxx - 4z[n+1+i-1] + 4(z[n+1+i-2] - round(0.1z[n+1+i-2], RoundNearestTiesAway)))
        @constraint(m, yy[i] == yyy - round(0.1z[n+1+i-1], RoundNearestTiesAway))
        @constraint(m, w[n+1+i] == 
        u[n+i] + 
        v[n+i] + 
        5(xx[i] - 4z[n+1+i] - aa[i] + 4(z[n+1+i-1] - round(0.1z[n+1+i-1], RoundNearestTiesAway))) + 
        10(yy[i] - z[n+1+i]) + 
        10(aa[i] + b[n+1+i]))
    else
    @constraint(m, xx[i] == xx[i-1] - 4z[n+1+i-1] + b[n+1+i-1] + 4(z[n+1+i-2] - round(0.1z[n+1+i-2], RoundNearestTiesAway)))
    @constraint(m, yy[i] == yy[i-1] - round(0.1z[n+1+i-1], RoundNearestTiesAway) + c[n+1+i-1])
    @constraint(m, w[n+1+i] == 
        u[n+i] + 
        v[n+i] + 
        5(xx[i] - 4z[n+1+i] - aa[i] + 4(z[n+1+i-1] - round(0.1z[n+1+i-1], RoundNearestTiesAway))) + 
        10(yy[i] - z[n+1+i]) + 
        10(aa[i] + b[n+1+i]))
    end
end


optimize!(m)

println("\n#-------------------------第五题--------------------------#")
println(solution_summary(m))

# 第1-104周结果
println("周次\t\t购艇\t购手\t养手\t养艇\t训手\t成本")
for i in [12, 26, 52, 78, 101, 102, 103, 104]
    print("第 $i 周, \t")
    l = [c[i], b[i], 
         x[i] - 4z[i] - a[i] + 4(z[i-1] - round(0.1z[i-1], RoundNearestTiesAway)), 
         y[i] - z[i], a[i] + b[i], w[i]]
    for j in l
        print(round(Int, (value(j))), ", \t")
    end
    print("\n")
end

# 第105周结果
println("\n周次\t\t购艇\t购手\t养手\t养艇\t训手\t成本")
print("第 105 周, \t")
l = [c[105], b[105], 
     xxx - 4z[105] + 4(z[105-1] - round(0.2z[105-1], RoundNearestTiesAway)),
     yyy - z[105], 0, w[105]]
for j in l
    print(round(Int, (value(j))), ", \t")
end
print("\n")

# 第106-112周结果
for i in 106:112
    print("第 $i 周, \t")
    l2 = [c[i], b[i], 
         xx[i-105] - 4z[i] - aa[i-105] + 4(z[i-1] - round(0.1z[i-1], RoundNearestTiesAway)),
         yy[i-105] - z[i], aa[i-105] + b[i], w[i]]
    for j in l2
        print(round(Int, (value(j))), ", \t")
    end
    print("\n")
end

# 总结果
ll = [sum(c), 
      sum(b), 
     (
         sum(x - 4z[1:104] - a) + 
         sum(4(z[2:n-1] - map(x -> round(x, RoundNearestTiesAway), 0.1z[2:n-1]))) +
         xxx - 4z[105] + 4(z[105-1] - round(0.2z[105-1], RoundNearestTiesAway)) + 
         sum(xx[1:7] - 4z[106:112] - aa[1:7] + 4(z[105:111] - map(x -> round(x, RoundNearestTiesAway), 0.1z[105:111])))
     ),
     (sum(y - z[1:104]) + yyy - z[105] + sum(yy[1:7] - z[106:112])), 
     (sum(a + b[1:104]) + 0 + sum(aa[1:7] + b[106:112])), 
     sum(w)]
     
for k in [1]
    print("1-112周（总计）, \t")
    for i in ll
        print(round(Int, value(i)), ",\t")
    end
end


