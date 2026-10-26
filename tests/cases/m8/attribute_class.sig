process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := F(N)
   |)
  where
    integer ZN, N;
    function F = ( ? integer X; ! integer Y; ) unsafe (| Y := X |);
  end;
