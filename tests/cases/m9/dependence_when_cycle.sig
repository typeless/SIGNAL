process DEPENDENCEWHENCYCLE =
  ( ! integer X, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N * 2
   | Y := N * 3
   | C := (N modulo 2) = 0
   | {X --> Y} when C
   | {Y --> X} when not C
   |)
  where
    integer ZN, N; boolean C;
  end;
