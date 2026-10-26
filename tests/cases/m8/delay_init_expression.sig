process P =
  ( ! integer Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Z := D(N)
   |)
  where
    integer ZN, N;
    constant integer K = 5;
    process D = ( ? integer X; ! integer Y; )
      (| Y := X $ init (K * 2) |);
  end;
