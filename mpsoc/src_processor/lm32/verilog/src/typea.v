/*-- ---------------------------------------------------------------------------
--
-- Name : TYPEA.v
--
-- Description:
--
--    This is one of the two types of cells that are used to create ER1/ER2
--    register bits.
--
-- $Log: typea.vhd,v $
-- Revision 1.2  2002-11-13 18:33:59-08  jhsin
-- The SHIFT_DR_CAPTURE_DR and ENABLE_ER1/2 signals of the
-- dedicate logic JTAG_PORT didn't act as what their names implied.
-- The SHIFT_DR_CAPTURE_DR actually acts as SHIFT_DR.
-- The ENABLE_ER1/2 actually acts as SHIFT_DR_CAPTURE_DR.
-- These had caused a lot of headaches for a long time and now they are
-- fixed by:
-- (1) Use SHIFT_DR_CAPTURE_DR and ENABLE_ER1/2 to create
--     CAPTURE_DR for all typeA, typeB bits in the ER1, ER2 registers.
-- (2) Use ENABLE_ER1 or the enESR, enCSR, enBAR (these 3 signals
--     have the same waveform of ENABLE_ER2) directly to be the CLKEN
--     of all typeA, typeB bits in the ER1, ER2 registers.
-- (3) Modify typea.vhd to use only UPDATE_DR signal for the clock enable
--     of the holding flip-flop.
-- These changes caused ispTracy.vhd and cge.dat changes and the new
-- CGE.exe version will be 1.3.5.
--
-- Revision 1.1  2002-05-01 18:13:51-07  jhsin
-- Added RCS version control header to file. No code changes.
--
-- $Header: \\\\hqfile2\\ipcores\\rcs\\hqfile2\\ipcores\\rcswork\\isptracy\\VHDL\\Implementation\\typea.vhd,v 1.2 2002-11-13 18:33:59-08 jhsin Exp $
--
-- Copyright (C) 2002 Lattice Semiconductor Corp.  All rights reserved.
--
-- ---------------------------------------------------------------------------*/

module TYPEA(
      input CLK,
      input RESET_N,
      input CLKEN,
      input TDI,
      output TDO,
      output reg DATA_OUT,
      input DATA_IN,
      input CAPTURE_DR,
      input UPDATE_DR
   );
  
  reg tdoInt;


  always @ (negedge CLK or negedge RESET_N)
  begin
      if (RESET_N == 1'b0)
         tdoInt <= 1'b0;
      else if (CLK == 1'b0)
         if (CLKEN == 1'b1)
            if (CAPTURE_DR == 1'b0)
               tdoInt <= TDI;
            else
               tdoInt <= DATA_IN;
  end

   assign TDO = tdoInt;

  always @ (negedge CLK or negedge RESET_N)
   begin
      if (RESET_N == 1'b0)
         DATA_OUT <= 1'b0;
      else if (CLK == 1'b0)
         if (UPDATE_DR == 1'b1)
            DATA_OUT <= tdoInt;
   end
endmodule
