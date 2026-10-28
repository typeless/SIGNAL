process INNERWITH =
  ( ! integer R; )
  (| array I to 1 of
       array J to 1 of
         R := R[?] + 1
       with R := 0
       end
     end
   |);
