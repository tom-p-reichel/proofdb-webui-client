#include <caml/mlvalues.h>
#include <stdint.h>
#include <stdio.h>

int popcount(uint64_t x) {
// this macro should be supported in recent versions of gcc and clang, per stackoverflow
#if defined(__GNUC__) && __has_builtin(__builtin_popcount)
  // if we have a builtin popcount, we should use it.
  return __builtin_popcount(x);
#else
  // taken from chessprogramming.org/Population_Count with immense gratitude
  // this is a very clever Simd Within A Register algorithm that is nice and branchless.
  const uint64_t k1 = 0x5555555555555555;
  const uint64_t k2 = 0x3333333333333333;
  const uint64_t k4 = 0x0f0f0f0f0f0f0f0f;
  const uint64_t kf = 0x0101010101010101;
  x = x - ((x >> 1) & k1);
  x = (x & k2) + ((x >> 2) & k2);
  x = (x + (x >> 4)) & k4;
  x = (x * kf) >> 56;
  return x;
#endif
}



int similarity(value a_val, value b_val) {
    unsigned char* a = Bytes_val(a_val);
    unsigned char* b = Bytes_val(b_val);
    size_t len = caml_string_length(a_val);
    if (len != caml_string_length(b_val)) {
        fprintf(stderr,"similarity was passed bytes with different lengths.\n");
        return 0;
    }
    int acc = 0;
    for (size_t x = 0; x < len/8; x++ ) {
        acc += popcount( ~(((uint64_t*)a)[x] ^ ((uint64_t*)b)[x]) );
    }

    for (size_t x = (len/8)*8; x < len; x++) {
        acc += popcount( (uint64_t) (~(a[x] ^ b[x]))  );
    }

    return acc;
}