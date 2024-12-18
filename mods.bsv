package mods;
  //imports

  ///////////////////////////////// interface definitions ////////////////////////////////////////
  //one bit fulladder
  interface Ifc_Fadder;
    method ActionValue #(Bit#(2)) fadder_result (Bit#(1)a ,Bit#(1)b, Bit#(1)c);
  endinterface:Ifc_Fadder

  //4 bit fulladder
  interface Ifc_4Fadder;
    method ActionValue #(Bit#(5)) f4adder_result (Bit#(4)a, Bit#(4)b, Bit#(1)c);
  endinterface:Ifc_4Fadder

  //32 bit fulladder
  interface Ifc_Fulladder;
    method ActionValue #(Bit#(33)) fulladder_result (Bit#(32)a, Bit#(32)b, Bit#(1)c);
  endinterface:Ifc_Fulladder

  //multiplier
  interface Ifc_Mul;
    method ActionValue #(Bit#(32)) mul_result (Bit#(16)a, Bit#(16)b);
  endinterface:Ifc_Mul;

  ///////////////////////////////// module definitions ////////////////////////////////////////
  //one bit fulladder
  module mkFadder(Ifc_Fadder);
    method ActionValue #(Bit#(2)) fadder_result (Bit#(1)a ,Bit#(1)b, Bit#(1)c);
      Bit#(2) ress = 0;
      ress[0] = (a ^ b ^ c);
      ress[1] = ((a & b) | (b & c) | (c & a));
      return ress;
    endmethod
  endmodule:mkFadder

  //4 bit fulladder
  module mk4Fadder(Ifc_4Fadder);
    Ifc_Fadder u1 <- mkFadder;
    Ifc_Fadder u2 <- mkFadder;
    Ifc_Fadder u3 <- mkFadder;
    Ifc_Fadder u4 <- mkFadder;
    method ActionValue #(Bit#(5)) f4adder_result (Bit#(4)a, Bit#(4)b, Bit#(1)c);
      Bit#(5) ress = 0;

      let interim1 <- u1.fadder_result(a[0],b[0],c);
      let interim2 <- u2.fadder_result(a[1],b[1],interim1[1]);
      let interim3 <- u3.fadder_result(a[2],b[2],interim2[1]);
      let interim4 <- u4.fadder_result(a[3],b[3],interim3[1]);

      ress[0] = interim1[0];
      ress[1] = interim2[0];
      ress[2] = interim3[0];
      ress[3] = interim4[0];
      ress[4] = interim4[1];
      return ress;
    endmethod
  endmodule:mk4Fadder

  //32 bit adder
  module mkFulladder(Ifc_Fulladder);
    Ifc_4Fadder u1 <- mk4Fadder;
    Ifc_4Fadder u2 <- mk4Fadder;
    Ifc_4Fadder u3 <- mk4Fadder;
    Ifc_4Fadder u4 <- mk4Fadder;
    Ifc_4Fadder u5 <- mk4Fadder;
    Ifc_4Fadder u6 <- mk4Fadder;
    Ifc_4Fadder u7 <- mk4Fadder;
    Ifc_4Fadder u8 <- mk4Fadder;

    method ActionValue #(Bit#(33)) fulladder_result (Bit#(32)a, Bit#(32)b, Bit#(1)c);
      Bit #(33) ress;
      let interim1 <- u1.f4adder_result(a[3:0],b[3:0],c);
      let interim2 <- u2.f4adder_result(a[7:4],b[7:4],interim1[4]);
      let interim3 <- u3.f4adder_result(a[11:8],b[11:8],interim2[4]);
      let interim4 <- u4.f4adder_result(a[15:12],b[15:12],interim3[4]);
      let interim5 <- u5.f4adder_result(a[19:16],b[19:16],interim4[4]);
      let interim6 <- u6.f4adder_result(a[23:20],b[23:20],interim5[4]);
      let interim7 <- u7.f4adder_result(a[27:24],b[27:24],interim6[4]);
      let interim8 <- u8.f4adder_result(a[31:28],b[31:28],interim7[4]);

      ress[3:0] = interim1[3:0];
      ress[7:4] = interim2[3:0];
      ress[11:8] = interim3[3:0];
      ress[15:12] = interim4[3:0];
      ress[19:16] = interim5[3:0];
      ress[23:20] = interim6[3:0];
      ress[27:24] = interim7[3:0];
      ress[31:28] = interim8[3:0];

      return ress;
    endmethod
  endmodule:mkFulladder

  //multiplier
  module mkMul(Ifc_Mul);
    
  endmodule:mkMul
endpackage:mods
