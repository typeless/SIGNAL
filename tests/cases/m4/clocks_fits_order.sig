process FO =
  ( ! integer A, B, C; )
  (| B := ZB + 10
   | ZB := B $ init 0
   | A := ZA + 1
   | ZA := A $ init 0
   | C := B default A
   |)
  where
    integer ZA, ZB;
  end;
