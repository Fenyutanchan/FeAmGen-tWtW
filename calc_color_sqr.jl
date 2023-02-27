function calc_color_square(
    one_color::Basic,
    conj_color::Basic 
)::Basic
    open( "calc.frm", "w" ) do io
        write(io, """

        #-
        Off Statistics;

        format nospaces;
        format maple;

        symbols nc;

        #include color.frm

        Local colorConj = $(conj_color);

        *** make conjugate for colorConj only
        id SUNT = SUNTConj;
        id sunTrace = sunTraceConj;
        .sort

        Local colorFactor = $(one_color);
        .sort

        Local colorSquare = colorConj*colorFactor;
        .sort
        drop colorConj;
        drop colorFactor;
        .sort

        #call calc1_CF();
        .sort 

        #call calc2_CF();
        .sort 

        id ca = nc;
        id cf = (nc^2-1)/(2*nc);
        id ca^(-1) = nc^(-1);
        id ca^(-2) = nc^(-2);
        .sort

        #write <calc.out> "%E", colorSquare
        #close <calc.out>
        .sort

        .end

        """ )
    end

    (run ∘ pipeline)(`$(form()) calc.frm`, "calc.log" )

    result_expr =   (Basic ∘ read)("calc.out", String)

    rm("calc.frm")
    rm("calc.out")
    rm("calc.log")
    
    return result_expr
end
