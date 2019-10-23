using Test, AdvancedHMC, LinearAlgebra, UnicodePlots
using Statistics: mean, var, cov
include("common.jl")

@testset "Matrix parallelisation" begin
    n_chains_max = 20
    θ_init = [randn(D, n_chains) for n_chains in 1:n_chains_max]
    ϵ = 0.1
    n_steps = 20
    n_samples = 10_000
    n_adapts = 2_000

    for metricT in [
        UnitEuclideanMetric,
        # DiagEuclideanMetric,
        # DenseEuclideanMetric
    ]
        τ = StaticTrajectory(Leapfrog(ϵ), n_steps)

        time_mat = Vector{Float64}(undef, n_chains_max)
        for (i, n_chains) in enumerate(1:n_chains_max)
            h = Hamiltonian(metricT((D, n_chains)), ℓπ, ∂ℓπ∂θ)
            t = @elapsed samples, stats = sample(h, τ, θ_init[i], n_samples; verbose=false)
            @test mean(samples) ≈ zeros(D, n_chains) atol=RNDATOL
            time_mat[i] = t
        end
        fig = lineplot(collect(1:n_chains_max), time_mat, title="Scalabiliry of multiple chains", name="matpara", xlabel="Num of chains", ylabel="time (s)")

        # Check time for multiple runs of single chain
        time_seperate = Vector{Float64}(undef, n_chains_max)

        h_single = Hamiltonian(UnitEuclideanMetric(D), ℓπ, ∂ℓπ∂θ)
        for (i, n_chains) in enumerate(1:n_chains_max)
            t = @elapsed for j in 1:n_chains
                samples, stats = sample(h_single, τ, θ_init[i][:,j], n_samples; verbose=false)
            end
            time_seperate[i] = t
        end
        lineplot!(fig, collect(1:n_chains_max), time_seperate; color=:blue, name="seperate")

        show(fig); println()
    end

    # adaptor = StanHMCAdaptor(
    #     n_adapts,
    #     Preconditioner(metric),
    #     NesterovDualAveraging(0.8, τ.integrator.ϵ),
    # )
    # samples, stats = sample(h, τ, θ_init, n_samples, adaptor, n_adapts; verbose=false, progress=false)

    # @test mean(samples) ≈ zeros(D) atol=RNDATOL
end
