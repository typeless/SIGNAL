process MEMO =
  ( ! integer N, D; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := N when (N modulo 2 = 0)
   | B := N when (N modulo 3 = 0)
   | S := A default B
   | D := A default 0
   | D ^= S
   |)
  where
    integer ZN, A, B, S;
  end;
