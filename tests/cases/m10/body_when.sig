process BODYWHEN =
  ( ! integer A; )
  (| array I to 1 of
       array J to 1 of
         A := (A[?] + I) when (J > 0)
       end
     end
   |);
