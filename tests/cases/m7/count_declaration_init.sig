process P =
  ( ? integer T; ! integer N init 5; )
  (| H1 := when (T modulo 2 = 1)
   | N := H1 count 3
   |)
  where
    event H1;
  end;
