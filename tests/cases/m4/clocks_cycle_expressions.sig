process CE =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | P := (N modulo 2) = 0
   | A := (B when P) + 1
   | B := (A when P) + 1
   |)
  where
    integer B, N, ZN;
    boolean P;
  end;
