main PROC
	MOV AX, @DATA
	MOV DS, AX
	PUSH BP
	MOV BP, SP
	SUB SP, 2
	SUB SP, 2
	SUB SP, 2
	SUB SP, 2
L1:
	MOV AX, 0       ; Line 5
	MOV [BP-2], AX       ; Line 5
	PUSH AX
	POP AX
L2:
	MOV AX, [BP-2]
	PUSH AX
	MOV AX, 6       ; Line 5
	MOV DX, AX
	POP AX
	CMP AX, DX
	JL L4
	JMP L5
L4:
	MOV AX, 1       ; Line 5
	JMP L6
L5:
	MOV AX, 0
L6:
	CMP AX, 0
	JE L3
	MOV [BP-2], AX
	PUSH AX
	INC AX
	MOV [BP-2], AX
	POP AX
L8:
	MOV AX, [BP-2]       ; Line 6
	CALL print_output
	CALL new_line
L7:
	JMP L2
L3:
	MOV AX, 0       ; Line 12
L9:
	ADD SP, 8
	POP BP
	MOV AX, 4CH
	INT 21H
main ENDP
END main
