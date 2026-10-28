process SEEDITERATE =
  ( ? event TICK; ! [2] integer LX; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | iterate J1 of
       LX[J1] := LX[?][J1] + J1 + N
     with LX[J1] := 0
     end
   | J1 := indices(2)
   |)
  where
    integer ZN, N;
    [2] integer J1;
  end;
