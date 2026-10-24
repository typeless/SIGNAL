process PARTCONST =
  ( ! integer N, W; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | V := (1 when C) default (0 when not C)
   | W := V + N
   |)
  where
    integer ZN, V;
    boolean C;
  end;
