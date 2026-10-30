process CHARSELECT =
  ( ? char A; integer N;
    ! char P, W, D, I, K, E; [2] char R; )
  (| P := A $ init 'z'
   | W := A when N > 0
   | D := W default P
   | I := if N > 1 then A else Q
   | case A in {'a', 'b'}: K := 'k' end
   | E := A cell (N > 2) init 'c'
   | R := [A, Q]
   |)
  where
    constant char Q = 'q';
  end;
