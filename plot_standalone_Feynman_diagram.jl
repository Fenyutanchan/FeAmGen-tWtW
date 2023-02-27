function plot_standalone_Feynman_diagram(tex_file::String)::Nothing
    @assert isfile(tex_file)

    current_dir                 =   pwd()
    tex_file_dir, tex_file_name =   splitdir(tex_file)
    isempty(tex_file_dir) && (tex_file_dir = current_dir)
    tex_file_head               =   (first ∘ splitext)(tex_file_name)
    contents                    =   readlines(tex_file)

    @assert first(contents) ==  "\\documentclass{revtex4}"
    contents[1] =   "\\documentclass{standalone}"

    to_be_comment_list  =   [
        "\\usepackage{rotating}",
        "\\usepackage{breqn}",
        "\\begin{figure}[!htb]",
        "\\begin{center}",
        "\\end{center}",
        "\\caption{",
        "\\end{figure}",
        "\\newpage"
    ]

    for (line_index, line) ∈ enumerate(contents)
        if any(occursin(line), to_be_comment_list)
            contents[line_index]    =   "% " * line
        end
    end

    cd(tex_file_dir)
    open("tmp_$(tex_file_head).tex", "w+") do io
        join(io, contents, "\n")
    end
    (run ∘ pipeline)(`lualatex tmp_$(tex_file_name)`, devnull)
    rm("tmp_$tex_file_head.tex")
    rm("tmp_$tex_file_head.aux")
    rm("tmp_$tex_file_head.log")
    mv("tmp_$tex_file_head.pdf", "$tex_file_head.pdf")
    cd(current_dir)
end
