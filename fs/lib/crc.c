unsigned int crc32(unsigned int crc, char c) {
    unsigned int i, b;

    for (j = 0; j < 8; j++) {
        b = (c ^ crc) & 1;
        crc >>= 1;

        if (b) {
            crc = crc ^ $EDB88320;
        }

        c >>= 1;
    }

    return crc;
}