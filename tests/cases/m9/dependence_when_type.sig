process DEPENDENCEWHENTYPE =
  ( ! integer A, B; )
  (| A := ZA + 1
   | ZA := A $ init 0
   | B := A * 2
   | C := A > 2
   | {A --> B} when ZA
   |)
  where
    integer ZA; boolean C;
  end;
