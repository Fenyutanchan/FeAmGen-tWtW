include("get_dir.jl")

root_dir    =   dirname(@__FILE__)
base_dir    =   joinpath(root_dir, "Wplus_t_TO_Wplus_t")
target_dir  =   joinpath(root_dir, "with_light_quark_loops")

!isdir(target_dir) && mkdir(target_dir)

function find_diagrams_with_light_quark_loop(n_loop::Int)::Vector{Int}
    tex_files   =   readdir(
        (get_visuals_dir ∘ get_n_loop_dir)(base_dir, n_loop);
        join=true
    )
    filter!(endswith(".tex"), tex_files)

    index_list  =   Int[]
    for tex_file in tex_files
        contents    =   readlines(tex_file)
        filter!(startswith('v'), contents)

        bottom_lines            =   filter(
            contains("label' = \\(b\\)"),
            contents
        )
        internal_bottom_lines   =   filter(
            !contains('q'),
            bottom_lines
        )

        if !isempty(internal_bottom_lines)
            index   =   parse(
                Int,
                match(
                    r"[1-9][0-9]*",
                    (last ∘ splitdir)(tex_file)
                ).match
            )
            println("Has internal bottom for cut: #$(index)")
            push!(index_list, index)
        end
    end
    sort!(index_list)
    @info   "There is $(length(index_list)) diagrams with internal bottom for cut."
    @show   index_list

    up_index_list   =   Int[]
    for index ∈ index_list
        tex_file =  joinpath(
            (get_visuals_dir ∘ get_n_loop_dir)(base_dir, 3),
            "visual_diagram$index.tex"
        )
        contents    =   readlines(tex_file)
        filter!(startswith('v'), contents)

        up_lines    =   filter(
            contains("label' = \\(u\\)"),
            contents
        )

        if !isempty(up_lines)
            println("Has up-quark: #$(index)")
            push!(up_index_list, index)
        end
    end
    @info   "There is $(length(up_index_list)) diagrams with up quark loop(s)."
    @show   up_index_list

    # bk_mkdir( "Wplus_t_TO_Wplus_t_3Loop_amplitudes_nf" )
    # for index in up_index_list
    # cp( "Wplus_t_TO_Wplus_t_3Loop_amplitudes/amplitude_diagram$(index).out", 
    #     "Wplus_t_TO_Wplus_t_3Loop_amplitudes_nf/amplitude_diagram$(index).out" ) 
    # cp( "Wplus_t_TO_Wplus_t_3Loop_amplitudes/amplitude_diagram$(index).jld2",  
    #     "Wplus_t_TO_Wplus_t_3Loop_amplitudes_nf/amplitude_diagram$(index).jld2" ) 
    # end # for index

    # bk_mkdir( "Wplus_t_TO_Wplus_t_3Loop_visuals_nf" )
    # cp( "Wplus_t_TO_Wplus_t_3Loop_visuals/generate_diagram_pdf.jl", 
    #     "Wplus_t_TO_Wplus_t_3Loop_visuals_nf/generate_diagram_pdf.jl" )
    # cp( "Wplus_t_TO_Wplus_t_3Loop_visuals/tikz-feynman.sty", 
    #     "Wplus_t_TO_Wplus_t_3Loop_visuals_nf/tikz-feynman.sty" )
    # for index in up_index_list
    # cp( "Wplus_t_TO_Wplus_t_3Loop_visuals/visual_diagram$(index).tex", 
    #     "Wplus_t_TO_Wplus_t_3Loop_visuals_nf/visual_diagram$(index).tex" ) 
    # cp( "Wplus_t_TO_Wplus_t_3Loop_visuals/expression_diagram$(index).out", 
    #     "Wplus_t_TO_Wplus_t_3Loop_visuals_nf/expression_diagram$(index).out" ) 
    # end # for index
    return up_index_list
end # function main

function light_quark_main(n_loop::Int)::Nothing
    amplitudes_dir  =   (get_amplitudes_dir ∘ get_n_loop_dir)(base_dir, n_loop)
    visuals_dir     =   (get_visuals_dir ∘ get_n_loop_dir)(base_dir, n_loop)

    for index ∈ find_diagrams_with_light_quark_loop(n_loop)
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

light_quark_main(3)
