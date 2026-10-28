process SEEDITERATERANK2 =
  ( ? event TICK; ! [2, 2] integer X; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | N ^= TICK
   | A := [[1, 2], [3, 4]]
   | B := [[5, 6], [7, 8]]
   | iterate I of
       iterate J of
         iterate K of
           X[I, J] := X[?][I, J] + A[I, K] * B[K, J] + N - N
         with X[I, J] := 0
         end
       end
     end
   | I := indices(2)
   | J := indices(2)
   | K := indices(2)
   |)
  where
    integer N, ZN;
    [2, 2] integer A, B;
    [2] integer I, J, K;
  end;
