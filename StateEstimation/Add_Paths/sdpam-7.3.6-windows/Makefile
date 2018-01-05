# SDPA version
SDPA_VERSION=7.3.6

# prefix of cross compilers
CROSS=i586-mingw32msvc
# CROSS=x86_64-w64-mingw32

# bit (32 or 64)
BIT=32
# BIT=64

# Directories
BASE_DIR=$(shell pwd)
SDPA_WIN_DIR=sdpa-$(SDPA_VERSION)-windows
SDPAM_WIN_DIR=sdpam-$(SDPA_VERSION)-windows

all:
	@echo "Choose target sdpa or sdpam"

sdpa: checkfiles pthreads-binary OpenBLAS-binary sdpa-binary sdpa-copy
sdpam: sdpam-checkfiles sdpam-binary sdpam-copy

clean:
	rm -f *~

clean-all: clean
	rm -rf pthreads
	rm -rf OpenBLAS
	rm -rf sdpa-install
	rm -rf $(SDPA_WIN_DIR)
	rm -rf $(SDPAM_WIN_DIR)
	rm -rf sdpa-$(SDPA_VERSION)

checkfiles:
	@echo "Checking compilers and other settings."
	@echo "If failed, read README.txt."
	@if [ "`which $(CROSS)-gcc`" = "" ]; then echo "Cannot find command $(CROSS)-gcc"; exit 1; fi
	@if [ "`which gcc`" = "" ]; then echo "Cannot find command gcc"; exit 1; fi
	@if [ "`which make`" = "" ]; then echo "Cannot find command make"; exit 1; fi
	@if [ "`which git`" = "" ]; then echo "Cannot find command git"; exit 1; fi
	@if [ "`which cvs`" = "" ]; then echo "Cannot find command cvs"; exit 1; fi
	@if [ "`which wget`" = "" ]; then echo "Cannot find command wget"; exit 1; fi
	@if [ ! -f sdpa_$(SDPA_VERSION).tar.gz ]; then echo "Cannot find source file sdpa_$(SDPA_VERSION).tar.gz"; exit 1; fi
	@echo "All check passed successfully."

pthreads-binary:
	@echo "******* Enter  anoncvs   as cvs-password ******"
	cvs -d :pserver:anoncvs@sourceware.org:/cvs/pthreads-win32 login
	cvs -d :pserver:anoncvs@sourceware.org:/cvs/pthreads-win32 checkout pthreads
	@if [ ! -d pthreads ]; then echo "Cannot download pthread-win32"; exit 1; fi
	(cd pthreads; make -f GNUmakefile CROSS=${CROSS}- clean GC-static)

OpenBLAS-binary:
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
	 $(CROSS)-ranlib libopenblas.lib )

sdpa-binary:
	tar xzf sdpa_$(SDPA_VERSION).tar.gz
	(cd sdpa-$(SDPA_VERSION); \
	 CFLAGS="-D__CLEANUP_C -O3 -finline-functions -DPTW32_BUILD_INLINED -DPTW32_STATIC_LIB -I. -DHAVE_CONFIG_H -Wall"  \
	 CXXFLAGS="-D__CLEANUP_C -O3 -finline-functions -DPTW32_BUILD_INLINED -DPTW32_STATIC_LIB -I. -DHAVE_CONFIG_H -Wall" \
	 FFLAGS="-D__CLEANUP_C -O3 -finline-functions -DPTW32_BUILD_INLINED -DPTW32_STATIC_LIB -I. -DHAVE_CONFIG_H -Wall"  \
	 ./configure --prefix=${BASE_DIR}/sdpa-install \
	  --host=$(CROSS) \
	  --target=$(CROSS) \
	  --with-blas=${BASE_DIR}/OpenBLAS/libopenblas.lib \
	  --with-lapack=${BASE_DIR}/OpenBLAS/libopenblas.lib \
	  --with-pthread-include="-I${BASE_DIR}/pthreads" \
	  --with-pthread-libs=${BASE_DIR}/pthreads/libpthreadGC2.a \
	  --with-mumps-libs=NO_MUMPS ; \
	 make; \
	 make install; )

sdpa-copy:
	rm -rf $(SDPA_WIN_DIR)
	rm -f $(SDPA_WIN_DIR).zip
	mkdir -p $(SDPA_WIN_DIR)
	mkdir -p $(SDPA_WIN_DIR)/matlab-extern
	cp sdpa-$(SDPA_VERSION)/COPYING $(SDPA_WIN_DIR)/
	cp sdpa-install/bin/sdpa.exe $(SDPA_WIN_DIR)/
	cp sdpa-install/share/sdpa/param.sdpa $(SDPA_WIN_DIR)/
	cp `find sdpa-install | grep dat-s$$` $(SDPA_WIN_DIR)/
	(cd $(SDPA_WIN_DIR)/; for i in *.dat-s; do sed -i -e 's/$$/\r/' $$i; done)
	cp Makefile README.txt $(SDPA_WIN_DIR)/
	zip -r $(SDPA_WIN_DIR).zip $(SDPA_WIN_DIR)

sdpam-checkfiles:
	@echo "Checking Matlab header and library files."
	@echo "If failed, read README.txt."
	@if [ ! -f matlab-extern/include/mex.h ]; then echo "Cannot find mex.h in matlab-extern/include/ "; exit 1; fi
	@if [ ! -f matlab-extern/include/matrix.h ]; then echo "Cannot find mex.h in matlab-extern/include/ "; exit 1; fi
	@if [ ! -f matlab-extern/microsoft/libmx.lib ]; then echo "Cannot find libmx.lib in matlab-extern/microsoft/ "; exit 1; fi
	@if [ ! -f matlab-extern/microsoft/libmex.lib ]; then echo "Cannot find libmex.lib in matlab-extern/microsoft/ "; exit 1; fi
	@echo "All check passed successfully."

sdpam-binary:
	(cd sdpa-install/share/sdpa/mex/; \
	 make MEX="$(CROSS)-g++ -shared" \
	 COMPILE_ENVIRONMENT=octave \
	 PRINTF_INT_STYLE=-DPRINTF_INT_STYLE=\\\"%zd\\\" \
	 OUTPUT_FORMAT="-o \$$@.mexw$(BIT)" \
	 MATLAB_INCLUDE="-I$(BASE_DIR)/matlab-extern/include" \
	 MATLAB_LIBS="$(BASE_DIR)/matlab-extern/microsoft/libmx.lib $(BASE_DIR)/matlab-extern/microsoft/libmex.lib";)

sdpam-copy:
	rm -rf $(SDPAM_WIN_DIR)
	rm -f $(SDPAM_WIN_DIR).zip
	cp -r $(SDPA_WIN_DIR) $(SDPAM_WIN_DIR)
	cp sdpa-install/share/sdpa/mex/*.m $(SDPAM_WIN_DIR)/
	cp sdpa-install/share/sdpa/mex/CommandList.txt $(SDPAM_WIN_DIR)/
	cp sdpa-install/share/sdpa/mex/mex*.mexw$(BIT) $(SDPAM_WIN_DIR)/
	zip -r $(SDPAM_WIN_DIR).zip $(SDPAM_WIN_DIR)
