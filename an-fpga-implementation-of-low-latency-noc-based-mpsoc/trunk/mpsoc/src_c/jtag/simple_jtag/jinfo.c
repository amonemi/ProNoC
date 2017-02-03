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
#include "jtag.h"

int main(int argc, char **argv) {
	unsigned bits;

	if (jtag_open() < 0)
		return -1;

	if (jtag_reset() < 0)
		return -1;
	
	if (jtag_dr(32, 0, &bits) < 0)
		return -1;
	fprintf(stderr,"IDCODE: %08x\n", bits);

	if (jtag_open_virtual_device(0xffffffff))
		return -1;

	jtag_close();
	return 0;
}
