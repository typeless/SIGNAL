process TUPLECALLEXPRESSION =
  ( ? integer N; boolean C; ! integer T; )
  (| P := (N, N + 1)
   | Q := SWAP(P) when C
   | T := Q.X
   | C ^= N
   |)
  where
    struct (integer X; integer Y;) P, Q;
    function SWAP = ( ? struct (integer X; integer Y;) U; ! struct (integer X; integer Y;) V; ) (| V := (U.Y, U.X) |);
  end;
