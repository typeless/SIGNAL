process BUNDLECLOCK =
  ( ? integer N; ! integer T; )
  (| B.P := N
   | B.Q := N + 1
   | T := 1 when ^B
   |)
  where
    bundle (integer P; integer Q;) B;
  end;
