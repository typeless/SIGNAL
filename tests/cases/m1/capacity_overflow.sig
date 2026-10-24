process CAPOVER =
  ( ! long X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(1)
   | iterate I of T := T[?] next 5000 : long(N) end
   | X := T[5000]
   |)
  where
    integer ZN, N;
    [1] integer I;
    [2305843009213693953] long T;
  end;
