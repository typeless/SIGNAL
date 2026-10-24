process P =
  ( ! long Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := syscall{MEM}(1, 2, 3, 4, 5, 6, 7, 8)
   |)
  where
    integer ZN, N;
    type MEM = external;
  end;
