process IR =
  ( ? integer I;
    ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I ^= N when (N > 2)
   | Y := I
   |)
  where
    integer ZN, N;
  end;
