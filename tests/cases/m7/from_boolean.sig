process P =
  ( ? integer T; ! integer N; )
  (| B1 := T modulo 2 = 1
   | B2 := T >= 2
   | N := B2 from B1
   |)
  where
    boolean B1, B2;
  end;
