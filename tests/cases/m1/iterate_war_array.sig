process WARARRAY =
  ( ! integer Q, Y; )
  (| I := ZEROS
   | iterate I of
       (| Y := Z[I]
        | Q := Z[?][I]
        | C := C[?] + 1
        | Z := Z[?] next I : C
        |)
     with C := 0
     end
   |)
  where
    constant [4] integer ZEROS = [0, 0, 0, 0];
    integer C;
    [4] integer I;
    [1] integer Z;
  end;
