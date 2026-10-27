process NULLDISJOINT =
  ( ! integer N, E, O; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 2 = 0
   | E := N when C
   | O := N when not C
   | ^0 ^= E ^* O
   |)
  where
    integer ZN;
    boolean C;
  end;
