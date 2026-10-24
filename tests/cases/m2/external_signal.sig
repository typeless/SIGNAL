process P =
  ( ! long Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := 1
   |)
  where
    integer ZN, N;
    type MEM = external;
    MEM M;
  end;
