using DifferentialEquations
using DynamicalSystems


"""
    generate_trajectories(ds,tmax, transient_T;Δt=0.01, t₀=0.0, PLOT=true)

generate the trajectory of a given ns system

Parameters
----------
ns_model : an initalized dynamical System
t₀ : Start time, default 0 (Float64)
STD : true for a standardized time series
PLOT : If a plot should be done, default true (BOOL)
plot_title : Specifies plot title
save_name : as what to save the file

*Plotting to Figures/*
"""
function generate_trajectories(model::GeneralizedDynamicalSystem, tmax, transient_T::Int; Δt=0.01, t₀=0.0, STD=false, PLOT=true, plot_title="", eval=false, eval_run=0, save_name="", model_name="")
    ts = trajectory(model, tmax; Δt=Δt, Ttr=transient_T, diffeq=(t₀=t₀,))
    u = Matrix(ts)
    u_std = StatsBase.standardize(ZScoreTransform, u, dims=1)

    t = t₀:Δt:tmax
    if PLOT
        if occursin("Paper", model_name)
            uS0 = u_std[findall(x -> x <= 0, t), :]
            uB0 = u_std[findall(x -> x > 0, t), :]
            p = plot3d(uS0[:, 1], uS0[:, 2], uS0[:, 3],
                grid=true,
                xlabel="x", ylabel="y", zlabel="z",
                lc=:red, label="t\$\\leq\$0", linealpha=1, title=plot_title)
            plot3d!(p, uB0[:, 1], uB0[:, 2], uB0[:, 3], lc=:black, label="t>0", linealpha=0.8)
        else
            p = plot3d(u_std[1:end, 1], u_std[1:end, 2], u_std[1:end, 3],
                grid=true,
                xlabel="x", ylabel="y", zlabel="z",
                lc=cgrad(:viridis), line_z=t[1:end] * 100,
                colorbar_title=" \n \ntime",
                right_margin=1.5Plots.mm, title=plot_title)
        end
        if eval
            mkpath("Figures/eval_$(model_name)")
            savefig(p, "Figures/eval_$(model_name)/$eval_run.png")
        else
            save_path = save_name == "" ? "Figures/data/$(model_name).png" : "Figures/" * save_name * ".png"
            mkpath("Figures/data/")
            savefig(p, save_path)
        end
    end
    if STD 
        return u_std
    else
        return u
    end
end



function sigmoid(lower::Real, upper::Real, tmax::Real, x::Real)
    return lower + (upper - lower) / (1 + exp(-2.5 * x + tmax))
end

function linear(start::Real, end_::Real, tmax::Real, x::Real)
    return start + (end_ - start) / tmax * x
end

function exponential(start::Real, end_::Real, tmax::Real, x::Real; offset=0.0, τ=0.0)
    if τ == 0
        τ = tmax / log(end_ / start)
    end
    return offset + start * exp(x / τ)
end


"""
uses DifferentialEquations
"""
function generate_trajectories(model::AbstractDynamicalSystem, tmax::AbstractFloat, skip_steps::Int; Δt=0.01, t₀=0.0, PLOT=true, plot_title="", eval=false, eval_run=0, save_name="")
    tspan = (t₀, tmax)

    prob = ODEProblem(model.sys, model.u0, tspan, model.params)
    sol = solve(prob)

    u = [sol(t) for t in (t₀+skip_steps*Δt):Δt:tmax]
    u = permutedims(hcat(u...))
    t = collect(t₀:0.01:(tmax-skip_steps*Δt))
    u_std = StatsBase.standardize(ZScoreTransform, u, dims=1)

    if PLOT
        if occursin("Paper", model.name)
            uS0 = u_std[findall(x -> x <= 0, t), :]
            uB0 = u_std[findall(x -> x > 0, t), :]
            p = plot3d(uS0[:, 1], uS0[:, 2], uS0[:, 3],
                grid=true,
                xlabel="x", ylabel="y", zlabel="z",
                lc=:red, label="t\$\\leq\$0", linealpha=1, title=plot_title)
            plot3d!(p, uB0[:, 1], uB0[:, 2], uB0[:, 3], lc=:black, label="t>0", linealpha=0.8)
        else
            p = plot3d(u_std[1:end, 1], u_std[1:end, 2], u_std[1:end, 3],
                grid=true,
                xlabel="x", ylabel="y", zlabel="z",
                lc=cgrad(:viridis), line_z=t[1:end] * 100,
                colorbar_title=" \n \ntime",
                right_margin=1.5Plots.mm, title=plot_title)
        end
        if eval
            mkpath("Figures/eval_$(model.name)")
            savefig(p, "Figures/eval_$(model.name)/$eval_run.png")
        else
            save_path = save_name == "" ? "Figures/data/$(model.name).png" : "Figures/" * save_name * ".png"
            mkpath("Figures/data/")
            savefig(p, save_path)
        end
    end
    return u
end