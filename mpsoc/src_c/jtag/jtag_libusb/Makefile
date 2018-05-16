
CFLAGS := -g -Wall
LIBS := -lusb-1.0

all: jinfo jtag_libusb usblist


jinfo.c: jtag.h
jtag_libusb.c: jtag.h
jtag.c: jtag.h
jtag-virtual.c: jtag.h
list_usb_dev.c: jtag.h



JINFO_OBJS := jinfo.o jtag-virtual.o jtag.o
jinfo: $(JINFO_OBJS)
	$(CC) -o jinfo $(JINFO_OBJS) $(LIBS)

JTAG_LIBUSB_OBJS := jtag_libusb.o jtag-virtual.o jtag.o
jtag_libusb: $(JTAG_LIBUSB_OBJS)
	$(CC) -o jtag_libusb $(JTAG_LIBUSB_OBJS) $(LIBS)

LIST_USB_OBJS := list_usb_dev.o jtag-virtual.o jtag.o
usblist: $(LIST_USB_OBJS)
	$(CC) -o list_usb_dev $(LIST_USB_OBJS) $(LIBS)

clean:
	rm -f  jinfo jtag_libusb list_usb_dev *.o
