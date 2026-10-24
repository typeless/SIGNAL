process CALLER =
  ( ! integer N, A, B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := PREVIOUS(N)
   | B := PREVIOUS(A)
   |)
  where
    integer ZN;
    process PREVIOUS =
      ( ? integer X; ! integer Y; )
      (| Y := X $ init 0 |);
  end;
