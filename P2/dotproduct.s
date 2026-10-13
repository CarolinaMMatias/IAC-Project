.data
    # Sample input arrays
    # You can change this array to test other values (remember to modify the dimensions in the main)
    
    arr0: .word 1, 2, 3, 4
    arr1: .word 10, 20, 30, 40

.text

main:
    # Set up arguments for dotproduct(arr0, arr1, 4)
    la a0, arr0             # a0 = &arr0
    la a1, arr1             # a1 = &arr1
    li a2, 4                # a2 = number of elements

    jal ra, dotproduct      # Call dotproduct function

    # The result of the dot product is now in a0

exit:
    li a7, 10               # Exit syscall code
    ecall                   # Terminate the program


# =======================================================
# FUNCTION: Dot product of 2 int arrays
# Arguments:
#   a0 (int*) - Pointer to the start of arr0
#   a1 (int*) - Pointer to the start of arr1
#   a2 (int)  - Number of elements to use
# Returns:
#   a0 (int)  - The dot product of arr0 and arr1
# Exceptions:
#   - If a2 < 1, exit with error code 38
# =======================================================
dotproduct:
    li t0, 1
    blt a2, t0, exit_with_error    # if size < 1, exit with error (code 38)

    li t1, 0                # t1 = accumulator for the dot product
    li t2, 0                # t2 = loop counter

loop:
    bge t2, a2, end_loop    # when counter = array size: loop ends

    lw t3, 0(a0)            # t3 = arr0[t2]
    lw t4, 0(a1)            # t4 = arr1[t2]
    mul t3, t3, t4          # t3 = arr0[t2] * arr1[t2]
    add t1, t1, t3          # accumulator += t3

    addi t2, t2, 1          # increment loop counter
    addi a0, a0, 4          # a0 += 4 bytes (next element on array)
    addi a1, a1, 4          # a1 += 4 bytes (next element on array)

    j loop

end_loop:
    mv a0, t1               # a0 is the result of the dotproduct (accumulator)
    jr ra                   # return to caller

exit_with_error:
    li a0, 38               # error code 38 for invalid input
    li a7, 93               # exit2 syscall code
    ecall