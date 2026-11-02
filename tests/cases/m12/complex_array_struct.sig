process COMPLEXARRAYSTRUCT =
  ( ? complex A; real X; integer I;
    ! complex F; real G; [2] complex C; )
  (| M.C := [A, A * A]
   | M.R := [X, -X]
   | F := M[I].C
   | G := M[1].R
   | C := M.C
   | A ^= X ^= I
   |)
  where
    [2] struct (complex C; real R;) M;
  end;
