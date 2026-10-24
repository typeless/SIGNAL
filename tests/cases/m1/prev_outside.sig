process POUT =
  ( ! integer A; )
  (| A := ZA[?] + 1
   | ZA := A $ init 0
   |)
  where
    integer ZA;
  end;
