process ENUMS =
  ( ! integer O; boolean G, B; )
  (| C := (color#green when Z = #red) default (#blue when Z = #green) default #red
   | Z := C $ init #red
   | O := integer(C)
   | G := C = #green
   | B := C > color#red
   |)
  where
    type color = enum (red, green, blue);
    color C, Z;
  end;
