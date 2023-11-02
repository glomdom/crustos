unsigned int crc32(unsigned int crc, char c) {
    unsigned int i;
    unsigned int b;

    for (i = 0; i < 8; i++) {
        b = (c ^ crc) & 1;
        crc = crc >> 1;

        if (b) {
            crc = crc ^ $EDB88320;
        }

        c = crc >> 1;
    }

    return crc;
}