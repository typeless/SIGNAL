process TWO =
  ( ! integer A, B, E; )
  (| B := ZB + 10
   | ZB := B $ init 0
   | A := ZA + 1
   | ZA := A $ init 0
   | E := B when (B modulo 20 = 0)
   |)
  where
    integer ZA, ZB;
  end;
