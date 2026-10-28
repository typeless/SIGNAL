process EXTENSIONSTRUCT =
  ( ? integer N; boolean C;
    ! struct (integer X; integer Y;) Z, D, W; )
  (| S := (N, N * 2)
   | T := (10, 20) when ^N
   | Z := S + T
   | D := S $ 1 init (-1, -2)
   | W := S when C default T
   | C ^= N
   |)
  where
    type POINT = struct (integer X; integer Y;);
    POINT S, T;
  end;
