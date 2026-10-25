process CT =
  ( ! integer C; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | P := (N modulo 2) = 0
   | C := B when P
   | B := A when P
   | A := C when P
   |)
  where
    integer A, B, N, ZN;
    boolean P;
  end;
