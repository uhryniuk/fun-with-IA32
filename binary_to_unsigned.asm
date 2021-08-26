; Dylan Uhryniuk
; 3126716
; Computer Architecture - Assignment 3
;-------------------------------------------------------------------------------------------------------------------------------------------------------
data	segment							; data segment. Keyword db means define byte. You can also define word (dw)
		prompt db "Enter a 16-bit binary number: ", "$"
		dialog db 10, "The decimal unsigned integer equivalent is ", "$"
		input db 17, 16 dup(?)
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
		
		mov ah, 0ah					; Load Hex into register for DOS Fucntion
		lea dx, input				; Load Data segement to receive input for String.
		int 21h						; Execute DOS Funciton
		
		mov ah, 9h					; Load Hex into register for DOS Function
		lea dx, dialog				; Load String to print DOS Function
		int 21h						; Execute DOS Function

		
		lea si, input 				; Move input Bianry String into SI register
		inc si						; Increment to get [si] to hold the length of String.
		mov ch, 0					; Clearing Register for compare testing.
		mov cl, [si]				; Move the number of characters in input string into CL
		add si, cx					; Add CX to SI to set the position of the last char in the string.	
	
	
		call add_total				; Add and convert the total of the binary string.
		call print_decimal			; Call proc to print the binary value.
	

;-------------------------------------------------------------------------------------------------------------------------------------------------------										
		mov ah, 4ch 					;Set up code to specify return to dos
        int 21h							;Interpt number 21 (Return control to dos prompt)
;--------------------------------------------------------------------------------------------------------------------------------------------------------
; Pop and add total from the stack
; Output (ax) Binary into decimal total.
add_total proc
		mov ax, "$"					; Push to stack for popping all values off later.
		push ax						
		mov ax, 1					; Set to 1 as will be multiplied by 2 for each bit.
		mov bx, 0 					; Set to 0, this will hold the total when pop values off stack.
		mov cx, TWO					; Set as multiplier contstant for each successive bit.
		
	get_position:
		mov dl, [si]				; Get the value at each position throughout the string.
		
		cmp si, 4dh					; Test if all of the characters have been passed.	
		je make_total				; Jump to add up total
		
		cmp dl, 31h					; Test if the current character is a "1"
		je push_total				; Jump to push the number onto the stack	
		
		mul cx						; Doubles the value of ax after every loop for each bit passed.
		dec si						; Move the pointer to the next character in the string.
	jmp get_position

	push_total:
		push ax						; Push current value onto stack to add later
		mul cx						; Double value in ax register
		dec si						; Move to the next character in the string
		jmp get_position


	make_total:						; Adds the total of all the bits
		pop ax						; Pop values off the stack to add
		cmp ax, "$"					; Test if it is the end of the stack
		je done_total				; If it is, jump to done totalling
		add bx, ax					; Otherwise add value of ax to bx which holds the running total.
		jmp make_total
		
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
code    ends

end     start
;-------------------------------------------------------------------------------------------------------------------------------------------------------



