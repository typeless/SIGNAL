process COMPLEXARRAYEXTRACT =
  ( ? [2] complex X; [1] complex Y; [2] integer K;
    ! [3] complex Z; [2] complex G; [2] complex S; [2, 2] complex R; )
  (| Z := X |+ Y
   | G := Z[K]
   | S := Z[1 .. 2]
   | R := tr M2
   | M2 := X window 2
   | X ^= Y ^= K
   |)
  where
    [2, 2] complex M2;
  end;
