process GUARDTICKFAIL =
  ( ! integer N, Y; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | X := N
   | C := N > 2
   | H := when (N modulo 2 = 0)
   | on H :: (| Y := X when C |)
   |)
  where
    integer ZN, X; boolean C; event H;
  end;
