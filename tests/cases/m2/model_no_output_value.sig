process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := SINK(N)
   |)
  where
    integer ZN, N;
    process SINK = ( ? integer X; ! ) (| Z := X |) where integer Z; end;
  end;
