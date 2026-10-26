process P =
  ( ? integer N; ! integer Y; )
  (| C := (N modulo 3 = 0)
   | case N modulo 2 in {0}: Y := N cell C end
   |)
  where
    boolean C;
  end;
