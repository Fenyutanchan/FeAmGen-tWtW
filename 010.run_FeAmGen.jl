using   FeAmGen

include("generate_tWtW_seed_yaml.jl")

process_name    =   "Wplus_t_TO_Wplus_t"
!isdir(process_name) && mkdir(process_name)
cd(process_name)
rm.(readdir(), force=true, recusive=true)

for ll ∈ 0:3
    open("seed_$ll-loop.yaml", "w+") do io
        write(io, generate_tWtW_seed_yaml(ll))
    end

    digest_seed_proc("seed_$ll-loop.yaml")
    
    cd("$(process_name)_$(ll)Loop")
    generate_amp.("$process_name.yaml")
    (cd ∘ dirname ∘ pwd)()
end

(cd ∘ dirname ∘ pwd)()
