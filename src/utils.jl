using Plots: plot, plot!
using Plots

function plot_param(params, time, Ttr,model_name)
    time1 = time .+ Ttr
    if occursin("Lorenz",model_name)
        p = plot(time, params[1].(time1)/params[1](time1[1]), label="σ₀=$(round(params[1](time1[1]),digits=1))", legend=:inside, ylabel="% of IC")
        plot!(time, params[2].(time1)/params[2](time1[1]), label="ρ₀=$(round(params[2](time1[1]),digits=1))")
        plot!(time, params[3].(time1)/params[3](time1[1]), label="β₀=$(round(params[3](time1[1]),digits=1))")
    elseif occursin("BN",model_name)
        p = plot(time, params[1].(time1)/params[1](time1[1]), label="gₙₘ₀ₐ₀=$(round(params[1](time1[1]),digits=1))",legend=:inside, ylabel="% of IC")
    else
        throw("No parameter specifices for this model implemented")
    end
    return p
end
    

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
function generate_trajectories(model::GeneralizedDynamicalSystem, tmax, transient_T::Int; Δt=0.01, t₀=0.0, process_noise_level=0.0, STD=true, save_name="", PLOT=true, plot_title="", pl_params=zeros(3), eval=false, eval_run=0, model_name="")::AbstractMatrix
    std_ = process_noise_level==0 ? [0,0,0] : std_model(model, tmax, transient_T;Δt,t₀)
    ts = trajectory(model, tmax; Δt=Δt, Ttr=transient_T, diffeq=(alg=Tsit5(), callback=dynamical_noise_callback(process_noise_level, std_)))
    u = Matrix(ts)
    u_std = StatsBase.standardize(ZScoreTransform, u, dims=1)

    t = t₀:Δt:tmax
    if PLOT
        if occursin("Paper", model_name)
            uS0 = u_std[findall(x -> x <= 0, t), :]
            uB0 = u_std[findall(x -> x > 0, t), :]
            p = plot3d(uS0[:, 1], uS0[:, 2], uS0[:, 3],
                grid=true,
                lc=:red, label="t\$\\leq\$0", linealpha=1, title=plot_title)
            plot3d!(p, uB0[:, 1], uB0[:, 2], uB0[:, 3], lc=:black, label="t>0", linealpha=0.8)
        else
            p = plot3d(u_std[1:end, 1], u_std[1:end, 2], u_std[1:end, 3],
                grid=true,
                lc=cgrad(:viridis), line_z=t[1:end],
                colorbar_title=" \n \ntime",
                right_margin=1.5Plots.mm, title=plot_title,label=nothing)
        end
        if !isempty(pl_params)
            p_par = plot_param(pl_params, t, transient_T, model_name)
            l = grid(2,1, heights=[0.8,0.2])
            p = plot(p, p_par, layout=l, plot_title=plot_title)
        end
        if eval
            mkpath("Figures/eval_$(model_name)")
            savefig(p, "Figures/eval_$(model_name)/$eval_run.png")
        else
            save_name = isempty(save_name) ? model_name : save_name
            mkpath("Figures/data/")
            savefig(p, "Figures/data/$save_name.png")
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
function generate_trajectories(model::AbstractDynamicalSystem, tmax::AbstractFloat, skip_steps::Int; Δt=0.01, t₀=0.0, process_noise_level=0.0, STD=true,PLOT=true, plot_title="", eval=false, eval_run=0, save_name="", pl_params=[],model_name="")
    tspan = (t₀, tmax)

    prob = ODEProblem(model.sys, model.u0, tspan, model.params)
    transient_T = skip_steps
    std_ = process_noise_level==0 ? [0,0,0] : std_model(prob, tmax, transient_T;Δt,t₀)
    sol = solve(prob, Tsit5(), callback=dynamical_noise_callback(process_noise_level,std_))

    u = [sol(t) for t in (t₀+skip_steps*Δt):Δt:tmax]
    u = permutedims(hcat(u...))
    t = collect(t₀:0.01:(tmax-skip_steps*Δt))
    u_std = StatsBase.standardize(ZScoreTransform, u, dims=1)

    if PLOT
        if occursin("Paper", model.name)
            uS0 = u_std[findall(x -> x <= 0, t), :]
            uB0 = u_std[findall(x -> x > 0, t), :]
            p = plot3d(uB0[:, 1], uB0[:, 2], uB0[:, 3], lc=:black, label="t>0")
            plot3d!(p,uS0[:, 1], uS0[:, 2], uS0[:, 3],
                grid=true,
                xlabel="x", ylabel="y", zlabel="z",
                lc=:red, label="t\$\\leq\$0", linealpha=1, title=plot_title, legend=nothing)
            
        else
            p = plot3d(u_std[1:end, 1], u_std[1:end, 2], u_std[1:end, 3],
                grid=true,
                xlabel="x", ylabel="y", zlabel="z",
                lc=cgrad(:viridis), line_z=t[1:end],
                colorbar_title=" \n \ntime",
                right_margin=1.5Plots.mm, title=plot_title,legend=nothing)
        end
        if !isempty(pl_params)
            p_par = plot_param(pl_params, t, 0, model_name)
            l = grid(2,1, heights=[0.8,0.2])
            p = plot(p, p_par, layout=l, plot_title=plot_title)
        end
        if eval
            mkpath("Figures/eval_$(model.name)")
            savefig(p, "Figures/eval_$(model.name)/$eval_run.png")
        else
            save_name = isempty(save_name) ? String(model.name) : save_name
            mkpath("Figures/data/")
            savefig(p, "Figures/data/$save_name.png")
        end
    end
    if STD
        return u_std
    else
        return u
    end
end


function check_validity(sys::String)
    if !any(x->sys in x, [valid_ns_systems,valid_trial_systems, valid_std_systems,valid_regimes])
        throw("$benchmark_system is not a valid system")
    end
    return true
end

function dynamical_noise_callback(dynamical_noise_level::AbstractFloat, std::AbstractVector)::DiscreteCallback
    noise_level = dynamical_noise_level .* std
    dn = dynamical_noise_level == 0 ? false : true
    condition(u, t, integrator) = dn
    affect!(integrator) = set_state!(integrator, get_state(integrator) .+ ϵ.(noise_level))
    cb = DiscreteCallback(condition, affect!)
    return cb
end

function std_model(ds::ContinuousDynamicalSystem,tmax, transient_T::Int; Δt=0.01, t₀=0.0)
    tseries = Matrix(trajectory(ds, tmax, Ttr=transient_T,Δt=Δt, t0=t₀))
    std_ = [std(tseries[:, i]) for i in axes(tseries, 2)]
    return std_
end

function std_model(ds::ODEProblem, tmax,transient_T;Δt=0.01,t₀=0.0)
    cde = ContinuousDynamicalSystem(ds)
    return std_model(cde, tmax,transient_T;Δt,t₀)
end

ϵ(process_noise::AbstractFloat)::AbstractFloat = randn() * process_noise
