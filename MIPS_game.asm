#####################################################################
#
# CSCB58 Winter 2024 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Adam Skinner, 1009191517, skinn109, adam.skinner@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4
# - Unit height in pixels: 4
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestoneshave been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 4
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Moving objects
# 2. Disappearing platforms
# 3. Enemies shoot back
#
# Link to video demonstration for final submission:
# - https://play.library.utoronto.ca/watch/aca2c37f375ecd3eee7b270c5a7fa645
#
# Are you OK with us sharing the video with people outside course staff?
# - Yes, I am okay with sharing the video with others. (didn't use GitHub)
#
# Any additional information that the TA needs to know:
# - To win the game you need to touch the white "flag" on the top
# - You have 4 hearts and loose one each time you contact an enemy/bullet
# - Loosing all 4 goes to the game over screen
# - You can also go to the game over screen by pressing 'q'
# - Pressing 'r' at any time during gameplay restarts the game (getting to win/fail screen terminates the program)
#####################################################################
.data
# arrays for beginning and ending points of floor & each platform
PLATFORM_BEGIN: .word 0x1000BF00, 0x1000B340, 0x1000A680, 0x10009920
PLATFORM_END: .word 0x1000BFFC, 0x1000B390, 0x1000A6E4, 0x10009984
CURRENT_POSITION: .word 0x1000BE04
CURRENT_ENEMY_A_STATE: .word 1
CURRENT_ENEMY_B_STATE: .word 1
ENEMY_A_LOC: .word 0x1000A5B0
ENEMY_B_LOC: .word 0x10009820
ON_PLATFORM: .word 0
END_FLAG: .word 0x10008EE0
CURRENT_LEVEL: .word 1
G_ACCEL: .word -1
X_ACCEL: .word 0
COUNTER: .word 10
PLAT_COUNTER: .word 60
CURRENT_HEALTH: .word 4
HEALTH_CHANGED: .word 0
HEART_LOC: .word 0x10008100 0x10008118 0x10008130 0x10008148
HEART_OFFSET: .word 12
TOP_PLATFORMS_EXIST: .word 0
BULLET_1_ACTIVE: .word 0
BULLET_2_ACTIVE: .word 0
BULLET_1_POS: .word 0x1000A5A8
BULLET_2_POS: .word 0x1000985C
	
.text
.eqv DISPLAY_ADDRESS 0x10008000
.eqv KBD_BASE	0xffff0000
.eqv PLATFORM_COLOUR 0xff9614
.eqv ENEMY_A_STATE_1 0x1000A5B0
.eqv ENEMY_A_STATE_2 0x1000A5E0
.eqv ENEMY_B_STATE_1 0x10009820
.eqv ENEMY_B_STATE_2 0x10009850
.eqv JUMP_POWER 18
.eqv SIDE_ACCEL 2
.eqv PLAT_1_OFFSET 0x10008FD4
.eqv PLAT_2_OFFSET 0x10008FB4
.eqv BULLET_1_RESET 0x1000A5A8
.eqv BULLET_2_RESET 0x1000985C
.globl main
main:
	li $t0, DISPLAY_ADDRESS			# $t0 stores the base address for display
	addi $t0, $t0, 16128 			# set $t0 to address of bottom row
	
	li $t7, DISPLAY_ADDRESS			# $t7 set to first pixel to remove
	addi $sp , $sp , -4 			# push to stack
	sw $t7, 0($sp)
	jal CLEAR_SCREEN 			# clears the screen
	
	li $t1, PLATFORM_COLOUR	 		# store PLATFORM_COLOUR in $t1
DRAW_FLOOR: bgt $t0, 0x1000BFFC, DRAW_PLAT_1
	sw $t1, 0($t0) 				# set colour of current pixel
	addi $t0, $t0, 4
	j DRAW_FLOOR
DRAW_PLAT_1:
	li $t0, DISPLAY_ADDRESS
	addi $t0, $t0, 13120 			# start pos of first platform
	addi $t2, $t0, 80
	loop: bgt $t0, $t2, DRAW_PLAT_2
	sw $t1, 0($t0)
	addi $t0, $t0, 4
	j loop
DRAW_PLAT_2:
	li $t0, DISPLAY_ADDRESS
	addi $t0, $t0, 9856 			# start pos of second platform
	addi $t2, $t0, 100
	loop2: bgt $t0, $t2, DRAW_PLAT_3
	sw $t1, 0($t0)
	addi $t0, $t0, 4
	j loop2
DRAW_PLAT_3:
	li $t0, DISPLAY_ADDRESS
	addi $t0, $t0, 6432 			# start pos of third platform
	addi $t2, $t0, 100
	loop3: bgt $t0, $t2, DRAW_HEARTS
	sw $t1, 0($t0)
	addi $t0, $t0, 4
	j loop3
DRAW_HEARTS:
	la $t9, HEART_LOC
	li $t0, 0
	hearts_loop: bgt $t0, 3, DRAW_FLAG
	lw $t1, 0($t9)
	addi $sp, $sp, -4
	sw $t1, 0($sp)
	jal DRAW_HEART
	addi $t9, $t9, 4
	addi $t0, $t0, 1
	j hearts_loop
DRAW_FLAG:
	la $t3, END_FLAG
	lw $t4, 0($t3)
	li $t1, 0xffffff 			# sets the colour to white
	sw $t1, 0($t4) 	 			# draws bottom pixel
	sw $t1, -256($t4) 	
	sw $t1, -512($t4) 	
	sw $t1, -768($t4) 			# draws top pixel 	
	
PRE_MAIN_LOOP:
	li $t9, KBD_BASE			# assigns $t9 to address of keyboard input
MAIN_LOOP:
	lw $t3, CURRENT_POSITION 		# assigns $t3 to the current position of the player
	li $v0, 32
	li $a0, 33				# updates screen at about 30 fps
	syscall


check_input:
	lw $t8, 4($t9) 				# takes input from keyboard
	bne $t8, 0x61, not_a 			# checks if input is not "a"
						# then input must be "a"
	addi $t7, $t3, -4 			# left of bottom pixel
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, clear_input			# if there was a collision, jump to clear_input
	
	addi $t7, $t3, -260 			# left of middle pixel (-4-256 = -260)
	addi $sp, $sp, -4			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, clear_input			# if there was a collision, jump to clear_input
	
	addi $t7, $t3, -516 			# left of top pixel (-4-512 = -516)
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, clear_input			# if there was a collision, jump to clear_input
	
	sub $t7, $0, SIDE_ACCEL			# negative side acceleration (left)
	sw $t7, X_ACCEL
	
	jal CLEAR_PLAYER
	addi $t3, $t3, -4			# if key is "a" then move current pixel 1 to the left
	j clear_input
	
not_a: bne $t8, 0x64, not_d			# checks if input is not "d"
						# then input must be "d"
	addi $t7, $t3, 4 			# right of bottom pixel
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, clear_input			# if there was a collision, jump to clear_input
	
	addi $t7, $t3, -252 			# right of middle pixel (4-256 = -252)
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, clear_input			# if there was a collision, jump to clear_input
	
	addi $t7, $t3, -508 			# left of top pixel (4-512 = -508)
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, clear_input			# if there was a collision, jump to clear_input
	
	addi $t7, $0, SIDE_ACCEL		# positive side acceleration (right)
	sw $t7, X_ACCEL
	
	jal CLEAR_PLAYER
	addi $t3, $t3, 4			# if key is d then move the current pixel 1 to the right
	j clear_input

not_d: bne $t8, 0x77, continue			# checks if input is not "w"
						# then input must be "w"
	lw $t7, ON_PLATFORM			# checks if player is on platform
	beq $t7, 0, clear_input			# if player is not on platform, don't jump
	addi $t7, $0, 0
	sw $t7, ON_PLATFORM			# change ON_PLATFORM accordingly
	
	addi $t7, $0, JUMP_POWER		# assign acceleration to positive
	sw $t7, G_ACCEL
	
	addi $t7, $t3, -768 			# check three pixels up
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4
	beq $t7, 1, clear_input			# if there was a collision, jump to clear_input
	
	jal CLEAR_PLAYER
	addi $t3, $t3, -256			# if key is w move up

clear_input:
	li $t8, 0				# sets the currently pressed key back to nothing
	sw $t8, 4($t9)
	
continue:
	addi $sp, $sp, -4 			# push $t3 onto the stack
	sw $t3, 0($sp)
	jal COLLIDE 				# checking for collision with enemies
	
	beq $t8, 0x71, GAME_OVER_SCREEN
	beq $t8, 0x72, RESTART
	
check_pos_x_accel:
	lw $t8, X_ACCEL
	ble $t8, 0, check_neg_x_accel
	
	# Positive x acceleration
	addi $t7, $t3, 4 			# check pixel to the right for collision
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp)	 			# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, decrease_x_accel 		# can't continue moving right
	
	addi $t7, $t3, -252 			# right of middle pixel (4-256 = -252)
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, decrease_x_accel 		# can't continue moving right
	
	addi $t7, $t3, -508 			# left of top pixel (4-512 = -508)
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, decrease_x_accel 		# can't continue moving right
	
	jal CLEAR_PLAYER
	addi $t3, $t3, 4

decrease_x_accel: 
	lw $t8, X_ACCEL
	addi $t8, $t8, -1			# slow down x accel
	sw $t8, X_ACCEL
	j zero_x_accel
	
check_neg_x_accel:
	lw $t8, X_ACCEL
	beq $t8, 0, zero_x_accel
	
	# Negative x acceleration
	addi $t7, $t3, -4			# left of bottom pixel
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, increase_x_accel		# can't continue moving left
	
	addi $t7, $t3, -260 			# left of middle pixel (-4-256 = -260)
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, increase_x_accel		# can't continue moving left
	
	addi $t7, $t3, -516 			# left of top pixel (-4-512 = -516)
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	beq $t7, 1, increase_x_accel		# can't continue moving left
	
	jal CLEAR_PLAYER
	addi $t3, $t3, -4
	
increase_x_accel:
	lw $t8, X_ACCEL
	addi $t8, $t8, 1			# slow x accel (from negative)
	sw $t8, X_ACCEL

zero_x_accel: # label to skip all x checks since no x acceleration

check_neg_y_accel:
	addi $t7, $t3, 256 			# below bottom pixel
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4 
	sw $t7, ON_PLATFORM 			# collision means on a platform
	beq $t7, 1, check_pos_y_accel 		# if there is a collision don't fall

	lw $t8, G_ACCEL
	bgt $t8, -1, check_pos_y_accel		# if G_ACCEL is non-negative then don't go down

	jal CLEAR_PLAYER
	addi $t3, $t3, 256
	j draw_player

check_pos_y_accel:
	lw $t8, G_ACCEL
	beq $t8, -1, draw_player 		# if negative, don't go up
	beq $t8, 0, zero_y_accel		# don't go up if less than or equal to zero
	
	addi $t7, $t3, -768 			# check three pixels up
	addi $sp, $sp, -4 			# push $t7 onto the stack
	sw $t7, 0($sp)
	jal COLLIDE
	lw $t7, 0($sp) 				# load return value
	addi $sp, $sp, 4
	beq $t7, 1, zero_y_accel
	
	jal CLEAR_PLAYER
	addi $t3, $t3, -256
	
zero_y_accel:
	addi $t8, $t8, -1
	sw $t8, G_ACCEL
	
draw_player:
	li $t1, 0xff006f 			# $t1 stores the colour pink
	sw $t1, 0($t3) 				# draws bottom pixel of character
	sw $t1, -256($t3) 			# draws middle pixel of character
	sw $t1, -512($t3) 			# draws top pixel of character
	
	la $t8, CURRENT_POSITION	# assigns $t8 to the address where it shows the current position of the player
	sw $t3, 0($t8)			# changes the current position of the player
check_counter:
	la $t2, COUNTER
	lw $t2, 0($t2)
	blt $t2, 10, update_counter
move_enemy_A:	
	lw $t8, CURRENT_ENEMY_A_STATE	# move enemy depending on state
	beq $t8, 2, move_enemy_A_2
	# move_enemy_A_1
	li  $t7, ENEMY_A_STATE_2	# assign $t7 to new enemy position
	li $t8, 2 			# move to state 2
	j update_enemy_A
move_enemy_A_2:
	la $t4, BULLET_1_ACTIVE
	li $t5, 1
	sw $t5, 0($t4)
	li $t7, ENEMY_A_STATE_1		# assign $t7 to new enemy position
	li $t8, 1			# move to state 1
update_enemy_A:
	li $t1, 0
	lw $t4, ENEMY_A_LOC		# $t4 stores current location of enemy
	sw $t1, 0($t4) 			# remove current enemy
	sw $t1, 4($t4)
	sw $t1, 8($t4)
	
	li $t1, 0xff0000		# $t1 stores the colour for drawing the enemies
	sw $t1, 0($t7) 			# redraw enemy in new location
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	
	sw $t8, CURRENT_ENEMY_A_STATE
	sw $t7, ENEMY_A_LOC
move_enemy_B:
	lw $t8, CURRENT_ENEMY_B_STATE	# move enemy depending on state
	beq $t8, 2, move_enemy_B_2
	# move_enemy_B_1
	li  $t7, ENEMY_B_STATE_2	# assign $t7 to new enemy position
	li $t8, 2 			# move to state 2
	j update_enemy_B
move_enemy_B_2:
	la $t4, BULLET_2_ACTIVE
	li $t5, 1
	sw $t5, 0($t4)
	li $t7, ENEMY_B_STATE_1		# assign $t7 to new enemy position
	li $t8, 1			# move to state 1
update_enemy_B:
	li $t1, 0
	lw $t4, ENEMY_B_LOC		# $t4 stores current location of enemy
	sw $t1, 0($t4) 			# remove current enemy
	sw $t1, 4($t4)
	sw $t1, 8($t4)
	
	li $t1, 0xff0000		# $t1 stores the colour for drawing the enemies
	sw $t1, 0($t7) 			# redraw enemy in new location
	sw $t1, 4($t7)
	sw $t1, 8($t7)
	
	sw $t8, CURRENT_ENEMY_B_STATE
	sw $t7, ENEMY_B_LOC
update_hearts:
	la $t1, HEALTH_CHANGED
	lw $t2, 0($t1)
	beq $t2, 0, reset_counter	# don't update hearts if health didn't decrease
	li $t8, 0
	sw $t8, 0($t1)			# reset HEALTH_CHANGED
	
	la $t1, HEART_LOC
	
	la $t7, HEART_OFFSET		# offset for heart location array 
	lw $t6, 0($t7)
	
	add $t1, $t1, $t6
	lw $t8, 0($t1)			# store location of heart to remove
	addi $sp, $sp, -4
	sw $t8, 0($sp)
	
	jal DEL_HEART
	
	addi $t6, $t6, -4
	sw $t6, 0($t7)
	blt $t6, 0, GAME_OVER_SCREEN
reset_counter:
	li $t2, -1
update_counter:
	addi $t2, $t2, 1
	la $t1, COUNTER
	sw $t2, 0($t1)
	
check_plat_counter:
	la $t2, PLAT_COUNTER
	lw $t2, 0($t2)
	blt $t2, 60, update_plat_counter
update_platforms:
	la $t1, TOP_PLATFORMS_EXIST
	lw $t3, 0($t1)
	li $t1, PLATFORM_COLOUR
	beq $t3, 0, draw		# platforms aren't drawn so draw them
	li $t1, 0x000000		# otherwise remove them
	draw: li $t2, PLAT_1_OFFSET
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 12($t2)
	sw $t1, 16($t2)
	
	li $t2, PLAT_2_OFFSET
	sw $t1, 0($t2)
	sw $t1, 4($t2)
	sw $t1, 8($t2)
	sw $t1, 12($t2)
	sw $t1, 16($t2)
	
	beq $t3, 0, set_1
	li $t3, 0
	j set_done
	set_1:
	li $t3, 1
	set_done:
	la $t1, TOP_PLATFORMS_EXIST
	sw $t3, 0($t1)

reset_plat_counter:
	li $t2, -1
update_plat_counter:
	addi $t2, $t2, 1
	la $t1, PLAT_COUNTER
	sw $t2, 0($t1)
	
update_bullets:
	la $t1, BULLET_1_ACTIVE
	lw $t2, 0($t1)
	beq $t2, 0, bullet_2
	la $t1, BULLET_1_POS
	lw $t2, 0($t1)
	
	li $t3, 0x000000
	sw $t3, 0($t2)
	
	addi $t2, $t2, -4
	blt $t2, 0x1000A500, set_1_inactive
	li $t3, 0xff0000
	sw $t3, 0($t2)
	j bullet_2
	set_1_inactive:
	la $t5, BULLET_1_ACTIVE
	li $t2, 0
	sw $t2, 0($t5)	
	li $t2, BULLET_1_RESET
	
	bullet_2:
	sw $t2, 0($t1)			# update bullet 1 location
	la $t1, BULLET_2_ACTIVE
	lw $t2, 0($t1)
	beq $t2, 0, MAIN_LOOP_END
	la $t1, BULLET_2_POS
	lw $t2, 0($t1)
	
	li $t3, 0x000000
	sw $t3, 0($t2)
	
	addi $t2, $t2, 4
	bgt $t2, 0x100098FC, set_2_inactive
	li $t3, 0xff0000
	sw $t3, 0($t2)
	j end_bullets
	set_2_inactive:
	la $t5, BULLET_2_ACTIVE
	li $t2, 0
	sw $t2, 0($t5)	
	li $t2, BULLET_2_RESET
	end_bullets: sw $t2, 0($t1)
	
	
MAIN_LOOP_END: j MAIN_LOOP # jumps back to loop

RESTART:
	li $t7, DISPLAY_ADDRESS
	addi $sp, $sp, -4 			# push to stack
	sw $t7, 0($sp)
	jal CLEAR_SCREEN 			# clear screen
	
	addi $t8, $0, 0				# clear input
	sw $t8, 4($t9)
	
	la $t1, CURRENT_POSITION 		# reset player pos
	li $t2, 0x1000BE04
	sw $t2, 0($t1)
	
	la $t1, CURRENT_HEALTH			# reset player health
	li $t2, 4
	sw $t2, 0($t1)
	la $t1, HEART_OFFSET
	li $t2, 12
	sw $t2, 0($t1)
	
	j main

END:
	li $v0, 10 # terminate the program
	syscall
	
CLEAR_SCREEN:			# function clears the screen
	li $s1, 0x00000000	# assign temp value for the 0x00000000
	lw $s0, 0($sp) 		# load location
	addi $sp, $sp, 4
	
CLEAR_LOOP:			
	sw $s1, 0($s0)			# clear current pixel
	addi $s0, $s0, 4		# iterate to the next pixel
	bgt $s0, 0x1000BFFC, END_CLEAR	# end at last pixel
	j CLEAR_LOOP
END_CLEAR: jr $ra
	
COLLIDE:			# s0 is the location to be checked, #s2 is the return value (either 1 or 0)
	lw $s0, 0($sp) 		# load location	
	addi $sp, $sp, 4
	la $s3, PLATFORM_BEGIN 	# s3 is set to array of starting points for platforms
	la $s4, PLATFORM_END 	# s4 set to array of end points
FLOOR: 
	lw $s1, 0($s3) 		# beginning of floor
	lw $s5, 0($s4) 		# end of floor
FLOOR_LOOP: bgt $s1, $s5, PLAT_1 # finished checking floor
	beq $s0, $s1, RETURN_COLLIDE # collision with floor
	addi $s1, $s1, 4
	j FLOOR_LOOP
	
PLAT_1:
	lw $s1, 4($s3) 		# beginning of platform 1
	lw $s5, 4($s4) 		# end of platform 1
PLAT_1_LOOP: bgt $s1, $s5, PLAT_2 # finished checking platform 1
	beq $s0, $s1, RETURN_COLLIDE # collision with platform 1
	addi $s1, $s1, 4
	j PLAT_1_LOOP
	
PLAT_2:
	lw $s1, 8($s3) 		# beginning of platform 2
	lw $s5, 8($s4) 		# end of platform 2
PLAT_2_LOOP: bgt $s1, $s5, PLAT_3 # finished checking platform 2
	beq $s0, $s1, RETURN_COLLIDE # collision with platform 2
	addi $s1, $s1, 4
	j PLAT_2_LOOP

PLAT_3:
	lw $s1, 12($s3) 	# beginning of platform 3
	lw $s5, 12($s4) 	# end of platform 3
PLAT_3_LOOP: bgt $s1, $s5, LEFT_WALL # finished checking platform 3
	beq $s0, $s1, RETURN_COLLIDE # collision with platform 3
	addi $s1, $s1, 4
	j PLAT_3_LOOP

LEFT_WALL:
	li $s1, DISPLAY_ADDRESS # top of left wall
	li $s5, 0x1000BE00 	# bottom of left wall
LEFT_WALL_LOOP: bgt $s1, $s5, RIGHT_WALL # finished checking left wall
	beq $s0, $s1, RETURN_COLLIDE
	addi $s1, $s1, 256
	j LEFT_WALL_LOOP
	
RIGHT_WALL:
	li $s1, 0x100080FC 	# top of right wall
	li $s5, 0x1000BEFC 	# bottom of right wall
RIGHT_WALL_LOOP: bgt $s1, $s5, CEILING
	beq $s0, $s1, RETURN_COLLIDE
	addi $s1, $s1, 256
	j RIGHT_WALL_LOOP

CEILING:
	li $s1, DISPLAY_ADDRESS # left of ceiling
	li $s5, 0x100080FC 	# right of ceiling
CEILING_LOOP: bgt $s1, $s5, CHECK_COLLIDE_ENEMIES # no collision with ceiling
	beq $s0, $s1, RETURN_COLLIDE
	addi $s1, $s1, 4
	j CEILING_LOOP
	
CHECK_COLLIDE_ENEMIES:
	la $s3, ENEMY_A_LOC 	# assign addresses of current enemy locations
	la $s4, ENEMY_B_LOC
	li $s7, 0
	lw $s5, 0($s3)
	lw $s6, 0($s4)
	la $s3, BULLET_1_POS
	la $s4, BULLET_2_POS
	lw $s1, 0($s3)
	lw $s3, 0($s4)
	beq $s0, $s1, DECREASE_HEALTH
	beq $s0, $s3, DECREASE_HEALTH
COLLIDE_ENEMIES_LOOP: bgt $s7, 2, CHECK_COLLIDE_FLAG
	beq $s0, $s5, DECREASE_HEALTH # collision with enemy
	beq $s0, $s6, DECREASE_HEALTH
	addi $s5, $s5, 4
	addi $s6, $s6, 4
	addi $s7, $s7, 1
	j COLLIDE_ENEMIES_LOOP
DECREASE_HEALTH:
	la $s0, HEALTH_CHANGED 	# health has been changed
	li $s5, 1
	sw $s5, 0($s0)
	
	la $s0, CURRENT_HEALTH	# decrease health
	lw $s5, 0($s0)
	addi $s5, $s5, -1
	sw $s5, 0($s0)
CHECK_COLLIDE_FLAG:		# check for collision with winning flag
	la $s1, END_FLAG
	lw $s2, 0($s1)
	flag_loop: blt $s2, 0x10008BE0, CHECK_COLLIDE_TOP_PLAT
	beq $s0, $s2, WIN_SCREEN
	addi $s2, $s2, -256
	j flag_loop
CHECK_COLLIDE_TOP_PLAT:		# check for collision with disappearing platforms
	la $s1, TOP_PLATFORMS_EXIST
	lw $s1, 0($s1)
	beq $s1, 0, RETURN_NO_COLLIDE
	
	li $s1, PLAT_1_OFFSET
	addi $s2, $s1, 20
	top_plat_loop_1: bgt $s1, $s2, top_plat_2
	beq $s0, $s1, RETURN_COLLIDE
	addi $s1, $s1, 4
	j top_plat_loop_1
	
	top_plat_2:
	li $s1, PLAT_2_OFFSET
	addi $s2, $s1, 20
	top_plat_loop_2: bgt $s1, $s2, RETURN_NO_COLLIDE
	beq $s0, $s1, RETURN_COLLIDE
	addi $s1, $s1, 4
	j top_plat_loop_2
	
RETURN_COLLIDE:
	li $s2, 1
RETURN_COLLIDE_VAL: addi $sp , $sp , -4 # push $s2 (return value) onto the stack
	sw $s2, 0($sp)
	jr $ra
RETURN_NO_COLLIDE:
	li $s2, 0
	j RETURN_COLLIDE_VAL

DRAW_HEART:
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	
	li $s1, 0xFA7389	# pink
	
	sw $s1, 0($s0)
	addi $s0, $s0, 4
	
	sw $s1, -256($s0)
	sw $s1, 0($s0)
	sw $s1, 256($s0)
	addi $s0, $s0, 4
	
	sw $s1, 0($s0)
	sw $s1, 256($s0)
	sw $s1, 512($s0)
	addi $s0, $s0, 4
	
	sw $s1, -256($s0)
	sw $s1, 0($s0)
	sw $s1, 256($s0)
	addi $s0, $s0, 4
	
	sw $s1, 0($s0)
	jr $ra

DEL_HEART:
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	
	li $s1, 0x000000	# black
	
	sw $s1, 0($s0)
	addi $s0, $s0, 4
	
	sw $s1, -256($s0)
	sw $s1, 0($s0)
	sw $s1, 256($s0)
	addi $s0, $s0, 4
	
	sw $s1, 0($s0)
	sw $s1, 256($s0)
	sw $s1, 512($s0)
	addi $s0, $s0, 4
	
	sw $s1, -256($s0)
	sw $s1, 0($s0)
	sw $s1, 256($s0)
	addi $s0, $s0, 4
	
	sw $s1, 0($s0)
	jr $ra	
	
DRAW_X:	# draws along the x axis
	# $t1 is the colour, $t3 is the start, $t4 is the end
DRAW_X_LOOP:
	bgt $t3,$t4,DRAW_X_LOOP_END 	# done when $t3 done drawing the pixel at $t4
	sw $t1, 0($t3) 			# colours current pixel for platform
	addi $t3, $t3, 4 		# moves $t3 to the next pixel
	j DRAW_X_LOOP
DRAW_X_LOOP_END:	
	jr $ra

DRAW_Y:	# draws along the y axis
	# $t1 is the colour, $t3 is the start, $t4 is the end
DRAW_Y_LOOP:
	bgt $t3, $t4, DRAW_Y_LOOP_END	# done when $t3 done drawing the pixel at $t4
	sw $t1, 0($t3) 			# draws current pixel for platform
	addi $t3, $t3, 256 		# moves $t3 to the next pixel
	j DRAW_Y_LOOP
DRAW_Y_LOOP_END:
	jr $ra
	
WIN_SCREEN:
	li $t7, DISPLAY_ADDRESS # assigns $t7 to the first pixel to remove
	addi $sp, $sp, -4 	# push to stack
	sw $t7, 0($sp)
	jal CLEAR_SCREEN 	# clears the screen
	li $t1, 0xffffff 	# $t1 stores the colour white
	# draw y
	li $t3, 0x1000994C	# assign $t3 to (19,25)
	addi $t4, $t3, 512	# assign $t4 to (19,27)
	jal DRAW_Y
	li $t3, 0x10009950	# assign $t3 to (20,25)
	addi $t4, $t3, 768	# assign $t4 to (20,27)
	jal DRAW_Y
	
	li $t3, 0x10009C54	# assign $t3 to (21,28)
	addi $t4, $t3, 768	# assign $t4 to (21,31)
	jal DRAW_Y
	li $t3, 0x10009C58	# assign $t3 to (22,28)
	addi $t4, $t3, 768	# assign $t4 to (22,31)
	jal DRAW_Y
	
	li $t3, 0x1000995C	# assign $t3 to (23,25)
	addi $t4, $t3, 768	# assign $t4 to (23,27)
	jal DRAW_Y
	li $t3, 0x10009960	# assign $t3 to (24,25)
	addi $t4, $t3, 512	# assign $t4 to (24,27)
	jal DRAW_Y
	
	# draw o
	li $t3, 0x10009A70	# assign $t3 to (28,26)
	addi $t4, $t3, 1024	# assign $t4 to (28,30)
	jal DRAW_Y
	li $t3, 0x10009A74	# assign $t3 to (29,26)
	addi $t4, $t3, 1024	# assign $t4 to (29,30)
	jal DRAW_Y
	li $t3, 0x10009a84	# assign $t3 to (33,26)
	addi $t4, $t3, 1024	# assign $t4 to (33,30)
	jal DRAW_Y
	li $t3, 0x10009A88	# assign $t3 to (34,26)
	addi $t4, $t3, 1024	# assign $t4 to (34,30)
	jal DRAW_Y
	li $t3, 0x10009974	# assign $t3 to (29,25)
	addi $t4, $t3, 16	# assign $t4 to (33,25)
	jal DRAW_X
	li $t3, 0x10009F74	# assign $t3 to (29,31)
	addi $t4, $t3, 16	# assign $t4 to (33,31)
	jal DRAW_X

	#draw u
	li $t3, 0x10009994	# assign $t3 to (37,25)
	addi $t4, $t3, 1280	# assign $t4 to (37,30)
	jal DRAW_Y
	li $t3, 0x10009998	# assign $t3 to (38,25)
	addi $t4, $t3, 1280	# assign $t4 to (38,30)
	jal DRAW_Y
	li $t3, 0x100099A8	# assign $t3 to (42,25)
	addi $t4, $t3, 1280	# assign $t4 to (42,30)
	jal DRAW_Y
	li $t3, 0x100099ac	# assign $t3 to (43,25)
	addi $t4, $t3, 1280	# assign $t4 to (43,30)
	jal DRAW_Y
	li $t3, 0x10009F98	# assign $t3 to (38,31)
	addi $t4, $t3, 16	# assign $t4 to (42,31)
	jal DRAW_X
	# draw w
	li $t3, 0x1000A44C	# assign $t3 to (19,36)
	addi $t4, $t3, 1536	# assign $t4 to (19,42)
	jal DRAW_Y
	li $t3, 0x1000A450	# assign $t3 to (20,36)
	addi $t4, $t3, 1536	# assign $t4 to (20,42)
	jal DRAW_Y
	li $t3, 0x1000A754	# assign $t3 to (21,39)
	addi $t4, $t3, 512	# assign $t4 to (21,41)
	jal DRAW_Y
	li $t3, 0x1000A658	# assign $t3 to (22,38)
	addi $t4, $t3, 512	# assign $t4 to (20,42)
	jal DRAW_Y
	li $t3, 0x1000A75C	# assign $t3 to (23,39)
	addi $t4, $t3, 512	# assign $t4 to (20,42)
	jal DRAW_Y
	li $t3, 0x1000A460	# assign $t3 to (24,36)
	addi $t4, $t3, 1536	# assign $t4 to (24,42)
	jal DRAW_Y
	li $t3, 0x1000A464	# assign $t3 to (25,36)
	addi $t4, $t3, 1536	# assign $t4 to (25,42)
	jal DRAW_Y
	# draw i
	li $t3, 0x1000A474	# assign $t3 to (29,36)
	addi $t4, $t3, 20	# assign $t4 to (34,36)
	jal DRAW_X
	li $t3, 0x1000Aa74	# assign $t3 to (29,42)
	addi $t4, $t3, 20	# assign $t4 to (34,42)
	jal DRAW_X
	li $t3, 0x1000A57C	# assign $t3 to (31,37)
	addi $t4, $t3, 1024	# assign $t4 to (24,42)
	jal DRAW_Y
	li $t3, 0x1000A580	# assign $t3 to (32,37)
	addi $t4, $t3, 1024	# assign $t4 to (25,42)
	jal DRAW_Y
	#draw n
	li $t3, 0x1000A494	# assign $t3 to (37,36)
	addi $t4, $t3, 1536	# assign $t4 to (37,42)
	jal DRAW_Y
	li $t3, 0x1000A498	# assign $t3 to (38,36)
	addi $t4, $t3, 1536	# assign $t4 to (38,42)
	jal DRAW_Y
	li $t3, 0x1000A59C	# assign $t3 to (39,37)
	addi $t4, $t3, 512	# assign $t4 to (39,39)
	jal DRAW_Y
	li $t3, 0x1000A6A0	# assign $t3 to (40,38)
	addi $t4, $t3, 512	# assign $t4 to (40,42)
	jal DRAW_Y
	li $t3, 0x1000A7A4	# assign $t3 to (41,39)
	addi $t4, $t3, 512	# assign $t4 to (41,42)
	jal DRAW_Y
	li $t3, 0x1000A4A8	# assign $t3 to (42,36)
	addi $t4, $t3, 1536	# assign $t4 to (42,42)
	jal DRAW_Y
	li $t3, 0x1000A4AC	# assign $t3 to (43,36)
	addi $t4, $t3, 1536	# assign $t4 to (43,42)
	jal DRAW_Y
	
	j END
	
GAME_OVER_SCREEN:
	li $t7, DISPLAY_ADDRESS # assigns $t7 to the first pixel to remove
	addi $sp, $sp, -4 # push to stack
	sw $t7, 0($sp)
	jal CLEAR_SCREEN 	# clears the screen
	# draws game over
	# draw g
	li $t1, 0xffffff # $t1 stores the colour white
	li $t3, 0x10008A38	# assign $t3 to (14,10)
	sw $t1, 0($t3)
	addi $t3, $t3, 256	# assign $t3 to (14,11)
	sw $t1, 0($t3)
	addi $t3, $t3, 256	# assign $t3 to (14,12)
	sw $t1, 0($t3)
	li $t3, 0x1000893C	# assign $t3 to (15,9)
	sw $t1, 0($t3)
	addi $t3, $t3, 256	# assign $t3 to (15,10)
	sw $t1, 0($t3)
	addi $t3, $t3, 256	# assign $t3 to (15,11)
	sw $t1, 0($t3)
	addi $t3, $t3, 256	# assign $t3 to (15,12)
	sw $t1, 0($t3)
	addi $t3, $t3, 256	# assign $t3 to (15,13)
	sw $t1, 0($t3)
	addi $t3, $t3, 4	# assign $t3 to (16,13)
	sw $t1, 0($t3)
	addi $t3, $t3, 256	# assign $t3 to (16,14)
	sw $t1, 0($t3)
	addi $t3, $t3, 4	# assign $t3 to (17,14)
	sw $t1, 0($t3)
	addi $t3, $t3, 4	# assign $t3 to (18,14)
	sw $t1, 0($t3)
	addi $t3, $t3, 4	# assign $t3 to (19,14)
	sw $t1, 0($t3)
	addi $t3, $t3, 4	# assign $t3 to (20,14)
	sw $t1, 0($t3)
	addi $t3, $t3, -256	# assign $t3 to (20,13)
	sw $t1, 0($t3)
	addi $t3, $t3, -256	# assign $t3 to (20,12)
	sw $t1, 0($t3)
	addi $t3, $t3, -256	# assign $t3 to (20,11)
	sw $t1, 0($t3)
	addi $t3, $t3, -4	# assign $t3 to (19,11)
	sw $t1, 0($t3)
	addi $t3, $t3, 256	# assign $t3 to (19,12)
	sw $t1, 0($t3)
	addi $t3, $t3, 256	# assign $t3 to (19,13)
	sw $t1, 0($t3)
	addi $t3, $t3, -516	# assign $t3 to (18,11)
	sw $t1, 0($t3)
	li $t3, 0x10008940 	# assign $t3 to (16,9)
	sw $t1, 0($t3)
	li $t3, 0x10008840	# assign $t3 to (16,8)
	li $t4, 0x10008850	# assign $t4 to (20,8)
	jal DRAW_X
	#draw a
	li $t3, 0x10008A5C	# assign $t3 to (23,10)
	addi $t4, $t3, 1024	# assign $t4 to (23,14)
	jal DRAW_Y
	li $t3, 0x10008960	# assign $t3 to (24,9)
	addi $t4, $t3, 1280	# assign $t4 to (24,14)
	jal DRAW_Y
	li $t3, 0x10008970	# assign $t3 to (24,9)
	addi $t4, $t3, 1280	# assign $t4 to (24,14)
	jal DRAW_Y
	li $t3, 0x10008A74	# assign $t3 to (29,10)
	addi $t4,$t3,1024	# assign $t4 to (29,14)
	jal DRAW_Y
	li $t3, 0x10008C64	# assign $t3 to (25,12)
	addi $t4, $t3, 12	# assign $t4 to (27,12)
	jal DRAW_X
	li $t3, 0x10008864	# assign $t3 to (25,8)
	addi $t4, $t3, 8	# assign $t4 to (27,8)
	jal DRAW_X
	# draw m
	li $t3, 0x10008880	# assign $t3 to (32,8)
	addi $t4, $t3, 1536	# assign $t4 to (32,14)
	jal DRAW_Y
	li $t3, 0x10008884	# assign $t3 to (33,8)
	addi $t4, $t3, 1536	# assign $t4 to (33,14)
	jal DRAW_Y
	li $t3, 0x10008894	# assign $t3 to (37,8)
	addi $t4, $t3, 1536	# assign $t4 to (37,14)
	jal DRAW_Y
	li $t3, 0x10008898	# assign $t3 to (38,8)
	addi $t4, $t3, 1536	# assign $t4 to (38,14)
	jal DRAW_Y
	
	li $t3, 0x10008988	# assign $t3 to (34,9)
	addi $t4, $t3, 256	# assign $t4 to (34,10)
	jal DRAW_Y
	li $t3, 0x10008A8C	# assign $t3 to (35,10)
	addi $t4, $t3, 256	# assign $t4 to (35,11)
	jal DRAW_Y
	li $t3, 0x10008990	# assign $t3 to (36,9)
	addi $t4, $t3, 256	# assign $t4 to (36,10)
	jal DRAW_Y
	# draw e
	li $t3, 0x100088A4	# assign $t3 to (41,8)
	addi $t4, $t3, 1536	# assign $t4 to (41,14)
	jal DRAW_Y
	li $t3, 0x100088A8	# assign $t3 to (42,8)
	addi $t4, $t3, 1536	# assign $t4 to (42,14)
	jal DRAW_Y
	li $t3, 0x100088AC	# assign $t3 to (43,8)
	addi $t4, $t3, 16	# assign $t4 to (47,8)
	jal DRAW_X
	li $t3, 0x10008BAC	# assign $t3 to (43,11)
	addi $t4, $t3, 12	# assign $t4 to (47,11)
	jal DRAW_X		
	li $t3, 0x10008EAC	# assign $t3 to (43,14)
	addi $t4, $t3, 16	# assign $t4 to (47,14)
	jal DRAW_X
	#draw o
	li $t3, 0x10009438	# assign $t3 to (14,20)
	addi $t4, $t3, 1024	# assign $t4 to (14,24)
	jal DRAW_Y
	li $t3, 0x1000943c	# assign $t3 to (15,20)
	addi $t4, $t3, 1024	# assign $t4 to (15,24)
	jal DRAW_Y
	li $t3, 0x1000944c	# assign $t3 to (19,20)
	addi $t4, $t3, 1024	# assign $t4 to (19,24)
	jal DRAW_Y
	li $t3, 0x10009450	# assign $t3 to (20,20)
	addi $t4, $t3, 1024	# assign $t4 to (20,24)
	jal DRAW_Y
	li $t3, 0x1000933C	# assign $t3 to (15,19)
	addi $t4, $t3, 16	# assign $t4 to (19,19)
	jal DRAW_X
	li $t3, 0x1000993C	# assign $t3 to (15,25)
	addi $t4, $t3, 16	# assign $t4 to (19,25)
	jal DRAW_X
	# draw v
	li $t3, 0x1000935C	# assign $t3 to (23,19)
	addi $t4, $t3, 768	# assign $t4 to (23,22)
	jal DRAW_Y
	li $t3, 0x10009360	# assign $t3 to (24,19)
	addi $t4, $t3, 768	# assign $t4 to (24,22)
	jal DRAW_Y
	li $t3, 0x10009760	# assign $t3 to (24,23)
	addi $t4, $t3, 4	# assign $t4 to (25,23)
	jal DRAW_X
	li $t3, 0x1000976c	# assign $t3 to (27,23)
	addi $t4, $t3, 4	# assign $t4 to (28,23)
	jal DRAW_X
	li $t3, 0x10009864	# assign $t3 to (25,24)
	addi $t4, $t3, 8	# assign $t4 to (27,24)
	jal DRAW_X
	li $t3, 0x10009370	# assign $t3 to (23,19)
	addi $t4, $t3, 768	# assign $t4 to (23,22)
	jal DRAW_Y
	li $t3, 0x10009374	# assign $t3 to (24,19)
	addi $t4, $t3, 768	# assign $t4 to (24,22)
	jal DRAW_Y
	li $t3, 0x10009968	# assign $t3 to (14,10)
	sw $t1, 0($t3)
	# draw e
	li $t3, 0x10009380	# assign $t3 to (32,19)
	addi $t4, $t3, 1536	# assign $t4 to (32,25)
	jal DRAW_Y
	li $t3, 0x10009384	# assign $t3 to (33,19)
	addi $t4, $t3, 1536	# assign $t4 to (33,25)
	jal DRAW_Y
	li $t3, 0x10009388	# assign $t3 to (34,19)
	addi $t4, $t3, 16	# assign $t4 to (38,19)
	jal DRAW_X
	li $t3, 0x10009688	# assign $t3 to (34,22)
	addi $t4, $t3, 12	# assign $t4 to (37,22)
	jal DRAW_X		
	li $t3, 0x10009988	# assign $t3 to (34,25)
	addi $t4, $t3, 16	# assign $t4 to (38,25)
	jal DRAW_X
	# draw r
	li $t3, 0x100093A4	# assign $t3 to (41,19)
	addi $t4, $t3, 1536	# assign $t4 to (41,25)
	jal DRAW_Y
	li $t3, 0x100093A8	# assign $t3 to (42,19)
	addi $t4, $t3, 1536	# assign $t4 to (42,25)
	jal DRAW_Y
	li $t3, 0x100093AC	# assign $t3 to (42,19)
	addi $t4, $t3, 12	# assign $t4 to (46,19)
	jal DRAW_X
	addi $t3,$0,0x100094B8	# assign $t3 to (46,20)
	addi $t4,$t3,512	# assign $t4 to (46,22)
	jal DRAW_Y
	li $t3, 0x100094BC	# assign $t3 to (47,20)
	addi $t4, $t3, 512	# assign $t4 to (47,22)
	jal DRAW_Y
	li $t3, 0x100096B4	# assign $t3 to (45,22)
	addi $t4, $t3, 256	# assign $t4 to (45,24)
	jal DRAW_Y
	li $t3, 0x100098B0	# assign $t3 to (44,24)
	addi $t4, $t3, 8	# assign $t4 to (46,24)
	jal DRAW_X
	li $t3, 0x100099B4	# assign $t3 to (45,25)
	addi $t4, $t3, 8	# assign $t4 to (47,25)
	jal DRAW_X
	
	j END
	
CLEAR_PLAYER:				# assumes that $t1 is not in use and $t3 is the current player's center
	li $t1, 0x000000 		# $t1 stores the colour black
	sw $t1, 0($t3) 		# draws bottom pixel of character
	sw $t1, -256($t3) 	# draws middle pixel of character
	sw $t1, -512($t3) 	# draws top pixel of character
	jr $ra
