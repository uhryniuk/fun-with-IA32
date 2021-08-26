; Dylan Uhryniuk
; 3126716
; Computer Architecture - Assignment 3
;-------------------------------------------------------------------------------------------------------------------------------------------------------
data	segment							; data segment. Keyword db means define byte. You can also define word (dw)
		prompt db "Enter a 16-bit binary number: ", "$"
		dialog db 10, "The decimal signed integer equivalent is ","$"
		input db 17, 16 dup(?)
		error_length db 10, "Error! Please enter exactly 16-bits: ", "$"
		error_character db "Error! Illegal characters detected. Please enter a 16-bit binary number ", 10, "$"
		TWO equ 2
		TEN equ 10
data	ends

										; stack segment
stack1  segment	stack 		
		db	100 dup(?)      			; This is the stack of 100 bytes
stack1  ends


code    segment
        assume  cs:code, ds:data, ss:stack1

start: 
										;Perform initialization 
		mov ax, data					;Put the starting address of the data segment into the ax register (must do this first)
		mov ds, ax						;Put the starting address of the data segment into the ds register (where it belongs)
		
		mov ax, stack1					;Put the starting address of the stack into the ax register (must do this first)
		mov ss, ax						;Put the starting address of the stack segment into the ss register (where it belongs)
;-------------------------------------------------------------------------------------------------------------------------------------------------------		
;****************** Perform Newton's Algorithm ******************
	start_dialog:									
		mov ah, 9h;					; Load Hex into register for DOS Function
		lea dx, prompt				; Load String to print with DOS Function
		int 21h						; Execute DOS Function
		
		
	calculate_input:
		mov ah, 0ah					; Load Hex into register for DOS Fucntion
		lea dx, input				; Load Data segement to receive input for String.
		int 21h						; Execute DOS Funciton
		
		lea si, input 				; Move input Bianry String into SI register
		inc si						; Increment to get [si] to hold the length of String.
		
		mov ch, 0					; Clearing Register for compare testing.
		
		mov al, [si+1]				; Testing the sign bit of the Binary String.
		mov cl, [si]				; Move the number of characters in input string into CL
		cmp cx, 16					; Length must be 16 bits long.
		jl length_error 			; Otherwise jump to error handling 
		
		add si, cx					; Add CX to SI to set the position of the last char in the string.
		
		call add_total				; Add and convert the total of the binary string.
		
		cmp si, 4ch					; Tests if an error was thrown causing the addition to end early.
		jg calculate_input			; If addition ended early, return to input label.
		
		jmp print					; If valid input and addition, jump to print label
		
		
	length_error:			
		call throw_length_error		; Call Proc tht prints length error message
		jmp calculate_input			; Return to request for input again.
		
		
	print:		
		call print_decimal			; Call proc to print the binary value.
	

;-------------------------------------------------------------------------------------------------------------------------------------------------------										
		mov ah, 4ch 					;Set up code to specify return to dos
        int 21h							;Interpt number 21 (Return control to dos prompt)
;--------------------------------------------------------------------------------------------------------------------------------------------------------
; Pop and add total from the stack
; Input  (al) Contains the sign bit of the binary string.
; Output (ax) Binary into decimal total.
add_total proc
		
		cmp al, 30h					; Test if the sign bit is 0
		je add_positive				; Jump to applicable addition label
		cmp al, 31h					; Test if the sitgn bit is 1
		je add_negative				; Jump to applicable addition label
		
		
	add_positive:					; Addition for all the positive signed bits
		mov ax, "$"					; Push to stack for popping all values off later.
		push ax						
		mov ax, 1					; Set to 1 as will be multiplied by 2 for each bit.
		mov bx, 0 					; Set to 0, this will hold the total when pop values off stack.
		mov cx, TWO					; Set as multiplier contstant for each successive bit.
		positive_loop:
			mov dl, [si]			; Get the value at each position throughout the string.
			
			cmp dl, 30h				; Check if it is a valid character
			jl illegal_char			; Jump to error handler if not valid.
			cmp dl, 31h 			; Check if it is a valid character
			jg illegal_char			; Jump to error handler if not valid.
			
			cmp si, 4ch				; Test if all the characters have been passed through
			je positive_dialog 		; Jump to positive dialog label
			
			cmp dl, 31h				; Tests if position contains a 1
			je push_positive		; Jump to push_positive put it on to the stack
			mul cx					; Doubles the value of ax after every loop for each bit passed.
			dec si					; Move the pointer to the next character in the string.
	jmp positive_loop	

	push_positive:		
		push ax						; Push current value onto stack to add later
		mul cx						; Double value in ax register
		dec si						; Move to the next character in the string
		jmp positive_loop
	
	
	add_negative:					; Addition for all of the negative signed bits
		mov ax, "$"					; Push to stack for popping all values off later.
		push ax
		mov ax, 1					; Set to 1 as will be multiplied by 2 for each bit.
		push ax						; Negative signed is offset by one.
		mov bx, 0 					; Set to 0, this will hold the total when pop values off stack.
		mov cx, TWO					; Set as multiplier contstant for each successive bit.
		negative_loop:
			mov dl, [si]			; Get the value at each position throughout the string.
			
			cmp dl, 30h				; Check if it is a valid character
			jl illegal_char			; Jump to error handler if not valid.
			cmp dl, 31h 			; Check if it is a valid character
			jg illegal_char			; Jump to error handler if not valid.
			
			cmp si, 4ch				; Test if all the characters have been passed through
			je negative_dialog 		; Jump to positive dialog label
			
			cmp dl, 30h				; Tests if position contains a 1
			je push_negative		; Jump to push_positive put it on to the stack
			mul cx					; Doubles the value of ax after every loop for each bit passed.
			dec si					; Move the pointer to the next character in the string.
	jmp negative_loop
	

	push_negative:		
		push ax						; Push current value onto stack to add later
		mul cx						; Double value in ax register
		dec si						; Move to the next character in the string
		jmp negative_loop
	
	

	make_total:						; Adds the total of all the bits
		pop ax						; Pop values off the stack to add
		cmp ax, "$"					; Test if it is the end of the stack
		je done_total				; If it is, jump to done totalling
		add bx, ax					; Otherwise add value of ax to bx which holds the running total.
		jmp make_total
		
	illegal_char:					; Thrown if an illegal character is found
		call throw_illegal_char_error
		jmp make_total					; Dump the stack to get return reference
		
	positive_dialog:				; Prints the rest of the dialog
		mov ah, 9h
		lea dx, dialog
		int 21h
		jmp make_total				; Jump to complete the total
		
	negative_dialog:				; Prints the rest of the dialog along with the "-" for negative sign
		mov ah, 9h
		lea dx, dialog
		int 21h
		
		mov ah, 2h					; Print the negative sign.
		mov dl, 2dh
		int 21h
		
		jmp make_total				; Jump to complete the totalling.
		
	done_total:						
		mov ax, bx 					; Move total as print_decimal call needs total in ax.
		ret					
add_total endp
;--------------------------------------------------------------------------------------------------------------------------------------------------------
; Print the decimal total to the terminal
; Input  (ax)   Decimal total of the binary PROC            
;--------------------------------------------------------------------------------------------------------------------------------------------------------
print_decimal proc      
    mov cx,0 						; Initilaize the counter
    mov bx, TEN         			; Set bx to 10 as it will be the divisor for remainder
    get_remainders: 
		mov dx, 0					; Set DX to not corrupt remainder
        
		cmp ax, 0					; Test if there is anything left in total to divide by. 
		je print_characters       	; Jump to print label
          
        div bx        				; Complete division to get remainder			           
        push dx       				; Get and put remainder on the stack  
        inc cx               		; Increase the counter
    jmp get_remainders

		
    print_characters: 
        cmp cx,0 					; Check if there are any other numbers to pop off stack
        je finish_print				; Jump to finish
          
        pop dx 						; Get the next value off of the stack.
        add dx, 30h 				; Add 30h to make the value it's ASCII version
          
        mov ah,02h 					; Load the print char value into ah
        int 21h 					; Execute DOS Function
        dec cx 						; Decrement the counter for number of pops.
	jmp print_characters 
		
	finish_print: 
		ret 
print_decimal endp 
;--------------------------------------------------------------------------------------------------------------------------------------------------------
;--------------------------------------------------------------------------------------------------------------------------------------------------------
; Prints error dialog if the length of the string is too short.
throw_length_error proc
		mov ah, 9h 					; Load print string value into register for DOS Function
		lea dx, error_length		; Load length error dialog to print
		int 21h						; Execute DOS Function
		 
	exit_length_exception:
		ret
throw_length_error endp
;--------------------------------------------------------------------------------------------------------------------------------------------------------
; Prints illegal input dialog and reprompts the user for a new binary string
throw_illegal_char_error proc
		mov ah, 9h;					; Load print string value into register for DOS Function
		lea dx, error_character		; Load character error dialog to print
		int 21h						; Execute the DOS Function
		
	exit_char_exception:
		ret
throw_illegal_char_error endp
;--------------------------------------------------------------------------------------------------------------------------------------------------------

code    ends

end     start
;-------------------------------------------------------------------------------------------------------------------------------------------------------



