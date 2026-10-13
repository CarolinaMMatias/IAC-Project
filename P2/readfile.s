.data

buffer_input:  .zero 796  # (file 28*28 + 12)
null:          .string ""

file_input:     .string "output.pgm"

.text

main:
    # Read both input files
    # read the image inputs

    la  a0, file_input       # a0 = pointer to filename
    la  a1, buffer_input     # a1 = pointer to buffer
    li  a2, 796              # a2 = number of bytes to read
    jal ra, read_file        # call read_file
    
   
    la a0, buffer_input
    li a7, 4                 # PrintString call
    ecall

    # Exit program
    li a7, 10                # syscall: exit
    ecall


######################################################################
# Function: read_file(char* filename, byte* buffer, int length)
# Input:
#   a0: pointer to null-terminated filename string
#   a1: destination buffer
#   a2: number of bytes to read
# Output:
#   a0: number of bytes read (return value from syscall)
# Exceptions:
#   - Error code 41 if error in the file descriptor
#   - Error code 42 If the length of the bytes to read is less than 1
######################################################################

read_file:
    # Save registers we'll modify (except a0 which is return value)
    addi sp, sp, -12
    sw ra, 8(sp)
    sw a1, 4(sp)    # Save buffer pointer
    sw a2, 0(sp)    # Save length
    
    # Check if length is valid (>= 1)
    li t0, 1
    blt a2, t0, length_error
    
    # Open file (a0 already contains filename)
    li a1, 0        # Flags: 0 for read-only
    li a7, 1024     # Open system call
    ecall
    
    # Check if file opened successfully
    blt a0, zero, open_error
    
    # Save file descriptor
    mv t0, a0       # t0 = file descriptor
    
    # Read file (a1 already contains buffer, a2 contains length)
    mv a0, t0       # File descriptor
    lw a1, 4(sp)    # Restore buffer pointer
    lw a2, 0(sp)    # Restore length
    li a7, 63       # Read system call
    ecall
    
    # Save bytes read (return value)
    mv t1, a0       # t1 = bytes read
    
    # Close file
    mv a0, t0       # File descriptor
    li a7, 57       # Close system call
    ecall
    
    # Return bytes read
    mv a0, t1
    
    # Restore registers
    lw ra, 8(sp)
    addi sp, sp, 12
    jr ra           # Return to caller

open_error:
    li a0, 41       # Error code for file descriptor error
    jal exit_with_error

length_error:
    li a0, 42       # Error code for invalid length
    jal exit_with_error

# Exits the program with an error 
# Arguments: 
# a0 (int) is the error code 
exit_with_error:
    li a7, 93       # Exit system call
    ecall           # Terminate