////////////////////////////////////////////////////////////////////////////////
//BEGIN echoString.s

/*
	Get In String, Echo Out To User
	===============================
	Code by Jason Lillard, 2017
	( Compile with gcc or g++ )

*/

// Get in a string, store in a char array, echo string to screen

// Here are our compiler constants. These aren't stored like
// normal data, because each constant (like OC_READ or ARRSZ)
// is replaced at compile time by the number we specify
// (e.g. OC_READ becomes 3, ARRSZ becomes 100). This is like
// doing a "find and replace" in Microsoft Word, where the
// thing we're finding (OC_READ, OC_WRITE, etc.) gets replaced
// by the number that comes after it (3, 4, etc.)
// You will see how we use these constants differently than
// the usual data we store and manipulate in our data sections.

.equ OC_READ, 3		// software interrupt opcode for read
.equ OC_WRITE, 4	// software interrupt opcode for write
.equ OC_EXIT, 1		// swi opcode for exit
.equ ARRSZ, 140		// length of input buffer

////////////////////////////////////////////////////////////////////////////////
/*
	Here is our "data" section. Our data section is empty for this tutorial,
	but most of the time you are going to want to fill this section with
	any variables you might end up changing. The .data section is all you
	*really* need for variables -- you can program without .equ directives,
	without a read-only data section (specified with ".section .rodata")
	and without a .bss section for uninitialized data.
*/
.section .data
.align 4  //this specifies that our section begins on an address divisible by 4.

	//No data here right now.

////////////////////////////////////////////////////////////////////////////////

/*
	Here is our (optional) .bss section for variables with no starting
	value, or "uninitialized" variables. You can include even
	uninitialized variables in the .data section. To prove this to
	yourself, try commenting out the line with .section .bss and you
	should be able to compile the program just the same as before.
*/

.section .bss
.align 4
inBuff:
	.skip ARRSZ	// allocate 140 char buffer

////////////////////////////////////////////////////////////////////////////////

/*
	This is our "read-only" data section. These are also optional, but if
	you are using constants like strings or sizes of those strings, then
	including those in the .rodata section is wise because you will not
	be able to change any of the values of these constants while your
	program is running. Attempting to change data in the .rodata section
	will result in a "segmentation fault." Trying to change read-only
	data is probably the leading cause of segmentation faults.
*/

.section .rodata
.align 4

//.asciz is null-terminated ascii c-string. Always use .asciz instead of .ascii

prompt1:	//the name of our variable, done with a label ending in ":"
	.asciz "Enter a string (up to 140 chars): "

//.word is a 4-byte number, equivalent to the "unsigned int" data type in C/C++
prompt1SZ:
	.word 34	//size of first string (excluding the null terminator)


output1:
	.asciz "Your string was:\n"	//string to precede echo of input

output1SZ:
	.word 17	//size of second string (excluding the null terminator)

////////////////////////////////////////////////////////////////////////////////

//BEGIN MAIN

/*
	Here we are in main. If we are compiling these source files with
	as and ld, then instead of ".global main" and "main:" we will
	need our program's entry point to be made with ".global _start"
	and "_start". ld will allow you to use main instead of _start
	as an entry point, but it will give a warning when it does.
	Trying to use both labels _start and main usually causes errors.

	Make sure that any sections of code, whether they are part of
	your main function or not, start with the ".text" compiler
	directive. (BTW Nearly everything that starts with a "." is
	something interpreted by the pre-compiler, and can be referred
	to as a compiler (or pre-compiler) directive).
*/


.section .text
.align 4

//.global _start	//use _start label for compiling with as and ld
//_start:

.global main		//use main label for compiling with gcc or g++
main:

/*
	Here we will do something a little annoying because
	it is actually slightly simpler at this point:
	we're going to set up our read and write system calls
	every single time we want to use them. Eventually,
	this will get annoying, and you won't want to do it,
	so you'll move each of these things into their own
	functions, or you'll just use the C library instead
	with printf, and scanf ( and maybe put and puts).

	For now, let's do these one at a time and for the
	next tutorial we'll put them into their own functions
	so it isn't so annoying to try to do simple I/O.
*/

	// STEP 1: Output prompt to user
	/*
		Important notes about this set-up:
	1. MOV is for moving direct values into registers,
	or for moving a value from one register to another.
	LDR is for loading a value from memory into a register.

	2. When we do "system interrupts" to call on the operating
	system to do something for us, the number of the "syscall"
	that we want is ALWAYS put in R7.

	3. R0 will always be set to 0 for our WRITE syscall

	4. Since we use .equ to specify OC_WRITE, it will be replaced
	with 4 by the precompiler. However, since our prompt1SZ number
	is actually stored in a data section, we cannot just use it
	as an immediate value like we did with OC_WRITE.

	5. To load the data stored at a specific label, we must use
	two lines of code. The first gets a pointer to the value,
	and the second line of code dereferences the value there.
		Example:
		LDR R2, =prompt1SZ 	//first get pointer to address
		LDR R2, [R2]		//then get value at that address

	And notice that for loading and dereferencing a value from memory,
	we need to use LDR for "load register"

	6. R1 needs a pointer to the c-string we want to print.
	DO NOT DEREFERENCE POINTERS TO STRINGS, as this will just load
	in one ascii character value instead of pointing to the full string.

	7. SWI 0 basically slaps the operating system and goes "HEY. DO STUFF!"
	*/
	MOV R7, #OC_WRITE	// R7 = syscall for write (4)
	MOV R0, #0		// R0 = write dest (0 is monitor)
	LDR R2, =prompt1SZ	// R2 = prompt length
	LDR R2, [R2]		// R2 = *length
	LDR R1, =prompt1	// R1 = pointer to string
	SWI 0			// Trigger Software Interrupt (OS function)


/*
	Even though the READ syscall is opcode 3 instead of 4, the set-up
	for this software interrupt is very similar to the one for WRITE.
	R7 gets the opcode
	R0 always gets 0, which shows we're reading from the keyboard
	R1 will always be a pointer to where you are storing the data
	R2 will always be how many numbers you want to read in
	SWI 0 again slaps the OS and tells it to do our bidding.
*/

	// Read in string from user, store in buffer
	MOV R7, #OC_READ	// R7 = syscall for read (3)
	MOV R0, #0		// R0 = read dest (0 is keyboard)
	LDR R1, =inBuff		// R1 = pointer to string (buffer)
	MOV R2, #ARRSZ		// R2 = max size to read (140)
	SWI 0			// Trigger Software Interrupt (OS function)

	// Notice again there was no need to dereference our .equ constants
	// like OC_READ and ARRSZ, but we did need "#" signs before them.


	// Print output1 string before buffer (set-up nearly same as before)
	MOV R7, #OC_WRITE	// R7 = syscall for write (4)
	MOV R0, #0		// R0 = write dest (0 is monitor)
	LDR R1, =output1	// R1 = pointer to string to print
	//Get pointer to output1SZ, then dereference it (both with LDR)
	LDR R2, =output1SZ	// R2 = # of chars to print
	LDR R2, [R2]		// R2 = *output1SZ
	SWI 0			// Trigger Software Interrupt (OS function)

	// Echo out string to user (set-up nearly same as before)
	MOV R7, #OC_WRITE	// R7 = syscall for write (4)
	MOV R0, #0		// R0 = wrtite dest (0 is monitor)
	LDR R1, =inBuff		// R1 = pointer to string (buffer)
	MOV R2, #ARRSZ		// R2 = # of chars to print (buffer size, 140)
	SWI 0			// Trigger Software Interrupt (OS function)


exit:
	//There is also a software interrupt for exiting. This is probably
	//optional when you put it at the end of the program, but it is still
	//good to be able to see where exactly your exit points are
	//(Plus you might eventually want to exit from somewhere else, so
	// it doesn't hurt to learn how to do this)
	MOV R7, #OC_EXIT	//R7 = syscall for exit program (1)
	SWI 0			// Trigger Software Interrupt (OS function)

// END MAIN
////////////////////////////////////////////////////////////////////////////////

/*
				FINAL NOTES:

	USE COMMENTS EVERYWHERE WHEN YOU DO ASSEMBLY LANGUAGE PROGRAMMING.

	THIS WILL SAVE YOU YOUR SANITY. KEEPING TRACK OF WHAT IS IN WHICH
	REGISTER IS NEARLY IMPOSSIBLE ONCE YOU START DOING ANYTHING EVEN A
	LITTLE BIT COMPLICATED.

	COME UP WITH VARIABLE NAMES TO PUT IN COMMENTS EVEN IF A VALUE
	NEVER ACTUALLY LEAVES A REGISTER TO BE STORED IN A DATA	SECTION
	(AND THEREFORE NEVER ACTUALLY GETS PUT AT A NAMED LABEL).
	EXAMPLE (INCLUDING COMMENTS):
	MOV R0, #0	//R0 = COUNTER
	MOV R1, #0	//R1 = ACCUMULATOR
	LDR R2, =arr	//R2 = BASE ADDRESS
	LDR R3, =ARRSZ	//R3 = ARRAY SIZE
	LDR R3, [R3]	//DEREFERENCE ARRSZ INTO R3

*/


// END echoString.s
////////////////////////////////////////////////////////////////////////////////
