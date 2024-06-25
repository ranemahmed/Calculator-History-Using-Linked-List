.data
    # Prompt messages for user selection
    prompt:           .asciiz "\n1.Addition.\n2.Subtraction.\n3.Multiplication.\n4.Division.\n5.View history.\n6.Delete no..\n7.Use previous result.\n8.Previous result.\n9.Exit.\n"
    # Constants for handling floats
    zeroFloat:        .float 0.0              # zero as a float to be used in moving floats
    # Size of each node in bytes
    node_size:        .word   8
    # Newline character for separating values
    newline:          .asciiz "\n"
    # Error messages
    nodeNotFound:     .asciiz "Number not found"
    noPreviousNumber: .asciiz "There is no previous number.\n"
    msg_empty:        .asciiz "No more values to display.\n"
    # Linked list pointers
    list_head:        .word   0          # Pointer to the head of the list

.text
main:
    # Load zero float value into register $f11
    lwc1 $f11, zeroFloat

start:
    # Print the menu prompt
    li $v0,4
    la $a0, prompt
    syscall

    # Get user's selection
    li $v0, 5
    syscall

    # Branch based on user's input
    beq $v0,1,Addition
    beq $v0,2,Subtraction
    beq $v0,3,Multiplication
    beq $v0,4,Division
    beq $v0,5,print
    beq $v0,6,delete_float
    beq $v0,7,use_previous_result
    beq $v0,8,printItem
    beq $v0,9,Exit

Exit:
    # Terminate the program
    li $v0, 10
    syscall

# Function to get two floats used by mathematical functions
GetTwoFloats:
    # Check if only one float is needed
    beq $t7, 1, GetOneFloat

    # Get the first float
    li $v0, 6 
    syscall
    add.s $f1, $f0, $f11 # Move the input to f1

GetOneFloat:
    # Get the second float
    li $v0, 6
    syscall
    add.s $f2, $f0, $f11 # Move the second input to f2

    # Reset flag to avoid continuously using the previous result
    li $t7, 0
    jr $ra

# Function to print the result of mathematical operations
PrintResult:
    li $v0,2
    syscall
    jr $ra

# Function to use the previous result
use_previous_result:
    # Load the address of the head of the linked list
    lw $t6, list_head
    # Check if the list is empty
    bne $t6, $zero, ResultExists
    # If list is empty, print error message
    li $v0,4
    la $a0,noPreviousNumber
    syscall
    j start

ResultExists:
    # Set flag to ask for one number only from the user in the next operation
    li $t7, 1
    # Load the first value from the list into f1
    lwc1 $f1, 0($t6)
    j start

# Addition function
Addition:
    jal GetTwoFloats
    add.s $f12, $f1, $f2
    jal PrintResult # Print the result
    jal insert_float # Insert the result into the linked list
    lw $s5, list_head
    j start

# Subtraction function
Subtraction:
    jal GetTwoFloats
    sub.s $f12, $f1, $f2
    jal PrintResult # Print the result
    jal insert_float # Insert the result into the linked list
    lw $s5, list_head
    j start

# Multiplication function
Multiplication:
    jal GetTwoFloats
    mul.s $f12, $f1, $f2
    jal PrintResult # Print the result
    jal insert_float # Insert the result into the linked list
    lw $s5, list_head
    j start

# Division function
Division:
    jal GetTwoFloats
    div.s $f12, $f1, $f2
    jal PrintResult # Print the result
    jal insert_float # Insert the result into the linked list
    lw $s5, list_head
    j start

# Function to print the values in the linked list
print:
    # Load the address of the head of the list
    lw $t0, list_head
    j print_loop

print_loop:
    # If current node is null, end loop
    beq $t0, $zero, print_end
    # Load float value of current node
    lwc1 $f12, 0($t0)
    # Print float value
    li $v0, 2
    syscall
    # Print newline
    li $v0, 4
    la $a0, newline
    syscall
    # Move to next node
    lw $t0, 4($t0)
    j print_loop

print_end:
    # Return to the start
    lw $t0, list_head
    j start

# Function to insert a float into the linked list
# $f12 = value to insert
insert_float:
    # Allocate memory for new node
    li $v0, 9
    lw $a0, node_size
    syscall
    move $t0, $v0

    # Store float value in the new node
    swc1 $f12, 0($t0)

    # Insert node at the beginning of the list
    lw $t1, list_head
    sw $t1, 4($t0)
    sw $t0, list_head
    jr $ra

# Function to delete a node containing a specific float value
# $f12 = float value to delete

delete_float:
    li $v0,6
    syscall
    lw $t0, list_head
    li $t2, 0

delete_loop:
    beq $t0, $zero, delete_end
    lwc1 $f1, 0($t0)
    c.eq.s $f1, $f0
    bc1t delete_node
    move $t2, $t0
    lw $t0, 4($t0)
    j delete_loop

delete_node:
    beq $t2, $0, DeleteHead
    lw $t1, 4($t0)
    sw $t1, 4($t2)
    j start

DeleteHead:
    lw $t2, 4($t0)
    sw $t2, list_head
    lw $s5, list_head
    j start

delete_end:
    # Print message indicating the node was not found
    li $v0, 4
    la $a0, nodeNotFound
    syscall
    j start 

# Function to print the data of the first node in the list
printItem:
    # Check if the list is empty
    beq $s5, $zero, empty
    # Print the data of the first node
    li $v0, 2 
    lwc1 $f12, 0($s5)
    syscall
    lw $s5,4($s5)
    j end

empty:
    # Print message indicating that the list is empty
    li $v0, 4
    la $a0, msg_empty
    syscall

end:
    j start
