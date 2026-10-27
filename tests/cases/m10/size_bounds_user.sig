process SIZEBOUNDSUSER =
  ( ? integer I;
    ! integer A, B; )
  (| A := size(I, 3)
   | B := bounds(I, 1, 2)
   |)
  where
    function size = ( ? integer X, Y; ! integer Z; ) (| Z := X * Y |);
    function bounds = ( ? integer X, Y, W; ! integer Z; ) (| Z := X + Y + W |);
  end;
