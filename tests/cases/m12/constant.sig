process CONSTANTS =
  ( ! integer N; real A, B, C; dreal D, E, F; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := PI
   | B := NEGATIVE
   | C := PI when N > 1 default ZERO
   | D := TAU
   | E := A
   | F := FD $ init 2.5d0
   | FD := D + E
   | A ^= B ^= C ^= D ^= E ^= F ^= N
   |)
  where
    integer ZN;
    dreal FD;
    constant real PI = 3.14159274;
    constant real NEGATIVE = -1.25e-3;
    constant real ZERO = 0.0;
    constant dreal TAU = 6.283185307179586d0;
  end;
