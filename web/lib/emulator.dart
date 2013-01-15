/*
 *  DCPU-16 Emulator Library
 *  js code by deNULL (me@denull.ru)
 */

class Registers {
  var A;
  var B;
  var C;
  var X;
  var Y;
  var Z;
  var I;
  var J;
  var PC;
  var SP;
  var EX;
  var IA;


  /*

  // get register from code to string
  static fromCode(int code) {

    // TODO(adam): refactor to sue

    switch(code) {
      case "A".charCodes[0]:
        return "A";

      case "B".charCodes[0]:
        return "B";

      case "C".charCodes[0]:
        return "C";

      case "X".charCodes[0]:
        return "X";

      case "Y".charCodes[0]:
        return "Y";

      case "Z".charCodes[0]:
        return "Z";

      case "I".charCodes[0]:
        return "I";

      case "J".charCodes[0]:
        return "J";

      default: throw "cant get register String $code";
    }
  }
*/
  /**
   * Returns the element at the given [index] in the list or throws
   * an [RangeError] if [index] is out of bounds.
   */
  /*
  operator [](int index) {
    switch(index) {
      case "A".charCodes[0]:
        return A;

      case "B".charCodes[0]:
        return B;

      case "C".charCodes[0]:
        return C;

      case "X".charCodes[0]:
        return X;

      case "Y".charCodes[0]:
        return Y;

      case "Z".charCodes[0]:
        return Z;

      case "I".charCodes[0]:
        return I;

      case "J".charCodes[0]:
        return J;

      default: throw "cant get register index $index";
    }
  }
*/
  /**
   * Sets the entry at the given [index] in the list to [value].
   * Throws an [RangeError] if [index] is out of bounds.
   */
  /*
  void operator []=(int index, value) {

    switch(index) {
      case "A".charCodes[0]:
        A = value;
        break;

      case "B".charCodes[0]:
        B = value;
        break;

      case "C".charCodes[0]:
        C = value;
        break;

      case "X".charCodes[0]:
        X = value;
        break;

      case "Y".charCodes[0]:
        Y = value;
        break;

      case "Z".charCodes[0]:
        Z = value;
        break;

      case "I".charCodes[0]:
        I = value;
        break;

      case "J".charCodes[0]:
        J = value;
        break;

      default: throw "cant set register $value";
    }
  }
  */
}

class DCPU {

}