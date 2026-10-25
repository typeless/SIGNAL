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
   | Q9 := (N > 9)
   | X9 := N when Q9
   | Q10 := (N > 10)
   | X10 := N when Q10
   | Q11 := (N > 11)
   | X11 := N when Q11
   | Q12 := (N > 12)
   | X12 := N when Q12
   | Q13 := (N > 13)
   | X13 := N when Q13
   | Q14 := (N > 14)
   | X14 := N when Q14
   | Q15 := (N > 15)
   | X15 := N when Q15
   | Q16 := (N > 16)
   | X16 := N when Q16
   | Q17 := (N > 17)
   | X17 := N when Q17
   | S := (X1 default (X2 default (X3 default (X4 default (X5 default (X6 default (X7 default (X8 default (X9 default (X10 default (X11 default (X12 default (X13 default (X14 default (X15 default (X16 default X17))))))))))))))))
   | Z := X17 default 0
   | Z ^= S
   |)
  where
    integer ZN, N, S, X1, X2, X3, X4, X5, X6, X7, X8, X9, X10, X11, X12, X13, X14, X15, X16, X17;
    boolean Q1, Q2, Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14, Q15, Q16, Q17;
  end;

