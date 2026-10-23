process NOTREE =
  ( ! integer A, B, C; )
  (| A := ZA + 1
   | ZA := A $ init 0
   | B := ZB + 10
   | ZB := B $ init 0
   | C := A default B
   |)
  where
    integer ZA, ZB;
  end;
