process COMPLEXARRAYCONSTANT =
  ( ? integer I; complex A;
    ! [2] complex T, N, D; [2] dcomplex TD; complex E; [3, 2] complex M; [2] complex W, L; complex Y; )
  (| T := K
   | TD := KD
   | E := K[I]
   | M := MK
   | N := K next I : A
   | D := X $ init K
   | X := [A, A]
   | W := A window 2 init K1
   | L := X $ 1 init [[1.0 @ -2.0, -3.0 @ 4.0]]
   | Y := A $ 2 init [1.0 @ 1.0, 2.0 @ 2.0]
   | I ^= A ^= T ^= TD ^= M
   |)
  where
    [2] complex X;
    constant [2] complex K = [1.0 @ 2.0, -3.0 @ -4.5];
    constant [2] dcomplex KD = [1.0d0 @ 2.0, 0.1 @ -0.0];
    constant [1] complex K1 = [7.0 @ 8.0];
    constant [3, 2] complex MK = [[1.0 @ 2.0, 3.0 @ 4.0], [5.0 @ 6.0, 7.0 @ 8.0], [9.0 @ 10.0, 11.0 @ 12.0]];
  end;
