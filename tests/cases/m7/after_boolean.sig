process P =
  ( ? integer T; ! integer N; )
  (| B1 := T modulo 2 = 1
   | B2 := T >= 2
   | N := B1 after B2
   |)
  where
    boolean B1, B2;
  end;
