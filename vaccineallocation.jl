using JuMP, Clp, CSV

count = 0
# println(count)
# readdir("./data/")
Return=[]
for filename in readdir("./data/")
    # println(filename)
    df = CSV.read("./data/$(filename)")
    list = [a-b for a in df["AdjClose"], b in df["AdjClose"]]
    # println(length(list))
    append!(Return,[list])
    global count = count+1
    # print("\n")
end
println("files read in")
# print("\n")
# print(count)
# print(df["AdjClose"])


# r - return on investment for each portfolio asset
# r_{ij} = return of ith asset on jth day
# Return = []



# Y - reference outcome
df = CSV.read("./data/0DJI.csv")[!,"AdjClose"]
Reference = [a-b for a in df, b in df]
# n = number of investment assets
n = count
N = length(Return[1])
# p_j = probability that return of ith asset on jth day
Probability = [1/N for i in range(1, N, step=1)]

model = Model(Clp.Optimizer)

# x - amount of each portfolio asset
@variable(model, x[1:n] >= 0)

@variable(model, w[1:N, 1:N] >= 0)

@objective(model, Min,
                  sum(Probability[j]*sum(Return[i,j]*x[i] for i in 1:n) for j in 1:N)
)

@constraint(model, [i in 1:n], sum(x[i]) <= 1)
@constraint(model, [j in 1:N], sum(Probability[k]*(w[j,k]-max(0,(Reference[j]-Reference[k]))) for k in 1:N) <= 0 )
@constraint(model, [j in 1:N, k in 1:N], Reference[j]-sum(Return[i,k]*x[i] for i in 1:n)<=w[j,k])


optimize!(model)
x_opt = [value(x[i]) for i in 1:n]
# w_opt = [value(w[i,j]) for i in 1:3, j in 1:3]


println()
println("Optimal objective = $(objective_value(model))")
println("x = ", x_opt)
# println("w = ", w_opt)
