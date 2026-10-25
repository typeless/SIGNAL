process F =
  ( ! integer Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Q1 := (N > 1)
   | X1 := N when Q1
   | Q2 := (N > 2)
   | X2 := N when Q2
   | Q3 := (N > 3)
   | X3 := N when Q3
   | Q4 := (N > 4)
   | X4 := N when Q4
   | Q5 := (N > 5)
   | X5 := N when Q5
   | Q6 := (N > 6)
   | X6 := N when Q6
   | Q7 := (N > 7)
   | X7 := N when Q7
   | Q8 := (N > 8)
   | X8 := N when Q8
   | S := (X1 default (X2 default (X3 default (X4 default (X5 default (X6 default (X7 default X8)))))))
   | Z := (X8 default (X7 default (X6 default (X5 default (X4 default (X3 default (X2 default X1))))))) default 0
   | Z ^= S
   |)
  where
    integer ZN, N, S, X1, X2, X3, X4, X5, X6, X7, X8;
    boolean Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8;
  end;
