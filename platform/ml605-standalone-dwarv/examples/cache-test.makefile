
# From 10us to 100ms, 6 per decade
CACHE_TIMER_VALUES  =     10     15    22    33    47    68
CACHE_TIMER_VALUES +=    100    150   220   330   470   680
CACHE_TIMER_VALUES +=   1000   1500  2200  3300  4700  6800
CACHE_TIMER_VALUES +=  10000  15000 22000 33000 47000 68000
CACHE_TIMER_VALUES += 100000

.PHONY: run-cache-test
run-cache-test:
	rm -f cache-runs
	$(MAKE) upload-cache
	$(MAKE) $(patsubst %,cache-pd-%,$(CACHE_TIMER_VALUES))
	$(MAKE) $(patsubst %,cache-ps-%,$(CACHE_TIMER_VALUES))
	$(MAKE) $(patsubst %,cache-wd-%,$(CACHE_TIMER_VALUES))
	$(MAKE) $(patsubst %,cache-ws-%,$(CACHE_TIMER_VALUES))
	$(MAKE) $(patsubst %,cache-nd-%,$(CACHE_TIMER_VALUES))
	$(MAKE) $(patsubst %,cache-ns-%,$(CACHE_TIMER_VALUES))

.PHONY: cache-nd-%
cache-nd-%:
	echo "---------- ND $*us"         >> cache-runs
	$(RVD) -c0 w IDMEM+0x3FFF0 0x8808
	$(RVD) -c0 w IDMEM+0x3FFF4 0x0088
	$(RVD) -c0 w IDMEM+0x3FFF8 0xFFFFFFFF
	$(RVD) -c0 w 0xF1000004 '(10*$*)-1'
	$(RVD) -c0 w 0xF1000000 0
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CREG 0x80000000
	sleep 6
	$(RVD) -c0 b
	$(RVD) -c0 exec FANCY_PERFORMANCE >> cache-runs
	echo "Return value:"              >> cache-runs
	$(RVD) -c0 r RET                  >> cache-runs
	echo "Number of interrupts:"      >> cache-runs
	$(RVD) -c0 r RSC1                 >> cache-runs
	echo "Number of qurt runs:"       >> cache-runs
	$(RVD) -c0 r SCRP1                >> cache-runs
	echo "Number of qurt cycles:"     >> cache-runs
	$(RVD) -c0 r SCRP2                >> cache-runs
	echo "Number of jpeg runs:"       >> cache-runs
	$(RVD) -c0 r SCRP3                >> cache-runs
	echo "Number of jpeg cycles:"     >> cache-runs
	$(RVD) -c0 r SCRP4                >> cache-runs

.PHONY: cache-ns-%
cache-ns-%:
	echo "---------- NS $*us"         >> cache-runs
	$(RVD) -c0 w IDMEM+0x3FFF0 0x8808
	$(RVD) -c0 w IDMEM+0x3FFF4 0x8800
	$(RVD) -c0 w IDMEM+0x3FFF8 0xFFFFFFFF
	$(RVD) -c0 w 0xF1000004 '(10*$*)-1'
	$(RVD) -c0 w 0xF1000000 0
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CREG 0x80000000
	sleep 6
	$(RVD) -c0 b
	$(RVD) -c0 exec FANCY_PERFORMANCE >> cache-runs
	echo "Return value:"              >> cache-runs
	$(RVD) -c0 r RET                  >> cache-runs
	echo "Number of interrupts:"      >> cache-runs
	$(RVD) -c0 r RSC1                 >> cache-runs
	echo "Number of qurt runs:"       >> cache-runs
	$(RVD) -c0 r SCRP1                >> cache-runs
	echo "Number of qurt cycles:"     >> cache-runs
	$(RVD) -c0 r SCRP2                >> cache-runs
	echo "Number of jpeg runs:"       >> cache-runs
	$(RVD) -c0 r SCRP3                >> cache-runs
	echo "Number of jpeg cycles:"     >> cache-runs
	$(RVD) -c0 r SCRP4                >> cache-runs

.PHONY: cache-wd-%
cache-wd-%:
	echo "---------- WD $*us"         >> cache-runs
	$(RVD) -c0 w IDMEM+0x3FFF0 0x8818
	$(RVD) -c0 w IDMEM+0x3FFF4 0x1188
	$(RVD) -c0 w IDMEM+0x3FFF8 0x8880
	$(RVD) -c0 w IDMEM+0x3FFFC 0x8880
	$(RVD) -c0 w 0xF1000004 '(10*$*)-1'
	$(RVD) -c0 w 0xF1000000 0
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CREG 0x80000000
	sleep 6
	$(RVD) -c0..1 b
	$(RVD) -c0 exec FANCY_PERFORMANCE >> cache-runs
	echo "Return value:"              >> cache-runs
	$(RVD) -c0 r RET                  >> cache-runs
	echo "Number of interrupts:"      >> cache-runs
	$(RVD) -c0 r RSC1                 >> cache-runs
	echo "Number of qurt runs:"       >> cache-runs
	$(RVD) -c1 r SCRP1                >> cache-runs
	echo "Number of qurt cycles:"     >> cache-runs
	$(RVD) -c1 r SCRP2                >> cache-runs
	echo "Number of jpeg runs:"       >> cache-runs
	$(RVD) -c1 r SCRP3                >> cache-runs
	echo "Number of jpeg cycles:"     >> cache-runs
	$(RVD) -c1 r SCRP4                >> cache-runs

.PHONY: cache-ws-%
cache-ws-%:
	echo "---------- WS $*us"         >> cache-runs
	$(RVD) -c0 w IDMEM+0x3FFF0 0x8818
	$(RVD) -c0 w IDMEM+0x3FFF4 0x8811
	$(RVD) -c0 w IDMEM+0x3FFF8 0x8088
	$(RVD) -c0 w IDMEM+0x3FFFC 0x8088
	$(RVD) -c0 w 0xF1000004 '(10*$*)-1'
	$(RVD) -c0 w 0xF1000000 0
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CREG 0x80000000
	sleep 6
	$(RVD) -c0..1 b
	$(RVD) -c0 exec FANCY_PERFORMANCE >> cache-runs
	echo "Return value:"              >> cache-runs
	$(RVD) -c0 r RET                  >> cache-runs
	echo "Number of interrupts:"      >> cache-runs
	$(RVD) -c0 r RSC1                 >> cache-runs
	echo "Number of qurt runs:"       >> cache-runs
	$(RVD) -c1 r SCRP1                >> cache-runs
	echo "Number of qurt cycles:"     >> cache-runs
	$(RVD) -c1 r SCRP2                >> cache-runs
	echo "Number of jpeg runs:"       >> cache-runs
	$(RVD) -c1 r SCRP3                >> cache-runs
	echo "Number of jpeg cycles:"     >> cache-runs
	$(RVD) -c1 r SCRP4                >> cache-runs

.PHONY: cache-pd-%
cache-pd-%:
	$(RVD) -c0 w IDMEM+0x3FFF0 0x8818
	$(RVD) -c0 w IDMEM+0x3FFF4 0x1188
	$(RVD) -c0 w IDMEM+0x3FFF8 0x8810
	$(RVD) -c0 w IDMEM+0x3FFFC 0x1180
	$(RVD) -c0 w 0xF1000004 '(10*$*)-1'
	$(RVD) -c0 w 0xF1000000 0
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CREG 0x80000000
	sleep 6
	$(RVD) -c0..1 b
	$(RVD) -c0 exec FANCY_PERFORMANCE >> cache-runs
	echo "Return value:"              >> cache-runs
	$(RVD) -c0 r RET                  >> cache-runs
	echo "Number of interrupts:"      >> cache-runs
	$(RVD) -c0 r RSC1                 >> cache-runs
	echo "Number of qurt runs:"       >> cache-runs
	$(RVD) -c1 r SCRP1                >> cache-runs
	echo "Number of qurt cycles:"     >> cache-runs
	$(RVD) -c1 r SCRP2                >> cache-runs
	echo "Number of jpeg runs:"       >> cache-runs
	$(RVD) -c1 r SCRP3                >> cache-runs
	echo "Number of jpeg cycles:"     >> cache-runs
	$(RVD) -c1 r SCRP4                >> cache-runs

.PHONY: cache-ps-%
cache-ps-%:
	echo "---------- PS $*us"         >> cache-runs
	$(RVD) -c0 w IDMEM+0x3FFF0 0x8818
	$(RVD) -c0 w IDMEM+0x3FFF4 0x8811
	$(RVD) -c0 w IDMEM+0x3FFF8 0x8018
	$(RVD) -c0 w IDMEM+0x3FFFC 0x8011
	$(RVD) -c0 w 0xF1000004 '(10*$*)-1'
	$(RVD) -c0 w 0xF1000000 0
	$(RVD) -c0 exec FLUSH_CACHE
	$(RVD) -c0 write CREG 0x80000000
	sleep 6
	$(RVD) -c0..1 b
	$(RVD) -c0 exec FANCY_PERFORMANCE >> cache-runs
	echo "Return value:"              >> cache-runs
	$(RVD) -c0 r RET                  >> cache-runs
	echo "Number of interrupts:"      >> cache-runs
	$(RVD) -c0 r RSC1                 >> cache-runs
	echo "Number of qurt runs:"       >> cache-runs
	$(RVD) -c1 r SCRP1                >> cache-runs
	echo "Number of qurt cycles:"     >> cache-runs
	$(RVD) -c1 r SCRP2                >> cache-runs
	echo "Number of jpeg runs:"       >> cache-runs
	$(RVD) -c1 r SCRP3                >> cache-runs
	echo "Number of jpeg cycles:"     >> cache-runs
	$(RVD) -c1 r SCRP4                >> cache-runs

