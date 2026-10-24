process WINDOWS =
  ( ! long X, Y, Z, W; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | V := long(N)
   | I := indices(1)
   | iterate I of
       (| T := T[?] next 262143 : V
        | U := U[?] next 0 : (0 - V)
        |)
     end
   | X := T[262143]
   | Y := U[0]
   | Z := T[0]
   | W := U[262143]
   |)
  where
    integer ZN, N;
    long V;
    [1] integer I;
    [262144] long T, U;
  end;
