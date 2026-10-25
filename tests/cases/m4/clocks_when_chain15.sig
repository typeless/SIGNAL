process F =
  ( ! integer A1; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | P := (N modulo 2) = 0
   | A1 := A2 when P
   | A2 := A3 when P
   | A3 := A4 when P
   | A4 := A5 when P
   | A5 := A6 when P
   | A6 := A7 when P
   | A7 := A8 when P
   | A8 := A9 when P
   | A9 := A10 when P
   | A10 := A11 when P
   | A11 := A12 when P
   | A12 := A13 when P
   | A13 := A14 when P
   | A14 := A15 when P
   | A15 := N when P
   |)
  where
    integer ZN, N, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15;
    boolean P;
  end;
