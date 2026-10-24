process LORDER =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | L1 :: X := N
   | L2 :: Y := X + 1
   | L2 --> L1
   |)
  where
    integer ZN, N, X;
    label L1, L2;
  end;
