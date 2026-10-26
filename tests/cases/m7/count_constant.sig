process P =
  ( ? integer T; ! integer N; )
  (| H1 := when (T modulo 2 = 1)
   | N := H1 count M
   |)
  where
    event H1;
    constant integer M = 3;
  end;
