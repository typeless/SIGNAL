process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := PEEK(N)
   |)
  where
    integer ZN, N;
    process PEEK = ( ? integer X; ! integer Z; ) (| Z := X + ZN |);
  end;
