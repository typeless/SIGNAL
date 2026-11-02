process COMPLEXCONSTANT =
  ( ! integer N; complex A; dcomplex D; complex E, C; dcomplex F; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := K
   | D := KD
   | E := KN
   | C := K when N > 1 default ZERO
   | F := FD $ init (2.5d0 @ -1.0d0)
   | FD := D + A
   | A ^= D ^= E ^= C ^= F ^= N
   |)
  where
    integer ZN;
    dcomplex FD;
    constant real THREEQUARTERS = 0.75;
    constant complex K = 1.0 @ (-1.0);
    constant dcomplex KD = -2.5d0 @ 0.5d0;
    constant complex KN = THREEQUARTERS @ -0.0;
    constant complex ZERO = 0.0 @ 0.0;
  end;
