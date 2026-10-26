process GUARDED =
  ( ! integer N; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | EVEN := when (N modulo 2 = 0)
   | on EVEN :: (| |)
   |)
  where
    integer ZN;
    event EVEN;
  end;
