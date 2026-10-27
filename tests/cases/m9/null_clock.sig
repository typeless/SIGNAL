process NULLCLOCK =
  ( ! integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N
   | X ^= ^0
   |)
  where
    integer N, ZN;
  end;
