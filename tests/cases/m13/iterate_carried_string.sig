process ITERATECARRIEDSTRING =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | K := indices(2)
   | iterate K of (| Q := E[?] | E := Q |) with E := "s" end
   | Q ^= N
   | T := Q $ 1 init "t0"
   | U := E $ 1 init "u0"
   | W :: write("t=", T when N < 4)
   | X :: write("u=", U when N < 4)
   | W --> X
   |)
  where
    integer ZN;
    string Q, E, T, U;
    [2] integer K;
    label W, X;
  end;
