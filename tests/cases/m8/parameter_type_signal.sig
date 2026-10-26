process P =
  ( ! integer A; ubyte B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := TWICE{integer}(N * 100)
   | B := TWICE{ubyte}(ubyte(N * 100))
   |)
  where
    integer ZN, N;
    process TWICE = { type T; } ( ? T X; ! T Y; ) (| Y := X + X |);
  end;
