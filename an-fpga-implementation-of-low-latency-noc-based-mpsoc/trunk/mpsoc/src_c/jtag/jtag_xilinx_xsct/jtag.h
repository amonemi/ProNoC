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


#define UPDATE_INDEX (1<< 0)
#define UPDATE_IR    (1<< 1)
#define UPDATE_DAT   (1<< 2)
	

#define UPDATE_WB_ADDR  0x7
#define UPDATE_WB_WR_DATA  0x6
#define UPDATE_WB_RD_DATA  0x5
#define RD_WR_STATUS	0x4

#define BIT_NUM		(word_width<<3)	
#define BYTE_NUM	 word_width	

#define MISS_RETRY_NUM  10


/* Global vars */
unsigned int jtag_target_number=3;//default value for arty z7-20 board
unsigned int jtag_shift_reg_size=36;//default value 32 + 4
unsigned int index_num=126;
unsigned int word_width=4; // 
unsigned int write_verify=0;
unsigned int memory_offset=0;
unsigned int memory_boundary=0xFFFFFFFF;
unsigned int WORDS_NUM = 2;// will be updated after reading arguments
int chain_num = 4;
int chain_code=	0x23;	

unsigned int mis_addr[MISS_RETRY_NUM+1];
unsigned int miss=0;


char * binary_file_name=0;
char enable_binary_send=0;
char enable_binary_verify=0;
char enable_binary_read=0;
char * write_data=0;


/* altera virtual jtag support */
int jtag_init( );
void jtag_vir(unsigned vir);
void jtag_vindex(unsigned vindex);
void jtag_vdr(unsigned sz, unsigned bits, unsigned *out);
void jtag_vdr_long(unsigned , unsigned * , unsigned *, int );

#include "jtag.c"

#endif
