process COMPARE =
  ( ? real A, B; dreal C, E;
    ! boolean EQ, NE, LT, LE, GT, GE, EQD, NED, LTD, LED, GTD, GED, MIXED; )
  (| EQ := A = B
   | NE := A /= B
   | LT := A < B
   | LE := A <= B
   | GT := A > B
   | GE := A >= B
   | EQD := C = E
   | NED := C /= E
   | LTD := C < E
   | LED := C <= E
   | GTD := C > E
   | GED := C >= E
   | MIXED := A < E
   |)
  where
  end;
