process ALIAS =
  ( ! ushort H; )
  (| H := ZH + ushort(32768)
   | ZH := H $
   |)
  where
    word ZH;
    type word = ushort;
  end;
