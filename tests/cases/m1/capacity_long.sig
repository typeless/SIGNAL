process CAPLONG =
  ( ! long X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | I := indices(1)
   | iterate I of T := T[?] next 0 : long(N) end
   | X := T[0]
   |)
  where
    integer ZN, N;
    [1] integer I;
    [9223372036854775808] long T;
  end;
