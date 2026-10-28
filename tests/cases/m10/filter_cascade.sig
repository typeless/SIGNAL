process FILTERCASCADE =
  ( ? integer X;
    ! [4] integer Y; )
  (| array I to 3 of
       Y[I] := FILTER(if I = 0 then X else Y[?][I - 1])
     end
   |)
  where
    process FILTER =
      ( ? integer u;
        ! integer v; )
      (| v := (u + (u $ init 0)) / 2 |);
  end;
