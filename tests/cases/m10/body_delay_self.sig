process BODYSELF =
  ( ! [3] integer T; )
  (| array I to 2 of
       T[I] := (T $ init Z)[I] + 1
     end
   |)
  where
    constant [3] integer Z = [7, 8, 9];
  end;
