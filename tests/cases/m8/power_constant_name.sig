process P =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := Q(N)
   |)
  where
    integer ZN;
    constant integer K = 2;
    process Q =
      ( ? integer X; ! integer Y; )
      (| Y := X ** K |);
  end;
