process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(2)
   | iterate I of A := COPY(I) end
   | Y := A[0]
   |)
  where
    integer ZN, N;
    [2] integer I, A;
    process COPY = ( ? integer X; ! integer Z; ) (| Z := X |);
  end;
