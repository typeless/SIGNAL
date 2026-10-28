process STRUCTCLOCK =
  ( ? integer N; boolean C;
    ! integer T, U; )
  (| S := (N, N + 1) when C
   | R := (N * 2, N * 3) when C
   | R ^= S
   | T := N when ^S
   | U := R.B
   | C ^= N
   |)
  where
    struct (integer A; integer B;) S, R;
  end;
