module MATH =
  constant integer BASE = 10;
  private constant integer HIDDEN = 2;
  type SMALL = short;
  process SCALE = { integer K; } ( ? integer X; ! integer Y; ) (| Y := X * K + HIDDEN |);
end;
process P =
  ( ! integer A, B; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | A := SCALE{BASE}(N)
   | S := short(N)
   | B := integer(S) + BASE
   |)
  where
    use MATH;
    integer ZN, N;
    SMALL S;
  end;
