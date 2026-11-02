process LITERAL =
  ( ! integer N; real R1; real R2; real R3; real R4; real R5; real R6; real R7; real R8; real R9; real R10; real R11; dreal D1; dreal D2; dreal D3; dreal D4; dreal D5; dreal D6; dreal D7; dreal D8; dreal D9; dreal D10; dreal D11; )
  (| N := ZN + 1
   | ZN := N $ init 0
   | R1 := 1.5
   | R2 := 0.1
   | R3 := 1e10
   | R4 := 3.4028235e38
   | R5 := 1.0e-45
   | R6 := -0.0
   | R7 := 0.0001
   | R8 := 0.00001
   | R9 := 1E+2
   | R10 := 16777217.0
   | R11 := -2.5e-3
   | D1 := 1.0d0
   | D2 := 0.1d0
   | D3 := 1.7976931348623157d308
   | D4 := 4.9d-324
   | D5 := -2.5D0
   | D6 := 1d-5
   | D7 := 123456789012345678d0
   | D8 := 1234567890123456.0d0
   | D9 := 12345678901234567.0d0
   | D10 := 9007199254740993d0
   | D11 := 2.2250738585072014d-308
   | R1 ^= R2 ^= R3 ^= R4 ^= R5 ^= R6 ^= R7 ^= R8 ^= R9 ^= R10 ^= R11 ^= D1 ^= D2 ^= D3 ^= D4 ^= D5 ^= D6 ^= D7 ^= D8 ^= D9 ^= D10 ^= D11 ^= N
   |)
  where
    integer ZN;
  end;
