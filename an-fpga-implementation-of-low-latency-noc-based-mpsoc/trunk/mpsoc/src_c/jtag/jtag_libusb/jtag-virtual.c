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

#include <stdio.h>
#include <stdlib.h>

#include "jtag.h"

int jtag_dr_8x4(unsigned *out) {
	unsigned bits = 0;
	unsigned tmp;
	int n, r;

	for (n = 0; n < 8; n++) {
		if ((r = jtag_dr(4, 0, &tmp)) < 0) return r;
		bits |= (tmp <<= (n * 4));
	}
	*out = bits;
	return 0;
}

/* number of bits needed given a max value 1-255 */
unsigned needbits(unsigned max) {
	if (max > 127) return 8;
	if (max > 63) return 7;
	if (max > 31) return 6;
	if (max > 15) return 5;
	if (max > 7) return 4;
	if (max > 3) return 3;
	if (max > 1) return 2;
	return 1;
}

static unsigned ir_width = 10;

static unsigned hub_version = 0;
static unsigned hub_nodecount = 0;
static unsigned hub_mfg = 0;

static unsigned vir_width = 0;
static unsigned vir_width_addr = 0;
static unsigned vir_width_ir = 0;
static unsigned vir_addr = 0;


int jtag_vir(unsigned vir) {
	int r;
	if ((r = jtag_ir(ir_width, 14)) < 0) return r;
	if ((r = jtag_dr(vir_width, vir_addr | vir, 0)) < 0) return r;
	return 0;
}

int jtag_vdr(unsigned sz, unsigned bits, unsigned *out) {
	int r;
	if ((r = jtag_ir(ir_width, 12)) < 0) return r;
	if ((r = jtag_dr(sz, bits, out)) < 0) return r;
	return 0;
}

int jtag_vdr_long(unsigned sz, unsigned * bits, unsigned *out, int words) {
	int r;
	if ((r = jtag_ir(ir_width, 12)) < 0) return r;
	if ((r = jtag_dr_long(sz, bits, out, words)) < 0) return r;
	return 0;
}

int jtag_open_virtual_device(unsigned iid,unsigned vid, unsigned pid) {
	unsigned n, bits;
	int r;

	if ((r = jtag_open(vid,pid)) < 0) return r;

	if ((r = jtag_reset()) < 0) return r;

	/* select empty node_addr + node_vir -- all zeros */
	if ((r = jtag_ir(ir_width, 14)) < 0) return r;
	if ((r = jtag_dr(32, 0, 0)) < 0) return r;

	/* select vdr - this will be the hub info (addr=0,vir=0) */
	if ((r = jtag_ir(ir_width, 12)) < 0) return r;

	/* read hub info */
	if ((r = jtag_dr_8x4(&bits)) < 0) return r;
	hub_version = (bits >> 27) & 0x1F;
	hub_nodecount = (bits >> 19) & 0xFF;
	hub_mfg = (bits >> 8) & 0x7FF;

	if (hub_mfg != 0x06e) {
		fprintf(stderr,"hub_version=%x,	hub_nodecount=%x, 	hub_mfg=%x \n",hub_version,	hub_nodecount, 	hub_mfg);

		fprintf(stderr,"HUB:    Cannot Find Virtual JTAG HUB\n");
		return -1;
	}

	/* altera docs claim this field is the sum of M bits (VIR field) and
	 * N bits (ADDR field), but empirical evidence suggests it is actually
	 * just the width of the ADDR field and the docs are wrong...
	 */
	vir_width_ir = bits & 0xFF;
	vir_width_addr = needbits(hub_nodecount);
	vir_width = vir_width_ir + vir_width_addr;

	fprintf(stderr,"HUB:    Mfg=0x%03x, Ver=0x%02x, Nodes=%d, VIR=%d+%d bits\n",
		hub_mfg, hub_version, hub_nodecount, vir_width_addr, vir_width_ir);

	for (n = 0; n < hub_nodecount; n++) {
		unsigned node_ver, node_id, node_mfg, node_iid;
		if ((r = jtag_dr_8x4(&bits)) < 0) return r;
		node_ver = (bits >> 27) & 0x1F;
		node_id = (bits >> 19) & 0xFF;
		node_mfg = (bits >> 8) & 0x7FF;
		node_iid = bits & 0xFF;

		fprintf(stderr,"NODE:   Mfg=0x%03x, Ver=0x%02x, ID=0x%02x, IID=0x%02x\n",
			node_mfg, node_ver, node_id, node_iid);

		if ((node_id == 0x08) && (node_iid) == iid) {
			vir_addr = (n + 1) << vir_width_ir;
		}
	}

	if ((vir_addr == 0) && (iid < 256)) {
		fprintf(stderr,"ERROR: IID 0x%02x not found\n", iid);
		return -1;
	}
	return 0;
}


