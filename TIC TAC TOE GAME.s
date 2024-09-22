.data
board:     .space 36  # Allocating 36 bytes (9 boxes for tic tac toe)
heading:   .asciiz "-------------------------TIC TAC TOE GAME BY AAWEEZA FAROOQUI-------------------------\n"
playerX:   .asciiz "X"
playerO:   .asciiz "O"
empty:     .asciiz " "
newline:   .asciiz "\n"
prompt:    .asciiz "Enter position (1-9): "
error:     .asciiz "Invalid move. Try again.\n"
separator: .asciiz "---\n"
player_turn: .word 1
turn_msg_x: .asciiz "Player X's turn\n"
turn_msg_o: .asciiz "Player O's turn\n"
win_msg_x:  .asciiz "Player X wins!\n"
win_msg_o:  .asciiz "Player O wins!\n"
draw_msg:   .asciiz "It's a draw!\n"
sample_board: .asciiz "1 2 3\n-----\n4 5 6\n-----\n7 8 9\n\n"
.text
.globl main

# Initialize the board with zeros
init_board:
    la $t0, board          # Load address of the board
    li $t1, 9              # Number of positions on the board
init_loop:
    li $t2, 0              # Zero value to initialize each position
    sw $t2, 0($t0)         # Store zero in the board position
    addi $t0, $t0, 4       # Move to the next board position (4 bytes for each int)
    sub $t1, $t1, 1        # Decrement the counter
    bnez $t1, init_loop    # Repeat until all positions are initialized
    jr $ra                 # Return to caller (main)

# Display the current board state
display_board:
    la $t0, board          # Load address of the board
    li $t1, 0              # Initialize position counter
display_loop:
    lw $t2, 0($t0)         # Load board value at the current position
    beq $t2, 0, print_empty # If the position is empty, print empty space
    beq $t2, 1, print_x    # If the position is marked by player X, print X
    beq $t2, 2, print_o    # If the position is marked by player O, print O
print_empty:
    la $a0, empty          # Load address of the empty string
    j print_char           # Jump to print_char
print_x:
    la $a0, playerX        # Load address of the player X string
    j print_char           # Jump to print_char
print_o:
    la $a0, playerO        # Load address of the player O string
print_char:
    li $v0, 4              # System call for print string
    syscall                # Make the system call
    addi $t0, $t0, 4       # Move to the next board position
    addi $t1, $t1, 1       # Increment the position counter
    li $t3, 3              # Constant for modulo calculation
    rem $t4, $t1, $t3      # Calculate position counter modulo 3
    bnez $t4, skip_separator # If not at the end of a row, skip separator
    la $a0, newline        # Load address of newline string
    li $v0, 4              # System call for print string
    syscall                # Make the system call
    la $a0, separator      # Load address of the separator string
    li $v0, 4              # System call for print string
    syscall                # Make the system call
skip_separator:
    li $t5, 9              # Constant for total board positions
    bne $t1, $t5, display_loop # If not all positions are printed, repeat loop
    jr $ra                 # Return to caller (main)

# Get player's move and update the board
get_player_move:
    la $a0, prompt         # Load address of the prompt string
    li $v0, 4              # System call for print string
    syscall                # Make the system call
    li $v0, 5              # System call for read integer
    syscall                # Make the system call
    sub $t0, $v0, 1        # Convert 1-9 input to 0-8 board index
    blt $t0, 0, invalid_move # If input is less than 0, invalid move
    bgt $t0, 8, invalid_move # If input is greater than 8, invalid move
    la $t1, board          # Load address of the board
    sll $t0, $t0, 2        # Calculate byte offset (index * 4)
    add $t1, $t1, $t0      # Calculate address of the board position
    lw $t2, 0($t1)         # Load the board value at the position
    bnez $t2, invalid_move # If position is not empty, invalid move
    lw $t3, player_turn    # Load current player turn
    sw $t3, 0($t1)         # Update board position with player mark
    jr $ra                 # Return to caller (main_loop)
invalid_move:
    la $a0, error          # Load address of the error message string
    li $v0, 4              # System call for print string
    syscall                # Make the system call
    j get_player_move      # Jump to get_player_move to retry

# Check if the board is full
check_full:
    la $t0, board          # Load address of the board
    li $t1, 9              # Number of positions on the board
check_full_loop:
    lw $t2, 0($t0)         # Load board value at the current position
    beqz $t2, not_full     # If any position is empty, board is not full
    addi $t0, $t0, 4       # Move to the next board position
    sub $t1, $t1, 1        # Decrement the counter
    bnez $t1, check_full_loop # Repeat until all positions are checked
    # Board is full
    la $a0, draw_msg       # Load address of the draw message string
    li $v0, 4              # System call for print string
    syscall                # Make the system call
    li $v0, 10             # System call for exit
    syscall                # Make the system call
not_full:
    jr $ra                 # Return to caller (main_loop)

# Check win condition
check_win:
    la $t0, board          # Load address of the board
    # Check rows
    li $t1, 0              # Initialize row counter
check_rows:
    lw $t2, 0($t0)         # Load first position of the row
    lw $t3, 4($t0)         # Load second position of the row
    lw $t4, 8($t0)         # Load third position of the row
    beq $t2, 0, next_row   # If first position is empty, check next row
    beq $t2, $t3, check_row_second # If first and second positions are equal
    j next_row             # Otherwise, check next row
check_row_second:
    beq $t3, $t4, win_detected # If second and third positions are equal
next_row:
    addi $t0, $t0, 12      # Move to the next row (3 positions * 4 bytes)
    addi $t1, $t1, 1       # Increment the row counter
    li $t5, 3              # Total number of rows
    bne $t1, $t5, check_rows # If not all rows are checked, repeat

    # Check columns
    la $t0, board          # Load address of the board
    li $t1, 0              # Initialize column counter
check_cols:
    lw $t2, 0($t0)         # Load first position of the column
    lw $t3, 12($t0)        # Load second position of the column
    lw $t4, 24($t0)        # Load third position of the column
    beq $t2, 0, next_col   # If first position is empty, check next column
    beq $t2, $t3, check_col_second # If first and second positions are equal
    j next_col             # Otherwise, check next column
check_col_second:
    beq $t3, $t4, win_detected # If second and third positions are equal
next_col:
    addi $t0, $t0, 4       # Move to the next column (4 bytes)
    addi $t1, $t1, 1       # Increment the column counter
    li $t5, 3              # Total number of columns
    bne $t1, $t5, check_cols # If not all columns are checked, repeat

    # Check diagonals
    la $t0, board          # Load address of the board
    # First diagonal (1, 5, 9)
    lw $t2, 0($t0)         # Load first position of the diagonal
    lw $t3, 16($t0)        # Load second position of the diagonal
    lw $t4, 32($t0)        # Load third position of the diagonal
    beq $t2, 0, check_anti_diagonal # If first position is empty, check anti-diagonal
    beq $t2, $t3, check_diag_second # If first and second positions are equal
    j check_anti_diagonal  # Otherwise, check anti-diagonal
check_diag_second:
    beq $t3, $t4, win_detected # If second and third positions are equal

    # Second diagonal (3, 5, 7)
check_anti_diagonal:
    lw $t2, 8($t0)         # Load first position of the anti-diagonal
    lw $t3, 16($t0)        # Load second position of the anti-diagonal
    lw $t4, 24($t0)        # Load third position of the anti-diagonal
    beq $t2, 0, end_check_win # If first position is empty, end check win
    beq $t2, $t3, check_anti_diag_second # If first and second positions are equal
    jr $ra                 # Return to caller (main_loop)
check_anti_diag_second:
    beq $t3, $t4, win_detected # If second and third positions are equal
    jr $ra                 # Return to caller (main_loop)

win_detected:
    lw $t1, player_turn    # Load current player turn
    li $t2, 1              # Check if player X
    beq $t1, $t2, player_x_wins # If player X, jump to player_x_wins
    li $t2, 2              # Check if player O
    beq $t1, $t2, player_o_wins # If player O, jump to player_o_wins
player_x_wins:
    la $a0, win_msg_x      # Load address of the win message for player X
    li $v0, 4              # System call for print string
    syscall                # Make the system call
    li $v0, 10             # System call for exit
    syscall                # Make the system call
player_o_wins:
    la $a0, win_msg_o      # Load address of the win message for player O
    li $v0, 4              # System call for print string
    syscall                # Make the system call
    li $v0, 10             # System call for exit
    syscall                # Make the system call
end_check_win:
    jr $ra                 # Return to caller (main_loop)

# Main function
main:
    li $v0, 4              # System call for print string
    la $a0, heading        # Load address of the heading string
    syscall                # Make the system call
    jal init_board         # Jump to init_board (initializes the board)
    la $a0, sample_board   # Load address of the sample board string
    li $v0, 4              # System call for print string
    syscall                # Make the system call
main_loop:
    lw $t0, player_turn    # Load current player turn
    li $t1, 1              # Check if player X's turn
    beq $t0, $t1, turn_player_x # If player X's turn, jump to turn_player_x
    li $t1, 2              # Check if player O's turn
    beq $t0, $t1, turn_player_o # If player O's turn, jump to turn_player_o
turn_player_x:
    la $a0, turn_msg_x     # Load address of the turn message for player X
    li $v0, 4              # System call for print string
    syscall                # Make the system call
    j continue_main        # Jump to continue_main
turn_player_o:
    la $a0, turn_msg_o     # Load address of the turn message for player O
    li $v0, 4              # System call for print string
    syscall                # Make the system call
    j continue_main        # Jump to continue_main
continue_main:
    jal get_player_move    # Jump to get_player_move (get and validate player move)
    jal display_board      # Jump to display_board (display the current board)
    jal check_win          # Jump to check_win (check if there's a win)
    jal check_full         # Jump to check_full (check if the board is full)
    # Switch player turn
    lw $t0, player_turn    # Load current player turn
    li $t1, 1              # Constant for player X
    li $t2, 2              # Constant for player O
    beq $t0, $t1, switch_to_o # If current player is X, switch to O
    beq $t0, $t2, switch_to_x # If current player is O, switch to X
switch_to_o:
    li $t1, 2              # Set player turn to O
    sw $t1, player_turn    # Store player turn
    j main_loop            # Jump to main_loop (continue the game loop)
switch_to_x:
    li $t1, 1              # Set player turn to X
    sw $t1, player_turn    # Store player turn
    j main_loop            # Jump to main_loop (continue the game loop)
