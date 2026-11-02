process COMPLEXARRAYWINDOWINIT =
  ( ? complex A;
    ! [2] complex W; [2] dcomplex V; )
  (| W := A window 2 init K
   | V := B window 2 init C
   | B := A
   |)
  where
    dcomplex B;
    constant dcomplex C = 3.0 @ 4.0;
    constant complex K = 1.0 @ 2.0;
  end;
