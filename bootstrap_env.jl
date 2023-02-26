import  Pkg

env_root    =  dirname(@__FILE__)

rm(joinpath(env_root, "Manifest.toml"), force=true, recursive=true)
rm(joinpath(env_root, "Project.toml"), force=true, recursive=true)
Pkg.activate(env_root)

Pkg.add("Git")
Pkg.add("JLD2")
Pkg.add("ProgressMeter")
Pkg.add("SymEngine")

Pkg.add(url="https://github.com/zhaoli-IHEP/AmpTools.jl")
Pkg.add(url="https://github.com/Fenyutanchan/QGRAF_jll.jl")
Pkg.develop(url="https://github.com/zhaoli-IHEP/FeAmGen.jl")

using   Git

(cd ∘ joinpath)(Pkg.devdir(), "FeAmGen")
all_patches =   filter(endswith(".patch"), readdir(env_root, join=true))
try
    for patch ∈ all_patches
        run(`$(git()) apply $patch`)
    end
catch
    run(`$(git()) reset --hard HEAD`)
    for patch ∈ all_patches
        run(`$(git()) apply $patch`)
    end
end
@info "Apply $(length(all_patches)) patch(s) successfully."
cd(env_root)
