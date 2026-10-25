process NAMES =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | ZETA := ALPHA + N
   | ALPHA := MID + 1
   | MID := ZETA * 2
   | X := ZETA
   |)
  where
    integer ZN, N, ZETA, ALPHA, MID;
  end;
