process P =
  ( ? integer T; ! integer N; )
  (| H1 := when (T modulo 2 = 1)
   | H2 := when (T >= 2)
   | N := H1 from H2
   |)
  where
    event H1, H2;
  end;
