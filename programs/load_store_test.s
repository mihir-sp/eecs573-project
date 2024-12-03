# Data Section

.data

    array:      .space  16        # Allocate space for an array of 4 bytes (16 bytes total)


# Text Section

.text

    # Store words into array

    li   x13, 0x12345678  # Load immediate word value

    sw   x13, array       # Store word at the beginning of the array


    li   x1, 0xAABBCCDD  # Load another immediate word value

    sw   x1, 4(array)    # Store word at index 4 in the array


    # Load words from array

    lw   x2, array       # Load word from the beginning of the array

    lw   x3, 4(array)    # Load word from index 4 in the array


    # Store bytes into array

    li   x4, 0xFF        # Load immediate byte value

    sb   x4, 8(array)    # Store byte at index 8 in the array


    li   x5, 0x55        # Load another immediate byte value

    sb   x5, 9(array)    # Store byte at index 9 in the array


    # Load bytes from array

    lb   x6, 8(array)    # Load byte from index 8 in the array

    lb   x7, 9(array)    # Load byte from index 9 in the array


    # Exit program

    li   a7, 10          # Load immediate value 10 into register a7 (system call code for exit)

    wfi                # Make a system call to exit the program

