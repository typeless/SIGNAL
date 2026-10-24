process GUARDED =
  ( ! integer N, M, L, K; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | EVEN := when (N modulo 2 = 0)
   | on EVEN :: (| M := N * 10 | L := M + 1 | K := 7 |)
   |)
  where
    integer ZN;
    event EVEN;
  end;
