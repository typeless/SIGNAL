process STRUCTFIELDS =
  ( ? integer N;
    ! struct (integer A; boolean B;) S; integer T; )
  (| S.A := N * 2
   | S.B := N > 1
   | T := S.A + 1
   |)
  where
  end;
