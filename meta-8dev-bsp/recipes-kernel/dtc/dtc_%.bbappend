# dtc 1.7.0 builds with meson default_options 'werror=true'. Build hosts with
# GCC 15+ (newer than this scarthgap release targets) flag a benign const-discard
# in libfdt/fdt_overlay.c (memchr() on a const string), which -Werror turns fatal
# and breaks the -native build. Drop werror so newer hosts can compile it; the CI
# builder image (GCC 13) is unaffected either way.
EXTRA_OEMESON:append = " -Dwerror=false"
