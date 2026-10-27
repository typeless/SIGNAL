process NULLALONE =
  ( ! integer N, X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := 1
   | X ^= ^0
   |)
  where
    integer ZN;
  end;
