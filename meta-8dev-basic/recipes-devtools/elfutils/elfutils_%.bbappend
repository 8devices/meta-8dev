# gcc-15 hosts make -Werror=discarded-qualifiers fatal on benign bsearch/memchr
# results. Native-only; the target toolchain is unaffected.
BUILD_CFLAGS:append:8dev-basic = " -Wno-error=discarded-qualifiers"
