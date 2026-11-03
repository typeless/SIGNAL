process ITERATESEEDREAD =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: A := read("" when ^N)
   | K := indices(1)
   | iterate K of (| Q := E[?] | E := "x" |) with E := A end
   | T := Q $ 1 init "t0"
   | W :: write("t=", T)
   | X :: write("a=", A)
   | R --> W --> X
   |)
  where
    integer N, ZN;
    string A, Q, E, T;
    [1] integer K;
    label R, W, X;
  end;
