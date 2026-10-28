process CALLINITERATEDELAY =
  ( ? [3] integer A;
    ! [3] integer B; )
  (| array I to 2 of
       B[I] := smooth(A[I])
     end
   |)
  where
    process smooth =
      ( ? integer x;
        ! integer y; )
      (| y := x + (x $ init 0) |);
  end;
