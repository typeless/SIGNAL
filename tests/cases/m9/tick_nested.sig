process TICKNESTED =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | on when N modulo 2 = 0 ::
       (| on when N modulo 4 = 0 :: (| Y := N |)
        |)
   |)
  where
    integer ZN;
  end;
