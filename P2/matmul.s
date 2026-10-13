.data

# You can change this array to test other values (remember to modify the dimentions in the main)
m0: .word 1, 2, 3, 4, 5, 6        # Matrix A (2x3) in row-major order
m1: .word 7, 8, 9, 10, 11, 12     # Matrix B (3x2) in row-major order
d:  .word 0, 0, 0, 0              # Output matrix C (2x2), initialized to 0

.text
main:
  # Load pointers to matrices
  la a0, m0                     # a0 = address of matrix A
  la a1, m1                     # a1 = address of matrix B
  la a6, d                      # a6 = address of output matrix C

  # Load matrix dimensions
  li a2, 2                      # a2 = rows of A = 2
  li a3, 3                      # a3 = cols of A = 3
  li a4, 3                      # a4 = rows of B = 3
  li a5, 2                      # a5 = cols of B = 2
  
  # Load input type 
  jal ra, matmul                # Call matrix multiplication function

  # The contents of matrix d now have the result of matmul(m0,m1)
  
  # Test
  lw t0, 0(a6)  # 58
  lw t1, 4(a6)  # 64
  lw t2, 8(a6)  # 139
  lw s0, 12(a6) # 154

exit:
  li a7, 10              # Exit syscall code
  ecall                  # Terminate the program
  


# =======================================================
# FUNCTION: Matrix Multiplication of 2 matrices
# Arguments:
#   a0 (int*) - Pointer to matrix A
#   a1 (int*) - Pointer to matrix B
#   a2 (int)  - Number of rows (n) in A
#   a3 (int)  - Number of columns (m) in A (and rows in B)
#   a4 (int)  - Number of rows (m) in B (must equal a3)
#   a5 (int)  - Number of columns (k) in B
#   a6 (int*) - Pointer to matrix C (output)
# Returns:
#   None
# Exceptions:
#   - Code 39 if dimensions are <1
#   - Code 40 if A's columns != B's rows
# =======================================================
matmul:
    # Prologue: Save registers
    addi sp, sp, -40
    sw ra, 36(sp)
    sw s0, 32(sp)
    sw s1, 28(sp)
    sw s2, 24(sp)
    sw s3, 20(sp)
    sw s4, 16(sp)
    sw s5, 12(sp)
    sw s6, 8(sp)
    sw s7, 4(sp)
    sw s8, 0(sp)

    # Save arguments
    mv s0, a0    # A
    mv s1, a1    # B
    mv s2, a2    # n
    mv s3, a3    # m
    mv s4, a4    # B's rows (must equal m)
    mv s5, a5    # k
    mv s6, a6    # C

    # Check for dimension errors
    li t0, 1
    blt s2, t0, error_39    # n <1
    blt s3, t0, error_39    # m <1
    blt s4, t0, error_39    # B's rows <1
    blt s5, t0, error_39    # k <1
    bne s3, s4, error_40    # m != B's rows

    # Save B column stride = k(B columns) * 4 bytes in t0
    slli t0, s5, 2    # t0 = k * 4

    # Outer loop over rows of A (i)
    li s7, 0          # i = 0
outer_loop:
    bge s7, s2, end_outer_loop

    # Inner loop over columns of B (j)
    li s8, 0          # j = 0
inner_loop:
    bge s8, s5, end_inner_loop

    # Compute A_row_i address: A + i * cols_A(m) * 4
    mul t1, s7, s3    # i * m
    slli t1, t1, 2    # * 4 bytes
    add a0, s0, t1    # a0 = &A[i][0]

    # Compute B_col_j address: B + j * 4
    slli t2, s8, 2    # j * 4
    add a1, s1, t2    # a1 = &B[0][j]

    # Set arguments for dotproduct
    mv a2, s3         # m elements
    li a3, 4          # A's stride (4 bytes)
    mv a4, t0         # B's stride (k * 4 bytes)

    # Save temporaries
    addi sp, sp, -12
    sw t0, 8(sp)
    sw s7, 4(sp)
    sw s8, 0(sp)

    jal ra, dotproduct

    # Restore temporaries
    lw s8, 0(sp)
    lw s7, 4(sp)
    lw t0, 8(sp)
    addi sp, sp, 12

    # C dimensions - n * k 
    # C[i][j] address: C + 4 * (i * k + j)
    mul t3, s7, s5    # i * k
    add t3, t3, s8    # i * k + j
    slli t3, t3, 2    # * 4 bytes
    add t4, s6, t3    # t4 = C[i][j]
    
    # Store result obtained from dotproduct at the respective address in C
    sw a0, 0(t4)      


    addi s8, s8, 1    # j++
    j inner_loop

end_inner_loop:
    addi s7, s7, 1    # i++
    j outer_loop

end_outer_loop:
    # Epilogue: Restore registers
    lw ra, 36(sp)
    lw s0, 32(sp)
    lw s1, 28(sp)
    lw s2, 24(sp)
    lw s3, 20(sp)
    lw s4, 16(sp)
    lw s5, 12(sp)
    lw s6, 8(sp)
    lw s7, 4(sp)
    lw s8, 0(sp)
    addi sp, sp, 40
    jr ra

error_39:
    addi sp, sp, 40   # Restore stack
    li a0, 39
    li a7, 93
    ecall

error_40:
    addi sp, sp, 40   # Restore stack
    li a0, 40
    li a7, 93
    ecall

# =======================================================
# Updated Dot Product Function with Strides
# Arguments:
#   a0 (int*) - Pointer to arr0
#   a1 (int*) - Pointer to arr1
#   a2 (int)  - Number of elements
#   a3 (int)  - Stride for arr0 (bytes)
#   a4 (int)  - Stride for arr1 (bytes)
# Returns:
#   a0 (int)  - Dot product
# Exceptions:
#   - Code 38 if a2 <1
# =======================================================
dotproduct:
    li t0, 1
    blt a2, t0, exit_with_error_dot

    li t1, 0       # Accumulator
    li t2, 0       # Index
loop_dot:
    bge t2, a2, end_dot

    lw t3, 0(a0)
    lw t4, 0(a1)
    mul t5, t3, t4
    add t1, t1, t5

    addi t2, t2, 1
    add a0, a0, a3 # Increment by stride0
    add a1, a1, a4 # Increment by stride1

    j loop_dot

end_dot:
    mv a0, t1
    jr ra

exit_with_error_dot:
    li a0, 38
    li a7, 93
    ecall