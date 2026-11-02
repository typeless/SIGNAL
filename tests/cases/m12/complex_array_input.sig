process COMPLEXARRAYINPUT =
  ( ? [2] complex A; [2] dcomplex B;
    ! [2] complex X; [2] dcomplex Y; complex E; )
  (| X := A
   | Y := B
   | E := A[1]
   |)
  where
  end;
