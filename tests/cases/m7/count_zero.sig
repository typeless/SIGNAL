process P =
  ( ? integer T; ! integer N; )
  (| H1 := when (T modulo 2 = 1)
   | N := H1 count 0
   |)
  where
    event H1;
  end;
