process NEGINIT =
  ( ! integer A, B; )
  (| A := ZA + 1
   | ZA := A $ init 0
   | B := A $ init -1
   |)
  where
    integer ZA;
  end;
