/*
 *  DCPU-16 Assembler & Emulator Library
 *  by js code by deNULL (me@denull.ru)
 */

library assembler;

class ParserState {
  var text;
  var pos;
  var end;
  var subst;
  var logger;
  var loc;
  var unary;
  var state;
  var right;
  var left;
  var binary;
  var literal;
  var register;
  var label;
  ParserState({this.state, this.text, this.label, this.pos, this.end, this.subst, this.loc, this.unary, this.left, this.right, this.literal, this.register, this.binary, this.logger});

  String dumpState() {
    var sb = new StringBuffer()
    ..add("text = ${text}\n")
    ..add("pos = ${pos}\n")
    ..add("end = ${end}\n")
    ..add("subst = ${subst}\n")
    ..add("logger = ${logger}\n")
    ..add("loc = ${loc}\n")
    ..add("unary = ${unary}\n")
    ..add("state = ${state}\n")
    ..add("right = ${right}\n")
    ..add("left = ${left}\n")
    ..add("binary = ${binary}\n")
    ..add("literal = ${literal}\n")
    ..add("register = ${register}\n")
    ..add("label = ${label}\n");
    return sb.toString();

  }
}

class AssemblerLineState {
  var op, size, dump, a, b, syntax, org, pc;
  AssemblerLineState({this.op, this.size, this.dump /*(array of words)*/, this.a, this.b, this.syntax, this.org, this.pc});
}

class OpcodeState {
  var infos, syntax;
  OpcodeState({this.infos, this.syntax});
}

class OperandExpression {
  var code, immediate, expr, short;
  OperandExpression({this.code, this.immediate, this.expr, this.short});
}

class LineParsed {
  var label, op, args, args_locs, args_ends;
  LineParsed({this.label, this.op, this.args, this.args_locs, this.args_ends});
}

//class ExpressionParsed {
//  var binary, left, right, state, loc;
//  ExpressionParsed({this.binary, this.left, this.right, this.state, this.loc});
//}

class Assembler {
  List<String> DIRECTIVES = [ "macro", "define" ];

  Map<String, int> REGISTERS = { "a": 0, "b": 1, "c": 2, "x": 3, "y": 4, "z": 5, "i": 6, "j": 7 };

  Map<String, int> SPECIALS = {
    "push": 0x18,
    "pop":  0x18,
    "peek": 0x19,
    "pick": 0x1a,
    "sp":   0x1b,
    "pc":   0x1c,
    "o":    0x1d, // deprecated
    "ex":   0x1d
  };

  Map<String, int> BINARY = { '*': 2, '/': 2, '%': 2, '+': 1, '-': 1 };

  Map<String, int> OP_BINARY = {
    "set": 0x01,
    "add": 0x02,
    "sub": 0x03,
    "mul": 0x04,
    "mli": 0x05,
    "div": 0x06,
    "dvi": 0x07,
    "mod": 0x08,
    "mdi": 0x09,
    "and": 0x0a,
    "bor": 0x0b,
    "xor": 0x0c,
    "shr": 0x0d,
    "asr": 0x0e,
    "shl": 0x0f,
    "ifb": 0x10,
    "ifc": 0x11,
    "ife": 0x12,
    "ifn": 0x13,
    "ifg": 0x14,
    "ifa": 0x15,
    "ifl": 0x16,
    "ifu": 0x17,
    // ...
    "adx": 0x1a,
    "sbx": 0x1b,
    // ...
    "sti": 0x1e,
    "std": 0x1f,
  };

  Map<String, int> OP_SPECIAL = {
    "jsr": 0x01,
    // ...
    "hcf": 0x07,
    "int": 0x08,
    "iag": 0x09,
    "ias": 0x0a,
    "rfi": 0x0b,
    "iaq": 0x0c,
    // ...
    "hwn": 0x10,
    "hwq": 0x11,
    "hwi": 0x12,
  };

  List<String> OP_RESERVED = [ "set", "add", "sub", "mul", "mli", "div", "dvi", "mod",
                 "mdi", "and", "bor", "xor", "shr", "asr", "shl",
                 "ifb", "ifc", "ife", "ifn", "ifg", "ifa", "ifl", "ifu",
                 "adx", "sbx", "sti", "std",
                 "jsr", "hcf", "int", "iag", "ias", "iap", "iaq",
                 "hwn", "hwq", "hwi",
                 "jmp", "brk", "ret", "bra", "dat", "org" ];

  Map<String, bool> SPACE = { '32': true, '160': true, '13': true, '10': true, '9': true }; // to replace charAt(pos).match(/\s/), using regexps is very slow

  /*
   * parser state is passed around in a "state" object:
   *   - text: line of text
   *   - pos: current index into text
   *   - end: parsing should not continue past end
   *   - logger: function(pos, message, fatal) for reporting errors
   * index & offset are only tracked so they can be passed to logger for error reporting.
   */

  /**
   * parse a single atom and return either: literal, register, or label
   */
  ParserState parseAtom(ParserState state) {

    String text = state.text;
    var pos = state.pos;
    var end = state.end;
    var subst = state.subst;
    var logger = state.logger;


    while (pos < end && this.SPACE.containsKey(text.charCodeAt(pos).toString())) {
      pos++;
    }

    if (pos == end) {
      logger(pos, "Value expected (operand or expression)", true);
      return null;
    }

    var atom = new ParserState(loc: pos);

    if (text[pos] == '(') {
      state.pos = pos + 1;
      atom = this.parseExpression(state, 0);

      if (atom == null) {
        return null;
      }

      pos = atom.state.pos;

      while (pos < end && this.SPACE.containsKey(text.charCodeAt(pos).toString()))  {
        pos++;
      }

      if (pos == end || text[pos] != ')') {
        logger(pos, "Missing ) on expression", true);
        return null;
      }

      atom.state.pos = pos + 1;
    } else if (text[pos] == "'" && text[pos + 2] == "'") {
      atom.literal = text.charCodeAt(pos + 1);
      atom.state = state;
      atom.state.pos = pos + 3;
    } else {
      var operandMatcher = new RegExp(r'^[A-Za-z_.0-9]+');
      //print("pos, end - pos = ${pos},   ${end}");
      if (!operandMatcher.hasMatch(text.substring(pos, end))) {
        logger(pos, "Operand value expected", true);
        return null;
      }

      var operand = operandMatcher.firstMatch(text.substring(pos, end)).str.toLowerCase();
      pos += operand.length;
      if (subst[operand] != null) {
        operand = subst[operand].toLowerCase();
      }

      var numMatcher = new RegExp(r'^[0-9]+$');
      var hexMatcher = new RegExp(r'^0x[0-9a-fA-f]+$');
      var labelMatcher = new RegExp(r'^[a-zA-Z_.][a-zA-Z_.0-9]*$');

      if (numMatcher.hasMatch(operand)) {
        atom.literal = int.parse(operand);
      } else if (hexMatcher.hasMatch(operand)) {
        atom.literal = int.parse(operand);
      } else if (this.REGISTERS.containsKey(operand)) {
        atom.register = this.REGISTERS[operand];
      } else if (labelMatcher.hasMatch(operand)) {
        atom.label = operand;
      }

      atom.state = new ParserState(text: text, pos: pos, end: end, logger: logger);
    }

    return atom;
  }

  ParserState parseUnary(ParserState state) {
    if (state.pos < state.end && (state.text[state.pos] == '-' || state.text[state.pos] == '+')) {
      var loc = state.pos;
      var op = state.text[state.pos];
      state.pos++;
      var expr = this.parseAtom(state);
      if (expr == null) {
        return null;
      }

      return new ParserState(unary: op, right: expr, state: expr.state, loc: loc);
    } else {
      return this.parseAtom(state);
    }
  }

  /**
   * Parse an expression and return a parse tree. The parse tree nodes will contain one of:
   *   - binary (left, right)
   *   - unary (right)
   *   - literal
   *   - register
   *   - label
   */
  ParserState parseExpression(state, precedence) {
    var text = state.text;
    var pos = state.pos;
    var end = state.end;
    var logger = state.logger;

    while (pos < end && this.SPACE.containsKey(text.charCodeAt(pos).toString())) {
      pos++;
    }

    if (pos == end) {
      logger(pos, "Expression expected", true);
      return null;
    }

    var left = this.parseUnary(state);
    if (left == null) {
      return null;
    }

    pos = left.state.pos;

    while(true) {
      while (pos < end && this.SPACE.containsKey(text.charCodeAt(pos).toString())) {
        pos++;
      }

      if (pos == end || text[pos] == ')') {
        return left;
      }

      var newprec = this.BINARY[text[pos]];
      if (newprec == null) {
        logger(pos, "Unknown operator (try: + - / %)", true);
        return null;
      }

      if (newprec <= precedence) {
        return left;
      }

      var op = text[pos];
      var loc = pos;
      state.pos = pos + 1;
      var right = this.parseExpression(state, newprec);
      if (right == null) {
        return null;
      }

      left = new ParserState(binary: op, left: left, right: right, state: right.state, loc: loc);
      pos = left.state.pos;
    }
  }

  /**
   * Convert an expression tree from 'parseExpression' into a human-friendly string form, for
   * debugging.
   */
  String expressionToString(expr) {
    if (expr.literal != null) {
      return expr.literal.toString();
    } else if (expr.label != null) {
      return expr.label;
    } else if (expr.register != null) {
      return this.REGISTERS[expr.register].toString();
    } else if (expr.unary != null) {
      return "(${expr.unary}${this.expressionToString(expr.right)})";
    } else if (expr.binary != null) {
      return "(${this.expressionToString(expr.left)} ${expr.binary} ${this.expressionToString(expr.right)})";
    } else {
      return "ERROR";
    }
  }

  /**
   * Given a parsed expression tree, evaluate into a literal number.
   * Label references are looked up in 'labels'. Any register reference, or reference to a label
   * that's not in 'labels' will be an error.
   */
  int evalConstant(expr, labels, fatal) {
    var logger = expr.state.logger;
    var pos = expr.state.pos;
    var value;

    if (expr.literal != null) {
      value = expr.literal;
    } else if (expr.label != null) {
      if (!this.SPECIALS.containsKey(expr.label)) {
        logger(pos, "You can't use ${expr.label.toUpperCase()} in expressions.", true);
        return null;
      }

      value = labels[expr.label];

      if (value == null) {
        if (fatal) {
          logger(expr.loc, "Unresolvable reference to '${expr.label}'", true);
        }

        return null;
      }
    } else if (expr.register != null) {
      logger(expr.loc, "Constant expressions may not contain register references", true);
      return null;
    } else if (expr.unary != null) {
      value = this.evalConstant(expr.right, labels, fatal);
      if (value == null) {
        return null;
      }

      switch (expr.unary) {
        case '-':
          value = -value;
          break;
      }
    } else if (expr.binary != null) {
      var left = this.evalConstant(expr.left, labels, fatal);
      if (left == null) {
        return null;
      }

      var right = this.evalConstant(expr.right, labels, fatal);
      if (right == null) {
        return null;
      }

      switch (expr.binary) {
        case '+':
          value = left + right;
          break;

        case '-':
          value = left - right;
          break;

        case '*':
          value = left * right;
          break;

        case '/':
          value = left ~/ right;
          break;

        case '%':
          value = left % right;
          break;

        default:
          logger(expr.loc, "Internal error (undefined binary operator)", true);
          return null;
      }
    } else {
      logger(expr.loc, "Internal error (undefined expression type)", true);
      return null;
    }

    if (value < 0 || value > 0xffff) {
      logger(pos, "(Warning) Literal value ${value.toRadixString(16)} will be truncated to ${(value & 0xffff).toRadixString(16)}", false);
      value = value & 0xffff;
    }

    return value;
  }

  /**
   * Parse any constant in this line and place it into the labels map if we found one.
   * Returns true if this line did contain some constant definition (even if it was an error),
   * meaning you shouldn't bother compiling this line.
   */
  bool parseConstant(text, labels, subst, logger) {
    var constMatcher = new RegExp(r'^\s*([A-Za-z_.][A-Za-z0-9_.]*)\s*=\s*(\S+)');

    if (!constMatcher.hasMatch(text)) {
      return false;
    }

    var name = constMatcher.firstMatch(text).group(1).toLowerCase();
    if (this.REGISTERS.containsKey(name) || this.SPECIALS.containsKey(name)) {
      logger(0, "$name is a reserved word and can't be used as a constant.", true);
      return true;
    }

    if (labels.containsKey(name)) {
      logger(0, "Duplicate label \"$name\"", false);
    }

    // manually find position of expression, for displaying nice error messages.
    var pos = text.indexOf('=') + 1;
    while (this.SPACE.containsKey(text.charCodeAt(pos).toString())) {
      pos++;
    }

    var state = new ParserState(text: text, pos: pos, end: text.length, subst: subst, logger: logger);
    var expr = this.parseExpression(state, 0);
    if (expr != null) {
      var value = this.evalConstant(expr, labels, true);
      if (value != false) {
        labels[name] = value;
      }
    }

    return true;
  }

  /*
   * Parse a line of code.
   * Returns the parsed line:
   *   - label (if any)
   *   - op (if any)
   *   - args (array): any operands, in text form
   *   - arg_locs (array): positions of the operands within the text
   *   - arg_ends (array): positions of the end of operands within the text
   */
  LineParsed parseLine(text, macros, subst, logger) {
    return null;
  }

  unquoteString(s) {

  }

  stateFromArg(is_a, line, i, subst, logger) {

  }

  handleData(info, line, labels, subst, logger) {

  }

  /**
   * Parse an operand expression into:
   *   - code: 5-bit value for the operand in an opcode
   *   - immediate: (optional) if the opcode has an immediate word attached
   *   - expr: if the operand expression can't be evaluated yet (needs to wait for the 2nd pass)
   * If 'short' is set in state, then the operand must fit into the opcode.
   */
  OperandExpression parseOperand(state, labels) {

  }

  /**
   * Called during the 2nd pass: resolve any unresolved expressions, or blow up.
   */
  OperandExpression resolveOperand(info, labels, logger) {
    var value = this.evalConstant(info.expr, labels, true);

    if (value == null) {
      return null;
    }

    if (info.short != null) {
      if (value >= 32) {
        logger(0, "Operand must be < 32", true);
        return null;
      }
      info.code = 0x20 + value;
    } else {
      info.immediate = value;
    }

    info.expr = null;
    return info;
  }

  /*
   * Compile a line of code. If either operand can't be resolved yet, it will have an 'expr' field.
   * The size will already be computed in any case.
   *
   * Returns object with fields:
   *   op, size, dump (array of words), a, b
   */
  AssemblerLineState compileLine(text, org, labels, macros, subst, logger) {
    return null;
  }

  AssemblerLineState resolveLine(info, labels, logger) {
    return null;
  }

  /**
   * Compile a list of lines of code.
   *   - lines: array of strings, lines of DCPU assembly to compile
   *   - memory: array of DCPU memory to fill in with compiled code
   *   - logger: (line#, address, line_pos, text, fatal) function to collect warnings/errors
   * If successful, returns:
   *   - infos: opcode info per line
   */
  compile(lines, memory, logger) {

    Map labels = { };
    bool aborted = false;
    int pc = 0;
    List<AssemblerLineState> infos = [ ];
    Map macros = { };
    List syntax = [ ];

    for (var i = 0; i < lines.length && !aborted; i++) {

      var l_logger = (pos, text, fatal) {
        logger(i, pc, pos, text, fatal);
        if (fatal) aborted = true;
      };

      labels["."] = pc;

      if (!this.parseConstant(lines[i], labels, { }, l_logger)) {
        var info = this.compileLine(lines[i], pc, labels, macros, { }, l_logger);
        if (info == null) {
          syntax.add(lines[i]);
          break;
        }
        syntax.add(info.syntax);
        if (pc + info.size > 0xffff) {
          l_logger(0, "Code is too big (exceeds 128 KB) &mdash; not enough memory", true);
          break;
        }
        if (info.org != null) {
          pc = info.org;
          info.pc = pc;
        } else {
          info.pc = pc;
          pc += info.size;
        }
        infos[i] = info;
      }
    }

    if (aborted) return null; //return false; // throw exception.

    // second pass -- resolve any leftover addresses:
    for (var i = 0; i < lines.length && !aborted; i++) {
      if (i > infos.length || infos[i] == null) continue;

      var l_logger = (pos, text, fatal) {
        logger(i, pc, pos, text, fatal);
        if (fatal) aborted = true;
      };

      labels["."] = infos[i].pc;
      infos[i] = this.resolveLine(infos[i], labels, l_logger);

      if (infos[i] == null) break;

      for (var j = 0; j < infos[i].dump.length; j++) {
        memory[infos[i].pc + j] = infos[i].dump[j];
      }
    }

    if (aborted) return null; //return false; // throw exception.

    return new OpcodeState(infos: infos, syntax: syntax);
  }
}
