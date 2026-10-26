process P =
  ( ! integer Y, Z; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | Y := B + N * 0
   | Z := C + N * 0
   |)
  where
    integer ZN, N;
    constant integer A = 3, B = A * 2 + 1, C = (B - 6) * ubyte(2);
  end;
