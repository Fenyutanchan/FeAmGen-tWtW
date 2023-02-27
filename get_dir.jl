function get_n_loop_dir(base_dir::String, n_loop::Int)::String
    @assert isdir(base_dir)
    n_loop_dir  =   joinpath(
        base_dir,
        (last ∘ splitdir)(base_dir) * "_$(n_loop)Loop"
    )
    @assert isdir(n_loop_dir)
    return  n_loop_dir
end

function get_amplitudes_dir(base_dir::String)::String
    @assert isdir(base_dir)
    amplitudes_dir  =   joinpath(
        base_dir,
        (last ∘ splitdir)(base_dir) * "_amplitudes"
    )
    @assert isdir(amplitudes_dir)
    return  amplitudes_dir
end

function get_visuals_dir(base_dir::String)::String
    @assert isdir(base_dir)
    visuals_dir =   joinpath(
        base_dir,
        (last ∘ splitdir)(base_dir) * "_visuals"
    )
    @assert isdir(visuals_dir)
    return  visuals_dir
end