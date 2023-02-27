using   AmpTools
using   FORM_jll
using   FeAmGen
using   JLD2
using   Pkg
using   SymEngine

include("calc_color_sqr.jl")
include("get_dir.jl")

root_dir    =   dirname(@__FILE__)
base_dir    =   joinpath(root_dir, "Wplus_t_TO_Wplus_t")
target_dir  =   joinpath(root_dir, "with_nfnc3")

!isdir(target_dir) && mkdir(target_dir)

function find_nfnc3(n_loop::Int)::Vector{Int}
    art_dir =   FeAmGen.art_FeAmGen_dir
    cp("$(art_dir)/scripts/color.frm", "color.frm", force=true)

    amp_dir =   (get_amplitudes_dir ∘ get_n_loop_dir)(base_dir, n_loop)

    jld_list    =   filter(endswith(".jld2"), readdir(amp_dir, join=true))

    @vars   ca, cf, nc

    conj_color          =   Basic("DeltaFun(cla4, clb2)")
    unique_color_list   =   Basic[]
    nc3_index_list      =   Int[]
    for file_name ∈ jld_list
        color_list  =   jldopen(file_name) do io
            (to_Basic ∘ read)(io, "amp_color_list")
        end

        color_square_list   =   map(
            x -> calc_color_square(x, conj_color),
            color_list
        )
        color_square_list   =   map(
            x -> subs(x, Basic("im") => im), color_square_list
        )
        for one_square ∈ color_square_list
            nc3_coeff   =   coeff(one_square, nc, Basic(3))
            if !iszero(nc3_coeff) 
                println("[ $(file_name) ]")
                println("  $(one_square)")

                index   =   parse(
                    Int,
                    match(
                        r"[1-9][0-9]*",
                        (last ∘ splitdir)(file_name)
                    ).match
                ) 
                union!(nc3_index_list, index)
            end
            term_list           =   get_add_vector_expand(one_square)
            filtered_term_list  =   filter!(
                x -> SymEngine.get_symengine_class(x) ∉ [:Integer, :Rational, :Complex],
                (unique ∘ map)(drop_coeff, term_list)
            )
            union!(unique_color_list, filtered_term_list)
        end
    end
    sort!(nc3_index_list)

    @show   unique_color_list
    @info   "There is $(length(nc3_index_list)) diagrams with NC^3."
    @show   nc3_index_list 

    rm("color.frm")

    return nc3_index_list
end # function main

function nfnc3_main(n_loop::Int)::Nothing
    amplitudes_dir  =   (get_amplitudes_dir ∘ get_n_loop_dir)(base_dir, n_loop)
    visuals_dir     =   (get_visuals_dir ∘ get_n_loop_dir)(base_dir, n_loop)

    for index ∈ find_nfnc3(n_loop)
        cp(
            joinpath(amplitudes_dir, "amplitude_diagram$index.jld2"),
            joinpath(target_dir, "$(n_loop)Loop_amplitude_diagram$index.jld2");
            force=true
        )
        cp(
            joinpath(visuals_dir, "visual_diagram$index.tex"),
            joinpath(target_dir, "$(n_loop)Loop_visual_diagram$index.tex");
            force=true
        )
    end
end

########
nfnc3_main(3)
########