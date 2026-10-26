process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := Q(N)
   |)
  where
    integer ZN, N;
    process Q = ( ? integer X; ! integer Y; ) deterministic (| Y := R(X) |);
    process R = ( ? integer X; ! integer Y; ) (| Y := X |);
  end;
