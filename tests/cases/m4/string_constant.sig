process TEXT =
  ( ! ubyte B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | B := GREETING[(N - 1) modulo 5]
   |)
  where
    constant [5] ubyte GREETING = "A é~";
    integer ZN, N;
  end;
