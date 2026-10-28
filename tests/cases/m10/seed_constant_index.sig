process SEEDCONSTANT =
  ( ! [3] integer T; )
  (| array I to 2 of
       T[I] := T[?][I] + I
     with T[1] := 5
     end
   |);
