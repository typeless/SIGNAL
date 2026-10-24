process BOOLORDER =
  ( ! boolean P, Q, LT, LE, GT, GE; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | P := N modulo 4 >= 2
   | Q := N modulo 2 = 0
   | LT := P < Q
   | LE := P <= Q
   | GT := P > Q
   | GE := P >= Q
   |)
  where
    integer N, ZN;
  end;
