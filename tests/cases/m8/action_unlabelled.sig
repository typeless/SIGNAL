process P =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | LOG(N)
   |)
  where
    type OS = external;
    integer ZN;
    action LOG = ( ? integer X; ) (| R := syscall{OS}(4, 1, 0, 0, 0, 0, X when X = 0) |) where long R; end;
  end;
