process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := SUM(N)
   |)
  where
    integer ZN, N;
    node SUM = ( ? integer X; ! integer Y; ) deterministic (| Y := ZY + X | ZY := Y $ init 0 |) where integer ZY; end;
  end;
