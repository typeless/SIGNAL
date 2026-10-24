process SIGC =
  ( ! )
  (| ARGC := integer(instruction{ARGS, 2853766112}(ulong(0)))
   | ARGV := pointer(instruction{ARGS, 2853831648}(ulong(ARGC)))
   | ARG1 := load{ARGS, pointer}(ARGV + 8)
   | ARG2 := load{ARGS, pointer}(ARGV + 16)
   | ARG3 := load{ARGS, pointer}(ARGV + 24)
   | ARG1 --> ARG2
   | ARG2 --> ARG3
   | ARGUMENT_COUNT_OK := ARGC = 4
   | DASH_INDEX := 0 .. (if ARGUMENT_COUNT_OK then 2 else -1)
   | iterate DASH_INDEX of
       (| DASH_BYTE := load{ARGS, ubyte}(ARG2 + DASH_INDEX)
        | DASH_MATCHES := DASH_MATCHES[?] and DASH_BYTE = OUTPUT_OPTION[DASH_INDEX]
        |)
     with DASH_MATCHES := true
     end
   | ARG3 --> DASH_BYTE
   | USAGE_OK := ARGUMENT_COUNT_OK and DASH_MATCHES
   | PATH_INDEX := 0 .. (if USAGE_OK then ARG_CAP - 1 else -1)
   | iterate PATH_INDEX of
       (| PATH_BYTE := load{ARGS, ubyte}(if PATH_ENDED[?] then ARG1 else ARG1 + PATH_INDEX)
        | PATH_ENDED := PATH_ENDED[?] or PATH_BYTE = ubyte(0)
        | PATH_LENGTH := if PATH_ENDED then PATH_LENGTH[?] else PATH_INDEX + 1
        | PATH_TEXT := PATH_TEXT[?] next PATH_INDEX : PATH_BYTE
        |)
     with (| PATH_ENDED := false | PATH_LENGTH := 0 |)
     end
   | BUFFER_ADDRESS := syscall{OS}(if USAGE_OK then 197 else 20, 0, OUTPUT_CAP, 3, 4098, -1, 0)
   | SOURCE_FD := syscall{OS}(if USAGE_OK then 5 else 20, ARG1, 0, 0, 0, 0, 0)
   | BUFFER_ADDRESS --> SOURCE_FD
   | OPEN_OK := USAGE_OK and SOURCE_FD >= 0
   | PROBE := syscall{OS}(if OPEN_OK then 3 else 20, SOURCE_FD, BUFFER_ADDRESS, 1, 0, 0, 0)
   | READ_OK := OPEN_OK and PROBE >= 0
   | SIZE := syscall{OS}(if READ_OK then 199 else 20, SOURCE_FD, 0, 2, 0, 0, 0)
   | SIZE_OK := READ_OK and SIZE >= 0
   | SOURCE_FITS := SIZE <= long(SRC_CAP - 4)
   | MAP_WANTED := SIZE_OK and SOURCE_FITS and SIZE > 0
   | MAPPED := syscall{OS}(if MAP_WANTED then 197 else 20, 0, SIZE, 1, 2, SOURCE_FD, 0)
   | MAP_OK := not MAP_WANTED or MAPPED >= 0
   | SOURCE_CLOSED := syscall{OS}(if OPEN_OK then 6 else 20, SOURCE_FD, 0, 0, 0, 0, 0)
   | MAPPED --> SOURCE_CLOSED
   | ERRNO := if not USAGE_OK then 0 else if not OPEN_OK then integer(-SOURCE_FD) else if not READ_OK then integer(-PROBE)
              else if not SIZE_OK then integer(-SIZE) else if not MAP_OK then integer(-MAPPED) else 0
   | SOURCE_OK := USAGE_OK and ERRNO = 0 and SOURCE_FITS
   | LENGTH := integer(SIZE)
   | SOURCE_BASE := pointer(ulong(MAPPED))
   | COPY_INDEX := 0 .. (if SOURCE_OK then LENGTH - 1 else -1)
   | iterate COPY_INDEX of
       (| SOURCE_BYTE := load{FILE, ubyte}(SOURCE_BASE + COPY_INDEX)
        | SRC := SRC[?] next COPY_INDEX : SOURCE_BYTE
        |)
     end
   | LEX_INDEX := 0 .. (if SOURCE_OK then LENGTH + 1 else -1)
   | iterate LEX_INDEX of
       (| AT_EOF := LEX_INDEX = LENGTH
        | AT_END := LEX_INDEX >= LENGTH
        | BYTE := SRC[LEX_INDEX]
        | NEXT_BYTE := SRC[LEX_INDEX + 1]
        | CLASS := CHARACTER_CLASS[BYTE]
        | PREVIOUS_MODE := MODE[?]
        | CONTINUES := not AT_END
            and (PREVIOUS_MODE = MODE_NAME and (CLASS = CLASS_LETTER or CLASS = CLASS_DIGIT)
                 or PREVIOUS_MODE = MODE_NUMBER and CLASS = CLASS_DIGIT
                 or PREVIOUS_MODE = MODE_COMMENT or PREVIOUS_MODE = MODE_STRING or PREVIOUS_MODE = MODE_SYMBOL)
        | STARTS := not CONTINUES
        | SYMBOL_LENGTH := if BYTE = ubyte(45) and NEXT_BYTE = ubyte(45) and SRC[LEX_INDEX + 2] = ubyte(62) then 3
                           else if PAIR_SECOND[BYTE] /= 0 and PAIR_SECOND[BYTE] = NEXT_BYTE
                                   or BYTE = ubyte(58) and NEXT_BYTE = ubyte(61) then 2
                           else if CLASS = CLASS_SYMBOL then 1 else 0
        | OPENED_KIND := if AT_EOF then KIND_EOF else if AT_END then KIND_NONE else OPENED_KIND_OF_CLASS[CLASS]
        | OPENS_TOKEN := STARTS and OPENED_KIND /= KIND_NONE
        | REMAINING := if STARTS then SYMBOL_LENGTH - 1 else REMAINING[?] - 1
        | MODE := if STARTS then (if AT_END then MODE_IDLE else if SYMBOL_LENGTH > 1 then MODE_SYMBOL else MODE_OF_CLASS[CLASS])
                  else if PREVIOUS_MODE = MODE_COMMENT and BYTE = ubyte(37)
                       or PREVIOUS_MODE = MODE_STRING and BYTE = ubyte(34)
                       or PREVIOUS_MODE = MODE_SYMBOL and REMAINING = 0 then MODE_IDLE
                  else PREVIOUS_MODE
        | COLUMN := CODE_POINTS[?] - LINE_START[?] + 1
        | ENDS_LINE := not AT_END and (BYTE = ubyte(10) or BYTE = ubyte(13) and NEXT_BYTE /= ubyte(10))
        | CODE_POINTS := CODE_POINTS[?]
                         + integer(not (BYTE = ubyte(13) and NEXT_BYTE = ubyte(10)) and (BYTE < ubyte(128) or BYTE >= ubyte(192)))
        | LINE_START := if ENDS_LINE then CODE_POINTS else LINE_START[?]
        | LINE := LINE[?] + integer(ENDS_LINE)
        | OPEN_AT := if STARTS then LEX_INDEX else OPEN_AT[?]
        | OPEN_LINE := if STARTS then LINE[?] else OPEN_LINE[?]
        | OPEN_COLUMN := if STARTS then COLUMN else OPEN_COLUMN[?]
        | OPEN_KIND := if STARTS then OPENED_KIND else OPEN_KIND[?]
        | PENDING := if STARTS then (if OPENS_TOKEN then TOKEN_COUNT[?] else -1) else PENDING[?]
        | LETTER := LETTER_VALUE[BYTE]
        | KEY := if STARTS then ulong(LETTER) else KEY[?] * ulong(32) + ulong(LETTER)
        | NOT_ALL_LETTERS := not STARTS and NOT_ALL_LETTERS[?] or LETTER = 0
        | HAS_LOWER := not STARTS and HAS_LOWER[?] or BYTE >= ubyte(97) and BYTE <= ubyte(122)
        | HAS_UPPER := not STARTS and HAS_UPPER[?] or BYTE >= ubyte(65) and BYTE <= ubyte(90)
        | FINISHED_LENGTH := if OPEN_KIND[?] = KIND_EOF then 0 else LEX_INDEX - OPEN_AT[?]
        | IS_KEYWORD := OPEN_KIND[?] = KIND_NAME and not NOT_ALL_LETTERS[?] and FINISHED_LENGTH <= KEYWORD_LENGTH_MAX
                        and KEYWORD_KEYS[integer(KEY[?] modulo ulong(KEYWORD_MODULUS))] = KEY[?]
                        and not (HAS_LOWER[?] and HAS_UPPER[?])
        | FINISHED_SLOT := if STARTS then PENDING[?] else -1
        | TOKEN_KIND := TOKEN_KIND[?] next FINISHED_SLOT : ubyte(if IS_KEYWORD then KIND_KEYWORD else OPEN_KIND[?])
        | TOKEN_LENGTH := TOKEN_LENGTH[?] next FINISHED_SLOT : FINISHED_LENGTH
        | OPENED_SLOT := if OPENS_TOKEN then TOKEN_COUNT[?] else -1
        | TOKEN_START := TOKEN_START[?] next OPENED_SLOT : LEX_INDEX
        | TOKEN_LINE := TOKEN_LINE[?] next OPENED_SLOT : LINE[?]
        | TOKEN_COLUMN := TOKEN_COLUMN[?] next OPENED_SLOT : COLUMN
        | TOKEN_COUNT := TOKEN_COUNT[?] + integer(OPENS_TOKEN)
        | UNCLOSED := AT_EOF and (PREVIOUS_MODE = MODE_COMMENT or PREVIOUS_MODE = MODE_STRING)
                      or CONTINUES and PREVIOUS_MODE = MODE_STRING and (BYTE = ubyte(10) or BYTE = ubyte(13))
        | UNEXPECTED := STARTS and not AT_END and (CLASS = CLASS_INVALID or CLASS = CLASS_DOT and SYMBOL_LENGTH < 2)
        | FOUND := if UNEXPECTED or UNCLOSED then ERROR_UNEXPECTED
                   else if OPENS_TOKEN and TOKEN_COUNT[?] >= TOKEN_CAP then ERROR_TOKENS else ERROR_NONE
        | FIRST_FOUND := LEX_ERROR[?] = ERROR_NONE and FOUND /= ERROR_NONE
        | LEX_ERROR := if FIRST_FOUND then FOUND else LEX_ERROR[?]
        | LEX_ERROR_LINE := if not FIRST_FOUND then LEX_ERROR_LINE[?] else if UNCLOSED then OPEN_LINE[?] else LINE[?]
        | LEX_ERROR_COLUMN := if not FIRST_FOUND then LEX_ERROR_COLUMN[?] else if UNCLOSED then OPEN_COLUMN[?] else COLUMN
        | LEX_ERROR_AT := if not FIRST_FOUND then LEX_ERROR_AT[?] else if UNCLOSED then OPEN_AT[?] else LEX_INDEX
        |)
     with (| MODE := MODE_IDLE | REMAINING := 0 | CODE_POINTS := 0 | LINE_START := 0 | LINE := 1
           | OPEN_AT := 0 | OPEN_LINE := 1 | OPEN_COLUMN := 1 | OPEN_KIND := KIND_NONE | PENDING := -1
           | KEY := ulong(0) | NOT_ALL_LETTERS := false | HAS_LOWER := false | HAS_UPPER := false | TOKEN_COUNT := 0
           | LEX_ERROR := ERROR_NONE | LEX_ERROR_LINE := 0 | LEX_ERROR_COLUMN := 0 | LEX_ERROR_AT := 0 |)
     end
   | SOURCE_TOO_BIG := USAGE_OK and ERRNO = 0 and not SOURCE_FITS
   | ERROR := if SOURCE_TOO_BIG then ERROR_SRC else LEX_ERROR
   | ERROR_LINE := if SOURCE_TOO_BIG then 1 else LEX_ERROR_LINE
   | ERROR_COLUMN := if SOURCE_TOO_BIG then 1 else LEX_ERROR_COLUMN
   | ERROR_LEAD := SRC[LEX_ERROR_AT]
   | ERROR_MULTIBYTE := ERROR_LEAD >= ubyte(192)
   | ERROR_FIRST_CONTINUES := ERROR_MULTIBYTE and SRC[LEX_ERROR_AT + 1] >= ubyte(128) and SRC[LEX_ERROR_AT + 1] < ubyte(192)
   | ERROR_SECOND_CONTINUES := ERROR_FIRST_CONTINUES and SRC[LEX_ERROR_AT + 2] >= ubyte(128) and SRC[LEX_ERROR_AT + 2] < ubyte(192)
   | ERROR_THIRD_CONTINUES := ERROR_SECOND_CONTINUES and SRC[LEX_ERROR_AT + 3] >= ubyte(128) and SRC[LEX_ERROR_AT + 3] < ubyte(192)
   | ERROR_CHARACTER_LENGTH := if ERROR /= ERROR_UNEXPECTED then 0
                               else 1 + integer(ERROR_FIRST_CONTINUES) + integer(ERROR_SECOND_CONTINUES) + integer(ERROR_THIRD_CONTINUES)
   | LAYOUT := if not USAGE_OK then LAYOUT_NONE else if ERRNO /= 0 then LAYOUT_OS
               else if DUMP_PASS = 1 then (if ERROR /= ERROR_NONE then LAYOUT_DUMP_ERROR else LAYOUT_DUMP_TOKENS)
               else if ERROR /= ERROR_NONE then LAYOUT_COMPILE else LAYOUT_NONE
   | DUMPS_TOKENS := LAYOUT = LAYOUT_DUMP_TOKENS
   | ITEM_COUNT := if DUMPS_TOKENS then 4 * (TOKEN_COUNT + 1) else LAYOUT_ITEM_COUNT[LAYOUT]
   | ITEM_INDEX := 0 .. ITEM_COUNT - 1
   | iterate ITEM_INDEX of
       (| SECTION := ITEM_INDEX / (TOKEN_COUNT + 1)
        | TOKEN := ITEM_INDEX modulo (TOKEN_COUNT + 1) - 1
        | IS_HEADER := TOKEN < 0
        | KIND := integer(TOKEN_KIND[TOKEN])
        | ROW := LAYOUT_FIRST_ROW[LAYOUT] + ITEM_INDEX
        | PREFIX := if DUMPS_TOKENS then (if IS_HEADER then SECTION_FRAGMENT[SECTION] else if SECTION = 0 then KIND_FRAGMENT[KIND] else 0)
                    else if ROW_MESSAGE[ROW] = 1 then MESSAGE_PREFIX[ERROR] else ROW_PREFIX[ROW]
        | SLICE := if DUMPS_TOKENS then (if not IS_HEADER and SECTION = 1 then SLICE_TOKEN else SLICE_NONE) else ROW_SLICE[ROW]
        | NUMBER_KIND := if DUMPS_TOKENS then (if IS_HEADER then NUMBER_TOKEN_COUNT else SECTION_NUMBER[SECTION]) else ROW_NUMBER[ROW]
        | NUMBER := if NUMBER_KIND = NUMBER_TOKEN_COUNT then TOKEN_COUNT
                    else if NUMBER_KIND = NUMBER_TOKEN_LINE then TOKEN_LINE[TOKEN]
                    else if NUMBER_KIND = NUMBER_TOKEN_COLUMN then TOKEN_COLUMN[TOKEN]
                    else if NUMBER_KIND = NUMBER_ERROR_LINE then ERROR_LINE
                    else if NUMBER_KIND = NUMBER_ERROR_COLUMN then ERROR_COLUMN
                    else ERRNO
        | DIGITS := if NUMBER_KIND = NUMBER_NONE then 0
                    else 1 + integer(NUMBER >= 10) + integer(NUMBER >= 100) + integer(NUMBER >= 1000) + integer(NUMBER >= 10000)
                         + integer(NUMBER >= 100000) + integer(NUMBER >= 1000000) + integer(NUMBER >= 10000000)
                         + integer(NUMBER >= 100000000) + integer(NUMBER >= 1000000000)
        | SLICE_LENGTH := if SLICE = SLICE_TOKEN then TOKEN_LENGTH[TOKEN] else if SLICE = SLICE_PATH then PATH_LENGTH
                          else if SLICE = SLICE_ERROR_CHARACTER then ERROR_CHARACTER_LENGTH else 0
        | SUFFIX := if DUMPS_TOKENS then 0 else if ROW_MESSAGE[ROW] = 1 then MESSAGE_SUFFIX[ERROR] else ROW_SUFFIX[ROW]
        | NEWLINE := if DUMPS_TOKENS then 1 else ROW_NEWLINE[ROW]
        | ITEM_PREFIX := ITEM_PREFIX[?] next ITEM_INDEX : PREFIX
        | ITEM_FROM_PATH := ITEM_FROM_PATH[?] next ITEM_INDEX : SLICE = SLICE_PATH
        | ITEM_SLICE_START := ITEM_SLICE_START[?] next ITEM_INDEX
                              : (if SLICE = SLICE_TOKEN then TOKEN_START[TOKEN] else if SLICE = SLICE_ERROR_CHARACTER then LEX_ERROR_AT else 0)
        | ITEM_SLICE_LENGTH := ITEM_SLICE_LENGTH[?] next ITEM_INDEX : SLICE_LENGTH
        | ITEM_FOLDS := ITEM_FOLDS[?] next ITEM_INDEX : SLICE = SLICE_TOKEN and KIND = KIND_KEYWORD
        | ITEM_NUMBER := ITEM_NUMBER[?] next ITEM_INDEX : NUMBER
        | ITEM_DIGITS := ITEM_DIGITS[?] next ITEM_INDEX : DIGITS
        | ITEM_SUFFIX := ITEM_SUFFIX[?] next ITEM_INDEX : SUFFIX
        | TOTAL := TOTAL[?] + FRAGMENT_LENGTH[PREFIX] + SLICE_LENGTH + DIGITS + FRAGMENT_LENGTH[SUFFIX] + NEWLINE
        | ITEM_END := ITEM_END[?] next ITEM_INDEX : TOTAL
        |)
     with TOTAL := 0
     end
   | OUTPUT_INDEX := 0 .. TOTAL - 1
   | iterate OUTPUT_INDEX of
       (| CURRENT := if OUTPUT_INDEX >= ITEM_END[CURRENT[?]] then CURRENT[?] + 1 else CURRENT[?]
        | OFFSET := OUTPUT_INDEX - ITEM_END[CURRENT - 1]
        | PREFIX_END := FRAGMENT_LENGTH[ITEM_PREFIX[CURRENT]]
        | SLICE_END := PREFIX_END + ITEM_SLICE_LENGTH[CURRENT]
        | DIGITS_END := SLICE_END + ITEM_DIGITS[CURRENT]
        | SUFFIX_END := DIGITS_END + FRAGMENT_LENGTH[ITEM_SUFFIX[CURRENT]]
        | SLICE_AT := ITEM_SLICE_START[CURRENT] + OFFSET - PREFIX_END
        | SLICE_BYTE := if ITEM_FROM_PATH[CURRENT] then PATH_TEXT[SLICE_AT] else SRC[SLICE_AT]
        | OUTPUT_BYTE := if OFFSET < PREFIX_END then FRAGMENTS[FRAGMENT_START[ITEM_PREFIX[CURRENT]] + OFFSET]
                         else if OFFSET < SLICE_END then
                           (if ITEM_FOLDS[CURRENT] and SLICE_BYTE >= ubyte(65) and SLICE_BYTE <= ubyte(90) then SLICE_BYTE + ubyte(32) else SLICE_BYTE)
                         else if OFFSET < DIGITS_END then
                           ubyte(48 + ITEM_NUMBER[CURRENT] / POWERS_OF_TEN[DIGITS_END - 1 - OFFSET] modulo 10)
                         else if OFFSET < SUFFIX_END then FRAGMENTS[FRAGMENT_START[ITEM_SUFFIX[CURRENT]] + OFFSET - DIGITS_END]
                         else ubyte(10)
        | store{OUTPUT, ubyte}(OUTPUT_BASE + OUTPUT_INDEX, OUTPUT_BYTE)
        |)
     with CURRENT := 0
     end
   | OUTPUT_BASE := pointer(ulong(BUFFER_ADDRESS))
   | DUMPING := LAYOUT = LAYOUT_DUMP_TOKENS or LAYOUT = LAYOUT_DUMP_ERROR
   | OUTPUT_FILE := syscall{OS}(if DUMPING then 5 else 20, ARG3, 1537, 420, 0, 0, 0)
   | SOURCE_CLOSED --> OUTPUT_FILE
   | OUTPUT_FD := if DUMPING then OUTPUT_FILE else long(2)
   | WRITES := LAYOUT /= LAYOUT_NONE and OUTPUT_FD >= 0
   | WRITTEN := syscall{OS}(if WRITES then 4 else 20, OUTPUT_FD, BUFFER_ADDRESS, TOTAL, 0, 0, 0)
   | OUTPUT_BYTE --> WRITTEN
   | OUTPUT_CLOSED := syscall{OS}(if DUMPING and OUTPUT_FILE >= 0 then 6 else 20, OUTPUT_FILE, 0, 0, 0, 0, 0)
   | WRITTEN --> OUTPUT_CLOSED
   | OUTPUT_FAILED := WRITES and WRITTEN /= long(TOTAL) or DUMPING and OUTPUT_FILE < 0
   | STATUS := if not USAGE_OK then 2 else if ERRNO /= 0 or OUTPUT_FAILED or not DUMPING and ERROR /= ERROR_NONE then 1 else 0
   | EXIT := syscall{OS}(1, STATUS, 0, 0, 0, 0, 0)
   | OUTPUT_CLOSED --> EXIT
   |)
  where
    constant integer DUMP_PASS = 0;
    constant integer ARG_CAP = 4096;
    constant integer SRC_CAP = 8388608;
    constant integer TOKEN_CAP = 2097152;
    constant integer ITEM_CAP = 16777216;
    constant long OUTPUT_CAP = 134217728;
    constant [3] ubyte OUTPUT_OPTION = [ubyte(45), ubyte(111), ubyte(0)];
    constant integer CLASS_INVALID = 0;
    constant integer CLASS_DIGIT = 2;
    constant integer CLASS_LETTER = 3;
    constant integer CLASS_SYMBOL = 6;
    constant integer CLASS_DOT = 7;
    constant [256] short CHARACTER_CLASS = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        1, 6, 5, 6, 6, 4, 0, 0, 6, 6, 6, 6, 6, 6, 7, 6, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 6, 6, 6, 6, 6, 6,
        0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 6, 0, 6, 6, 3,
        0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 6, 6, 6, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short LETTER_VALUE = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 0, 0, 0, 0, 0,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant [256] short PAIR_SECOND = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 124, 0, 0, 0, 0, 0, 46, 61, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 0, 61, 0, 61, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 61, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    constant integer MODE_IDLE = 0;
    constant integer MODE_NAME = 1;
    constant integer MODE_NUMBER = 2;
    constant integer MODE_COMMENT = 3;
    constant integer MODE_STRING = 4;
    constant integer MODE_SYMBOL = 5;
    constant [8] short MODE_OF_CLASS = [0, 0, 2, 1, 3, 4, 0, 0];
    constant integer KIND_KEYWORD = 0;
    constant integer KIND_NAME = 1;
    constant integer KIND_EOF = 5;
    constant integer KIND_NONE = 6;
    constant [8] short OPENED_KIND_OF_CLASS = [6, 6, 3, 1, 6, 4, 2, 2];
    constant integer KEYWORD_LENGTH_MAX = 9;
    constant integer KEYWORD_MODULUS = 156;
    constant [156] ulong KEYWORD_KEYS = [
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(474245), ulong(10154581170), ulong(0),
        ulong(198245431340), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(14836), ulong(0), ulong(486), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(5969364), ulong(0), ulong(494), ulong(0), ulong(0), ulong(0), ulong(498), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(309556), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(17799681651),
        ulong(763528), ulong(0), ulong(0), ulong(0), ulong(19724), ulong(681477), ulong(0), ulong(0),
        ulong(1476), ulong(0), ulong(19730), ulong(0), ulong(119675684308), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(674469), ulong(1843057971694), ulong(0), ulong(4469085588), ulong(178861), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(464660), ulong(6337125), ulong(0), ulong(0),
        ulong(0), ulong(18226873521733), ulong(0), ulong(0), ulong(0), ulong(0), ulong(663726), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(24385093), ulong(0), ulong(0),
        ulong(5572), ulong(0), ulong(25074), ulong(0), ulong(0), ulong(0), ulong(229180581358), ulong(0),
        ulong(0), ulong(10340599429), ulong(0), ulong(0), ulong(0), ulong(0), ulong(762030), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(2666927150), ulong(0),
        ulong(20201044), ulong(0), ulong(294), ulong(452089231), ulong(0), ulong(0), ulong(0), ulong(0),
        ulong(0), ulong(0), ulong(0), ulong(0), ulong(0), ulong(176741), ulong(0), ulong(0),
        ulong(12617900), ulong(0), ulong(0), ulong(409031)];
    constant integer ERROR_NONE = 0;
    constant integer ERROR_UNEXPECTED = 1;
    constant integer ERROR_SRC = 2;
    constant integer ERROR_TOKENS = 3;
    constant integer LAYOUT_NONE = 0;
    constant integer LAYOUT_OS = 1;
    constant integer LAYOUT_COMPILE = 2;
    constant integer LAYOUT_DUMP_ERROR = 3;
    constant integer LAYOUT_DUMP_TOKENS = 4;
    constant [5] short LAYOUT_ITEM_COUNT = [0, 2, 4, 3, 0];
    constant [5] short LAYOUT_FIRST_ROW = [0, 0, 2, 6, 0];
    constant integer SLICE_NONE = 0;
    constant integer SLICE_TOKEN = 1;
    constant integer SLICE_PATH = 2;
    constant integer SLICE_ERROR_CHARACTER = 3;
    constant integer NUMBER_NONE = 0;
    constant integer NUMBER_ERROR_LINE = 1;
    constant integer NUMBER_ERROR_COLUMN = 2;
    constant integer NUMBER_ERRNO = 3;
    constant integer NUMBER_TOKEN_COUNT = 4;
    constant integer NUMBER_TOKEN_LINE = 5;
    constant integer NUMBER_TOKEN_COLUMN = 6;
    constant [9] short ROW_PREFIX = [15, 0, 0, 0, 0, 0, 13, 0, 0];
    constant [9] short ROW_SLICE = [0, 2, 2, 0, 0, 3, 0, 0, 3];
    constant [9] short ROW_NUMBER = [3, 0, 0, 1, 2, 0, 1, 2, 0];
    constant [9] short ROW_SUFFIX = [16, 0, 11, 11, 12, 0, 14, 14, 0];
    constant [9] short ROW_NEWLINE = [0, 1, 0, 0, 0, 1, 0, 0, 1];
    constant [9] short ROW_MESSAGE = [0, 0, 0, 0, 0, 1, 0, 0, 1];
    constant [4] short MESSAGE_PREFIX = [0, 17, 19, 20];
    constant [4] short MESSAGE_SUFFIX = [0, 18, 0, 0];
    constant [4] short SECTION_FRAGMENT = [1, 2, 3, 4];
    constant [4] short SECTION_NUMBER = [0, 0, 5, 6];
    constant [6] short KIND_FRAGMENT = [5, 6, 7, 8, 9, 10];
    constant [199] ubyte FRAGMENTS = "kinds texts lines columns keywordnamesymbolnumberstringeof:: error: error  sigc: error: [Errno ] unexpected character ''program exceeds compiler capacity: SRCprogram exceeds compiler capacity: TOKENS";
    constant [21] short FRAGMENT_START = [0, 0, 6, 12, 18, 26, 33, 37, 43, 49, 55, 58, 59, 68, 74, 75, 95, 97, 119, 120, 158];
    constant [21] short FRAGMENT_LENGTH = [0, 6, 6, 6, 8, 7, 4, 6, 6, 6, 3, 1, 9, 6, 1, 20, 2, 22, 1, 38, 41];
    constant [10] integer POWERS_OF_TEN = [1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000, 1000000000];
    type ARGS = external;
    type OS = external;
    type FILE = external;
    type OUTPUT = external;
    integer ARGC, PATH_LENGTH, ERRNO, LENGTH, CLASS, PREVIOUS_MODE, SYMBOL_LENGTH, OPENED_KIND, REMAINING, MODE, COLUMN,
      CODE_POINTS, LINE_START, LINE, OPEN_AT, OPEN_LINE, OPEN_COLUMN, OPEN_KIND, PENDING, LETTER, FINISHED_LENGTH,
      FINISHED_SLOT, OPENED_SLOT, TOKEN_COUNT, FOUND, LEX_ERROR, LEX_ERROR_LINE, LEX_ERROR_COLUMN, LEX_ERROR_AT,
      ERROR, ERROR_LINE, ERROR_COLUMN, ERROR_CHARACTER_LENGTH, LAYOUT, ITEM_COUNT, SECTION, TOKEN, KIND, ROW, PREFIX,
      SLICE, NUMBER_KIND, NUMBER, DIGITS, SLICE_LENGTH, SUFFIX, NEWLINE, TOTAL, CURRENT, OFFSET, PREFIX_END,
      SLICE_END, DIGITS_END, SUFFIX_END, SLICE_AT, STATUS;
    pointer ARGV, ARG1, ARG2, ARG3, SOURCE_BASE, OUTPUT_BASE;
    boolean ARGUMENT_COUNT_OK, DASH_MATCHES, USAGE_OK, PATH_ENDED, OPEN_OK, READ_OK, SIZE_OK, SOURCE_FITS, MAP_WANTED,
      MAP_OK, SOURCE_OK, AT_EOF, AT_END, CONTINUES, STARTS, OPENS_TOKEN, ENDS_LINE, NOT_ALL_LETTERS, HAS_LOWER,
      HAS_UPPER, IS_KEYWORD, UNCLOSED, UNEXPECTED, FIRST_FOUND, SOURCE_TOO_BIG, ERROR_MULTIBYTE, ERROR_FIRST_CONTINUES,
      ERROR_SECOND_CONTINUES, ERROR_THIRD_CONTINUES, DUMPS_TOKENS, IS_HEADER, DUMPING, WRITES, OUTPUT_FAILED;
    ubyte DASH_BYTE, PATH_BYTE, SOURCE_BYTE, BYTE, NEXT_BYTE, ERROR_LEAD, SLICE_BYTE, OUTPUT_BYTE;
    ulong KEY;
    long BUFFER_ADDRESS, SOURCE_FD, PROBE, SIZE, MAPPED, SOURCE_CLOSED, OUTPUT_FILE, OUTPUT_FD, WRITTEN, OUTPUT_CLOSED,
      EXIT;
    [3] integer DASH_INDEX;
    [ARG_CAP] integer PATH_INDEX;
    [ARG_CAP] ubyte PATH_TEXT;
    [SRC_CAP] integer COPY_INDEX, LEX_INDEX;
    [SRC_CAP] ubyte SRC;
    [TOKEN_CAP] ubyte TOKEN_KIND;
    [TOKEN_CAP] integer TOKEN_LENGTH, TOKEN_START, TOKEN_LINE, TOKEN_COLUMN;
    [ITEM_CAP] integer ITEM_INDEX, ITEM_PREFIX, ITEM_SLICE_START, ITEM_SLICE_LENGTH, ITEM_NUMBER, ITEM_DIGITS, ITEM_SUFFIX,
      ITEM_END;
    [ITEM_CAP] boolean ITEM_FROM_PATH, ITEM_FOLDS;
    [OUTPUT_CAP] integer OUTPUT_INDEX;
  end;
