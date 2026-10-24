process SWAP =
  ( ! integer A0, A1, B0, B1; )
  (| I := indices(2)
   | iterate I of
       (| A := B[?][R]
        | B := A[?] next I : I + 10
        |)
     with (| A := SA | B := SB |)
     end
   | A0 := A[0]
   | A1 := A[1]
   | B0 := B[0]
   | B1 := B[1]
   |)
  where
    constant [2] integer R = [1, 0];
    constant [2] integer SA = [1, 2];
    constant [2] integer SB = [3, 4];
    [2] integer I, A, B;
  end;
