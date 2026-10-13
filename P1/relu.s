.data
# You can change this array to test other values
array: .word -3, 2, -1, 7, 2   # Initial array values				 

.text

main:
  la a0, array      # a0 = pointer to array
  li a1, 5          # a1 = number of elements in the array

  jal ra, relu      # Call relu function

  # Result: the array now has its negative values replaced by zero
    
exit:
  li a7, 10              # Exit syscall code
  ecall                  # Terminate the program


# ============================================================
# FUNCTION: relu
#   Applies ReLU on each element of the array (in-place)
# Arguments:
#   a0 = pointer to int array
#   a1 = array length
# Exceptions:
#   - If the length of the array is less than 1,
#     this function terminates the program with error code 36
# ============================================================
relu:
    # 1. size validation
    li t0, 1                      # Load constant 1 into t0
    blt a1, t0, exit_with_error   # If a1(size of the array) < 1, jump to error

    # 2 Inicialize loop counter (starts at 0)
    li t1, 0

    # 3- loop
    loop:
        bge t1, a1, loop_end  # Exit when counter >= size
        
        # get the value contained in index t1
        slli t2, t1, 2         # t2 = index * 4 (byte offset)
        add t2, a0, t2         # t2 = address of array[t1]
        lw t3, 0(t2)           # t3 = array[t1] 
    
        bltz t3, set_zero      # If t4 (array[t1]) < 0, goes to set_zero
    
        j continue_loop        # Otherwise, continues loop
    
    set_zero:
        li t3, 0               # t3 is now 0, instead of a negative value
        sw t3, 0(t2)           # we store the value of t3 (0) in the respective adress (to change the array)

    continue_loop:
        addi t1, t1, 1         # increment loop counter
        j loop                 # repeat loop
    
loop_end:
  jr ra                  # normal return


# Exits the program with an error 
# Arguments: 
# a0 (int) is the error code 
# You need to load a0 the error to a0 before to jump here
exit_with_error:
  li a0, 36            # Error code 36
  li a7, 93            # Exit system call
  ecall                # Terminate program