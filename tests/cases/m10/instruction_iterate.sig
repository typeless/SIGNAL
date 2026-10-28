process INSTRUCTIONITERATE =
  ( ? [3] ulong A;
    ! [3] ulong B; )
  (| array I to 2 of
       B[I] := instruction{CPU, ADD_ONE}(A[I])
     end
   |)
  where
    type CPU = external;
    constant long ADD_ONE = 2432697344;
  end;
