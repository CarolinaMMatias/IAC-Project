.data
# You can change this array to test other values
array: .word 5, 9, 3, 9, 2   # Initial array values

.text

main:
    la a0, array           # Load address of the array
    li a1, 5               # Number of elements in the array

    jal ra, argmax         # Call the argmax function

    # Result: the index of the largest element is now in a0

exit:
    li a7, 10              # Exit syscall code
    ecall                  # Terminate the program


# =================================================================
# FUNCTION: Given an int array, return the index of the largest
#   element. If there are multiple, return the one
#   with the smallest index.
# Arguments:
#   a0 (int*) is the pointer to the start of the array
#   a1 (int)  is the number of elements in the array
# Returns:
#   a0 (int)  is the first index of the largest element
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 36
# =================================================================
argmax:  
    # 1. size validation
    li t0, 1            # Load constant 1 into t0
    blt a1, t0, error   # If a1(size of the array) < 1, jump to error
    
    # 2. Initialize variables
    lw t1, 0(a0)           # t1 = current max value (first element)
    li t2, 0               # t2 = current max index (0)
    li t3, 1               # t3 = loop counter (start at 1) 
    
    #3. Loop through array elements
    loop:
        bge t3, a1, end_loop   # Exit when counter >= size
        
        # get the value contained in index t3
        slli t4, t3, 2         # t4 = index * 4 (byte offset)
        add t4, a0, t4         # t4 = address of array[t3]
        lw t5, 0(t4)           # t5 = array[t3]
        
        # Compare with current max value
        ble t5, t1, not_greater # If current value <= max, skip to not_greater
       
        # Update the max value and the respective index
        mv t1, t5
        mv t2, t3
        
        not_greater:
            # Increment counter and repeat loop
            addi t3, t3, 1
            j loop     
        
    # 4. Return result
    end_loop:
        mv a0, t2              # Return index in a0
        jr ra                  # Return to caller

    # Error- invalid array size
    error:
        li a0, 36           # Error code 36
        li a7, 93           # Syscall to exit with error
        ecall               # Exit