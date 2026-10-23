process ORDER =
  ( ! integer N, T; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C2 := N modulo 2 = 0
   | C3 := N modulo 3 = 0
   | Q := (N when C2) when C3
   | R := (N when C3) when C2
   | T := Q + R
   |)
  where
    integer ZN, Q, R;
    boolean C2, C3;
  end;
