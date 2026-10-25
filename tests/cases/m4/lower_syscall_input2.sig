process P =
  ( ! integer Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := integer(syscall{MEM}(1, 2, 0, 0, 0, 0, color#red))
   |)
  where
    integer ZN, N;
    type MEM = external; type color = enum(red, green);
  end;
