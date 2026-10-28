function ARRAYBOUNDINNER =
  ( ? [4] integer A; ! [4] integer T; )
  (| array j to 2 of
       array i to 2 - j of
         T := T[?] next (i : if T[?][i] > T[?][i + 1] then T[?][i + 1] else T[?][i])
       end
     with T := A
     end
   |);
