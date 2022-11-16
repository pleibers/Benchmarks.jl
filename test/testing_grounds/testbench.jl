using Plots
using DynamicalSystems
using DifferentialEquations
using BenchmarkTools
ϵ(std::AbstractFloat)::AbstractFloat = randn() * std

function loop_lorenz!(du, u, p, t)
    σ, ρ, β = p
    du[1] = σ * (u[2] - u[1])
    du[2] = u[1] * (ρ - u[3]) - u[2]
    du[3] = u[1] * u[2] - β * u[3]
    return nothing

end
function lorenz_(;u0=[1.0, 0.0, 0.0], ρ=28.0, σ=10.0, β=8 / 3, p=[], t₀=0.0)::ContinuousDynamicalSystem
    if isempty(p)
        p = [σ, ρ, β]
    else
        p = p
    end
    rhs = (du, u, par, t) -> loop_lorenz!(du, u, par, t)
    return ContinuousDynamicalSystem(rhs, u0, p, t0=t₀)
end


condition(u, t, integrator) = true
affect!(integrator) = set_state!(integrator, get_state(integrator).+ϵ(0.7))
cb = DiscreteCallback(condition, affect!)


# prob = ODEProblem(loop_lorenz!, [0.5,0.5,0.5],(0,100),[10,28,8/3])
# sol = solve(prob, callback=cb, tstops=[40.0])
# u2 = sol(collect(0:0.01:100))
# p2 = plot3d(u2[1, :], u2[2, :], u2[3, :])
# p2=plot(sol)

ds = Systems.lorenz()
diffeq=(alg=Tsit5(), callback=cb)
u1=[1,0,0]
u0s=[u1,[0,10,0]]
pinteg = DynamicalSystems.parallel_integrator(ds,u0s)
integ=DynamicalSystems.integrator(ds, u1)

    # u2 = trajectory(cde_lorenz, 100.0,diffeq)
# p2 = plot3d(u2[:, 1], u2[:, 2], u2[:, 3])




function lorenz(du, u, p, t)
    du[1] = 10.0(u[2] - u[1])
    du[2] = u[1] * (28.0 - u[3]) - u[2]
    du[3] = u[1] * u[2] - (8 / 3) * u[3]
end

function σ_lorenz(du, u, p, t)
    du[1] = 3
    du[2] = 3
    du[3] = 3
end

# prob_sde_lorenz = SDEProblem(lorenz, σ_lorenz, [1.0, 0.0, 0.0], (0.0, 10.0))
# sol = solve(prob_sde_lorenz)   
# p1= plot(sol, idxs=(1, 2, 3))

# # u = sol(collect(0:0.01:10))
# p=plot3d(u[1, :], u[2, :], u[3, :],label="sde")
# plot3d!(u2[:, 1], u2[:, 2], u2[:, 3])
# display(p2)