/* Copyright 2012 Brian Swetland <swetland@frotz.net>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef _JTAG_H_
#define _JTAG_H_

int jtag_open(unsigned vid, unsigned pid);
int jtag_close(void);

/* move into RESET state */
int jtag_reset(void);

/* clock count times, TDI=0, TMS=bits[0], bits >>= 1 */
int jtag_move(int count, unsigned bits);

/* clock count-1 times, TMS=0, TDI=bits[0], bits >>= 1
 * clock 1 time, TMS=1, TDI=bits[0]
 * if out, capture TDO into out
 */
int jtag_shift(int count, unsigned bits, unsigned *out);


/* load sz bits into IR */
int jtag_ir(unsigned sz, unsigned bits);

/* load sz bits into DR, capture sz bits into out if non-null */
int jtag_dr(unsigned sz, unsigned bits, unsigned *out);
int jtag_dr_long(unsigned sz, unsigned * bits, unsigned *out, int words);



/* altera virtual jtag support */
int jtag_open_virtual_device(unsigned iid,unsigned vid, unsigned pid);
int jtag_vir(unsigned vir);
int jtag_vdr(unsigned sz, unsigned bits, unsigned *out);
int jtag_vdr_long(unsigned , unsigned * , unsigned *, int );

#endif
