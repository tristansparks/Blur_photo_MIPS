
.data

#Must use accurate file path.
#These file paths are EXAMPLES, 
#should not work for you
str1:	.asciiz "/Users/apple/Documents/Cours/McGill/Fall2017/COMP 273/A4/test1.txt"
str3:	.asciiz "/Users/apple/Documents/Cours/McGill/Fall2017/COMP 273/A4/test-blur.pgm"	#used as output

buffer:  .space 2048		# buffer for upto 2048 bytes
newbuff: .space 2048
array: 	 .space 168		#Array with space for 24*7 bytes (we can safely use 
				#byte sized memory to store the integers since they range
				#from 0 to 255, because they represented pixel values)
blurarray: .space 168		#array to store the blurred image's pixel values (24x7 bytes space)

header: .asciiz "P2\n24 7\n15\n"

error1: .asciiz "Error opening the file\n"
error2: .asciiz "Error reading the file\n"
error3: .asciiz "Error writing to the file\n"
error4: .asciiz "Error closing the file\n"

	.text
	.globl main

main:	la $a0,str1		#readfile takes $a0 as input
	jal readfile

	la $a1,buffer		#$a1 will specify the "2D array" we will be averaging
	la $a2,newbuff		#$a2 will specify the blurred 2D array.
	jal blur

	la $a0, str3		#writefile will take $a0 as file location
	move $a1, $v1		#$a1 takes location of what we wish to write.
	jal writefile

	li $v0,10		# exit
	syscall

readfile: #Copy and pasted from q1
#Open the file to be read,using $a0
	li $v0, 13		#syscall code 13 for open file command
	add $a1, $0, $0  	#flag $a1=0 for read only
	li $a2, 0
	syscall 		#syscall. file descriptor returned in $v0
	move $s6, $v0		#save file descriptor 
#Conduct error check, to see if file exists
	bgez $v0, ok		#branch if no error opening the file
	la $a0, error1		#load error message address
	li $v0, 55		#syscall code 55
	li $a1, 0		#error dialog
	syscall
	j terminate
	


# read from file
# use correct file descriptor, and point to buffer
# hardcode maximum number of chars to read
# read from file
ok:	li $v0, 14		#syscall code for read
	move $a0, $s6		#$a0= file descriptor
	la $a1, buffer		#$a1=address of buffer
	li $a2, 2048		#$a2: max number of char to be read
	syscall 
	
	ble $0, $v0, ok2	#branch if no error reading the file
	la $a0, error2		#load error message address
	li $v0, 55		#syscall code 55
	li $a1, 0		#error dialog
	syscall
	j terminate

ok2:	la $v1,	buffer		# address of the ascii string you just read is returned in $v1.
				# the text of the string is in buffer
	
# close the file (make sure to check for errors)
	li $v0, 16		#syscall code for close file
	move $a0, $s6		#$a0= file descriptor
	syscall
	
	ble $0, $a0, ok5	#check if no error closing file
	la $a0, error4		#load error message address
	li $v0, 55		#syscall code 55
	li $a1, 0		#error dialog
	syscall
	j terminate
	
ok5:	jr $ra			#return to main


blur:	addi $sp, $sp, -16 	#create space for 4 words on stack 
	sw $ra, 0($sp)		#save $ra, $s0, $s1, $s2, $s3 on the stack
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)

	jal convert		#convert buffer (with ascii values) $a1 to an array of integers
	move $s0, $v0		#move address of array with integer values to $t0
	li $s1, 0		#use $t1 to keep track of the index in the array 
	la $s2, blurarray	#$s2 = pointer to blurred array
	li $t0, 24		#$t2= width of image = number of columns in 2D array
	li $t1, 23		#index of last column (23)
	li $t2, 6		#index of last row (6)
	
bloop:	div $s1, $t0		#euclidian division of index by 24		beginning of blur loop
	mfhi $t3		#remainder = column index
	mflo $t4		#quotient = row index

	seq $t5, $t4, $0	#1 if row 0
	seq $t6, $t3, $0	#1 if column 0
	seq $t7, $t4, $t2	#1 if row 6
	seq $t8, $t3, $t1	#1 if column 23

	#check all 8 edge cases
	and $t9, $t5, $t6	#1 if corner (0,0)
	bne $t9, $0, corner0	#edge case: corner0 = (0,0)
	
	and $t9, $t5, $t8	#1 if corner (0,23)
	bne $t9, $0, corner1	#edge case: corner1 = (0,23)
	
	and $t9, $t7, $t6	#1 if corner (6,0)
	bne $t9, $0, corner2	#edge case: corner1 = (6,0)
	
	and $t9, $t7, $t8	#1 if corner (6,23)
	bne $t9, $0, corner3	#edge case: corner1 = (6,23)
	
	bne $t5, $0, row0	#edge case: row 0
	bne $t6, $0, column0	#edge case: column 0
	bne $t7, $0, row6	#edge case: row 6
	bne $t8, $0, column23	#edge case: column 23
	
	#Not an edge case, thus average 3x3 square
	addi $t3, $s1, -25	#get index of top left pixel of square
	add $t3, $s0, $t3	#get pointer to top left pixel of square
	lb $t4, 0($t3)		#get value of pixel at top left square; $t4 will store the sum of all pixels values of the 3x3 square
	lb $t5, 1($t3)		#value of top middle pixel
	add $t4, $t4, $t5	
	lb $t5, 2($t3)		#value of top right pixel
	add $t4, $t4, $t5
	lb $t5, 24($t3)		#value of middle left pixel
	add $t4, $t4, $t5
	lb $t5, 25($t3)		#value of center pixel
	add $t4, $t4, $t5
	lb $t5, 26($t3)		#value of middle right pixel
	add $t4, $t4, $t5
	lb $t5, 48($t3)		#value of bottom left pixel
	add $t4, $t4, $t5
	lb $t5, 49($t3)		#value of bottom middle pixel
	add $t4, $t4, $t5
	lb $t5, 50($t3)		#value of bottom right pixel
	add $t4, $t4, $t5
	
	li $t5, 9
	mtc1 $t4, $f8		#move sum of pixel values to coprocessor 1
	cvt.s.w $f8, $f8	#Convert to float
	mtc1 $t5, $f9		#move number of square to coprocessor 1
	cvt.s.w $f9, $f9	#Convert to float
	div.s $f8, $f8, $f9	#averaging division 
	round.w.s $f8, $f8	#round result of division
	mfc1 $t4, $f8		#Move result to register $t4
	add $t5, $s2, $s1	#$t5 pointer to corresponding square of blurred array
	sb $t4, 0($t5)		#store average pixel value in the blur array
	
	addi $s1, $s1, 1	#increment pointer $s1
	j bloop			#return to blurloop
	
#edge cases:
#row cases
row0:	#pixel (0, k) -> average over (0, k-1), (0, k), (0, k+1), (1, k-1), (1, k), (1, k+1)
	add $t3, $s0, $s1	#pointer to pixel (0,k)
	addi $t3, $t3, -1	#pointer to pixel (0,k-1)
	
	lb $t4, 0($t3)		#get value of pixel at (0, k-1)
	lb $t5, 1($t3)		#value of (0,k)
	add $t4, $t4, $t5	
	lb $t5, 2($t3)		#value of (0,k+1)
	add $t4, $t4, $t5
	lb $t5, 24($t3)		#value of (1,k-1)
	add $t4, $t4, $t5
	lb $t5, 25($t3)		#value of (1,k)
	add $t4, $t4, $t5
	lb $t5, 26($t3)		#value of (1,k+1°
	add $t4, $t4, $t5
	
	li $t5, 6		#number of pixels read
	mtc1 $t4, $f8		#move sum of pixel values to coprocessor 1
	cvt.s.w $f8, $f8	#Convert to float
	mtc1 $t5, $f9		#move number of square to coprocessor 1
	cvt.s.w $f9, $f9	#Convert to float
	div.s $f8, $f8, $f9	#averaging division 
	round.w.s $f8, $f8	#round result of division
	mfc1 $t4, $f8		#Move result to register $t4
	add $t5, $s1, $s2	#pointer to corresponding square of blurred array
	sb $t4, 0($t5)		#store average pixel value in the blur array
	
	addi $s1, $s1, 1	#increment pointer $s1
	j bloop			#return to blurring loop
	
row6:	#pixel (6, k) -> average over (5, k-1), (5, k), (5, k+1), (6, k-1), (6, k), (6, k+1)
	add $t3, $s0, $s1	#pointer to pixel (6,k)
	addi $t3, $t3, -25	#pointer to pixel (5,k-1)
	
	lb $t4, 0($t3)		#get value of pixel at (5, k-1)
	lb $t5, 1($t3)		#value of (5,k)
	add $t4, $t4, $t5	
	lb $t5, 2($t3)		#value of (5,k+1)
	add $t4, $t4, $t5
	lb $t5, 24($t3)		#value of (6,k-1)
	add $t4, $t4, $t5
	lb $t5, 25($t3)		#value of (6,k)
	add $t4, $t4, $t5
	lb $t5, 26($t3)		#value of (6,k+1)
	add $t4, $t4, $t5
	
	li $t5, 6		#number of pixels read
	mtc1 $t4, $f8		#move sum of pixel values to coprocessor 1
	cvt.s.w $f8, $f8	#Convert to float
	mtc1 $t5, $f9		#move number of square to coprocessor 1
	cvt.s.w $f9, $f9	#Convert to float
	div.s $f8, $f8, $f9	#averaging division 
	round.w.s $f8, $f8	#round result of division
	mfc1 $t4, $f8		#Move result to register $t4
	add $t5, $s1, $s2	#pointer to corresponding square of blurred array
	sb $t4, 0($t5)		#store average pixel value in the blur array
	
	addi $s1, $s1, 1	#increment pointer $s1
	j bloop			#return to blurring loop
		
#column cases: 
column0: #pixel (k, 0) -> average over (k-1, 0), (k, 0), (k+1, 0), (k-1, 1), (k, 1), (k+1, 1)
	add $t3, $s0, $s1	#pointer to pixel (k, 0)
	addi $t3, $t3, -24	#pointer to pixel (k-1, 0)
	
	lb $t4, 0($t3)		#get value of pixel at (k-1, 0)
	lb $t5, 1($t3)		#value of (k-1, 1)
	add $t4, $t4, $t5	
	lb $t5, 24($t3)		#value of (k, 0)
	add $t4, $t4, $t5
	lb $t5, 25($t3)		#value of (k, 1)
	add $t4, $t4, $t5
	lb $t5, 48($t3)		#value of (k+1, 0)
	add $t4, $t4, $t5
	lb $t5, 49($t3)		#value of (k+1, 1)
	add $t4, $t4, $t5
	
	li $t5, 6		#number of pixels read
	mtc1 $t4, $f8		#move sum of pixel values to coprocessor 1
	cvt.s.w $f8, $f8	#Convert to float
	mtc1 $t5, $f9		#move number of square to coprocessor 1
	cvt.s.w $f9, $f9	#Convert to float
	div.s $f8, $f8, $f9	#averaging division 
	round.w.s $f8, $f8	#round result of division
	mfc1 $t4, $f8		#Move result to register $t4
	add $t5, $s1, $s2	#pointer to corresponding square of blurred array
	sb $t4, 0($t5)		#store average pixel value in the blur array
	
	addi $s1, $s1, 1	#increment pointer $s1
	j bloop			#return to blurring loop
				
column23: #pixel (k, 23) -> average over (k-1, 22), (k, 22), (k+1, 22), (k-1, 23), (k, 23), (k+1, 23)
	add $t3, $s0, $s1	#pointer to pixel (k, 23)
	addi $t3, $t3, -25	#pointer to pixel (k-1, 22)
	
	lb $t4, 0($t3)		#get value of pixel at (k-1, 22)
	lb $t5, 1($t3)		#value of (k-1, 23)
	add $t4, $t4, $t5	
	lb $t5, 24($t3)		#value of (k, 22)
	add $t4, $t4, $t5
	lb $t5, 25($t3)		#value of (k, 23)
	add $t4, $t4, $t5
	lb $t5, 48($t3)		#value of (k+1, 22)
	add $t4, $t4, $t5
	lb $t5, 49($t3)		#value of (k+1, 23)
	add $t4, $t4, $t5
	
	li $t5, 6		#number of pixels read
	mtc1 $t4, $f8		#move sum of pixel values to coprocessor 1
	cvt.s.w $f8, $f8	#Convert to float
	mtc1 $t5, $f9		#move number of square to coprocessor 1
	cvt.s.w $f9, $f9	#Convert to float
	div.s $f8, $f8, $f9	#averaging division 
	round.w.s $f8, $f8	#round result of division
	mfc1 $t4, $f8		#Move result to register $t4
	add $t5, $s1, $s2	#pointer to corresponding square of blurred array
	sb $t4, 0($t5)		#store average pixel value in the blur array
	
	addi $s1, $s1, 1	#increment pointer $s1
	j bloop			#return to blurring loop				
#corner cases
corner0: #corner (0,0) case	Average over pixels (0,0), (0,1), (1,0), (1,1)
	add $t3, $s0, $s1	#pointer to cell
	lb $t4, 0($t3)		#value at pixel
	lb $t5, 1($t3)		#value of pixel (0,1)
	add $t4, $t4, $t5
	lb $t5, 24($t3)		#value of pixel (1,0)
	add $t4, $t4, $t5
	lb $t5, 25($t3)		#value of pixel (1,1)
	add $t4, $t4, $t5
	
	li $t5, 4		#number of pixels read
	mtc1 $t4, $f8		#move sum of pixel values to coprocessor 1
	cvt.s.w $f8, $f8	#Convert to float
	mtc1 $t5, $f9		#move number of square to coprocessor 1
	cvt.s.w $f9, $f9	#Convert to float
	div.s $f8, $f8, $f9	#averaging division 
	round.w.s $f8, $f8	#round result of division
	mfc1 $t4, $f8		#Move result to register $t4
	add $t5, $s1, $s2	#pointer to corresponding square of blurred array
	sb $t4, 0($t5)		#store average pixel value in the blur array
	
	addi $s1, $s1, 1	#increment pointer $s1
	j bloop			#return to blurring loop
	
corner1: #corner (0,23) case	Average over pixels (0,23), (0,22), (1,22), (1,23)
	add $t3, $s0, $s1	#pointer to pixel (0,23)
	addi $t3, $t3, -1	#pointer to pixel (0,22)
	lb $t4, 0($t3)		#value at pixel (0,22)
	lb $t5, 1($t3)		#value of pixel (0,23)
	add $t4, $t4, $t5
	lb $t5, 24($t3)		#value of pixel (1,22)
	add $t4, $t4, $t5
	lb $t5, 25($t3)		#value of pixel (1,23)
	add $t4, $t4, $t5
	
	li $t5, 4		#number of pixels read
	mtc1 $t4, $f8		#move sum of pixel values to coprocessor 1
	cvt.s.w $f8, $f8	#Convert to float
	mtc1 $t5, $f9		#move number of square to coprocessor 1
	cvt.s.w $f9, $f9	#Convert to float
	div.s $f8, $f8, $f9	#averaging division 
	round.w.s $f8, $f8	#round result of division
	mfc1 $t4, $f8		#Move result to register $t4
	add $t5, $s1, $s2	#pointer to corresponding square of blurred array
	sb $t4, 0($t5)		#store average pixel value in the blur array
	
	addi $s1, $s1, 1	#increment pointer $s1
	j bloop			#return to blurring loop

corner2: #corner (6,0) case	Average over pixels (5,0), (5,1), (6,0), (6,1)
	add $t3, $s0, $s1	#pointer to pixel (6,0)
	addi $t3, $t3, -24	#pointer to pixel (5,0)
	lb $t4, 0($t3)		#value at pixel (5,0)
	lb $t5, 1($t3)		#value of pixel (5,1)
	add $t4, $t4, $t5
	lb $t5, 24($t3)		#value of pixel (6,0)
	add $t4, $t4, $t5
	lb $t5, 25($t3)		#value of pixel (6,1)
	add $t4, $t4, $t5
	
	li $t5, 4		#number of pixels read
	mtc1 $t4, $f8		#move sum of pixel values to coprocessor 1
	cvt.s.w $f8, $f8	#Convert to float
	mtc1 $t5, $f9		#move number of square to coprocessor 1
	cvt.s.w $f9, $f9	#Convert to float
	div.s $f8, $f8, $f9	#averaging division 
	round.w.s $f8, $f8	#round result of division
	mfc1 $t4, $f8		#Move result to register $t4
	add $t5, $s1, $s2	#pointer to corresponding square of blurred array
	sb $t4, 0($t5)		#store average pixel value in the blur array
	
	addi $s1, $s1, 1	#increment pointer $s1
	j bloop			#return to blurring loop		
	
corner3: #corner (6,23) case	Average over pixels (5,22), (5,23), (6,22), (6,23)
	add $t3, $s0, $s1	#pointer to pixel (6,23)
	addi $t3, $t3, -25	#pointer to pixel (5,22)
	lb $t4, 0($t3)		#value at pixel (5,22)
	lb $t5, 1($t3)		#value of pixel (5,23)
	add $t4, $t4, $t5
	lb $t5, 24($t3)		#value of pixel (6,22)
	add $t4, $t4, $t5
	lb $t5, 25($t3)		#value of pixel (6,23)
	add $t4, $t4, $t5
	
	li $t5, 4		#number of pixels read
	mtc1 $t4, $f8		#move sum of pixel values to coprocessor 1
	cvt.s.w $f8, $f8	#Convert to float
	mtc1 $t5, $f9		#move number of square to coprocessor 1
	cvt.s.w $f9, $f9	#Convert to float
	div.s $f8, $f8, $f9	#averaging division 
	round.w.s $f8, $f8	#round result of division
	mfc1 $t4, $f8		#Move result to register $t4
	add $t5, $s1, $s2	#pointer to corresponding square of blurred array
	sb $t4, 0($t5)		#store average pixel value in the blur array
	
	#don't return to blurring loop	since array is exhausted		
	#convert blurarray to string to be stored in $a2
	la $a3, blurarray
	jal convertback		#address of blurred buffer is already in $v1 after this
	
	lw $ra, 0($sp)		#restore $ra, $s0, $s1, $s2 from the stack
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s2, 12($sp)
	addi $sp, $sp, 16	#restore stack
	jr $ra			#return to main
	
	
#use real values for averaging.
#HINT set of 8 "edge" cases.
#The rest of the averaged pixels will 
#default to the 3x3 averaging method
#we will return the address of our
#blurred 2D array in #v1
	
 #procedure that converts the string in the buffer in $a1 to an array of integers returned in $v0
convert:la $t0, array
	li $t1, 48	#ascii code for '0'
	li $t2, 57	#ascii code for '9'
	li $t7, 10	#base to which integers are converted
loop:	lb $t3, 0($a1)		#load byte at 0($a1)
	addi $a1, $a1, 1	#increment pointer to next byte
	slt $t4, $t3, $t1	#1 if $t3 < '0'
	slt $t5, $t2, $t3	#1 if '9' < $t3
	or $t4, $t4, $t5	#1 if $t3 not a numerical character
	beq $t3, $0, null	#Check if null character read
	bne $t4, $0, loop	#If not a numerical character, skip
	
	addi $t6, $t3, -48	#convert to integer
	#check if character after is a numerical
loop2:	lb $t3, 0($a1)	#load byte at 0($a1)
	addi $a1, $a1, 1	#increment pointer
	slt $t4, $t3, $t1	#1 if $t3 < '0'
	slt $t5, $t2, $t3	#1 if '9' < $t3
	or $t4, $t4, $t5	#1 if $t3 not a numerical character
	
	beq $t3, $0, nullstore	#Check if null character read
	bne $0, $t4, store 	#number is finished, so store it in array
	#number is not finished, so convert to base 10 : $t6=$t6*10+($t3-48)
	mult $t6, $t7		#multiply $t6 by 10
	mflo $t6		#result of $t6*10 stored in $t6
	addi $t3, $t3, -48	#convert $t3 to integer
	add $t6, $t6, $t3	#add to $t6
	j loop2			#return to loop3 to check if the number had terminated 
	
store: 	sb $t6, 0($t0)		#store number in array at pointer position
	addi $t0, $t0, 1	#increment pointer to next byte
	j loop			#return to loop to read next character	

nullstore: sb $t6, 0($t0)	#store number in array at pointer position, then return
null: 	la $v0, array		#load address of array in return register $v0
	jr $ra			#return to caller
	

		#procedure that converts an array of integers passed in $a3 to a string, stores it in the space pointed at by $a2,
		#returns a pointer to the buffer in $v1
convertback: move $t0, $a2
	addi $t5, $a3, 168 	#pointer to the byte after the last byte of the array
	li $t2, 10
	li $t4, 32		#ascii code for space
cloop:	ble $t5, $a3, end
	lb $t1, 0($a3)		#read byte at current index of blurred array
	addi $a3, $a3, 1	#increment pointer in array by 1
	div $t1, $t2		#euclidian division of $t1 by 10
	mflo $t3		#quotient of division by 10
	bne $t3, $0, long	#number has more than 1 digit
	addi $t1, $t1, 48	#convert to ascii code
	sb $t1, 0($t0)		#store byte in buffer
	sb $t4, 1($t0)		#add space
	addi $t0, $t0, 2	#increment buffer pointer by 2
	j cloop

long:	mfhi $t1		#get remainder of previous division by 10
	addi $t3, $t3, 48	#convert quotient to ascii
	sb $t3, 0($t0)		#store byte in buffer
	addi $t0, $t0, 1	#increment pointer in buffer
	div $t1, $t2
	mflo $t3		#quotient of division of previous remainder by 10
	bne $t3, $0, long	#remainder still has more than 1 digit, so go to long
	addi $t1, $t1, 48	#convert to ascii code
	sb $t1, 0($t0)		#store word in buffer
	sb $t4, 1($t0)		#add space
	addi $t0, $t0, 2	#increment buffer pointer by 2
	j cloop
	
end: 	sb $0, 0($t0)		#array has been exhausted, so add a nul character to the buffer
	move $v1, $a2		#move pointer to beginning of buffer in $v1
	jr $ra 			#return to caller
	
writefile: 
	addi $sp, $sp, -12
	sw $a1, 0($sp)		#save address stored in $a1
	sw $s6, 4($sp)
	sw $ra, 8($sp)
#open file to be written to, using $a0.
	li $v0, 13		#syscall code 13 for open file command
	li $a1, 1  		#flag $a1=1 for write only with create
	li $a2, 0
	syscall 		#syscall. file descriptor returned in $v0
	move $s6, $v0		#save file descriptor 
#Conduct error check
	bgez $v0, ok3		#branch if no error opening the file
	la $a0, error1		#load error message address
	li $v0, 55		#syscall code 55
	li $a1, 0		#error dialog
	syscall
	j terminate
		
#write the specified characters as seen on assignment PDF:
ok3:	la $a1, header
	jal length		#mesure length of the string we want to print
	move $a2, $v0		#number of char to be written
	li $v0, 15		#syscall code 15 for write to file
	move $a0, $s6		#$a0=file descriptor
	la $a1, header		#address of output buffer
	syscall
	
	blt $v0, $0, werror	#check if error when writing

#write the content stored at the address in $s5.

	move $a0, $s6		#$a0=file descriptor
	lw $a1, 0($sp)		#address of output buffer
	jal length
	lw $a1, 0($sp)		#address of output buffer
	move $a2, $v0		#number of char to be written
	li $v0, 15		#syscall code 15 for write to file
	syscall
	
	bge $v0, $0, ok4	#check if no error when writing
werror: la $a0, error3		#load error message address
	li $v0, 55		#syscall code 55
	li $a1, 0		#error dialog
	syscall
	j terminate
				
#close the file (make sure to check for errors)
ok4: 	li $v0, 16		#syscall code for close file
	move $a0, $s6		#$a0= file descriptor
	syscall
	
	ble $0, $a0, ok6	#check if no error closing file
	la $a0, error4		#load error message address
	li $v0, 55		#syscall code 55
	li $a1, 0		#error dialog
	syscall
	j terminate
	
ok6:	lw $s6, 4($sp)
	lw $ra, 8($sp)
	jr $ra			#return to main

terminate: #in case of error in File I/O, terminates execution with error code 1
	addi $a0, $0, 1		#error code
	addi $v0, $0, 17	#syscall code for terminate with code
	syscall	


##############################################################
length: li $v0, 0
loopl:	lb $t0, 0($a1)
	beq $0, $t0, return
	addi $v0, $v0, 1
	addi $a1, $a1, 1
	j loopl
return: jr $ra