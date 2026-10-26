module FIRST =
  constant integer K = 1;
end;
process P = ( ! integer A; ) (| A := ZA + K | ZA := A $ init 0 |) where use FIRST, SECOND; integer ZA; end;
