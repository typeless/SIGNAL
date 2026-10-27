process F =
  ( ! integer A0; )
  (| G0 := when P0
   | A1 := INNER((N + N))
   | N := ZN + 1
   | on G0 :: (| K0 := ((A0 * 2) * 2) | on when (N > 1) :: (| K1 := ((N + A1) * 2) |) |)
   | ZN := N $ init 0
   | A0 := INNER((INNER(N) default INNER(N)))
   | Q := (N > 0)
   | P0 := (A0 > 0)
   |)
  where
    integer A1, N, ZN, K0, K1;
    boolean P0, Q;
    event G0;
    process INNER =
      ( ? integer U; ! integer O; )
      (| iQ0 := (U > 0)
       | iQ1 := (U > 1)
       | iL0 := ((U $ init 0) + U)
       | O := ((2 when iQ0) when not iQ0)
       |)
      where integer iL0; boolean iQ0, iQ1; end;
  end;
