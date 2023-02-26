using   ProgressMeter

root_dir            =   dirname(@__FILE__)
with_archive_dir    =   joinpath(root_dir, "with_light_quark_loops")
without_archive_dir =   joinpath(root_dir, "without_light_quark_loops")

with_archive_files      =   readdir(with_archive_dir, join=true)
without_archive_files   =   readdir(without_archive_dir, join=true)

with_tex_list           =   filter(endswith(".tex"), with_archive_files)
with_tex_head_list      =   (first ∘ splitext).(with_tex_list)
with_pdf_list           =   filter(endswith(".pdf"), with_archive_files)
with_pdf_head_list      =   (first ∘ splitext).(with_pdf_list)
setdiff!(with_tex_head_list, with_pdf_head_list)

cd(with_archive_dir)
p       =   Progress(length(with_tex_head_list), "Plotting with with light quark loops")
counter =   Threads.Atomic{Int}(0)
l       =   Threads.SpinLock()
Threads.@threads for with_head in with_tex_head_list
    Threads.atomic_add!(counter, 1)
    Threads.lock(l)
        update!(p, counter[])
    Threads.unlock(l)
    (run ∘ pipeline)(`lualatex $(with_head)`, devnull)
end

without_tex_list           =   filter(endswith(".tex"), without_archive_files)
without_tex_head_list      =   (first ∘ splitext).(without_tex_list)
without_pdf_list           =   filter(endswith(".pdf"), without_archive_files)
without_pdf_head_list      =   (first ∘ splitext).(without_pdf_list)
setdiff!(without_tex_head_list, without_pdf_head_list)

cd(without_archive_dir)
p       =   Progress(length(with_tex_head_list), "Plotting with with light quark loops")
counter =   Threads.Atomic{Int}(0)
Threads.@threads for without_head in without_tex_head_list
    Threads.atomic_add!(counter, 1)
    Threads.lock(l)
        update!(p, counter[])
    Threads.unlock(l)
    (run ∘ pipeline)(`lualatex $(without_head)`, devnull)
end
