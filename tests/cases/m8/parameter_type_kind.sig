process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := CAST{3}(N)
   |)
  where
    integer ZN, N;
    process CAST = { type T; } ( ? integer X; ! integer Y; ) (| Y := X |);
  end;
