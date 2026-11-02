process COMPLEXARRAYITERATE =
  ( ? [2] complex X; complex A;
    ! [2] complex LX; [2] dcomplex DX; )
  (| I := indices(2)
   | I ^= X ^= A
   | iterate I of
       LX[I] := LX[?][I] + X[I] * A
     with LX[I] := 1.0 @ 1.0
     end
   | iterate I of
       DX[I] := DX[?][I] * A
     with DX[I] := 0.1 @ 0.2
     end
   |)
  where
    [2] integer I;
  end;
