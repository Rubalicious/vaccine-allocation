using Clp, CSV, JuMP, DataFrames, Plots

count = 0
# fill a dictionary of real data
Infection=Dict()
for filename in readdir("./Data/")
    Infection[chop(filename, tail=4)] = CSV.read("./Data/$(filename)")
    global count = count+1
end


function vaccine_effect(I, x)
    maxI = last(I.Infected)
    dI = [I.Infected[s+1]-I.Infected[s] for s in 1:(length(I.Infected)-1)]

    maxdI = maximum(dI)
    normdI = [e/maxdI for e in dI]

    # vaccine effect
    Iv = [1-(maxI-x)/maxI for x in I.Infected]
    dIv = [Iv[s+1]-Iv[s] for s in 1:(length(I.Infected)-1)]

    vaccinated = [normdI[s]*(1-(normdI[s]-dIv[s])) for s in 1:(length(I.Infected)-2)]

    if x == 1
        global effect = sum(vaccinated)

    elseif x == 0
        global effect = sum(normdI)
    end
    return effect
end
# effect = vaccine_effect(Infection["Mohave"],1)
# println(effect)


# r - return on investment for each portfolio asset
# r_{ij} = return of ith asset on jth day
# Return = []



# Y - reference outcome
#df = CSV.read("./data/0DJI.csv")[!,"AdjClose"]
#Reference = [a-b for a in df, b in df]

N = count # number of counties
B = 100000 # Budget for vaccines
C = 20 # cost per vaccine

# p_j = probability that return of ith asset on jth day
#Probability = [1/N for i in range(1, N, step=1)]

model = Model(Clp.Optimizer)

# x - choice of county
@variable(model, x[1:N] >= 0)

@variable(model, n[1:N] >= 0)

@objective(model, Min,
                 sum( vaccine_effect(Infection[county[2]], x[county[1]]) for county in enumerate(keys(Infection)) )
)
@constraint(model, [i in 1:N], C*n[i]/B <= 1)
@constraint(model, [i in 1:N], C*sum(n[i]) <= B)

optimize!(model)
x_opt = [value(x[i]) for i in 1:N]
n_opt = [value(n[i]) for i in 1:N]


println()
println("Optimal objective = $(objective_value(model))")
println("x = ", x_opt)
println("n = ", n_opt)
