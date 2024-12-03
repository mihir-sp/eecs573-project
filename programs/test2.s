data = 0x1000
    li	x1, data
    jal	x2,	start #
    .dword 2862933555777941757
    .dword 	3037000493
start:	lw	x3, 0(x2)
    lw	x4, 8(x2)
    li	x5, 0
loop:	addi	x5,	x5,	1 #
    slti	x6,	x5,	16 #
    mul	x11,	x2,	x3 #
    add	x11,	x11,	x4 #
    mul	x12,	x11,	x3 #
    add	x12,	x12,	x4 #
    mul	x13,	x12,	x3 #
    add	x13,	x13,	x4 #
    mul	x2,	x13,	x3 #
    add	x2,	x2,	x4 #
    srli	x11,	x11,	0 #
    sw	x11, 0(x1)
    srli	x12,	x12,	0 #
    sw	x12, 8(x1)
    srli	x13,	x13,	0 #
    sw	x13, 16(x1)
    srli	x14,	x2,	0 #
    sw	x14, 24(x1)
    addi	x1,	x1,	32 #
    bne	x6,	x0,	loop #
    wfi