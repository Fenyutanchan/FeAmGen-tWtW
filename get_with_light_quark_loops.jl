using   JLD2
using   SymEngine

root_dir            =   dirname(@__FILE__)
original_dir        =   joinpath(root_dir, "with_Fermion_loops")
with_archive_dir    =   joinpath(root_dir, "with_light_quark_loops")
without_archive_dir =   joinpath(root_dir, "without_light_quark_loops")

@assert isdir(original_dir)
!isdir(with_archive_dir) && mkdir(with_archive_dir)
!isdir(without_archive_dir) && mkdir(without_archive_dir)

amp_file_list   =   filter(
    endswith(".jld2"), 
    readdir(original_dir)
)
tex_file_list   =   filter(
    endswith(".tex"),
    readdir(original_dir)
)

for (index, amp_file) ∈ enumerate(amp_file_list)
    amp_str_list    =   jldopen(joinpath(original_dir, amp_file)) do jld_file
        jld_file["amp_lorentz_list"]
    end

    trace_term_list =   Basic[]
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
                            trace_term_list,
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

    without_flag    =   false
    for trace_term ∈ trace_term_list
        if occursin("mt", string(trace_term))
            cp(
                joinpath(original_dir, amp_file),
                joinpath(without_archive_dir, amp_file);
                force=true
            )
            cp(
                joinpath(original_dir, tex_file_list[index]),
                joinpath(without_archive_dir, tex_file_list[index])
            )
            without_flag    =   true
            break
        end
    end
    if !without_flag
        cp(
            joinpath(original_dir, amp_file),
            joinpath(with_archive_dir, amp_file);
            force=true
        )
        cp(
            joinpath(original_dir, tex_file_list[index]),
            joinpath(with_archive_dir, tex_file_list[index])
        )
    end
end
