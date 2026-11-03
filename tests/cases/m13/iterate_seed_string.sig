process ITERATESEEDSTRING =
  ( )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R :: A := read("" when ^N)
   | K := indices(1)
   | iterate K of (| Q := E[?] | E := A |) with E := "s" end
   | W :: write("q=", Q)
   | X :: write("a=", A)
   | R --> W --> X
   |)
  where
    integer N, ZN;
    string A, Q, E;
    [1] integer K;
    label R, W, X;
  end;
