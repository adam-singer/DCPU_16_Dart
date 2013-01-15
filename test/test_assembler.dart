import '../web/lib/assembler.dart';

l_logger(pos, text, fatal) {
  print("$pos $text $fatal");
}

class TestAssembler {

}

void main() {


  Assembler ass = new Assembler();

  ParserState state = new ParserState();



  /* This could be a good test */
//  state.text = "";
//  state.pos = 0;
//  state.end = 0;
//  state.subst = {};
//  state.logger = l_logger;
//  print(ass.parseAtom(state));


  state.text = "set B, 0x00";
  state.pos = 0;
  state.end = state.text.length;
  state.subst = {};
  state.logger = l_logger;
  print(ass.parseAtom(state).dumpState());

  state.text = "set B, 0x30";
  state.pos = 6;
  state.end = state.text.length;
  state.subst = {};
  state.logger = l_logger;
  print(ass.parseAtom(state).dumpState());

  state.text = "set B, 0x30";
  state.pos = 0;
  state.end = 3;
  state.subst = {};
  state.logger = l_logger;
  print(ass.parseAtom(state).dumpState());

  state.text = "set B, 0x30";
  state.pos = 3;
  state.end = 5;
  state.subst = {};
  state.logger = l_logger;
  print(ass.parseAtom(state).dumpState());
}
