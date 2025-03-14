#ifndef CRC32_H
#define CRC32_H

#include <stdint.h>
#include <stdlib.h>

uint32_t crc_32(const unsigned char *input_str, size_t num_bytes);
uint32_t update_crc_32(uint32_t crc, unsigned char c);

#endif // CRC32_H
