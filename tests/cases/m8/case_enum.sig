process P =
  ( ! integer A; )
  (| N := ZN + 1 | ZN := N $ init 0
   | S := if N modulo 2 = 0 then COLOR#RED else COLOR#GREEN
   | case S in {COLOR#GREEN}: A := 1 end
   |)
  where type COLOR = enum (RED, GREEN); integer ZN, N; COLOR S; end;
