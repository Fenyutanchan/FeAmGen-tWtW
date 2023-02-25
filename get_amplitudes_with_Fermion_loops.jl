using   JLD2

root_dir        =   dirname(@__FILE__)
process_name    =   "Wplus_t_TO_Wplus_t"
archive_dir     =   joinpath(root_dir, "amp_files_with_Fermion_loops")
loops           =   0:3

# amplitudes_with_Fermion_loops   =   Vector{String}[]
# amp_files_with_Fermion_loops    =   String[]
if !isdir(archive_dir)
    mkdir(archive_dir)
end

function main()::Int
    counter =   0
    for n_loop ∈ loops
        amp_file_list   =   readdir(
            joinpath(
                root_dir,
                process_name,
                process_name * "_$(n_loop)Loop",
                process_name * "_$(n_loop)Loop_amplitudes"
            );
            join=true
        )
        filter!(endswith(".jld2"), amp_file_list)

        for amp_file ∈ amp_file_list
            amp_str_list    =   jldopen(amp_file) do jld_file
                jld_file["amp_lorentz_list"]
            end
            for amp_str ∈ amp_str_list
                if occursin("Trace", amp_str)
                    cp(
                        amp_file,
                        joinpath(
                            archive_dir,
                            "$(n_loop)Loop_" * (last ∘ splitdir)(amp_file)
                        );
                        force=true
                    )
                    counter +=  1
                    break
                end
            end
        end
    end

    return counter
end

println("There are $(main()) diagrams with Fermion loops.")
