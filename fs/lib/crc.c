// TODO: use char for "c"
// TODO: declare i and b on the same line
// TODO: use >>=
// TODO: replace if (b == 1) with if (b)

extern unsigned int crc32(unsigned int crc, int c) {
    unsigned int i;
    unsigned int b;

    for (i = 0; i < 8; i++) {
        b = (c ^ crc) & 1;
        crc = crc >> 1;

        if (b == 1) {
            crc = crc ^ $EDB88320;
        }

        c = c >> 1;
    }

    return crc;
}