process SEEDFILL =
  ( ! [3] integer T; )
  (| array I to 2 of
       T[I] := T[?][I] + I + 1
     with T := 5
     end
   |);
