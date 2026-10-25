process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := integer(syscall{MEM}(1, true, 0, 0, 0, 0, 0))
   |)
  where
    integer ZN, N;
    type MEM = external;
  end;
