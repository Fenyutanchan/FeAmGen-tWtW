using   AmpTools
using   FORM_jll
using   FeAmGen
using   JLD2
using   Pkg
using   SymEngine

include("get_dir.jl")

root_dir    =   dirname(@__FILE__)
base_dir    =   joinpath(root_dir, "Wplus_t_TO_Wplus_t")
target_dir  =   joinpath(root_dir, "with_nc4")

!isdir(target_dir) && mkdir(target_dir)

function calc_color_square(
    one_color::Basic,
    conj_color::Basic 
)::Basic
    open( "calc.frm", "w" ) do io
        write(io, """

        #-
        Off Statistics;

        format nospaces;
        format maple;

        symbols nc;

        #include color.frm

        Local colorConj = $(conj_color);

        *** make conjugate for colorConj only
        id SUNT = SUNTConj;
        id sunTrace = sunTraceConj;
        .sort

        Local colorFactor = $(one_color);
        .sort

        Local colorSquare = colorConj*colorFactor;
        .sort
        drop colorConj;
        drop colorFactor;
        .sort

        #call calc1_CF();
        .sort 

        #call calc2_CF();
        .sort 

        id ca = nc;
        id cf = (nc^2-1)/(2*nc);
        id ca^(-1) = nc^(-1);
        id ca^(-2) = nc^(-2);
        .sort

        #write <calc.out> "%E", colorSquare
        #close <calc.out>
        .sort

        .end

        """ )
    end

    (run ∘ pipeline)(`$(form()) calc.frm`, "calc.log" )

    result_expr =   (Basic ∘ read)("calc.out", String)

    rm("calc.frm")
    rm("calc.out")
    rm("calc.log")
    
    return result_expr
end

function find_nc4(n_loop::Int)::Vector{Int}
    art_dir =   FeAmGen.art_FeAmGen_dir
    cp("$(art_dir)/scripts/color.frm", "color.frm", force=true)

    amp_dir =   (get_amplitudes_dir ∘ get_n_loop_dir)(base_dir, n_loop)
    vis_dir =   (get_visuals_dir ∘ get_n_loop_dir)(base_dir, n_loop)

    jld_list    =   filter(endswith(".jld2"), readdir(amp_dir, join=true))

    @vars   ca, cf, nc

    conj_color          =   Basic("DeltaFun(cla4, clb2)")
    unique_color_list   =   Basic[]
    nc4_index_list      =   Int[]
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
            nc4_coeff   =   coeff(one_square, nc, Basic(4))
            if !iszero(nc4_coeff) 
                println("[ $(file_name) ]")
                println("  $(one_square)")

                index   =   parse(
                    Int,
                    match(
                        r"[1-9][0-9]*",
                        (last ∘ splitdir)(file_name)
                    ).match
                ) 
                union!(nc4_index_list, index)
            end
            term_list           =   get_add_vector_expand(one_square)
            filtered_term_list  =   filter!(
                x -> SymEngine.get_symengine_class(x) ∉ [:Integer, :Rational, :Complex],
                (unique ∘ map)(drop_coeff, term_list)
            )
            union!(unique_color_list, filtered_term_list)
        end
    end
    sort!(nc4_index_list)

    @show   unique_color_list
    @info   "There is $(length(nc4_index_list)) diagrams with NC^4."
    @show   nc4_index_list 

    rm("color.frm")

    for index in nc4_index_list
        cp(
            joinpath(amp_dir, "amplitude_diagram$index.jld2"),
            joinpath(target_dir, "$(n_loop)Loop_amplitude_diagram$index.jld2")
        )
        cp(
            joinpath(vis_dir, "visual_diagram$index.tex"),
            joinpath(target_dir, "$(n_loop)Loop_visual_diagram$index.tex")
        )
    end

    return nc4_index_list
end # function main

function nc4_main(n_loop::Int)::Nothing
    amplitudes_dir  =   (get_amplitudes_dir ∘ get_n_loop_dir)(base_dir, n_loop)
    visuals_dir     =   (get_visuals_dir ∘ get_n_loop_dir)(base_dir, n_loop)

    for index ∈ find_nc4(n_loop)
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
nc4_main(3)
########
