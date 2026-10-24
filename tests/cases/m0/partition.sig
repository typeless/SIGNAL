process PARTITION =
  ( ! integer N, M, S; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | M := (N when C) default ((-N) when not C)
   | M ^= N
   | S := M + N
   |)
  where
    integer ZN;
    boolean C;
  end;
