using   ProgressMeter

include("plot_standalone_Feynman_diagram.jl")

root_dir    =   dirname(@__FILE__)
archive_dir =   joinpath(root_dir, "with_light_quark_loops")

archive_files   =   readdir(archive_dir, join=true)

tex_list        =   filter(endswith(".tex"), archive_files)
tex_head_list   =   (first ∘ splitext).(tex_list)
pdf_list        =   filter(endswith(".pdf"), archive_files)
pdf_head_list   =   (first ∘ splitext).(pdf_list)
setdiff!(tex_head_list, pdf_head_list)

cd(archive_dir)
p       =   Progress(length(tex_head_list), "Plotting with with light quark loops")
counter =   Threads.Atomic{Int}(0)
l       =   Threads.SpinLock()
Threads.@threads for tex_head in tex_head_list
    Threads.atomic_add!(counter, 1)
    Threads.lock(l)
        update!(p, counter[])
    Threads.unlock(l)
    plot_standalone_Feynman_diagram("$tex_head.tex")
end
