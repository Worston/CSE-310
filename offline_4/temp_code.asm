main PROC
	MOV AX, @DATA
	MOV DS, AX
	PUSH BP
	MOV BP, SP
	SUB SP, 2
	SUB SP, 2
	SUB SP, 2
	SUB SP, 2
	SUB SP, 2
	SUB SP, 2
L1:
	MOV AX, 1       ; Line 6
	MOV i, AX       ; Line 6
	PUSH AX
	POP AX
L2:
	MOV AX, i       ; Line 7
	CALL print_output
	CALL new_line
L3:
	MOV AX, 5       ; Line 9
	PUSH AX
	MOV AX, 8       ; Line 9
	MOV DX, AX
	POP AX
	ADD AX, DX       ; Line 9
	MOV j, AX       ; Line 9
	PUSH AX
	POP AX
L4:
	MOV AX, j       ; Line 10
	CALL print_output
	CALL new_line
L5:
	MOV AX, i
	PUSH AX
	MOV AX, 2       ; Line 12
	PUSH AX
	MOV AX, j
	MOV CX, AX
	POP AX
	CWD
	MUL CX       ; Line 12
	MOV DX, AX
	POP AX
	ADD AX, DX       ; Line 12
	MOV [BP-2], AX
	PUSH AX
	POP AX
L6:
	MOV AX, [BP-2]       ; Line 13
	CALL print_output
	CALL new_line
L7:
	MOV AX, [BP-2]
	PUSH AX
	MOV AX, 9       ; Line 15
	MOV CX, AX
	POP AX
	CWD
	DIV CX
	MOV AX, DX
	MOV [BP-6], AX
	PUSH AX
	POP AX
L8:
	MOV AX, [BP-6]       ; Line 16
	CALL print_output
	CALL new_line
L9:
	MOV AX, [BP-6]
	PUSH AX
	MOV AX, [BP-4]
	MOV DX, AX
	POP AX
	CMP AX, DX
	JLE L10
	JMP L11
L10:
	MOV AX, 1       ; Line 18
	JMP L12
L11:
	MOV AX, 0
L12:
	MOV [BP-8], AX
	PUSH AX
	POP AX
L13:
	MOV AX, [BP-8]       ; Line 19
	CALL print_output
	CALL new_line
L14:
	MOV AX, i
	PUSH AX
	MOV AX, j
	MOV DX, AX
	POP AX
	CMP AX, DX
	JNE L15
	JMP L16
L15:
	MOV AX, 1       ; Line 21
	JMP L17
L16:
	MOV AX, 0
L17:
	MOV [BP-10], AX
	PUSH AX
	POP AX
L18:
	MOV AX, [BP-10]       ; Line 22
	CALL print_output
	CALL new_line
L19:
	MOV AX, [BP-8]
	PUSH AX
	MOV AX, [BP-10]
	MOV DX, AX
	POP AX
	CMP AX, 0
	JNE L20
	CMP DX, 0
	JNE L20
	MOV AX, 0
	JMP L22
L20:
	MOV AX, 1       ; Line 24
L22:
	MOV [BP-12], AX
	PUSH AX
	POP AX
L23:
	MOV AX, [BP-12]       ; Line 25
	CALL print_output
	CALL new_line
L24:
	MOV AX, [BP-8]
	PUSH AX
	MOV AX, [BP-10]
	MOV DX, AX
	POP AX
	CMP AX, 0
	JE L26
	CMP DX, 0
	JE L26
	MOV AX, 1       ; Line 27
	JMP L27
L26:
	MOV AX, 0
L27:
	MOV [BP-12], AX
	PUSH AX
	POP AX
L28:
	MOV AX, [BP-12]       ; Line 28
	CALL print_output
	CALL new_line
	MOV [BP-12], AX
	PUSH AX
	INC AX
	MOV [BP-12], AX
	POP AX
L29:
	MOV AX, [BP-12]       ; Line 31
	CALL print_output
	CALL new_line
L30:
	MOV AX, [BP-12]
	NEG AX       ; Line 33
	MOV [BP-2], AX
	PUSH AX
	POP AX
L31:
	MOV AX, [BP-2]       ; Line 34
	CALL print_output
	CALL new_line
	MOV AX, 0       ; Line 36
L32:
	ADD SP, 12
	POP BP
	MOV AX, 4CH
	INT 21H
main ENDP
END main
