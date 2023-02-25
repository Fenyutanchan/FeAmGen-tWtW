using   JLD2
using   SymEngine

root_dir        =   dirname(@__FILE__)
original_dir    =   joinpath(root_dir, "amp_files_with_Fermion_loops")
archive_dir     =   joinpath(root_dir, "amp_files_with_light_quark_loops")

if !isdir(archive_dir)
    mkdir(archive_dir)
end

amp_file_list   =   filter(
    endswith(".jld2"), 
    readdir(original_dir, join=true)
)

function main()::Vector{Basic}
    all_trace_terms =   Basic[]

    for amp_file ∈ amp_file_list
        amp_str_list    =   jldopen(amp_file) do jld_file
            jld_file["amp_lorentz_list"]
        end
        for amp_str ∈ amp_str_list
            if occursin("Trace", amp_str)
                trace_pos_list  =   findall("Trace(", amp_str)
                for trace_pos ∈ trace_pos_list
                    trace_begin_index   =   first(trace_pos)
                    find_begin_index    =   last(trace_pos)
                    while true
                        try
                            trace_end_index =   findnext(
                                ')', amp_str, find_begin_index
                            )
                            push!(
                                all_trace_terms,
                                Basic(amp_str[trace_begin_index:trace_end_index])
                            )
                            break
                        catch
                            find_begin_index    =   findnext(
                                ')', amp_str, find_begin_index
                            ) + 1
                        end
                    end
                end
            end
        end
    end

    return all_trace_terms
end

for trace_term ∈ main()
    println(trace_term)
    println()
end
