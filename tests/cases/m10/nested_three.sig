process THREE =
  ( ! integer S; integer C; )
  (| array I to 1 of
       array J to 2 of
         array K to 1 of
           (| S := S[?] * 2 + I * 100 + J * 10 + K
            | C := C[?] + 1
            |)
         end
       end
     with (| S := 0 | C := 0 |)
     end
   |);
