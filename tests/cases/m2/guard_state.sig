process GCOUNT =
  ( ! integer N, C; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | EVEN := when (N modulo 2 = 0)
   | on EVEN :: (| C := ZC + 1 | ZC := C $ init 0 |)
   |)
  where
    integer ZN, ZC;
    event EVEN;
  end;
