process IFS =
  ( ! integer X, Y; boolean B; integer E; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := if N > 2 then N * 10 else 0 - N
   | S := short(N)
   | Y := if (N modulo 2) = 0 then S else N + 100
   | B := if N < 3 then N = 1 else N = 4
   | C := (color#green when Z = #red) default (#blue when Z = #green) default #red
   | Z := C $ init #red
   | E := integer(if N = 2 then color#red else C)
   |)
  where
    type color = enum (red, green, blue);
    integer ZN, N;
    short S;
    color C, Z;
  end;
