process COMPLEXARRAYWINDOW =
  ( ? complex A, B;
    ! [2] complex W, L; [2, 2] complex WT; complex E; )
  (| T := [A, B]
   | W := A window 2
   | WT := T window 2
   | L := T $ 1
   | E := (T window 2)[0, 1]
   | A ^= B
   |)
  where
    [2] complex T;
  end;
