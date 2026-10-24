process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := COPY(long(N))
   |)
  where
    integer ZN, N;
    process COPY = ( ? integer X; ! integer Z; ) (| Z := X |);
  end;
