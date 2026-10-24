process IFTYPES =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := N > 2
   | X := if B then N else B
   |)
  where
    integer ZN, N;
    boolean B;
  end;
