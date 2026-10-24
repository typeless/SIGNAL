process RMAX =
  ( ! integer A, B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | E := 9223372036854775807 when N >= 1
   | X := 0 .. E
   | iterate X of S := S[?] + 1 with S := 0 end
   | A := S
   | F := (ulong(0) - ulong(1)) when N >= 1
   | Y := 0 .. F
   | iterate Y of T := T[?] + 1 with T := 0 end
   | B := T
   |)
  where
    integer ZN, N, S, T;
    long E;
    ulong F;
    [5] integer X, Y;
  end;
