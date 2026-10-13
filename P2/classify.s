# ===========================================================
# Identificacao do grupo:  [T?? para Tagus ou A?? para Alameda]
# A49
# Membros [istID, primeiro + ultimo nome]
# 1. ist1114476, Antonio Cruz,
# 2. ist1114249, Frederico Silva
# 3. ist1114295, Carolina Matias
#
# ===========================================================
# Requisitos do enunciado que *nao* estao corretamente implementados: 
# (indicar um por linha, ou responder "nenhum")
# - nenhum
#
# ===========================================================
# Top-5 das otimizacoes que a vossa solucao incorpora:                
# (maximo 140 caracteres por cada otimizacao)
#
# 1. Implementação de dotproduct com strides para matmul
#
# 2. Utilização de buffers temporários para a leitura de ficheiros
#    (reduz operações diretas na memória);
#
# 3. Uso de operações bit-shift (slli) para multiplicações por potências de 2
#    (mais rápido que mul para cálculos de offset)
#
# 4. Funções auxiliares de processamento dos ficheiros de input e de pesos 
#    (load_pgm_input e correct_weights)
#
# 5. Verificação da condição do ciclo logo no início 
#    ( evita trabalho desnecessário e torna a execução mais eficiente e segura)
#
# ===========================================================

.data

# ===========================================================
#Main data structures. These definitions cannot be changed.

h_m0: .word 128
w_m0: .word 784
m0: .zero 401408                #h_m0 * w_m0 * 4 bytes

h_m1: .word 10
w_m1: .word 128
m1: .zero 5120                  #h_m1 * w_m1 * 4 bytes

h_input: .word 784
w_input: .word 1
input: .zero 3136               #h_input * w_input * 4 bytes

h_h: .word 128
w_h: .word 1
h: .zero 512                    #h_h * w_h * 4 bytes

h_o: .word 10
w_o: .word 1
o: .zero 40                     #h_o * w_o * 4 bytes


# ===========================================================
# Here you can define any additional data structures that your program might need
# Additional data needed for file paths

.data
m0_path:    .string "m0.bin"    # Path to m0 weights file
m1_path:    .string "m1.bin"    # Path to m1 weights file
input_path: .string "output1.pgm"       # Path to input image file

# Temporary buffers for raw file contents (before processing)
m0_temp: .zero 100352  # Temporary buffer for m0 weights (128×784 bytes)
m1_temp: .zero 1280    # Temporary buffer for m1 weights (10×128 bytes)
input_temp: .zero 796  # Temporary buffer for input image (28×28 pixels) + 12 bytes header 
                       # Note: Header is removed later in load_pgm_input() 

# ===========================================================
.text
main:
    # Set up arguments for classify function

    la a0, m0_path      # pointer to m0 weights file path
    la a1, m1_path      # pointer to m1 weights file path
    la a2, input_path   # pointer to input image file path

    # Call classify function
    jal ra, classify

    # The result (digit classified) is now in a0
    li a7, 1       # Syscall to print the result in a0
    ecall

    # Exit program
    j exit

# ===========================================================
# FUNCTION: abs
#   Computes absolute value of the int stored at a0
# Arguments:
#   a0, a pointer to int
# Returns:
#   Nothing (modifies value in memory)
# ===========================================================
abs:
    lw t0, 0(a0)         # Load int value
    bgez t0, done        # If value >= 0, skip negation
    sub t0, x0, t0       # t0 = -t0
    sw t0, 0(a0)         # Store back to memory

done:
    jr ra                # Return to the caller


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
relu_loop:
    bge t1, a1, relu_loop_end  # Exit when counter >= size
    
    # get the value contained in index t1
    slli t2, t1, 2         # t2 = index * 4 (byte offset)
    add t2, a0, t2         # t2 = address of array[t1]
    lw t3, 0(t2)           # t3 = array[t1] 

    bltz t3, set_zero      # If t3 (array[t1]) < 0, goes to set_zero

    j continue_loop        # Otherwise, continues loop

set_zero:
    li t3, 0               # t3 is now 0, instead of a negative value
    sw t3, 0(t2)           # we store the value of t3 (0) in the respective adress (to change the array)

continue_loop:
    addi t1, t1, 1         # increment loop counter
    j relu_loop            # repeat loop

relu_loop_end:
    jr ra                  # Return to the caller



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
#     this function terminates the program with error code 37
# =================================================================
argmax:
    # 1. size validation
    li t0, 1            # Load constant 1 into t0
    blt a1, t0, argmax_error   # If a1(size of the array) < 1, jump to error
    
    # 2. Initialize variables
    lw t1, 0(a0)           # t1 = current max value (first element)
    li t2, 0               # t2 = current max index (0)
    li t3, 1               # t3 = loop counter (start at 1) 
    
    #3. Loop through array elements
argmax_loop:
    bge t3, a1, end_argmax_loop   # Exit when counter >= size
    
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
    j argmax_loop     
    
# 4. Return result
end_argmax_loop:
    mv a0, t2              # Return index in a0
    jr ra                  # Return to caller

# Error- invalid array size
argmax_error:
    li a0, 37              # Error code 37
    li a7, 93              # Syscall to exit with error
    ecall                  # Exit


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
    blt a2, t0, dotproduct_error    # if size < 1, exit with error (code 38)

    li t1, 0                # t1 = accumulator for the dot product
    li t2, 0                # t2 = loop counter

dotproduct_loop:
    bge t2, a2, end_dotproduct_loop    # when counter = array size: loop ends

    lw t3, 0(a0)            # t3 = arr0[t2]
    lw t4, 0(a1)            # t4 = arr1[t2]
    mul t3, t3, t4          # t3 = arr0[t2] * arr1[t2]
    add t1, t1, t3          # accumulator += t3

    addi t2, t2, 1          # increment loop counter
    addi a0, a0, 4          # a0 += 4 bytes (next element on array)
    addi a1, a1, 4          # a1 += 4 bytes (next element on array)

    j dotproduct_loop

end_dotproduct_loop:
    mv a0, t1               # a0 is the result of the dotproduct (accumulator)
    jr ra                   # Return to the caller

dotproduct_error:
    li a0, 38               # error code 38 for invalid input
    li a7, 93               # exit2 syscall code
    ecall


# =======================================================
# FUNCTION: Matrix Multiplication of 2 integer matrices
#   d = matmul(m0, m1)
#
# Arguments:
#   a0 (int*)  - pointer to the start of m0     (Matrix A)
#   a1 (int*)  - pointer to the start of m1     (Matrix B)
#   a2 (int)   - number of rows in m0 (A)             [rows_A]
#   a3 (int)   - number of columns in m0 (A)          [cols_A]
#   a4 (int)   - number of rows in m1 (B)             [rows_B]
#   a5 (int)   - number of columns in m1 (B)          [cols_B]
#   a6 (int*)  - pointer to the start of d            (Matrix C = A x B)
#
# Returns:
#   None (void); result is stored in memory pointed to by a6 (d)
#
# Exceptions:
#  - If the height or width of any of the matrices is less than 1, 
#    this function terminates the program with error core 39
#  - If the number of columns in matrix A is not equal to the number 
#    of rows in matrix B, it terminates with error code 40
# =======================================================
matmul:
    # Save registers
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
    blt s2, t0, matmul_error_39    # n <1
    blt s3, t0, matmul_error_39    # m <1
    blt s4, t0, matmul_error_39    # B's rows <1
    blt s5, t0, matmul_error_39    # k <1
    bne s3, s4, matmul_error_40    # m != B's rows

    # Save B column stride = k(B columns) * 4 bytes in t0
    slli t0, s5, 2    # t0 = k * 4

    # Outer loop over rows of A (i)
    li s7, 0          # i = 0
matmul_outer_loop:
    bge s7, s2, matmul_end_outer_loop

    # Inner loop over columns of B (j)
    li s8, 0          # j = 0
matmul_inner_loop:
    bge s8, s5, matmul_end_inner_loop

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

    jal ra, matmul_dotproduct

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
    j matmul_inner_loop

matmul_end_inner_loop:
    addi s7, s7, 1    # i++
    j matmul_outer_loop

matmul_end_outer_loop:
    # Restore registers
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

matmul_error_39:
    addi sp, sp, 40   # Restore stack
    li a0, 39
    li a7, 93
    ecall

matmul_error_40:
    addi sp, sp, 40   # Restore stack
    li a0, 40
    li a7, 93
    ecall

# =======================================================
# Updated Dot Product Function with Strides for MatMul
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
matmul_dotproduct:
    li t0, 1
    blt a2, t0, matmul_dotproduct_error

    li t1, 0       # Accumulator
    li t2, 0       # Index
matmul_dotproduct_loop:
    bge t2, a2, matmul_dotproduct_end

    lw t3, 0(a0)
    lw t4, 0(a1)
    mul t5, t3, t4
    add t1, t1, t5

    addi t2, t2, 1
    add a0, a0, a3 # Increment by stride0
    add a1, a1, a4 # Increment by stride1

    j matmul_dotproduct_loop

matmul_dotproduct_end:
    mv a0, t1
    jr ra

matmul_dotproduct_error:
    li a0, 38
    li a7, 93
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
    blt a2, t0, read_file_length_error
    
    # Open file (a0 already contains filename)
    li a1, 0        # Flags: 0 for read-only
    li a7, 1024     # Open system call
    ecall
    
    # Check if file opened successfully
    blt a0, zero, read_file_open_error
    
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

read_file_open_error:
    li a0, 41       # Error code for file descriptor error
    jal exit_with_error

read_file_length_error:
    li a0, 42       # Error code for invalid length
    jal exit_with_error



# ===========================================================
# FUNCTION: correct_weights
#   Adjusts weight matrix values:
#     1. Subtracts 32 from each value (storage format adjustment)
#     2. Converts from 8-bit (byte) to 32-bit (word)
# Arguments:
#   a0 (int*) - Pointer to source buffer (8-bit file data)
#   a1 (int*) - Pointer to destination matrix (32-bit)
#   a2 (int)  - Number of elements (bytes) to process
# Returns:
#   Nothing (modifies destination matrix)
# ===========================================================
correct_weights:
    li t0, 0                  # Initialize counter i = 0
    
correct_loop:
    bge t0, a2, correct_end   # Exit loop if i >= num_elements
    lb t1, 0(a0)              # Load byte (8-bit value)
    addi t1, t1, -32          # Subtract 32
    sw t1, 0(a1)              # Store as 32-bit word
    
    # - Source: 8-bit array -> advance 1 byte per element
    # - Destination: 32-bit array -> advance 1 word (4 bytes) per element
    addi a0, a0, 1            # Next source byte
    addi a1, a1, 4            # Next destination word

    addi t0, t0, 1            # Increment counter
    j correct_loop
    
correct_end:
    jr ra                     # Return

    
# ===========================================================
# FUNCTION: load_pgm_input
#   Loads a binary PGM image:
#     1. Skips the 13-byte header
#     2. Converts 8-bit pixels to 32-bit words
# Arguments:
#   a0 (int*) - Pointer to file buffer (8-bit data with header)
#   a1 (int*) - Pointer to destination matrix (32-bit)
#   a2 (int)  - Number of pixels (e.g. 784 for 28x28 image)
# Returns:
#   None (modifies destination matrix)
# ===========================================================
load_pgm_input:
    li t0, 0                  # Initialize pixel counter
    addi a0, a0, 12           # Skip 12-byte PGM header
    
input_loop:
    bge t0, a2, input_end     # Process all pixels
    lb t1, 0(a0)              # Load 8-bit pixel value
    sw t1, 0(a1)              # Store as 32-bit word
    
    # Same logic as in correct_weights function
    addi a0, a0, 1            # Next source byte
    addi a1, a1, 4            # Next destination word
    
    addi t0, t0, 1            # Increment counter
    j input_loop
    
input_end:
    jr ra                     # Return to caller
    
    
# =======================================================
# FUNCTION: Classify decimal digit from input image
#   d = classify(A, B, input)
#
# Arguments:
#   a0 (string*)  - pathname of file with the weight matrix m0
#   a1 (string*)  - pathname of file with the weight matrix m1
#   a2 (string*)  - pathname of file with the input image in Raw PGM format
#
# Returns:
#   a0 (int) - value of the classified decimal digit
#
# =======================================================
classify:
    # Save registers: s0-s2 saved following RISC-V conventions, though only used locally
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)
    
    # Save arguments
    mv s0, a0        # path to m0
    mv s1, a1        # path to m1
    mv s2, a2        # path to input
    
    # 1. Load m0 weights
    mv a0, s0                 # m0 path
    la a1, m0_temp            # temp buffer (8-bit format)
    li a2, 100352             # size: 128x784 bytes
    jal ra, read_file

    # 2. Adjust m0 weights (subtract 32 + 8-bit format -> 32-bit format)
    la a0, m0_temp
    la a1, m0                 # final matrix (32-bit format)
    li a2, 100352             # byte count
    jal ra, correct_weights

    # 3. Load m1 weights
    mv a0, s1                 # m1 path
    la a1, m1_temp            # temp buffer (8-bit)
    li a2, 1280               # size: 10x128 bytes
    jal ra, read_file

    # 4. Adjust m1 weights (subtract 32 + 8b→32b)
    la a0, m1_temp
    la a1, m1                 # final matrix (32-bit)
    li a2, 1280               # byte count
    jal ra, correct_weights

    # 5. Load input image (PGM)
    mv a0, s2                 # input path
    la a1, input_temp         # temp buffer (8-bit)
    li a2, 796                # 28x28 pixels + 12 header bytes
    jal ra, read_file

    # 6. Process input (skip header + 8b→32b)
    la a0, input_temp         # buffer with header
    la a1, input              # final matrix (32-bit)
    li a2, 784                # pixel count (28x28)
    jal ra, load_pgm_input

    #############################################################
    # With all files loaded into buffers, we can now process the data
    
    # 7. Matrix multiplication: h = m0 × input
    # m0 shape: (128, 784), input shape: (784, 1)
    la a0, m0           # Load address of m0 weight matrix
    la a1, input        # Load address of input image vector
    lw a2, h_m0         # Load m0 rows (128)
    lw a3, w_m0         # Load m0 columns (784)
    lw a4, h_input      # Load input rows (784)
    lw a5, w_input      # Load input columns (1)
    la a6, h            # Load address to store result vector h (128, 1)
    jal ra, matmul      # Matrix multiplication

    # 8. Apply ReLU to h
    la a0, h            # Load address of h vector
    lw a1, h_h          # Load number of elements in h (128)
    jal ra, relu        # Apply ReLU

    # 9. Matrix multiplication: o = m1 × h
    # m1 shape: (10, 128), h shape: (128, 1)
    la a0, m1           # Load address of m1 weight matrix
    la a1, h            # Load address of hidden layer vector
    lw a2, h_m1         # Load m1 rows (10)
    lw a3, w_m1         # Load m1 columns (128)
    lw a4, h_h          # Load h rows (128)
    lw a5, w_h          # Load h columns (1)
    la a6, o            # Load address to store output vector o (10, 1)
    jal ra, matmul      # Matrix multiplication

    # 10. Compute argmax(o): find digit with highest probability
    la a0, o            # Load address of output vector
    lw a1, h_o          # Load number of classes (10)
    jal ra, argmax      # Returns index (0-9) of max value

    # Restore registers
    lw ra, 12(sp)
    lw s0, 8(sp)
    lw s1, 4(sp)
    lw s2, 0(sp)
    addi sp, sp, 16
    jr ra

# =======================================================
# Exit procedures
# =======================================================

# Exits the program (with code 0)
exit:
    li a7, 10     # Exit syscall code
    ecall         # Terminate the program

# Exits the program with an error 
# a0 contains the error code
exit_with_error:
  li a7, 93            # Exit system call
  ecall     