process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | E := N when (N modulo 2 = 0)
   | C := N when (N modulo 3 = 1)
   | Y := var E
   | Y ^= C
   |)
  where
    integer N, ZN, E, C;
  end;
