TOOLCHAIN:=${PRONOC_WORK}/toolchain
SUBDIRS = ihex2bin  ihex2mif bin2str jtag  plot bin2mif bin2mem
BIN_FILES = ihex2bin/ihex2bin  ihex2mif/ihex2mif    bin2str/bin2str  jtag/jtag_libusb/jtag_libusb jtag/jtag_quartus_stp/jtag_quartus_stp bin2mif/bin2mif bin2mem/bin2mem jtag/jtag_xilinx_xsct/jtag_xilinx_xsct
PRONOC_WORK_BIN := $(TOOLCHAIN)/bin


all: subdirs binfiles
	
subdirs:
	for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir; \
	done

binfiles: 
	
	mkdir -p $(PRONOC_WORK_BIN)
	cp -f $(BIN_FILES) $(PRONOC_WORK_BIN)
	#	cp jtag/urjtag-0.10/src/jtag_main  $(PRONOC_WORK_BIN)/jtag_main
