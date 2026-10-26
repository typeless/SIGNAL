process P =
  ( ! integer A; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := Q(N)
   |)
  where
    type OS = external;
    integer ZN, N;
    process Q = ( ? integer X; ! integer Y; ) deterministic (| R := syscall{OS}(4, 1, 0, 0, 0, 0, 0) when X = 0 | Y := X |) where long R; end;
  end;
