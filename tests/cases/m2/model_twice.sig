process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := N
   |)
  where
    integer ZN, N;
    process COPY = ( ? integer X; ! integer Z; ) (| Z := X |);
    process COPY = ( ? integer X; ! integer Z; ) (| Z := X |);
  end;
