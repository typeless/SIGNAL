process ARRAYDELAY =
  ( ! integer X; [3] integer A, B, C, D; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | T := T $ next 0 : N
   | X := T[0]
   | A := [N, N * 10, -N]
   | B := A $
   | C := A $ init C0
   | D := (A $ init C0) $
   |)
  where
    integer ZN, N;
    [4] integer T;
    constant [3] integer C0 = [7, 8, 9];
  end;
