process STRUCTIO =
  ( ? struct (integer X; integer Y;) P;
    ! struct (integer X; integer Y;) Q; integer R; )
  (| Q := (P.Y, P.X + P.Y)
   | R := Q.X * 10
   |)
  where
  end;
