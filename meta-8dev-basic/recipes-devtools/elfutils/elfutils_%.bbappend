# elfutils 0.191 predates gcc-15 and trips -Werror=discarded-qualifiers in
# several files (libcpu/riscv_disasm.c, libdw/dwarf_getsrclines.c, ...) when
# the *native* build uses a gcc-15 host compiler. The flagged spots are benign
# (bsearch/memchr results over const data assigned to non-const locals).
#
# poky's recipe already relaxes a related gcc-15 nit the same way
# (BUILD_CFLAGS += "-Wno-error=stringop-overflow"); extend that rather than
# carrying a growing pile of per-file backports or touching the pinned poky
# submodule. Native-only: the target toolchain is gcc-13 and is unaffected.
BUILD_CFLAGS += "-Wno-error=discarded-qualifiers"
