process P =
  ( ? integer N; ! integer Y; )
  (| C := when (N modulo 2 = 0)
   | on C :: (| Y := N cell C init 0 |)
   |)
  where
    event C;
  end;
