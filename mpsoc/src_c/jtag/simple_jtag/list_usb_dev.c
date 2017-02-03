#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>
#include <libusb-1.0/libusb.h>


int main(){
// discover devices

if (libusb_init(NULL) < 0)
		return -1;










libusb_context *ctx=NULL;
//uint16_t vendor_id,
//uint16_t product_id

	struct libusb_device **devs;
	//struct libusb_device *found = NULL;
	struct libusb_device *dev;
	//struct libusb_device_handle *handle = NULL;
	size_t i = 0;
	int r;
	if (libusb_get_device_list(ctx, &devs) < 0)
		return -1;
	while ((dev = devs[i++]) != NULL) {
		struct libusb_device_descriptor desc;
		r = libusb_get_device_descriptor(dev, &desc);
		if (r < 0)
			goto out;
		printf("vid=%x,\t pid=%x\n",desc.idVendor,desc.idProduct);		
		//if (desc.idVendor == vendor_id && desc.idProduct == product_id) {
		//	found = dev;
		//	break;
		//}
	}
	//if (found) {
	//	r = libusb_open(found, &handle);
	//	if (r < 0)
	//		handle = NULL;
	//}
out:
	libusb_free_device_list(devs, 1);
	//return handle;

return 0;

}

