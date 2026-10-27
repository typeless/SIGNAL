process EXCLINSIDE =
  ( ! integer X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N * 2
   | Y := N * 3
   | C := X > 4
   | {X --> Y} when C
   | {Y --> X} when not C
   |)
  where
    integer ZN, N; boolean C;
  end;
