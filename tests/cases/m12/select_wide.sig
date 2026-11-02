process SELECTWIDE =
  ( ? real X; dreal D; boolean B;
    ! dreal E; )
  (| E := if B then X else D
   | X ^= D ^= B
   |)
  where
  end;
