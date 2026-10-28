process NEXTPAIR =
  ( ! [2, 3] integer T; )
  (| array I to 1 of
       array J to 2 of
         T := T[?] next (I, J) : I * 10 + J
       end
     with T := Z
     end
   |)
  where
    constant [2, 3] integer Z = [[9, 9, 9], [9, 9, 9]];
  end;
