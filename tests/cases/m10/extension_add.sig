process EXTADD =
  ( ? [3] integer A, B;
    ! [3] integer C, D; [3] boolean E, F; [3] integer G; [3] long H; )
  (| C := A + B
   | D := (A + 1) * B
   | E := A < B
   | F := not E
   | G := -A
   | H := long(A) * long(1000000000)
   |);
