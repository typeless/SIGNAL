process SAMPLE =
  ( ! integer N, S, H; boolean C; event W, K; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | C := N modulo 3 = 0
   | S := N when C
   | H := S $ init 100
   | W := when C
   | K := ^S
   | ZN --> S
   |)
  where
    integer ZN;
  end;
