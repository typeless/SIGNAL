process COMPLEXSELECT =
  ( ? complex A; boolean B;
    ! complex Z, H, W, I; dcomplex E; )
  (| Z := A $ init (0.5 @ -0.5)
   | H := A when B
   | W := H default Z
   | I := if B then A else -A
   | E := H
   | A ^= B
   |)
  where
  end;
