import math
import re
import struct
import sys
from pathlib import Path

SOURCE = Path(__file__).resolve().parent / "sigc.sig"
ANCHOR = "    type ARGS = external;\n"

SEED_WORDS = [
    "event", "boolean", "short", "integer", "long", "ubyte", "ushort", "uinteger", "ulong", "pointer", "char", "string",
    "real", "dreal", "complex", "dcomplex",
    "load", "store", "syscall", "instruction", "read", "write", "writeString", "abs", "left_tt",
    "Automaton_Initial_State", "Automaton_Transition", "Automaton_SetClock", "Automaton_Clock",
    "Automaton_SetCurrentStateId", "Automaton_IsIn",
    "clock'", "state'", "cur'", "on'",
    "process", "where", "end", "init", "true", "false", "when", "default", "and", "or", "xor", "not", "modulo",
    "shl", "shr", "type", "enum", "constant", "next", "iterate", "of", "with", "if", "then", "else", "procedure",
    "node", "function", "automaton", "label", "on", "external", "indices", "pragmas", "Interrupt", "Boot", "Machine",
    "cell", "var", "after", "from", "count", "case", "in", "array", "to",
    "module", "use", "private", "ref", "action", "safe", "deterministic", "unsafe", "defaultvalue", "shared", "statevar", "tr", "assert", "min_clock", "spec",
    "affine_sample", "affine_clock_relation", "affine_unsample",
    "cell'", "zcell'", "var'", "varm'", "zvar'", "h1'", "h2'", "m'", "a'", "za'", "s'", "zs'", "n'", "i'", "zcount'", "tick'", "v'", "zv'", "vb'", "zvb'", "clk_x'", "clk_y'", "clk_i'", "rep'", "seq'", "tup'", "math'",
    "dim", "size", "bounds", "step", "window", "struct", "bundle",
    "conj", "conjd", "rpart", "rpartd", "ipart", "ipartd", "modu", "modud",
    "acos", "asin", "atan", "cos", "sin", "tan", "cosh", "sinh", "tanh", "exp", "log", "log10", "sqrt", "ceil", "fabs", "floor",
    "frexp", "modf", "frexp'm", "frexp'e", "modf'f", "modf'i",
    "atan2", "ldexp", "pow", "fmod", "arg", "argd",
]
FRESH_FIRST = "cell'"
FRESH_LAST = "math'"
KEYWORDS = {
    "process", "where", "end", "init", "integer", "boolean", "event", "true", "false", "when", "default", "and", "or",
    "xor", "not", "modulo", "short", "long", "shl", "shr", "type", "enum", "constant", "next", "iterate", "of", "with",
    "if", "then", "else", "procedure", "node", "function", "automaton", "label", "on", "external",
    "cell", "var", "after", "from", "count", "case", "in", "array", "to",
    "module", "use", "private", "ref", "action", "safe", "deterministic", "unsafe", "defaultvalue", "shared", "statevar",
    "tr",
}
NAME_CONSTANTS = {
    "event": "N_EVENT", "boolean": "N_BOOLEAN", "ubyte": "N_UBYTE", "ulong": "N_ULONG", "load": "N_LOAD",
    "store": "N_STORE", "syscall": "N_SYSCALL",
    "instruction": "N_INSTRUCTION", "abs": "N_ABS", "left_tt": "N_LEFT_TT", "Automaton_Initial_State": "N_INITIAL", "Automaton_Transition": "N_TRANSITION",
    "Automaton_SetClock": "N_SET_CLOCK", "Automaton_Clock": "N_AUTOMATON_CLOCK",
    "Automaton_SetCurrentStateId": "N_SET_CURRENT_STATE_ID",
    "Automaton_IsIn": "N_ISIN", "clock'": "N_CLOCK_MARK", "state'": "N_STATE_MARK", "cur'": "N_CURRENT_MARK",
    "on'": "N_ON_MARK", "indices": "N_INDICES", "pragmas": "N_PRAGMAS", "Interrupt": "N_INTERRUPT", "Boot": "N_BOOT",
    "Machine": "N_MACHINE", "assert": "N_ASSERT", "min_clock": "N_MIN_CLOCK", "spec": "N_SPEC", "affine_sample": "N_AFFINE_SAMPLE", "affine_clock_relation": "N_AFFINE_RELATION",
    "affine_unsample": "N_AFFINE_UNSAMPLE", "clk_i'": "N_AFFINE_CLOCK", "rep'": "N_REPEAT_MARK", "tick'": "N_TICK_MARK",
    "dim": "N_DIM", "size": "N_SIZE", "bounds": "N_BOUNDS", "step": "N_STEP",
    "window": "N_WINDOW", "seq'": "N_SEQ_MARK", "tup'": "N_TUPLE_MARK",
    "struct": "N_STRUCT", "bundle": "N_BUNDLE",
    "string": "N_STRING", "read": "N_READ", "write": "N_WRITE", "writeString": "N_WRITE_STRING",
    "conj": "N_CONJ", "conjd": "N_CONJD", "rpart": "N_RPART", "rpartd": "N_RPARTD", "ipart": "N_IPART",
    "ipartd": "N_IPARTD", "modu": "N_MODU", "modud": "N_MODUD", "acos": "N_ACOS", "floor": "N_FLOOR", "atan2": "N_ATAN2",
    "ldexp": "N_LDEXP", "fmod": "N_FMOD", "arg": "N_ARG", "argd": "N_ARGD", "frexp": "N_FREXP", "modf": "N_MODF",
    "frexp'm": "N_FREXP_MANTISSA", "frexp'e": "N_FREXP_EXPONENT", "modf'f": "N_MODF_FRACTION", "math'": "N_MATH_MARK",
}
SYMBOLS = [
    ("(|", "OPEN_BAR"), ("|)", "BAR_CLOSE"), ("-->", "ARROW"), ("::", "COLONS"), (":=", "DEFINE"),
    ("^=", "CLOCK_EQUAL"), ("/=", "NOT_EQUAL"), ("<=", "LESS_EQUAL"), (">=", "GREATER_EQUAL"), ("..", "RANGE"),
    ("|", "BAR"), ("$", "DOLLAR"), ("+", "PLUS"), ("-", "MINUS"), ("*", "STAR"), ("/", "SLASH"), ("(", "OPEN"),
    (")", "CLOSE"), ("=", "EQUAL"), (";", "SEMICOLON"), (",", "COMMA"), ("?", "QUESTION"), ("!", "BANG"),
    ("<", "LESS"), (">", "GREATER"), ("^", "CARET"), ("#", "HASH"), ("[", "OPEN_BRACKET"), ("]", "CLOSE_BRACKET"),
    (":", "COLON"), ("{", "OPEN_BRACE"), ("}", "CLOSE_BRACE"),
    ("^+", "CLOCK_PLUS"), ("^*", "CLOCK_TIMES"), ("^-", "CLOCK_MINUS"), ("==", "EQUAL_EQUAL"),
    ("<<=", "LESS_LESS_EQUAL"), ("[:", "OPEN_COLON"), ("[/:", "OPEN_SLASH_COLON"), ("\\\\", "BACKSLASHES"),
    ("|*", "BAR_STAR"), ("**", "STAR_STAR"), ("^<", "CLOCK_LT"), ("^>", "CLOCK_GT"), ("^#", "CLOCK_SHARP"),
    (":=:", "IDENTITY"), ("::=", "PARTIAL_DEFINE"), ("|+", "BAR_PLUS"), ("*.", "STAR_DOT"), (".", "DOT"),
    ("@", "AT"),
]
SYMBOL_BASE = 94
OTHER_CODES = [("EOF", 0), ("NAME", 145), ("NUMBER", 146), ("STRING", 147), ("REAL", 148)]
CODE_LIMIT = 149
ESCAPES = {"a": 7, "b": 8, "f": 12, "n": 10, "r": 13, "t": 9, "v": 11, "\\": 92, '"': 34, "'": 39, "?": 63, "%": 37}

OPS = [
    "CONST", "SIGNAL", "ENUMCONST", "CALL", "DELAY", "PREV", "INDEX", "NEG", "NOT", "UWHEN", "CLOCK", "IF", "BRANCH",
    "DEFAULT", "WHEN", "XOR", "OR", "AND", "EQ", "NE", "LT", "LE", "GT", "GE", "ADD", "SUB", "MUL", "DIV", "MOD",
    "SHL", "SHR", "NEXT", "PAIR", "RANGE", "OPEN_PAREN", "OPEN_SQUARE", "IF_MARK", "THEN_MARK", "EFFECT",
    "INPUT", "COPY", "CONVERT", "TABLE", "ELEMENT", "GATHER", "ITER", "SEED", "ARG",
    "CLOCK_PLUS", "CLOCK_TIMES", "OPEN_COLON", "OPEN_SLASH_COLON", "LEFT_TT", "CLOCK_MINUS", "ABS", "OPERAND", "ZERO",
    "RECOVER", "RECOVER_SQUARE", "INDEX_OPERAND", "SIZE", "SIZE_LESS", "CELL", "VAR", "AFTER", "FROM", "COUNT",
    "REPEAT", "ONE", "RIGHT_OPERAND", "TARGET_SIGNAL", "INDEX_SIGNAL", "REPEAT_RANGE", "ARRAY_RANGE", "REPEAT_BODY",
    "SLOT", "POW", "AFFINE_SAMPLE", "AFFINE_RELATION", "AFFINE_UNSAMPLE", "STATE", "FLAT", "SQUARE_FLAT", "SLICE",
    "DIM_CALL", "SIZE_CALL", "SIZE_ONE_CALL", "BOUNDS_CALL", "DIM", "DIM_SIZE", "BOUNDS", "BOUNDS_PAIR", "RECOVER_SQUARE_FLAT",
    "ENUM", "DEFAULTS", "PUT", "SPAN", "STEP", "TARGET_INDEX", "RESTRUCTURE", "SQUARE_FLAT_TARGET", "CONCAT", "ARRAY_EQ", "RANGE_TABLE", "FLATV",
    "EACH", "EACH_STORE", "GDELAY", "WINDOW", "LAG", "SQUARE_FLAT_NEXT", "ELEMENT_PAIR", "AXIS",
    "SEQ_RANGE", "SEQ_SPAN", "SEQ_LIST", "SEQ_HEAD1", "SEQ_HEAD2", "SEQ_HEAD3", "SEQ_HEAD4", "SEQ_ELEMENT", "SEQ_TAIL",
    "SEQ_TAIL_PAIR", "SEQ_FINAL", "SEQ_FROM", "SEQ_TO", "SEQ_BY", "SEQ_HIDDEN", "SEQ_PREVIOUS", "SEQ_INDEX",
    "TUPLE_HEAD", "TUPLE_TAIL", "TUPLE_TARGET", "TUPLE_OUTPUT", "TRANSPOSE", "MATPROD",
    "CPAIR", "CONJ_CALL", "RPART_CALL", "IPART_CALL", "MODU_CALL", "CONJ", "RPART", "IPART", "MODU", "IMAG", "FMA", "COPYSIGN",
    "MATH_CALL", "MATH2_CALL", "CARG_CALL", "MATH", "MATH2", "CARG", "TUPLE_SOURCE", "TUPLE_PART", "TUPLE_TAIL_MATH",
]
MONOCHRONOUS = {
    "ADD", "SUB", "MUL", "DIV", "MOD", "NEG", "LT", "LE", "GT", "GE", "EQ", "NE", "AND", "OR", "XOR", "NOT", "SHL", "SHR",
    "CONVERT", "ELEMENT", "GATHER", "PAIR", "NEXT", "PREV", "ITER", "IF", "BRANCH", "ARG", "RANGE", "FLAT", "SLICE", "BOUNDS", "BOUNDS_PAIR", "DIM", "DIM_SIZE", "PUT", "SPAN", "TABLE", "RESTRUCTURE", "CONCAT", "ARRAY_EQ", "RANGE_TABLE", "FLATV", "EACH", "EACH_STORE", "WINDOW",
    "TRANSPOSE", "MATPROD", "CPAIR", "CONJ", "RPART", "IPART", "MODU", "IMAG", "FMA", "COPYSIGN", "MATH", "MATH2", "CARG",
}
CX_REFS = {"NONE": 0, "AR": 1, "AI": 2, "BR": 3, "BI": 4, "L": 5, "R": 6, "SELF": 7, "IMR": 8}
CX_TEMP_BASE = 16
CX_DESTS = {"RE": 0, "IM": 1, "TEMP": 2}
CX_TYPES = {"C": 0, "K": 1, "B": 2}
CX_VALUES = {"KEEP": 0, "PRE": 1, "PIM": 2, "ZERO": 3, "ONE": 4, "INF": 5, "NAN": 6, "STATE_IM": 7, "TABLE_IM": 8}


class ComplexProgram:
    def __init__(self):
        self.steps = []

    def step(self, dest, op, left="NONE", right="NONE", kind="C", value="KEEP"):
        self.steps.append((dest, op, left, right, kind, value))
        return CX_TEMP_BASE + len(self.steps) - 1

    def temp(self, op, left="NONE", right="NONE", kind="C", value="KEEP"):
        return self.step("TEMP", op, left, right, kind, value)

    def const(self, value):
        return self.temp("CONST", value=value)

    def absolute(self, x, zero):
        negative = self.temp("LT", x, zero, "B")
        return self.temp("IF", negative, self.temp("BRANCH", self.temp("NEG", x), x))

    def select(self, condition, when_true, when_false, dest="TEMP"):
        return self.step(dest, "IF", condition, self.temp("BRANCH", when_true, when_false))

    def fma(self, addend, x, y):
        return self.temp("FMA", addend, self.temp("BRANCH", x, y))


def complex_unary(op_re, op_im, left_re, left_im, right_re="NONE", right_im="NONE", value_re="KEEP", value_im="KEEP"):
    program = ComplexProgram()
    program.step("IM", op_im, left_im, right_im, "C", value_im)
    program.step("RE", op_re, left_re, right_re, "C", value_re)
    return program


def complex_quotient():
    program = ComplexProgram()
    ar, ai = program.temp("CONVERT", "AR"), program.temp("CONVERT", "AI")
    br, bi = program.temp("CONVERT", "BR"), program.temp("CONVERT", "BI")
    zero, one, infinity, nan = program.const("ZERO"), program.const("ONE"), program.const("INF"), program.const("NAN")
    abs_br, abs_bi = program.absolute(br, zero), program.absolute(bi, zero)
    real_wider = program.temp("GE", abs_br, abs_bi, "B")
    imag_wider = program.temp("GE", abs_bi, abs_br, "B")
    real_zero = program.temp("EQ", br, zero, "B")
    negative_ar = program.temp("NEG", ar)
    ratio1 = program.temp("DIV", bi, br)
    denom1 = program.fma(br, bi, ratio1)
    re1 = program.temp("DIV", program.fma(ar, ai, ratio1), denom1)
    im1 = program.temp("DIV", program.fma(ai, negative_ar, ratio1), denom1)
    ratio2 = program.temp("DIV", br, bi)
    denom2 = program.fma(bi, br, ratio2)
    re2 = program.temp("DIV", program.fma(ai, ar, ratio2), denom2)
    im2 = program.temp("DIV", program.fma(negative_ar, ai, ratio2), denom2)
    first_re = program.select(real_zero, zero, re1)
    first_im = program.select(real_zero, zero, im1)
    second_re = program.select(imag_wider, re2, nan)
    second_im = program.select(imag_wider, im2, nan)
    quotient_re = program.select(real_wider, first_re, second_re)
    quotient_im = program.select(real_wider, first_im, second_im)
    both_nan = program.temp("AND", program.temp("NE", quotient_re, quotient_re, "B"),
                            program.temp("NE", quotient_im, quotient_im, "B"), "B")
    abs_ar, abs_ai = program.absolute(ar, zero), program.absolute(ai, zero)
    inf_ar = program.temp("EQ", abs_ar, infinity, "B")
    inf_ai = program.temp("EQ", abs_ai, infinity, "B")
    inf_br = program.temp("EQ", abs_br, infinity, "B")
    inf_bi = program.temp("EQ", abs_bi, infinity, "B")
    finite_a = program.temp("AND", program.temp("LT", abs_ar, infinity, "B"), program.temp("LT", abs_ai, infinity, "B"), "B")
    finite_b = program.temp("AND", program.temp("LT", abs_br, infinity, "B"), program.temp("LT", abs_bi, infinity, "B"), "B")
    infinite_a = program.temp("AND", program.temp("OR", inf_ar, inf_ai, "B"), finite_b, "B")
    infinite_b = program.temp("AND", program.temp("OR", inf_br, inf_bi, "B"), finite_a, "B")
    xa = program.temp("COPYSIGN", program.select(inf_ar, one, zero), ar)
    ya = program.temp("COPYSIGN", program.select(inf_ai, one, zero), ai)
    re_a = program.temp("MUL", infinity, program.fma(program.temp("MUL", ya, bi), xa, br))
    im_a = program.temp("MUL", infinity, program.fma(program.temp("NEG", program.temp("MUL", xa, bi)), ya, br))
    xb = program.temp("COPYSIGN", program.select(inf_br, one, zero), br)
    yb = program.temp("COPYSIGN", program.select(inf_bi, one, zero), bi)
    re_b = program.temp("MUL", zero, program.fma(program.temp("MUL", ai, yb), ar, xb))
    im_b = program.temp("MUL", zero, program.fma(program.temp("NEG", program.temp("MUL", yb, ar)), ai, xb))
    recovered_re = program.select(infinite_a, re_a, program.select(infinite_b, re_b, quotient_re))
    recovered_im = program.select(infinite_a, im_a, program.select(infinite_b, im_b, quotient_im))
    program.select(both_nan, recovered_im, quotient_im, "IM")
    program.select(both_nan, recovered_re, quotient_re, "RE")
    return program


def complex_product():
    program = ComplexProgram()
    a, b = program.temp("CONVERT", "AR"), program.temp("CONVERT", "AI")
    c, d = program.temp("CONVERT", "BR"), program.temp("CONVERT", "BI")
    zero, one, infinity = program.const("ZERO"), program.const("ONE"), program.const("INF")
    ac, bd = program.temp("MUL", a, c), program.temp("MUL", b, d)
    ad, bc = program.temp("MUL", a, d), program.temp("MUL", b, c)
    product_re, product_im = program.temp("SUB", ac, bd), program.temp("ADD", ad, bc)
    both_nan = program.temp("AND", program.temp("NE", product_re, product_re, "B"),
                            program.temp("NE", product_im, product_im, "B"), "B")

    def infinite(x):
        return program.temp("EQ", program.absolute(x, zero), infinity, "B")

    def boxed_or_denanned(x, x_infinite, boxes):
        boxed = program.temp("COPYSIGN", program.select(x_infinite, one, zero), x)
        denanned = program.select(program.temp("NE", x, x, "B"), program.temp("COPYSIGN", zero, x), x)
        return program.select(boxes, boxed, denanned)

    inf_a, inf_b, inf_c, inf_d = infinite(a), infinite(b), infinite(c), infinite(d)
    z_infinite, w_infinite = program.temp("OR", inf_a, inf_b, "B"), program.temp("OR", inf_c, inf_d, "B")
    overflowed = program.temp("OR", program.temp("OR", infinite(ac), infinite(bd), "B"),
                              program.temp("OR", infinite(ad), infinite(bc), "B"), "B")
    recalc = program.temp("AND", both_nan, program.temp("OR", program.temp("OR", z_infinite, w_infinite, "B"), overflowed, "B"), "B")
    a, b = boxed_or_denanned(a, inf_a, z_infinite), boxed_or_denanned(b, inf_b, z_infinite)
    c, d = boxed_or_denanned(c, inf_c, w_infinite), boxed_or_denanned(d, inf_d, w_infinite)
    recalc_re = program.temp("MUL", infinity, program.fma(program.temp("NEG", program.temp("MUL", b, d)), a, c))
    recalc_im = program.temp("MUL", infinity, program.fma(program.temp("MUL", b, c), a, d))
    program.select(recalc, recalc_im, product_im, "IM")
    program.select(recalc, recalc_re, product_re, "RE")
    return program


def complex_equal(negated):
    program = ComplexProgram()
    real_equal, imag_equal = program.temp("EQ", "AR", "BR", "B"), program.temp("EQ", "AI", "BI", "B")
    if negated:
        program.step("RE", "NOT", program.temp("AND", real_equal, imag_equal, "B"), kind="K")
    else:
        program.step("RE", "AND", real_equal, imag_equal, "K")
    return program


def complex_array_equal():
    program = ComplexProgram()
    program.step("RE", "AND", program.temp("ARRAY_EQ", "AR", "BR", "B"), program.temp("ARRAY_EQ", "AI", "BI", "B"), "K")
    return program


def complex_part(ref):
    program = ComplexProgram()
    program.step("RE", "CONVERT", ref, kind="K")
    return program


def complex_modulus():
    program = ComplexProgram()
    program.step("RE", "MODU", program.temp("CONVERT", "AR", kind="K"), program.temp("CONVERT", "AI", kind="K"), "K")
    return program


def complex_argument():
    program = ComplexProgram()
    program.step("RE", "MATH2", program.temp("CONVERT", "AI", kind="K"), program.temp("CONVERT", "AR", kind="K"), "K")
    return program


def complex_conjugate():
    program = ComplexProgram()
    program.step("IM", "NEG", program.temp("CONVERT", "AI"))
    program.step("RE", "CONVERT", "AR")
    return program


def complex_input():
    program = ComplexProgram()
    program.step("IM", "IMAG", "SELF")
    program.step("RE", None, "L", "R")
    return program


def complex_signal():
    program = ComplexProgram()
    program.step("IM", "IMAG", "SELF", "AI")
    program.step("RE", None, "AR")
    return program


def complex_retype():
    program = ComplexProgram()
    program.step("IM", None, "AI", "R")
    program.step("RE", None, "AR", "IMR")
    return program


CX_PROGRAMS = {
    "INPUT": complex_input(),
    "RETYPE": complex_retype(),
    "SIGNAL": complex_signal(),
    "CONST": complex_unary("CONST", "CONST", "NONE", "NONE", value_re="PRE", value_im="PIM"),
    "DELAY": complex_unary(None, None, "AR", "AI", "R", "R", value_re="PRE", value_im="PIM"),
    "UNARY": complex_unary(None, None, "AR", "AI"),
    "STATE": complex_unary(None, None, "NONE", "NONE", value_im="STATE_IM"),
    "TABLE": complex_unary(None, None, "NONE", "NONE", value_im="TABLE_IM"),
    "BINARY": complex_unary(None, None, "AR", "AI", "BR", "BI"),
    "WHEN": complex_unary(None, None, "AR", "AI", "R", "R"),
    "IF": complex_unary(None, None, "L", "L", "BR", "BI"),
    "PAIR": complex_unary("CONVERT", "CONVERT", "L", "R"),
    "CONVERT": complex_unary("CONVERT", "CONVERT", "AR", "AI"),
    "CONJ": complex_conjugate(),
    "MUL": complex_product(),
    "DIV": complex_quotient(),
    "EQ": complex_equal(False),
    "NE": complex_equal(True),
    "ARRAY_EQ": complex_array_equal(),
    "RPART": complex_part("AR"),
    "IPART": complex_part("AI"),
    "MODU": complex_modulus(),
    "CARG": complex_argument(),
}
CX_TYPED_PROGRAM = {
    "INPUT": "INPUT", "EFFECT": "INPUT", "ARG": "RETYPE", "CONST": "CONST", "DELAY": "DELAY", "COPY": "SIGNAL", "NEG": "UNARY",
    "ADD": "BINARY", "SUB": "BINARY", "DEFAULT": "BINARY", "BRANCH": "BINARY", "WHEN": "WHEN", "IF": "IF", "CPAIR": "PAIR",
    "CONVERT": "CONVERT", "CONJ": "CONJ", "MUL": "MUL", "DIV": "DIV", "LAG": "WHEN", "PREV": "UNARY", "SEED": "BINARY", "STATE": "STATE",
    "TABLE": "TABLE", "PUT": "BINARY", "NEXT": "BINARY", "PAIR": "IF", "ELEMENT": "WHEN", "GATHER": "WHEN", "RESTRUCTURE": "WHEN",
    "WINDOW": "WHEN", "EACH": "UNARY", "EACH_STORE": "UNARY", "TRANSPOSE": "UNARY", "CONCAT": "BINARY",
}
CX_OPERAND_PROGRAM = {"EQ": "EQ", "NE": "NE", "ARRAY_EQ": "ARRAY_EQ", "CONVERT": "RPART", "RPART": "RPART", "IPART": "IPART", "MODU": "MODU", "CARG": "CARG"}

POINTWISE = {
    "ADD", "SUB", "MUL", "DIV", "MOD", "NEG", "LT", "LE", "GT", "GE", "EQ", "NE", "AND", "OR", "XOR", "NOT", "SHL", "SHR", "IF", "BRANCH",
}
OPENERS = {"CALL", "OPEN_PAREN", "OPEN_SQUARE", "IF_MARK", "THEN_MARK", "OPEN_COLON", "OPEN_SLASH_COLON", "ENUM"}
BRACKETED = {"OPEN_SQUARE", "OPEN_COLON", "OPEN_SLASH_COLON", "ENUM"}
COMPOSITES = {
    "CLOCK_PLUS": (["CLOCK"], ["CLOCK", "DEFAULT"]), "CLOCK_TIMES": (["CLOCK"], ["CLOCK", "WHEN"]),
    "OPEN_COLON": ([], ["UWHEN"]), "OPEN_SLASH_COLON": ([], ["NOT", "UWHEN"]), "LEFT_TT": ([], ["WHEN", "DEFAULT"]),
    "CLOCK_MINUS": (["CLOCK"], ["CLOCK", "WHEN", "NOT", "OPERAND", "CLOCK", "DEFAULT", "UWHEN"]),
    "ABS": ([], ["ZERO", "LT", "OPERAND", "NEG", "OPERAND", "BRANCH", "IF"]),
    "POW": ([], ["OPERAND", "MUL"]),
    "RECOVER": (["INDEX_OPERAND", "ZERO", "GE", "INDEX_OPERAND", "SIZE_LESS", "LE", "AND", "WHEN"], ["RIGHT_OPERAND", "EQ", "INDEX_OPERAND", "ZERO", "GE", "AND", "RIGHT_OPERAND", "RIGHT_OPERAND", "BRANCH", "IF", "DEFAULT"]),
    "RECOVER_SQUARE": ([], ["SIZE", "MOD", "SIZE", "ADD", "SIZE", "MOD", "INDEX"]),
    "SQUARE_FLAT": ([], ["FLAT", "INDEX"]),
    "RECOVER_SQUARE_FLAT": ([], ["FLAT", "INDEX"]),
    "SQUARE_FLAT_TARGET": ([], ["FLAT", "TARGET_INDEX"]),
    "SQUARE_FLAT_NEXT": ([], ["FLAT"]),
    "ELEMENT_PAIR": ([], ["PAIR", "NEXT"]),
    "DIM_CALL": ([], ["DIM"]),
    "SIZE_CALL": ([], ["DIM_SIZE"]),
    "SIZE_ONE_CALL": ([], ["ONE", "DIM_SIZE"]),
    "BOUNDS_CALL": ([], ["BOUNDS_PAIR", "BOUNDS"]),
    "REPEAT_RANGE": ([], ["ZERO", "RIGHT_OPERAND", "ONE", "SUB", "RANGE"]),
    "ARRAY_RANGE": ([], ["ZERO", "RIGHT_OPERAND", "RANGE"]),
    "REPEAT_BODY": ([], ["TARGET_SIGNAL", "PREV", "INDEX_SIGNAL", "OPERAND", "PAIR", "NEXT"]),
    "SEQ_RANGE": ([], ["SEQ_FROM", "SEQ_TO", "RANGE"]),
    "SEQ_SPAN": ([], ["SEQ_FROM", "SEQ_TO", "SPAN", "SEQ_BY", "STEP"]),
    "SEQ_LIST": ([], ["SEQ_HIDDEN", "PREV"]),
    "SEQ_HEAD1": ([], ["SEQ_HIDDEN", "PREV", "SEQ_INDEX"]),
    "SEQ_HEAD2": ([], ["SEQ_HIDDEN", "PREV", "SEQ_INDEX", "SEQ_INDEX", "FLAT"]),
    "SEQ_HEAD3": ([], ["SEQ_HIDDEN", "PREV", "SEQ_INDEX", "SEQ_INDEX", "FLAT", "SEQ_INDEX", "FLAT"]),
    "SEQ_HEAD4": ([], ["SEQ_HIDDEN", "PREV", "SEQ_INDEX", "SEQ_INDEX", "FLAT", "SEQ_INDEX", "FLAT", "SEQ_INDEX", "FLAT"]),
    "SEQ_ELEMENT": ([], ["SEQ_PREVIOUS"]),
    "SEQ_TAIL": ([], ["NEXT"]),
    "SEQ_TAIL_PAIR": ([], ["PAIR", "NEXT"]),
    "SEQ_FINAL": ([], ["SEQ_HIDDEN"]),
    "TUPLE_HEAD": ([], ["TUPLE_TARGET", "PREV"]),
    "TUPLE_TAIL": ([], ["TUPLE_OUTPUT", "PAIR", "NEXT"]),
    "TUPLE_PART": ([], ["TUPLE_SOURCE", "MATH"]),
    "TUPLE_TAIL_MATH": ([], ["TUPLE_SOURCE", "MATH", "PAIR", "NEXT"]),
    "CONJ_CALL": ([], ["CONJ"]),
    "RPART_CALL": ([], ["RPART"]),
    "IPART_CALL": ([], ["IPART"]),
    "MODU_CALL": ([], ["MODU"]),
    "MATH_CALL": ([], ["MATH"]),
    "MATH2_CALL": ([], ["MATH2"]),
    "CARG_CALL": ([], ["CARG"]),
}
LEAVES = {"CONST", "SIGNAL", "ENUMCONST", "SLOT", "DEFAULTS"}
TEMPLATE_ROW_KINDS = ["EMIT", "LEFT", "RIGHT", "DEFINE", "GROUP", "END", "INPUT"]
TEMPLATE_VALUE_REFS = ["LITERAL", "INIT", "INIT_DECL", "BOUND", "PHASE_A", "PERIOD_A", "PHASE_B", "PERIOD_B"]
TEMPLATE_REFS = {"TARGET": -2, "OPERAND": -3, "BOUND": -4, "FIRST_OPERAND": -5}
TEMPLATE_KINDS = {"CELL": 1, "AFTER": 1, "FROM": 1, "COUNT": 1, "VAR": 2, "AFFINE_SAMPLE": 1, "AFFINE_RELATION": 1, "AFFINE_UNSAMPLE": 1}
TEMPLATE_SKIPS_LEFT = {"AFTER", "FROM", "COUNT", "AFFINE_SAMPLE", "AFFINE_RELATION", "AFFINE_UNSAMPLE"}


def template_emit(op, name=None, value=0, ref="LITERAL", type=None):
    return ("EMIT", op, name, value, ref, type)


def define(name, type):
    return ("DEFINE", None, name, 0, "LITERAL", type)


LEFT_ROW = ("LEFT", None, None, 0, "LITERAL", None)
RIGHT_ROW = ("RIGHT", None, None, 0, "LITERAL", None)
GROUP_ROW = ("GROUP", None, None, 0, "LITERAL", None)
END_ROW = ("END", None, None, 0, "LITERAL", None)


def hidden_input(name):
    return ("INPUT", None, name, 0, "LITERAL", "event")


def template_literal(value, type="short"):
    return template_emit("CONST", value=value, type=type)


def counter_rest(next_count):
    return [
        LEFT_ROW, template_emit("CLOCK"), define("h1'", "event"),
        RIGHT_ROW, template_emit("CLOCK"), define("h2'", "event"),
        template_emit("SIGNAL", "h1'"), template_emit("SIGNAL", "h2'"), template_emit("DEFAULT"), define("m'", "event"),
        template_literal(1, "boolean"), template_emit("SIGNAL", "h2'"), template_emit("WHEN"), template_emit("SIGNAL", "za'"), template_emit("DEFAULT"),
        define("a'", "boolean"),
        template_emit("SIGNAL", "a'"), template_emit("DELAY", value=0, type="boolean"), define("za'", "boolean"),
        template_emit("SIGNAL", "n'"), template_emit("SIGNAL", "zs'"), template_emit("DEFAULT"), define("s'", "TARGET"),
        template_emit("SIGNAL", "s'"), template_emit("DELAY", value=0, type="short"), define("zs'", "TARGET"),
        *next_count, define("n'", "TARGET"),
        template_emit("SIGNAL", "zs'"), template_literal(1), template_emit("ADD"), template_emit("SIGNAL", "za'"), template_emit("WHEN"), template_emit("SIGNAL", "h1'"),
        template_emit("WHEN"), define("i'", "TARGET"),
        template_emit("SIGNAL", "a'"), template_emit("SIGNAL", "m'"), GROUP_ROW,
        template_emit("SIGNAL", "s'"), template_emit("SIGNAL", "m'"), GROUP_ROW, END_ROW,
    ]


COUNTER_INLINE = [
    template_emit("SIGNAL", "n'"), template_emit("SIGNAL", "h1'"), template_emit("WHEN"), template_literal(0), template_emit("SIGNAL", "h1'"), template_emit("WHEN"),
    template_emit("DEFAULT"),
]
def affine_counter(clock, phase, period, count, next_count):
    zero = [template_emit("SIGNAL", next_count), template_literal(0, "integer"), template_emit("EQ")]
    return [
        template_emit("CONST", ref=period, type="integer"), *zero, template_emit("WHEN"),
        template_emit("SIGNAL", next_count), template_literal(1, "integer"), template_emit("SUB"), template_emit("DEFAULT"), define(count, "integer"),
        template_emit("SIGNAL", count), template_emit("DELAY", ref=phase, type="integer"), define(next_count, "integer"),
        template_emit("SIGNAL", count), template_emit("SIGNAL", clock), GROUP_ROW,
    ]


def affine_sampled(clock, next_count, name):
    return [
        template_emit("SIGNAL", clock), template_emit("SIGNAL", next_count), template_literal(0, "integer"), template_emit("EQ"),
        template_emit("WHEN"), define(name, "event"),
    ]


def affine_relation(first, second):
    return [
        hidden_input("clk_i'"),
        *affine_sampled("clk_i'", "zv'", "clk_x'"), *affine_counter("clk_i'", "PHASE_A", "PERIOD_A", "v'", "zv'"),
        *affine_sampled("clk_i'", "zvb'", "clk_y'"), *affine_counter("clk_i'", "PHASE_B", "PERIOD_B", "vb'", "zvb'"),
        template_emit("SIGNAL", "clk_x'"), template_emit("SIGNAL", first), GROUP_ROW,
        template_emit("SIGNAL", "clk_y'"), template_emit("SIGNAL", second), GROUP_ROW,
    ]


TEMPLATE_PROGRAMS = {
    "AFFINE_SAMPLE": ([
        template_emit("SIGNAL", "OPERAND"), template_emit("SIGNAL", "zv'"), template_literal(0, "integer"), template_emit("EQ"),
        template_emit("WHEN")], [*affine_counter("OPERAND", "PHASE_A", "PERIOD_A", "v'", "zv'"), END_ROW]),
    "AFFINE_RELATION": ([], [*affine_relation("FIRST_OPERAND", "OPERAND"), END_ROW]),
    "AFFINE_UNSAMPLE": ([
        template_emit("SIGNAL", "FIRST_OPERAND"), template_emit("SIGNAL", "TARGET"), template_emit("CLOCK"), template_emit("WHEN"),
        template_emit("SIGNAL", "OPERAND"), template_emit("DEFAULT")], [
        *affine_relation("FIRST_OPERAND", "TARGET"),
        template_emit("SIGNAL", "OPERAND"), template_emit("SIGNAL", "TARGET"), GROUP_ROW, END_ROW]),
    "CELL": ([template_emit("SIGNAL", "zcell'"), template_emit("DEFAULT")], [
        template_emit("SIGNAL", "TARGET"), template_emit("DELAY", ref="INIT_DECL"), define("zcell'", "TARGET"),
        LEFT_ROW, template_emit("CLOCK"), RIGHT_ROW, template_emit("UWHEN"), template_emit("DEFAULT"), define("cell'", "event"),
        template_emit("SIGNAL", "TARGET"), template_emit("SIGNAL", "cell'"), GROUP_ROW, END_ROW,
    ]),
    "VAR": ([template_emit("SIGNAL", "varm'"), template_emit("SIGNAL", "TARGET"), template_emit("CLOCK"), template_emit("WHEN")], [
        template_emit("SIGNAL", "OPERAND"), template_emit("SIGNAL", "zvar'"), template_emit("DEFAULT"), define("varm'", "OPERAND"),
        template_emit("SIGNAL", "varm'"), template_emit("DELAY", ref="INIT_DECL"), define("zvar'", "OPERAND"),
        template_emit("SIGNAL", "OPERAND"), template_emit("CLOCK"), template_emit("SIGNAL", "TARGET"), template_emit("CLOCK"), template_emit("DEFAULT"),
        define("var'", "event"),
        template_emit("SIGNAL", "varm'"), template_emit("SIGNAL", "var'"), GROUP_ROW, END_ROW,
    ]),
    "AFTER": (COUNTER_INLINE, counter_rest([
        template_literal(0), template_emit("SIGNAL", "h2'"), template_emit("WHEN"), template_emit("SIGNAL", "i'"), template_emit("DEFAULT")])),
    "FROM": (COUNTER_INLINE, counter_rest([
        template_literal(1), template_emit("SIGNAL", "h2'"), template_emit("WHEN"), template_emit("SIGNAL", "h1'"), template_emit("WHEN"), template_literal(0),
        template_emit("SIGNAL", "h2'"), template_emit("WHEN"), template_emit("DEFAULT"), template_emit("SIGNAL", "i'"), template_emit("DEFAULT")])),
    "COUNT": ([
        template_literal(0), template_emit("SIGNAL", "zcount'"), template_emit("CONST", ref="BOUND", type="BOUND"), template_emit("GE"), template_emit("WHEN"),
        template_emit("SIGNAL", "zcount'"), template_literal(1), template_emit("ADD"), template_emit("DEFAULT")], [
        template_emit("SIGNAL", "TARGET"), template_emit("DELAY", ref="BOUND", type="BOUND"), define("zcount'", "TARGET"),
        LEFT_ROW, template_emit("CLOCK"), define("h1'", "event"),
        template_emit("SIGNAL", "TARGET"), template_emit("SIGNAL", "h1'"), GROUP_ROW, END_ROW,
    ]),
}
UNARY = {"NEG", "NOT", "UWHEN", "CLOCK", "DELAY", "PREV", "VAR", "STATE", "DIM", "AXIS", "TRANSPOSE", "CONJ", "RPART", "IPART", "MODU", "MATH", "CARG"}
BINARY = [
    ("default", "DEFAULT", 3), ("when", "WHEN", 4), ("xor", "XOR", 11), ("or", "OR", 12), ("and", "AND", 13),
    ("=", "EQ", 16), ("/=", "NE", 16), ("<", "LT", 16), ("<=", "LE", 16), (">", "GT", 16), (">=", "GE", 16),
    ("+", "ADD", 17), ("-", "SUB", 17), ("*", "MUL", 18), ("/", "DIV", 18), ("modulo", "MOD", 18),
    ("shl", "SHL", 18), ("shr", "SHR", 18), ("next", "NEXT", 1), (":", "PAIR", 2), ("..", "RANGE", 1),
    ("^+", "CLOCK_PLUS", 6), ("^*", "CLOCK_TIMES", 7), ("^-", "CLOCK_MINUS", 6), ("==", "EQ", 15), ("<<=", "LE", 15),
    ("\\\\", "RECOVER", 23), ("cell", "CELL", 21), ("after", "AFTER", 5), ("from", "FROM", 5), ("count", "COUNT", 5),
    ("|*", "REPEAT", 18), ("**", "POW", 19), ("|+", "CONCAT", 17), ("*.", "MATPROD", 18), ("@", "CPAIR", 19),
]
PREFIX = [
    ("when", "UWHEN", 8), ("not", "NOT", 14), ("-", "NEG", 20), ("^", "CLOCK", 24),
    ("[:", "OPEN_COLON", 1), ("[/:", "OPEN_SLASH_COLON", 1), ("var", "VAR", 21), ("tr", "TRANSPOSE", 20),
]
MODEL_CLASSES = ["process", "procedure", "node", "function", "automaton", "action"]
ATTRIBUTES = ["safe", "deterministic", "unsafe"]

TYPE_KINDS = ["EVENT", "BOOLEAN", "INT", "POINTER", "ENUM", "ARRAY", "EXTERNAL", "STRING", "CHAR", "REAL", "COMPLEX"]
BUILTIN_KIND = [0, 1, 2, 2, 2, 2, 2, 2, 2, 3, 8, 7, 9, 9, 10, 10]
BUILTIN_BYTES = [1, 1, 2, 4, 8, 1, 2, 4, 8, 8, 1, 8, 4, 8, 8, 16]
BUILTIN_SIGNED = [0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
ROLES = ["input", "output", "local"]
TOKEN_KIND_NAMES = ["keyword", "name", "symbol", "number", "string", "eof", "none", "character", "real", "dreal"]
TOKEN_SECTIONS = ["kinds ", "texts ", "lines ", "columns "]

COLUMNS = [
    "name", "types.kind", "types.bytes", "types.signed", "types.name", "types.values", "types.element", "types.size",
    "models.name", "models.kind", "models.parent", "models.line", "models.column", "models.labels",
    "signal_names", "signal_roles", "signal_types", "signal_models", "signal_positions",
    "constant_names", "constant_types", "constant_values", "table_types", "table_values",
    "equation_targets", "equation_ops", "equation_args", "equation_positions", "equation_loops", "equation_kinds",
    "equation_models", "equation_labels", "equation_guards",
    "guard_models", "guard_ops", "guard_args", "guard_positions", "guard_context", "guard_labels", "guard_signals",
    "label_names", "label_uses", "loop_names", "loop_positions", "loop_models",
    "constraint_groups", "constraint_positions", "constraint_models", "constraint_guards",
    "dependence_from", "dependence_to", "dependence_positions", "dependence_models", "dependence_guards",
]
ROW_COLUMNS = [
    "rows.op", "rows.left", "rows.right", "rows.value", "rows.type", "rows.ctx", "rows.line", "rows.column",
    "rows.owner", "rows.loop", "rows.guard", "rows.groups", "rows.group_positions", "rows.dependence_from",
    "rows.dependence_to", "rows.war", "rows.snapshotted", "rows.effects.kind", "rows.effects.resource",
    "rows.effects.param", "loops.index", "loops.size", "loops.defined", "loops.snapshots", "loops.count",
]
CLOCK_COLUMNS = [
    "parent", "sample_rows", "def_kind", "def_target", "def_left", "def_right", "def_line", "def_column", "def_pending",
    "ob_small", "ob_big", "ob_line", "ob_column", "node_kind", "node_parent", "node_depth", "node_root", "node_left",
    "node_right", "roots",
]
SCHEDULE_COLUMNS = ["order", "loop_orders", "snapshots", "snapshotted"]
STRING_COLUMNS = ["string_buffers"]
ALL_COLUMNS = COLUMNS + ROW_COLUMNS + CLOCK_COLUMNS + SCHEDULE_COLUMNS + STRING_COLUMNS
TYPE_COLUMNS = [column for column in COLUMNS if column.startswith("types.")]
DUMP_ORDERS = [
    ("PROGRAM", COLUMNS), ("ROWS", ROW_COLUMNS + TYPE_COLUMNS + ["table_types", "table_values"] + STRING_COLUMNS), ("CLOCKS", CLOCK_COLUMNS),
    ("SCHEDULE", SCHEDULE_COLUMNS),
]
CLOCK_KINDS = ["NONE", "ROOT", "SAMPLE", "PRODUCT", "SUM", "NULL"]

ARGUMENT_KINDS = [
    "NONE", "TOKEN", "LITERAL", "NAME", "TYPE", "NUMBER", "CODE", "FRAGMENT", "CHARACTER", "FLAT", "TEXT", "LONG", "CLOCK", "MODEL",
]
SPLIT_CAP = 4
CORE_CAP = 256
CORE_EDGE_CAP = 1024
SAT_CAP = 256
WALK_CAP = 64
TEMPLATES = [
    ("UNEXPECTED_CHARACTER", "unexpected character '#'", ["CHARACTER"]),
    ("CAPACITY", "program exceeds compiler capacity: #", ["FRAGMENT"]),
    ("EXPECTED_FOUND", "expected '#', found #", ["CODE", "TOKEN"]),
    ("EXPECTED_NAME", "expected a name, found #", ["TOKEN"]),
    ("RESERVED", "# is a reserved name", ["NAME"]),
    ("NAME_OF_MODEL", "# is the name of a model", ["NAME"]),
    ("DECLARED_TWICE", "# # is declared twice", ["FRAGMENT", "NAME"]),
    ("LITERAL_BIG", "integer literal # does not fit in long", ["LITERAL"]),
    ("REAL_BIG", "real literal # does not fit in #", ["LITERAL", "TYPE"]),
    ("CONSTANT_UNDECLARED", "constant # is not declared", ["NAME"]),
    ("EXPECTED_INTEGER_CONSTANT", "expected an integer constant, found #", ["TOKEN"]),
    ("CAPACITY_POSITIVE", "array capacity must be strictly positive", []),
    ("EXPECTED_TYPE", "expected a type, found #", ["TOKEN"]),
    ("EXTERNAL_SIGNAL", "type # is external; signals cannot have that type", ["TYPE"]),
    ("ARRAYS_TO_MODELS", "arrays cannot be passed to models", []),
    ("UNEXPECTED_AFTER", "unexpected # after the process model", ["TOKEN"]),
    ("ENUM_TWICE", "enumerated value # is declared twice", ["NAME"]),
    ("CONSTANT_STRING", "constant # has type # but its definition is a string", ["NAME", "TYPE"]),
    ("CONSTANT_LIST", "constant # has type # but its definition is a list", ["NAME", "TYPE"]),
    ("CONSTANT_ELEMENT", "constant # has type # but its definition has an element of type #", ["NAME", "TYPE", "TYPE"]),
    ("CONSTANT_TYPE", "constant # has type # but its definition has type #", ["NAME", "TYPE", "TYPE"]),
    ("CONSTANT_COUNT", "constant # has type # but its definition has # elements", ["NAME", "TYPE", "NUMBER"]),
    ("CONVERSION", "a conversion in a constant must name an integer type", []),
    ("CONSTANT_LITERAL", "a constant must be defined by an integer literal, a conversion of one, or a list of them", []),
    ("ONLY_DEFINITIONS", "only definitions are allowed inside iterate", []),
    ("ITERATE_NESTED", "iterate cannot be nested", []),
    ("ITERATE_GUARDED", "iterate is not allowed inside a guarded process", []),
    ("ARROW_NAMES", "--> requires signal names", []),
    ("EXPECTED_DEFINITION", "expected ':=' or '^=', found #", ["TOKEN"]),
    ("DELAY_INITIAL", "the initial value of a delay must be a literal or a constant name", []),
    ("STATIC_PARAMETER", "expected a static parameter, found #", ["TOKEN"]),
    ("EXPECTED_EXPRESSION", "expected an expression, found #", ["TOKEN"]),
    ("EXPECTED_THEN", "expected 'then'", []),
    ("EXPECTED_ELSE", "expected 'else'", []),
    ("UNBALANCED", "unbalanced parenthesis", []),
    ("EXPECTED_OPERATOR", "expected an operator, found #", ["TOKEN"]),
    ("RECOVERY_ACCESS", "expected an array access before #", ["TOKEN"]),
    ("ABS_SIGNED", "abs expects a signed integer, found #", ["TYPE"]),
    ("CASE_VALUE", "a case value must be a literal, found #", ["TOKEN"]),
    ("CASE_DUPLICATE", "value # is listed twice in this case", ["TOKEN"]),
    ("CLASS_NEEDS_OUTPUT", "# # must declare at least one output", ["CODE", "NAME"]),
    ("FUNCTION_MEMORY", "# cannot contain #", ["MODEL", "TOKEN"]),
    ("FUNCTION_CALL", "function # cannot call # #", ["NAME", "CODE", "NAME"]),
    ("WHOLE_DEFINITION", "# can only be the whole definition of a signal", ["TOKEN"]),
    ("VAR_NAME", "var takes a signal name", []),
    ("VAR_CONTEXT", "var is supported only where its context clock is the defined signal's clock", []),
    ("TEMPLATE_GUARDED", "# cannot be used inside a guard, case branch, label or state action", ["TOKEN"]),
    ("CONSTANT_BOUND", "the bound of # must be a positive integer literal or constant name", ["TOKEN"]),
    ("LABEL_UNDECLARED", "label # is not declared", ["NAME"]),
    ("NO_INPUT", "automaton # has no input; its control clock is the upper bound of its inputs", ["NAME"]),
    ("WRONG_ARGUMENTS", "wrong number of arguments for #: expected #, found #", ["NAME", "NUMBER", "NUMBER"]),
    ("LABEL_PLACED", "label # cannot be placed on #", ["NAME", "NAME"]),
    ("CANNOT_GUARD", "# cannot be guarded", ["NAME"]),
    ("EXPECTS_STATE", "# expects a state name of automaton #", ["NAME", "NAME"]),
    ("NOT_LABEL_OF", "# is not a label of automaton #", ["NAME", "NAME"]),
    ("ONE_INITIAL", "automaton # needs exactly one Automaton_Initial_State", ["NAME"]),
    ("ONLY_AUTOMATON", "# is allowed only in an automaton", ["NAME"]),
    ("NO_OUTPUT", "model # has no output and cannot be used in an expression", ["NAME"]),
    ("HAS_OUTPUT", "model # has an output and cannot be called as a process", ["NAME"]),
    ("NOT_STATE", "# is not a state of automaton #", ["NAME", "NAME"]),
    ("SIGNAL_UNDECLARED", "signal # is not declared", ["NAME"]),
    ("LABEL_AS_SIGNAL", "label # cannot be used as a signal", ["NAME"]),
    ("CONVERSION_ONE", "conversion to # expects one argument", ["NAME"]),
    ("INDICES_CONSTANT", "indices expects a positive constant", []),
    ("CALLS_IN_ITERATE", "model calls are not allowed inside iterate", []),
    ("UNSAFE_CALL", "unsafe model # is called from # #", ["NAME", "CODE", "NAME"]),
    ("MODEL_UNDECLARED", "model # is not declared", ["NAME"]),
    ("PARAMETER_UNDECLARED", "# is not a constant, a type or a model", ["NAME"]),
    ("PARAMETER_KIND", "parameter # of # expects #", ["NAME", "NAME", "FRAGMENT"]),
    ("PARAMETER_TYPE", "parameter # expects #, found #", ["NAME", "TYPE", "TYPE"]),
    ("SLOT_DEFINED", "# is a parameter of # and cannot be defined", ["NAME", "NAME"]),
    ("FORMAL_ARRAY", "a formal type cannot be an array or an element type", []),
    ("MODULE_NESTED", "a module cannot be declared here", []),
    ("MODEL_TYPE_CALL", "# is a model type and cannot be called", ["NAME"]),
    ("MODEL_TYPE_EXPECTED", "# is not a model type", ["NAME"]),
    ("PARAMETER_INTERFACE", "parameter # expects the interface of #, found #", ["NAME", "NAME", "NAME"]),
    ("PARAMETER_MODEL_FORMALS", "# has static parameters and cannot be an actual model", ["NAME"]),
    ("PRIVATE_OUTSIDE", "private is allowed only in a module", []),
    ("MODULE_UNDECLARED", "module # is not declared", ["NAME"]),
    ("PRIVATE_NAME", "# is private to module #", ["NAME", "NAME"]),
    ("NOT_IMPORTED", "# is declared in module #, which is not used here", ["NAME", "NAME"]),
    ("CALLS_ITSELF", "model # calls itself", ["NAME"]),
    ("OUTPUT_COUNT", "model # has # outputs; the definition names #", ["NAME", "NUMBER", "NUMBER"]),
    ("TUPLE_CALL_PLACED", "a call with several outputs cannot be guarded", []),
    ("ACTION_UNLABELLED", "action # is called outside a labelled process", ["NAME"]),
    ("ATTRIBUTE_CLASS", "a # cannot be #", ["CODE", "CODE"]),
    ("ATTRIBUTE_CALL", "# cannot call #", ["MODEL", "MODEL"]),
    ("LABEL_NO_TICK", "label # has no tick", ["NAME"]),
    ("REF_UNDECLARED", "ref # names no signal of an enclosing model", ["NAME"]),
    ("REF_PLACED", "ref must precede the embedded models", []),
    ("PRIORITY_CONSTANT", "the priority of a transition must be a constant integer", []),
    ("ONE_SETCLOCK", "an automaton sets its clock once", []),
    ("POWER_RANGE", "the exponent of ** must be at least 1", []),
    ("POWER_CONSTANT", "the exponent of ** must be a constant integer", []),
    ("POWER_CHAIN", "a chain of ** needs parentheses", []),
    ("AT_CHAIN", "a chain of @ needs parentheses", []),
    ("PRIVATE_TARGET", "private must be followed by constant, type or a model class", []),
    ("FLAT_UNDECLARED", "signal # is not declared", ["FLAT"]),
    ("STATIC_COUNT", "# expects # static parameters, found #", ["NAME", "NUMBER", "NUMBER"]),
    ("WORD_CONSTANT", "the word of # must be an integer constant", ["NAME"]),
    ("TYPE_UNDECLARED_TEXT", "type # is not declared", ["TEXT"]),
    ("RESOURCE_EXTERNAL", "the resource of # must be an external type", ["NAME"]),
    ("ACCESS_TYPE", "# accesses an integer or pointer type, found #", ["NAME", "TEXT"]),
    ("WORD_RANGE", "the word of # must fit in 32 bits", ["NAME"]),
    ("PAIR_OPERAND", "':' is supported only as the right operand of next", []),
    ("INPUT_POINTER", "input 1 of # must be a pointer, found #", ["NAME", "TYPE"]),
    ("STORE_TYPE", "input 2 of store must have type #, found #", ["TYPE", "TYPE"]),
    ("SYSCALL_INPUT", "input # of syscall must be an integer or a pointer, found #", ["NUMBER", "TYPE"]),
    ("INSTRUCTION_INPUT", "input 1 of instruction must have type ulong, found #", ["TYPE"]),
    ("NOT_IN_ITERATE", "operator # is not allowed inside iterate", ["FRAGMENT"]),
    ("ARRAY_VALUE", "an array value can only be the whole definition of a signal", []),
    ("PREV_SIGNAL", "[?] applies only to a signal name", []),
    ("PREV_OUTSIDE", "#[?] is allowed only inside iterate", ["FLAT"]),
    ("PREV_UNDEFINED", "#[?] refers to a signal the iterate body does not define", ["FLAT"]),
    ("NOT_ARRAY", "indexing a value that is not an array", []),
    ("RANGE_START", "a range must start at a constant", []),
    ("RANGE_BOUND", "the bound of a range must be an integer", []),
    ("INDEX_INTEGER", "an array index must be an integer", []),
    ("NEXT_PAIR", "next expects 'index : value' on its right", []),
    ("INDEX_RANGE", "constant index # is outside 0..#", ["LONG", "LONG"]),
    ("NEXT_TYPE", "next expects a value of type #, found #", ["TYPE", "TYPE"]),
    ("SCALAR_OPERANDS", "operator # expects scalar operands", ["FRAGMENT"]),
    ("IF_TYPES", "operator if expects operands of comparable types, found # and #", ["TYPE", "TYPE"]),
    ("IF_CONDITION", "the condition of if must be boolean", []),
    ("EFFECT_IN_IF", "# cannot be inside an if; gate it by its clock or its inputs", ["NAME"]),
    ("NO_CONVERSION", "no conversion from # to #", ["TYPE", "TYPE"]),
    ("POINTER_OFFSET", "operator # expects a pointer and an integer offset", ["FRAGMENT"]),
    ("INTEGER_OPERANDS", "operator # expects integer operands", ["FRAGMENT"]),
    ("REAL_OPERANDS", "operator # expects real operands", ["FRAGMENT"]),
    ("ORDERED", "operator # expects ordered operands, found #", ["FRAGMENT", "TYPE"]),
    ("COMPLEX_ARGUMENT", "# expects #, found #", ["NAME", "TYPE", "TYPE"]),
    ("COMPLEX_EXPANSION", "complex values are not supported by operator #", ["FRAGMENT"]),
    ("COMPARABLE", "operator # expects operands of comparable types, found # and #", ["FRAGMENT", "TYPE", "TYPE"]),
    ("ONE_TYPE", "operator # expects operands of one type", ["FRAGMENT"]),
    ("BOOLEAN_OPERANDS", "operator # expects boolean operands", ["FRAGMENT"]),
    ("UNSIGNED_OPERANDS", "operator # expects unsigned operands", ["FRAGMENT"]),
    ("WHEN_CONDITION", "the condition of when must be boolean", []),
    ("DELAY_MATCH", "the initial value of a delay must match its type", []),
    ("ENUM_UNDECLARED", "enumerated value # is not declared", ["NAME"]),
    ("ENUM_AMBIGUOUS", "enumerated value # is ambiguous", ["NAME"]),
    ("TYPE_UNDECLARED", "type # is not declared", ["NAME"]),
    ("NO_VALUE", "type # has no value #", ["NAME", "NAME"]),
    ("ITERATE_INDEX", "the index of iterate must be an array of integers", []),
    ("INDEX_DEFINED", "iterate body cannot define its index #", ["FLAT"]),
    ("WITH_UNDEFINED", "signal # in with is not defined by the iterate body", ["FLAT"]),
    ("WITH_READS", "the initial value of # cannot read a signal the iterate defines", ["FLAT"]),
    ("WITH_ARRAY", "with initializes an array only from an array constant or an array signal", []),
    ("SIGNAL_TYPE", "signal # has type # but its definition has type #", ["FLAT", "TYPE", "TYPE"]),
    ("INPUT_DEFINED", "input signal # cannot be defined", ["FLAT"]),
    ("DEFINED_TWICE", "signal # is defined twice", ["FLAT"]),
    ("RANGE_DEFINES", "a range defines an array of integers", []),
    ("ARRAY_DEFINITION", "an array signal must be defined by a constant, indices, a gather, or next", []),
    ("NEVER_DEFINED", "signal # is never defined", ["FLAT"]),
    ("RANGE_INDEX", "a range can only be the index of iterate", []),
    ("NO_CLOCK", "a constant has no clock", []),
    ("DELAY_CONSTANT", "the argument of $ cannot be a constant", []),
    ("FITS_NO_TREE", "clock of # fits no tree: it relates root clocks # and #", ["CLOCK", "CLOCK", "CLOCK"]),
    ("TWO_DEFINITIONS", "clock of # has two definitions that cannot be shown equal", ["CLOCK"]),
    ("CLOCK_CYCLE", "clocks of # are defined in terms of each other", ["CLOCK"]),
    ("GUARD_CYCLE", "the clocks of guards # depend on each other", ["CLOCK"]),
    ("NOT_INSIDE", "clock of # cannot be shown inside the clock #", ["CLOCK", "CLOCK"]),
    ("INPUT_ROOT", "input signal # must have a root of its own", ["FLAT"]),
    ("RELATION_LT", "clock relation # ^< # cannot be shown", ["CLOCK", "CLOCK"]),
    ("RELATION_GT", "clock relation # ^> # cannot be shown", ["CLOCK", "CLOCK"]),
    ("RELATION_SHARP", "clock relation # ^# # cannot be shown", ["CLOCK", "CLOCK"]),
    ("ASSERT_TYPE", "assertion on # is not boolean", ["CLOCK"]),
    ("MIN_CLOCK_EMPTY", "min_clock finds no instant for #", ["CLOCK"]),
    ("MIN_CLOCK_NAME", "min_clock expects a signal name", []),
    ("IDENTITY_CLOCKS", ":=: joins signals whose clocks cannot be shown equal", []),
    ("CONDITION_TYPE", "dependence condition is not boolean", []),
    ("SPEC_BODY", "spec must be followed by the model's body", []),
    ("GUARD_TICK", "members of guard # do not tick at every #", ["CLOCK", "CLOCK"]),
    ("ASSERT_MEMBER", "assert accepts only clock relations and :=:", []),
    ("CLOCK_UNDEFINED", "clock of # is undefined: its definition is a constant", ["CLOCK"]),
    ("SIGNAL_CYCLE", "causality cycle between signals #", ["CLOCK"]),
    ("EFFECT_CYCLE", "causality cycle between effects at #", ["CLOCK"]),
    ("CLOCK_CAUSALITY", "causality cycle between clocks", []),
    ("EFFECTS_UNORDERED", "effects # and # on resource # have no order between them; order them with -->", ["CLOCK", "CLOCK", "TYPE"]),
    ("ARRAYS_ADDRESS", "arrays need more than 2^64 bytes of address space", []),
    ("PRAGMA_TOP_ONLY", "pragma # is allowed on the top model only", ["NAME"]),
    ("PRAGMAS_END", "expected 'end pragmas', found #", ["TOKEN"]),
    ("INTERRUPT_STATEMENT", "Interrupt expects an interrupt number in quotes, found #", ["TOKEN"]),
    ("INTERRUPT_NUMBER", "interrupt number # must be a decimal from 16 to 31", ["TOKEN"]),
    ("INTERRUPT_TWICE", "interrupt # is used twice", ["NUMBER"]),
    ("BOOT_TWICE", "pragma Boot is used twice", []),
    ("PRAGMA_INPUT", "pragma object # is not an input signal", ["NAME"]),
    ("PRAGMA_EVENT", "input signal # named by a pragma must be event", ["NAME"]),
    ("PRAGMA_TWICE", "input signal # is named by two pragmas", ["NAME"]),
    ("INPUT_UNNAMED", "input signal # must be named by an Interrupt or Boot pragma", ["NAME"]),
    ("VIRT_ROOT", "the root clock of # is not the clock of an Interrupt or Boot input", ["CLOCK"]),
    ("SYSCALL_VIRT", "# is not available on QEMU virt", ["NAME"]),
    ("BOOT_MISSING", "a program with Interrupt pragmas needs a Boot pragma to enable them", []),
    ("INPUT_SHARED", "input signals # and # share one root clock; each Interrupt or Boot input needs its own", ["NAME", "NAME"]),
    ("MACHINE_UNKNOWN", "machine # is not supported; use mps2-an385", ["TOKEN"]),
    ("MACHINE_TWICE", "pragma Machine is used twice", []),
    ("INTERRUPT_NUMBER_MPS2", "interrupt number # must be a decimal from 15 to 47", ["TOKEN"]),
    ("SYSCALL_MPS2", "# is not available on mps2-an385", ["NAME"]),
    ("IMAGE_SIZE", "the program needs more than the 4 MiB of RAM on mps2-an385", []),
    ("ESCAPE", "unknown escape '#' in a string", ["CHARACTER"]),
    ("ESCAPE_RANGE", "escape value # does not fit in a byte", ["NUMBER"]),
    ("CHARACTER_COUNT", "character constant must hold one character", []),
    ("CHARACTER_RANGE", "character constant above U+00FF", []),
    ("STRING_ELEMENT", "string cannot be an array element or a field", []),
    ("STRING_INTERFACE", "string # cannot be an input or output of the top model; use read or write", ["NAME"]),
    ("IO_STRING", "input 1 of # must be a string, found #", ["NAME", "TYPE"]),
    ("WRITE_VALUE", "input 2 of write must be a boolean, an integer, a char, a real, a complex or a string, found #", ["TYPE"]),
    ("READ_TYPE", "the output of read must be a boolean, an integer, a char, a real, a complex or a string, found #", ["TYPE"]),
    ("CASE_STRING", "a case value cannot be a string literal; name it with a constant", []),
    ("HIDES_OUTPUT", "signal # is an # of # and cannot be hidden", ["NAME", "FRAGMENT", "NAME"]),
    ("MODEL_IN_INNER_WHERE", "a model cannot be declared in an inner where", []),
    ("INIT_UNUSED", "initial value of # is unused: # is not defined by $, cell or var", ["NAME", "NAME"]),
    ("REPEAT_TYPE", "'|*' expects a value of type #, found #", ["TYPE", "TYPE"]),
    ("COUNTER_EVENT", "operator # expects event operands, found #", ["FRAGMENT", "TYPE"]),
    ("REPEAT_SIZE", "'|*' produces # elements but the array has #", ["NUMBER", "NUMBER"]),
    ("RANGE_FIT", "the index range has # elements but the array has #", ["NUMBER", "NUMBER"]),
    ("CONSTANT_EXPRESSION", "the definition of constant # is not a constant expression", ["NAME"]),
    ("INIT_EXPRESSION", "the initial value of a delay is not a constant expression", []),
    ("CONSTANT_DIVIDE", "a constant expression divides by zero", []),
    ("CYCLE_SPLIT", f"causality cycle between signals # needs more than {SPLIT_CAP} splits", ["CLOCK"]),
    ("CYCLE_INSIDE", "causality cycle between signals # cannot be split by a signal it defines", ["CLOCK"]),
    ("MIN_CLOCK_TWO", "min_clock of # has more than one clock relation", ["CLOCK"]),
    ("CONDITION_LIST", "{ } when takes one signal on each side of -->", []),
    ("AFFINE_PHASE", "affine phase must be a non-negative integer", []),
    ("AFFINE_PERIOD", "affine period must be a positive integer", []),
    ("AFFINE_FORM", "# takes integer constant parameters and signal name operands", ["TOKEN"]),
    ("AFFINE_TOP", "# can only be used in the top-level process", ["TOKEN"]),
    ("PARTIAL_TUPLE", "tuple partial definitions are not supported", []),
    ("FIELD_UNKNOWN", "# has no field #", ["NAME", "NAME"]),
    ("NOT_TUPLE", "# is not a tuple and has no field #", ["NAME", "NAME"]),
    ("BUNDLE_ELEMENT", "an array element cannot be a bundle", []),
    ("TUPLE_EXPRESSION", "tuple # is used where a scalar is expected", ["NAME"]),
    ("TUPLE_SHAPE", "the tuple has # components but # has #", ["NUMBER", "NAME", "NUMBER"]),
    ("TUPLE_CALL", "# returns a tuple and must be the whole definition", ["NAME"]),
    ("TUPLE_EFFECT", "tuple # cannot be an operand of #", ["NAME", "NAME"]),
    ("TUPLE_DEPTH", "a tuple type is nested more than 4 levels", []),
    ("BUNDLE_CLOCK", "bundle # has no clock", ["NAME"]),
    ("TUPLE_INIT", "a tuple signal cannot have an initial value", []),
    ("STRUCT_ORDER", "operator <<= is not defined on struct #", ["NAME"]),
    ("TUPLE_PLACE", "a tuple type cannot be used here", []),
    ("BUNDLE_FIELD", "a bundle cannot be the type of a field", []),
    ("TUPLE_VALUE", "a tuple value is used where a scalar is expected", []),
    ("TUPLE_SPREAD", "# cannot be called inside a tuple expression", ["NAME"]),
    ("FIELD_TWICE", "field # is declared twice", ["NAME"]),
    ("TUPLE_FIELD_ARRAY", "a field of tuple type cannot be an array", []),
    ("TUPLE_EMPTY", "a tuple type needs at least one field", []),
    ("FIELD_ACCESS", "a field can only be selected from a signal name", []),
    ("TUPLE_FORWARD", "tuple type # is used before its declaration", ["NAME"]),
    ("TUPLE_KIND_MIX", "# and # are not the same kind of tuple", ["NAME", "NAME"]),
    ("SPEC_FIELD", "# in a spec is not a field of the bundle", ["NAME"]),
    ("STRUCT_ELEMENT_EQUAL", "== on elements of an array of structs is not supported", []),
    ("TUPLE_DELAY_INIT", "init on a delay of a tuple is accepted only for $ 1", []),
    ("STRUCT_ELEMENT_TARGET", "an element of # is a tuple and cannot be a target; define its fields, as in #.F[I] := E", ["NAME", "NAME"]),
    ("TUPLE_ARGUMENT", "a tuple value cannot be an argument of #", ["NAME"]),
    ("PARTIAL_MIXED", "# has both := and ::= definitions", ["FLAT"]),
    ("PARTIAL_TWO_DEFAULTS", "# has two defaultvalue definitions", ["FLAT"]),
    ("PARTIAL_CONSTANT", "partial definition of # is a constant", ["FLAT"]),
    ("PARTIAL_OVERLAP", "partial definitions of # may coincide", ["CLOCK"]),
    ("PARTIAL_NO_CLOCK", "partial definitions of # need a clock for #; add a clock equation or min_clock(#)", ["CLOCK", "CLOCK", "CLOCK"]),
    ("STATEVAR_DIRECT", "state variable # is read without ?", ["FLAT"]),
    ("STATEVAR_ASSIGNED", "state variable # cannot be defined by :=", ["FLAT"]),
    ("STATEVAR_CONTEXT", "#? needs a context clock", ["CLOCK"]),
    ("STATEVAR_NOT", "# is not a state variable", ["FLAT"]),
    ("STATEVAR_DEFAULT", "state variable # has no defaultvalue", ["FLAT"]),
    ("PARTIAL_OUTPUT", "output # cannot have partial definitions", ["FLAT"]),
    ("PARTIAL_INSIDE", "partial definition # cannot be shown inside the clock of #", ["CLOCK", "CLOCK"]),
    ("RANK", "an array type has more than 4 dimensions", []),
    ("INDEX_COUNT", "the access has more indices than the array has dimensions", []),
    ("SUBARRAY_TARGET", "a sub-array cannot be defined; define its elements", []),
    ("EXTRACT_SUBARRAY", "an extraction with fewer index arrays than the array has dimensions is not supported", []),
    ("ARRAY_TOTAL", "an array type has 2^31 or more elements", []),
    ("CONSTANT_SHAPE", "the definition of constant # is not nested as its type", ["NAME"]),
    ("SIZE_AXIS", "the dimension of size must be a constant between 1 and the number of dimensions", []),
    ("BOUNDS_TYPES", "the operands of bounds have no common scalar type", []),
    ("ELEMENT_ENDPOINT", "signal # is not an array and has no elements", ["FLAT"]),
    ("ELEMENT_LABEL", "label # has no elements", ["FLAT"]),
    ("ELEMENT_RANGE", "a dependence endpoint cannot be a range of elements", []),
    ("ENUM_SHAPE", "an enumeration does not match the shape of its array", []),
    ("STEP_CONSTANT", "a range with step needs constant bounds and a constant step", []),
    ("STEP_EMPTY", "a range with step must have a nonzero step and at least one element", []),
    ("ENUM_TYPE", "an enumeration element must have type #, found #", ["TYPE", "TYPE"]),
    ("RESTRUCTURE_TYPE", "a restructuration value must have type #, found #", ["TYPE", "TYPE"]),
    ("RANGE_TABLE_BOUNDS", "a range used as an index needs constant bounds and at least one element", []),
    ("EXTRACT_RANK", "an extraction supports at most two index arrays", []),
    ("EXTRACT_INDEX", "the index arrays of an extraction must have one size and one integer type", []),
    ("CONCAT_TYPE", "|+ expects two arrays of one element type", []),
    ("RESTRUCTURE_SHAPE", "a restructuration needs an integer index array and a value array of one size", []),
    ("EXTENSION_SHAPE", "operator # expects arrays of one shape", ["FRAGMENT"]),
    ("NOT_IN_EXTENSION", "operator # is not allowed inside an operator on arrays", ["FRAGMENT"]),
    ("EXTENSION_WHOLE", "operator # on arrays must be the whole definition of an array signal", ["FRAGMENT"]),
    ("EFFECT_IN_EXTENSION", "# is not allowed inside an operator on arrays", ["NAME"]),
    ("DELAY_COUNT", "the number of instants of a delay must be a positive constant", []),
    ("WINDOW_SIZE", "the size of a window must be a positive constant", []),
    ("DELAY_INIT_SHAPE", "the initial value of the delay must be a constant array of # elements of type #", ["LONG", "TYPE"]),
    ("ITERATE_INDEX_TWICE", "# is already the index of an enclosing iterate", ["NAME"]),
    ("ITERATE_RANK", "an iterate has at most 4 index levels", []),
    ("LOOP_PRODUCT", "the iterations of a nested iterate number more than 2147483647", []),
    ("LOOP_COUNT_INNER", "only the outermost range of a nested iterate can have a bound that is not constant", []),
    ("DELAY_IN_ITERATE", "$ cannot apply to #, which the iterate defines", ["FLAT"]),
    ("RANGE_END", "a range that does not start at 0 must end at a constant", []),
    ("SEED_ELEMENT", "with on an element must index it by the indices of the iterate, one per dimension", []),
    ("AXIS_CONSTANT", "the arguments of indices and the ranges of << >> must be constants", []),
    ("AXIS_SHAPE", "each target of indices or << >> must be an integer array whose dimensions are its ranges", []),
    ("SEQ_PLACED", "a sequential enumeration cannot be used inside an iterate, guard, case branch, label or state action", []),
    ("SEQ_RANGE", "each index of a sequential enumeration needs a to bound, in, to and step that are integer literals or constant names, a positive step and at least one value", []),
    ("CALL_IN_ITERATE_STATE", "# is called inside iterate but is not a function without iterate", ["NAME"]),
    ("TUPLE_ELEMENT", "a tuple with an element target must be defined by a call inside iterate", []),
    ("RANK_TWO", "tr expects an array of two dimensions", []),
    ("MATRIX_SHAPE", "operator # expects arrays of one element type and matching shapes", ["FRAGMENT"]),
    ("MATRIX_PLACED", "operator # must be the whole definition of an array signal outside iterate", ["FRAGMENT"]),
    ("ITERATE_PLACED", "an inner iterate must directly follow of", []),
    ("SEED_CALL", "the initial values in with cannot call a model", []),
    ("PREV_ARRAY", "the previous value of an array can only be indexed or be the left operand of next", []),
    ("SIGNAL_INIT_LIST", "signal # has type # but its initial value is a list", ["NAME", "TYPE"]),
    ("SIGNAL_INIT_ELEMENT", "signal # has type # but its initial value has an element of type #", ["NAME", "TYPE", "TYPE"]),
    ("SIGNAL_INIT_COUNT", "signal # has type # but its initial value has # elements", ["NAME", "TYPE", "NUMBER"]),
    ("SIGNAL_INIT_SHAPE", "the initial value of signal # is not nested as its type", ["NAME"]),
    ("DELAY_INIT_LIST", "the initial value of a delay must be a list of one shape", []),
]
CAPACITY_TABLES = [
    "SRC", "TOKENS", "NAMES", "TYPES", "VALUES", "MODELS", "SIGNALS", "CONSTANTS", "TABLES", "EQUATIONS", "ENTRIES",
    "GUARDS", "LABELS", "LOOPS", "GROUPS", "DEPENDENCES", "STACK", "PATHS", "LOCALS", "PARSE", "FINISH", "ITEMS",
    "OUTPUT", "INSTANCES", "INSTANTIATE", "LOOKUPS", "ROWS", "ROW_DEPENDENCES", "SEGMENTS", "LOWER",
    "CLOCKS", "DEFINITIONS", "OBLIGATIONS", "BDD", "CLOCK_NAMES", "CLOCK_TEXT", "CLOCK_SORT",
    "EDGES", "SCHEDULE_NODES", "EFFECTS", "EFFECT_ORDER", "SPLIT", "UNITS", "MICRO_OPS", "CODE", "CODE_LABELS", "DATA", "CODE_TEXT",
    "TUPLES", "REALS",
]
NAMED_FRAGMENTS = [
    ("COLON", ":"), ("ERROR_SEPARATOR", ": error: "), ("ERROR_WORD", "error "), ("SPACE", " "),
    ("ERRNO_PREFIX", "sigc: error: [Errno "), ("ERRNO_SUFFIX", "] "), ("QUOTE", "'"), ("ELLIPSIS", "..."),
    ("END_OF_FILE", "'end of file'"), ("NONE", "none"), ("OPEN", "["), ("CLOSE", "]"), ("OPEN_TWO", "[["),
    ("CLOSE_TWO", "]]"), ("CLOSE_THREE", "]]]"), ("EMPTY_LIST", "[]"), ("OPEN_NONE", "[none"),
    ("NONE_CLOSE", "none]"), ("CONST_OPEN", "[CONST ["), ("ENUMCONST_OPEN", "[ENUMCONST ["), ("SIZE_CLOSE", "] "),
    ("STATE_SUFFIX", "'state"), ("DEFINE", "DEFINE"), ("SEED", "SEED"),
    ("HASH", "#"), ("DOT", "."), ("CALL_SUFFIX", "'call"), ("EXPRESSION_AT", "[expression at "),
    ("AT", " at "), ("OUTPUT_FULL", "error 1 1 program exceeds compiler capacity: OUTPUT"),
    ("ENCODE_POSITION", ":0:0: error: "), ("OUT_OF_RANGE", " operand out of range: ["), ("LIST_SEPARATOR", ", "),
    ("PRESENCE_PREFIX", "presence inputs: "),
    ("UTF8_BYTE_PREFIX", "sigc: error: 'utf-8' codec can't decode byte 0x"),
    ("UTF8_BYTES_PREFIX", "sigc: error: 'utf-8' codec can't decode bytes in position "), ("IN_POSITION", " in position "),
    ("COLON_SPACE", ": "), ("DASH", "-"), ("RESERVATION_FAILED", "memory reservation failed"),
]
UTF8_REASONS = [
    ("INVALID_START", "invalid start byte"), ("INVALID_CONTINUATION", "invalid continuation byte"),
    ("UNEXPECTED_END", "unexpected end of data"),
]
ROLE_WORDS = ["signal", "type", "model", "constant", "label", "parameter", "module"]
PARAMETER_KINDS = ["value", "type", "model", "signal"]

LAYOUTS = [
    "NONE", "OS", "COMPILE", "DUMP_ERROR", "DUMP_TOKENS", "DUMP_PROGRAM", "DUMP_CODE", "ENCODE", "OS_OUTPUT", "PRESENCE",
    "UTF8_BYTE", "UTF8_BYTES",
]
SLICES = ["NONE", "PATH", "OUTPUT_PATH", "CLOCK"]
NUMBERS = [
    "NONE", "ERROR_LINE", "ERROR_COLUMN", "ERRNO", "ENCODE_OP0", "ENCODE_OP1", "ENCODE_OP2", "ENCODE_OP3", "OUTPUT_ERRNO",
    "UTF8_START", "UTF8_LAST",
]
COMPUTED_PREFIXES = ["FORM_NAME", "HEX_BYTE", "UTF8_REASON"]
MESSAGE_SLOTS = 10
MESSAGE_SLOT_ORDER = [0, 1, 10, 11, 12, 2, 3, 4, 13, 14, 15, 5, 6, 7, 16, 17, 18, 8, 9]
LAYOUT_ROWS = {
    "OS": [("ERRNO_PREFIX", "NONE", "ERRNO", "ERRNO_SUFFIX", 0, -1), ("", "PATH", "NONE", "", 1, -1)],
    "COMPILE": [
        ("", "PATH", "NONE", "COLON", 0, -1),
        ("", "NONE", "ERROR_LINE", "COLON", 0, -1),
        ("", "NONE", "ERROR_COLUMN", "ERROR_SEPARATOR", 0, -1),
        *[("", "NONE", "NONE", "", 0, slot) for slot in MESSAGE_SLOT_ORDER],
        ("", "NONE", "NONE", "", 1, -1),
    ],
    "DUMP_ERROR": [
        ("ERROR_WORD", "NONE", "ERROR_LINE", "SPACE", 0, -1),
        ("", "NONE", "ERROR_COLUMN", "SPACE", 0, -1),
        *[("", "NONE", "NONE", "", 0, slot) for slot in MESSAGE_SLOT_ORDER],
        ("", "NONE", "NONE", "", 1, -1),
    ],
    "ENCODE": [
        ("", "PATH", "NONE", "ENCODE_POSITION", 0, -1),
        ("FORM_NAME", "NONE", "NONE", "OUT_OF_RANGE", 0, -1),
        ("", "NONE", "ENCODE_OP0", "LIST_SEPARATOR", 0, -1),
        ("", "NONE", "ENCODE_OP1", "LIST_SEPARATOR", 0, -1),
        ("", "NONE", "ENCODE_OP2", "LIST_SEPARATOR", 0, -1),
        ("", "NONE", "ENCODE_OP3", "CLOSE", 1, -1),
    ],
    "OS_OUTPUT": [("ERRNO_PREFIX", "NONE", "OUTPUT_ERRNO", "ERRNO_SUFFIX", 0, -1), ("", "OUTPUT_PATH", "NONE", "", 1, -1)],
    "PRESENCE": [("PRESENCE_PREFIX", "CLOCK", "NONE", "", 1, -1)],
    "UTF8_BYTE": [
        ("UTF8_BYTE_PREFIX", "NONE", "NONE", "", 0, -1),
        ("HEX_BYTE", "NONE", "NONE", "IN_POSITION", 0, -1),
        ("", "NONE", "UTF8_START", "COLON_SPACE", 0, -1),
        ("UTF8_REASON", "NONE", "NONE", "", 1, -1),
    ],
    "UTF8_BYTES": [
        ("UTF8_BYTES_PREFIX", "NONE", "UTF8_START", "DASH", 0, -1),
        ("", "NONE", "UTF8_LAST", "COLON_SPACE", 0, -1),
        ("UTF8_REASON", "NONE", "NONE", "", 1, -1),
    ],
}

POWERS = [10 ** k for k in range(20)]

PARSE_STATES = [
    "COPY_TYPES", "START", "MODEL_NAME", "MODEL_EQUAL", "MODEL_OPEN", "MODEL_QUESTION", "INPUTS", "MODEL_BANG",
    "OUTPUTS", "MODEL_CLOSE", "MODEL_BODY", "MODEL_AFTER", "PROGRAM", "END_SEMICOLON", "END_CHECK", "TYPE_STATEMENT",
    "TYPE_SKIP", "TYPE", "TYPE_SIZE", "TYPE_CLOSE", "TYPE_NAME", "TYPE_INTERN", "DECLARE_NAME", "DECLARE_SEPARATOR",
    "CONSTANT_NAME", "CONSTANT_EQUAL", "CONSTANT_DEFINITION", "INTEGER_CONSTANT", "CONSTANT_ELEMENT",
    "CONSTANT_SCALAR", "CONSTANT_SEPARATOR", "LABEL_NAME", "LABEL_SEPARATOR", "REF_NAME", "REF_SEPARATOR", "PROCESS", "PATH_COPY",
    "GUARD_COLONS", "ITERATE_NAME", "ITERATE_OF", "EQUATION", "DEPENDENCE", "EQUATION_END", "GROUP_MEMBER", "POP",
    "OPERAND", "PARAMETER", "PARAMETER_CLOSE", "OPERATOR", "BRANCH", "PRAGMA_NAME", "PRAGMA_OPEN", "PRAGMA_OBJECT",
    "PRAGMA_CLOSE", "PRAGMA_STATEMENT", "PRAGMA_OTHER", "PRAGMA_SKIP", "PRAGMA_TEXT", "SET_NAME", "SET_SEPARATOR",
    "SET_EMIT", "ALIAS_END", "HIDE_NAME", "HIDE_SEPARATOR", "DECLARE_INIT", "TUPLE_NAME", "TUPLE_SEPARATOR", "CASE_IN",
    "CASE_BRANCH", "CASE_COPY", "CASE_LITERAL", "CASE_SCAN", "CASE_ELSE_VALUE", "CASE_COMPARE", "CASE_JOIN",
    "CASE_SEPARATOR", "CASE_WHEN", "CASE_GUARD", "STATE_SIGNAL", "STATE_CALL", "STATE_WHEN", "STATE_GUARD", "SYNC",
    "REPEAT_START", "INDEX_EMIT", "REPEAT_EMIT", "ARRAY_TO", "INDEX_TYPE", "INDEX_DECLARE", "SEQ_HEAD", "SEQ_EMIT", "TUPLE_SKIP", "TUPLE_SEEK", "TUPLE_EMIT", "CONSTANT_END", "INIT_END", "PARAMETER_OPEN", "PARAMETER_DECL", "PARAMETER_END", "MODULE_NAME", "MODULE_EQUAL", "MODULE_END",
    "USE_NAME", "USE_SEPARATOR", "MODEL_COPY", "PARAMETER_MODEL", "PARAMETER_MODEL_NAME", "STALL", "DONE", "FAILED",
    "DELAY_ELEMENT", "DELAY_LIST_SIZE", "DELAY_LIST_END",
]
OPERAND_CASES = ["EMPTY_CALL", "LITERAL", "CALL", "PARAMETERS", "SIGNAL", "OPEN_PAREN", "IF", "PREFIX", "PLUS", "FAIL"]
OPERATOR_CASES = ["REDUCE", "BINARY", "THEN", "ELSE", "DELAY", "PREVIOUS", "OPEN_SQUARE", "CLOSE", "COMMA", "RETURN", "INIT", "STATE"]
FRAMES = ["COMPOSE", "LABEL", "GUARD", "ITERATE", "CASE"]
DELAY_INITS = ["NONE", "CONST", "ENUMCONST", "NAME", "SIZE", "SIZE2", "SIZE3", "SIZE4"]
FINISH_PHASES = [
    "START", "LABEL", "USE", "SIGNAL", "HIDE", "INITS", "STATEMENT", "REWRITE_EQ", "REWRITE_MEMBER", "REWRITE_GUARD",
    "REWRITE_TRIGGER", "CLOCK", "STATE", "PICK", "CUR", "CUR_TAIL", "GROUP", "TICK", "GUARD_START", "DEFINE_PARSE", "DEFINE_FINISH",
    "READ_PARSE", "READ_FINISH", "READ_MEMBERS", "READ_DEPS", "ON", "FILTER", "DONE", "FAILED", "DEFINE_GROUP",
]
TICK_STEPS = ["LABEL", "USE", "EQUATION", "SCAN", "PART", "COPY", "CLOCK", "DEFAULT", "END"]
LOWER_STATES = [
    "SIGNAL", "LABEL", "VALUE", "ARRAY", "TABLE", "LOOP", "STATEVAR", "EQUATION", "GROUP", "START", "SCAN", "ENTRY", "NEVER",
    "MEMBERS", "PARTIAL", "CXTYPE", "CXTABLE", "CXMAP", "CXEXPAND", "DONE", "FAILED",
]
REAL_PHASES = ["START", "CHAR", "MULADD", "DECIDE", "SCALE", "BITS", "SHIFT", "COMPARE", "SUB", "TRIM", "ROUND", "FINISH"]
POST_STATES = ["DEPENDENCE", "ROWS", "PREFIX", "PLACE", "WALK", "LABELSUM", "SIZE", "DONE", "FAILED"]
EXPAND_STATES = ["PLACE", "PAIRS", "PREV", "DONE", "FAILED"]
CLOCK_STATES = [
    "ROWS", "SAMPLES", "GROUPS", "PAIRS", "REWRITE", "TARGETS", "GUARDS", "SCAN", "DEFS", "APPLY", "WAIT", "CHECKS", "DONE", "FAILED",
]
BDD_JOBS = ["AND", "OR", "WALK", "ANDNOT", "XOR"]
SPLIT_PHASES = ["START", "LIVE", "BLOCK", "PLACE", "PICK", "RECORD", "UNWIND", "DONE"]
OBLIGATION_KINDS = ["INSIDE", "LT", "GT", "SHARP", "EQUAL", "BOOLEAN", "TICK", "IDENTITY", "PARTIAL"]
KEY_FAMILIES = ["SIGNAL", "LABEL", "CALL_LABEL", "VALUE", "PAIR", "ARRAY"]
KEY_STRIDE = 8
INSTANTIATE_PHASES = [
    "ROOT", "INSTANCE", "LABEL", "SIGNAL", "FINISH_SIGNAL", "LOOP", "EQUATION", "FINISH_EQUATION", "GROUP",
    "FINISH_GROUP", "DEPENDENCE", "ENTRY", "ANCESTRY", "PATH", "INPUT", "EMIT", "SLOT", "BIND", "DONE", "FAILED",
]
SHAPES = ["NAME", "NUMBER", "FRAGMENT", "POSITION", "TYPE", "USE", "END_POINT", "LIST", "GROUP"]
SCALAR_ATOMS = ["NAME", "NUMBER", "FRAGMENT", "LINE", "COLUMN", "TYPE_HEAD", "TYPE_ELEMENT"]
SCALAR_PROGRAMS = {
    "NAME": ["NAME"], "NUMBER": ["NUMBER"], "FRAGMENT": ["FRAGMENT"], "POSITION": ["LINE", "COLUMN"],
    "TYPE": ["TYPE_HEAD", "TYPE_ELEMENT"], "USE": ["NUMBER", "NAME", "LINE", "COLUMN"],
    "END_POINT": ["NAME", "LINE", "COLUMN"],
}
SCALAR_WIDTH = 4
LIST_KINDS = ["NONE", "NAMES", "NUMBERS", "OPS", "ARGS"]
COLUMN_SHAPES = {
    "name": "NAME", "types.kind": "FRAGMENT", "types.name": "TYPE", "types.values": "LIST NAMES",
    "models.name": "NAME", "models.kind": "NAME", "models.labels": "LIST NAMES", "signal_names": "NAME",
    "signal_roles": "FRAGMENT", "signal_positions": "POSITION", "constant_names": "NAME", "table_values": "LIST NUMBERS",
    "equation_targets": "NAME", "equation_ops": "LIST OPS", "equation_args": "LIST ARGS",
    "equation_positions": "POSITION", "equation_kinds": "FRAGMENT", "equation_labels": "LIST NAMES",
    "equation_guards": "LIST NUMBERS", "guard_ops": "LIST OPS", "guard_args": "LIST ARGS",
    "guard_positions": "POSITION", "guard_context": "LIST NUMBERS", "guard_labels": "LIST NAMES",
    "guard_signals": "NAME", "label_names": "NAME", "label_uses": "USE", "loop_names": "NAME",
    "loop_positions": "POSITION", "constraint_groups": "GROUP", "constraint_positions": "POSITION",
    "constraint_guards": "LIST NUMBERS", "dependence_from": "END_POINT", "dependence_to": "END_POINT",
    "dependence_positions": "POSITION", "dependence_guards": "LIST NUMBERS",
    "rows.op": "FRAGMENT", "rows.groups": "LIST NUMBERS", "rows.group_positions": "POSITION",
    "rows.war": "LIST NUMBERS", "loop_orders": "LIST NUMBERS", "snapshots": "LIST NUMBERS", "rows.effects.kind": "NAME", "loops.defined": "LIST NUMBERS",
    "def_kind": "FRAGMENT", "node_kind": "FRAGMENT",
}
ITEM_CLASSES = ["HEADER", "NEWLINE", "OPEN", "CLOSE", "NAME", "TOKEN", "NUMBER", "FRAGMENT", "SIZE", "PREFIX"]
ARG_ATOMS = [
    "OPEN", "CLOSE", "NAME", "LINE", "COLUMN", "VALUE", "TYPE_NUMBER", "TYPE_NAME", "VALUE_NAME", "INIT_LINE",
    "INIT_COLUMN", "NONE", "CONST", "ENUMCONST", "PARAMS", "COUNT",
]
DELAY_VARIANTS = ["DELAY_NONE", "DELAY_CONST", "DELAY_ENUMCONST"]
ARG_PROGRAMS = {
    "CONST": ["OPEN", "VALUE", "TYPE_NUMBER", "CLOSE"],
    "SIGNAL": ["OPEN", "NAME", "LINE", "COLUMN", "CLOSE"],
    "ENUMCONST": ["OPEN", "TYPE_NAME", "VALUE_NAME", "LINE", "COLUMN", "CLOSE"],
    "CALL": ["OPEN", "LINE", "COLUMN", "NAME", "PARAMS", "COUNT", "CLOSE"],
    "EFFECT": ["OPEN", "LINE", "COLUMN", "NAME", "PARAMS", "COUNT", "CLOSE"],
    "DELAY_NONE": ["OPEN", "LINE", "COLUMN", "NONE", "CLOSE"],
    "DELAY_CONST": ["OPEN", "LINE", "COLUMN", "OPEN", "CONST", "OPEN", "VALUE", "TYPE_NUMBER", "CLOSE", "CLOSE", "CLOSE"],
    "DELAY_ENUMCONST": [
        "OPEN", "LINE", "COLUMN", "OPEN", "ENUMCONST", "OPEN", "TYPE_NAME", "VALUE_NAME", "INIT_LINE", "INIT_COLUMN",
        "CLOSE", "CLOSE", "CLOSE",
    ],
}
POSITION_PROGRAM = ["OPEN", "LINE", "COLUMN", "CLOSE"]
ARG_WIDTH = 13
CALL_PARAMS_STEP = 4
PARAM_STEPS = 6
CONDITION_PRECEDENCE = 9
DELAY_PRECEDENCE = 21


FORMS = [
    "MOVZ_X", "MOVZ_W", "MOVK_X", "MOVK_W", "ADD_X_IMM", "ADD_W_IMM", "SUB_X_IMM", "SUB_W_IMM", "SUBS_X_IMM",
    "SUBS_W_IMM", "ADD_X", "ADDS_X", "SUB_X", "SUBS_X", "AND_X", "AND_W", "ORR_X", "ORR_W", "EOR_X", "ORN_X",
    "EOR_X_ONE", "LSLV_X", "LSRV_X", "SDIV_X", "UDIV_X", "MUL_X", "MSUB_X", "UMULH_X", "CSEL_X", "CSINC_W", "CSNEG_X",
    "LDR_X", "LDR_W", "LDRSW_X", "LDRH_W", "LDRSH_X", "LDRB_W", "STR_X", "STR_W", "STRH_W", "STRB_W",
    "LDR_X_REG", "LDR_W_REG", "LDRSW_X_REG", "LDRH_W_REG", "LDRSH_X_REG", "LDRB_W_REG", "STR_X_REG", "STR_W_REG",
    "STRH_W_REG", "STRB_W_REG", "LDR_X_POST", "STR_X_POST", "STR_W_POST", "STRB_W_POST", "LDRB_W_PRE",
    "B", "BL", "B_COND", "CBZ_W", "CBZ_X", "CBNZ_X", "ADRP", "RET", "SVC_80", "WORD", "WFI",
    "FMOV_S_W", "FMOV_D_X", "FMOV_W_S", "FMOV_X_D", "FADD_S", "FADD_D", "FSUB_S", "FSUB_D", "FMUL_S", "FMUL_D",
    "FDIV_S", "FDIV_D", "FNEG_S", "FNEG_D", "FCMP_S", "FCMP_D", "SCVTF_S_X", "SCVTF_D_X", "UCVTF_S_X", "UCVTF_D_X",
    "FCVTZS_X_S", "FCVTZS_X_D", "FCVT_D_S", "FCVT_S_D", "CLZ_X", "MSR_CPACR", "ISB", "FMADD_S", "FMADD_D", "FSQRT_D",
    "MOVN_X", "ASRV_X", "UBFM_X", "SBFM_X", "FABS_D", "FMOV_D", "FRINTM_D", "FRINTP_D", "FRINTZ_D",
]
MOVE_X = ((0, 0, 5, 0), (2, 0, 16, 5), (3, 0, 2, 21))
MOVE_W = ((0, 0, 5, 0), (2, 0, 16, 5), (3, 0, 1, 21))
IMM12 = ((0, 0, 5, 0), (1, 0, 5, 5), (2, 0, 12, 10))
REG2 = ((0, 0, 5, 0), (1, 0, 5, 5))
REG3 = ((0, 0, 5, 0), (1, 0, 5, 5), (2, 0, 5, 16))
REG4 = ((0, 0, 5, 0), (1, 0, 5, 5), (2, 0, 5, 16), (3, 0, 5, 10))
BITFIELD = ((0, 0, 5, 0), (1, 0, 5, 5), (2, 0, 6, 16), (3, 0, 6, 10))
SELECT = ((0, 0, 5, 0), (1, 0, 5, 5), (2, 0, 5, 16), (3, 0, 4, 12))
SCALED = tuple(((0, 0, 5, 0), (1, 0, 5, 5), (2, scale, 12, 10)) for scale in range(4))
INDEXED = ((0, 0, 5, 0), (1, 0, 5, 5), (2, 0, 9, 12))
BRANCH26 = ((2, 2, 26, 0),)
BRANCH19 = ((3, 0, 4, 0), (2, 2, 19, 5))
COMPARE_BRANCH = ((0, 0, 5, 0), (2, 2, 19, 5))
PAGE21 = ((0, 0, 5, 0), (2, 12, 2, 29), (2, 14, 19, 5))
WORD32 = ((2, 0, 32, 0),)
FIELD_KINDS = ["NONE", "PCREL", "PAGE", "PAGEOFF", "THUMB_PCREL", "ABS_LO", "ABS_HI"]
FORM_SPECS = [
    ("movz x", 0xD2800000, MOVE_X, False, "NONE"),
    ("movz w", 0x52800000, MOVE_W, False, "NONE"),
    ("movk x", 0xF2800000, MOVE_X, False, "NONE"),
    ("movk w", 0x72800000, MOVE_W, False, "NONE"),
    ("add x imm", 0x91000000, IMM12, False, "PAGEOFF"),
    ("add w imm", 0x11000000, IMM12, False, "NONE"),
    ("sub x imm", 0xD1000000, IMM12, False, "NONE"),
    ("sub w imm", 0x51000000, IMM12, False, "NONE"),
    ("subs x imm", 0xF1000000, IMM12, False, "NONE"),
    ("subs w imm", 0x71000000, IMM12, False, "NONE"),
    ("add x", 0x8B000000, REG3, False, "NONE"),
    ("adds x", 0xAB000000, REG3, False, "NONE"),
    ("sub x", 0xCB000000, REG3, False, "NONE"),
    ("subs x", 0xEB000000, REG3, False, "NONE"),
    ("and x", 0x8A000000, REG3, False, "NONE"),
    ("and w", 0x0A000000, REG3, False, "NONE"),
    ("orr x", 0xAA000000, REG3, False, "NONE"),
    ("orr w", 0x2A000000, REG3, False, "NONE"),
    ("eor x", 0xCA000000, REG3, False, "NONE"),
    ("orn x", 0xAA200000, REG3, False, "NONE"),
    ("eor x one", 0xD2400000, REG2, False, "NONE"),
    ("lslv x", 0x9AC02000, REG3, False, "NONE"),
    ("lsrv x", 0x9AC02400, REG3, False, "NONE"),
    ("sdiv x", 0x9AC00C00, REG3, False, "NONE"),
    ("udiv x", 0x9AC00800, REG3, False, "NONE"),
    ("mul x", 0x9B007C00, REG3, False, "NONE"),
    ("msub x", 0x9B008000, REG4, False, "NONE"),
    ("umulh x", 0x9BC07C00, REG3, False, "NONE"),
    ("csel x", 0x9A800000, SELECT, False, "NONE"),
    ("csinc w", 0x1A800400, SELECT, False, "NONE"),
    ("csneg x", 0xDA800400, SELECT, False, "NONE"),
    ("ldr x", 0xF9400000, SCALED[3], False, "PAGEOFF"),
    ("ldr w", 0xB9400000, SCALED[2], False, "PAGEOFF"),
    ("ldrsw x", 0xB9800000, SCALED[2], False, "PAGEOFF"),
    ("ldrh w", 0x79400000, SCALED[1], False, "PAGEOFF"),
    ("ldrsh x", 0x79800000, SCALED[1], False, "PAGEOFF"),
    ("ldrb w", 0x39400000, SCALED[0], False, "PAGEOFF"),
    ("str x", 0xF9000000, SCALED[3], False, "PAGEOFF"),
    ("str w", 0xB9000000, SCALED[2], False, "PAGEOFF"),
    ("strh w", 0x79000000, SCALED[1], False, "PAGEOFF"),
    ("strb w", 0x39000000, SCALED[0], False, "PAGEOFF"),
    ("ldr x reg", 0xF8607800, REG3, False, "NONE"),
    ("ldr w reg", 0xB8607800, REG3, False, "NONE"),
    ("ldrsw x reg", 0xB8A07800, REG3, False, "NONE"),
    ("ldrh w reg", 0x78607800, REG3, False, "NONE"),
    ("ldrsh x reg", 0x78A07800, REG3, False, "NONE"),
    ("ldrb w reg", 0x38606800, REG3, False, "NONE"),
    ("str x reg", 0xF8207800, REG3, False, "NONE"),
    ("str w reg", 0xB8207800, REG3, False, "NONE"),
    ("strh w reg", 0x78207800, REG3, False, "NONE"),
    ("strb w reg", 0x38206800, REG3, False, "NONE"),
    ("ldr x post", 0xF8400400, INDEXED, True, "NONE"),
    ("str x post", 0xF8000400, INDEXED, True, "NONE"),
    ("str w post", 0xB8000400, INDEXED, True, "NONE"),
    ("strb w post", 0x38000400, INDEXED, True, "NONE"),
    ("ldrb w pre", 0x38400C00, INDEXED, True, "NONE"),
    ("b", 0x14000000, BRANCH26, True, "PCREL"),
    ("bl", 0x94000000, BRANCH26, True, "PCREL"),
    ("b.cond", 0x54000000, BRANCH19, True, "PCREL"),
    ("cbz w", 0x34000000, COMPARE_BRANCH, True, "PCREL"),
    ("cbz x", 0xB4000000, COMPARE_BRANCH, True, "PCREL"),
    ("cbnz x", 0xB5000000, COMPARE_BRANCH, True, "PCREL"),
    ("adrp", 0x90000000, PAGE21, True, "PAGE"),
    ("ret", 0xD65F03C0, (), False, "NONE"),
    ("svc 0x80", 0xD4001001, (), False, "NONE"),
    ("word", 0x00000000, WORD32, False, "NONE"),
    ("wfi", 0xD503207F, (), False, "NONE"),
    ("fmov s w", 0x1E270000, REG2, False, "NONE"),
    ("fmov d x", 0x9E670000, REG2, False, "NONE"),
    ("fmov w s", 0x1E260000, REG2, False, "NONE"),
    ("fmov x d", 0x9E660000, REG2, False, "NONE"),
    ("fadd s", 0x1E202800, REG3, False, "NONE"),
    ("fadd d", 0x1E602800, REG3, False, "NONE"),
    ("fsub s", 0x1E203800, REG3, False, "NONE"),
    ("fsub d", 0x1E603800, REG3, False, "NONE"),
    ("fmul s", 0x1E200800, REG3, False, "NONE"),
    ("fmul d", 0x1E600800, REG3, False, "NONE"),
    ("fdiv s", 0x1E201800, REG3, False, "NONE"),
    ("fdiv d", 0x1E601800, REG3, False, "NONE"),
    ("fneg s", 0x1E214000, REG2, False, "NONE"),
    ("fneg d", 0x1E614000, REG2, False, "NONE"),
    ("fcmp s", 0x1E202000, REG3, False, "NONE"),
    ("fcmp d", 0x1E602000, REG3, False, "NONE"),
    ("scvtf s x", 0x9E220000, REG2, False, "NONE"),
    ("scvtf d x", 0x9E620000, REG2, False, "NONE"),
    ("ucvtf s x", 0x9E230000, REG2, False, "NONE"),
    ("ucvtf d x", 0x9E630000, REG2, False, "NONE"),
    ("fcvtzs x s", 0x9E380000, REG2, False, "NONE"),
    ("fcvtzs x d", 0x9E780000, REG2, False, "NONE"),
    ("fcvt d s", 0x1E22C000, REG2, False, "NONE"),
    ("fcvt s d", 0x1E624000, REG2, False, "NONE"),
    ("clz x", 0xDAC01000, REG2, False, "NONE"),
    ("msr cpacr_el1", 0xD5181040, ((0, 0, 5, 0),), False, "NONE"),
    ("isb", 0xD5033FDF, (), False, "NONE"),
    ("fmadd s", 0x1F000000, REG4, False, "NONE"),
    ("fmadd d", 0x1F400000, REG4, False, "NONE"),
    ("fsqrt d", 0x1E61C000, REG2, False, "NONE"),
    ("movn x", 0x92800000, MOVE_X, False, "NONE"),
    ("asrv x", 0x9AC02800, REG3, False, "NONE"),
    ("ubfm x", 0xD3400000, BITFIELD, False, "NONE"),
    ("sbfm x", 0x93400000, BITFIELD, False, "NONE"),
    ("fabs d", 0x1E60C000, REG2, False, "NONE"),
    ("fmov d", 0x1E604000, REG2, False, "NONE"),
    ("frintm d", 0x1E654000, REG2, False, "NONE"),
    ("frintp d", 0x1E64C000, REG2, False, "NONE"),
    ("frintz d", 0x1E65C000, REG2, False, "NONE"),
]


def memory_order(word):
    return ((word & 0xFFFF) << 16) | (word >> 16)


def memory_field(field):
    slot, low, width, at = field
    assert at + width <= 16 or at >= 16
    return (slot, low, width, at - 16 if at >= 16 else at + 16)


THUMB_IMM16 = ((0, 0, 4, 8), (2, 0, 8, 0), (2, 8, 3, 12), (2, 11, 1, 26), (2, 12, 4, 16))
THUMB_IMM12 = ((0, 0, 4, 8), (1, 0, 4, 16), (2, 0, 8, 0), (2, 8, 3, 12), (2, 11, 1, 26))
THUMB_IMM8 = ((0, 0, 4, 8), (1, 0, 4, 16), (2, 0, 8, 0))
THUMB_REG3 = ((0, 0, 4, 8), (1, 0, 4, 16), (2, 0, 4, 0))
THUMB_REG3_SHIFT = THUMB_REG3 + ((3, 0, 2, 6), (3, 2, 3, 12))
THUMB_REG2 = ((0, 0, 4, 8), (1, 0, 4, 0))
THUMB_SHIFT_IMM = ((0, 0, 4, 8), (1, 0, 4, 0), (2, 0, 2, 6), (2, 2, 3, 12))
THUMB_MULTIPLY = ((0, 0, 4, 8), (1, 0, 4, 16), (2, 0, 4, 0), (3, 0, 4, 12))
THUMB_LONG_MULTIPLY = ((0, 0, 4, 12), (1, 0, 4, 16), (2, 0, 4, 0), (3, 0, 4, 8))
THUMB_OFFSET12 = ((0, 0, 4, 12), (1, 0, 4, 16), (2, 0, 12, 0))
THUMB_OFFSET8 = ((0, 0, 4, 12), (1, 0, 4, 16), (2, 0, 8, 0))
THUMB_DUAL = ((0, 0, 4, 12), (1, 0, 4, 16), (2, 2, 8, 0), (3, 0, 4, 8))
THUMB_BRANCH = ((2, 1, 11, 0), (2, 12, 10, 16), (2, 22, 1, 26))
THUMB_SKIP = ((3, 0, 4, 24),)
THUMB_WORD = ((2, 0, 16, 0), (2, 16, 16, 16))
THUMB_SPECS = [
    ("MOVW_T", "movw", 0xF2400000, THUMB_IMM16, False, "NONE"),
    ("MOVT_T", "movt", 0xF2C00000, THUMB_IMM16, False, "NONE"),
    ("MOVW_ABS_T", "movw address", 0xF2400000, THUMB_IMM16, False, "ABS_LO"),
    ("MOVT_ABS_T", "movt address", 0xF2C00000, THUMB_IMM16, False, "ABS_HI"),
    ("ADDW_T", "addw", 0xF2000000, THUMB_IMM12, False, "NONE"),
    ("SUBW_T", "subw", 0xF2A00000, THUMB_IMM12, False, "NONE"),
    ("AND_T", "and.w", 0xEA000000, THUMB_REG3, False, "NONE"),
    ("ORR_T", "orr.w", 0xEA400000, THUMB_REG3, False, "NONE"),
    ("ORRS_T", "orrs.w", 0xEA500000, THUMB_REG3, False, "NONE"),
    ("EOR_T", "eor.w", 0xEA800000, THUMB_REG3, False, "NONE"),
    ("ADD_SHIFT_T", "add.w shifted", 0xEB000000, THUMB_REG3_SHIFT, False, "NONE"),
    ("ADDS_T", "adds.w", 0xEB100000, THUMB_REG3, False, "NONE"),
    ("ADC_T", "adc.w", 0xEB400000, THUMB_REG3, False, "NONE"),
    ("ADCS_T", "adcs.w", 0xEB500000, THUMB_REG3, False, "NONE"),
    ("SBC_T", "sbc.w", 0xEB600000, THUMB_REG3, False, "NONE"),
    ("SBCS_T", "sbcs.w", 0xEB700000, THUMB_REG3, False, "NONE"),
    ("SUBS_T", "subs.w", 0xEBB00000, THUMB_REG3, False, "NONE"),
    ("MOV_T", "mov.w", 0xEA4F0000, THUMB_REG2, False, "NONE"),
    ("MVN_T", "mvn.w", 0xEA6F0000, THUMB_REG2, False, "NONE"),
    ("LSL_T", "lsl.w", 0xFA00F000, THUMB_REG3, False, "NONE"),
    ("LSR_T", "lsr.w", 0xFA20F000, THUMB_REG3, False, "NONE"),
    ("LSL_IMM_T", "lsl.w imm", 0xEA4F0000, THUMB_SHIFT_IMM, False, "NONE"),
    ("LSR_IMM_T", "lsr.w imm", 0xEA4F0010, THUMB_SHIFT_IMM, False, "NONE"),
    ("ASR_IMM_T", "asr.w imm", 0xEA4F0020, THUMB_SHIFT_IMM, False, "NONE"),
    ("UMULL_T", "umull", 0xFBA00000, THUMB_LONG_MULTIPLY, False, "NONE"),
    ("MLA_T", "mla", 0xFB000000, THUMB_MULTIPLY, False, "NONE"),
    ("MLS_T", "mls", 0xFB000010, THUMB_MULTIPLY, False, "NONE"),
    ("UDIV_T", "udiv", 0xFBB0F0F0, THUMB_REG3, False, "NONE"),
    ("SUBS_IMM_T", "subs.w imm", 0xF1B00000, THUMB_IMM8, False, "NONE"),
    ("ADDS_IMM_T", "adds.w imm", 0xF1100000, THUMB_IMM8, False, "NONE"),
    ("ADC_IMM_T", "adc.w imm", 0xF1400000, THUMB_IMM8, False, "NONE"),
    ("SBCS_IMM_T", "sbcs.w imm", 0xF1700000, THUMB_IMM8, False, "NONE"),
    ("RSB_IMM_T", "rsb.w imm", 0xF1C00000, THUMB_IMM8, False, "NONE"),
    ("EOR_IMM_T", "eor.w imm", 0xF0800000, THUMB_IMM8, False, "NONE"),
    ("ORR_IMM_T", "orr.w imm", 0xF0400000, THUMB_IMM8, False, "NONE"),
    ("LDR_T", "ldr.w", 0xF8D00000, THUMB_OFFSET12, False, "NONE"),
    ("LDRB_T", "ldrb.w", 0xF8900000, THUMB_OFFSET12, False, "NONE"),
    ("LDRH_T", "ldrh.w", 0xF8B00000, THUMB_OFFSET12, False, "NONE"),
    ("LDRSH_T", "ldrsh.w", 0xF9B00000, THUMB_OFFSET12, False, "NONE"),
    ("STR_T", "str.w", 0xF8C00000, THUMB_OFFSET12, False, "NONE"),
    ("STRB_T", "strb.w", 0xF8800000, THUMB_OFFSET12, False, "NONE"),
    ("STRH_T", "strh.w", 0xF8A00000, THUMB_OFFSET12, False, "NONE"),
    ("LDRD_T", "ldrd", 0xE9D00000, THUMB_DUAL, False, "NONE"),
    ("STRD_T", "strd", 0xE9C00000, THUMB_DUAL, False, "NONE"),
    ("LDRD_POST_T", "ldrd post", 0xE8F00000, THUMB_DUAL, False, "NONE"),
    ("STRD_POST_T", "strd post", 0xE8E00000, THUMB_DUAL, False, "NONE"),
    ("STRB_POST_T", "strb post", 0xF8000B00, THUMB_OFFSET8, False, "NONE"),
    ("LDRB_POST_T", "ldrb post", 0xF8100B00, THUMB_OFFSET8, False, "NONE"),
    ("LDRB_PRE_DEC_T", "ldrb pre", 0xF8100D00, THUMB_OFFSET8, False, "NONE"),
    ("STR_PRE_DEC_T", "str pre", 0xF8400D00, THUMB_OFFSET8, False, "NONE"),
    ("LDR_POST_T", "ldr post", 0xF8500B00, THUMB_OFFSET8, False, "NONE"),
    ("B_W_T", "b.w", 0xF000B800, THUMB_BRANCH, True, "THUMB_PCREL"),
    ("BL_T", "bl", 0xF000F800, THUMB_BRANCH, True, "THUMB_PCREL"),
    ("SKIP_T", "b.n skip", 0xD002BF00, THUMB_SKIP, False, "NONE"),
    ("BX_LR_T", "bx lr", 0x4770BF00, (), False, "NONE"),
    ("WFI_T", "wfi.w", 0xF3AF8003, (), False, "NONE"),
    ("MSR_PRIMASK_T", "msr primask", 0xF3808810, (), False, "NONE"),
    ("WORD_T", "thumb word", 0x00000000, THUMB_WORD, False, "NONE"),
]
FORMS += [name for name, _, _, _, _, _ in THUMB_SPECS]
FORM_SPECS += [
    (text, memory_order(base), tuple(memory_field(field) for field in fields), signed, kind)
    for _, text, base, fields, signed, kind in THUMB_SPECS
]
FORM_FIELD_SLOTS = 5
MACHO_BASE = 0x100000000
TEXT_OFFSET = 392
COMMAND_BYTES = 360
SEGMENT_BYTES = 16384
ELF_VARIABLES = ["CONSTANT", "SIGNED_BYTES", "MEMORY_BYTES"]
HEADER_VARIABLES = ["CONSTANT", "TEXT_BYTES", "DATA_BYTES", "SIGNED_BYTES", "LINKEDIT_BYTES", "SIGNATURE_BYTES"]
SIGNATURE_VARIABLES = ["CONSTANT", "SIGNATURE_BYTES", "DIRECTORY_BYTES", "PAGES", "SIGNED_BYTES"]
SUPERBLOB_HEADER_BYTES = 20
CODE_DIRECTORY_HEADER_BYTES = 48
HASH_BYTES = 32
MARKER_BASE = 0xF0000000
CONDITIONS = {"EQ": 0, "NE": 1, "HS": 2, "LO": 3, "MI": 4, "HI": 8, "LS": 9, "GE": 10, "LT": 11, "GT": 12, "LE": 13}
XZR = 31
SP = 31
UINTEGER_TYPE = 7
LOAD_FORMS = {
    (1, 0): ("LDRB_W", "LDRB_W_REG"), (2, 0): ("LDRH_W", "LDRH_W_REG"), (2, 1): ("LDRSH_X", "LDRSH_X_REG"),
    (4, 0): ("LDR_W", "LDR_W_REG"), (4, 1): ("LDRSW_X", "LDRSW_X_REG"), (8, 0): ("LDR_X", "LDR_X_REG"),
    (8, 1): ("LDR_X", "LDR_X_REG"),
}
STORE_FORMS = {1: ("STRB_W", "STRB_W_REG"), 2: ("STRH_W", "STRH_W_REG"), 4: ("STR_W", "STR_W_REG"), 8: ("STR_X", "STR_X_REG")}
OP_INSTRUCTIONS = {"ADD": "ADD_X", "SUB": "SUB_X", "MUL": "MUL_X", "AND": "AND_X", "OR": "ORR_X", "XOR": "EOR_X"}
OP_CONDITIONS = {
    "EQ": ("EQ", "EQ"), "NE": ("NE", "NE"), "LT": ("LT", "LO"), "LE": ("LE", "LS"), "GT": ("GT", "HI"), "GE": ("GE", "HS"),
}
OP_SHIFTS = {"SHL": "LSLV_X", "SHR": "LSRV_X"}
OP_REAL_INSTRUCTIONS = {"ADD": "FADD_S", "SUB": "FSUB_S", "MUL": "FMUL_S", "DIV": "FDIV_S"}
OP_REAL_CONDITIONS = {"EQ": "EQ", "NE": "NE", "LT": "MI", "LE": "LS", "GT": "GT", "GE": "GE"}
GLOBAL_LABELS = [
    "malformed", "reserve_failed", "read_value", "put_int", "put_uint", "put_bool", "step", "read_done", "wait", "complete",
    "divide", "put_text", "put_char", "read_line", "read_number", "read_malformed",
    "put_real", "put_dreal", "read_real_value", "parse_real", "bn_muladd", "bn_add", "bn_sub", "bn_cmp", "bn_set",
    "bn_shift", "bn_bits", "math_acos", "math_asin", "math_atan", "math_cos", "math_sin", "math_tan", "math_cosh",
    "math_sinh", "math_tanh", "math_exp", "math_log", "math_log10", "math_atan2", "math_ldexp", "math_pow", "math_fmod",
    "math_exp_dd", "math_atan_dd", "math_rem_pio2", "math_k_sin", "math_k_cos", "math_k_tan", "math_frexp", "math_modf",
]
LOCAL_LABEL_COUNT = 96
EMIT_SOURCES = [
    "row", "left", "right", "right_left", "right_right", "param", "value_row",
    "arg0", "arg1", "arg2", "arg3", "arg4", "arg5", "arg6",
    "type_row", "size_left", "size_row", "words_row",
    "key_left", "key_right", "key_owner", "key_a_right", "key_a_row", "key_p_row",
    "clock_row", "clock_left", "clock_loop", "node_parent", "node_left", "node_right", "root_position",
    "input_root_position", "input_bound", "loop_count", "loop_size", "loop_size_less_one", "loop_condition",
    "window_offset", "window_bytes", "reservation", "line_capacity", "root_count",
    "load_param", "store_param", "load_indexed_row", "load_indexed_index", "load_indexed_element",
    "store_indexed_element", "instruction_op", "shift_op", "pair_form", "signed_condition", "unsigned_condition",
    "loop_start", "loop_end", "put_output", "root_irq",
    "binary_lo", "binary_hi", "pair_form_thumb", "signed_condition_thumb", "unsigned_condition_thumb", "element_row",
    "index_element",
] + GLOBAL_LABELS + [
    "copy_next", "copy_end", "key_row", "key_right_left", "key_right_right", "key_mem", "key_init", "span", "count_mem",
    "count_shift", "load_indexed_scalar", "store_indexed_scalar", "load_indexed_init", "scalar_row", "init_element",
    "iter_stride", "iter_size", "iter_start", "loop_inner", "size_right", "put_param", "key_arg0", "key_arg1",
    "real_in", "real_out", "real_op", "real_neg", "real_cmp", "real_condition", "real_from_int", "real_to_int", "real_bytes",
    "imag_row", "key_string_init", "key_string_value", "key_string_mem",
] + [f"local{index}" for index in range(LOCAL_LABEL_COUNT)]
EMIT_PREDICATES = [
    "always", "flag", "has_arg1", "has_arg2", "has_arg3", "has_arg4", "has_arg5", "has_arg6", "right_loads",
    "counted", "uncounted", "bounded", "keys_differ", "mul", "not_mul", "compare_equal", "compare_direct", "compare_swapped",
    "shift_left", "shift_right", "nested_counted", "empty", "iter_divides", "iter_whole", "iter_wraps", "iter_offset",
    "iter_plain", "iter_derived", "iter_derived_whole", "compare_negated",
    "writes_string", "writes_char", "writes_number", "reads_string", "reads_scalar", "reads_char", "reads_number",
    "reads_boolean", "left_widens", "right_widens", "reads_real", "reads_integer", "right_left_widens", "right_right_widens",
    "writes_complex", "reads_complex", "index_real", "index_integer",
]
MICRO_KINDS = ["EMIT", "LI", "LOAD", "STORE", "OPERAND", "ADDRESS", "PLACE", "LOAD_AT", "STORE_AT"]
TARGET_KINDS = ["NONE", "LABEL", "TABLE", "WINDOW", "SIG", "MEM", "CLK", "IN", "OUT", "MALFORMED_TEXT", "RESERVE_TEXT", "TAIL", "STACK"]
SOURCE_BASE = 1 << 20
CC = CONDITIONS
CODE_COLUMNS = [
    "form", "op0", "op1", "op2", "op3", "target_section", "target_offset", "data_offsets", "data_alignments", "data",
]
EMIT_TEXT = "presence input malformed at step memory reservation failed"
UNIT_PHASES = [
    "PROLOGUE", "RESERVE", "WINDOW", "SEED_MEMORY", "SEED_STRING", "JUMP_STEP", "BOOT", "WAIT", "DISPATCH", "WAIT_TAIL", "RESERVE_FAILED", "READ_VALUE",
    "STEP", "READ_LINE", "VALUE_INPUT", "READ_TAIL", "ORDER", "DELAY", "LAG", "OUTPUT_HEAD", "OUTPUT", "OUTPUT_TAIL", "FINISH",
    "PUT_TEXT", "READ_INPUT", "READ_NUMBER", "REAL_RUNTIME", "REAL_PARSE",
]
VIRT_SUFFIX = "_VIRT"
VIRT_BASE = 0x40000000
VIRT_TEXT_OFFSET = 120
BOOT_ID = 1024
SPECIAL_ID = 1020
GICC_PAGE = 0x0801
GICC_IAR = 0x0C
GICC_EOIR = 0x10
UART_PAGE = 0x0900


def step(kind, when, form=0, a0=0, a1=0, a2=0, a3=0, target=("NONE", 0)):
    return (kind, when, form, a0, a1, a2, a3, target[0], target[1])


def emit(form, a0=0, a1=0, a2=0, a3=0, to=("NONE", 0), when="always"):
    return step("EMIT", when, form, a0, a1, a2, a3, to)


def li(register, value, when="always"):
    return step("LI", when, 0, register, value)


def ld(register, target, type_source, when="always"):
    return step("LOAD", when, 0, register, type_source, target=target)


def st(register, target, type_source, when="always"):
    return step("STORE", when, 0, register, type_source, target=target)


def operand(register, row, when="always"):
    return step("OPERAND", when, 0, register, row)


def address(register, key, when="always"):
    return step("ADDRESS", when, 0, register, key)


def place(label, when="always"):
    return step("PLACE", when, 0, label)


def label(name):
    return ("LABEL", name)


def copy_words(source_key, destination_key, words, loop_label, when="always"):
    return [
        address(12, source_key, when), address(13, destination_key, when), li(15, words, when), place(loop_label, when),
        emit("LDR_X_POST", 9, 12, 8, when=when), emit("STR_X_POST", 9, 13, 8, when=when),
        emit("SUBS_X_IMM", 15, 15, 1, when=when), emit("B_COND", a3=CC["NE"], to=label(loop_label), when=when),
    ]


def gated(body, stores=True):
    return (
        [ld(9, ("CLK", "clock_row"), UINTEGER_TYPE, "flag"), emit("CBZ_W", 9, to=label("local0"), when="flag")]
        + body + ([st(9, ("SIG", "row"), "type_row")] if stores else []) + [place("local0", "flag")]
    )


def string_length(register, pointer, when="always"):
    return [emit("SUB_X_IMM", register, pointer, 8, when=when), emit("LDR_X", register, register, 0, when=when)]


def copy_string(source, destination, loop_label):
    return [
        *string_length(11, source), emit("STR_X", 11, destination, 0), emit("ADD_X_IMM", destination, destination, 8),
        emit("ADD_X_IMM", 11, 11, 1), emit("MOVZ_X", 15), place(loop_label), emit("LDRB_W_REG", 16, source, 15),
        emit("STRB_W_REG", 16, destination, 15), emit("ADD_X_IMM", 15, 15, 1), emit("SUBS_X", XZR, 15, 11),
        emit("B_COND", a3=CC["LO"], to=label(loop_label)),
    ]


def widen(register, when):
    return [emit("FMOV_S_W", 16, register, when=when), emit("FCVT_D_S", 16, 16, when=when), emit("FMOV_X_D", register, 16, when=when)]


def generic(*tail):
    return [operand(9, "left"), *widen(9, "left_widens"), operand(10, "right", "right_loads"), *widen(10, "right_widens"), *tail]


def fused_multiply_add(width):
    return [
        operand(9, "left"), operand(10, "right_left"), operand(11, "right_right"), emit("real_in", 16, 9),
        emit("real_in", 17, 10), emit("real_in", 18, 11), emit(f"FMADD_{width}", 16, 17, 18, 16), emit("real_out", 9, 16),
    ]


def copy_sign(sign_halfword):
    return generic(
        emit("MOVZ_X", 11, 0, 0x8000, sign_halfword), emit("AND_X", 10, 10, 11), emit("ORN_X", 11, XZR, 11),
        emit("AND_X", 9, 9, 11), emit("ORR_X", 9, 9, 10),
    )


def complex_modulus_template(narrow):
    widen_operands = [
        step for register in (9, 10)
        for step in (emit("FMOV_S_W", 16, register), emit("FCVT_D_S", 16, 16), emit("FMOV_X_D", register, 16))
    ] if narrow else []
    narrow_result = [emit("FMOV_D_X", 16, 9), emit("FCVT_S_D", 16, 16), emit("FMOV_W_S", 9, 16)] if narrow else []
    return generic(
        *widen_operands,
        emit("MOVZ_X", 12, 0, 1), emit("LSLV_X", 9, 9, 12), emit("LSRV_X", 9, 9, 12), emit("LSLV_X", 10, 10, 12),
        emit("LSRV_X", 10, 10, 12), emit("MOVZ_X", 13, 0, 0x7FF0, 3), emit("SUBS_X", XZR, 9, 13),
        emit("B_COND", a3=CC["EQ"], to=label("local1")), emit("SUBS_X", XZR, 10, 13),
        emit("B_COND", a3=CC["EQ"], to=label("local1")), emit("SUBS_X", XZR, 9, 10), emit("CSEL_X", 11, 9, 10, CC["HI"]),
        emit("MOVZ_X", 14, 0, 52), emit("LSRV_X", 11, 11, 14), emit("SUBS_W_IMM", XZR, 11, 0),
        emit("CSINC_W", 11, 11, XZR, CC["NE"]), emit("MOVZ_X", 15, 0, 2047), emit("SUB_X", 15, 15, 11),
        emit("LSLV_X", 15, 15, 14), emit("LSLV_X", 11, 11, 14), emit("FMOV_D_X", 16, 9), emit("FMOV_D_X", 17, 10),
        emit("FMOV_D_X", 18, 15), emit("FMUL_D", 16, 16, 18), emit("FMUL_D", 17, 17, 18), emit("FMUL_D", 19, 17, 17),
        emit("FMADD_D", 19, 16, 16, 19), emit("FSQRT_D", 20, 19), emit("FMOV_X_D", 12, 20),
        emit("CBZ_X", 12, to=label("local3")), emit("FNEG_D", 21, 20), emit("FMADD_D", 21, 21, 20, 19),
        emit("FDIV_D", 21, 21, 20), emit("MOVZ_X", 12, 0, 0x3FE0, 3), emit("FMOV_D_X", 22, 12),
        emit("FMADD_D", 20, 21, 22, 20), emit("FMUL_D", 20, 20, 22), emit("FMOV_D_X", 18, 11), emit("FMUL_D", 20, 20, 18),
        emit("FMOV_X_D", 9, 20), emit("B", to=label("local4")), place("local1"), emit("MOVZ_X", 9, 0, 0x7FF0, 3),
        emit("B", to=label("local4")), place("local3"), emit("MOVZ_X", 9), place("local4"), *narrow_result,
    )


MATH_INSTRUCTIONS = {"sqrt": "FSQRT_D", "ceil": "FRINTP_D", "fabs": "FABS_D", "floor": "FRINTM_D", "modf'i": "FRINTZ_D"}
MATH_PARTS = {"frexp'm": ("frexp", 0), "frexp'e": ("frexp", 1), "modf'f": ("modf", 0)}
MATH_UNARY = ["acos", "asin", "atan", "cos", "sin", "tan", "cosh", "sinh", "tanh", "exp", "log", "log10", "sqrt", "ceil",
              "fabs", "floor", "frexp", "modf", "frexp'm", "frexp'e", "modf'f", "modf'i"]
MATH_BINARY = ["atan2", "ldexp", "pow", "fmod"]


def math_template(function):
    if function in MATH_INSTRUCTIONS:
        return generic(emit("FMOV_D_X", 16, 9), emit(MATH_INSTRUCTIONS[function], 16, 16), emit("FMOV_X_D", 9, 16))
    if function in ("frexp", "modf"):
        return generic()
    routine, result = MATH_PARTS.get(function, (function, 0))
    if function == "ldexp":
        second = [emit("SBFM_X", 1, 10, 0, 31)]
    else:
        second = [emit("ORR_X", 1, XZR, 10)] if function in MATH_BINARY else []
    return generic(emit("ORR_X", 0, XZR, 9), *second, emit("BL", to=label("math_" + routine)), emit("ORR_X", 9, XZR, result))


def complex_argument_template():
    return generic(
        *[step for register in (9, 10)
          for step in (emit("FMOV_S_W", 16, register), emit("FCVT_D_S", 16, 16), emit("FMOV_X_D", register, 16))],
        emit("ORR_X", 0, XZR, 9), emit("ORR_X", 1, XZR, 10), emit("BL", to=label("math_atan2")), emit("FMOV_D_X", 16, 0),
        emit("FCVT_S_D", 16, 16), emit("FMOV_W_S", 9, 16),
    )


def loop_bound(when):
    return [
        operand(11, "loop_count", when), li(12, "loop_size_less_one", when), emit("SUBS_X", XZR, 11, 12, when=when),
        emit("CSEL_X", 11, 11, 12, "loop_condition", when=when), emit("ADD_X_IMM", 11, 11, 1, when=when),
        li(12, "loop_inner", "nested_counted"), emit("MUL_X", 11, 11, 12, when="nested_counted"),
    ]


def system_call(number):
    return [emit("MOVZ_X", 16, 0, number), emit("SVC_80")]


PUT_NUMBER = [
    place("put_int"), emit("SUBS_X_IMM", XZR, 0, 0),
    emit("B_COND", a3=CC["GE"], to=label("put_uint")), emit("MOVZ_W", 10, 0, 45), emit("STRB_W_POST", 10, 20, 1),
    emit("SUB_X", 0, XZR, 0), place("put_uint"), emit("ORR_X", 9, XZR, 0), emit("SUB_X_IMM", SP, SP, 32),
    emit("ADD_X_IMM", 11, SP, 0), emit("ADD_X_IMM", 15, SP, 0), emit("MOVZ_X", 12, 0, 10), place("local0"),
    emit("UDIV_X", 13, 9, 12), emit("MSUB_X", 14, 13, 12, 9), emit("ADD_W_IMM", 14, 14, 48),
    emit("STRB_W_POST", 14, 11, 1), emit("ORR_X", 9, XZR, 13), emit("CBNZ_X", 9, to=label("local0")), place("local1"),
    emit("LDRB_W_PRE", 14, 11, -1), emit("STRB_W_POST", 14, 20, 1), emit("SUBS_X", XZR, 11, 15),
    emit("B_COND", a3=CC["NE"], to=label("local1")), emit("ADD_X_IMM", SP, SP, 32), emit("RET"),
]


READ_REAL_BYTES = 1024
READ_STRING_CAPACITY = 1048575
STRING_BUFFER_BYTES = 8 + READ_STRING_CAPACITY + 1
PARSE_LIMBS = 120
PRINT_LIMBS = 40
PRINT_FRAME = 896
PARSE_FRAME = 1216
PRINT_R, PRINT_S, PRINT_MP, PRINT_MM, PRINT_T, PRINT_DIGITS = 64, 224, 384, 544, 704, 864
PARSE_N, PARSE_M = 256, 736
PARSE_NEGATIVE, PARSE_PRECISION, PARSE_T_MAX, PARSE_BIAS, PARSE_MAX_EXPONENT, PARSE_SIGN_SHIFT = 8, 16, 24, 32, 40, 48
PARSE_DROPPED, PARSE_STICKY, PARSE_ADJUST, PARSE_FRACTION, PARSE_EXPONENT, PARSE_EXPONENT_NEGATIVE, PARSE_T, PARSE_PART = (
    56, 64, 72, 80, 88, 96, 104, 120)
REAL_LABELS = {name: f"local{index}" for index, name in enumerate([
    "muladd_loop", "add_loop", "sub_loop", "cmp_loop", "cmp_done", "set_loop", "shift_next", "shift_loop", "shift_done",
    "bits_loop", "bits_found", "bits_zero", "put_float", "finite", "infinite", "positive_infinite", "unsigned", "nonzero",
    "scale_up", "scale_down", "digit", "digit_subtract", "digit_decide", "digit_last", "digit_increment", "digit_store",
    "point_left", "zeros", "zeros_done", "point_right", "plain_loop", "plain_dot_done", "plain_zero", "plain_put",
    "scientific", "scientific_loop", "exponent", "exponent_positive", "exponent_digits", "print_done",
    "parse_double", "parse_parameters", "parse_word", "parse_nan", "parse_number", "part_start", "part_digit", "significant",
    "kept", "dropped_zero", "part_end", "exponent_check", "exponent_sign", "exponent_loop", "exponent_end",
    "parse_end", "power_loop", "no_flush", "no_sticky", "scale_step", "power_step", "scale_done", "shift_negative",
    "shift_more", "round_loop", "round_next", "rounds_done", "wide_done", "half_done", "carry_done", "normal", "zero", "sign",
    "ok", "malformed", "parse_return", "value_scan", "value_end", "exponent_value_positive", "even_scale_up", "leading",
    "kept_fraction", "dropped_fraction", "fraction_check",
])}


def put_bytes(text):
    return [step_row for byte in text.encode() for step_row in (emit("MOVZ_W", 9, 0, byte), emit("STRB_W_POST", 9, 20, 1))]


PUT_CHAR = [
    place("put_char"), emit("SUBS_X_IMM", XZR, 0, 128), emit("B_COND", a3=CC["HS"], to=label("local4")),
    emit("STRB_W_POST", 0, 20, 1), emit("RET"), place("local4"), emit("MOVZ_X", 10, 0, 6), emit("LSRV_X", 11, 0, 10),
    emit("MOVZ_X", 12, 0, 0xC0), emit("ORR_X", 11, 11, 12), emit("STRB_W_POST", 11, 20, 1), emit("MOVZ_X", 12, 0, 63),
    emit("AND_X", 11, 0, 12), emit("MOVZ_X", 12, 0, 0x80), emit("ORR_X", 11, 11, 12), emit("STRB_W_POST", 11, 20, 1),
    emit("RET"),
]

L = REAL_LABELS
REAL_RUNTIME = [
    place("bn_muladd"), emit("MOVZ_X", 4), emit("MOVZ_X", 8, 0, 32), place(L["muladd_loop"]), emit("LDR_W_REG", 5, 0, 4),
    emit("MUL_X", 5, 5, 1), emit("ADD_X", 5, 5, 2), emit("STR_W_REG", 5, 0, 4), emit("LSRV_X", 2, 5, 8),
    emit("ADD_X_IMM", 4, 4, 1), emit("SUBS_X", XZR, 4, 15), emit("B_COND", a3=CC["LO"], to=label(L["muladd_loop"])), emit("RET"),
    place("bn_add"), emit("MOVZ_X", 4), emit("MOVZ_X", 5), emit("MOVZ_X", 8, 0, 32), place(L["add_loop"]),
    emit("LDR_W_REG", 6, 1, 4), emit("LDR_W_REG", 7, 2, 4), emit("ADD_X", 6, 6, 7), emit("ADD_X", 6, 6, 5),
    emit("STR_W_REG", 6, 0, 4), emit("LSRV_X", 5, 6, 8), emit("ADD_X_IMM", 4, 4, 1), emit("SUBS_X", XZR, 4, 15),
    emit("B_COND", a3=CC["LO"], to=label(L["add_loop"])), emit("RET"),
    place("bn_sub"), emit("MOVZ_X", 4), emit("MOVZ_X", 5), emit("MOVZ_X", 8, 0, 63), place(L["sub_loop"]),
    emit("LDR_W_REG", 6, 0, 4), emit("LDR_W_REG", 7, 1, 4), emit("SUB_X", 6, 6, 7), emit("SUB_X", 6, 6, 5),
    emit("STR_W_REG", 6, 0, 4), emit("LSRV_X", 5, 6, 8), emit("ADD_X_IMM", 4, 4, 1), emit("SUBS_X", XZR, 4, 15),
    emit("B_COND", a3=CC["LO"], to=label(L["sub_loop"])), emit("RET"),
    place("bn_cmp"), emit("SUB_X_IMM", 4, 15, 1), place(L["cmp_loop"]), emit("LDR_W_REG", 6, 0, 4), emit("LDR_W_REG", 7, 1, 4),
    emit("SUBS_X", XZR, 6, 7), emit("B_COND", a3=CC["NE"], to=label(L["cmp_done"])), emit("CBZ_X", 4, to=label(L["cmp_done"])),
    emit("SUB_X_IMM", 4, 4, 1), emit("B", to=label(L["cmp_loop"])), place(L["cmp_done"]), emit("RET"),
    place("bn_set"), emit("MOVZ_X", 4), place(L["set_loop"]), emit("STR_W_REG", XZR, 0, 4), emit("ADD_X_IMM", 4, 4, 1),
    emit("SUBS_X", XZR, 4, 15), emit("B_COND", a3=CC["LO"], to=label(L["set_loop"])), emit("MOVZ_X", 5, 0, 5),
    emit("LSRV_X", 6, 2, 5), emit("MOVZ_X", 5, 0, 31), emit("AND_X", 7, 2, 5), emit("LSLV_X", 16, 1, 7),
    emit("STR_W_REG", 16, 0, 6), emit("MOVZ_X", 5, 0, 32), emit("LSRV_X", 16, 16, 5), emit("ADD_X_IMM", 6, 6, 1),
    emit("STR_W_REG", 16, 0, 6), emit("MOVZ_X", 5, 0, 1), emit("LSRV_X", 16, 1, 5), emit("MOVZ_X", 5, 0, 63),
    emit("SUB_X", 5, 5, 7), emit("LSRV_X", 16, 16, 5), emit("ADD_X_IMM", 6, 6, 1), emit("STR_W_REG", 16, 0, 6), emit("RET"),
    place("bn_shift"), place(L["shift_next"]), emit("CBZ_X", 1, to=label(L["shift_done"])), emit("MOVZ_X", 5, 0, 31),
    emit("SUBS_X", XZR, 1, 5), emit("CSEL_X", 6, 1, 5, CC["LO"]), emit("SUB_X", 1, 1, 6), emit("MOVZ_X", 7, 0, 1),
    emit("LSLV_X", 7, 7, 6), emit("MOVZ_X", 2), emit("MOVZ_X", 4), emit("MOVZ_X", 8, 0, 32), place(L["shift_loop"]),
    emit("LDR_W_REG", 5, 0, 4), emit("MUL_X", 5, 5, 7), emit("ADD_X", 5, 5, 2), emit("STR_W_REG", 5, 0, 4),
    emit("LSRV_X", 2, 5, 8), emit("ADD_X_IMM", 4, 4, 1), emit("SUBS_X", XZR, 4, 15),
    emit("B_COND", a3=CC["LO"], to=label(L["shift_loop"])), emit("B", to=label(L["shift_next"])), place(L["shift_done"]),
    emit("RET"),
    place("bn_bits"), emit("SUB_X_IMM", 4, 15, 1), place(L["bits_loop"]), emit("LDR_W_REG", 5, 0, 4),
    emit("CBNZ_X", 5, to=label(L["bits_found"])), emit("CBZ_X", 4, to=label(L["bits_zero"])), emit("SUB_X_IMM", 4, 4, 1),
    emit("B", to=label(L["bits_loop"])), place(L["bits_found"]), emit("CLZ_X", 5, 5), emit("MOVZ_X", 6, 0, 64),
    emit("SUB_X", 5, 6, 5), emit("MOVZ_X", 6, 0, 5), emit("LSLV_X", 4, 4, 6), emit("ADD_X", 4, 4, 5), emit("RET"),
    place(L["bits_zero"]), emit("MOVZ_X", 4), emit("RET"),

    place("put_real"), emit("MOVZ_X", 1, 0, 23), emit("MOVZ_X", 2, 0, 255), emit("MOVZ_X", 3, 0, 127), emit("MOVZ_X", 4, 0, 31),
    emit("B", to=label(L["put_float"])),
    place("put_dreal"), emit("MOVZ_X", 1, 0, 52), emit("MOVZ_X", 2, 0, 2047), emit("MOVZ_X", 3, 0, 1023), emit("MOVZ_X", 4, 0, 63),
    place(L["put_float"]), emit("SUB_X_IMM", SP, SP, PRINT_FRAME), emit("STR_X", 30, SP, 0), emit("MOVZ_X", 15, 0, PRINT_LIMBS),
    emit("LSRV_X", 5, 0, 4), emit("LSLV_X", 6, 5, 4), emit("SUB_X", 0, 0, 6), emit("LSRV_X", 6, 0, 1), emit("AND_X", 6, 6, 2),
    emit("MOVZ_X", 7, 0, 1), emit("LSLV_X", 7, 7, 1), emit("SUB_X_IMM", 8, 7, 1), emit("AND_X", 9, 0, 8),
    emit("SUBS_X", XZR, 6, 2), emit("B_COND", a3=CC["NE"], to=label(L["finite"])),
    emit("CBZ_X", 9, to=label(L["infinite"])), *put_bytes("nan"), emit("B", to=label(L["print_done"])),
    place(L["infinite"]), emit("CBZ_X", 5, to=label(L["positive_infinite"])), *put_bytes("-"), place(L["positive_infinite"]),
    *put_bytes("inf"), emit("B", to=label(L["print_done"])),
    place(L["finite"]), emit("CBZ_X", 5, to=label(L["unsigned"])), emit("ORR_X", 16, XZR, 9), *put_bytes("-"),
    emit("ORR_X", 9, XZR, 16), place(L["unsigned"]), emit("ORR_X", 16, 6, 9), emit("CBNZ_X", 16, to=label(L["nonzero"])),
    *put_bytes("0.0"), emit("B", to=label(L["print_done"])),
    place(L["nonzero"]), emit("SUBS_X_IMM", XZR, 6, 0), emit("MOVZ_X", 16, 0, 1), emit("CSEL_X", 10, 6, 16, CC["NE"]),
    emit("ORR_X", 16, 9, 7), emit("CSEL_X", 9, 16, 9, CC["NE"]), emit("SUB_X", 10, 10, 3), emit("SUB_X", 10, 10, 1),
    emit("SUBS_X_IMM", XZR, 6, 1), emit("CSINC_W", 11, XZR, XZR, CC["HI"] ^ 1), emit("SUBS_X", XZR, 9, 7),
    emit("CSINC_W", 16, XZR, XZR, CC["EQ"] ^ 1), emit("AND_X", 11, 11, 16), emit("MOVZ_X", 16, 0, 1), emit("AND_X", 12, 9, 16),
    emit("EOR_X_ONE", 12, 12), emit("SUBS_X_IMM", XZR, 10, 0), emit("CSEL_X", 13, 10, XZR, CC["GT"]), emit("SUB_X", 16, XZR, 10),
    emit("CSEL_X", 14, 16, XZR, CC["LT"]),
    emit("ADD_X_IMM", 0, SP, PRINT_R), emit("ORR_X", 1, XZR, 9), emit("ADD_X", 2, 13, 11), emit("ADD_X_IMM", 2, 2, 1),
    emit("BL", to=label("bn_set")),
    emit("ADD_X_IMM", 0, SP, PRINT_S), emit("MOVZ_X", 1, 0, 1), emit("ADD_X", 2, 14, 11), emit("ADD_X_IMM", 2, 2, 1),
    emit("BL", to=label("bn_set")),
    emit("ADD_X_IMM", 0, SP, PRINT_MP), emit("MOVZ_X", 1, 0, 1), emit("ADD_X", 2, 13, 11), emit("BL", to=label("bn_set")),
    emit("ADD_X_IMM", 0, SP, PRINT_MM), emit("MOVZ_X", 1, 0, 1), emit("ADD_X_IMM", 2, 13, 0), emit("BL", to=label("bn_set")),
    emit("MOVZ_X", 13), emit("MOVZ_X", 14),
    place(L["scale_up"]), emit("ADD_X_IMM", 0, SP, PRINT_T), emit("ADD_X_IMM", 1, SP, PRINT_R), emit("ADD_X_IMM", 2, SP, PRINT_MP),
    emit("BL", to=label("bn_add")), emit("ADD_X_IMM", 0, SP, PRINT_T), emit("ADD_X_IMM", 1, SP, PRINT_S),
    emit("BL", to=label("bn_cmp")), emit("CSINC_W", 5, XZR, XZR, CC["HS"] ^ 1), emit("CSINC_W", 6, XZR, XZR, CC["HI"] ^ 1),
    emit("SUBS_X_IMM", XZR, 12, 0), emit("CSEL_X", 5, 5, 6, CC["NE"]), emit("CBZ_X", 5, to=label(L["scale_down"])),
    emit("ADD_X_IMM", 0, SP, PRINT_S), emit("MOVZ_X", 1, 0, 10), emit("MOVZ_X", 2), emit("BL", to=label("bn_muladd")),
    emit("ADD_X_IMM", 13, 13, 1), emit("B", to=label(L["scale_up"])),
    place(L["scale_down"]), emit("ADD_X_IMM", 0, SP, PRINT_T), emit("ADD_X_IMM", 1, SP, PRINT_R),
    emit("ADD_X_IMM", 2, SP, PRINT_MP), emit("BL", to=label("bn_add")), emit("ADD_X_IMM", 0, SP, PRINT_T), emit("MOVZ_X", 1, 0, 10),
    emit("MOVZ_X", 2), emit("BL", to=label("bn_muladd")), emit("ADD_X_IMM", 0, SP, PRINT_T), emit("ADD_X_IMM", 1, SP, PRINT_S),
    emit("BL", to=label("bn_cmp")), emit("CSINC_W", 5, XZR, XZR, CC["LO"] ^ 1), emit("CSINC_W", 6, XZR, XZR, CC["LS"] ^ 1),
    emit("SUBS_X_IMM", XZR, 12, 0), emit("CSEL_X", 5, 5, 6, CC["NE"]), emit("CBZ_X", 5, to=label(L["digit"])),
    *[step_row for offset in (PRINT_R, PRINT_MP, PRINT_MM) for step_row in (
        emit("ADD_X_IMM", 0, SP, offset), emit("MOVZ_X", 1, 0, 10), emit("MOVZ_X", 2), emit("BL", to=label("bn_muladd")))],
    emit("SUB_X_IMM", 13, 13, 1), emit("B", to=label(L["scale_down"])),
    place(L["digit"]),
    *[step_row for offset in (PRINT_R, PRINT_MP, PRINT_MM) for step_row in (
        emit("ADD_X_IMM", 0, SP, offset), emit("MOVZ_X", 1, 0, 10), emit("MOVZ_X", 2), emit("BL", to=label("bn_muladd")))],
    emit("MOVZ_X", 10),
    place(L["digit_subtract"]), emit("ADD_X_IMM", 0, SP, PRINT_R), emit("ADD_X_IMM", 1, SP, PRINT_S), emit("BL", to=label("bn_cmp")),
    emit("B_COND", a3=CC["LO"], to=label(L["digit_decide"])), emit("ADD_X_IMM", 0, SP, PRINT_R), emit("ADD_X_IMM", 1, SP, PRINT_S),
    emit("BL", to=label("bn_sub")), emit("ADD_X_IMM", 10, 10, 1), emit("B", to=label(L["digit_subtract"])),
    place(L["digit_decide"]), emit("ADD_X_IMM", 0, SP, PRINT_R), emit("ADD_X_IMM", 1, SP, PRINT_MM), emit("BL", to=label("bn_cmp")),
    emit("CSINC_W", 5, XZR, XZR, CC["LS"] ^ 1), emit("CSINC_W", 6, XZR, XZR, CC["LO"] ^ 1), emit("SUBS_X_IMM", XZR, 12, 0),
    emit("CSEL_X", 11, 5, 6, CC["NE"]),
    emit("ADD_X_IMM", 0, SP, PRINT_T), emit("ADD_X_IMM", 1, SP, PRINT_R), emit("ADD_X_IMM", 2, SP, PRINT_MP),
    emit("BL", to=label("bn_add")), emit("ADD_X_IMM", 0, SP, PRINT_T), emit("ADD_X_IMM", 1, SP, PRINT_S),
    emit("BL", to=label("bn_cmp")), emit("CSINC_W", 5, XZR, XZR, CC["HS"] ^ 1), emit("CSINC_W", 6, XZR, XZR, CC["HI"] ^ 1),
    emit("SUBS_X_IMM", XZR, 12, 0), emit("CSEL_X", 9, 5, 6, CC["NE"]), emit("ORR_X", 5, 11, 9),
    emit("CBNZ_X", 5, to=label(L["digit_last"])), emit("ADD_X_IMM", 16, SP, PRINT_DIGITS), emit("ADD_W_IMM", 5, 10, 48),
    emit("STRB_W_REG", 5, 16, 14), emit("ADD_X_IMM", 14, 14, 1), emit("B", to=label(L["digit"])),
    place(L["digit_last"]), emit("CBZ_X", 9, to=label(L["digit_store"])), emit("CBZ_X", 11, to=label(L["digit_increment"])),
    emit("ADD_X_IMM", 0, SP, PRINT_T), emit("ADD_X_IMM", 1, SP, PRINT_R), emit("ADD_X_IMM", 2, SP, PRINT_R),
    emit("BL", to=label("bn_add")), emit("ADD_X_IMM", 0, SP, PRINT_T), emit("ADD_X_IMM", 1, SP, PRINT_S),
    emit("BL", to=label("bn_cmp")), emit("B_COND", a3=CC["LO"], to=label(L["digit_store"])),
    emit("B_COND", a3=CC["HI"], to=label(L["digit_increment"])), emit("MOVZ_X", 16, 0, 1), emit("AND_X", 16, 10, 16),
    emit("CBZ_X", 16, to=label(L["digit_store"])), place(L["digit_increment"]), emit("ADD_X_IMM", 10, 10, 1),
    place(L["digit_store"]), emit("ADD_X_IMM", 16, SP, PRINT_DIGITS), emit("ADD_W_IMM", 5, 10, 48),
    emit("STRB_W_REG", 5, 16, 14), emit("ADD_X_IMM", 14, 14, 1),
    emit("ADD_X_IMM", 8, SP, PRINT_DIGITS), emit("ADD_X_IMM", 5, 13, 3), emit("SUBS_X_IMM", XZR, 5, 20),
    emit("B_COND", a3=CC["HS"], to=label(L["scientific"])), emit("SUBS_X_IMM", XZR, 13, 0),
    emit("B_COND", a3=CC["GT"], to=label(L["point_right"])), *put_bytes("0."), emit("SUB_X", 6, XZR, 13),
    place(L["zeros"]), emit("CBZ_X", 6, to=label(L["zeros_done"])), *put_bytes("0"), emit("SUB_X_IMM", 6, 6, 1),
    emit("B", to=label(L["zeros"])), place(L["zeros_done"]), emit("MOVZ_X", 6), place(L["point_left"]),
    emit("LDRB_W_REG", 5, 8, 6), emit("STRB_W_POST", 5, 20, 1), emit("ADD_X_IMM", 6, 6, 1), emit("SUBS_X", XZR, 6, 14),
    emit("B_COND", a3=CC["LO"], to=label(L["point_left"])), emit("B", to=label(L["print_done"])),
    place(L["point_right"]), emit("MOVZ_X", 6), emit("SUBS_X", XZR, 14, 13), emit("CSEL_X", 7, 14, 13, CC["HI"]),
    place(L["plain_loop"]), emit("SUBS_X", XZR, 6, 13), emit("B_COND", a3=CC["NE"], to=label(L["plain_dot_done"])),
    *put_bytes("."), place(L["plain_dot_done"]), emit("SUBS_X", XZR, 6, 14), emit("B_COND", a3=CC["HS"], to=label(L["plain_zero"])),
    emit("LDRB_W_REG", 5, 8, 6), emit("B", to=label(L["plain_put"])), place(L["plain_zero"]), emit("MOVZ_W", 5, 0, 48),
    place(L["plain_put"]), emit("STRB_W_POST", 5, 20, 1), emit("ADD_X_IMM", 6, 6, 1), emit("SUBS_X", XZR, 6, 7),
    emit("B_COND", a3=CC["LO"], to=label(L["plain_loop"])), emit("SUBS_X", XZR, 13, 14),
    emit("B_COND", a3=CC["LO"], to=label(L["print_done"])), *put_bytes(".0"), emit("B", to=label(L["print_done"])),
    place(L["scientific"]), emit("LDRB_W", 5, 8, 0), emit("STRB_W_POST", 5, 20, 1), emit("SUBS_X_IMM", XZR, 14, 1),
    emit("B_COND", a3=CC["LS"], to=label(L["exponent"])), *put_bytes("."), emit("MOVZ_X", 6, 0, 1), place(L["scientific_loop"]),
    emit("LDRB_W_REG", 5, 8, 6), emit("STRB_W_POST", 5, 20, 1), emit("ADD_X_IMM", 6, 6, 1), emit("SUBS_X", XZR, 6, 14),
    emit("B_COND", a3=CC["LO"], to=label(L["scientific_loop"])),
    place(L["exponent"]), *put_bytes("e"), emit("SUB_X_IMM", 0, 13, 1), emit("SUBS_X_IMM", XZR, 0, 0),
    emit("B_COND", a3=CC["GE"], to=label(L["exponent_positive"])), *put_bytes("-"), emit("SUB_X", 0, XZR, 0),
    emit("B", to=label(L["exponent_digits"])), place(L["exponent_positive"]), *put_bytes("+"), place(L["exponent_digits"]),
    emit("SUBS_X_IMM", XZR, 0, 10), emit("B_COND", a3=CC["HS"], to=label(L["exponent_value_positive"])), *put_bytes("0"),
    place(L["exponent_value_positive"]), emit("BL", to=label("put_uint")),
    place(L["print_done"]), emit("LDR_X", 30, SP, 0), emit("ADD_X_IMM", SP, SP, PRINT_FRAME), emit("RET"),

]
MATH_X_POOL = list(range(16))
MATH_D_POOL = list(range(32))
MATH_SCRATCH = 17
MATH_FLOAT_CONDITIONS = {"lt": 4, "le": 9, "gt": 12, "ge": 10, "eq": 0, "ne": 1}
MATH_SIGNED_CONDITIONS = {"lt": 11, "le": 13, "gt": 12, "ge": 10, "eq": 0, "ne": 1}
MATH_UNSIGNED_CONDITIONS = {"lt": 3, "le": 9, "gt": 8, "ge": 2, "eq": 0, "ne": 1}
MATH_SWAPPED = {"lt": "gt", "le": "ge", "gt": "lt", "ge": "le", "eq": "eq", "ne": "ne"}
MATH_FLOAT_FORMS = {"add": "FADD_D", "sub": "FSUB_D", "mul": "FMUL_D", "div": "FDIV_D"}
MATH_FLOAT_UNARY = {"neg": "FNEG_D", "sqrt": "FSQRT_D", "abs": "FABS_D", "floor": "FRINTM_D", "ceil": "FRINTP_D"}
MATH_INTEGER_FORMS = {"div": "SDIV_X", "add": "ADD_X", "sub": "SUB_X", "and": "AND_X", "or": "ORR_X", "xor": "EOR_X", "mul": "MUL_X",
                      "shl": "LSLV_X", "lsr": "LSRV_X", "asr": "ASRV_X"}
MATH_WRAPS = {"add", "sub", "mul", "shl", "not"}


class MathCondition:
    def __init__(self, kind, test, left, right):
        self.kind, self.test, self.left, self.right = kind, test, left, right


class MathValue:
    __hash__ = object.__hash__

    def __init__(self, routine, index, kind):
        self.routine, self.index, self.kind = routine, index, kind

    def __add__(self, other):
        return self.routine.binary("add", self, other)

    def __radd__(self, other):
        return self.routine.binary("add", other, self)

    def __sub__(self, other):
        return self.routine.binary("sub", self, other)

    def __rsub__(self, other):
        return self.routine.binary("sub", other, self)

    def __mul__(self, other):
        return self.routine.binary("mul", self, other)

    def __rmul__(self, other):
        return self.routine.binary("mul", other, self)

    def __truediv__(self, other):
        return self.routine.binary("div", self, other)

    def __rtruediv__(self, other):
        return self.routine.binary("div", other, self)

    def __neg__(self):
        return self.routine.unary("neg", self)

    def __and__(self, other):
        return self.routine.binary("and", self, other)

    def __rand__(self, other):
        return self.routine.binary("and", other, self)

    def __or__(self, other):
        return self.routine.binary("or", self, other)

    def __ror__(self, other):
        return self.routine.binary("or", other, self)

    def __xor__(self, other):
        return self.routine.binary("xor", self, other)

    def __invert__(self):
        return self.routine.unary("not", self)

    def __lshift__(self, other):
        return self.routine.binary("shl", self, other)

    def __rshift__(self, other):
        return self.routine.binary("asr" if self.kind == "I" else "lsr", self, other)

    def __lt__(self, other):
        return self.routine.compare("lt", self, other)

    def __le__(self, other):
        return self.routine.compare("le", self, other)

    def __gt__(self, other):
        return self.routine.compare("gt", self, other)

    def __ge__(self, other):
        return self.routine.compare("ge", self, other)

    def __eq__(self, other):
        return self.routine.compare("eq", self, other)

    def __ne__(self, other):
        return self.routine.compare("ne", self, other)

    def set(self, value):
        self.routine.assign(self, value)


class MathArray:
    def __init__(self, routine, slot, length, kind):
        self.routine, self.slot, self.length, self.kind = routine, slot, length, kind

    def __getitem__(self, index):
        return self.routine.load(self, index)

    def __setitem__(self, index, value):
        self.routine.store(self, index, value)


class MathBlock:
    def __init__(self, routine, condition):
        self.routine, self.condition = routine, condition

    def __enter__(self):
        self.end = self.routine.label()
        self.routine.branch(self.condition, self.end, negate=True)
        return self

    def __exit__(self, *exception):
        self.routine.last_if_end = (self.end, len(self.routine.code))
        self.routine.place(self.end)


class MathElse:
    def __init__(self, routine):
        self.routine = routine

    def __enter__(self):
        else_label, position = self.routine.last_if_end
        self.end = self.routine.label()
        self.routine.code.insert(position, ("jump", self.end))
        return self

    def __exit__(self, *exception):
        self.routine.last_if_end = (self.end, len(self.routine.code))
        self.routine.place(self.end)


class MathRoutine:
    def __init__(self, name, parameters):
        self.name = name
        self.code = []
        self.kinds = []
        self.mutable = set()
        self.arrays = []
        self.labels = 0
        self.last_if_end = None
        self.parameters = [self.fresh(kind) for kind in parameters]
        self.code.append(("enter", self.parameters))

    def fresh(self, kind):
        self.kinds.append(kind)
        return MathValue(self, len(self.kinds) - 1, kind)

    def label(self):
        self.labels += 1
        return ("label", self.name, self.labels)

    def place(self, label):
        self.code.append(("place", label))

    def jump(self, label):
        self.code.append(("jump", label))

    def var(self, kind, initial=None):
        value = self.fresh(kind)
        self.mutable.add(value.index)
        if initial is not None:
            self.assign(value, initial)
        return value

    def array(self, length, kind):
        array = MathArray(self, len(self.arrays), length, kind)
        self.arrays.append(length)
        return array

    def constant(self, value, kind):
        if isinstance(value, MathValue):
            assert value.kind == kind, (value.kind, kind)
            return value
        result = self.fresh(kind)
        if kind == "D":
            self.code.append(("const", result, struct.unpack("<Q", struct.pack("<d", float(value)))[0]))
        else:
            self.code.append(("const", result, self.normalize(int(value), kind)))
        return result

    def d(self, value):
        return self.constant(value, "D")

    def bits_constant(self, bits):
        result = self.fresh("D")
        self.code.append(("const", result, bits))
        return result

    def i(self, value):
        return self.constant(value, "I")

    def u(self, value):
        return self.constant(value, "U")

    @staticmethod
    def normalize(value, kind):
        if kind == "I":
            value &= 0xFFFFFFFF
            return value - (1 << 32) if value >= 1 << 31 else value
        if kind == "U":
            return value & 0xFFFFFFFF
        return value

    def kind_of(self, left, right):
        kind = left.kind if isinstance(left, MathValue) else right.kind
        return kind

    def binary(self, operation, left, right):
        kind = self.kind_of(left, right)
        if kind == "D":
            left, right = self.constant(left, "D"), self.constant(right, "D")
            result = self.fresh("D")
            self.code.append(("float", result, MATH_FLOAT_FORMS[operation], left, right))
            return result
        assert operation != "div" or kind == "I"
        if operation in ("shl", "lsr", "asr") and isinstance(right, int):
            assert 0 <= right < 64
            result = self.fresh(kind)
            self.code.append(("shift", result, operation, self.constant(left, kind), right))
            return self.wrap(result, operation)
        if operation in ("add", "sub") and isinstance(right, int) and 0 <= right < 4096:
            result = self.fresh(kind)
            self.code.append(("immediate", result, "ADD_X_IMM" if operation == "add" else "SUB_X_IMM", left, right))
            return self.wrap(result, operation)
        left = self.constant(left, kind)
        if operation not in ("shl", "lsr", "asr"):
            right = self.constant(right, kind)
            assert left.kind == right.kind, (operation, left.kind, right.kind)
        result = self.fresh(kind)
        self.code.append(("integer", result, MATH_INTEGER_FORMS[operation], left, right))
        return self.wrap(result, operation)

    def wrap(self, value, operation):
        if operation not in MATH_WRAPS or value.kind == "L":
            return value
        result = self.fresh(value.kind)
        self.code.append(("extend", result, value))
        return result

    def unary(self, operation, value):
        if value.kind == "D":
            result = self.fresh("D")
            self.code.append(("float_unary", result, MATH_FLOAT_UNARY[operation], value))
            return result
        if operation == "neg":
            return self.binary("sub", 0, value)
        result = self.fresh(value.kind)
        self.code.append(("not", result, value))
        return self.wrap(result, "not")

    def sqrt(self, value):
        return self.unary("sqrt", value)

    def fma(self, left, right, addend):
        left, right, addend = self.constant(left, "D"), self.constant(right, "D"), self.constant(addend, "D")
        result = self.fresh("D")
        self.code.append(("fma", result, left, right, addend))
        return result

    def fabs(self, value):
        return self.unary("abs", value)

    def compare(self, test, left, right):
        kind = self.kind_of(left, right)
        if isinstance(left, MathValue) is False:
            left, right, test = right, left, MATH_SWAPPED[test]
        if kind == "D":
            right = self.constant(right, "D")
        elif isinstance(right, MathValue):
            assert right.kind == left.kind, (left.kind, right.kind)
        else:
            right = self.normalize(right, kind)
        return MathCondition(kind, test, left, right)

    def branch(self, condition, label, negate=False):
        self.code.append(("branch", condition, label, negate))

    def If(self, condition):
        return MathBlock(self, condition)

    def Else(self):
        return MathElse(self)

    def assign(self, target, value):
        assert target.index in self.mutable
        value = self.constant(value, target.kind)
        self.code.append(("move", target, value))

    def convert(self, value, kind):
        if value.kind == kind:
            return value
        if kind == "D":
            result = self.fresh(kind)
            self.code.append(("scvtf", result, value))
            return result
        if value.kind == "D":
            result = self.fresh("L")
            self.code.append(("fcvtzs", result, value))
            return self.convert(result, kind)
        if kind == "L":
            return MathValue(self, value.index, "L")
        result = self.fresh(kind)
        self.code.append(("extend", result, value))
        return result

    def bits(self, value):
        result = self.fresh("L")
        self.code.append(("to_bits", result, value))
        return result

    def from_bits(self, value):
        assert value.kind == "L"
        result = self.fresh("D")
        self.code.append(("from_bits", result, value))
        return result

    def hi(self, value):
        return self.convert(self.binary("asr", self.bits(value), 32), "I")

    def lo(self, value):
        return self.convert(self.bits(value), "U")

    def words(self, high, low):
        high_bits = self.binary("shl", self.convert(high, "L"), 32)
        low_bits = self.convert(self.convert(self.constant(low, "U") if isinstance(low, int) else low, "U"), "L")
        return self.from_bits(high_bits | low_bits)

    def with_hi(self, value, high):
        return self.words(high, self.lo(value))

    def with_lo(self, value, low):
        return self.words(self.hi(value), low)

    def call(self, label, arguments, results):
        arguments = [self.constant(argument, "D") if isinstance(argument, float) else argument for argument in arguments]
        values = [self.fresh(kind) for kind in results]
        self.code.append(("call", label, arguments, values))
        return values[0] if len(values) == 1 else values

    def ret(self, *values):
        values = [self.constant(value, "D") if not isinstance(value, MathValue) and index == 0 else value
                  for index, value in enumerate(values)]
        self.code.append(("ret", values))

    def load(self, array, index):
        result = self.fresh(array.kind)
        self.code.append(("load", result, array, self.constant(index, "L") if isinstance(index, int) else index))
        return result

    def store(self, array, index, value):
        value = self.constant(value, array.kind)
        self.code.append(("store", array, self.constant(index, "L") if isinstance(index, int) else index, value))


def math_uses_defs(instruction):
    kind = instruction[0]
    if kind == "enter":
        return [], list(instruction[1])
    if kind == "const":
        return [], [instruction[1]]
    if kind in ("float", "integer"):
        return [instruction[3], instruction[4]], [instruction[1]]
    if kind == "fma":
        return [instruction[2], instruction[3], instruction[4]], [instruction[1]]
    if kind in ("float_unary", "shift", "immediate"):
        return [instruction[3]], [instruction[1]]
    if kind in ("extend", "not", "scvtf", "fcvtzs", "to_bits", "from_bits"):
        return [instruction[2]], [instruction[1]]
    if kind == "move":
        return [instruction[2]], [instruction[1]]
    if kind == "branch":
        condition = instruction[1]
        return [condition.left] + ([condition.right] if isinstance(condition.right, MathValue) else []), []
    if kind == "call":
        return list(instruction[2]), list(instruction[3])
    if kind == "ret":
        return list(instruction[1]), []
    if kind == "load":
        return [instruction[3]], [instruction[1]]
    if kind == "store":
        return [instruction[2], instruction[3]], []
    return [], []


def math_intervals(routine):
    starts, ends = {}, {}
    places = {}
    for position, instruction in enumerate(routine.code):
        if instruction[0] == "place":
            places[instruction[1]] = position
        uses, defs = math_uses_defs(instruction)
        for value in uses + defs:
            starts.setdefault(value.index, position)
            ends[value.index] = position
    loops = []
    for position, instruction in enumerate(routine.code):
        target = instruction[1] if instruction[0] == "jump" else instruction[2] if instruction[0] == "branch" else None
        if target is not None and places[target] < position:
            loops.append((places[target], position))
    changed = True
    while changed:
        changed = False
        for head, tail in loops:
            for index in starts:
                start, end = starts[index], ends[index]
                if index in routine.mutable and start <= tail and end >= head:
                    start, end = min(start, head), max(end, tail)
                elif start < head <= end:
                    end = max(end, tail)
                if (start, end) != (starts[index], ends[index]):
                    starts[index], ends[index] = start, end
                    changed = True
    return starts, ends


def math_allocate(routine):
    starts, ends = math_intervals(routine)
    order = sorted(starts, key=lambda index: (starts[index], index))
    registers = {}
    active = []
    free = {"X": list(MATH_X_POOL), "D": list(MATH_D_POOL)}
    for index in order:
        start = starts[index]
        for other in list(active):
            if ends[other] <= start and other != index:
                active.remove(other)
                free[math_class(routine, other)].append(registers[other])
        register_class = math_class(routine, index)
        if not free[register_class]:
            raise SystemExit(f"tables.py: routine {routine.name} needs more {register_class} registers at {start}")
        free[register_class].sort()
        registers[index] = free[register_class].pop(0)
        active.append(index)
    return registers, starts, ends


def math_class(routine, index):
    return "D" if routine.kinds[index] == "D" else "X"


def math_constant_steps(register, value):
    value &= (1 << 64) - 1
    chunks = [(value >> (16 * shift)) & 0xFFFF for shift in range(4)]
    inverted = sum(1 for chunk in chunks if chunk != 0xFFFF) < sum(1 for chunk in chunks if chunk != 0)
    filler = 0xFFFF if inverted else 0
    steps = []
    for shift, chunk in enumerate(chunks):
        if chunk == filler:
            continue
        if not steps:
            steps.append(("MOVN_X", register, 0, chunk ^ 0xFFFF, shift) if inverted else ("MOVZ_X", register, 0, chunk, shift))
        else:
            steps.append(("MOVK_X", register, 0, chunk, shift))
    if not steps:
        steps.append(("MOVN_X", register, 0, 0, 0) if inverted else ("MOVZ_X", register, 0, 0, 0))
    return steps


def math_lower(routine, name_label):
    registers, starts, ends = math_allocate(routine)
    calls = [position for position, instruction in enumerate(routine.code) if instruction[0] == "call"]
    slots = {}
    for position in calls:
        for index in starts:
            if starts[index] < position < ends[index]:
                slots.setdefault(index, 8 * (len(slots) + 1))
    array_offsets = []
    offset = 8 * (len(slots) + 1)
    for length in routine.arrays:
        array_offsets.append(offset)
        offset += 8 * length
    framed = bool(calls or routine.arrays)
    frame = (offset + 15) // 16 * 16 if framed else 0
    assert frame < 4096
    out = [("place", routine.name)]

    def emit_step(form, a0=0, a1=0, a2=0, a3=0, target=None):
        out.append(("emit", form, a0, a1, a2, a3, target))

    def reg(value):
        return registers[value.index]

    def epilogue():
        if framed:
            emit_step("LDR_X", 30, 31, 0)
            emit_step("ADD_X_IMM", 31, 31, frame)
        emit_step("RET")

    for position, instruction in enumerate(routine.code):
        kind = instruction[0]
        if kind == "enter":
            if framed:
                emit_step("SUB_X_IMM", 31, 31, frame)
                emit_step("STR_X", 30, 31, 0)
            for number, value in enumerate(instruction[1]):
                if value.kind == "D":
                    emit_step("FMOV_D_X", reg(value), number)
            for number, value in enumerate(instruction[1]):
                if value.kind != "D" and reg(value) != number:
                    emit_step("ORR_X", reg(value), 31, number)
        elif kind == "place":
            out.append(("place", name_label(instruction[1])))
        elif kind == "jump":
            emit_step("B", target=name_label(instruction[1]))
        elif kind == "const":
            value, bits = instruction[1], instruction[2]
            if value.kind == "D":
                if bits == 0:
                    emit_step("FMOV_D_X", reg(value), 31)
                else:
                    for step in math_constant_steps(MATH_SCRATCH, bits):
                        emit_step(*step)
                    emit_step("FMOV_D_X", reg(value), MATH_SCRATCH)
            else:
                for step in math_constant_steps(reg(value), bits):
                    emit_step(*step)
        elif kind in ("float", "integer"):
            emit_step(instruction[2], reg(instruction[1]), reg(instruction[3]), reg(instruction[4]))
        elif kind == "fma":
            emit_step("FMADD_D", reg(instruction[1]), reg(instruction[2]), reg(instruction[3]), reg(instruction[4]))
        elif kind == "immediate":
            emit_step(instruction[2], reg(instruction[1]), reg(instruction[3]), instruction[4])
        elif kind == "float_unary":
            emit_step(instruction[2], reg(instruction[1]), reg(instruction[3]))
        elif kind == "shift":
            result, operation, source, amount = instruction[1], instruction[2], instruction[3], instruction[4]
            if operation == "shl":
                emit_step("UBFM_X", reg(result), reg(source), (64 - amount) % 64, 63 - amount)
            else:
                emit_step("SBFM_X" if operation == "asr" else "UBFM_X", reg(result), reg(source), amount, 63)
        elif kind == "extend":
            emit_step("SBFM_X" if instruction[1].kind == "I" else "UBFM_X", reg(instruction[1]), reg(instruction[2]), 0, 31)
        elif kind == "not":
            emit_step("ORN_X", reg(instruction[1]), 31, reg(instruction[2]))
        elif kind == "move":
            target, source = instruction[1], instruction[2]
            if reg(target) != reg(source):
                emit_step("FMOV_D" if target.kind == "D" else "ORR_X", reg(target), *((reg(source),) if target.kind == "D" else (31, reg(source))))
        elif kind == "scvtf":
            emit_step("SCVTF_D_X", reg(instruction[1]), reg(instruction[2]))
        elif kind == "fcvtzs":
            emit_step("FCVTZS_X_D", reg(instruction[1]), reg(instruction[2]))
        elif kind == "to_bits":
            emit_step("FMOV_X_D", reg(instruction[1]), reg(instruction[2]))
        elif kind == "from_bits":
            emit_step("FMOV_D_X", reg(instruction[1]), reg(instruction[2]))
        elif kind == "branch":
            condition, target, negate = instruction[1], instruction[2], instruction[3]
            if condition.kind == "D":
                emit_step("FCMP_D", 0, reg(condition.left), reg(condition.right))
                code = MATH_FLOAT_CONDITIONS[condition.test]
            else:
                if isinstance(condition.right, MathValue):
                    emit_step("SUBS_X", 31, reg(condition.left), reg(condition.right))
                elif 0 <= condition.right < 4096:
                    emit_step("SUBS_X_IMM", 31, reg(condition.left), condition.right)
                else:
                    for step in math_constant_steps(MATH_SCRATCH, condition.right):
                        emit_step(*step)
                    emit_step("SUBS_X", 31, reg(condition.left), MATH_SCRATCH)
                table = MATH_UNSIGNED_CONDITIONS if condition.kind == "U" else MATH_SIGNED_CONDITIONS
                code = table[condition.test]
            emit_step("B_COND", a3=code ^ 1 if negate else code, target=name_label(target))
        elif kind == "call":
            label, arguments, results = instruction[1], instruction[2], instruction[3]
            saved = [index for index in slots if starts[index] < position < ends[index]]
            for index in saved:
                if routine.kinds[index] == "D":
                    emit_step("FMOV_X_D", MATH_SCRATCH, registers[index])
                    emit_step("STR_X", MATH_SCRATCH, 31, slots[index])
                else:
                    emit_step("STR_X", registers[index], 31, slots[index])
            assert sum(1 for argument in arguments if argument.kind != "D") <= 1
            for number, argument in enumerate(arguments):
                if argument.kind != "D" and reg(argument) != number:
                    emit_step("ORR_X", number, 31, reg(argument))
            for number, argument in enumerate(arguments):
                if argument.kind == "D":
                    emit_step("FMOV_X_D", number, reg(argument))
            emit_step("BL", target=name_label(label))
            for number, result in enumerate(results):
                if result.kind == "D":
                    emit_step("FMOV_D_X", reg(result), number)
            for number, result in enumerate(results):
                if result.kind != "D" and reg(result) != number:
                    emit_step("ORR_X", reg(result), 31, number)
            for index in saved:
                if routine.kinds[index] == "D":
                    emit_step("LDR_X", MATH_SCRATCH, 31, slots[index])
                    emit_step("FMOV_D_X", registers[index], MATH_SCRATCH)
                else:
                    emit_step("LDR_X", registers[index], 31, slots[index])
        elif kind == "ret":
            values = instruction[1]
            for number, value in enumerate(values):
                if value.kind != "D" and reg(value) != number:
                    emit_step("ORR_X", number, 31, reg(value))
            for number, value in enumerate(values):
                if value.kind == "D":
                    emit_step("FMOV_X_D", number, reg(value))
            epilogue()
        elif kind == "load":
            result, array, index = instruction[1], instruction[2], instruction[3]
            emit_step("ADD_X_IMM", MATH_SCRATCH, 31, array_offsets[array.slot])
            if result.kind == "D":
                emit_step("LDR_X_REG", MATH_SCRATCH, MATH_SCRATCH, reg(index))
                emit_step("FMOV_D_X", reg(result), MATH_SCRATCH)
            else:
                emit_step("LDR_X_REG", reg(result), MATH_SCRATCH, reg(index))
        elif kind == "store":
            array, index, value = instruction[1], instruction[2], instruction[3]
            emit_step("ADD_X_IMM", MATH_SCRATCH, 31, array_offsets[array.slot])
            if value.kind == "D":
                emit_step("FMOV_X_D", 16, reg(value))
                emit_step("STR_X_REG", 16, MATH_SCRATCH, reg(index))
            else:
                emit_step("STR_X_REG", reg(value), MATH_SCRATCH, reg(index))
        else:
            raise SystemExit(f"tables.py: unknown math instruction {kind}")
    return out


def math_ldexp():
    f = MathRoutine("math_ldexp", ["D", "I"])
    x, count = f.parameters
    y = f.var("D", x)
    n = f.var("I", count)
    with f.If(n > 1023):
        y.set(y * f.bits_constant(0x7FE0000000000000))
        n.set(n - 1023)
        with f.If(n > 1023):
            y.set(y * f.bits_constant(0x7FE0000000000000))
            n.set(n - 1023)
            with f.If(n > 1023):
                n.set(1023)
    with f.Else():
        with f.If(n < -1022):
            y.set(y * f.bits_constant(0x0360000000000000))
            n.set(n + 969)
            with f.If(n < -1022):
                y.set(y * f.bits_constant(0x0360000000000000))
                n.set(n + 969)
                with f.If(n < -1022):
                    n.set(-1022)
    f.ret(y * f.from_bits(f.convert(n + 0x3FF, "L") << 52))
    return f


def math_frexp():
    f = MathRoutine("math_frexp", ["D"])
    x = f.var("D", f.parameters[0])
    hx = f.var("I", f.hi(x))
    lx = f.convert(f.bits(x), "I")
    ix = f.var("I", hx & 0x7FFFFFFF)
    exponent = f.var("I", 0)
    with f.If(ix >= 0x7FF00000):
        f.ret(x, exponent)
    with f.If((ix | lx) == 0):
        f.ret(x, exponent)
    with f.If(ix < 0x00100000):
        x.set(x * f.bits_constant(0x4350000000000000))
        hx.set(f.hi(x))
        ix.set(hx & 0x7FFFFFFF)
        exponent.set(-54)
    exponent.set(exponent + ((ix >> 20) - 1022))
    hx.set((hx & 0x800FFFFF) | 0x3FE00000)
    x.set(f.with_hi(x, hx))
    f.ret(x, exponent)
    return f


def math_modf():
    f = MathRoutine("math_modf", ["D"])
    x = f.parameters[0]
    i0 = f.hi(x)
    i1 = f.lo(x)
    j0 = f.var("I", ((i0 >> 20) & 0x7FF) - 0x3FF)
    signed_zero = f.words(i0 & 0x80000000, 0)
    with f.If(j0 < 20):
        with f.If(j0 < 0):
            f.ret(x, signed_zero)
        i = f.convert(f.u(0x000FFFFF) >> f.convert(j0, "U"), "I")
        with f.If(((i0 & i) | f.convert(i1, "I")) == 0):
            f.ret(signed_zero, x)
        whole = f.words(i0 & ~i, 0)
        f.ret(x - whole, whole)
    with f.If(j0 > 51):
        with f.If(j0 == 0x400):
            f.ret(f.d(0.0) / x, x)
        f.ret(signed_zero, x * 1.0)
    i = f.u(0xFFFFFFFF) >> f.convert(j0 - 20, "U")
    with f.If((i1 & i) == 0):
        f.ret(signed_zero, x)
    whole = f.words(i0, i1 & ~i)
    f.ret(x - whole, whole)
    return f


def math_fmod():
    f = MathRoutine("math_fmod", ["D", "D"])
    x0, y0 = f.parameters
    hx = f.var("I", f.hi(x0))
    lx = f.var("U", f.lo(x0))
    hy = f.var("I", f.hi(y0))
    ly = f.var("U", f.lo(y0))
    sx = hx & 0x80000000
    hx.set(hx ^ sx)
    hy.set(hy & 0x7FFFFFFF)
    nan_label = f.label()
    with f.If((hy | f.convert(ly, "I")) == 0):
        f.jump(nan_label)
    with f.If(hx >= 0x7FF00000):
        f.jump(nan_label)
    with f.If((hy | f.convert((ly | (0 - ly)) >> 31, "I")) > 0x7FF00000):
        f.jump(nan_label)
    zero = f.from_bits(f.convert(sx, "L") << 32)
    with f.If(hx <= hy):
        with f.If(hx < hy):
            f.ret(x0)
        with f.If(lx < ly):
            f.ret(x0)
        with f.If(lx == ly):
            f.ret(zero)
    ix = f.var("I")
    iy = f.var("I")
    for high, low, logb in ((hx, lx, ix), (hy, ly, iy)):
        with f.If(high < 0x00100000):
            j = f.var("I", -1022)
            i = f.var("U")
            with f.If(high == 0):
                j.set(j - 21)
                i.set(low)
            with f.Else():
                i.set(f.convert(high, "U") << 11)
            top = f.label()
            done = f.label()
            f.place(top)
            with f.If((i & 0x80000000) != 0):
                f.jump(done)
            with f.If(i == 0):
                f.jump(done)
            j.set(j - 1)
            i.set(i << 1)
            f.jump(top)
            f.place(done)
            logb.set(j)
        with f.Else():
            logb.set((high >> 20) - 1023)
    n = f.var("I")
    for high, low, logb in ((hx, lx, ix), (hy, ly, iy)):
        with f.If(logb >= -1022):
            high.set((high & 0x000FFFFF) | 0x00100000)
        with f.Else():
            n.set(-1022 - logb)
            with f.If(n <= 31):
                high.set((high << n) | f.convert(low >> f.convert(32 - n, "U"), "I"))
                low.set(low << f.convert(n, "U"))
            with f.Else():
                high.set(f.convert(low << f.convert(n - 32, "U"), "I"))
                low.set(0)
    n.set(ix - iy)
    hz = f.var("I")
    lz = f.var("U")
    top = f.label()
    done = f.label()
    f.place(top)
    with f.If(n == 0):
        f.jump(done)
    n.set(n - 1)
    hz.set(hx - hy)
    lz.set(lx - ly)
    with f.If(lx < ly):
        hz.set(hz - 1)
    with f.If(hz < 0):
        hx.set(hx + hx + f.convert(lx >> 31, "I"))
        lx.set(lx + lx)
    with f.Else():
        with f.If((hz | f.convert(lz, "I")) == 0):
            f.ret(zero)
        hx.set(hz + hz + f.convert(lz >> 31, "I"))
        lx.set(lz + lz)
    f.jump(top)
    f.place(done)
    hz.set(hx - hy)
    lz.set(lx - ly)
    with f.If(lx < ly):
        hz.set(hz - 1)
    with f.If(hz >= 0):
        hx.set(hz)
        lx.set(lz)
    with f.If((hx | f.convert(lx, "I")) == 0):
        f.ret(zero)
    top = f.label()
    done = f.label()
    f.place(top)
    with f.If(hx >= 0x00100000):
        f.jump(done)
    hx.set(hx + hx + f.convert(lx >> 31, "I"))
    lx.set(lx + lx)
    iy.set(iy - 1)
    f.jump(top)
    f.place(done)
    with f.If(iy >= -1022):
        hx.set((hx - 0x00100000) | ((iy + 1023) << 20))
        f.ret(f.words(hx | sx, lx))
    n.set(-1022 - iy)
    with f.If(n <= 20):
        lx.set((lx >> f.convert(n, "U")) | (f.convert(hx, "U") << f.convert(32 - n, "U")))
        hx.set(hx >> n)
    with f.Else():
        with f.If(n <= 31):
            lx.set(f.convert(hx << (32 - n), "U") | (lx >> f.convert(n, "U")))
            hx.set(sx)
        with f.Else():
            lx.set(f.convert(hx >> (n - 32), "U"))
            hx.set(sx)
    f.ret(f.words(hx | sx, lx) * 1.0)
    f.place(nan_label)
    product = (x0 + 0.0) * (y0 + 0.0)
    f.ret(product / product)
    return f


def math_exp():
    f = MathRoutine("math_exp", ["D"])
    x = f.var("D", f.parameters[0])
    hi = f.var("D", 0.0)
    lo = f.var("D", 0.0)
    k = f.var("I", 0)
    high = f.hi(x)
    xsb = f.var("I", (high >> 31) & 1)
    hx = f.var("I", high & 0x7FFFFFFF)
    with f.If(hx >= 0x40862E42):
        with f.If(hx >= 0x7FF00000):
            with f.If(((hx & 0xFFFFF) | f.convert(f.lo(x), "I")) != 0):
                f.ret(x + x)
            with f.If(xsb == 0):
                f.ret(x)
            f.ret(0.0)
        with f.If(x > 7.09782712893383973096e+02):
            f.ret(f.d(1.0e+300) * 1.0e+300)
        with f.If(x < -7.45133219101941108420e+02):
            f.ret(f.d(9.33263618503218878990e-302) * 9.33263618503218878990e-302)
    with f.If(hx > 0x3FD62E42):
        with f.If(hx < 0x3FF0A2B2):
            with f.If(xsb == 0):
                hi.set(x - 6.93147180369123816490e-01)
                lo.set(1.90821492927058770002e-10)
                k.set(1)
            with f.Else():
                hi.set(x - -6.93147180369123816490e-01)
                lo.set(-1.90821492927058770002e-10)
                k.set(-1)
        with f.Else():
            half = f.var("D", 0.5)
            with f.If(xsb != 0):
                half.set(-0.5)
            k.set(f.convert(1.44269504088896338700e+00 * x + half, "I"))
            t = f.convert(k, "D")
            hi.set(x - t * 6.93147180369123816490e-01)
            lo.set(t * 1.90821492927058770002e-10)
        x.set(hi - lo)
    with f.Else():
        with f.If(hx < 0x3E300000):
            with f.If(f.d(1.0e+300) + x > 1.0):
                f.ret(1.0 + x)
        with f.Else():
            k.set(0)
    t = x * x
    twopk = f.var("D")
    with f.If(k >= -1021):
        twopk.set(f.words(f.convert(k + 0x3FF, "U") << 20, 0))
    with f.Else():
        twopk.set(f.words(f.convert(k + (0x3FF + 1000), "U") << 20, 0))
    c = x - t * (1.66666666666666019037e-01 + t * (-2.77777777770155933842e-03 + t * (6.61375632143793436117e-05 + t * (
        -1.65339022054652515390e-06 + t * 4.13813679705723846039e-08))))
    with f.If(k == 0):
        f.ret(1.0 - ((x * c) / (c - 2.0) - x))
    y = 1.0 - ((lo - (x * c) / (2.0 - c)) - hi)
    with f.If(k >= -1021):
        with f.If(k == 1024):
            f.ret(y * 2.0 * f.bits_constant(0x7FE0000000000000))
        f.ret(y * twopk)
    f.ret(y * twopk * 9.33263618503218878990e-302)
    return f


def log_reduce(f, x, k, check_one):
    high = f.hi(x)
    hx = f.var("I", high)
    lx = f.lo(x)
    with f.If(hx < 0x00100000):
        with f.If(((hx & 0x7FFFFFFF) | f.convert(lx, "I")) == 0):
            f.ret(f.d(-1.80143985094819840000e+16) / f.d(0.0))
        with f.If(hx < 0):
            f.ret((x - x) / f.d(0.0))
        k.set(k - 54)
        x.set(x * 1.80143985094819840000e+16)
        hx.set(f.hi(x))
    with f.If(hx >= 0x7FF00000):
        f.ret(x + x)
    if check_one:
        with f.If(hx == 0x3FF00000):
            with f.If(f.lo(x) == 0):
                f.ret(0.0)
    k.set(k + ((hx >> 20) - 1023))
    hx.set(hx & 0x000FFFFF)
    i = (hx + 0x95F64) & 0x100000
    x.set(f.with_hi(x, hx | (i ^ 0x3FF00000)))
    k.set(k + (i >> 20))
    return hx


def math_log():
    f = MathRoutine("math_log", ["D"])
    x = f.var("D", f.parameters[0])
    k = f.var("I", 0)
    hx = log_reduce(f, x, k, False)
    g = x - 1.0
    with f.If((0x000FFFFF & (hx + 2)) < 3):
        with f.If(g == 0.0):
            with f.If(k == 0):
                f.ret(0.0)
            dk = f.convert(k, "D")
            f.ret(dk * 6.93147180369123816490e-01 + dk * 1.90821492927058770002e-10)
        r = g * g * (0.5 - 0.33333333333333333 * g)
        with f.If(k == 0):
            f.ret(g - r)
        dk = f.convert(k, "D")
        f.ret(dk * 6.93147180369123816490e-01 - ((r - dk * 1.90821492927058770002e-10) - g))
    s = g / (2.0 + g)
    dk = f.convert(k, "D")
    z = s * s
    i = f.var("I", hx - 0x6147A)
    w = z * z
    j = 0x6B851 - hx
    t1 = w * (3.999999999940941908e-01 + w * (2.222219843214978396e-01 + w * 1.531383769920937332e-01))
    t2 = z * (6.666666666666735130e-01 + w * (2.857142874366239149e-01 + w * (1.818357216161805012e-01 + w * 1.479819860511658591e-01)))
    i.set(i | j)
    r = t2 + t1
    with f.If(i > 0):
        hfsq = 0.5 * g * g
        with f.If(k == 0):
            f.ret(g - (hfsq - s * (hfsq + r)))
        f.ret(dk * 6.93147180369123816490e-01 - ((hfsq - (s * (hfsq + r) + dk * 1.90821492927058770002e-10)) - g))
    with f.If(k == 0):
        f.ret(g - s * (g - r))
    f.ret(dk * 6.93147180369123816490e-01 - ((s * (g - r) - dk * 1.90821492927058770002e-10) - g))
    return f


def math_log10():
    f = MathRoutine("math_log10", ["D"])
    x = f.var("D", f.parameters[0])
    k = f.var("I", 0)
    log_reduce(f, x, k, True)
    y = f.convert(k, "D")
    g = x - 1.0
    hfsq = 0.5 * g * g
    s = g / (2.0 + g)
    z = s * s
    w = z * z
    t1 = w * (3.999999999940941908e-01 + w * (2.222219843214978396e-01 + w * 1.531383769920937332e-01))
    t2 = z * (6.666666666666735130e-01 + w * (2.857142874366239149e-01 + w * (1.818357216161805012e-01 + w * 1.479819860511658591e-01)))
    r = s * (0.5 * g * g + (t2 + t1))
    hi = f.with_lo(g - hfsq, 0)
    lo = (g - hi) - hfsq + r
    val_hi = f.var("D", hi * 4.34294481878168880939e-01)
    y2 = y * 3.01029995663611771306e-01
    val_lo = f.var("D", y * 3.69423907715893078616e-13 + (lo + hi) * 2.50829467116452752298e-11 + lo * 4.34294481878168880939e-01)
    w2 = y2 + val_hi
    val_lo.set(val_lo + ((y2 - w2) + val_hi))
    val_hi.set(w2)
    f.ret(val_lo + val_hi)
    return f


def two_sum(f, a, b):
    s = a + b
    bb = s - a
    return s, (a - (s - bb)) + (b - bb)


def math_exp_dd():
    f = MathRoutine("math_exp_dd", ["D"])
    a = f.parameters[0]
    half = f.var("D", 0.5)
    with f.If(a < 0.0):
        half.set(-0.5)
    k = f.convert(1.44269504088896338700e+00 * a + half, "I")
    t = f.convert(k, "D")
    r, rr = two_sum(f, a - t * 6.93147180369123816490e-01, -(t * 1.90821492927058770002e-10))
    factorials = [1]
    for n in range(1, 17):
        factorials.append(factorials[-1] * n)
    tail = f.d(1.0 / factorials[16])
    for n in range(15, 2, -1):
        tail = r * tail + 1.0 / factorials[n]
    tail = r * tail
    square = r * r
    square_low = f.fma(r, r, -square) + 2.0 * r * rr
    cubic = square * tail
    quadratic = 0.5 * square + cubic
    quadratic_low = cubic - (quadratic - 0.5 * square)
    p1 = r + quadratic
    p2 = (quadratic - (p1 - r)) + (quadratic_low + rr + 0.5 * square_low)
    e1 = 1.0 + p1
    e2 = (p1 - (e1 - 1.0)) + p2
    f.ret(e1, e2, k)
    return f


def scaled_exp(f, a):
    e1, e2, k = f.call("math_exp_dd", [a], ["D", "D", "I"])
    scale = f.words(f.convert(k + 0x3FF, "U") << 20, 0)
    return e1 * scale, e2 * scale


def exp_overflow_range(f, a, sign):
    e1, e2, k = f.call("math_exp_dd", [a], ["D", "D", "I"])
    return (e1 + e2) * sign * f.words(f.convert(k + (0x3FF - 2), "U") << 20, 0) * 2.0


def math_sinh():
    f = MathRoutine("math_sinh", ["D"])
    x = f.parameters[0]
    jx = f.hi(x)
    ix = f.var("I", jx & 0x7FFFFFFF)
    with f.If(ix >= 0x7FF00000):
        f.ret(x + x)
    h = f.var("D", 0.5)
    with f.If(jx < 0):
        h.set(-h)
    with f.If(ix < 0x40360000):
        with f.If(ix < 0x3E300000):
            with f.If(f.d(1.0e307) + x > 1.0):
                f.ret(x)
        big, small = scaled_exp(f, f.fabs(x))
        t1, t2 = two_sum(f, big, f.d(-1.0))
        t2 = t2 + small
        w0 = t1 / big
        w1 = (f.fma(-w0, big, t1) + (t2 - w0 * small)) / big
        s1, s2 = two_sum(f, t1, w0)
        f.ret(h * (s1 + (s2 + (t2 + w1))))
    with f.If(ix <= 0x408633CE):
        f.ret(exp_overflow_range(f, f.fabs(x), h + h))
    f.ret(x * 1.0e307)
    return f


def math_cosh():
    f = MathRoutine("math_cosh", ["D"])
    x = f.parameters[0]
    ix = f.var("I", f.hi(x) & 0x7FFFFFFF)
    with f.If(ix >= 0x7FF00000):
        f.ret(x * x)
    with f.If(ix < 0x40360000):
        big, small = scaled_exp(f, f.fabs(x))
        i0 = 1.0 / big
        i1 = (f.fma(-i0, big, f.d(1.0)) - i0 * small) * i0
        s1, s2 = two_sum(f, big, i0)
        f.ret(0.5 * (s1 + (s2 + (small + i1))))
    with f.If(ix <= 0x408633CE):
        f.ret(exp_overflow_range(f, f.fabs(x), f.d(1.0)))
    f.ret(f.d(1.0e300) * 1.0e300)
    return f


def math_tanh():
    f = MathRoutine("math_tanh", ["D"])
    x = f.parameters[0]
    jx = f.var("I", f.hi(x))
    ix = f.var("I", jx & 0x7FFFFFFF)
    with f.If(ix >= 0x7FF00000):
        with f.If(jx >= 0):
            f.ret(1.0 / x + 1.0)
        f.ret(1.0 / x - 1.0)
    z = f.var("D")
    with f.If(ix < 0x40360000):
        with f.If(ix < 0x3E300000):
            with f.If(f.d(1.0e300) + x > 1.0):
                f.ret(x)
        a = f.var("D", -2.0 * f.fabs(x))
        with f.If(ix >= 0x3FF00000):
            a.set(-a)
        big, small = scaled_exp(f, a)
        n1, n2 = two_sum(f, big, f.d(-1.0))
        d1, d2 = two_sum(f, big, f.d(1.0))
        z0 = n1 / d1
        z.set(f.fabs(z0 + (f.fma(-z0, d1, n1) + ((n2 + small) - z0 * (d2 + small))) / d1))
    with f.Else():
        z.set(f.d(1.0) - 1.0e-300)
    with f.If(jx >= 0):
        f.ret(z)
    f.ret(-z)
    return f


def math_pow():
    f = MathRoutine("math_pow", ["D", "D"])
    x, y = f.parameters
    huge, tiny = 1.0e300, 1.0e-300
    hx = f.var("I", f.hi(x))
    lx = f.var("U", f.lo(x))
    hy = f.var("I", f.hi(y))
    ly = f.var("U", f.lo(y))
    ix = f.var("I", hx & 0x7FFFFFFF)
    iy = f.var("I", hy & 0x7FFFFFFF)
    with f.If((iy | f.convert(ly, "I")) == 0):
        f.ret(1.0)
    with f.If(hx == 0x3FF00000):
        with f.If(lx == 0):
            f.ret(1.0)
    nan = f.label()
    f.branch(ix > 0x7FF00000, nan)
    with f.If(ix == 0x7FF00000):
        f.branch(lx != 0, nan)
    f.branch(iy > 0x7FF00000, nan)
    with f.If(iy == 0x7FF00000):
        f.branch(ly != 0, nan)
    yisint = f.var("I", 0)
    k = f.var("I")
    j = f.var("I")
    with f.If(hx < 0):
        with f.If(iy >= 0x43400000):
            yisint.set(2)
        with f.Else():
            with f.If(iy >= 0x3FF00000):
                k.set((iy >> 20) - 0x3FF)
                with f.If(k > 20):
                    shift = f.convert(52 - k, "U")
                    ju = ly >> shift
                    with f.If((ju << shift) == ly):
                        yisint.set(2 - f.convert(ju & 1, "I"))
                with f.Else():
                    with f.If(ly == 0):
                        j.set(iy >> (20 - k))
                        with f.If((j << (20 - k)) == iy):
                            yisint.set(2 - (j & 1))
    with f.If(ly == 0):
        with f.If(iy == 0x7FF00000):
            with f.If(((ix - 0x3FF00000) | f.convert(lx, "I")) == 0):
                f.ret(1.0)
            with f.If(ix >= 0x3FF00000):
                with f.If(hy >= 0):
                    f.ret(y)
                f.ret(0.0)
            with f.If(hy < 0):
                f.ret(-y)
            f.ret(0.0)
        with f.If(iy == 0x3FF00000):
            with f.If(hy < 0):
                f.ret(1.0 / x)
            f.ret(x)
        with f.If(hy == 0x40000000):
            f.ret(x * x)
        with f.If(hy == 0x3FE00000):
            with f.If(hx >= 0):
                f.ret(f.sqrt(x))
    ax = f.var("D", f.fabs(x))
    with f.If(lx == 0):
        special = f.label()
        ordinary = f.label()
        f.branch(ix == 0x7FF00000, special)
        f.branch(ix == 0, special)
        f.branch(ix == 0x3FF00000, special)
        f.jump(ordinary)
        f.place(special)
        z = f.var("D", ax)
        with f.If(hy < 0):
            z.set(1.0 / z)
        with f.If(hx < 0):
            with f.If(((ix - 0x3FF00000) | yisint) == 0):
                z.set((z - z) / (z - z))
            with f.Else():
                with f.If(yisint == 1):
                    z.set(-z)
        f.ret(z)
        f.place(ordinary)
    n = f.var("I", f.convert(f.convert(hx, "U") >> 31, "I") - 1)
    with f.If((n | yisint) == 0):
        f.ret((x - x) / (x - x))
    s = f.var("D", 1.0)
    with f.If((n | (yisint - 1)) == 0):
        s.set(-1.0)
    t1 = f.var("D")
    t2 = f.var("D")
    with f.If(iy > 0x41E00000):
        with f.If(iy > 0x43F00000):
            with f.If(ix <= 0x3FEFFFFF):
                with f.If(hy < 0):
                    f.ret(f.d(huge) * huge)
                f.ret(f.d(tiny) * tiny)
            with f.If(ix >= 0x3FF00000):
                with f.If(hy > 0):
                    f.ret(f.d(huge) * huge)
                f.ret(f.d(tiny) * tiny)
        with f.If(ix < 0x3FEFFFFF):
            with f.If(hy < 0):
                f.ret(s * huge * huge)
            f.ret(s * tiny * tiny)
        with f.If(ix > 0x3FF00000):
            with f.If(hy > 0):
                f.ret(s * huge * huge)
            f.ret(s * tiny * tiny)
        t = ax - 1.0
        w = (t * t) * (0.5 - t * (3.3333333333333331e-01 - t * 0.25))
        u = 1.44269502162933349609e+00 * t
        v = t * 1.92596299112661746887e-08 - w * 1.44269504088896338700e+00
        t1.set(f.with_lo(u + v, 0))
        t2.set(v - (t1 - u))
    with f.Else():
        n.set(0)
        with f.If(ix < 0x00100000):
            ax.set(ax * 9007199254740992.0)
            n.set(n - 53)
            ix.set(f.hi(ax))
        n.set(n + ((ix >> 20) - 0x3FF))
        j.set(ix & 0x000FFFFF)
        ix.set(j | 0x3FF00000)
        bp = f.var("D", 1.0)
        dp_h = f.var("D", 0.0)
        dp_l = f.var("D", 0.0)
        with f.If(j <= 0x3988E):
            k.set(0)
        with f.Else():
            with f.If(j < 0xBB67A):
                k.set(1)
                bp.set(1.5)
                dp_h.set(5.84962487220764160156e-01)
                dp_l.set(1.35003920212974897128e-08)
            with f.Else():
                k.set(0)
                n.set(n + 1)
                ix.set(ix - 0x00100000)
        ax.set(f.with_hi(ax, ix))
        u = ax - bp
        v = 1.0 / (ax + bp)
        ss = u * v
        s_h = f.with_lo(ss, 0)
        t_h = f.words(((ix >> 1) | 0x20000000) + 0x00080000 + (k << 18), 0)
        t_l = ax - (t_h - bp)
        s_l = v * ((u - s_h * t_h) - s_h * t_l)
        s2 = ss * ss
        r = s2 * s2 * (5.99999999999994648725e-01 + s2 * (4.28571428578550184252e-01 + s2 * (3.33333329818377432918e-01 + s2 * (
            2.72728123808534006489e-01 + s2 * (2.30660745775561754067e-01 + s2 * 2.06975017800338417784e-01)))))
        r = r + s_l * (s_h + ss)
        s2 = s_h * s_h
        t_h = f.with_lo(3.0 + s2 + r, 0)
        t_l = r - ((t_h - 3.0) - s2)
        u = s_h * t_h
        v = s_l * t_h + t_l * ss
        p_h = f.with_lo(u + v, 0)
        p_l = v - (p_h - u)
        z_h = 9.61796700954437255859e-01 * p_h
        z_l = -7.02846165095275826516e-09 * p_h + p_l * 9.61796693925975554329e-01 + dp_l
        t = f.convert(n, "D")
        t1.set(f.with_lo(((z_h + z_l) + dp_h) + t, 0))
        t2.set(z_l - (((t1 - t) - dp_h) - z_h))
    y1 = f.with_lo(y, 0)
    p_l = f.var("D", (y - y1) * t1 + y * t2)
    p_h = f.var("D", y1 * t1)
    z = f.var("D", p_l + p_h)
    j.set(f.hi(z))
    i = f.var("I", f.convert(f.lo(z), "I"))
    with f.If(j >= 0x40900000):
        with f.If(((j - 0x40900000) | i) != 0):
            f.ret(s * huge * huge)
        with f.If(p_l + 8.0085662595372944372e-0017 > z - p_h):
            f.ret(s * huge * huge)
    with f.Else():
        with f.If((j & 0x7FFFFFFF) >= 0x4090CC00):
            with f.If(((j - 0xC090CC00) | i) != 0):
                f.ret(s * tiny * tiny)
            with f.If(p_l <= z - p_h):
                f.ret(s * tiny * tiny)
    i.set(j & 0x7FFFFFFF)
    k.set((i >> 20) - 0x3FF)
    n.set(0)
    with f.If(i > 0x3FE00000):
        n.set(j + (f.i(0x00100000) >> (k + 1)))
        k.set(((n & 0x7FFFFFFF) >> 20) - 0x3FF)
        t = f.words(n & ~(f.i(0x000FFFFF) >> k), 0)
        n.set(((n & 0x000FFFFF) | 0x00100000) >> (20 - k))
        with f.If(j < 0):
            n.set(-n)
        p_h.set(p_h - t)
    t = f.with_lo(p_l + p_h, 0)
    u = t * 6.93147182464599609375e-01
    v = (p_l - (t - p_h)) * 6.93147180559945286227e-01 + t * -1.90465429995776804525e-09
    z.set(u + v)
    w = v - (z - u)
    t = z * z
    t1.set(z - t * (1.66666666666666019037e-01 + t * (-2.77777777770155933842e-03 + t * (6.61375632143793436117e-05 + t * (
        -1.65339022054652515390e-06 + t * 4.13813679705723846039e-08)))))
    r = (z * t1) / (t1 - 2.0) - (w + z * w)
    z.set(1.0 - (r - z))
    j.set(f.hi(z))
    j.set(j + (n << 20))
    with f.If((j >> 20) <= 0):
        z.set(f.call("math_ldexp", [z, n], ["D"]))
    with f.Else():
        z.set(f.with_hi(z, j))
    f.ret(s * z)
    f.place(nan)
    f.ret((x + 0.0) + (y + 0.0))
    return f


IPIO2 = [10680707, 7228996, 1387004, 2578385, 16069853, 12639074, 9804092, 4427841, 16666979, 11263675, 12935607, 2387514, 4345298, 14681673, 3074569, 13734428, 16653803, 1880361, 10960616, 8533493, 3062596, 8710556, 7349940, 6258241, 3772886, 3769171, 3798172, 8675211, 12450088, 3874808, 9961438, 366607, 15675153, 9132554, 7151469, 3571407, 2607881, 12013382, 4155038, 6285869, 7677882, 13102053, 15825725, 473591, 9065106, 15363067, 6271263, 9264392, 5636912, 4652155, 7056368, 13614112, 10155062, 1944035, 9527646, 15080200, 6658437, 6231200, 6832269, 16767104, 5075751, 3212806, 1398474, 7579849, 6349435, 12618859]
PIO2 = [1.57079625129699707031e+00, 7.54978941586159635335e-08, 5.39030252995776476554e-15, 3.28200341580791294123e-22,
        1.27065575308067607349e-29, 1.22933308981111328932e-36, 2.73370053816464559624e-44, 2.16741683877804819444e-51]
PS = [1.66666666666666657415e-01, -3.25565818622400915405e-01, 2.01212532134862925881e-01, -4.00555345006794114027e-02,
      7.91534994289814532176e-04, 3.47933107596021167570e-05]
QS = [-2.40339491173441421878e+00, 2.02094576023350569471e+00, -6.88283971605453293030e-01, 7.70381505559019352791e-02]
TAN_T = [3.33333333333334091986e-01, 1.33333333333201242699e-01, 5.39682539762260521377e-02, 2.18694882948595424599e-02,
         8.86323982359930005737e-03, 3.59207910759131235356e-03, 1.45620945432529025516e-03, 5.88041240820264096874e-04,
         2.46463134818469906812e-04, 7.81794442939557092300e-05, 7.14072491382608190305e-05, -1.85586374855275456654e-05,
         2.59073051863633712884e-05]
ATAN_HI = [4.63647609000806093515e-01, 7.85398163397448278999e-01, 9.82793723247329054082e-01, 1.57079632679489655800e+00]
ATAN_LO = [2.26987774529616870924e-17, 3.06161699786838301793e-17, 1.39033110312309984516e-17, 6.12323399573676603587e-17]
AT = [3.33333333333329318027e-01, -1.99999999998764832476e-01, 1.42857142725034663711e-01, -1.11111104054623557880e-01,
      9.09088713343650656196e-02, -7.69187620504482999495e-02, 6.66107313738753120669e-02, -5.83357013379057348645e-02,
      4.97687799461593236017e-02, -3.65315727442169155270e-02, 1.62858201153657823623e-02]


def math_k_sin():
    f = MathRoutine("math_k_sin", ["D", "D", "I"])
    x, y, iy = f.parameters
    z = x * x
    w = z * z
    r = 8.33333333332248946124e-03 + z * (-1.98412698298579493134e-04 + z * 2.75573137070700676789e-06) + z * w * (
        -2.50507602534068634195e-08 + z * 1.58969099521155010221e-10)
    v = z * x
    with f.If(iy == 0):
        f.ret(x + v * (-1.66666666666666324348e-01 + z * r))
    f.ret(x - ((z * (0.5 * y - v * r) - y) - v * -1.66666666666666324348e-01))
    return f


def math_k_cos():
    f = MathRoutine("math_k_cos", ["D", "D"])
    x, y = f.parameters
    z = x * x
    w = z * z
    r = z * (4.16666666666666019037e-02 + z * (-1.38888888888741095749e-03 + z * 2.48015872894767294178e-05)) + w * w * (
        -2.75573143513906633035e-07 + z * (2.08757232129817482790e-09 + z * -1.13596475577881948265e-11))
    hz = 0.5 * z
    w = 1.0 - hz
    f.ret(w + (((1.0 - w) - hz) + (z * r - x * y)))
    return f


def math_k_tan():
    f = MathRoutine("math_k_tan", ["D", "D", "I"])
    x0, y0, iy = f.parameters
    x = f.var("D", x0)
    y = f.var("D", y0)
    hx = f.hi(x0)
    ix = f.var("I", hx & 0x7FFFFFFF)
    T = TAN_T
    with f.If(ix >= 0x3FE59428):
        with f.If(hx < 0):
            x.set(-x)
            y.set(-y)
        z = 7.85398163397448278999e-01 - x
        w = 3.06161699786838301793e-17 - y
        x.set(z + w)
        y.set(0.0)
    z = x * x
    w = z * z
    r = T[1] + w * (T[3] + w * (T[5] + w * (T[7] + w * (T[9] + w * T[11]))))
    v = z * (T[2] + w * (T[4] + w * (T[6] + w * (T[8] + w * (T[10] + w * T[12])))))
    s = z * x
    r = f.var("D", y + z * (s * (r + v) + y))
    r.set(r + T[0] * s)
    w = x + r
    with f.If(ix >= 0x3FE59428):
        v = f.convert(iy, "D")
        f.ret(f.convert(1 - ((hx >> 30) & 2), "D") * (v - 2.0 * (x - (w * w / (w + v) - r))))
    with f.If(iy == 1):
        f.ret(w)
    z = f.with_lo(w, 0)
    v = r - (z - x)
    a = -1.0 / w
    t = f.with_lo(a, 0)
    s = 1.0 + t * z
    f.ret(t + a * (s + t * v))
    return f


def math_rem_pio2():
    f = MathRoutine("math_rem_pio2", ["D"])
    x = f.parameters[0]
    pio2_1, pio2_1t = 1.57079632673412561417e+00, 6.07710050650619224932e-11
    hx = f.var("I", f.hi(x))
    ix = f.var("I", hx & 0x7FFFFFFF)
    medium = f.label()

    def near(multiple):
        with f.If(hx > 0):
            z = x - multiple * pio2_1
            first = z - multiple * pio2_1t
            f.ret(f.i(multiple), first, (z - first) - multiple * pio2_1t)
        z = x + multiple * pio2_1
        first = z + multiple * pio2_1t
        f.ret(f.i(-multiple), first, (z - first) + multiple * pio2_1t)

    with f.If(ix <= 0x400F6A7A):
        f.branch((ix & 0xFFFFF) == 0x921FB, medium)
        with f.If(ix <= 0x4002D97C):
            near(1)
        near(2)
    with f.If(ix <= 0x401C463B):
        with f.If(ix <= 0x4015FDBC):
            f.branch(ix == 0x4012D97C, medium)
            near(3)
        f.branch(ix == 0x401921FB, medium)
        near(4)
    large = f.label()
    f.branch(ix >= 0x413921FB, large)
    f.place(medium)
    fn = (x * 6.36619772367581382433e-01 + 6755399441055744.0) - 6755399441055744.0
    n = f.convert(fn, "I")
    r = f.var("D", x - fn * pio2_1)
    w = f.var("D", fn * pio2_1t)
    j = ix >> 20
    first = f.var("D", r - w)
    i = j - f.convert((f.convert(f.hi(first), "U") >> 20) & 0x7FF, "I")
    with f.If(i > 16):
        t = f.var("D", r)
        w.set(fn * 6.07710050630396597660e-11)
        r.set(t - w)
        w.set(fn * 2.02226624879595063154e-21 - ((t - r) - w))
        first.set(r - w)
        i = j - f.convert((f.convert(f.hi(first), "U") >> 20) & 0x7FF, "I")
        with f.If(i > 49):
            t.set(r)
            w.set(fn * 2.02226624871116645580e-21)
            r.set(t - w)
            w.set(fn * 8.47842766036889956997e-32 - ((t - r) - w))
            first.set(r - w)
    f.ret(n, first, (r - first) - w)
    f.place(large)
    with f.If(ix >= 0x7FF00000):
        z = x - x
        f.ret(f.i(0), z, z)
    two24, twon24 = 1.67772160000000000000e+07, 5.96046447753906250000e-08
    e0 = f.var("I", (ix >> 20) - 1046)
    z = f.var("D", f.words(ix - (e0 << 20), f.lo(x)))
    tx = f.array(3, "D")
    for index in range(2):
        whole = f.convert(f.convert(z, "I"), "D")
        tx[index] = whole
        z.set((z - whole) * two24)
    tx[2] = z
    nx = f.var("I", 3)
    trim, trimmed = f.label(), f.label()
    f.place(trim)
    f.branch(tx[nx - 1] != 0.0, trimmed)
    nx.set(nx - 1)
    f.jump(trim)
    f.place(trimmed)

    table = f.array(len(IPIO2), "I")
    for index, value in enumerate(IPIO2):
        table[index] = value
    pio2 = f.array(len(PIO2), "D")
    for index, value in enumerate(PIO2):
        pio2[index] = value
    iq = f.array(20, "I")
    fv = f.array(20, "D")
    fq = f.array(20, "D")
    q = f.array(20, "D")
    jk = 4
    jp = 4
    jx = f.var("I", nx - 1)
    jv = f.var("I", (e0 - 3) / f.i(24))
    with f.If(jv < 0):
        jv.set(0)
    q0 = f.var("I", e0 - 24 * (jv + 1))
    i = f.var("I", 0)
    j = f.var("I", jv - jx)
    k = f.var("I")
    m = f.var("I", jx + jk)
    fw = f.var("D")
    zv = f.var("D")
    nv = f.var("I")
    ih = f.var("I")
    carry = f.var("I")

    def loop(condition_builder, body):
        top, done = f.label(), f.label()
        f.place(top)
        f.branch(condition_builder(), done, negate=True)
        body()
        f.jump(top)
        f.place(done)

    def fill_f():
        value = f.var("D", 0.0)
        with f.If(j >= 0):
            value.set(f.convert(table[j], "D"))
        fv[i] = value
        i.set(i + 1)
        j.set(j + 1)

    i.set(0)
    loop(lambda: i <= m, fill_f)

    def product(target_index):
        fw.set(0.0)
        j.set(0)

        def accumulate():
            fw.set(fw + tx[j] * fv[jx + target_index - j])
            j.set(j + 1)
        loop(lambda: j <= jx, accumulate)
        q[target_index] = fw

    def fill_q():
        product(i)
        i.set(i + 1)

    i.set(0)
    loop(lambda: i <= jk, fill_q)
    jz = f.var("I", jk)
    recompute = f.label()
    f.place(recompute)
    i.set(0)
    j.set(jz)
    zv.set(q[jz])

    def split():
        fw.set(f.convert(f.convert(twon24 * zv, "I"), "D"))
        iq[i] = f.convert(zv - two24 * fw, "I")
        zv.set(q[j - 1] + fw)
        i.set(i + 1)
        j.set(j - 1)
    loop(lambda: j > 0, split)
    zv.set(f.call("math_ldexp", [zv, q0], ["D"]))
    zv.set(zv - 8.0 * f.unary("floor", zv * 0.125))
    nv.set(f.convert(zv, "I"))
    zv.set(zv - f.convert(nv, "D"))
    ih.set(0)
    with f.If(q0 > 0):
        top = iq[jz - 1]
        shifted = top >> (24 - q0)
        nv.set(nv + shifted)
        rest = top - (shifted << (24 - q0))
        iq[jz - 1] = rest
        ih.set(rest >> (23 - q0))
    with f.Else():
        with f.If(q0 == 0):
            ih.set(iq[jz - 1] >> 23)
        with f.Else():
            with f.If(zv >= 0.5):
                ih.set(2)
    with f.If(ih > 0):
        nv.set(nv + 1)
        carry.set(0)
        i.set(0)

        def complement():
            j.set(iq[i])
            with f.If(carry == 0):
                with f.If(j != 0):
                    carry.set(1)
                    iq[i] = 0x1000000 - j
            with f.Else():
                iq[i] = 0xFFFFFF - j
            i.set(i + 1)
        loop(lambda: i < jz, complement)
        with f.If(q0 > 0):
            with f.If(q0 == 1):
                iq[jz - 1] = iq[jz - 1] & 0x7FFFFF
            with f.If(q0 == 2):
                iq[jz - 1] = iq[jz - 1] & 0x3FFFFF
        with f.If(ih == 2):
            zv.set(1.0 - zv)
            with f.If(carry != 0):
                zv.set(zv - f.call("math_ldexp", [f.d(1.0), q0], ["D"]))
    finish = f.label()
    f.branch(zv != 0.0, finish)
    j.set(0)
    i.set(jz - 1)

    def gather():
        j.set(j | iq[i])
        i.set(i - 1)
    loop(lambda: i >= jk, gather)
    f.branch(j != 0, finish)
    k.set(1)

    def count():
        k.set(k + 1)
    loop(lambda: iq[jk - k] == 0, count)
    i.set(jz + 1)

    def extend():
        fv[jx + i] = f.convert(table[jv + i], "D")
        product(i)
        i.set(i + 1)
    loop(lambda: i <= jz + k, extend)
    jz.set(jz + k)
    f.jump(recompute)
    f.place(finish)
    with f.If(zv == 0.0):
        jz.set(jz - 1)
        q0.set(q0 - 24)

        def drop():
            jz.set(jz - 1)
            q0.set(q0 - 24)
        loop(lambda: iq[jz] == 0, drop)
    with f.Else():
        zv.set(f.call("math_ldexp", [zv, 0 - q0], ["D"]))
        with f.If(zv >= two24):
            fw.set(f.convert(f.convert(twon24 * zv, "I"), "D"))
            iq[jz] = f.convert(zv - two24 * fw, "I")
            jz.set(jz + 1)
            q0.set(q0 + 24)
            iq[jz] = f.convert(fw, "I")
        with f.Else():
            iq[jz] = f.convert(zv, "I")
    fw.set(f.call("math_ldexp", [f.d(1.0), q0], ["D"]))
    i.set(jz)

    def scale():
        q[i] = fw * f.convert(iq[i], "D")
        fw.set(fw * twon24)
        i.set(i - 1)
    loop(lambda: i >= 0, scale)
    i.set(jz)

    def multiply():
        fw.set(0.0)
        k.set(0)
        top, done = f.label(), f.label()
        f.place(top)
        f.branch(k > jp, done)
        f.branch(k > jz - i, done)
        fw.set(fw + pio2[k] * q[i + k])
        k.set(k + 1)
        f.jump(top)
        f.place(done)
        fq[jz - i] = fw
        i.set(i - 1)
    loop(lambda: i >= 0, multiply)
    fw.set(0.0)
    i.set(jz)

    def total():
        fw.set(fw + fq[i])
        i.set(i - 1)
    loop(lambda: i >= 0, total)
    head = f.var("D", fw)
    with f.If(ih != 0):
        head.set(-fw)
    fw.set(fq[0] - fw)
    i.set(1)

    def tail():
        fw.set(fw + fq[i])
        i.set(i + 1)
    loop(lambda: i <= jz, tail)
    with f.If(ih != 0):
        fw.set(-fw)
    nv.set(nv & 7)
    with f.If(hx < 0):
        f.ret(0 - nv, -head, -fw)
    f.ret(nv, head, fw)
    return f


def math_sin():
    f = MathRoutine("math_sin", ["D"])
    x = f.parameters[0]
    ix = f.var("I", f.hi(x) & 0x7FFFFFFF)
    with f.If(ix <= 0x3FE921FB):
        with f.If(ix < 0x3E500000):
            with f.If(f.convert(x, "I") == 0):
                f.ret(x)
        f.ret(f.call("math_k_sin", [x, 0.0, f.i(0)], ["D"]))
    with f.If(ix >= 0x7FF00000):
        f.ret(x - x)
    n, y0, y1 = f.call("math_rem_pio2", [x], ["I", "D", "D"])
    quadrant = n & 3
    with f.If(quadrant == 0):
        f.ret(f.call("math_k_sin", [y0, y1, f.i(1)], ["D"]))
    with f.If(quadrant == 1):
        f.ret(f.call("math_k_cos", [y0, y1], ["D"]))
    with f.If(quadrant == 2):
        f.ret(-f.call("math_k_sin", [y0, y1, f.i(1)], ["D"]))
    f.ret(-f.call("math_k_cos", [y0, y1], ["D"]))
    return f


def math_cos():
    f = MathRoutine("math_cos", ["D"])
    x = f.parameters[0]
    ix = f.var("I", f.hi(x) & 0x7FFFFFFF)
    with f.If(ix <= 0x3FE921FB):
        with f.If(ix < 0x3E46A09E):
            with f.If(f.convert(x, "I") == 0):
                f.ret(1.0)
        f.ret(f.call("math_k_cos", [x, 0.0], ["D"]))
    with f.If(ix >= 0x7FF00000):
        f.ret(x - x)
    n, y0, y1 = f.call("math_rem_pio2", [x], ["I", "D", "D"])
    quadrant = n & 3
    with f.If(quadrant == 0):
        f.ret(f.call("math_k_cos", [y0, y1], ["D"]))
    with f.If(quadrant == 1):
        f.ret(-f.call("math_k_sin", [y0, y1, f.i(1)], ["D"]))
    with f.If(quadrant == 2):
        f.ret(-f.call("math_k_cos", [y0, y1], ["D"]))
    f.ret(f.call("math_k_sin", [y0, y1, f.i(1)], ["D"]))
    return f


def math_tan():
    f = MathRoutine("math_tan", ["D"])
    x = f.parameters[0]
    ix = f.var("I", f.hi(x) & 0x7FFFFFFF)
    with f.If(ix <= 0x3FE921FB):
        with f.If(ix < 0x3E400000):
            with f.If(f.convert(x, "I") == 0):
                f.ret(x)
        f.ret(f.call("math_k_tan", [x, 0.0, f.i(1)], ["D"]))
    with f.If(ix >= 0x7FF00000):
        f.ret(x - x)
    n, y0, y1 = f.call("math_rem_pio2", [x], ["I", "D", "D"])
    f.ret(f.call("math_k_tan", [y0, y1, 1 - ((n & 1) << 1)], ["D"]))
    return f


def math_atan_dd():
    f = MathRoutine("math_atan_dd", ["D", "D"])
    x, dx = f.parameters
    ix = f.hi(x)
    numerator = f.var("D", -1.0)
    numerator_low = f.var("D", 0.0)
    denominator = f.var("D", x)
    denominator_low = f.var("D", dx)
    selector = f.var("I", 3)
    z = f.var("D", x)
    z_low = f.var("D", dx)
    reduce = f.label()
    with f.If(ix < 0x3FDC0000):
        selector.set(-1)
        f.jump(reduce)
    with f.If(ix < 0x3FE60000):
        selector.set(0)
        numerator.set(2.0 * x - 1.0)
        numerator_low.set(2.0 * dx)
        denominator.set(x + 2.0)
        denominator_low.set((2.0 - (denominator - x)) + dx)
    with f.Else():
        with f.If(ix < 0x3FF30000):
            selector.set(1)
            numerator.set(x - 1.0)
            numerator_low.set(dx)
            sum_, error = two_sum(f, x, f.d(1.0))
            denominator.set(sum_)
            denominator_low.set(error + dx)
        with f.Else():
            with f.If(ix < 0x40038000):
                selector.set(2)
                numerator.set(x - 1.5)
                numerator_low.set(dx)
                product = 1.5 * x
                sum_, error = two_sum(f, f.d(1.0), product)
                denominator.set(sum_)
                denominator_low.set(error + (f.fma(f.d(1.5), x, -product) + 1.5 * dx))
    quotient = numerator / denominator
    z.set(quotient)
    z_low.set((f.fma(-quotient, denominator, numerator) + (numerator_low - quotient * denominator_low)) / denominator)
    f.place(reduce)
    zz = z * z
    w = zz * zz
    s1 = zz * (AT[0] + w * (AT[2] + w * (AT[4] + w * (AT[6] + w * (AT[8] + w * AT[10])))))
    s2 = w * (AT[1] + w * (AT[3] + w * (AT[5] + w * (AT[7] + w * AT[9]))))
    t = z * (s1 + s2)
    correction = z_low / (1.0 + zz)
    with f.If(selector < 0):
        h = z - t
        f.ret(h, ((z - h) - t) + correction)
    high = f.var("D", ATAN_HI[3])
    low = f.var("D", ATAN_LO[3])
    for index in range(3):
        with f.If(selector == index):
            high.set(ATAN_HI[index])
            low.set(ATAN_LO[index])
    h1, l1 = two_sum(f, high, z)
    h = h1 - t
    f.ret(h, ((h1 - h) - t) + (l1 + low + correction))
    return f


def math_atan():
    f = MathRoutine("math_atan", ["D"])
    x = f.parameters[0]
    hx = f.hi(x)
    ix = f.var("I", hx & 0x7FFFFFFF)
    with f.If(ix >= 0x44100000):
        low = f.lo(x)
        with f.If(ix > 0x7FF00000):
            f.ret(x + x)
        with f.If(ix == 0x7FF00000):
            with f.If(low != 0):
                f.ret(x + x)
        with f.If(hx > 0):
            f.ret(f.d(ATAN_HI[3]) + ATAN_LO[3])
        f.ret(f.d(-ATAN_HI[3]) - ATAN_LO[3])
    with f.If(ix < 0x3E400000):
        with f.If(f.d(1.0e300) + x > 1.0):
            f.ret(x)
    h, l = f.call("math_atan_dd", [f.fabs(x), 0.0], ["D", "D"])
    z = h + l
    with f.If(hx < 0):
        f.ret(-z)
    f.ret(z)
    return f


def math_atan2():
    f = MathRoutine("math_atan2", ["D", "D"])
    y, x = f.parameters
    tiny, pi_o_4, pi_o_2, pi = 1.0e-300, 7.8539816339744827900E-01, 1.5707963267948965580E+00, 3.1415926535897931160E+00
    pi_lo = 1.2246467991473531772E-16
    hx = f.var("I", f.hi(x))
    lx = f.var("U", f.lo(x))
    ix = f.var("I", hx & 0x7FFFFFFF)
    hy = f.var("I", f.hi(y))
    ly = f.var("U", f.lo(y))
    iy = f.var("I", hy & 0x7FFFFFFF)
    nan = f.label()
    f.branch((ix | f.convert((lx | (0 - lx)) >> 31, "I")) > 0x7FF00000, nan)
    f.branch((iy | f.convert((ly | (0 - ly)) >> 31, "I")) > 0x7FF00000, nan)
    with f.If(hx == 0x3FF00000):
        with f.If(lx == 0):
            f.ret(f.call("math_atan", [y], ["D"]))
    m = f.var("I", ((hy >> 31) & 1) | ((hx >> 30) & 2))

    def by_quadrant(values):
        for index, value in enumerate(values[:-1]):
            with f.If(m == index):
                f.ret(value())
        f.ret(values[-1]())

    with f.If((iy | f.convert(ly, "I")) == 0):
        by_quadrant([lambda: y, lambda: y, lambda: f.d(pi) + tiny, lambda: f.d(-pi) - tiny])
    with f.If((ix | f.convert(lx, "I")) == 0):
        with f.If(hy < 0):
            f.ret(f.d(-pi_o_2) - tiny)
        f.ret(f.d(pi_o_2) + tiny)
    with f.If(ix == 0x7FF00000):
        with f.If(iy == 0x7FF00000):
            by_quadrant([lambda: f.d(pi_o_4) + tiny, lambda: f.d(-pi_o_4) - tiny, lambda: f.d(3.0 * pi_o_4) + tiny,
                         lambda: f.d(-3.0 * pi_o_4) - tiny])
        by_quadrant([lambda: f.d(0.0), lambda: f.d(-0.0), lambda: f.d(pi) + tiny, lambda: f.d(-pi) - tiny])
    with f.If(iy == 0x7FF00000):
        with f.If(hy < 0):
            f.ret(f.d(-pi_o_2) - tiny)
        f.ret(f.d(pi_o_2) + tiny)
    k = (iy - ix) >> 20
    z = f.var("D")
    z_low = f.var("D", 0.0)
    done = f.label()
    with f.If(k > 60):
        z.set(pi_o_2)
        z_low.set(0.5 * pi_lo)
        m.set(m & 1)
    with f.Else():
        with f.If(hx < 0):
            with f.If(k < -60):
                z.set(0.0)
                f.jump(done)
        ay = f.fabs(y)
        ax = f.fabs(x)
        q = ay / ax
        z.set(q)
        z_low.set(f.fma(-q, ax, ay) / ax)
        with f.If(f.hi(q) >= 0x3E400000):
            h, l = f.call("math_atan_dd", [q, z_low], ["D", "D"])
            z.set(h)
            z_low.set(l)
    f.place(done)
    s, e = two_sum(f, f.d(pi), -z)
    by_quadrant([lambda: z + z_low, lambda: -(z + z_low), lambda: s + (e + (pi_lo - z_low)), lambda: -(s + (e + (pi_lo - z_low)))])
    f.place(nan)
    f.ret((x + 0.0) + (y + 0.0))
    return f


def inverse_rational(f, t):
    p = t * (PS[0] + t * (PS[1] + t * (PS[2] + t * (PS[3] + t * (PS[4] + t * PS[5])))))
    q = 1.0 + t * (QS[0] + t * (QS[1] + t * (QS[2] + t * QS[3])))
    return p, q


def math_asin():
    f = MathRoutine("math_asin", ["D"])
    x = f.parameters[0]
    pio2_hi, pio2_lo, pio4_hi = 1.57079632679489655800e+00, 6.12323399573676603587e-17, 7.85398163397448278999e-01
    hx = f.hi(x)
    ix = f.var("I", hx & 0x7FFFFFFF)
    with f.If(ix >= 0x3FF00000):
        with f.If(((ix - 0x3FF00000) | f.convert(f.lo(x), "I")) == 0):
            f.ret(x * pio2_hi + x * pio2_lo)
        f.ret((x - x) / (x - x))
    with f.If(ix < 0x3FE00000):
        with f.If(ix < 0x3E500000):
            with f.If(f.d(1.000e+300) + x > 1.0):
                f.ret(x)
        t = x * x
        p, q = inverse_rational(f, t)
        w = p / q
        f.ret(x + x * w)
    w = 1.0 - f.fabs(x)
    t = f.var("D", w * 0.5)
    p, q = inverse_rational(f, t)
    s = f.sqrt(t)
    with f.If(ix >= 0x3FEF3333):
        w = p / q
        t.set(pio2_hi - (2.0 * (s + s * w) - pio2_lo))
    with f.Else():
        w = f.with_lo(s, 0)
        c = (t - w * w) / (s + w)
        r = p / q
        p = 2.0 * s * r - (pio2_lo - 2.0 * c)
        q = pio4_hi - 2.0 * w
        t.set(pio4_hi - (p - q))
    with f.If(hx > 0):
        f.ret(t)
    f.ret(-t)
    return f


def math_acos():
    f = MathRoutine("math_acos", ["D"])
    x = f.parameters[0]
    pi, pio2_hi, pio2_lo = 3.14159265358979311600e+00, 1.57079632679489655800e+00, 6.12323399573676603587e-17
    hx = f.hi(x)
    ix = f.var("I", hx & 0x7FFFFFFF)
    with f.If(ix >= 0x3FF00000):
        with f.If(((ix - 0x3FF00000) | f.convert(f.lo(x), "I")) == 0):
            with f.If(hx > 0):
                f.ret(0.0)
            f.ret(pi + 2.0 * f.d(pio2_lo))
        f.ret((x - x) / (x - x))
    with f.If(ix < 0x3FE00000):
        with f.If(ix <= 0x3C600000):
            f.ret(f.d(pio2_hi) + pio2_lo)
        z = x * x
        p, q = inverse_rational(f, z)
        r = p / q
        f.ret(pio2_hi - (x - (pio2_lo - x * r)))
    with f.If(hx < 0):
        z = (1.0 + x) * 0.5
        p, q = inverse_rational(f, z)
        s = f.sqrt(z)
        r = p / q
        w = r * s - pio2_lo
        f.ret(pi - 2.0 * (s + w))
    z = (1.0 - x) * 0.5
    s = f.sqrt(z)
    df = f.with_lo(s, 0)
    c = (z - df * df) / (s + df)
    p, q = inverse_rational(f, z)
    r = p / q
    w = r * s + c
    f.ret(2.0 * (df + w))
    return f


MATH_ROUTINES = [math_ldexp, math_frexp, math_modf, math_fmod, math_exp, math_exp_dd, math_log, math_log10, math_sinh, math_cosh, math_tanh, math_pow, math_k_sin, math_k_cos, math_k_tan, math_rem_pio2, math_sin, math_cos, math_tan, math_atan_dd, math_atan, math_atan2, math_asin, math_acos]


def math_runtime(first_local):
    locals_by_target = {}

    def local_name(target):
        if isinstance(target, str):
            return target
        return locals_by_target.setdefault(target, f"local{first_local + len(locals_by_target)}")

    steps = []
    for build in MATH_ROUTINES:
        for item in math_lower(build(), local_name):
            if item[0] == "place":
                steps.append(place(item[1]))
            else:
                _, form, a0, a1, a2, a3, target = item
                steps.append(emit(form, a0, a1, a2, a3, to=label(target)) if target else emit(form, a0, a1, a2, a3))
    return steps, first_local + len(locals_by_target)


MATH_RUNTIME, MATH_LOCAL_END = math_runtime(len(REAL_LABELS))
REAL_RUNTIME += MATH_RUNTIME
EMIT_SOURCES += [f"local{index}" for index in range(LOCAL_LABEL_COUNT, MATH_LOCAL_END)]


REAL_PARSE = [
    place("read_real_value"), emit("LDRB_W_REG", 9, 21, 19), emit("SUBS_W_IMM", XZR, 9, 32),
    emit("B_COND", a3=CC["NE"], to=label("malformed")), emit("ADD_X_IMM", 19, 19, 1), emit("ORR_X", 5, XZR, 19),
    place(L["value_scan"]), emit("LDRB_W_REG", 9, 21, 19), emit("SUBS_W_IMM", XZR, 9, 32),
    emit("B_COND", a3=CC["EQ"], to=label(L["value_end"])), emit("SUBS_W_IMM", XZR, 9, 10),
    emit("B_COND", a3=CC["EQ"], to=label(L["value_end"])), emit("ADD_X_IMM", 19, 19, 1), emit("B", to=label(L["value_scan"])),
    place(L["value_end"]), emit("ADD_X", 13, 21, 5), emit("SUB_X", 14, 19, 5),

    place("parse_real"), emit("SUB_X_IMM", SP, SP, PARSE_FRAME), emit("STR_X", 30, SP, 0), emit("MOVZ_X", 15, 0, PARSE_LIMBS),
    emit("SUBS_X_IMM", XZR, 12, 4), emit("B_COND", a3=CC["NE"], to=label(L["parse_double"])),
    *[step_row for value, offset in ((24, PARSE_PRECISION), (150, PARSE_T_MAX), (127, PARSE_BIAS), (255, PARSE_MAX_EXPONENT),
                                     (31, PARSE_SIGN_SHIFT)) for step_row in (emit("MOVZ_X", 5, 0, value), emit("STR_X", 5, SP, offset))],
    emit("B", to=label(L["parse_parameters"])), place(L["parse_double"]),
    *[step_row for value, offset in ((53, PARSE_PRECISION), (1075, PARSE_T_MAX), (1023, PARSE_BIAS), (2047, PARSE_MAX_EXPONENT),
                                     (63, PARSE_SIGN_SHIFT)) for step_row in (emit("MOVZ_X", 5, 0, value), emit("STR_X", 5, SP, offset))],
    place(L["parse_parameters"]), emit("ORR_X", 11, XZR, 13), emit("ORR_X", 10, XZR, 14), emit("MOVZ_X", 9),
    *[emit("STR_X", XZR, SP, offset) for offset in (PARSE_NEGATIVE, PARSE_DROPPED, PARSE_STICKY, PARSE_ADJUST, PARSE_FRACTION,
                                                    PARSE_EXPONENT, PARSE_EXPONENT_NEGATIVE)],
    emit("CBZ_X", 10, to=label(L["malformed"])), emit("LDRB_W", 5, 11, 0), emit("SUBS_W_IMM", XZR, 5, 45),
    emit("B_COND", a3=CC["NE"], to=label(L["parse_word"])), emit("MOVZ_X", 5, 0, 1), emit("STR_X", 5, SP, PARSE_NEGATIVE),
    emit("MOVZ_X", 9, 0, 1),
    place(L["parse_word"]), emit("SUB_X", 5, 10, 9), emit("SUBS_X_IMM", XZR, 5, 3), emit("B_COND", a3=CC["NE"], to=label(L["parse_number"])),
    emit("ADD_X", 6, 11, 9), emit("LDRB_W", 5, 6, 0), emit("LDRB_W", 7, 6, 1), emit("LDRB_W", 8, 6, 2), emit("MOVZ_X", 16, 0, 8),
    emit("LSLV_X", 7, 7, 16), emit("ORR_X", 5, 5, 7), emit("MOVZ_X", 16, 0, 16), emit("LSLV_X", 8, 8, 16), emit("ORR_X", 5, 5, 8),
    emit("MOVZ_X", 6, 0, 0x6E69), emit("MOVK_X", 6, 0, 0x66, 1), emit("SUBS_X", XZR, 5, 6),
    emit("B_COND", a3=CC["NE"], to=label(L["parse_nan"])), emit("LDR_X", 5, SP, PARSE_MAX_EXPONENT),
    emit("LDR_X", 6, SP, PARSE_PRECISION), emit("SUB_X_IMM", 6, 6, 1), emit("LSLV_X", 0, 5, 6), emit("B", to=label(L["sign"])),
    place(L["parse_nan"]), emit("MOVZ_X", 6, 0, 0x616E), emit("MOVK_X", 6, 0, 0x6E, 1), emit("SUBS_X", XZR, 5, 6),
    emit("B_COND", a3=CC["NE"], to=label(L["parse_number"])), emit("LDR_X", 7, SP, PARSE_NEGATIVE),
    emit("CBNZ_X", 7, to=label(L["malformed"])), emit("LDR_X", 5, SP, PARSE_MAX_EXPONENT), emit("LDR_X", 6, SP, PARSE_PRECISION),
    emit("SUB_X_IMM", 6, 6, 1), emit("LSLV_X", 0, 5, 6), emit("SUB_X_IMM", 6, 6, 1), emit("MOVZ_X", 7, 0, 1),
    emit("LSLV_X", 7, 7, 6), emit("ORR_X", 0, 0, 7), emit("B", to=label(L["ok"])),
    place(L["parse_number"]), emit("ADD_X_IMM", 0, SP, PARSE_N), emit("MOVZ_X", 1), emit("MOVZ_X", 2), emit("BL", to=label("bn_set")),
    emit("MOVZ_X", 12), emit("MOVZ_X", 13), emit("MOVZ_X", 14),
    place(L["part_start"]), emit("STR_X", XZR, SP, PARSE_PART),
    place(L["part_digit"]), emit("SUBS_X", XZR, 9, 10), emit("B_COND", a3=CC["HS"], to=label(L["part_end"])),
    emit("LDRB_W_REG", 5, 11, 9), emit("SUB_W_IMM", 5, 5, 48), emit("SUBS_W_IMM", XZR, 5, 9),
    emit("B_COND", a3=CC["HI"], to=label(L["part_end"])), emit("ADD_X_IMM", 9, 9, 1), emit("LDR_X", 6, SP, PARSE_PART),
    emit("ADD_X_IMM", 6, 6, 1), emit("STR_X", 6, SP, PARSE_PART), emit("CBNZ_X", 12, to=label(L["significant"])),
    emit("CBNZ_X", 5, to=label(L["significant"])), emit("LDR_X", 6, SP, PARSE_FRACTION), emit("CBZ_X", 6, to=label(L["part_digit"])),
    emit("LDR_X", 6, SP, PARSE_ADJUST), emit("SUB_X_IMM", 6, 6, 1), emit("STR_X", 6, SP, PARSE_ADJUST),
    emit("B", to=label(L["part_digit"])),
    place(L["significant"]), emit("MOVZ_X", 6, 0, 768), emit("SUBS_X", XZR, 12, 6), emit("B_COND", a3=CC["HS"], to=label(L["dropped_zero"])),
    emit("MOVZ_X", 6, 0, 10), emit("MUL_X", 13, 13, 6), emit("ADD_X", 13, 13, 5), emit("ADD_X_IMM", 14, 14, 1),
    emit("ADD_X_IMM", 12, 12, 1), emit("LDR_X", 6, SP, PARSE_FRACTION), emit("CBZ_X", 6, to=label(L["kept"])),
    emit("LDR_X", 6, SP, PARSE_ADJUST), emit("SUB_X_IMM", 6, 6, 1), emit("STR_X", 6, SP, PARSE_ADJUST),
    place(L["kept"]), emit("SUBS_X_IMM", XZR, 14, 9), emit("B_COND", a3=CC["NE"], to=label(L["part_digit"])),
    emit("ADD_X_IMM", 0, SP, PARSE_N), emit("MOVZ_X", 1, 0, 0xCA00), emit("MOVK_X", 1, 0, 0x3B9A, 1), emit("ORR_X", 2, XZR, 13),
    emit("BL", to=label("bn_muladd")), emit("MOVZ_X", 13), emit("MOVZ_X", 14), emit("B", to=label(L["part_digit"])),
    place(L["dropped_zero"]), emit("LDR_X", 6, SP, PARSE_DROPPED), emit("ADD_X_IMM", 6, 6, 1), emit("STR_X", 6, SP, PARSE_DROPPED),
    emit("CBZ_X", 5, to=label(L["dropped_fraction"])), emit("MOVZ_X", 6, 0, 1), emit("STR_X", 6, SP, PARSE_STICKY),
    place(L["dropped_fraction"]), emit("LDR_X", 6, SP, PARSE_FRACTION), emit("CBNZ_X", 6, to=label(L["part_digit"])),
    emit("LDR_X", 6, SP, PARSE_ADJUST), emit("ADD_X_IMM", 6, 6, 1), emit("STR_X", 6, SP, PARSE_ADJUST),
    emit("B", to=label(L["part_digit"])),
    place(L["part_end"]), emit("LDR_X", 6, SP, PARSE_PART), emit("CBZ_X", 6, to=label(L["malformed"])),
    emit("LDR_X", 6, SP, PARSE_FRACTION), emit("CBNZ_X", 6, to=label(L["exponent_check"])), emit("SUBS_X", XZR, 9, 10),
    emit("B_COND", a3=CC["HS"], to=label(L["exponent_check"])), emit("LDRB_W_REG", 5, 11, 9), emit("SUBS_W_IMM", XZR, 5, 46),
    emit("B_COND", a3=CC["NE"], to=label(L["exponent_check"])), emit("ADD_X_IMM", 9, 9, 1), emit("MOVZ_X", 6, 0, 1),
    emit("STR_X", 6, SP, PARSE_FRACTION), emit("B", to=label(L["part_start"])),
    place(L["exponent_check"]), emit("SUBS_X", XZR, 9, 10), emit("B_COND", a3=CC["HS"], to=label(L["parse_end"])),
    emit("LDRB_W_REG", 5, 11, 9), emit("MOVZ_X", 6, 0, 32), emit("ORR_X", 5, 5, 6), emit("SUBS_W_IMM", XZR, 5, 101),
    emit("B_COND", a3=CC["NE"], to=label(L["parse_end"])), emit("ADD_X_IMM", 9, 9, 1), emit("SUBS_X", XZR, 9, 10),
    emit("B_COND", a3=CC["HS"], to=label(L["malformed"])), emit("LDRB_W_REG", 5, 11, 9), emit("SUBS_W_IMM", XZR, 5, 45),
    emit("B_COND", a3=CC["NE"], to=label(L["exponent_sign"])), emit("MOVZ_X", 6, 0, 1), emit("STR_X", 6, SP, PARSE_EXPONENT_NEGATIVE),
    emit("ADD_X_IMM", 9, 9, 1), emit("B", to=label(L["exponent_loop"])), place(L["exponent_sign"]), emit("SUBS_W_IMM", XZR, 5, 43),
    emit("B_COND", a3=CC["NE"], to=label(L["exponent_loop"])), emit("ADD_X_IMM", 9, 9, 1),
    place(L["exponent_loop"]), emit("MOVZ_X", 7), emit("MOVZ_X", 8), place(L["leading"]), emit("SUBS_X", XZR, 9, 10),
    emit("B_COND", a3=CC["HS"], to=label(L["exponent_end"])), emit("LDRB_W_REG", 5, 11, 9), emit("SUB_W_IMM", 5, 5, 48),
    emit("SUBS_W_IMM", XZR, 5, 9), emit("B_COND", a3=CC["HI"], to=label(L["exponent_end"])), emit("ADD_X_IMM", 9, 9, 1),
    emit("ADD_X_IMM", 7, 7, 1), emit("MOVZ_X", 6, 0, 10), emit("MUL_X", 8, 8, 6), emit("ADD_X", 8, 8, 5),
    emit("MOVZ_X", 6, 0, 1, 3), emit("SUBS_X", XZR, 8, 6), emit("CSEL_X", 8, 8, 6, CC["LO"]),
    emit("B", to=label(L["leading"])), place(L["exponent_end"]), emit("CBZ_X", 7, to=label(L["malformed"])),
    emit("STR_X", 8, SP, PARSE_EXPONENT),
    place(L["parse_end"]), emit("SUBS_X", XZR, 9, 10), emit("B_COND", a3=CC["NE"], to=label(L["malformed"])),
    emit("CBZ_X", 14, to=label(L["no_flush"])), emit("MOVZ_X", 1, 0, 1), emit("MOVZ_X", 6, 0, 10), place(L["power_loop"]),
    emit("MUL_X", 1, 1, 6), emit("SUB_X_IMM", 14, 14, 1), emit("CBNZ_X", 14, to=label(L["power_loop"])),
    emit("ADD_X_IMM", 0, SP, PARSE_N), emit("ORR_X", 2, XZR, 13), emit("BL", to=label("bn_muladd")),
    place(L["no_flush"]), emit("LDR_X", 5, SP, PARSE_DROPPED), emit("CBZ_X", 5, to=label(L["no_sticky"])),
    emit("ADD_X_IMM", 0, SP, PARSE_N), emit("MOVZ_X", 1, 0, 10), emit("LDR_X", 2, SP, PARSE_STICKY), emit("BL", to=label("bn_muladd")),
    emit("ADD_X_IMM", 12, 12, 1), emit("LDR_X", 6, SP, PARSE_ADJUST), emit("SUB_X_IMM", 6, 6, 1), emit("STR_X", 6, SP, PARSE_ADJUST),
    place(L["no_sticky"]), emit("LDR_X", 5, SP, PARSE_EXPONENT), emit("LDR_X", 6, SP, PARSE_EXPONENT_NEGATIVE),
    emit("CBZ_X", 6, to=label(L["fraction_check"])), emit("SUB_X", 5, XZR, 5), place(L["fraction_check"]),
    emit("LDR_X", 6, SP, PARSE_ADJUST), emit("ADD_X", 5, 5, 6), emit("CBZ_X", 12, to=label(L["zero"])), emit("ADD_X", 6, 12, 5),
    emit("MOVZ_X", 7, 0, 310), emit("SUBS_X", XZR, 6, 7), emit("B_COND", a3=CC["GT"], to=label(L["malformed"])),
    emit("ADD_X_IMM", 6, 6, 330), emit("SUBS_X_IMM", XZR, 6, 0), emit("B_COND", a3=CC["LT"], to=label(L["zero"])),
    emit("ORR_X", 12, XZR, 5), emit("ADD_X_IMM", 0, SP, PARSE_M), emit("MOVZ_X", 1, 0, 1), emit("MOVZ_X", 2),
    emit("BL", to=label("bn_set")), emit("SUBS_X_IMM", XZR, 12, 0), emit("ADD_X_IMM", 13, SP, PARSE_N),
    emit("ADD_X_IMM", 16, SP, PARSE_M), emit("CSEL_X", 13, 16, 13, CC["LT"]), emit("SUB_X", 6, XZR, 12),
    emit("CSEL_X", 14, 6, 12, CC["LT"]),
    place(L["scale_step"]), emit("CBZ_X", 14, to=label(L["scale_done"])), emit("MOVZ_X", 6, 0, 9), emit("SUBS_X", XZR, 14, 6),
    emit("CSEL_X", 6, 14, 6, CC["LO"]), emit("SUB_X", 14, 14, 6), emit("MOVZ_X", 1, 0, 1), emit("MOVZ_X", 7, 0, 10),
    place(L["power_step"]), emit("MUL_X", 1, 1, 7), emit("SUB_X_IMM", 6, 6, 1), emit("CBNZ_X", 6, to=label(L["power_step"])),
    emit("ORR_X", 0, XZR, 13), emit("MOVZ_X", 2), emit("BL", to=label("bn_muladd")), emit("B", to=label(L["scale_step"])),
    place(L["scale_done"]), emit("ADD_X_IMM", 0, SP, PARSE_N), emit("BL", to=label("bn_bits")), emit("ORR_X", 13, XZR, 4),
    emit("ADD_X_IMM", 0, SP, PARSE_M), emit("BL", to=label("bn_bits")), emit("SUB_X", 13, 13, 4), emit("LDR_X", 5, SP, PARSE_PRECISION),
    emit("ADD_X_IMM", 5, 5, 1), emit("SUB_X", 5, 5, 13), emit("LDR_X", 6, SP, PARSE_T_MAX), emit("SUBS_X", XZR, 5, 6),
    emit("CSEL_X", 5, 5, 6, CC["LT"]), emit("STR_X", 5, SP, PARSE_T), emit("SUBS_X_IMM", XZR, 5, 0),
    emit("B_COND", a3=CC["LT"], to=label(L["shift_negative"])), emit("ADD_X_IMM", 0, SP, PARSE_N), emit("ORR_X", 1, XZR, 5),
    emit("BL", to=label("bn_shift")), emit("B", to=label(L["shift_more"])), place(L["shift_negative"]),
    emit("ADD_X_IMM", 0, SP, PARSE_M), emit("SUB_X", 1, XZR, 5), emit("BL", to=label("bn_shift")),
    place(L["shift_more"]), emit("ADD_X_IMM", 0, SP, PARSE_M), emit("MOVZ_X", 1, 0, 55), emit("BL", to=label("bn_shift")),
    emit("MOVZ_X", 13), emit("MOVZ_X", 14),
    place(L["round_loop"]), emit("ADD_X", 13, 13, 13), emit("ADD_X_IMM", 0, SP, PARSE_N), emit("ADD_X_IMM", 1, SP, PARSE_M),
    emit("BL", to=label("bn_cmp")), emit("B_COND", a3=CC["LO"], to=label(L["round_next"])), emit("ADD_X_IMM", 0, SP, PARSE_N),
    emit("ADD_X_IMM", 1, SP, PARSE_M), emit("BL", to=label("bn_sub")), emit("ADD_X_IMM", 13, 13, 1),
    place(L["round_next"]), emit("SUBS_X_IMM", XZR, 14, 55), emit("B_COND", a3=CC["EQ"], to=label(L["rounds_done"])),
    emit("ADD_X_IMM", 0, SP, PARSE_N), emit("MOVZ_X", 1, 0, 2), emit("MOVZ_X", 2), emit("BL", to=label("bn_muladd")),
    emit("ADD_X_IMM", 14, 14, 1), emit("B", to=label(L["round_loop"])),
    place(L["rounds_done"]), emit("ADD_X_IMM", 0, SP, PARSE_N), emit("BL", to=label("bn_bits")), emit("SUBS_X_IMM", XZR, 4, 0),
    emit("CSINC_W", 12, XZR, XZR, CC["NE"] ^ 1), emit("LDR_X", 5, SP, PARSE_PRECISION), emit("LDR_X", 6, SP, PARSE_T),
    emit("MOVZ_X", 7, 0, 1), emit("ADD_X_IMM", 8, 5, 1), emit("LSLV_X", 8, 7, 8), emit("SUBS_X", XZR, 13, 8),
    emit("B_COND", a3=CC["LO"], to=label(L["wide_done"])), emit("AND_X", 16, 13, 7), emit("ORR_X", 12, 12, 16),
    emit("LSRV_X", 13, 13, 7), emit("SUB_X_IMM", 6, 6, 1),
    place(L["wide_done"]), emit("AND_X", 16, 13, 7), emit("LSRV_X", 14, 13, 7), emit("CBZ_X", 16, to=label(L["half_done"])),
    emit("AND_X", 8, 14, 7), emit("ORR_X", 8, 8, 12), emit("CBZ_X", 8, to=label(L["half_done"])), emit("ADD_X_IMM", 14, 14, 1),
    place(L["half_done"]), emit("LSLV_X", 8, 7, 5), emit("SUBS_X", XZR, 14, 8), emit("B_COND", a3=CC["NE"], to=label(L["carry_done"])),
    emit("LSRV_X", 14, 14, 7), emit("SUB_X_IMM", 6, 6, 1),
    place(L["carry_done"]), emit("SUB_X_IMM", 16, 5, 1), emit("LSLV_X", 8, 7, 16), emit("SUBS_X", XZR, 14, 8),
    emit("B_COND", a3=CC["HS"], to=label(L["normal"])), emit("ORR_X", 0, XZR, 14), emit("B", to=label(L["sign"])),
    place(L["normal"]), emit("SUB_X", 5, 5, 6), emit("LDR_X", 6, SP, PARSE_BIAS), emit("ADD_X", 5, 5, 6),
    emit("LDR_X", 6, SP, PARSE_MAX_EXPONENT), emit("SUBS_X", XZR, 5, 6), emit("B_COND", a3=CC["GE"], to=label(L["malformed"])),
    emit("LSLV_X", 5, 5, 16), emit("SUB_X", 14, 14, 8), emit("ORR_X", 0, 5, 14), emit("B", to=label(L["sign"])),
    place(L["zero"]), emit("MOVZ_X", 0),
    place(L["sign"]), emit("LDR_X", 5, SP, PARSE_NEGATIVE), emit("LDR_X", 6, SP, PARSE_SIGN_SHIFT), emit("LSLV_X", 5, 5, 6),
    emit("ORR_X", 0, 0, 5),
    place(L["ok"]), emit("MOVZ_X", 1, 0, 1), emit("B", to=label(L["parse_return"])),
    place(L["malformed"]), emit("MOVZ_X", 1), emit("MOVZ_X", 0),
    place(L["parse_return"]), emit("LDR_X", 30, SP, 0), emit("ADD_X_IMM", SP, SP, PARSE_FRAME), emit("RET"),
]


EMIT_TEMPLATES = [
    ("PROLOGUE", [emit("ORR_X", 25, XZR, 0), emit("ORR_X", 26, XZR, 1), emit("MOVZ_X", 22)]),
    ("RESERVE", [
        emit("MOVZ_X", 0), li(1, "reservation"), emit("MOVZ_X", 2), emit("MOVZ_X", 3, 0, 0x1002), emit("ORN_X", 4, XZR, XZR),
        emit("MOVZ_X", 5), *system_call(197), emit("B_COND", a3=CC["HS"], to=label("reserve_failed")),
        emit("ORR_X", 24, XZR, 0),
    ]),
    ("WINDOW", [
        li(9, "window_offset"), emit("ADD_X", 0, 24, 9), emit("ADRP", 8, to=("WINDOW", "row")),
        emit("STR_X", 0, 8, to=("WINDOW", "row")), li(1, "window_bytes"), emit("MOVZ_X", 2, 0, 3), *system_call(74),
        emit("B_COND", a3=CC["HS"], to=label("reserve_failed")),
    ]),
    ("JUMP_STEP", [emit("B", to=label("step"))]),
    ("RESERVE_FAILED", [
        place("reserve_failed"), emit("MOVZ_X", 0, 0, 2), emit("ADRP", 1, to=("RESERVE_TEXT", 0)),
        emit("ADD_X_IMM", 1, 1, to=("RESERVE_TEXT", 0)), emit("MOVZ_X", 2, 0, 26), *system_call(4), emit("MOVZ_X", 0, 0, 3),
        *system_call(1),
    ]),
    ("READ_VALUE", [
        place("read_value"), emit("LDRB_W_REG", 9, 21, 19), emit("SUBS_W_IMM", XZR, 9, 32),
        emit("B_COND", a3=CC["NE"], to=label("malformed")), emit("ADD_X_IMM", 19, 19, 1), emit("MOVZ_X", 11),
        emit("LDRB_W_REG", 9, 21, 19), emit("SUBS_W_IMM", XZR, 9, 45), emit("B_COND", a3=CC["NE"], to=label("local0")),
        emit("MOVZ_X", 11, 0, 1), emit("ADD_X_IMM", 19, 19, 1), place("local0"), emit("MOVZ_X", 0), emit("MOVZ_X", 12),
        emit("MOVZ_X", 13, 0, 10), place("local1"), emit("LDRB_W_REG", 9, 21, 19), emit("SUB_W_IMM", 9, 9, 48),
        emit("SUBS_W_IMM", XZR, 9, 9), emit("B_COND", a3=CC["HI"], to=label("local2")), emit("UMULH_X", 14, 0, 13),
        emit("CBNZ_X", 14, to=label("malformed")), emit("MUL_X", 0, 0, 13), emit("ADDS_X", 0, 0, 9),
        emit("B_COND", a3=CC["HS"], to=label("malformed")), emit("ADD_X_IMM", 19, 19, 1), emit("ADD_X_IMM", 12, 12, 1),
        emit("B", to=label("local1")), place("local2"), emit("CBZ_X", 12, to=label("malformed")),
        emit("SUBS_X_IMM", XZR, 12, 20), emit("B_COND", a3=CC["HI"], to=label("malformed")),
        emit("CBZ_X", 11, to=label("local3")), emit("SUB_X", 0, XZR, 0), place("local3"), emit("RET"),
    ]),
    ("STEP", [place("step"), emit("ADD_X_IMM", 22, 22, 1)]),
    ("READ_LINE", [
        emit("ADRP", 21, to=("IN", 0)), emit("ADD_X_IMM", 21, 21, to=("IN", 0)), emit("MOVZ_X", 19), place("local0"),
        emit("MOVZ_X", 0), emit("ADD_X", 1, 21, 19), emit("MOVZ_X", 2, 0, 1), *system_call(3),
        emit("B_COND", a3=CC["HS"], to=label("malformed")), emit("CBNZ_X", 0, to=label("local1")),
        emit("CBNZ_X", 19, to=label("malformed")), emit("MOVZ_X", 0), *system_call(1), place("local1"),
        emit("LDRB_W_REG", 9, 21, 19), emit("SUBS_W_IMM", XZR, 9, 10), emit("B_COND", a3=CC["EQ"], to=label("local2")),
        emit("ADD_X_IMM", 19, 19, 1), li(11, "line_capacity"), emit("SUBS_X", XZR, 19, 11),
        emit("B_COND", a3=CC["LS"], to=label("local0")), emit("B", to=label("malformed")), place("local2"),
        li(11, "root_count"), emit("SUBS_X", XZR, 19, 11), emit("B_COND", a3=CC["LO"], to=label("malformed")),
        emit("MOVZ_X", 19), place("local3"), emit("SUBS_X", XZR, 19, 11), emit("B_COND", a3=CC["EQ"], to=label("local4")),
        emit("LDRB_W_REG", 9, 21, 19), emit("SUB_W_IMM", 9, 9, 48), emit("SUBS_W_IMM", XZR, 9, 1),
        emit("B_COND", a3=CC["HI"], to=label("malformed")), emit("ADD_X_IMM", 19, 19, 1), emit("B", to=label("local3")),
        place("local4"),
    ]),
    ("VALUE_INPUT", [
        li(10, "input_root_position"), emit("LDRB_W_REG", 9, 21, 10), emit("SUBS_W_IMM", XZR, 9, 49),
        emit("B_COND", a3=CC["NE"], to=label("local0")), emit("BL", to=label("read_value")),
        emit("CBNZ_X", 11, to=label("malformed"), when="bounded"), li(12, "input_bound", "bounded"),
        emit("SUBS_X", XZR, 0, 12, when="bounded"), emit("B_COND", a3=CC["HS"], to=label("malformed"), when="bounded"),
        st(0, ("SIG", "row"), "type_row"), place("local0"),
    ]),
    ("VALUE_INPUT_REAL", [
        li(10, "input_root_position"), emit("LDRB_W_REG", 9, 21, 10), emit("SUBS_W_IMM", XZR, 9, 49),
        emit("B_COND", a3=CC["NE"], to=label("local0")), li(12, "real_bytes"), emit("BL", to=label("read_real_value")),
        emit("CBZ_X", 1, to=label("malformed")), st(0, ("SIG", "row"), "type_row"), place("local0"),
    ]),
    ("VALUE_INPUT_ARRAY", [
        li(10, "input_root_position"), emit("LDRB_W_REG", 9, 21, 10), emit("SUBS_W_IMM", XZR, 9, 49),
        emit("B_COND", a3=CC["NE"], to=label("local0")), address(27, "key_row"), emit("MOVZ_X", 23), place("local1"),
        emit("BL", to=label("read_value"), when="reads_integer"), li(12, "real_bytes", "reads_real"),
        emit("BL", to=label("read_real_value"), when="reads_real"), emit("CBZ_X", 1, to=label("malformed"), when="reads_real"),
        emit("CBNZ_X", 11, to=label("malformed"), when="bounded"),
        li(12, "input_bound", "bounded"), emit("SUBS_X", XZR, 0, 12, when="bounded"),
        emit("B_COND", a3=CC["HS"], to=label("malformed"), when="bounded"), emit("store_indexed_element", 0, 27, 23),
        emit("ADD_X_IMM", 23, 23, 1), li(11, "size_row"), emit("SUBS_X", XZR, 23, 11), emit("B_COND", a3=CC["LO"], to=label("local1")),
        place("local0"),
    ]),
    ("READ_TAIL", [
        emit("LDRB_W_REG", 9, 21, 19), emit("SUBS_W_IMM", XZR, 9, 10), emit("B_COND", a3=CC["EQ"], to=label("read_done")),
        place("malformed"), emit("MOVZ_X", 0, 0, 2), emit("ADRP", 1, to=("MALFORMED_TEXT", 0)),
        emit("ADD_X_IMM", 1, 1, to=("MALFORMED_TEXT", 0)), emit("MOVZ_X", 2, 0, 33), *system_call(4),
        emit("ADRP", 20, to=("OUT", 0)), emit("ADD_X_IMM", 20, 20, to=("OUT", 0)), emit("ORR_X", 0, XZR, 22),
        emit("BL", to=label("put_int")), emit("MOVZ_W", 10, 0, 10), emit("STRB_W_POST", 10, 20, 1), emit("MOVZ_X", 0, 0, 2),
        emit("ADRP", 1, to=("OUT", 0)), emit("ADD_X_IMM", 1, 1, to=("OUT", 0)), emit("SUB_X", 2, 20, 1), *system_call(4),
        emit("MOVZ_X", 0, 0, 2), *system_call(1), place("read_done"),
    ]),
    ("LOOP_HEAD", [ld(9, ("CLK", "clock_loop"), UINTEGER_TYPE), emit("CBZ_W", 9, to=label("loop_end"))]),
    ("LOOP_MID", [
        emit("MOVZ_X", 23), *loop_bound("counted"), emit("SUBS_X", XZR, 23, 11, when="counted"),
        emit("B_COND", a3=CC["GE"], to=label("loop_end"), when="counted"), emit("B", to=label("loop_end"), when="empty"),
        place("loop_start"),
    ]),
    ("SNAPSHOT", copy_words("key_a_row", "key_p_row", "words_row", "local0")),
    ("LOOP_TAIL", [
        emit("ADD_X_IMM", 23, 23, 1), *loop_bound("counted"), li(11, "loop_size", "uncounted"), emit("SUBS_X", XZR, 23, 11),
        emit("B_COND", a3=CC["LO"], to=label("loop_start")), place("loop_end"),
    ]),
    ("CLOCK_ROOT_READ", [
        li(10, "root_position"), emit("LDRB_W_REG", 9, 21, 10), emit("SUBS_W_IMM", XZR, 9, 49),
        emit("CSINC_W", 9, XZR, XZR, CC["EQ"] ^ 1), st(9, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("CLOCK_ROOT", [emit("MOVZ_W", 9, 0, 1), st(9, ("CLK", "row"), UINTEGER_TYPE)]),
    ("CLOCK_SAMPLE", [
        ld(9, ("CLK", "node_parent"), UINTEGER_TYPE), operand(10, "node_left"), emit("AND_W", 9, 9, 10),
        st(9, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("CLOCK_PAIR", [
        ld(9, ("CLK", "node_left"), UINTEGER_TYPE), ld(10, ("CLK", "node_right"), UINTEGER_TYPE),
        emit("pair_form", 9, 9, 10), st(9, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("ROW_SEED_ARRAY", gated(copy_words("key_left", "key_a_right", "words_row", "local1"), False)),
    ("ROW_SEED", gated([operand(9, "left"), *widen(9, "left_widens"), st(9, ("SIG", "right"), "type_row")], False)),
    ("ROW_SEED_FILL", gated([
        operand(9, "left"), *widen(9, "left_widens"), address(12, "key_a_right"), li(10, "size_row"), place("local1"), emit("SUBS_X_IMM", 10, 10, 1),
        emit("store_indexed_element", 9, 12, 10), emit("CBNZ_X", 10, to=label("local1")),
    ], False)),
    ("ROW_LOAD", gated([operand(9, "arg0"), emit("load_param", 9, 9, 0)])),
    ("ROW_STORE", gated([operand(9, "arg0"), operand(10, "arg1"), emit("store_param", 10, 9, 0)], False)),
    ("ROW_SYSCALL", gated([
        *[operand(register, f"arg{register + 1}", f"has_arg{register + 1}") for register in range(6)],
        operand(16, "arg0"), emit("SVC_80"), emit("CSNEG_X", 9, 0, 0, CC["HS"] ^ 1),
    ])),
    ("ROW_INSTRUCTION", gated([operand(0, "arg0"), emit("WORD", a2="param"), emit("ORR_X", 9, XZR, 0)])),
    ("ROW_WRITE", gated([
        operand(1, "arg0"), *string_length(2, 1), emit("BL", to=label("put_text")),
        operand(1, "arg1", "writes_string"), *string_length(2, 1, "writes_string"),
        emit("BL", to=label("put_text"), when="writes_string"), emit("SUB_X_IMM", SP, SP, 32, when="writes_complex"),
        emit("SUB_X_IMM", SP, SP, 32), emit("ADD_X_IMM", 20, SP, 0),
        operand(0, "arg1", "writes_number"), emit("BL", to=label("put_param"), when="writes_number"),
        emit("MOVZ_W", 10, 0, 32, when="writes_complex"), emit("STRB_W_POST", 10, 20, 1, when="writes_complex"),
        operand(0, "arg2", "writes_complex"), emit("BL", to=label("put_param"), when="writes_complex"),
        operand(0, "arg1", "writes_char"), emit("BL", to=label("put_char"), when="writes_char"),
        emit("MOVZ_W", 10, 0, 10), emit("STRB_W_POST", 10, 20, 1), emit("ADD_X_IMM", 1, SP, 0), emit("SUB_X", 2, 20, 1),
        emit("BL", to=label("put_text")), emit("ADD_X_IMM", SP, SP, 32), emit("ADD_X_IMM", SP, SP, 32, when="writes_complex"),
    ], False)),
    ("ROW_READ", gated([
        operand(1, "arg0"), *string_length(2, 1), emit("BL", to=label("put_text")),
        address(13, "key_string_value", "reads_string"), emit("ADD_X_IMM", 1, 13, 8, when="reads_string"),
        emit("MOVZ_X", 2, 0, READ_STRING_CAPACITY & 0xFFFF, when="reads_string"),
        emit("MOVK_X", 2, 0, READ_STRING_CAPACITY >> 16, 1, when="reads_string"), emit("BL", to=label("read_line"), when="reads_string"),
        address(13, "key_string_value", "reads_string"), emit("STR_X", 0, 13, 0, when="reads_string"),
        emit("ADD_X_IMM", 9, 13, 8, when="reads_string"), emit("STRB_W_REG", XZR, 9, 0, when="reads_string"),
        st(9, ("SIG", "row"), "type_row", "reads_string"),
        emit("SUB_X_IMM", SP, SP, 32, when="reads_scalar"), emit("SUB_X_IMM", SP, SP, READ_REAL_BYTES, when="reads_real"),
        emit("SUB_X_IMM", SP, SP, 2 * READ_REAL_BYTES, when="reads_complex"),
        emit("ADD_X_IMM", 1, SP, 0, when="reads_scalar"),
        emit("MOVZ_X", 2, 0, 21, when="reads_number"), emit("MOVZ_X", 2, 0, 2, when="reads_char"),
        emit("MOVZ_X", 2, 0, READ_REAL_BYTES, when="reads_real"), emit("MOVZ_X", 2, 0, 2 * READ_REAL_BYTES + 1, when="reads_complex"),
        emit("BL", to=label("read_line"), when="reads_scalar"), emit("ADD_X_IMM", 1, SP, 0, when="reads_scalar"),
        emit("BL", to=label("read_number"), when="reads_number"), emit("ORR_X", 9, XZR, 0, when="reads_number"),
        emit("ORR_X", 13, XZR, 1, when="reads_real"), emit("ORR_X", 14, XZR, 0, when="reads_real"),
        li(12, "real_bytes", "reads_real"), emit("BL", to=label("parse_real"), when="reads_real"),
        emit("CBZ_X", 1, to=label("read_malformed"), when="reads_real"), emit("ORR_X", 9, XZR, 0, when="reads_real"),
        emit("STR_X", 0, SP, 2 * READ_REAL_BYTES + 8, when="reads_complex"), emit("MOVZ_X", 15, when="reads_complex"),
        place("local4", "reads_complex"), emit("SUBS_X", XZR, 15, 0, when="reads_complex"),
        emit("B_COND", a3=CC["HS"], to=label("read_malformed"), when="reads_complex"),
        emit("LDRB_W_REG", 9, 1, 15, when="reads_complex"), emit("SUBS_W_IMM", XZR, 9, 32, when="reads_complex"),
        emit("B_COND", a3=CC["EQ"], to=label("local5"), when="reads_complex"), emit("ADD_X_IMM", 15, 15, 1, when="reads_complex"),
        emit("B", to=label("local4"), when="reads_complex"), place("local5", "reads_complex"),
        emit("STR_X", 15, SP, 2 * READ_REAL_BYTES + 16, when="reads_complex"),
        emit("ORR_X", 13, XZR, 1, when="reads_complex"), emit("ORR_X", 14, XZR, 15, when="reads_complex"),
        li(12, "real_bytes", "reads_complex"), emit("BL", to=label("parse_real"), when="reads_complex"),
        emit("CBZ_X", 1, to=label("read_malformed"), when="reads_complex"),
        emit("STR_X", 0, SP, 2 * READ_REAL_BYTES + 24, when="reads_complex"),
        emit("LDR_X", 15, SP, 2 * READ_REAL_BYTES + 16, when="reads_complex"), emit("ADD_X_IMM", 15, 15, 1, when="reads_complex"),
        emit("ADD_X_IMM", 13, SP, 0, when="reads_complex"), emit("ADD_X", 13, 13, 15, when="reads_complex"), emit("LDR_X", 14, SP, 2 * READ_REAL_BYTES + 8, when="reads_complex"),
        emit("SUB_X", 14, 14, 15, when="reads_complex"),
        li(12, "real_bytes", "reads_complex"), emit("BL", to=label("parse_real"), when="reads_complex"),
        emit("CBZ_X", 1, to=label("read_malformed"), when="reads_complex"), st(0, ("SIG", "imag_row"), "type_row", "reads_complex"),
        emit("LDR_X", 9, SP, 2 * READ_REAL_BYTES + 24, when="reads_complex"),
        emit("SUBS_X_IMM", XZR, 9, 1, when="reads_boolean"),
        emit("B_COND", a3=CC["HI"], to=label("read_malformed"), when="reads_boolean"),
        emit("LDRB_W", 9, 1, 0, when="reads_char"), emit("SUBS_X_IMM", XZR, 0, 1, when="reads_char"),
        emit("B_COND", a3=CC["NE"], to=label("local2"), when="reads_char"), emit("SUBS_X_IMM", XZR, 9, 128, when="reads_char"),
        emit("B_COND", a3=CC["HS"], to=label("read_malformed"), when="reads_char"),
        emit("B", to=label("local3"), when="reads_char"), place("local2", "reads_char"),
        emit("SUBS_X_IMM", XZR, 0, 2, when="reads_char"), emit("B_COND", a3=CC["NE"], to=label("read_malformed"), when="reads_char"),
        emit("SUBS_X_IMM", XZR, 9, 0xC2, when="reads_char"), emit("B_COND", a3=CC["LO"], to=label("read_malformed"), when="reads_char"),
        emit("SUBS_X_IMM", XZR, 9, 0xC3, when="reads_char"), emit("B_COND", a3=CC["HI"], to=label("read_malformed"), when="reads_char"),
        emit("LDRB_W", 10, 1, 1, when="reads_char"), emit("SUBS_X_IMM", XZR, 10, 0x80, when="reads_char"),
        emit("B_COND", a3=CC["LO"], to=label("read_malformed"), when="reads_char"),
        emit("SUBS_X_IMM", XZR, 10, 0xBF, when="reads_char"), emit("B_COND", a3=CC["HI"], to=label("read_malformed"), when="reads_char"),
        emit("MOVZ_X", 11, 0, 0x1F, when="reads_char"), emit("AND_X", 9, 9, 11, when="reads_char"),
        emit("MOVZ_X", 11, 0, 6, when="reads_char"), emit("LSLV_X", 9, 9, 11, when="reads_char"),
        emit("MOVZ_X", 11, 0, 0x3F, when="reads_char"), emit("AND_X", 10, 10, 11, when="reads_char"),
        emit("ORR_X", 9, 9, 10, when="reads_char"), place("local3", "reads_char"),
        emit("ADD_X_IMM", SP, SP, READ_REAL_BYTES, when="reads_real"),
        emit("ADD_X_IMM", SP, SP, 2 * READ_REAL_BYTES, when="reads_complex"), emit("ADD_X_IMM", SP, SP, 32, when="reads_scalar"),
        st(9, ("SIG", "row"), "type_row", "reads_scalar"),
    ], False)),
    ("ROW_ITER_RANGE", gated([
        emit("ORR_X", 9, XZR, 23, when="iter_whole"), li(10, "iter_stride", "iter_divides"),
        emit("UDIV_X", 9, 23, 10, when="iter_divides"), li(10, "iter_size", "iter_wraps"),
        emit("UDIV_X", 11, 9, 10, when="iter_wraps"), emit("MSUB_X", 9, 11, 10, 9, when="iter_wraps"),
        li(10, "iter_start", "iter_offset"), emit("ADD_X", 9, 9, 10, when="iter_offset"),
    ])),
    ("ROW_ITER", gated([
        address(12, "key_left"), emit("load_indexed_row", 9, 12, 23, when="iter_plain"),
        li(10, "iter_stride", "iter_divides"), emit("UDIV_X", 13, 23, 10, when="iter_divides"),
        emit("ORR_X", 13, XZR, 23, when="iter_derived_whole"), li(10, "iter_size", "iter_wraps"),
        emit("UDIV_X", 11, 13, 10, when="iter_wraps"), emit("MSUB_X", 13, 11, 10, 13, when="iter_wraps"),
        emit("load_indexed_row", 9, 12, 13, when="iter_derived"),
    ])),
    ("ROW_PREV", gated([ld(9, ("SIG", "left"), "type_row")])),
    ("ROW_ELEMENT", gated([
        address(12, "key_left"), operand(10, "right"), li(11, "size_left"), emit("MOVZ_X", 9), emit("SUBS_X", XZR, 10, 11),
        emit("B_COND", a3=CC["HS"], to=label("local1")), emit("load_indexed_row", 9, 12, 10), place("local1"),
    ])),
    ("ROW_GATHER", gated([
        address(12, "key_left"), address(13, "key_right"), address(14, "key_owner"), emit("MOVZ_X", 15), place("local1"),
        emit("load_indexed_index", 10, 13, 15), emit("MOVZ_X", 9), li(11, "size_left"), emit("SUBS_X", XZR, 10, 11),
        emit("B_COND", a3=CC["HS"], to=label("local2")), emit("load_indexed_element", 9, 12, 10), place("local2"),
        emit("store_indexed_element", 9, 14, 15), emit("ADD_X_IMM", 15, 15, 1), li(17, "size_row"),
        emit("SUBS_X", XZR, 15, 17), emit("B_COND", a3=CC["LO"], to=label("local1")),
    ], False)),
    ("ROW_NEXT", gated([
        *copy_words("key_left", "key_owner", "words_row", "local1", "keys_differ"), address(12, "key_owner"),
        operand(10, "right_left"), operand(9, "right_right"), *widen(9, "right_right_widens"), li(11, "size_row"),
        emit("SUBS_X", XZR, 10, 11), emit("B_COND", a3=CC["HS"], to=label("local2")), emit("store_indexed_element", 9, 12, 10),
        place("local2"),
    ], False)),
    ("ROW_PUT", gated([
        *copy_words("key_left", "key_owner", "words_row", "local1", "keys_differ"), address(12, "key_owner"),
        li(10, "value_row"), operand(9, "right"), *widen(9, "right_widens"), emit("store_indexed_element", 9, 12, 10),
    ], False)),
    ("ROW_RESTRUCTURE", gated([
        address(13, "key_owner"), li(15, "words_row"), place("local1"), emit("STR_X_POST", XZR, 13, 8),
        emit("SUBS_X_IMM", 15, 15, 1), emit("B_COND", a3=CC["NE"], to=label("local1")), address(12, "key_owner"),
        operand(10, "right"), operand(9, "left"), *widen(9, "left_widens"), li(11, "size_row"), emit("SUBS_X", XZR, 10, 11),
        emit("B_COND", a3=CC["HS"], to=label("local2")), emit("store_indexed_element", 9, 12, 10), place("local2"),
    ], False)),
    ("ROW_SCATTER", gated([
        address(13, "key_owner"), li(15, "words_row"), place("local1"), emit("STR_X_POST", XZR, 13, 8),
        emit("SUBS_X_IMM", 15, 15, 1), emit("B_COND", a3=CC["NE"], to=label("local1")),
        address(12, "key_left"), address(13, "key_right"), address(14, "key_owner"), emit("MOVZ_X", 15), place("local2"),
        emit("load_indexed_index", 10, 13, 15), li(11, "size_row"), emit("SUBS_X", XZR, 10, 11),
        emit("B_COND", a3=CC["HS"], to=label("local3")), emit("load_indexed_element", 9, 12, 15),
        emit("store_indexed_element", 9, 14, 10), place("local3"), emit("ADD_X_IMM", 15, 15, 1), li(17, "size_left"),
        emit("SUBS_X", XZR, 15, 17), emit("B_COND", a3=CC["LO"], to=label("local2")),
    ], False)),
    ("ROW_CONCAT", gated([
        address(12, "key_left"), address(13, "key_right"), address(14, "key_owner"), emit("MOVZ_X", 15), li(17, "size_left"),
        place("local1"), emit("load_indexed_element", 9, 12, 15), emit("store_indexed_element", 9, 14, 15),
        emit("ADD_X_IMM", 15, 15, 1), emit("SUBS_X", XZR, 15, 17), emit("B_COND", a3=CC["LO"], to=label("local1")),
        place("local2"), li(17, "size_left"), emit("SUB_X", 16, 15, 17), emit("load_indexed_element", 9, 13, 16),
        emit("store_indexed_element", 9, 14, 15), emit("ADD_X_IMM", 15, 15, 1), li(17, "size_row"),
        emit("SUBS_X", XZR, 15, 17), emit("B_COND", a3=CC["LO"], to=label("local2")),
    ], False)),
    ("ROW_ARRAY_EQ", gated([
        address(12, "key_left"), address(13, "key_right"), emit("MOVZ_X", 15), li(17, "size_left"), place("local1"),
        emit("load_indexed_index", 10, 12, 15), emit("load_indexed_index", 11, 13, 15),
        emit("SUBS_X", XZR, 10, 11, when="index_integer"), emit("real_in", 16, 10, when="index_real"),
        emit("real_in", 17, 11, when="index_real"), emit("real_cmp", 0, 16, 17, when="index_real"),
        emit("B_COND", a3=CC["NE"], to=label("local2")), emit("ADD_X_IMM", 15, 15, 1), emit("SUBS_X", XZR, 15, 17),
        emit("B_COND", a3=CC["LO"], to=label("local1")), emit("MOVZ_X", 9, 0, 1), emit("B", to=label("local3")),
        place("local2"), emit("MOVZ_X", 9), place("local3"), emit("EOR_X_ONE", 9, 9, when="compare_negated"),
    ])),
    ("ROW_STRING_EQ", gated([
        operand(12, "left"), operand(13, "right"), *string_length(10, 12), *string_length(11, 13), emit("SUBS_X", XZR, 10, 11),
        emit("B_COND", a3=CC["NE"], to=label("local2")), emit("MOVZ_X", 15), place("local1"), emit("SUBS_X", XZR, 15, 10),
        emit("B_COND", a3=CC["HS"], to=label("local3")), emit("LDRB_W_REG", 16, 12, 15), emit("LDRB_W_REG", 17, 13, 15),
        emit("SUBS_X", XZR, 16, 17), emit("B_COND", a3=CC["NE"], to=label("local2")), emit("ADD_X_IMM", 15, 15, 1),
        emit("B", to=label("local1")), place("local3"), emit("MOVZ_X", 9, 0, 1), emit("B", to=label("local4")), place("local2"),
        emit("MOVZ_X", 9), place("local4"), emit("EOR_X_ONE", 9, 9, when="compare_negated"),
    ])),
    ("ROW_STRING_LT", gated([
        operand(12, "left", "compare_direct"), operand(13, "right", "compare_direct"),
        operand(12, "right", "compare_swapped"), operand(13, "left", "compare_swapped"), *string_length(10, 12),
        *string_length(11, 13), emit("SUBS_X", XZR, 10, 11), emit("CSEL_X", 14, 10, 11, CC["LO"]), emit("MOVZ_X", 15),
        place("local1"), emit("SUBS_X", XZR, 15, 14), emit("B_COND", a3=CC["HS"], to=label("local2")),
        emit("LDRB_W_REG", 16, 12, 15), emit("LDRB_W_REG", 17, 13, 15), emit("SUBS_X", XZR, 16, 17),
        emit("B_COND", a3=CC["NE"], to=label("local3")), emit("ADD_X_IMM", 15, 15, 1), emit("B", to=label("local1")),
        place("local2"), emit("SUBS_X", XZR, 10, 11), place("local3"), emit("CSINC_W", 9, XZR, XZR, CC["HS"]),
        emit("EOR_X_ONE", 9, 9, when="compare_negated"),
    ])),
    ("ROW_IF_BLOCK", gated([
        operand(9, "left"), emit("CBZ_W", 9, to=label("local1")),
        *copy_words("key_right_left", "key_owner", "words_row", "local2"), emit("B", to=label("local3")), place("local1"),
        *copy_words("key_right_right", "key_owner", "words_row", "local4"), place("local3"),
    ], False)),
    ("ROW_GATHER2", gated([
        address(12, "key_left"), address(13, "key_right_left"), address(16, "key_right_right"), address(14, "key_owner"),
        emit("MOVZ_X", 15), place("local1"), emit("load_indexed_index", 10, 13, 15), emit("load_indexed_index", 11, 16, 15),
        li(17, "value_row"), emit("SUBS_X", XZR, 11, 17), emit("B_COND", a3=CC["HS"], to=label("local2")),
        li(9, "size_left"), emit("SUBS_X", XZR, 10, 9), emit("B_COND", a3=CC["HS"], to=label("local2")),
        emit("MUL_X", 10, 10, 17), emit("ADD_X", 10, 10, 11), emit("SUBS_X", XZR, 10, 9),
        emit("B_COND", a3=CC["HS"], to=label("local2")), emit("load_indexed_element", 9, 12, 10), emit("B", to=label("local3")),
        place("local2"), emit("MOVZ_X", 9), place("local3"), emit("store_indexed_element", 9, 14, 15),
        emit("ADD_X_IMM", 15, 15, 1), li(17, "size_row"), emit("SUBS_X", XZR, 15, 17), emit("B_COND", a3=CC["LO"], to=label("local1")),
    ], False)),
    ("ROW_EACH_STORE", gated([address(12, "key_owner"), operand(9, "left"), emit("store_indexed_element", 9, 12, 23)], False)),
    ("ROW_DEFAULT_ARRAY", gated([
        ld(11, ("CLK", "clock_left"), UINTEGER_TYPE), emit("CBZ_W", 11, to=label("local1")),
        *copy_words("key_left", "key_owner", "words_row", "local2"), emit("B", to=label("local3")), place("local1"),
        *copy_words("key_right", "key_owner", "words_row", "local4"), place("local3"),
    ], False)),
    ("ROW_TRANSPOSE", gated([
        address(12, "key_left"), address(14, "key_owner"), emit("MOVZ_X", 15), emit("MOVZ_X", 16), emit("MOVZ_X", 10),
        place("local1"), emit("load_indexed_element", 9, 12, 10), emit("store_indexed_element", 9, 14, 15),
        emit("ADD_X_IMM", 15, 15, 1), li(17, "value_row"), emit("ADD_X", 10, 10, 17), li(17, "size_left"),
        emit("SUBS_X", XZR, 10, 17), emit("B_COND", a3=CC["LO"], to=label("local2")),
        emit("ADD_X_IMM", 16, 16, 1), emit("ADD_X_IMM", 10, 16, 0), place("local2"),
        li(17, "size_row"), emit("SUBS_X", XZR, 15, 17), emit("B_COND", a3=CC["LO"], to=label("local1")),
    ], False)),
    ("ROW_MATPROD", gated([
        address(12, "key_left"), address(13, "key_right"), address(14, "key_owner"), emit("MOVZ_X", 15), emit("MOVZ_X", 16),
        emit("MOVZ_X", 11), place("local1"), emit("MOVZ_X", 9), emit("ADD_X_IMM", 10, 16, 0), emit("ADD_X_IMM", 17, 11, 0),
        place("local2"), emit("load_indexed_element", 0, 12, 10), emit("load_indexed_element", 1, 13, 17),
        emit("MUL_X", 0, 0, 1), emit("ADD_X", 9, 9, 0), emit("ADD_X_IMM", 10, 10, 1), li(2, "value_row"),
        emit("ADD_X", 17, 17, 2), li(2, "size_right"), emit("SUBS_X", XZR, 17, 2), emit("B_COND", a3=CC["LO"], to=label("local2")),
        emit("store_indexed_element", 9, 14, 15), emit("ADD_X_IMM", 15, 15, 1), emit("ADD_X_IMM", 11, 11, 1),
        li(2, "value_row"), emit("SUBS_X", XZR, 11, 2), emit("B_COND", a3=CC["LO"], to=label("local3")),
        emit("MOVZ_X", 11), emit("ADD_X_IMM", 16, 10, 0), place("local3"),
        li(2, "size_row"), emit("SUBS_X", XZR, 15, 2), emit("B_COND", a3=CC["LO"], to=label("local1")),
    ], False)),
    ("ROW_DOT", gated([
        address(12, "key_left"), address(13, "key_right"), emit("MOVZ_X", 9), emit("MOVZ_X", 15), place("local1"),
        emit("load_indexed_row", 0, 12, 15), emit("load_indexed_row", 1, 13, 15), emit("MUL_X", 0, 0, 1),
        emit("ADD_X", 9, 9, 0), emit("ADD_X_IMM", 15, 15, 1), li(2, "size_left"), emit("SUBS_X", XZR, 15, 2),
        emit("B_COND", a3=CC["LO"], to=label("local1")),
    ])),
    ("ROW_CONST", gated([operand(9, "row")])),
    ("ROW_DELAY", gated([ld(9, ("MEM", "row"), "type_row")])),
    ("ROW_STATE", gated([ld(9, ("MEM", "value_row"), "type_row")])),
    ("ROW_DELAY_STRING", gated([
        ld(10, ("MEM", "row"), "type_row"), address(13, "key_string_value"), *copy_string(10, 13, "local1"), emit("ORR_X", 9, XZR, 13),
    ])),
    ("ROW_STATE_STRING", gated([
        ld(10, ("MEM", "value_row"), "type_row"), address(13, "key_string_value"), *copy_string(10, 13, "local1"),
        emit("ORR_X", 9, XZR, 13),
    ])),
    ("ROW_ONE", gated([emit("MOVZ_X", 9, 0, 1)])),
    ("ROW_IF", gated([
        operand(9, "left"), operand(10, "right_left"), *widen(10, "right_left_widens"), operand(11, "right_right"),
        *widen(11, "right_right_widens"), emit("SUBS_X_IMM", XZR, 9, 0), emit("CSEL_X", 9, 10, 11, CC["NE"]),
    ])),
    ("ROW_DEFAULT", gated([
        ld(11, ("CLK", "clock_left"), UINTEGER_TYPE), operand(9, "left"), *widen(9, "left_widens"), operand(10, "right"),
        *widen(10, "right_widens"), emit("SUBS_W_IMM", XZR, 11, 0), emit("CSEL_X", 9, 9, 10, CC["NE"]),
    ])),
    ("ROW_PLAIN", gated(generic())),
    ("ROW_NEG", gated(generic(emit("SUB_X", 9, XZR, 9)))),
    ("ROW_NOT_LOGICAL", gated(generic(emit("EOR_X_ONE", 9, 9)))),
    ("ROW_NOT", gated(generic(emit("ORN_X", 9, XZR, 9)))),
    ("ROW_BINARY", gated(generic(emit("instruction_op", 9, 9, 10)))),
    ("ROW_DIV_SIGNED", gated(generic(emit("SDIV_X", 9, 9, 10)))),
    ("ROW_DIV", gated(generic(emit("UDIV_X", 9, 9, 10)))),
    ("ROW_COMPARE_SIGNED", gated(generic(emit("SUBS_X", XZR, 9, 10), emit("CSINC_W", 9, XZR, XZR, "signed_condition")))),
    ("ROW_COMPARE", gated(generic(emit("SUBS_X", XZR, 9, 10), emit("CSINC_W", 9, XZR, XZR, "unsigned_condition")))),
    ("ROW_MOD_SIGNED", gated(generic(
        emit("SDIV_X", 11, 9, 10), emit("MSUB_X", 11, 11, 10, 9), emit("SUBS_X_IMM", XZR, 10, 0),
        emit("CSNEG_X", 12, 10, 10, CC["LT"] ^ 1), emit("ADD_X", 12, 11, 12), emit("SUBS_X_IMM", XZR, 11, 0),
        emit("CSEL_X", 9, 12, 11, CC["LT"]),
    ))),
    ("ROW_MOD", gated(generic(emit("UDIV_X", 11, 9, 10), emit("MSUB_X", 9, 11, 10, 9)))),
    ("ROW_REAL_BINARY", gated(generic(
        emit("real_in", 16, 9), emit("real_in", 17, 10), emit("real_op", 16, 16, 17), emit("real_out", 9, 16),
    ))),
    ("ROW_REAL_IMAG", gated([operand(9, "right"), *widen(9, "right_widens")])),
    ("ROW_REAL_FMA_S", gated(fused_multiply_add("S"))),
    ("ROW_REAL_FMA_D", gated(fused_multiply_add("D"))),
    ("ROW_REAL_COPYSIGN_S", gated(copy_sign(1))),
    ("ROW_REAL_COPYSIGN_D", gated(copy_sign(3))),
    ("ROW_REAL_MODU_S", gated(complex_modulus_template(True))),
    ("ROW_REAL_MODU_D", gated(complex_modulus_template(False))),
    *[(f"ROW_REAL_MATH_{function.upper().replace("'", "_")}", gated(math_template(function))) for function in MATH_UNARY + MATH_BINARY],
    ("ROW_REAL_MATH_ARG", gated(complex_argument_template())),
    ("ROW_REAL_NEG", gated(generic(emit("real_in", 16, 9), emit("real_neg", 16, 16), emit("real_out", 9, 16)))),
    ("ROW_REAL_COMPARE", gated(generic(
        emit("real_in", 16, 9), emit("real_in", 17, 10), emit("real_cmp", 0, 16, 17), emit("CSINC_W", 9, XZR, XZR, "real_condition"),
    ))),
    ("ROW_REAL_FROM_INT", gated(generic(emit("real_from_int", 16, 9), emit("real_out", 9, 16)))),
    ("ROW_REAL_TO_INT", gated(generic(emit("real_in", 16, 9), emit("real_to_int", 9, 16)))),
    ("ROW_REAL_NARROW", gated(generic(emit("FMOV_D_X", 16, 9), emit("FCVT_S_D", 16, 16), emit("FMOV_W_S", 9, 16)))),
    ("ROW_SHIFT", gated(generic(
        emit("SUBS_X_IMM", XZR, 10, 64), emit("shift_op", 11, 9, 10), emit("CSEL_X", 9, 11, XZR, CC["LO"]),
    ))),
    ("DELAY", [
        ld(9, ("CLK", "clock_row"), UINTEGER_TYPE), emit("CBZ_W", 9, to=label("local0")),
        ld(9, ("SIG", "left"), "type_row"), st(9, ("MEM", "row"), "type_row"), place("local0"),
    ]),
    ("DELAY_STRING", [
        ld(9, ("CLK", "clock_row"), UINTEGER_TYPE), emit("CBZ_W", 9, to=label("local0")),
        ld(10, ("SIG", "left"), "type_row"), address(13, "key_string_mem"), *copy_string(10, 13, "local1"),
        st(13, ("MEM", "row"), "type_row"), place("local0"),
    ]),
    ("SEED_STRING", [address(9, "key_string_init"), st(9, ("MEM", "row"), "type_row")]),
    ("OUTPUT_HEAD", [emit("ADRP", 20, to=("OUT", 0)), emit("ADD_X_IMM", 20, 20, to=("OUT", 0))]),
    ("OUTPUT", [
        emit("MOVZ_W", 10, 0, 32, when="flag"), emit("STRB_W_POST", 10, 20, 1, when="flag"),
        ld(9, ("CLK", "clock_row"), UINTEGER_TYPE), emit("CBZ_W", 9, to=label("local0")), ld(0, ("SIG", "row"), "type_row"),
        emit("BL", to=label("put_output")), emit("B", to=label("local1")), place("local0"), emit("MOVZ_W", 10, 0, 45),
        emit("STRB_W_POST", 10, 20, 1), place("local1"),
    ]),
    ("OUTPUT_ARRAY", [
        emit("MOVZ_W", 10, 0, 32, when="flag"), emit("STRB_W_POST", 10, 20, 1, when="flag"),
        ld(9, ("CLK", "clock_row"), UINTEGER_TYPE), emit("CBZ_W", 9, to=label("local0")), address(27, "key_row"),
        emit("MOVZ_X", 23), place("local2"), emit("CBZ_X", 23, to=label("local3")), emit("MOVZ_W", 10, 0, 32),
        emit("STRB_W_POST", 10, 20, 1), place("local3"), emit("load_indexed_element", 0, 27, 23),
        emit("BL", to=label("put_output")), emit("ADD_X_IMM", 23, 23, 1), li(11, "size_row"), emit("SUBS_X", XZR, 23, 11),
        emit("B_COND", a3=CC["LO"], to=label("local2")), emit("B", to=label("local1")), place("local0"),
        emit("MOVZ_W", 10, 0, 45), emit("STRB_W_POST", 10, 20, 1), place("local1"),
    ]),
    ("OUTPUT_TAIL", [
        emit("MOVZ_W", 10, 0, 10), emit("STRB_W_POST", 10, 20, 1), emit("ADRP", 1, to=("OUT", 0)),
        emit("ADD_X_IMM", 1, 1, to=("OUT", 0)), emit("SUB_X", 2, 20, 1), emit("MOVZ_X", 0, 0, 1), *system_call(4),
    ]),
    ("FINISH", [
        emit("B", to=label("step")), *PUT_NUMBER, place("put_bool"),
        emit("CBZ_W", 0, to=label("local2")), emit("MOVZ_W", 9, 0, 0x7274), emit("MOVK_W", 9, 0, 0x6575, 1),
        emit("STR_W_POST", 9, 20, 4), emit("RET"), place("local2"), emit("MOVZ_W", 9, 0, 0x6166),
        emit("MOVK_W", 9, 0, 0x736C, 1), emit("STR_W_POST", 9, 20, 4), emit("MOVZ_W", 9, 0, 101),
        emit("STRB_W_POST", 9, 20, 1), emit("RET"),
    ]),
    ("CYCLE_VALUE", [ld(9, ("CLK", "clock_row"), UINTEGER_TYPE), operand(10, "row"), emit("AND_W", 9, 9, 10)]),
    ("CYCLE_JUMP_TRUE", [emit("CBZ_W", 9, to=label("copy_next"))]),
    ("CYCLE_JUMP_FALSE", [emit("CBNZ_X", 9, to=label("copy_next"))]),
    ("CYCLE_CLOSE", [emit("B", to=label("copy_end")), place("copy_next")]),
    ("CYCLE_DONE", [place("copy_end")]),
    ("REAL_RUNTIME", REAL_RUNTIME),
    ("REAL_PARSE", REAL_PARSE),
    ("PUT_TEXT", [place("put_text"), emit("MOVZ_X", 0, 0, 1), *system_call(4), emit("RET"), *PUT_CHAR]),
    ("READ_INPUT", [
        place("read_line"), emit("ORR_X", 20, XZR, 1), emit("ORR_X", 28, XZR, 2), emit("MOVZ_X", 19),
        emit("SUB_X_IMM", SP, SP, 16), place("local0"), emit("MOVZ_X", 0), emit("ADD_X_IMM", 1, SP, 0), emit("MOVZ_X", 2, 0, 1),
        *system_call(3), emit("B_COND", a3=CC["HS"], to=label("read_malformed")), emit("CBNZ_X", 0, to=label("local1")),
        emit("CBNZ_X", 19, to=label("read_malformed")), emit("MOVZ_X", 0), *system_call(1), place("local1"),
        emit("LDRB_W", 9, SP, 0), emit("SUBS_W_IMM", XZR, 9, 10), emit("B_COND", a3=CC["EQ"], to=label("local2")),
        emit("SUBS_X", XZR, 19, 28), emit("B_COND", a3=CC["HS"], to=label("read_malformed")), emit("STRB_W_REG", 9, 20, 19),
        emit("ADD_X_IMM", 19, 19, 1), emit("B", to=label("local0")), place("local2"), emit("ADD_X_IMM", SP, SP, 16),
        emit("ORR_X", 0, XZR, 19), emit("RET"),
        place("read_malformed"), emit("SUB_X_IMM", SP, SP, 64), emit("ADD_X_IMM", 20, SP, 0),
        *put_bytes("read input malformed at step "), emit("ORR_X", 0, XZR, 22), emit("BL", to=label("put_int")),
        emit("MOVZ_W", 10, 0, 10), emit("STRB_W_POST", 10, 20, 1), emit("MOVZ_X", 0, 0, 2), emit("ADD_X_IMM", 1, SP, 0),
        emit("SUB_X", 2, 20, 1), *system_call(4), emit("MOVZ_X", 0, 0, 2), *system_call(1),
    ]),
    ("READ_NUMBER", [
        place("read_number"), emit("ORR_X", 13, XZR, 1), emit("ORR_X", 14, XZR, 0), emit("MOVZ_X", 15), emit("MOVZ_X", 11),
        emit("CBZ_X", 14, to=label("read_malformed")), emit("LDRB_W_REG", 9, 13, 15), emit("SUBS_W_IMM", XZR, 9, 45),
        emit("B_COND", a3=CC["NE"], to=label("local0")), emit("MOVZ_X", 11, 0, 1), emit("ADD_X_IMM", 15, 15, 1),
        place("local0"), emit("MOVZ_X", 0), emit("MOVZ_X", 12), emit("MOVZ_X", 10, 0, 10), place("local1"),
        emit("SUBS_X", XZR, 15, 14), emit("B_COND", a3=CC["HS"], to=label("local2")), emit("LDRB_W_REG", 9, 13, 15),
        emit("SUB_W_IMM", 9, 9, 48), emit("SUBS_W_IMM", XZR, 9, 9), emit("B_COND", a3=CC["HI"], to=label("read_malformed")),
        emit("UMULH_X", 16, 0, 10), emit("CBNZ_X", 16, to=label("read_malformed")), emit("MUL_X", 0, 0, 10),
        emit("ADDS_X", 0, 0, 9), emit("B_COND", a3=CC["HS"], to=label("read_malformed")), emit("ADD_X_IMM", 15, 15, 1),
        emit("ADD_X_IMM", 12, 12, 1), emit("B", to=label("local1")), place("local2"),
        emit("CBZ_X", 12, to=label("read_malformed")), emit("SUBS_X_IMM", XZR, 12, 20),
        emit("B_COND", a3=CC["HI"], to=label("read_malformed")), emit("CBZ_X", 11, to=label("local3")), emit("SUB_X", 0, XZR, 0),
        place("local3"), emit("RET"),
    ]),
]



EMIT_TEMPLATES += [
    ("PROLOGUE_VIRT", [
        emit("ADRP", 9, to=("STACK", 0)), emit("ADD_X_IMM", 9, 9, to=("STACK", 0)), emit("ADD_X_IMM", SP, 9, 0),
        emit("MOVZ_X", 22), emit("MOVZ_X", 9, 0, 0x30, 1), emit("MSR_CPACR", 9), emit("ISB"),
    ]),
    ("WINDOW_VIRT", [
        emit("ADRP", 0, to=("TAIL", "row")), emit("ADD_X_IMM", 0, 0, to=("TAIL", "row")), emit("ADRP", 8, to=("WINDOW", "row")),
        emit("STR_X", 0, 8, to=("WINDOW", "row")),
    ]),
    ("BOOT", [emit("MOVZ_X", 21, 0, BOOT_ID), emit("B", to=label("step"))]),
    ("WAIT", [place("wait"), emit("WFI"), emit("MOVZ_X", 9, 0, GICC_PAGE, 1), emit("LDR_W", 21, 9, GICC_IAR)]),
    ("DISPATCH", [
        emit("SUBS_W_IMM", XZR, 21, "row", when="flag"), emit("B_COND", a3=CC["EQ"], to=label("step"), when="flag"),
    ]),
    ("WAIT_TAIL", [
        place("complete"), emit("SUBS_W_IMM", XZR, 21, SPECIAL_ID), emit("B_COND", a3=CC["HS"], to=label("wait")),
        emit("MOVZ_X", 9, 0, GICC_PAGE, 1), emit("STR_W", 21, 9, GICC_EOIR), emit("B", to=label("wait")),
    ]),
    ("CLOCK_ROOT_VIRT", [
        emit("SUBS_W_IMM", XZR, 21, "root_irq"), emit("CSINC_W", 9, XZR, XZR, CC["EQ"] ^ 1),
        st(9, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("OUTPUT_TAIL_VIRT", [
        emit("MOVZ_W", 10, 0, 10), emit("STRB_W_POST", 10, 20, 1), emit("ADRP", 1, to=("OUT", 0)),
        emit("ADD_X_IMM", 1, 1, to=("OUT", 0)), emit("SUB_X", 2, 20, 1), emit("MOVZ_X", 9, 0, UART_PAGE, 1), emit("MOVZ_X", 11),
        place("local0"), emit("LDRB_W_REG", 10, 1, 11), emit("STR_W", 10, 9, 0), emit("ADD_X_IMM", 11, 11, 1),
        emit("SUBS_X", XZR, 11, 2), emit("B_COND", a3=CC["NE"], to=label("local0")),
    ]),
    ("PUT_TEXT_VIRT", [
        place("put_text"), emit("MOVZ_X", 9, 0, UART_PAGE, 1), emit("MOVZ_X", 11), place("local1"), emit("SUBS_X", XZR, 11, 2),
        emit("B_COND", a3=CC["HS"], to=label("local2")), emit("LDRB_W_REG", 10, 1, 11), emit("STR_W", 10, 9, 0),
        emit("ADD_X_IMM", 11, 11, 1), emit("B", to=label("local1")), place("local2"), emit("RET"), *PUT_CHAR,
    ]),
    ("FINISH_VIRT", [
        emit("B", to=label("complete")), *PUT_NUMBER,
        place("put_bool"), emit("CBZ_W", 0, to=label("local2")), *put_bytes("true"), emit("RET"), place("local2"),
        *put_bytes("false"), emit("RET"),
    ]),
]


THUMB_SUFFIX = "_THUMB"
LR = 14
SP_T = 13
PC_T = 15
UART0 = 0x40004000
ICSR = 0xE000ED04
NVIC_ICPR0 = 0xE000E280
PENDSTCLR = 0x02000000
MPS2_UNLOADED = 84
MPS2_HEADER_BYTES = 92
MPS2_RAM_BYTES = 0x400000
MPS2_STACK_BYTES = 64
VIRT_STACK_BYTES = 1536


def runtime_stack_depths(*step_lists):
    frames, edges, entries = {}, {}, []
    for steps in step_lists:
        owner_of_local, jumps, current, falls = {}, [], None, False
        for row in steps:
            kind, form, a0, a1, a2, target_name = row[0], row[2], row[3], row[4], row[5], row[8]
            if kind == "PLACE" and not a0.startswith("local"):
                if current is not None and falls:
                    edges[current].add(a0)
                current = a0
                entries.append(current)
                frames[current], edges[current] = 0, set()
            elif kind == "PLACE" and current is not None:
                owner_of_local[a0] = current
            elif kind == "EMIT" and current is not None:
                if form == "SUB_X_IMM" and a0 == SP and a1 == SP:
                    frames[current] += a2
                elif form == "BL":
                    edges[current].add(target_name)
                elif form in ("B", "B_COND", "CBZ_W", "CBZ_X", "CBNZ_X"):
                    jumps.append((current, target_name))
                falls = form not in ("B", "RET")
        for source, target_name in jumps:
            target = owner_of_local.get(target_name, target_name)
            if target != source and target in frames:
                edges[source].add(target)
    depths = {}

    def depth(name, open_names):
        if name in open_names:
            raise SystemExit(f"tables.py: runtime routine {name} recurses")
        if name not in depths:
            callees = [callee for callee in edges[name] if callee in frames]
            depths[name] = frames[name] + max((depth(callee, open_names | {name}) for callee in callees), default=0)
        return depths[name]

    return {name: depth(name, frozenset()) for name in entries}


RUNTIME_STACK_DEPTHS = runtime_stack_depths(REAL_RUNTIME, REAL_PARSE, PUT_NUMBER)
DEEPEST_RUNTIME_ROUTINE = max(RUNTIME_STACK_DEPTHS, key=RUNTIME_STACK_DEPTHS.get)
if RUNTIME_STACK_DEPTHS[DEEPEST_RUNTIME_ROUTINE] > VIRT_STACK_BYTES:
    raise SystemExit(f"tables.py: {DEEPEST_RUNTIME_ROUTINE} needs {RUNTIME_STACK_DEPTHS[DEEPEST_RUNTIME_ROUTINE]} stack bytes, "
                     f"VIRT_STACK_BYTES is {VIRT_STACK_BYTES}")
PLATFORMS = ["MACOS", "VIRT", "MPS2"]
MACHINE_TEXT = "mps2-an385"
THUMB_LOAD_FORMS = {(1, 0): "LDRB_T", (1, 1): "LDRB_T", (2, 0): "LDRH_T", (2, 1): "LDRSH_T", (4, 0): "LDR_T", (4, 1): "LDR_T",
                    (8, 0): "LDRD_T", (8, 1): "LDRD_T"}
THUMB_STORE_FORMS = {1: "STRB_T", 2: "STRH_T", 4: "STR_T", 8: "STRD_T"}
THUMB_BINARY = {"ADD": ("ADDS_T", "ADC_T"), "SUB": ("SUBS_T", "SBC_T"), "AND": ("AND_T", "AND_T"), "OR": ("ORR_T", "ORR_T"),
                "XOR": ("EOR_T", "EOR_T")}
THUMB_CONDITIONS = {
    "EQ": ("EQ", "EQ"), "NE": ("NE", "NE"), "LT": ("LT", "LO"), "GE": ("GE", "HS"), "GT": ("LT", "LO"), "LE": ("GE", "HS"),
}


def li1(register, value, when="always"):
    return step("LI", when, 0, register, value)


def li2(register, value, when="always"):
    return step("LI", when, 1, register, value)


def ld1(register, target, type_source, when="always"):
    return step("LOAD", when, 0, register, type_source, target=target)


def ld2(register, target, type_source, when="always"):
    return step("LOAD", when, 1, register, type_source, target=target)


def st1(register, target, type_source, when="always"):
    return step("STORE", when, 0, register, type_source, target=target)


def st2(register, target, type_source, when="always"):
    return step("STORE", when, 1, register, type_source, target=target)


def operand1(register, row, when="always"):
    return step("OPERAND", when, 0, register, row)


def operand2(register, row, when="always"):
    return step("OPERAND", when, 1, register, row)


def load_at(register, type_source, base, index, when="always"):
    return step("LOAD_AT", when, 1, register, type_source, base, index)


def store_at(register, type_source, base, index, when="always"):
    return step("STORE_AT", when, 1, register, type_source, base, index)


def movw(register, value, when="always"):
    return emit("MOVW_T", register, 0, value, when=when)


def mov(destination, source, when="always"):
    return emit("MOV_T", destination, source, when=when)


def literal(register, value):
    return [movw(register, value & 0xFFFF), emit("MOVT_T", register, 0, value >> 16)]


def absolute(register, target):
    return [emit("MOVW_ABS_T", register, to=target), emit("MOVT_ABS_T", register, to=target)]


def only_if(condition, when="always"):
    return emit("SKIP_T", a3=CC[condition] ^ 1, when=when)


def branch_if(condition, name, when="always"):
    return [only_if(condition, when), emit("B_W_T", to=label(name), when=when)]


def branch(name, when="always"):
    return emit("B_W_T", to=label(name), when=when)


def compare(register, value, when="always"):
    return emit("SUBS_IMM_T", PC_T, register, value, when=when)


def compare_registers(left, right, when="always"):
    return emit("SUBS_T", PC_T, left, right, when=when)


def compare_pairs(left, right, when="always"):
    return [emit("SUBS_T", LR, left, right, when=when), emit("SBCS_T", LR, left + 1, right + 1, when=when)]


def put_byte(register):
    return emit("STRB_POST_T", register, 10, 1)


def apply_sign(register, sign):
    return [
        emit("EOR_T", register, register, sign), emit("EOR_T", register + 1, register + 1, sign),
        emit("SUBS_T", register, register, sign), emit("SBC_T", register + 1, register + 1, sign),
    ]


def copy_pairs(source_key, destination_key, words, loop_label, when="always"):
    return [
        address(6, source_key, when), address(7, destination_key, when), li1(9, words, when), place(loop_label, when),
        emit("LDRD_POST_T", 0, 6, 8, 1, when=when), emit("STRD_POST_T", 0, 7, 8, 1, when=when),
        emit("SUBS_IMM_T", 9, 9, 1, when=when), *branch_if("NE", loop_label, when),
    ]


def string_length_thumb(register, pointer, when="always"):
    return [emit("SUBS_IMM_T", register, pointer, 4, when=when), emit("LDR_T", register, register, 0, when=when)]


def gated_thumb(body, stores=True):
    return (
        [ld1(0, ("CLK", "clock_row"), UINTEGER_TYPE, "flag"), compare(0, 0, "flag"), *branch_if("EQ", "local0", "flag")]
        + body + ([st2(0, ("SIG", "row"), "type_row")] if stores else []) + [place("local0", "flag")]
    )


def generic_thumb(*tail):
    return [operand2(0, "left"), operand2(2, "right", "right_loads"), *tail]


def loop_bound_thumb(when):
    return [
        operand2(4, "loop_count", when), li2(2, "loop_size_less_one", when), *compare_pairs(4, 2, when),
        emit("SKIP_T", a3="loop_condition", when=when), mov(4, 2, when),
        emit("SKIP_T", a3="loop_condition", when=when), mov(5, 3, when),
        emit("ADDS_IMM_T", 4, 4, 1, when=when), emit("ADC_IMM_T", 5, 5, 0, when=when),
        li1(2, "loop_inner", "nested_counted"), emit("MLA_T", 4, 4, 2, 15, when="nested_counted"),
    ]


def put_bytes_thumb(text):
    return [step_row for byte in text.encode() for step_row in (movw(2, byte), put_byte(2))]


SIGNS = [emit("ASR_IMM_T", 8, 1, 31), emit("ASR_IMM_T", 9, 3, 31), *apply_sign(0, 8), *apply_sign(2, 9)]
SHIFT_LEFT = [
    emit("LSL_T", 4, 1, 2), emit("RSB_IMM_T", 5, 2, 32), emit("LSR_T", 6, 0, 5), emit("ORR_T", 4, 4, 6),
    emit("SUBW_T", 5, 2, 32), emit("LSL_T", 6, 0, 5), emit("ORR_T", 1, 4, 6), emit("LSL_T", 0, 0, 2),
]
SHIFT_RIGHT = [
    emit("LSR_T", 4, 0, 2), emit("RSB_IMM_T", 5, 2, 32), emit("LSL_T", 6, 1, 5), emit("ORR_T", 4, 4, 6),
    emit("SUBW_T", 5, 2, 32), emit("LSR_T", 6, 1, 5), emit("ORR_T", 0, 4, 6), emit("LSR_T", 1, 1, 2),
]
PUT_NUMBER_THUMB = [
    place("put_int"), compare(1, 0), *branch_if("GE", "put_uint"), movw(2, 45), put_byte(2), movw(2, 0),
    emit("SUBS_T", 0, 2, 0), emit("SBC_T", 1, 2, 1),
    place("put_uint"), emit("STR_PRE_DEC_T", LR, SP_T, 8), emit("SUBW_T", SP_T, SP_T, 24), emit("ADDW_T", 12, SP_T, 0),
    place("local0"), movw(2, 10), movw(3, 0), emit("BL_T", to=label("divide")), emit("ADDW_T", 2, 2, 48),
    emit("STRB_POST_T", 2, 12, 1), emit("ORRS_T", 4, 0, 1), *branch_if("NE", "local0"),
    place("local1"), emit("LDRB_PRE_DEC_T", 2, 12, 1), put_byte(2), compare_registers(SP_T, 12), *branch_if("NE", "local1"),
    emit("ADDW_T", SP_T, SP_T, 24), emit("LDR_POST_T", PC_T, SP_T, 8),
]
DIVIDE_THUMB = [
    place("divide"), emit("ORRS_T", 4, 2, 3), only_if("EQ"), mov(2, 0), only_if("EQ"), mov(3, 1), only_if("EQ"), movw(0, 0),
    only_if("EQ"), movw(1, 0), only_if("EQ"), emit("BX_LR_T"), movw(4, 0), movw(5, 0), movw(9, 64), place("local3"),
    emit("ADDS_T", 0, 0, 0), emit("ADCS_T", 1, 1, 1), emit("ADCS_T", 4, 4, 4), emit("ADCS_T", 5, 5, 5), movw(8, 0),
    emit("ADC_IMM_T", 8, 8, 0), emit("SUBS_T", 6, 4, 2), emit("SBCS_T", 7, 5, 3), emit("SBCS_IMM_T", 8, 8, 0),
    only_if("HS"), mov(4, 6), only_if("HS"), mov(5, 7), only_if("HS"), emit("ORR_IMM_T", 0, 0, 1),
    emit("SUBS_IMM_T", 9, 9, 1), *branch_if("NE", "local3"), mov(2, 4), mov(3, 5), emit("BX_LR_T"),
]
COMPARE_FLAGS = [
    emit("EOR_T", 4, 0, 2, when="compare_equal"), emit("EOR_T", 5, 1, 3, when="compare_equal"),
    emit("ORRS_T", 4, 4, 5, when="compare_equal"), *compare_pairs(0, 2, "compare_direct"), *compare_pairs(2, 0, "compare_swapped"),
]


EMIT_TEMPLATES += [
    ("PROLOGUE_THUMB", [
        movw(0, 1), emit("MSR_PRIMASK_T"), *literal(6, UART0), movw(0, 16), emit("STR_T", 0, 6, 16), movw(0, 1),
        emit("STR_T", 0, 6, 8),
    ]),
    ("WINDOW_THUMB", [*absolute(0, ("TAIL", "row")), *absolute(LR, ("WINDOW", "row")), emit("STR_T", 0, LR, 0)]),
    ("BOOT_THUMB", [movw(11, BOOT_ID), branch("step")]),
    ("WAIT_THUMB", [
        place("wait"), emit("WFI_T"), *literal(6, ICSR), emit("LDR_T", 11, 6, 0), emit("LSL_IMM_T", 11, 11, 11),
        emit("LSR_IMM_T", 11, 11, 23), compare(11, 15), *branch_if("LO", "wait"),
    ]),
    ("DISPATCH_THUMB", [compare(11, "row", "flag"), *branch_if("EQ", "step", "flag")]),
    ("WAIT_TAIL_THUMB", [
        place("complete"), compare(11, 15), *branch_if("NE", "local0"), *literal(6, ICSR), *literal(0, PENDSTCLR),
        emit("STR_T", 0, 6, 0), branch("wait"), place("local0"), compare(11, 48), *branch_if("HS", "wait"),
        emit("SUBW_T", 0, 11, 16), movw(1, 1), emit("LSL_T", 1, 1, 0), *literal(6, NVIC_ICPR0), emit("STR_T", 1, 6, 0),
        branch("wait"),
    ]),
    ("STEP_THUMB", [place("step")]),
    ("LOOP_HEAD_THUMB", [ld1(0, ("CLK", "clock_loop"), UINTEGER_TYPE), compare(0, 0), *branch_if("EQ", "loop_end")]),
    ("LOOP_MID_THUMB", [
        movw(12, 0), *loop_bound_thumb("counted"), emit("SUBS_IMM_T", LR, 4, 1, when="counted"),
        emit("SBCS_IMM_T", LR, 5, 0, when="counted"), *branch_if("LT", "loop_end", "counted"), branch("loop_end", "empty"),
        place("loop_start"),
    ]),
    ("SNAPSHOT_THUMB", copy_pairs("key_a_row", "key_p_row", "words_row", "local0")),
    ("LOOP_TAIL_THUMB", [
        emit("ADDW_T", 12, 12, 1), *loop_bound_thumb("counted"), li1(4, "loop_size", "uncounted"), compare_registers(12, 4),
        *branch_if("LO", "loop_start"), place("loop_end"),
    ]),
    ("CLOCK_ROOT_THUMB", [
        li1(6, "root_irq"), compare_registers(11, 6), movw(0, 0), only_if("EQ"), movw(0, 1),
        st1(0, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("CLOCK_SAMPLE_THUMB", [
        ld1(0, ("CLK", "node_parent"), UINTEGER_TYPE), operand1(2, "node_left"), emit("AND_T", 0, 0, 2),
        st1(0, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("CLOCK_PAIR_THUMB", [
        ld1(0, ("CLK", "node_left"), UINTEGER_TYPE), ld1(2, ("CLK", "node_right"), UINTEGER_TYPE),
        emit("pair_form_thumb", 0, 0, 2), st1(0, ("CLK", "row"), UINTEGER_TYPE),
    ]),
    ("ROW_SEED_ARRAY_THUMB", gated_thumb(copy_pairs("key_left", "key_a_right", "words_row", "local1"), False)),
    ("ROW_SEED_THUMB", gated_thumb([operand2(0, "left"), st2(0, ("SIG", "right"), "type_row")], False)),
    ("ROW_SEED_FILL_THUMB", gated_thumb([
        operand2(0, "left"), address(6, "key_a_right"), li1(4, "size_row"), place("local1"), emit("SUBS_IMM_T", 4, 4, 1),
        store_at(0, "element_row", 6, 4), compare(4, 0), *branch_if("NE", "local1"),
    ], False)),
    ("ROW_LOAD_THUMB", gated_thumb([operand1(0, "arg0"), load_at(0, "param", 0, -1)])),
    ("ROW_STORE_THUMB", gated_thumb([operand1(6, "arg0"), operand2(2, "arg1"), store_at(2, "param", 6, -1)], False)),
    ("ROW_INSTRUCTION_THUMB", gated_thumb([operand2(0, "arg0"), emit("WORD_T", a2="param")])),
    ("ROW_ITER_RANGE_THUMB", gated_thumb([
        mov(0, 12, "iter_whole"), li1(2, "iter_stride", "iter_divides"), emit("UDIV_T", 0, 12, 2, when="iter_divides"),
        li1(2, "iter_size", "iter_wraps"), emit("UDIV_T", 3, 0, 2, when="iter_wraps"),
        emit("MLS_T", 0, 3, 2, 0, when="iter_wraps"), movw(1, 0), li2(2, "iter_start", "iter_offset"),
        emit("ADDS_T", 0, 0, 2, when="iter_offset"), emit("ADC_T", 1, 1, 3, when="iter_offset"),
    ])),
    ("ROW_ITER_THUMB", gated_thumb([
        address(6, "key_left"), load_at(0, "type_row", 6, 12, "iter_plain"), li1(2, "iter_stride", "iter_divides"),
        emit("UDIV_T", 4, 12, 2, when="iter_divides"), mov(4, 12, "iter_derived_whole"),
        li1(2, "iter_size", "iter_wraps"), emit("UDIV_T", 3, 4, 2, when="iter_wraps"),
        emit("MLS_T", 4, 3, 2, 4, when="iter_wraps"), load_at(0, "type_row", 6, 4, "iter_derived"),
    ])),
    ("ROW_PREV_THUMB", gated_thumb([ld2(0, ("SIG", "left"), "type_row")])),
    ("ROW_ELEMENT_THUMB", gated_thumb([
        address(6, "key_left"), operand2(2, "right"), li2(4, "size_left"), movw(0, 0), movw(1, 0), *compare_pairs(2, 4),
        *branch_if("HS", "local1"), load_at(0, "type_row", 6, 2), place("local1"),
    ])),
    ("ROW_GATHER_THUMB", gated_thumb([
        address(6, "key_left"), address(7, "key_right"), address(8, "key_owner"), movw(9, 0), place("local1"),
        load_at(2, "index_element", 7, 9), movw(0, 0), movw(1, 0), li2(4, "size_left"), *compare_pairs(2, 4),
        *branch_if("HS", "local2"), load_at(0, "element_row", 6, 2), place("local2"), store_at(0, "element_row", 8, 9),
        emit("ADDW_T", 9, 9, 1), li1(LR, "size_row"), compare_registers(9, LR), *branch_if("LO", "local1"),
    ], False)),
    ("ROW_NEXT_THUMB", gated_thumb([
        *copy_pairs("key_left", "key_owner", "words_row", "local1", "keys_differ"), address(6, "key_owner"),
        operand2(2, "right_left"), operand2(0, "right_right"), li2(4, "size_row"), *compare_pairs(2, 4),
        *branch_if("HS", "local2"), store_at(0, "element_row", 6, 2), place("local2"),
    ], False)),
    ("ROW_PUT_THUMB", gated_thumb([
        *copy_pairs("key_left", "key_owner", "words_row", "local1", "keys_differ"), address(6, "key_owner"),
        li2(2, "value_row"), operand2(0, "right"), store_at(0, "element_row", 6, 2),
    ], False)),
    ("ROW_RESTRUCTURE_THUMB", gated_thumb([
        address(7, "key_owner"), movw(0, 0), movw(1, 0), li1(9, "words_row"), place("local1"),
        emit("STRD_POST_T", 0, 7, 8, 1), emit("SUBS_IMM_T", 9, 9, 1), *branch_if("NE", "local1"), address(6, "key_owner"),
        operand2(2, "right"), operand2(0, "left"), li2(4, "size_row"), *compare_pairs(2, 4),
        *branch_if("HS", "local2"), store_at(0, "element_row", 6, 2), place("local2"),
    ], False)),
    ("ROW_SCATTER_THUMB", gated_thumb([
        address(7, "key_owner"), movw(0, 0), movw(1, 0), li1(9, "words_row"), place("local1"),
        emit("STRD_POST_T", 0, 7, 8, 1), emit("SUBS_IMM_T", 9, 9, 1), *branch_if("NE", "local1"),
        address(6, "key_left"), address(7, "key_right"), address(8, "key_owner"), movw(9, 0), place("local2"),
        load_at(2, "index_element", 7, 9), li2(4, "size_row"), *compare_pairs(2, 4), *branch_if("HS", "local3"),
        load_at(0, "element_row", 6, 9), store_at(0, "element_row", 8, 2), place("local3"),
        emit("ADDW_T", 9, 9, 1), li1(LR, "size_left"), compare_registers(9, LR), *branch_if("LO", "local2"),
    ], False)),
    ("ROW_CONCAT_THUMB", gated_thumb([
        address(6, "key_left"), address(7, "key_right"), address(8, "key_owner"), movw(9, 0), place("local1"),
        load_at(0, "element_row", 6, 9), store_at(0, "element_row", 8, 9), emit("ADDW_T", 9, 9, 1), li1(LR, "size_left"),
        compare_registers(9, LR), *branch_if("LO", "local1"), place("local2"), li1(LR, "size_left"), emit("SUBS_T", 2, 9, LR),
        load_at(0, "element_row", 7, 2), store_at(0, "element_row", 8, 9), emit("ADDW_T", 9, 9, 1), li1(LR, "size_row"),
        compare_registers(9, LR), *branch_if("LO", "local2"),
    ], False)),
    ("ROW_ARRAY_EQ_THUMB", gated_thumb([
        address(6, "key_left"), address(7, "key_right"), movw(9, 0), place("local1"), load_at(0, "index_element", 6, 9),
        load_at(2, "index_element", 7, 9), compare_registers(0, 2), *branch_if("NE", "local2"), compare_registers(1, 3),
        *branch_if("NE", "local2"), emit("ADDW_T", 9, 9, 1), li1(LR, "size_left"), compare_registers(9, LR),
        *branch_if("LO", "local1"), movw(0, 1), movw(1, 0), branch("local3"), place("local2"), movw(0, 0), movw(1, 0),
        place("local3"), emit("EOR_IMM_T", 0, 0, 1, when="compare_negated"),
    ])),
    ("ROW_STRING_EQ_THUMB", gated_thumb([
        operand1(6, "left"), operand1(7, "right"), *string_length_thumb(4, 6), *string_length_thumb(5, 7), compare_registers(4, 5),
        *branch_if("NE", "local2"), place("local1"), compare(4, 0), *branch_if("EQ", "local3"), emit("LDRB_POST_T", 0, 6, 1),
        emit("LDRB_POST_T", 2, 7, 1), compare_registers(0, 2), *branch_if("NE", "local2"), emit("SUBS_IMM_T", 4, 4, 1),
        branch("local1"), place("local3"), movw(0, 1), movw(1, 0), branch("local4"), place("local2"), movw(0, 0), movw(1, 0),
        place("local4"), emit("EOR_IMM_T", 0, 0, 1, when="compare_negated"),
    ])),
    ("ROW_STRING_LT_THUMB", gated_thumb([
        operand1(6, "left", "compare_direct"), operand1(7, "right", "compare_direct"),
        operand1(6, "right", "compare_swapped"), operand1(7, "left", "compare_swapped"), *string_length_thumb(4, 6),
        *string_length_thumb(5, 7), mov(8, 4), compare_registers(5, 4), only_if("LO"), mov(8, 5), place("local1"),
        compare(8, 0), *branch_if("EQ", "local2"), emit("LDRB_POST_T", 0, 6, 1), emit("LDRB_POST_T", 2, 7, 1),
        compare_registers(0, 2), *branch_if("NE", "local3"), emit("SUBS_IMM_T", 8, 8, 1), branch("local1"), place("local2"),
        compare_registers(4, 5), place("local3"), movw(0, 0), movw(1, 0), *branch_if("HS", "local4"), movw(0, 1),
        place("local4"), emit("EOR_IMM_T", 0, 0, 1, when="compare_negated"),
    ])),
    ("ROW_IF_BLOCK_THUMB", gated_thumb([
        operand1(0, "left"), compare(0, 0), *branch_if("EQ", "local1"),
        *copy_pairs("key_right_left", "key_owner", "words_row", "local2"), branch("local3"), place("local1"),
        *copy_pairs("key_right_right", "key_owner", "words_row", "local4"), place("local3"),
    ], False)),
    ("ROW_GATHER2_THUMB", gated_thumb([
        address(6, "key_left"), address(7, "key_right_left"), address(8, "key_owner"), movw(9, 0), place("local1"),
        load_at(2, "index_element", 7, 9), address(5, "key_right_right"), load_at(4, "index_element", 5, 9),
        li2(0, "value_row"), *compare_pairs(4, 0), *branch_if("HS", "local2"), li2(0, "size_left"), *compare_pairs(2, 0),
        *branch_if("HS", "local2"), li1(LR, "value_row"), emit("UMULL_T", 0, 2, LR, 1), emit("ADDS_T", 0, 0, 4),
        emit("ADC_T", 1, 1, 5), li2(2, "size_left"), *compare_pairs(0, 2), *branch_if("HS", "local2"), mov(2, 0),
        load_at(0, "element_row", 6, 2), branch("local3"), place("local2"), movw(0, 0), movw(1, 0), place("local3"),
        store_at(0, "element_row", 8, 9), emit("ADDW_T", 9, 9, 1), li1(LR, "size_row"), compare_registers(9, LR),
        *branch_if("LO", "local1"),
    ], False)),
    ("ROW_EACH_STORE_THUMB", gated_thumb([address(6, "key_owner"), operand2(0, "left"), store_at(0, "element_row", 6, 12)], False)),
    ("ROW_DEFAULT_ARRAY_THUMB", gated_thumb([
        ld1(4, ("CLK", "clock_left"), UINTEGER_TYPE), compare(4, 0), *branch_if("EQ", "local1"),
        *copy_pairs("key_left", "key_owner", "words_row", "local2"), branch("local3"), place("local1"),
        *copy_pairs("key_right", "key_owner", "words_row", "local4"), place("local3"),
    ], False)),
    ("ROW_TRANSPOSE_THUMB", gated_thumb([
        address(6, "key_left"), address(7, "key_owner"), movw(9, 0), movw(12, 0), movw(8, 0), place("local1"),
        load_at(0, "element_row", 6, 8), store_at(0, "element_row", 7, 9), emit("ADDW_T", 9, 9, 1),
        li1(2, "value_row"), emit("ADDS_T", 8, 8, 2), li1(2, "size_left"), compare_registers(8, 2), *branch_if("LO", "local2"),
        emit("ADDW_T", 12, 12, 1), mov(8, 12), place("local2"),
        li1(2, "size_row"), compare_registers(9, 2), *branch_if("LO", "local1"),
    ], False)),
    ("ROW_MATPROD_THUMB", gated_thumb([
        movw(0, 0), emit("STR_PRE_DEC_T", 0, SP_T, 8), address(6, "key_left"), movw(8, 0), movw(9, 0), place("local1"),
        movw(4, 0), movw(5, 0), emit("LDR_T", 12, SP_T, 0), place("local2"),
        load_at(0, "element_row", 6, 12), address(7, "key_right"), load_at(2, "element_row", 7, 9),
        emit("MLA_T", 5, 0, 3, 5), emit("MLA_T", 5, 1, 2, 5), emit("UMULL_T", 1, 0, 2, 3), emit("ADDS_T", 4, 4, 1),
        emit("ADC_T", 5, 5, 3), emit("ADDW_T", 12, 12, 1), li1(0, "value_row"), emit("ADDS_T", 9, 9, 0),
        li1(0, "size_right"), compare_registers(9, 0), *branch_if("LO", "local2"),
        address(7, "key_owner"), store_at(4, "element_row", 7, 8), emit("ADDW_T", 8, 8, 1),
        li1(0, "size_right"), emit("SUBS_T", 9, 9, 0), emit("ADDW_T", 9, 9, 1), li1(0, "value_row"),
        compare_registers(9, 0), *branch_if("LO", "local3"), movw(9, 0), emit("STR_T", 12, SP_T, 0), place("local3"),
        li1(0, "size_row"), compare_registers(8, 0), *branch_if("LO", "local1"), emit("LDR_POST_T", 0, SP_T, 8),
    ], False)),
    ("ROW_DOT_THUMB", gated_thumb([
        address(6, "key_left"), movw(4, 0), movw(5, 0), movw(9, 0), place("local1"),
        load_at(0, "type_row", 6, 9), address(7, "key_right"), load_at(2, "type_row", 7, 9),
        emit("MLA_T", 5, 0, 3, 5), emit("MLA_T", 5, 1, 2, 5), emit("UMULL_T", 1, 0, 2, 3), emit("ADDS_T", 4, 4, 1),
        emit("ADC_T", 5, 5, 3), emit("ADDW_T", 9, 9, 1), li1(0, "size_left"), compare_registers(9, 0),
        *branch_if("LO", "local1"), mov(0, 4), mov(1, 5),
    ])),
    ("ROW_CONST_THUMB", gated_thumb([operand2(0, "row")])),
    ("ROW_DELAY_THUMB", gated_thumb([ld2(0, ("MEM", "row"), "type_row")])),
    ("ROW_STATE_THUMB", gated_thumb([ld2(0, ("MEM", "value_row"), "type_row")])),
    ("ROW_ONE_THUMB", gated_thumb([movw(0, 1), movw(1, 0)])),
    ("ROW_IF_THUMB", gated_thumb([
        operand1(0, "left"), operand2(2, "right_left"), operand2(4, "right_right"), compare(0, 0), mov(0, 4), mov(1, 5),
        only_if("NE"), mov(0, 2), only_if("NE"), mov(1, 3),
    ])),
    ("ROW_DEFAULT_THUMB", gated_thumb([
        ld1(4, ("CLK", "clock_left"), UINTEGER_TYPE), operand2(0, "left"), operand2(2, "right"), compare(4, 0),
        only_if("EQ"), mov(0, 2), only_if("EQ"), mov(1, 3),
    ])),
    ("ROW_PLAIN_THUMB", gated_thumb(generic_thumb())),
    ("ROW_NEG_THUMB", gated_thumb(generic_thumb(movw(LR, 0), emit("SUBS_T", 0, LR, 0), emit("SBC_T", 1, LR, 1)))),
    ("ROW_NOT_LOGICAL_THUMB", gated_thumb(generic_thumb(emit("EOR_IMM_T", 0, 0, 1)))),
    ("ROW_NOT_THUMB", gated_thumb(generic_thumb(emit("MVN_T", 0, 0), emit("MVN_T", 1, 1)))),
    ("ROW_BINARY_THUMB", gated_thumb(generic_thumb(
        emit("binary_lo", 0, 0, 2, when="not_mul"), emit("binary_hi", 1, 1, 3, when="not_mul"),
        emit("UMULL_T", 4, 0, 2, 5, when="mul"), emit("MLA_T", 5, 0, 3, 5, when="mul"), emit("MLA_T", 5, 1, 2, 5, when="mul"),
        mov(0, 4, "mul"), mov(1, 5, "mul"),
    ))),
    ("ROW_DIV_SIGNED_THUMB", gated_thumb(generic_thumb(
        *SIGNS, emit("EOR_T", 8, 8, 9), emit("STR_PRE_DEC_T", 8, SP_T, 8), emit("BL_T", to=label("divide")),
        emit("LDR_POST_T", 8, SP_T, 8), *apply_sign(0, 8),
    ))),
    ("ROW_DIV_THUMB", gated_thumb(generic_thumb(emit("BL_T", to=label("divide"))))),
    ("ROW_COMPARE_SIGNED_THUMB", gated_thumb(generic_thumb(
        *COMPARE_FLAGS, movw(0, 0), movw(1, 0), emit("SKIP_T", a3="signed_condition_thumb"), movw(0, 1),
    ))),
    ("ROW_COMPARE_THUMB", gated_thumb(generic_thumb(
        *COMPARE_FLAGS, movw(0, 0), movw(1, 0), emit("SKIP_T", a3="unsigned_condition_thumb"), movw(0, 1),
    ))),
    ("ROW_MOD_SIGNED_THUMB", gated_thumb(generic_thumb(
        *SIGNS, emit("STR_PRE_DEC_T", 3, SP_T, 4), emit("STR_PRE_DEC_T", 2, SP_T, 4), emit("STR_PRE_DEC_T", 8, SP_T, 8), emit("BL_T", to=label("divide")),
        emit("LDR_POST_T", 8, SP_T, 8), emit("LDRD_POST_T", 4, SP_T, 8, 5), mov(0, 2), mov(1, 3), *apply_sign(0, 8),
        compare(1, 0), *branch_if("GE", "local1"), emit("ADDS_T", 0, 0, 4), emit("ADC_T", 1, 1, 5), place("local1"),
    ))),
    ("ROW_MOD_THUMB", gated_thumb(generic_thumb(emit("BL_T", to=label("divide")), mov(0, 2), mov(1, 3)))),
    ("ROW_SHIFT_THUMB", gated_thumb(generic_thumb(
        *[step_row[:1] + ("shift_left",) + step_row[2:] for step_row in SHIFT_LEFT],
        *[step_row[:1] + ("shift_right",) + step_row[2:] for step_row in SHIFT_RIGHT],
        emit("SUBS_IMM_T", LR, 2, 64), emit("SBCS_IMM_T", LR, 3, 0), only_if("HS"), movw(0, 0), only_if("HS"), movw(1, 0),
    ))),
    ("SEED_STRING_THUMB", [address(0, "key_string_init"), st1(0, ("MEM", "row"), "type_row")]),
    ("DELAY_THUMB", [
        ld1(0, ("CLK", "clock_row"), UINTEGER_TYPE), compare(0, 0), *branch_if("EQ", "local0"),
        ld2(0, ("SIG", "left"), "type_row"), st2(0, ("MEM", "row"), "type_row"), place("local0"),
    ]),
    ("OUTPUT_HEAD_THUMB", absolute(10, ("OUT", 0))),
    ("OUTPUT_THUMB", [
        movw(2, 32, "flag"), emit("STRB_POST_T", 2, 10, 1, when="flag"), ld1(0, ("CLK", "clock_row"), UINTEGER_TYPE),
        compare(0, 0), *branch_if("EQ", "local0"), ld2(0, ("SIG", "row"), "type_row"), emit("BL_T", to=label("put_output")),
        branch("local1"), place("local0"), movw(2, 45), put_byte(2), place("local1"),
    ]),
    ("OUTPUT_ARRAY_THUMB", [
        movw(2, 32, "flag"), emit("STRB_POST_T", 2, 10, 1, when="flag"), ld1(0, ("CLK", "clock_row"), UINTEGER_TYPE),
        compare(0, 0), *branch_if("EQ", "local0"), movw(2, 0), emit("STR_PRE_DEC_T", 2, SP_T, 8), place("local2"),
        emit("LDR_T", 9, SP_T, 0), compare(9, 0), *branch_if("EQ", "local3"), movw(2, 32), put_byte(2), place("local3"),
        address(6, "key_row"), load_at(0, "element_row", 6, 9), emit("BL_T", to=label("put_output")),
        emit("LDR_T", 9, SP_T, 0), emit("ADDW_T", 9, 9, 1), emit("STR_T", 9, SP_T, 0), li1(LR, "size_row"),
        compare_registers(9, LR), *branch_if("LO", "local2"), emit("ADDW_T", SP_T, SP_T, 8), branch("local1"),
        place("local0"), movw(2, 45), put_byte(2), place("local1"),
    ]),
    ("OUTPUT_TAIL_THUMB", [
        movw(2, 10), put_byte(2), *absolute(6, ("OUT", 0)), *literal(7, UART0), place("local0"), emit("LDRB_POST_T", 2, 6, 1),
        emit("STR_T", 2, 7, 0), compare_registers(6, 10), *branch_if("NE", "local0"),
    ]),
    ("FINISH_THUMB", [
        branch("complete"), *PUT_NUMBER_THUMB, place("put_bool"), compare(0, 0), *branch_if("EQ", "local2"),
        *put_bytes_thumb("true"), emit("BX_LR_T"), place("local2"), *put_bytes_thumb("false"), emit("BX_LR_T"), *DIVIDE_THUMB,
    ]),
    ("CYCLE_VALUE_THUMB", [ld1(0, ("CLK", "clock_row"), UINTEGER_TYPE), operand1(2, "row"), emit("AND_T", 0, 0, 2)]),
    ("CYCLE_JUMP_TRUE_THUMB", [compare(0, 0), *branch_if("EQ", "copy_next")]),
    ("CYCLE_JUMP_FALSE_THUMB", [compare(0, 0), *branch_if("NE", "copy_next")]),
    ("CYCLE_CLOSE_THUMB", [branch("copy_end"), place("copy_next")]),
    ("CYCLE_DONE_THUMB", [place("copy_end")]),
    ("PUT_TEXT_THUMB", [
        place("put_text"), *literal(7, UART0), place("local1"), compare(2, 0), *branch_if("EQ", "local2"),
        emit("LDRB_POST_T", 3, 6, 1), emit("STR_T", 3, 7, 0), emit("SUBS_IMM_T", 2, 2, 1), branch("local1"), place("local2"),
        emit("BX_LR_T"), place("put_char"), compare(0, 128), *branch_if("HS", "local4"), put_byte(0), emit("BX_LR_T"),
        place("local4"), emit("LSR_IMM_T", 2, 0, 6), emit("ORR_IMM_T", 2, 2, 0xC0), put_byte(2), movw(3, 63),
        emit("AND_T", 2, 0, 3), emit("ORR_IMM_T", 2, 2, 0x80), put_byte(2), emit("BX_LR_T"),
    ]),
    ("ROW_WRITE_THUMB", gated_thumb([
        operand1(6, "arg0"), *string_length_thumb(2, 6), emit("BL_T", to=label("put_text")),
        operand1(6, "arg1", "writes_string"), *string_length_thumb(2, 6, "writes_string"),
        emit("BL_T", to=label("put_text"), when="writes_string"), *absolute(10, ("OUT", 0)),
        operand2(0, "arg1", "writes_number"), emit("BL_T", to=label("put_param"), when="writes_number"),
        operand1(0, "arg1", "writes_char"), emit("BL_T", to=label("put_char"), when="writes_char"),
        movw(2, 10), put_byte(2), *absolute(6, ("OUT", 0)), emit("SUBS_T", 2, 10, 6), emit("BL_T", to=label("put_text")),
    ], False)),
]
EMIT_TEMPLATES += [
    ("ROW_FLAT", gated([
        operand(9, "left"), operand(10, "right"), li(11, "value_row"), emit("MOVZ_X", 12, 0, 0x8000, 1),
        emit("SUBS_X", XZR, 9, 12), emit("B_COND", a3=CC["HS"], to=label("local1")), emit("SUBS_X", XZR, 10, 11),
        emit("B_COND", a3=CC["HS"], to=label("local1")), emit("MUL_X", 9, 9, 11), emit("ADD_X", 9, 9, 10),
        emit("B", to=label("local2")), place("local1"), emit("ORN_X", 9, XZR, XZR), place("local2"),
    ])),
    ("ROW_FLAT_THUMB", gated_thumb([
        operand2(0, "left"), operand2(2, "right"), li2(4, "value_row"), compare(1, 0), *branch_if("NE", "local1"),
        compare(0, 0), *branch_if("LT", "local1"), *compare_pairs(2, 4), *branch_if("HS", "local1"),
        emit("UMULL_T", 6, 0, 4, 7), emit("ADDS_T", 0, 6, 2), emit("ADC_T", 1, 7, 3), branch("local2"),
        place("local1"), movw(0, 0), emit("MVN_T", 0, 0), mov(1, 0), place("local2"),
    ])),
    ("ROW_FOLD", gated([li(9, "value_row")])),
    ("ROW_FOLD_THUMB", gated_thumb([li2(0, "value_row")])),
    ("ROW_BOUNDS", gated([
        operand(9, "left"), operand(10, "right_left"), operand(11, "right_right"), emit("SUBS_X", XZR, 9, 10),
        emit("CSEL_X", 9, 10, 9, CC["LO"]), emit("B_COND", a3=CC["LO"], to=label("local1")), emit("SUBS_X", XZR, 9, 11),
        emit("CSEL_X", 9, 11, 9, CC["HI"]), place("local1"),
    ])),
    ("ROW_BOUNDS_SIGNED", gated([
        operand(9, "left"), operand(10, "right_left"), operand(11, "right_right"), emit("SUBS_X", XZR, 9, 10),
        emit("CSEL_X", 9, 10, 9, CC["LT"]), emit("B_COND", a3=CC["LT"], to=label("local1")), emit("SUBS_X", XZR, 9, 11),
        emit("CSEL_X", 9, 11, 9, CC["GT"]), place("local1"),
    ])),
    ("ROW_BOUNDS_THUMB", gated_thumb([
        operand2(0, "left"), operand2(2, "right_left"), operand2(4, "right_right"), *compare_pairs(0, 2),
        *branch_if("LO", "local1"), *compare_pairs(4, 0), *branch_if("LO", "local2"), branch("local3"),
        place("local1"), mov(0, 2), mov(1, 3), branch("local3"), place("local2"), mov(0, 4), mov(1, 5), place("local3"),
    ])),
    ("ROW_BOUNDS_SIGNED_THUMB", gated_thumb([
        operand2(0, "left"), operand2(2, "right_left"), operand2(4, "right_right"), *compare_pairs(0, 2),
        *branch_if("LT", "local1"), *compare_pairs(4, 0), *branch_if("LT", "local2"), branch("local3"),
        place("local1"), mov(0, 2), mov(1, 3), branch("local3"), place("local2"), mov(0, 4), mov(1, 5), place("local3"),
    ])),
    ("ROW_SLICE", gated([
        address(12, "key_left"), address(14, "key_owner"), operand(10, "right"), li(11, "value_row"),
        emit("SUBS_X", XZR, 10, 11), emit("CSEL_X", 10, 10, 11, CC["LO"]), li(17, "size_row"), emit("MUL_X", 10, 10, 17),
        li(13, "size_left"), emit("MOVZ_X", 15), place("local1"), emit("ADD_X", 16, 10, 15), emit("MOVZ_X", 9),
        emit("SUBS_X", XZR, 16, 13), emit("B_COND", a3=CC["HS"], to=label("local2")), emit("load_indexed_element", 9, 12, 16),
        place("local2"), emit("store_indexed_element", 9, 14, 15), emit("ADD_X_IMM", 15, 15, 1), emit("SUBS_X", XZR, 15, 17),
        emit("B_COND", a3=CC["LO"], to=label("local1")),
    ], False)),
    ("ROW_SLICE_THUMB", gated_thumb([
        address(6, "key_left"), address(8, "key_owner"), operand2(2, "right"), li2(4, "value_row"), *compare_pairs(2, 4),
        only_if("HS"), mov(2, 4), li1(7, "size_row"), emit("UMULL_T", 4, 2, 7, 1), li1(5, "size_left"), movw(9, 0),
        place("local1"), emit("ADDS_T", 3, 4, 9), movw(0, 0), movw(1, 0), compare_registers(3, 5), *branch_if("HS", "local2"),
        load_at(0, "element_row", 6, 3), place("local2"), store_at(0, "element_row", 8, 9), emit("ADDW_T", 9, 9, 1),
        compare_registers(9, 7), *branch_if("LO", "local1"),
    ], False)),
]



def element_loop(base, destination, count_source, top, end, offset=None):
    shifted = [li(11, offset), emit("ADD_X", 16, 15, 11)] if offset else []
    source_index = 16 if offset else 15
    return [
        emit("MOVZ_X", 15), li(17, count_source), place(top), emit("SUBS_X", XZR, 15, 17),
        emit("B_COND", a3=CC["HS"], to=label(end)), *shifted, emit("load_indexed_scalar", 9, base, source_index),
        emit("store_indexed_scalar", 9, destination, 15), emit("ADD_X_IMM", 15, 15, 1), emit("B", to=label(top)), place(end),
    ]


def append_loop(source_key, destination, top, end):
    return [
        address(14, source_key), emit("MOVZ_X", 16), li(11, "span"), place(top), emit("SUBS_X", XZR, 16, 11),
        emit("B_COND", a3=CC["HS"], to=label(end)), emit("load_indexed_scalar", 9, 14, 16),
        emit("store_indexed_scalar", 9, destination, 15), emit("ADD_X_IMM", 15, 15, 1), emit("ADD_X_IMM", 16, 16, 1),
        emit("B", to=label(top)), place(end),
    ]


def element_loop_thumb(base, destination, count_source, top, end, offset=None):
    shifted = [li1(3, offset), emit("ADDS_T", 2, 9, 3)] if offset else []
    source_index = 2 if offset else 9
    return [
        movw(9, 0), li1(5, count_source), place(top), compare_registers(9, 5), *branch_if("HS", end), *shifted,
        load_at(0, "scalar_row", base, source_index), store_at(0, "scalar_row", destination, 9), emit("ADDW_T", 9, 9, 1),
        branch(top), place(end),
    ]


def append_loop_thumb(source_key, destination, top, end):
    return [
        address(8, source_key), movw(2, 0), li1(3, "span"), place(top), compare_registers(2, 3), *branch_if("HS", end),
        load_at(0, "scalar_row", 8, 2), store_at(0, "scalar_row", destination, 9), emit("ADDW_T", 9, 9, 1),
        emit("ADDW_T", 2, 2, 1), branch(top), place(end),
    ]


def clocked(body):
    return [ld(9, ("CLK", "clock_row"), UINTEGER_TYPE), emit("CBZ_W", 9, to=label("local0")), *body, place("local0")]


def clocked_thumb(body):
    return [ld1(0, ("CLK", "clock_row"), UINTEGER_TYPE), compare(0, 0), *branch_if("EQ", "local0"), *body, place("local0")]


EMIT_TEMPLATES += [
    ("ROW_LAG", gated([address(12, "key_mem"), emit("MOVZ_X", 10), emit("load_indexed_scalar", 9, 12, 10)])),
    ("ROW_LAG_STRING", gated([
        address(12, "key_mem"), emit("LDR_X", 10, 12, 0), address(13, "key_string_value"), *copy_string(10, 13, "local1"),
        emit("ORR_X", 9, XZR, 13),
    ])),
    ("ROW_LAG_THUMB", gated_thumb([address(6, "key_mem"), movw(9, 0), load_at(0, "scalar_row", 6, 9)])),
    ("ROW_LAG_ARRAY", gated(copy_words("key_mem", "key_row", "words_row", "local1"), False)),
    ("ROW_LAG_ARRAY_THUMB", gated_thumb(copy_pairs("key_mem", "key_row", "words_row", "local1"), False)),
    ("ROW_WINDOW", gated([
        address(12, "key_mem"), address(13, "key_row"), *element_loop(12, 13, "count_mem", "local1", "local2"),
        ld(9, ("SIG", "left"), "element_row"), emit("store_indexed_scalar", 9, 13, 15),
    ], False)),
    ("ROW_WINDOW_THUMB", gated_thumb([
        address(6, "key_mem"), address(7, "key_row"), *element_loop_thumb(6, 7, "count_mem", "local1", "local2"),
        ld2(0, ("SIG", "left"), "element_row"), store_at(0, "scalar_row", 7, 9),
    ], False)),
    ("ROW_WINDOW_ARRAY", gated([
        address(12, "key_mem"), address(13, "key_row"), *element_loop(12, 13, "count_mem", "local1", "local2"),
        *append_loop("key_left", 13, "local3", "local4"),
    ], False)),
    ("ROW_WINDOW_ARRAY_THUMB", gated_thumb([
        address(6, "key_mem"), address(7, "key_row"), *element_loop_thumb(6, 7, "count_mem", "local1", "local2"),
        *append_loop_thumb("key_left", 7, "local3", "local4"),
    ], False)),
    ("SEED_MEMORY", [
        address(12, "key_mem"), address(14, "key_init"), emit("MOVZ_X", 15), li(17, "count_mem"), place("local0"),
        emit("SUBS_X", XZR, 15, 17), emit("B_COND", a3=CC["HS"], to=label("local1")), emit("load_indexed_init", 9, 14, 15),
        emit("store_indexed_scalar", 9, 12, 15), emit("ADD_X_IMM", 15, 15, 1), emit("B", to=label("local0")), place("local1"),
    ]),
    ("SEED_MEMORY_THUMB", [
        address(6, "key_mem"), address(7, "key_init"), movw(9, 0), li1(5, "count_mem"), place("local0"),
        compare_registers(9, 5), *branch_if("HS", "local1"), load_at(0, "init_element", 7, 9),
        store_at(0, "scalar_row", 6, 9), emit("ADDW_T", 9, 9, 1), branch("local0"), place("local1"),
    ]),
    ("SEED_STRING_LAG", [
        address(12, "key_mem"), address(9, "key_string_init"), emit("MOVZ_X", 15), li(17, "count_mem"), place("local0"),
        emit("SUBS_X", XZR, 15, 17), emit("B_COND", a3=CC["HS"], to=label("local1")), emit("store_indexed_scalar", 9, 12, 15),
        emit("ADD_X_IMM", 15, 15, 1), emit("B", to=label("local0")), place("local1"),
    ]),
    ("SEED_STRING_LAG_THUMB", [
        address(6, "key_mem"), address(0, "key_string_init"), movw(9, 0), li1(5, "count_mem"), place("local0"),
        compare_registers(9, 5), *branch_if("HS", "local1"), store_at(0, "scalar_row", 6, 9), emit("ADDW_T", 9, 9, 1),
        branch("local0"), place("local1"),
    ]),
    ("SEED_STRING_RING", [
        address(12, "key_mem"), address(13, "key_string_mem"), emit("ADD_X_IMM", 13, 13, 8),
        emit("MOVZ_X", 14, 0, STRING_BUFFER_BYTES & 0xFFFF), emit("MOVK_X", 14, 0, STRING_BUFFER_BYTES >> 16, 1),
        emit("MOVZ_X", 15), li(17, "count_mem"), place("local0"), emit("SUBS_X", XZR, 15, 17),
        emit("B_COND", a3=CC["HS"], to=label("local1")), emit("store_indexed_scalar", 13, 12, 15), emit("ADD_X", 13, 13, 14),
        emit("ADD_X_IMM", 15, 15, 1), emit("B", to=label("local0")), place("local1"),
    ]),
    ("LAG_STRING", clocked([
        address(12, "key_mem"), emit("LDR_X", 14, 12, 0), li(17, "count_shift"), emit("MOVZ_X", 15), place("local1"),
        emit("SUBS_X", XZR, 15, 17), emit("B_COND", a3=CC["HS"], to=label("local2")), emit("ADD_X_IMM", 16, 15, 1),
        emit("load_indexed_scalar", 9, 12, 16), emit("store_indexed_scalar", 9, 12, 15), emit("ADD_X_IMM", 15, 15, 1),
        emit("B", to=label("local1")), place("local2"), emit("SUB_X_IMM", 13, 14, 8), ld(10, ("SIG", "left"), "type_row"),
        *copy_string(10, 13, "local3"), emit("store_indexed_scalar", 13, 12, 17),
    ])),
    ("LAG", clocked([
        address(12, "key_mem"), *element_loop(12, 12, "count_shift", "local1", "local2", "span"),
        ld(9, ("SIG", "left"), "type_row"), emit("store_indexed_scalar", 9, 12, 15),
    ])),
    ("LAG_THUMB", clocked_thumb([
        address(6, "key_mem"), *element_loop_thumb(6, 6, "count_shift", "local1", "local2", "span"),
        ld2(0, ("SIG", "left"), "type_row"), store_at(0, "scalar_row", 6, 9),
    ])),
    ("LAG_ARRAY", clocked([
        address(12, "key_mem"), *element_loop(12, 12, "count_shift", "local1", "local2", "span"),
        *append_loop("key_left", 12, "local3", "local4"),
    ])),
    ("LAG_ARRAY_THUMB", clocked_thumb([
        address(6, "key_mem"), *element_loop_thumb(6, 6, "count_shift", "local1", "local2", "span"),
        *append_loop_thumb("key_left", 6, "local3", "local4"),
    ])),
    ("WINDOW_STEP", clocked([
        address(12, "key_mem"), address(13, "key_row"), *element_loop(13, 12, "count_mem", "local1", "local2", "span"),
    ])),
    ("WINDOW_STEP_THUMB", clocked_thumb([
        address(6, "key_mem"), address(7, "key_row"), *element_loop_thumb(7, 6, "count_mem", "local1", "local2", "span"),
    ])),
]

def emit_template_rows():
    starts, lengths, label_counts, rows = [], [], [], []
    for _, steps in EMIT_TEMPLATES:
        starts.append(len(rows))
        lengths.append(len(steps))
        locals_used = [
            int(name[5:]) for step_row in steps for name in (step_row[3], step_row[8])
            if isinstance(name, str) and name.startswith("local")
        ]
        label_counts.append(max(locals_used) + 1 if locals_used else 0)
        for kind, when, form, a0, a1, a2, a3, target_kind, target in steps:
            sources = []

            def spec(value):
                if isinstance(value, int):
                    assert -1 <= value < SOURCE_BASE
                    return value
                if value in FORMS:
                    return FORMS.index(value)
                sources.append(EMIT_SOURCES.index(value))
                return SOURCE_BASE + len(sources) - 1

            slots = [spec(value) for value in (form, a0, a1, a2, a3, target)]
            assert len(sources) <= 2
            sources += [-1] * (2 - len(sources))
            rows.append((MICRO_KINDS.index(kind), EMIT_PREDICATES.index(when), *slots, TARGET_KINDS.index(target_kind), *sources))
    return starts, lengths, label_counts, rows


def packed_words(text, count):
    data = text.encode() + bytes(8 * count - len(text))
    return [int.from_bytes(data[8 * k:8 * k + 8], "little") for k in range(count)]


class Fragments:
    def __init__(self):
        self.texts = [""]

    def add(self, text):
        if text not in self.texts:
            self.texts.append(text)
        return self.texts.index(text)


def template_pieces(text):
    pieces = re.split(r"(?<!\^)#", text)
    return pieces + [""] * (4 - len(pieces))


def signed64(value):
    return value - (1 << 64) if value >> 63 else value


def segment(name, vmaddr, vmsize, fileoff, filesize, protection):
    return struct.pack("<II16sQQQQiiII", 0x19, 72, name, vmaddr, vmsize, fileoff, filesize, protection, protection, 0, 0)


def macho_header_words():
    text_bytes, data_bytes, signed_bytes, linkedit_bytes, signature_bytes = (MARKER_BASE + k for k in range(1, 6))
    header = (
        struct.pack("<IiiIIIII", 0xFEEDFACF, 0x0100000C, 0, 2, 7, COMMAND_BYTES, 0x00200004, 0)
        + segment(b"__PAGEZERO", 0, MACHO_BASE, 0, 0, 0)
        + segment(b"__TEXT", MACHO_BASE, text_bytes, 0, text_bytes, 5)
        + segment(b"__DATA", MACHO_BASE + text_bytes, data_bytes, text_bytes, data_bytes, 3)
        + segment(b"__LINKEDIT", MACHO_BASE + signed_bytes, linkedit_bytes, signed_bytes, signature_bytes, 1)
        + struct.pack("<III20s", 0xE, 32, 12, b"/usr/lib/dyld")
        + struct.pack("<IIQQ", 0x80000028, 24, TEXT_OFFSET, 0)
        + struct.pack("<IIII", 0x1D, 16, signed_bytes, signature_bytes)
    )
    assert len(header) == TEXT_OFFSET
    return [struct.unpack_from("<I", header, 4 * k)[0] for k in range(len(header) // 4)]


def elf_header_words():
    signed_bytes, memory_bytes = (MARKER_BASE + k for k in range(1, 3))
    header = (
        b"\x7fELF\x02\x01\x01" + bytes(9)
        + struct.pack("<HHIQQQIHHHHHH", 2, 183, 1, VIRT_BASE + VIRT_TEXT_OFFSET, 64, 0, 0, 64, 56, 1, 0, 0, 0)
        + struct.pack("<IIQQQQQQ", 1, 7, 0, VIRT_BASE, VIRT_BASE, signed_bytes, memory_bytes, SEGMENT_BYTES)
    )
    assert len(header) == VIRT_TEXT_OFFSET
    return [struct.unpack_from("<I", header, 4 * k)[0] for k in range(len(header) // 4)]


def elf32_header_words():
    signed_bytes, memory_bytes = (MARKER_BASE + k for k in range(1, 3))
    entry = MPS2_HEADER_BYTES - MPS2_UNLOADED + 1
    header = (
        b"\x7fELF\x01\x01\x01" + bytes(9)
        + struct.pack("<HHIIIIIHHHHHH", 2, 40, 1, entry, 52, 0, 0x05000200, 52, 32, 1, 40, 0, 0)
        + struct.pack("<IIIIIIII", 1, MPS2_UNLOADED, 0, 0, signed_bytes, memory_bytes, 7, 4)
        + struct.pack("<II", memory_bytes, entry)
    )
    assert len(header) == MPS2_HEADER_BYTES
    return [struct.unpack_from("<I", header, 4 * k)[0] for k in range(len(header) // 4)]


def signature_header_words():
    signature_bytes, directory_bytes, pages, signed_bytes = (MARKER_BASE + k for k in range(1, 5))
    header = struct.pack(">IIIII", 0xFADE0CC0, signature_bytes, 1, 0, SUPERBLOB_HEADER_BYTES) + struct.pack(
        ">IIIIIIIIIBBBBII", 0xFADE0C02, directory_bytes, 0x20100, 0x2, CODE_DIRECTORY_HEADER_BYTES + 1,
        CODE_DIRECTORY_HEADER_BYTES, 0, pages, signed_bytes, HASH_BYTES, 2, 0, SEGMENT_BYTES.bit_length() - 1, 0, 0,
    )
    assert len(header) == SUPERBLOB_HEADER_BYTES + CODE_DIRECTORY_HEADER_BYTES
    return [struct.unpack_from(">I", header, 4 * k)[0] for k in range(len(header) // 4)]


def split_markers(words, variables):
    fields = [word - MARKER_BASE if MARKER_BASE < word < MARKER_BASE + len(variables) else 0 for word in words]
    assert sorted(set(fields)) == list(range(len(variables)))
    return [0 if field else word for word, field in zip(words, fields)], fields


def first_primes(count):
    primes = []
    candidate = 2
    while len(primes) < count:
        if all(candidate % prime for prime in primes):
            primes.append(candidate)
        candidate += 1
    return primes


def integer_cube_root(value):
    root = int(round(value ** (1 / 3)))
    while root ** 3 > value:
        root -= 1
    while (root + 1) ** 3 <= value:
        root += 1
    return root


def build():
    fragments = Fragments()
    constants = []

    def integer(name, value):
        constants.append((name, f"constant integer {name} = {value};"))

    def table(name, element, values, render=str):
        rendered = [render(v) for v in values]
        width = 24 if element in ("short", "integer") else 6
        rows = [", ".join(rendered[i:i + width]) for i in range(0, len(rendered), width)]
        body = ",\n        ".join(rows)
        constants.append((name, f"constant [{len(values)}] {element} {name} = [\n        {body}];"))

    named = {}
    for name, text in NAMED_FRAGMENTS:
        named[name] = fragments.add(text)
        integer(f"F_{name}", named[name])
    section_ids = [fragments.add(text) for text in TOKEN_SECTIONS]
    kind_ids = [fragments.add(text) for text in TOKEN_KIND_NAMES]
    op_ids = [fragments.add(op) for op in OPS]
    type_kind_ids = [fragments.add(kind) for kind in TYPE_KINDS]
    role_ids = [fragments.add(role) for role in ROLES]
    column_ids = [fragments.add(column + " ") for column in ALL_COLUMNS]
    role_word_ids = [fragments.add(word) for word in ROLE_WORDS]
    parameter_kind_ids = [fragments.add(f"a {expected}, found a {found}") for expected in PARAMETER_KINDS for found in PARAMETER_KINDS]
    capacity_ids = [fragments.add(name) for name in CAPACITY_TABLES]
    model_description_ids = [fragments.add(f"{model_class} " if model_class == "function" else f"{attribute} {model_class} ")
                             for attribute in ATTRIBUTES for model_class in MODEL_CLASSES]
    symbol_ids = [0 if "\\" in text else fragments.add(text) for text, _ in SYMBOLS]
    piece_ids = [[fragments.add(piece) for piece in template_pieces(text)] for _, text, _ in TEMPLATES]

    seed = " ".join(SEED_WORDS)
    integer("SEED_LENGTH", len(seed))
    integer("SEED_NAME_COUNT", len(SEED_WORDS))
    constants.append(("SEED", f'constant [{len(seed)}] ubyte SEED = "{seed}";'))
    for word, name in NAME_CONSTANTS.items():
        integer(name, SEED_WORDS.index(word))
    for index, word in enumerate(SEED_WORDS):
        if word in KEYWORDS:
            integer(f"C_{word.upper()}", index + 1)
    for index, (_, name) in enumerate(SYMBOLS):
        integer(f"C_{name}", SYMBOL_BASE + index)
    for name, value in OTHER_CODES:
        integer(f"C_{name}", value)
    integer("C_SYMBOL_BASE", SYMBOL_BASE)
    integer("RELATION_ASSERT", CODE_LIMIT)
    integer("RELATION_MIN", CODE_LIMIT + 1)
    integer("RELATION_CONDITION", CODE_LIMIT + 2)

    name_char = [0] * 256
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_'"
    for code, character in enumerate(alphabet):
        name_char[ord(character)] = code
    for continuation in range(0x80, 0xC0):
        name_char[continuation] = len(alphabet) + continuation - 0x80
    table("NAME_CHAR", "short", name_char)
    integer("NAME_FANOUT", len(alphabet) + 0x40)
    single = [0] * 256
    for index, (text, _) in enumerate(SYMBOLS):
        if len(text) == 1:
            single[ord(text)] = SYMBOL_BASE + index
    table("SINGLE_SYMBOL", "short", single)
    pairs = [(text, SYMBOL_BASE + index) for index, (text, _) in enumerate(SYMBOLS) if len(text) == 2]
    firsts = sorted({text[0] for text, _ in pairs})
    seconds = sorted({text[1] for text, _ in pairs})
    pair_row = [0] * 256
    pair_column = [0] * 256
    for row, character in enumerate(firsts, 1):
        pair_row[ord(character)] = row
    for column, character in enumerate(seconds, 1):
        pair_column[ord(character)] = column
    pair_width = len(seconds) + 1
    pair_code = [0] * ((len(firsts) + 1) * pair_width)
    for text, code in pairs:
        pair_code[pair_row[ord(text[0])] * pair_width + pair_column[ord(text[1])]] = code
    table("PAIR_ROW", "short", pair_row)
    table("PAIR_COLUMN", "short", pair_column)
    integer("PAIR_WIDTH", pair_width)
    table("PAIR_CODE", "short", pair_code)
    triples = [(text, SYMBOL_BASE + index) for index, (text, _) in enumerate(SYMBOLS) if len(text) == 3]
    triple_firsts = sorted({text[0] for text, _ in triples})
    triple_seconds = sorted({text[1] for text, _ in triples})
    triple_row = [0] * 256
    triple_column = [0] * 256
    for row, character in enumerate(triple_firsts, 1):
        triple_row[ord(character)] = row
    for column, character in enumerate(triple_seconds, 1):
        triple_column[ord(character)] = column
    triple_width = len(triple_seconds) + 1
    triple_third = [0] * ((len(triple_firsts) + 1) * triple_width)
    triple_code = [0] * len(triple_third)
    for text, code in triples:
        slot = triple_row[ord(text[0])] * triple_width + triple_column[ord(text[1])]
        assert triple_code[slot] == 0
        triple_third[slot] = ord(text[2])
        triple_code[slot] = code
    table("TRIPLE_ROW", "short", triple_row)
    table("TRIPLE_COLUMN", "short", triple_column)
    integer("TRIPLE_WIDTH", triple_width)
    table("TRIPLE_THIRD", "short", triple_third)
    table("TRIPLE_CODE", "short", triple_code)
    escape_value = [0] * 256
    for character, value in ESCAPES.items():
        escape_value[ord(character)] = value
    table("ESCAPE_VALUE", "short", escape_value)
    hex_digit = [0] * 256
    for value, character in enumerate("0123456789abcdef"):
        hex_digit[ord(character)] = value + 1
        hex_digit[ord(character.upper())] = value + 1
    table("HEX_DIGIT", "short", hex_digit)
    keyword_keys = {}
    for word in KEYWORDS:
        key = 0
        for character in word:
            key = (key * 32 + ord(character) - ord("a") + 1) % 2 ** 64
        keyword_keys[word] = key
    modulus = next(m for m in range(len(KEYWORDS), 4096) if len({key % m for key in keyword_keys.values()}) == len(KEYWORDS))
    slots = [0] * modulus
    for key in keyword_keys.values():
        slots[key % modulus] = key
    integer("KEYWORD_LENGTH_MAX", max(len(word) for word in KEYWORDS))
    integer("KEYWORD_MODULUS", modulus)
    table("KEYWORD_KEYS", "ulong", slots, lambda key: f"ulong({key})")
    table("SYMBOL_FRAGMENT", "short", symbol_ids)

    for index, op in enumerate(OPS):
        integer(f"OP_{op}", index)
    table("OP_FRAGMENT", "short", op_ids)
    table("OP_IS_OPENER", "short", [int(op in OPENERS) for op in OPS])
    table("OP_POINTWISE", "short", [int(op in POINTWISE) for op in OPS])
    table("OP_ARITY", "short", [0 if op in LEAVES else 1 if op in UNARY else 2 for op in OPS])
    table("OP_MONOCHRONOUS", "short", [int(op in MONOCHRONOUS) for op in OPS])
    table("OP_BRACKETED", "short", [int(op in BRACKETED) for op in OPS])
    cx_names = list(CX_PROGRAMS)
    cx_steps = []
    cx_start, cx_length = [], []
    for name in cx_names:
        integer(f"CXP_{name}", cx_names.index(name))
        cx_start.append(len(cx_steps))
        cx_length.append(len(CX_PROGRAMS[name].steps))
        cx_steps.extend(CX_PROGRAMS[name].steps)

    def cx_ref(ref):
        return ref if isinstance(ref, int) else CX_REFS[ref]

    table("CXP_START", "short", cx_start)
    table("CXP_LENGTH", "short", cx_length)
    table("CXP_IMAG", "short", [int(any(dest == "IM" for dest, *_ in CX_PROGRAMS[name].steps)) for name in cx_names])
    integer("CX_STEP_LIMIT", max(cx_length))
    integer("CX_TEMP_BASE", CX_TEMP_BASE)
    table("CXS_DEST", "short", [CX_DESTS[dest] for dest, *_ in cx_steps])
    table("CXS_OP", "short", [-1 if op is None else OPS.index(op) for _, op, *_ in cx_steps])
    table("CXS_LEFT", "short", [cx_ref(left) for _, _, left, *_ in cx_steps])
    table("CXS_RIGHT", "short", [cx_ref(right) for _, _, _, right, *_ in cx_steps])
    table("CXS_TYPE", "short", [CX_TYPES[kind] for *_, kind, _ in cx_steps])
    table("CXS_VALUE", "short", [CX_VALUES[value] for *_, value in cx_steps])
    table("CX_TYPED_PROGRAM", "short", [cx_names.index(CX_TYPED_PROGRAM[op]) if op in CX_TYPED_PROGRAM else -1 for op in OPS])
    table("CX_OPERAND_PROGRAM", "short", [cx_names.index(CX_OPERAND_PROGRAM[op]) if op in CX_OPERAND_PROGRAM else -1 for op in OPS])
    for name, value in CX_VALUES.items():
        integer(f"CXV_{name}", value)
    for name, value in CX_REFS.items():
        integer(f"CXR_{name}", value)
    for name, value in CX_DESTS.items():
        integer(f"CXD_{name}", value)
    for name, value in CX_TYPES.items():
        integer(f"CXT_{name}", value)
    tp_rows = []
    tp_inline_start, tp_inline_length, tp_rest_start = [], [], []
    for op in OPS:
        inline, rest = TEMPLATE_PROGRAMS.get(op, ([], []))
        tp_inline_start.append(len(tp_rows))
        tp_inline_length.append(len(inline))
        tp_rows.extend(inline)
        tp_rest_start.append(len(tp_rows))
        tp_rows.extend(rest)
    def template_ref(ref):
        if ref is None:
            return -1
        if ref in TEMPLATE_REFS:
            return TEMPLATE_REFS[ref]
        return SEED_WORDS.index(ref)
    table("OP_TEMPLATE_KIND", "short", [TEMPLATE_KINDS.get(op, 0) for op in OPS])
    table("OP_TEMPLATE_SKIPS_LEFT", "short", [int(op in TEMPLATE_SKIPS_LEFT) for op in OPS])
    table("OP_TEMPLATE_INLINE_START", "short", tp_inline_start)
    table("OP_TEMPLATE_INLINE_LENGTH", "short", tp_inline_length)
    table("OP_TEMPLATE_REST_START", "short", tp_rest_start)
    table("TEMPLATE_ROW_KIND", "short", [TEMPLATE_ROW_KINDS.index(row[0]) for row in tp_rows])
    table("TEMPLATE_ROW_OP", "short", [OPS.index(row[1]) if row[1] else -1 for row in tp_rows])
    table("TEMPLATE_ROW_NAME", "integer", [template_ref(row[2]) for row in tp_rows])
    table("TEMPLATE_ROW_VALUE", "integer", [row[3] for row in tp_rows])
    table("TEMPLATE_ROW_REF", "short", [TEMPLATE_VALUE_REFS.index(row[4]) for row in tp_rows])
    table("TEMPLATE_ROW_TYPE", "integer", [template_ref(row[5]) for row in tp_rows])
    for index, name in enumerate(TEMPLATE_ROW_KINDS):
        integer(f"TPK_{name}", index)
    for index, name in enumerate(TEMPLATE_VALUE_REFS):
        integer(f"TPV_{name}", index)
    for name, value in TEMPLATE_REFS.items():
        integer(f"TPR_{name}", value)
    integer("N_FRESH_FIRST", SEED_WORDS.index(FRESH_FIRST))
    integer("N_FRESH_LAST", SEED_WORDS.index(FRESH_LAST))
    stage_ops = []
    for side, label in enumerate(["PRE", "POST"]):
        starts = []
        for op in OPS:
            starts.append(len(stage_ops))
            stage_ops.extend(OPS.index(part) for part in COMPOSITES.get(op, ([], []))[side])
        table(f"OP_{label}_START", "short", starts)
        table(f"OP_{label}_LENGTH", "short", [len(COMPOSITES.get(op, ([], []))[side]) for op in OPS])
    table("STAGE_OP", "short", stage_ops)
    op_text = {}
    for text, op, _ in BINARY + PREFIX:
        if "\\" not in text:
            op_text.setdefault(op, text)
    op_text.update({"DELAY": "$", "IF": "if", "BRANCH": "if", "GDELAY": "$", "WINDOW": "window", "LAG": "$"})
    table("OP_TEXT_FRAGMENT", "short", [fragments.add(op_text.get(op, op.lower())) for op in OPS])

    def code_of(text):
        if text in KEYWORDS:
            return SEED_WORDS.index(text) + 1
        return SYMBOL_BASE + [symbol for symbol, _ in SYMBOLS].index(text)

    binary_op = [0] * CODE_LIMIT
    binary_precedence = [0] * CODE_LIMIT
    for text, op, precedence in BINARY:
        binary_op[code_of(text)] = OPS.index(op)
        binary_precedence[code_of(text)] = precedence
    table("BINARY_OP", "short", binary_op)
    table("BINARY_PRECEDENCE", "short", binary_precedence)
    prefix_op = [0] * CODE_LIMIT
    prefix_precedence = [0] * CODE_LIMIT
    for text, op, precedence in PREFIX:
        prefix_op[code_of(text)] = OPS.index(op)
        prefix_precedence[code_of(text)] = precedence
    table("PREFIX_OP", "short", prefix_op)
    table("PREFIX_PRECEDENCE", "short", prefix_precedence)
    class_codes = [code_of(word) for word in MODEL_CLASSES]
    table("MODEL_CLASS", "short", [int(code in class_codes) for code in range(CODE_LIMIT)])
    table("CLASS_INDEX", "short", [class_codes.index(code) if code in class_codes else 0 for code in range(CODE_LIMIT)])
    integer("CLASS_COUNT", len(MODEL_CLASSES))
    attribute_codes = [code_of(word) for word in ATTRIBUTES]
    table("ATTRIBUTE_OF_CODE", "short", [attribute_codes.index(code) + 1 if code in attribute_codes else 0 for code in range(CODE_LIMIT)])
    for index, word in enumerate(ATTRIBUTES):
        integer(f"ATTRIBUTE_{word.upper()}", index)
    table("MODEL_DESCRIPTION_FRAGMENT", "short", model_description_ids)

    for index, kind in enumerate(TYPE_KINDS):
        integer(f"TK_{kind}", index)
    table("TYPE_KIND_FRAGMENT", "short", type_kind_ids)
    table("CLOCK_KIND_FRAGMENT", "short", [named["NONE"]] + [fragments.add(kind) for kind in CLOCK_KINDS[1:]])
    table("BUILTIN_KIND", "short", BUILTIN_KIND)
    table("BUILTIN_BYTES", "short", BUILTIN_BYTES)
    table("BUILTIN_SIGNED", "short", BUILTIN_SIGNED)
    for index, role in enumerate(ROLES):
        integer(f"ROLE_{role.upper()}", index)
    table("ROLE_FRAGMENT", "short", role_ids)
    for index, word in enumerate(ROLE_WORDS):
        integer(f"F_ROLE_{word.upper()}", role_word_ids[index])
    for index, kind in enumerate(PARAMETER_KINDS):
        integer(f"PK_{kind.upper()}", index)
    integer("PARAMETER_KIND_COUNT", len(PARAMETER_KINDS))
    table("PARAMETER_KIND_FRAGMENT", "short", parameter_kind_ids)
    dump_order = []
    for name, columns in DUMP_ORDERS:
        integer(f"ORDER_{name}_START", len(dump_order))
        dump_order.extend(ALL_COLUMNS.index(column) for column in columns)
        integer(f"ORDER_{name}_END", len(dump_order))
    table("DUMP_ORDER", "short", dump_order)
    for index, column in enumerate(ALL_COLUMNS):
        integer(f"COL_{column.upper().replace('.', '_')}", index)
    table("COLUMN_FRAGMENT", "short", column_ids)
    for index, name in enumerate(CAPACITY_TABLES):
        integer(f"F_CAP_{name}", capacity_ids[index])
    table("SECTION_FRAGMENT", "short", section_ids)
    table("KIND_FRAGMENT", "short", kind_ids)

    for index, kind in enumerate(ARGUMENT_KINDS):
        integer(f"A_{kind}", index)
    for index, (name, _, _) in enumerate(TEMPLATES, 1):
        integer(f"T_{name}", index)
    rows = [[0, 0, 0, 0]] + piece_ids
    kinds = [[0, 0, 0]] + [[ARGUMENT_KINDS.index(k) for k in ks] + [0] * (3 - len(ks)) for _, _, ks in TEMPLATES]
    for slot in range(4):
        table(f"TEMPLATE_PIECE{slot}", "short", [row[slot] for row in rows])
    for slot in range(3):
        table(f"TEMPLATE_KIND{slot}", "short", [row[slot] for row in kinds])

    for index, name in enumerate(LAYOUTS):
        integer(f"LAYOUT_{name}", index)
    for index, name in enumerate(SLICES):
        integer(f"ROW_SLICE_{name}", index)
    for index, name in enumerate(NUMBERS):
        integer(f"ROW_NUMBER_{name}", index)
    layout_rows = []
    first_rows = []
    counts = []
    for name in LAYOUTS:
        first_rows.append(len(layout_rows))
        counts.append(len(LAYOUT_ROWS.get(name, [])))
        layout_rows.extend(LAYOUT_ROWS.get(name, []))
    table("LAYOUT_ITEM_COUNT", "short", counts)
    table("LAYOUT_FIRST_ROW", "short", first_rows)
    table("ROW_PREFIX", "short", [-1 - COMPUTED_PREFIXES.index(row[0]) if row[0] in COMPUTED_PREFIXES
                                  else named[row[0]] if row[0] else 0 for row in layout_rows])
    for index, name in enumerate(COMPUTED_PREFIXES):
        integer(f"ROW_PREFIX_{name}", -1 - index)
    for index, (name, _) in enumerate(UTF8_REASONS):
        integer(f"UTF8_{name}", index)
    table("UTF8_REASON_FRAGMENT", "short", [fragments.add(text) for _, text in UTF8_REASONS])
    table("HEX_FRAGMENT", "short", [fragments.add(f"{value:02x}") for value in range(256)])
    table("ROW_SLICE", "short", [SLICES.index(row[1]) for row in layout_rows])
    table("ROW_NUMBER", "short", [NUMBERS.index(row[2]) for row in layout_rows])
    table("ROW_SUFFIX", "short", [named[row[3]] if row[3] else 0 for row in layout_rows])
    table("ROW_NEWLINE", "short", [row[4] for row in layout_rows])
    table("ROW_SLOT", "short", [row[5] for row in layout_rows])
    integer("MESSAGE_SLOTS", MESSAGE_SLOTS)

    table("POWERS_OF_TEN", "ulong", POWERS, lambda v: f"ulong({signed64(v)})")

    for index, word in enumerate(SEED_WORDS[:len(BUILTIN_KIND)]):
        integer(f"BUILTIN_{word.upper()}", index)
    for prefix, names in (("P", PARSE_STATES), ("X", OPERAND_CASES + OPERATOR_CASES), ("FRAME", FRAMES),
                          ("INIT", DELAY_INITS), ("PHASE", FINISH_PHASES), ("TS", TICK_STEPS),
                          ("IP", INSTANTIATE_PHASES), ("LS", LOWER_STATES), ("PS", POST_STATES),
                          ("XS", EXPAND_STATES), ("KS", CLOCK_STATES), ("JOB", BDD_JOBS), ("SPH", SPLIT_PHASES), ("CLK", CLOCK_KINDS),
                          ("OB", OBLIGATION_KINDS), ("RVP", REAL_PHASES)):
        for index, name in enumerate(names):
            integer(f"{prefix}_{name}", index)
    integer("SPLIT_CAP", SPLIT_CAP)
    integer("COPY_CAP", 1 << SPLIT_CAP)
    integer("SPLIT_FRAMES", 2 << SPLIT_CAP)
    integer("CORE_CAP", CORE_CAP)
    integer("CORE_EDGE_CAP", CORE_EDGE_CAP)
    integer("SAT_CAP", SAT_CAP)
    integer("WALK_CAP", WALK_CAP)
    integer("COPY_NODE_CAP", (1 << SPLIT_CAP) * CORE_CAP)
    integer("COPY_LITERAL_CAP", (1 << SPLIT_CAP) * SPLIT_CAP)
    integer("CONDITION_PRECEDENCE", CONDITION_PRECEDENCE)
    assert len(KEY_FAMILIES) <= KEY_STRIDE
    integer("KEY_STRIDE", KEY_STRIDE)
    for index, name in enumerate(KEY_FAMILIES):
        integer(f"KEY_{name}", index)
    for prefix, names in (("SHAPE", SHAPES), ("SA", SCALAR_ATOMS), ("LIST", LIST_KINDS), ("IC", ITEM_CLASSES),
                          ("AA", ARG_ATOMS)):
        for index, name in enumerate(names):
            integer(f"{prefix}_{name}", index)
    shapes = [COLUMN_SHAPES.get(column, "NUMBER").split() for column in ALL_COLUMNS]
    table("COLUMN_SHAPE", "short", [SHAPES.index(shape[0]) for shape in shapes])
    table("COLUMN_LIST_KIND", "short", [LIST_KINDS.index(shape[1]) if len(shape) > 1 else 0 for shape in shapes])
    integer("SCALAR_WIDTH", SCALAR_WIDTH)
    scalar_programs = [SCALAR_PROGRAMS.get(shape, []) for shape in SHAPES]
    table("SCALAR_LENGTH", "short", [len(program) for program in scalar_programs])
    table("SCALAR_PROGRAM", "short", [
        SCALAR_ATOMS.index(program[step]) if step < len(program) else 0
        for program in scalar_programs for step in range(SCALAR_WIDTH)])
    integer("OP_TOTAL", len(OPS))
    integer("ARG_WIDTH", ARG_WIDTH)
    integer("CALL_PARAMS_STEP", CALL_PARAMS_STEP)
    integer("PARAM_STEPS", PARAM_STEPS)
    arg_programs = [ARG_PROGRAMS.get(name, POSITION_PROGRAM) for name in OPS + DELAY_VARIANTS]
    assert ARG_PROGRAMS["CALL"].index("PARAMS") == CALL_PARAMS_STEP
    assert all(len(program) <= ARG_WIDTH for program in arg_programs)
    table("ARG_LENGTH", "short", [len(program) for program in arg_programs])
    table("ARG_PROGRAM", "short", [
        ARG_ATOMS.index(program[step]) if step < len(program) else 0
        for program in arg_programs for step in range(ARG_WIDTH)])
    integer("DELAY_PRECEDENCE", DELAY_PRECEDENCE)

    for index, name in enumerate(FORMS):
        integer(f"FORM_{name}", index)
    assert len(FORM_SPECS) == len(FORMS)
    assert all(len(fields) <= FORM_FIELD_SLOTS for _, _, fields, _, _ in FORM_SPECS)
    for index, name in enumerate(FIELD_KINDS):
        integer(f"FIELD_{name}", index)
    table("FORM_BASE", "long", [base for _, base, _, _, _ in FORM_SPECS])
    table("FORM_SIGNED", "short", [int(signed) for _, _, _, signed, _ in FORM_SPECS])
    table("FORM_KIND", "short", [FIELD_KINDS.index(kind) for _, _, _, _, kind in FORM_SPECS])
    table("FORM_TOP2", "short", [max([low + width for slot, low, width, _ in fields if slot == 2], default=0)
                                 for _, _, fields, _, _ in FORM_SPECS])
    padded = [list(fields) + [(0, 0, 0, 0)] * (FORM_FIELD_SLOTS - len(fields)) for _, _, fields, _, _ in FORM_SPECS]
    for column, name in enumerate(["SLOT", "LOW", "WIDTH", "AT"]):
        table(f"FORM_FIELD_{name}", "short", [field[column] for fields in padded for field in fields])
    integer("FORM_FIELD_SLOTS", FORM_FIELD_SLOTS)
    table("FORM_NAME_FRAGMENT", "short", [fragments.add(name) for name, _, _, _, _ in FORM_SPECS])
    constants.append(("MACHO_BASE", f"constant long MACHO_BASE = {MACHO_BASE};"))
    integer("TEXT_OFFSET", TEXT_OFFSET)
    integer("SEGMENT_BYTES", SEGMENT_BYTES)
    integer("SUPERBLOB_HEADER_BYTES", SUPERBLOB_HEADER_BYTES)
    integer("CODE_DIRECTORY_HEADER_BYTES", CODE_DIRECTORY_HEADER_BYTES)
    integer("HASH_BYTES", HASH_BYTES)
    header_words, header_fields = split_markers(macho_header_words(), HEADER_VARIABLES)
    integer("HEADER_WORD_COUNT", len(header_words))
    table("HEADER_WORD", "uinteger", header_words, lambda v: f"uinteger({v})")
    table("HEADER_FIELD", "short", header_fields)
    for index, name in enumerate(HEADER_VARIABLES):
        integer(f"HV_{name}", index)
    elf_words, elf_fields = split_markers(elf_header_words(), ELF_VARIABLES)
    integer("ELF_WORD_COUNT", len(elf_words))
    table("ELF_WORD", "uinteger", elf_words, lambda v: f"uinteger({v})")
    table("ELF_FIELD", "short", elf_fields)
    for index, name in enumerate(ELF_VARIABLES):
        integer(f"EV_{name}", index)
    elf32_words, elf32_fields = split_markers(elf32_header_words(), ELF_VARIABLES)
    table("ELF32_WORD", "uinteger", elf32_words, lambda v: f"uinteger({v})")
    table("ELF32_FIELD", "short", elf32_fields)
    integer("MPS2_HEADER_BYTES", MPS2_HEADER_BYTES)
    integer("MPS2_UNLOADED", MPS2_UNLOADED)
    integer("MPS2_RAM_BYTES", MPS2_RAM_BYTES)
    integer("STRING_BUFFER_BYTES", STRING_BUFFER_BYTES)
    integer("MPS2_STACK_BYTES", MPS2_STACK_BYTES)
    integer("VIRT_STACK_BYTES", VIRT_STACK_BYTES)
    for index, name in enumerate(PLATFORMS):
        integer(f"PLATFORM_{name}", index)
    integer("MACHINE_TEXT_LENGTH", len(MACHINE_TEXT))
    constants.append(("MACHINE_TEXT", f'constant [{len(MACHINE_TEXT)}] ubyte MACHINE_TEXT = "{MACHINE_TEXT}";'))
    constants.append(("VIRT_BASE", f"constant long VIRT_BASE = {VIRT_BASE};"))
    integer("VIRT_TEXT_OFFSET", VIRT_TEXT_OFFSET)
    integer("BOOT_ID", BOOT_ID)
    signature_words, signature_fields = split_markers(signature_header_words(), SIGNATURE_VARIABLES)
    integer("SIGNATURE_HEADER_BYTES", 4 * len(signature_words))
    table("SIGNATURE_WORD", "uinteger", signature_words, lambda v: f"uinteger({v})")
    table("SIGNATURE_FIELD", "short", signature_fields)
    for index, name in enumerate(SIGNATURE_VARIABLES):
        integer(f"SV_{name}", index)
    primes = first_primes(64)
    table("SHA_K", "uinteger", [integer_cube_root(prime << 96) & 0xFFFFFFFF for prime in primes], lambda v: f"uinteger({v})")
    table("SHA_IV", "uinteger", [math.isqrt(prime << 64) & 0xFFFFFFFF for prime in primes[:8]], lambda v: f"uinteger({v})")
    for name, value in CONDITIONS.items():
        integer(f"CC_{name}", value)
    for prefix, names in (("MK", MICRO_KINDS), ("TG", TARGET_KINDS), ("GL", GLOBAL_LABELS)):
        for index, name in enumerate(names):
            integer(f"{prefix}_{name.upper()}", index)
    for prefix, names in (("ES", EMIT_SOURCES), ("EP", EMIT_PREDICATES), ("ET", [name for name, _ in EMIT_TEMPLATES])):
        for index, name in enumerate(names):
            integer(f"{prefix}_{name.upper()}", index)
    integer("GLOBAL_LABEL_COUNT", len(GLOBAL_LABELS))
    integer("STEP_SOURCE_BASE", SOURCE_BASE)
    integer("ET_COUNT", len(EMIT_TEMPLATES))
    template_names = [name for name, _ in EMIT_TEMPLATES]
    for index, name in enumerate(UNIT_PHASES):
        integer(f"UPH_{name}", index)
    integer("UPH_DONE", len(UNIT_PHASES))
    table("UNIT_PHASE_TEMPLATE", "integer", [template_names.index(name) if name in template_names else -1 for name in UNIT_PHASES])
    table("UNIT_PHASE_TEMPLATE_VIRT", "integer", [
        template_names.index(name + VIRT_SUFFIX) if name + VIRT_SUFFIX in template_names
        else template_names.index(name) if name in template_names else -1 for name in UNIT_PHASES
    ])
    thumb_template = []
    for name in template_names:
        base = name[:-len(VIRT_SUFFIX)] if name.endswith(VIRT_SUFFIX) else name
        thumb_name = base + THUMB_SUFFIX
        thumb_template.append(template_names.index(thumb_name) if thumb_name in template_names
                              else template_names.index(name) if name.endswith(THUMB_SUFFIX) else -1)
    assert all(name + THUMB_SUFFIX in template_names for name in template_names if name.startswith("ROW_")
               and name not in ("ROW_SYSCALL", "ROW_READ", "ROW_DELAY_STRING", "ROW_STATE_STRING", "ROW_LAG_STRING")
               and not name.startswith("ROW_REAL_") and not name.endswith(THUMB_SUFFIX))
    table("THUMB_TEMPLATE", "integer", thumb_template)
    table("THUMB_LOAD_FORM", "integer", [FORMS.index(THUMB_LOAD_FORMS[key]) if key in THUMB_LOAD_FORMS else 0
                                         for key in ((index // 2, index % 2) for index in range(18))])
    table("THUMB_STORE_FORM", "integer", [FORMS.index(THUMB_STORE_FORMS[size]) if size in THUMB_STORE_FORMS else 0
                                          for size in range(9)])
    table("THUMB_BINARY_LO", "integer", [FORMS.index(THUMB_BINARY[op][0]) if op in THUMB_BINARY else -1 for op in OPS])
    table("THUMB_BINARY_HI", "integer", [FORMS.index(THUMB_BINARY[op][1]) if op in THUMB_BINARY else -1 for op in OPS])
    table("THUMB_SIGNED_SKIP", "integer", [CONDITIONS[THUMB_CONDITIONS[op][0]] ^ 1 if op in THUMB_CONDITIONS else -1 for op in OPS])
    table("THUMB_UNSIGNED_SKIP", "integer", [CONDITIONS[THUMB_CONDITIONS[op][1]] ^ 1 if op in THUMB_CONDITIONS else -1
                                             for op in OPS])
    starts, lengths, label_counts, step_rows = emit_template_rows()
    table("ET_START", "integer", starts)
    table("ET_LENGTH", "integer", lengths)
    table("ET_LABELS", "integer", label_counts)
    template_names = [name for name, _ in EMIT_TEMPLATES]
    table("MATH_TEMPLATE", "integer", [template_names.index(f"ROW_REAL_MATH_{function.upper().replace("'", "_")}") for function in MATH_UNARY + MATH_BINARY]
          + [template_names.index("ROW_REAL_MATH_ARG"), template_names.index("ROW_REAL_MATH_ATAN2")])
    step_columns = ["KIND", "WHEN", "FORM", "A0", "A1", "A2", "A3", "TARGET", "TARGET_KIND", "SOURCE0", "SOURCE1"]
    for column, name in enumerate(step_columns):
        table(f"STEP_{name}", "integer", [row[column] for row in step_rows])
    table("LOAD_OFFSET_FORM", "integer", [FORMS.index(LOAD_FORMS[key][0]) if key in LOAD_FORMS else 0
                                          for key in ((index // 2, index % 2) for index in range(18))])
    table("LOAD_INDEXED_FORM", "integer", [FORMS.index(LOAD_FORMS[key][1]) if key in LOAD_FORMS else 0
                                           for key in ((index // 2, index % 2) for index in range(18))])
    table("STORE_OFFSET_FORM", "integer", [FORMS.index(STORE_FORMS[size][0]) if size in STORE_FORMS else 0 for size in range(9)])
    table("STORE_INDEXED_FORM", "integer", [FORMS.index(STORE_FORMS[size][1]) if size in STORE_FORMS else 0 for size in range(9)])
    table("OP_INSTRUCTION_FORM", "integer", [FORMS.index(OP_INSTRUCTIONS[op]) if op in OP_INSTRUCTIONS else -1 for op in OPS])
    table("OP_SHIFT_FORM", "integer", [FORMS.index(OP_SHIFTS[op]) if op in OP_SHIFTS else -1 for op in OPS])
    table("OP_SIGNED_CONDITION", "integer", [CONDITIONS[OP_CONDITIONS[op][0]] ^ 1 if op in OP_CONDITIONS else -1 for op in OPS])
    table("OP_UNSIGNED_CONDITION", "integer", [CONDITIONS[OP_CONDITIONS[op][1]] ^ 1 if op in OP_CONDITIONS else -1 for op in OPS])
    table("OP_REAL_FORM", "integer", [FORMS.index(OP_REAL_INSTRUCTIONS[op]) if op in OP_REAL_INSTRUCTIONS else -1 for op in OPS])
    table("OP_REAL_CONDITION", "integer", [CONDITIONS[OP_REAL_CONDITIONS[op]] ^ 1 if op in OP_REAL_CONDITIONS else -1 for op in OPS])
    headers = [column + " " for column in CODE_COLUMNS]
    assert all(len(header) <= 16 for header in headers)
    integer("CODE_COLUMN_COUNT", len(CODE_COLUMNS))
    for word in range(2):
        table(f"CODE_HEADER_WORD{word}", "ulong", [packed_words(header, 2)[word] for header in headers],
              lambda v: f"ulong({signed64(v)})")
    table("CODE_HEADER_LENGTH", "integer", [len(header) for header in headers])
    constants.append(("EMIT_TEXT", f'constant [{len(EMIT_TEXT)}] ubyte EMIT_TEXT = "{EMIT_TEXT}";'))
    integer("MALFORMED_TEXT_LENGTH", EMIT_TEXT.index("memory"))

    text = "".join(fragments.texts)
    assert '"' not in text and "\n" not in text and "\\" not in text
    fragment_starts = []
    position = 0
    for fragment in fragments.texts:
        fragment_starts.append(position)
        position += len(fragment.encode())
    constants.append(("FRAGMENTS", f'constant [{len(text.encode())}] ubyte FRAGMENTS = "{text}";'))
    table("FRAGMENT_START", "short", fragment_starts)
    table("FRAGMENT_LENGTH", "short", [len(fragment.encode()) for fragment in fragments.texts])
    return constants


def declaration_pattern(name):
    return re.compile(r"    constant [^=;\"]*\b" + re.escape(name) + r' = (?:"[^"]*"|[^;"]*);\n')


def rewrite(source_text, constants):
    names = [name for name, _ in constants]
    duplicates = sorted({name for name in names if names.count(name) > 1})
    if duplicates:
        raise SystemExit(f"tables.py: constants generated twice: {', '.join(duplicates)}")
    for name, declaration in constants:
        pattern = declaration_pattern(name)
        replacement = "    " + declaration + "\n"
        if pattern.search(source_text):
            source_text = pattern.sub(lambda _: replacement, source_text, count=1)
        else:
            source_text = source_text.replace(ANCHOR, replacement + ANCHOR, 1)
    return source_text


def main():
    original = SOURCE.read_text()
    updated = rewrite(original, build())
    if updated != original:
        SOURCE.write_text(updated)
    return 0


if __name__ == "__main__":
    sys.exit(main())
