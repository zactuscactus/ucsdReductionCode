# SDPA version
SDPA_VERSION=7.3.9

# prefix of cross compilers
# CROSS=i586-mingw32msvc
CROSS=x86_64-w64-mingw32

# bit (32 or 64)
# BIT=32
BIT=64

# Directories
BASE_DIR=$(shell pwd)
SDPA_WIN_DIR=sdpa7-windows
SDPAM_WIN_DIR=sdpam7-windows

all: OpenBLAS sdpa

OpenBLAS: OpenBLAS/libopenblas.a

OpenBLAS/libopenblas.a:
	rm -rf OpenBLAS
	git clone https://github.com/xianyi/OpenBLAS.git
	(cd OpenBLAS; \
	 make \
		DYNAMIC_ARCH=1 \
		HOSTCC=gcc \
		CC=${CROSS}-gcc \
		FC=${CROSS}-gfortran \
		CROSS_SUFFIX=${CROSS}- \
		BINARY=${BIT} \
		USE_OPENMP=0 \
		NO_CBLAS=1 \
		NO_WARMUP=1 \
		libs netlib; \
	 $(CROSS)-ranlib libopenblas.a )

sdpa: sdpa-binary sdpa-copy

sdpa-copy:
	rm -rf $(SDPA_WIN_DIR)
	rm -f $(SDPA_WIN_DIR).zip
	mkdir -p $(SDPA_WIN_DIR)
	mkdir -p $(SDPA_WIN_DIR)/matlab-root
	cp sdpa7/COPYING $(SDPA_WIN_DIR)/
	cp -r sdpa7-src $(SDPA_WIN_DIR)/
	cp sdpa-install/bin/sdpa.exe $(SDPA_WIN_DIR)/
	cp sdpa-install/share/sdpa/param.sdpa $(SDPA_WIN_DIR)/
	cp `find sdpa-install | grep dat-s$$` $(SDPA_WIN_DIR)/
	(cd $(SDPA_WIN_DIR)/; for i in *.dat-s; do sed -i -e 's/$$/\r/' $$i; done)
	cp Makefile README.txt $(SDPA_WIN_DIR)/
	zip -r $(SDPA_WIN_DIR).zip $(SDPA_WIN_DIR)


sdpa-binary: OpenBLAS
	(cp -r sdpa7-src sdpa7; \
	 cd sdpa7; \
	 autoreconf -i; \
	 CFLAGS=-static CXXFLAGS=-static FFLAGS=-static FCFLAGS=-static \
	 ./configure --prefix=${BASE_DIR}/sdpa-install \
	  --host=$(CROSS) \
	  --target=$(CROSS) \
	  --with-blas=${BASE_DIR}/OpenBLAS/libopenblas.a \
	  --with-lapack=${BASE_DIR}/OpenBLAS/libopenblas.a \
	  --with-pthread-include=-I/usr/$(CROSS)/include \
	  --with-pthread-libs=/usr/$(CROSS)/lib/libpthread.a \
	  --with-mumps-libs=NO_MUMPS ; \
         make; \
         make install; )
	cp sdpa7/sdpa.exe .

sdpam: sdpam-checkfiles sdpam-binary sdpam-copy

sdpam-checkfiles:
	@echo "Checking Matlab header and library files."
	@echo "If failed, read README.txt."
	@if [ ! -f matlab-root/extern/include/mex.h ]; then echo "Cannot find mex.h in matlab-root/extern/include/ "; exit 1; fi
	@if [ ! -f matlab-root/extern/include/matrix.h ]; then echo "Cannot find mex.h in matlab-root/extern/include/ "; exit 1; fi
	@if [ ! -f matlab-root/libmx.dll ]; then echo "Cannot find libmx.dll in matlab-root/ "; exit 1; fi
	@if [ ! -f matlab-root/libmex.dll ]; then echo "Cannot find libmex.dll in matlab-root/"; exit 1; fi
	@if [ ! -f matlab-root/libmat.dll ]; then echo "Cannot find libmex.dll in matlab-root/"; exit 1; fi
	@echo "All check passed successfully."

sdpam-binary:
	(cd sdpa-install/share/sdpa/mex/; \
	 make MEX="$(CROSS)-g++ -shared -static -DMX_COMPAT_32   -D_GNU_SOURCE -DMATLAB_MEX_FILE" \
	 COMPILE_ENVIRONMENT=octave \
	 PRINTF_INT_STYLE=-DPRINTF_INT_STYLE=\\\"%zd\\\" \
	 OUTPUT_FORMAT="-o \$$@.mexw$(BIT)" \
	 MATLAB_INCLUDE="-I$(BASE_DIR)/matlab-root/extern/include" \
	 MATLAB_LIBS="$(BASE_DIR)/matlab-root/libmx.dll $(BASE_DIR)/matlab-root/libmex.dll $(BASE_DIR)/matlab-root/libmat.dll";)

sdpam-copy:
	rm -rf $(SDPAM_WIN_DIR)
	rm -f $(SDPAM_WIN_DIR).zip
	cp -r $(SDPA_WIN_DIR) $(SDPAM_WIN_DIR)
	cp sdpa-install/share/sdpa/mex/*.m $(SDPAM_WIN_DIR)/
	cp sdpa-install/share/sdpa/mex/CommandList.txt $(SDPAM_WIN_DIR)/
	cp sdpa-install/share/sdpa/mex/mex*.mexw$(BIT) $(SDPAM_WIN_DIR)/
	zip -r $(SDPAM_WIN_DIR).zip $(SDPAM_WIN_DIR)

