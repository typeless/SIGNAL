process SEEDCALL =
  ( ! integer C; )
  (| array I to 2 of
       C := C[?] + 1
     with C := g(4)
     end
   |)
  where
    function g = ( ? integer a; ! integer b; ) (| b := a + 1 |);
  end;
