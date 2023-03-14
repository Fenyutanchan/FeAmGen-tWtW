using   JLD2
using   SymEngine

root_dir    =   dirname(@__FILE__)

archive_dir =   joinpath(root_dir, "with_nc4")

function get_diagram_index(amp_file_name::String)::Int
    @assert isfile(amp_file_name)

    diagram_str_range   =   findfirst(r"diagram[1-9]+\d*.jld2$", amp_file_name)
    @assert !isnothing(diagram_str_range)
    diagram_str         =   amp_file_name[diagram_str_range]

    index_str_range     =   findfirst(r"[1-9]+\d*", diagram_str)
    return  parse(Int, diagram_str[index_str_range])
end

function get_amp_with_MMA_form(amp_file_name::String)::Vector{String}
    @assert isfile(amp_file_name)

    amp_lorentz_list    =   load(amp_file_name, "amp_lorentz_list")
    
    map!(transform_GA_to_MMA_form, amp_lorentz_list, amp_lorentz_list)
    map!(transform_Den_to_MMA_form, amp_lorentz_list, amp_lorentz_list)
    map!(transform_SP_to_MMA_form, amp_lorentz_list, amp_lorentz_list)
    map!(transform_U_to_MMA_form, amp_lorentz_list, amp_lorentz_list)
    map!(transform_VecEp_to_MMA_form, amp_lorentz_list, amp_lorentz_list)
    map!(transform_FermionChain_to_MMA_form, amp_lorentz_list, amp_lorentz_list)

    # amp_lorentz_list    =   replace.(amp_lorentz_list,
    #     '(' => '[',
    #     ')' => ']'
    # )
    # amp_lorentz_list    =   replace.(amp_lorentz_list,
    #     "FermionChain" => "Dot"
    # )
    amp_lorentz_list    =   replace.(amp_lorentz_list,
        "diim" => "D",
        "im" => "I",
        "PR" => "GA[6]",
        "PL" => "GA[7]"
    )

    return  amp_lorentz_list
end

function get_color_with_MMA_form(amp_file_name::String)::Vector{String}
    @assert isfile(amp_file_name)

    amp_color_list  =   load(amp_file_name, "amp_color_list")
    map!(transform_DeltaFun_to_MMA_form, amp_color_list, amp_color_list)

    return  replace.(amp_color_list,
        "cf" => "CF",
        "ca" => "CA"
    )
end

function get_den_list_MMA_form(amp_file_name::String)::Vector{String}
    @assert isfile(amp_file_name)
    
    den_list    =   load(amp_file_name, "loop_den_list")

    return replace.(den_list, '(' => '[', ')' => ']')
end

function transform_DeltaFun_to_MMA_form(expr_str::String)::String
    @assert is_parenthesis_match(expr_str)

    orig_str_ranges =   findall(r"DeltaFun\((\w+)\, (\w+)\)", expr_str)
    orig_str_list   =   [expr_str[the_range] for the_range ∈ orig_str_ranges]
    for orig_str ∈ orig_str_list
        repl_str    =   replace(orig_str,
            "DeltaFun" => "SD",
            '(' => '[',
            ')' => ']'
        )
        expr_str    =   replace(expr_str, orig_str => repl_str)
    end
    return  expr_str
end

function transform_Den_to_MMA_form(expr_str::String)::String
    @assert is_parenthesis_match(expr_str)

    Den_head_ranges         =   findall("Den(", expr_str)
    den_expr_begin_indices  =   map(first, Den_head_ranges)
    findnext_begin_indices  =   last.(Den_head_ranges) .+ 1
    den_expr_end_indices    =   Int[]
    for (begin_index, findnext_begin_index) ∈ zip(den_expr_begin_indices, findnext_begin_indices)
        end_index   =   findnext(')', expr_str, findnext_begin_index)
        while !is_parenthesis_match(expr_str[begin_index:end_index])
            end_index   =   findnext(')', expr_str, end_index + 1)
        end
        if expr_str[end_index+1] == '^'
            end_index = (last ∘ findnext)(r"\^\d+", expr_str, end_index)
        end
        push!(den_expr_end_indices, end_index)
    end
    
    den_expr_str_list   =   [
        expr_str[begin_index:end_index]
        for (begin_index, end_index) ∈ zip(den_expr_begin_indices, den_expr_end_indices)
    ]

    for den_expr_str ∈ den_expr_str_list
        den_str, den_power_str  =   split(den_expr_str, '^')..., "1"

        mom, mass, ieta =   (get_args∘Basic∘String)(den_str)
        mass2           =   expand(-mass^2)
        new_expr_str    =   "FeynAmpDenominator[StandardPropagatorDenominator[Momentum[$mom,D],0,$mass2,{$den_power_str,1}]]"
        expr_str        =   replace(expr_str, den_expr_str => new_expr_str)
    end

    return  expr_str
end

function transform_FermionChain_to_MMA_form(expr_str::String)::String
    @assert is_parenthesis_match(expr_str)

    fermion_chain_head_ranges           =   findall("FermionChain(", expr_str)
    fermion_chain_expr_begin_indices    =   map(first, fermion_chain_head_ranges)
    findnext_begin_indices              =   last.(fermion_chain_head_ranges) .+ 1
    fermion_chain_expr_end_indices      =   Int[]
    for (begin_index, findnext_begin_index) ∈ zip(fermion_chain_expr_begin_indices, findnext_begin_indices)
        end_index   =   findnext(')', expr_str, findnext_begin_index)
        while !is_parenthesis_match(expr_str[begin_index:end_index])
            end_index   =   findnext(')', expr_str, end_index + 1)
        end
        push!(fermion_chain_expr_end_indices, end_index)
    end
    
    fermion_chain_expr_str_list =   [
        expr_str[begin_index:end_index]
        for (begin_index, end_index) ∈ zip(fermion_chain_expr_begin_indices, fermion_chain_expr_end_indices)
    ]

    for fermion_chain_expr_str ∈ fermion_chain_expr_str_list
        repl_str    =   replace(fermion_chain_expr_str, "FermionChain(" => "Dot[")

        @assert last(repl_str) == ')'
        repl_str    =   repl_str[begin:end-1] * ']'
        
        expr_str    =   replace(expr_str, fermion_chain_expr_str => repl_str)
    end

    return  expr_str
end

function transform_GA_to_MMA_form(expr_str::String)::String
    @assert is_parenthesis_match(expr_str)

    GA_head_ranges          =   findall("GA(", expr_str)
    GA_expr_begin_indices   =   map(first, GA_head_ranges)
    findnext_begin_indices  =   last.(GA_head_ranges) .+ 1
    GA_expr_end_indices     =   Int[]
    for (begin_index, findnext_begin_index) ∈ zip(GA_expr_begin_indices, findnext_begin_indices)
        end_index   =   findnext(')', expr_str, findnext_begin_index)
        while !is_parenthesis_match(expr_str[begin_index:end_index])
            end_index   =   findnext(')', expr_str, end_index + 1)
        end
        push!(GA_expr_end_indices, end_index)
    end
    
    GA_expr_str_list    =   [
        expr_str[begin_index:end_index]
        for (begin_index, end_index) ∈ zip(GA_expr_begin_indices, GA_expr_end_indices)
    ]

    for GA_expr_str ∈ GA_expr_str_list
        repl_str    =   replace(GA_expr_str,
            '(' => '[',
            ')' => ']',
            "unity" => "1"
        )
        if contains(GA_expr_str, 'q') || contains(GA_expr_str, 'K')
            repl_str    =   replace(repl_str,
                "GA" => "GS"
            )
        end
        
        expr_str    =   replace(expr_str, GA_expr_str => repl_str)
    end

    return  expr_str
end

function transform_SP_to_MMA_form(expr_str::String)::String
    @assert is_parenthesis_match(expr_str)

    SP_head_ranges          =   findall("SP(", expr_str)
    SP_expr_begin_indices   =   map(first, SP_head_ranges)
    findnext_begin_indices  =   last.(SP_head_ranges) .+ 1
    SP_expr_end_indices     =   Int[]
    for (begin_index, findnext_begin_index) ∈ zip(SP_expr_begin_indices, findnext_begin_indices)
        end_index   =   findnext(')', expr_str, findnext_begin_index)
        while !is_parenthesis_match(expr_str[begin_index:end_index])
            end_index   =   findnext(')', expr_str, end_index + 1)
        end
        push!(SP_expr_end_indices, end_index)
    end
    
    SP_expr_str_list    =   [
        expr_str[begin_index:end_index]
        for (begin_index, end_index) ∈ zip(SP_expr_begin_indices, SP_expr_end_indices)
    ]

    for SP_expr_str ∈ SP_expr_str_list
        repl_str    =   replace(SP_expr_str,
            '(' => '[',
            ')' => ']'
        )
        
        expr_str    =   replace(expr_str, SP_expr_str => repl_str)
    end

    return  expr_str
end

function transform_U_to_MMA_form(expr_str::String)::String
    @assert is_parenthesis_match(expr_str)

    U_head_ranges           =   findall("U(", expr_str)
    union!(U_head_ranges, findall("UB(", expr_str) )
    U_expr_begin_indices    =   map(first, U_head_ranges)
    findnext_begin_indices  =   last.(U_head_ranges) .+ 1
    U_expr_end_indices      =   Int[]
    for (begin_index, findnext_begin_index) ∈ zip(U_expr_begin_indices, findnext_begin_indices)
        end_index   =   findnext(')', expr_str, findnext_begin_index)
        while !is_parenthesis_match(expr_str[begin_index:end_index])
            end_index   =   findnext(')', expr_str, end_index + 1)
        end
        push!(U_expr_end_indices, end_index)
    end

    U_expr_str_list =   [
        expr_str[begin_index:end_index]
        for (begin_index, end_index) ∈ zip(U_expr_begin_indices, U_expr_end_indices)
    ]

    for U_expr_str ∈ U_expr_str_list
        Bar =   startswith(U_expr_str, "UB") ? "Bar" : ""

        index, mom, mass    =   (get_args∘Basic∘String)(U_expr_str)

        expr_str    =   replace(expr_str, U_expr_str => "SpinorU$Bar[$mom, $mass]")
    end

    return  expr_str
end

function transform_VecEp_to_MMA_form(expr_str::String)::String
    @assert is_parenthesis_match(expr_str)

    VecEp_head_ranges            =   findall("VecEp(", expr_str)
    union!(VecEp_head_ranges, findall("VecEpC(", expr_str))
    VecEp_expr_begin_indices    =   map(first, VecEp_head_ranges)
    findnext_begin_indices      =   last.(VecEp_head_ranges) .+ 1
    VecEp_expr_end_indices      =   Int[]
    for (begin_index, findnext_begin_index) ∈ zip(VecEp_expr_begin_indices, findnext_begin_indices)
        end_index   =   findnext(')', expr_str, findnext_begin_index)
        while !is_parenthesis_match(expr_str[begin_index:end_index])
            end_index   =   findnext(')', expr_str, end_index + 1)
        end
        push!(VecEp_expr_end_indices, end_index)
    end

    VecEp_expr_str_list =   [
        expr_str[begin_index:end_index]
        for (begin_index, end_index) ∈ zip(VecEp_expr_begin_indices, VecEp_expr_end_indices)
    ]
    
    for VecEp_expr_str ∈ VecEp_expr_str_list
        conj_flag   =   startswith(VecEp_expr_str, "VecEpC") ? -1 : 1

        index, lorentz_index, mom, mass =   (get_args ∘ Basic)(VecEp_expr_str)
        new_str     =   "FV[Polarization[$mom,$conj_flag*I],$lorentz_index]"
        expr_str    =   replace(expr_str, VecEp_expr_str => new_str)
    end

    return  expr_str
end

function is_parenthesis_match(expr_str::String)::Bool
    left_parenthesis_list   =   ['(', '[', '{']
    right_parenthesis_list  =   [')', ']', '}']
    parenthesis_list        =   union(left_parenthesis_list, right_parenthesis_list)

    matching_dict   =   Dict(right_parenthesis_list .=> left_parenthesis_list)

    parenthesis_stack   =   Char[]
    pos_index           =   findfirst(in(parenthesis_list), expr_str)
    while !isnothing(pos_index)
        s = expr_str[pos_index]
        if s ∈ left_parenthesis_list
            push!(parenthesis_stack, s)
        elseif s ∈ right_parenthesis_list
            if matching_dict[s] == last(parenthesis_stack)
                pop!(parenthesis_stack)
            else
                return  false
            end
        end
        pos_index   =   findnext(in(parenthesis_list), expr_str, pos_index + 1)
    end

    if !isempty(parenthesis_stack)
        return  false
    end

    return  true
end

function main()::Nothing
    amp_files   =   readdir(archive_dir; join=true)
    filter!(endswith(".jld2"), amp_files)
    sort!(amp_files; by=get_diagram_index)

    diagram_indices     =   map(get_diagram_index, amp_files)
    amp_lorentz_lists   =   map(get_amp_with_MMA_form, amp_files)
    den_lists           =   map(get_den_list_MMA_form, amp_files)
    color_lists         =   map(get_color_with_MMA_form, amp_files)

    diagram_indices_str     =   '{' * join(diagram_indices, ", ") * '}'
    amp_lorentz_lists_str   =   '{' * join(
        [
            '{' * join(amp_lorentz_list, ", ") * '}'
            for amp_lorentz_list ∈ amp_lorentz_lists
        ],
        ", "
    ) * '}'
    color_lists_str         =   '{' * join(
        [
            '{' * join(color_list, ", ") * '}'
            for color_list ∈ color_lists
        ],
        ", "
    ) * '}'
    den_lists_str           =   '{' * join(
        [
            '{' * join(den_list, ", ") * '}'
            for den_list ∈ den_lists
        ],
        ", "
    ) * '}'

    contents    =   """
    DiagramIndices  =   $diagram_indices_str;
    AmpLorentzList  =   $amp_lorentz_lists_str;
    ColorList       =   $color_lists_str;
    DenList         =   $den_lists_str;
    """
    write(joinpath(root_dir, "output.m"), contents)

    return  nothing
end

main()
