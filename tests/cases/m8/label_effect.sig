process P =
  ( ! integer N, Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | W :: R := syscall{OS}(4, 1, 0, 0, 0, 0, N when N modulo 4 = 0)
   | Z := N when ^W
   |)
  where
    type OS = external;
    integer ZN;
    long R;
    label W;
  end;
