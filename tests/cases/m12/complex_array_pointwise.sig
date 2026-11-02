process COMPLEXARRAYPOINTWISE =
  ( ? complex A, B; boolean C;
    ! [2] complex S, N, M, D, G, F; [2] boolean Q; boolean X; )
  (| T := [A, B]
   | U := [B, A]
   | S := T + U
   | N := - T
   | M := T * U
   | D := T / U
   | G := if C then T else U
   | F := (T when C) default U
   | Q := T = U
   | X := T == U
   | A ^= B ^= C
   |)
  where
    [2] complex T, U;
  end;
