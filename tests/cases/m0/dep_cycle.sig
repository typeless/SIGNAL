process DEP =
  ( ! integer A, B; )
  (| A := ZA + 1
   | ZA := A $ init 0
   | B := A * 2
   | B --> A
   |)
  where
    integer ZA;
  end;
