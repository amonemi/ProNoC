/*-- ---------------------------------------------------------------------------
--
-- Name : TYPEB.vhd
--
-- Description:
--
--    This is one of the two types of cells that are used to create ER1/ER2
--    register bits.
--
-- $Log: typeb.vhd,v $
-- Revision 1.2  2002-08-01 16:39:33-07  jhsin
-- Modified typeb module to remove redundant DATA_OUT port.
--
-- Revision 1.1  2002-05-01 18:13:51-07  jhsin
-- Added RCS version control header to file. No code changes.
--
-- $Header: \\\\hqfile2\\ipcores\\rcs\\hqfile2\\ipcores\\rcswork\\isptracy\\VHDL\\Implementation\\typeb.vhd,v 1.2 2002-08-01 16:39:33-07 jhsin Exp $
--
-- Copyright (C) 2002 Lattice Semiconductor Corp.  All rights reserved.
--
-- ---------------------------------------------------------------------------*/
module TYPEB
   (
      input CLK,
      input RESET_N,
      input CLKEN,
      input TDI,
      output TDO,
      input DATA_IN,
      input CAPTURE_DR
   );

   reg tdoInt;

   always @ (negedge CLK or negedge RESET_N)
   begin
      if (RESET_N== 1'b0)
         tdoInt <= 1'b0;
      else if (CLK == 1'b0)
         if (CLKEN==1'b1)
            if (CAPTURE_DR==1'b0)
               tdoInt <= TDI;
            else
               tdoInt <= DATA_IN;
   end

   assign TDO = tdoInt;

endmodule

