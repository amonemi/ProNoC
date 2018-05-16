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

#define VENDOR_ID      0x09fb   // Altera
#define PRODUCT_ID     0x6001   // usb blaster (DE2-115) 
// Altera usb blaster  product IDs "6001", "6002", "6003", MODE="0666"   
// dose not work for USB-Blaster II "6010", "6810"
// run ./list_usb_dev  to see the list of all usb devices' vid and pid

unsigned usb_blaster_id = PRODUCT_ID; 


int main(int argc, char **argv) {
	unsigned bits;

	if (jtag_open(VENDOR_ID,usb_blaster_id) < 0)
		return -1;

	if (jtag_reset() < 0)
		return -1;
	
	if (jtag_dr(32, 0, &bits) < 0)
		return -1;
	fprintf(stderr,"IDCODE: %08x\n", bits);

	if (jtag_open_virtual_device(0xffffffff,VENDOR_ID,usb_blaster_id))
		return -1;

	jtag_close();
	return 0;
}
