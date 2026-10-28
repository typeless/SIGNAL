process SEEDELEMENT =
  ( ! [2, 2] integer X; )
  (| A := [[1, 2], [3, 4]]
   | B := [[5, 6], [7, 8]]
   | array I to 1 of
       array J to 1 of
         array K to 1 of
           X[I, J] := X[?][I, J] + A[I, K] * B[K, J]
         with X[I, J] := 0
         end
       end
     end
   |)
  where
    [2, 2] integer A, B;
  end;
