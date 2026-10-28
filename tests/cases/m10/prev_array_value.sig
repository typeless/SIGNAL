process PREVARRAYVALUE =
  ( ! [3] integer V; integer C; )
  (| array I to 2 of
       (| V[I] := I | C := C[?] + g(V[?]) |)
     with (| C := 0 | V := Z |)
     end
   |)
  where
    constant [3] integer Z = [1, 1, 1];
    function g = ( ? [3] integer a; ! integer b; ) (| b := a[0] + a[1] + a[2] |);
  end;
