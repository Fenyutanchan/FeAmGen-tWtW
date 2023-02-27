(cd ∘ dirname)(@__FILE__)

include("001.bootstrap_env.jl")
include("010.run_FeAmGen.jl")
include("020.find_light_quark_loop.jl")
include("030.find_nc4.jl")
include("100.generate_diagram_pdf.jl")
