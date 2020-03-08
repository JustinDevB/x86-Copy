;#include <stdio.h>
;#include <unistd.h>
;#include <string.h>
;#include <errno.h>
;#include <sys/stat.h>
;#include <sys/types.h>
;#include <fcntl.h>

;#define BUF_SIZE	4096

;/**
; * (5 points)
; */
;int main(int argc, char *argv[])
;{
;  if (argc == 2 && strcmp(argv[1], "--help") == 0) {
;    printf("Print a more helpful usage here.\n");
;    return 0;
;  } else if (argc != 3) {
;    printf("Usage: cp <src> <dst>\n");
;    return 0;
;  }
;
;  int src = open(argv[1], O_RDONLY);
;  if (src < 0) {
;    printf("Error opening source file.\n");
;    return 1;
;  }
;  int dst = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0666);
;  if (dst < 0) {
;    printf("Error opening destination file.\n");
;    return 1;
;  }
;  
;  char buf[BUF_SIZE];
;  int r;
;  while ((r = read(src, buf, BUF_SIZE)) > 0) {
;    write(dst, buf, r);
;  }
;
;  close(src);
;  close(dst);
;
;  return 0;
;}


%include "syscalls.h"

SECTION .bss
	src: resq 1
	dst: resq 1
	buf: resb 1024

SECTION .data
	mesg: db `Error opening file\n`
	help: db `Print a more useful help here\n`
	args: db `Not enough args\n`


SECTION .text
global _start
_start:
	cmp [rsp], BYTE 2
	je .usage

	
	; Open src
	mov rax, SYS_OPEN
	mov rdi, [rsp+16]
	mov rsi, O_RDONLY
	syscall
	cmp rax, 0
	jl .error
	mov [src], rax
	
	;open dst
	mov rax, SYS_OPEN
	mov rdi, [rsp+24]
	mov rsi, O_CREAT
	mov r12, O_WRONLY
	or rsi, r12
	mov r12, O_TRUNC
	or rsi, r12
	mov rdx, 0o666
	syscall
	cmp rax, 0
	jl .error
	mov [dst], rax
	
	
.while:
	; Read
	mov rax, SYS_READ
	mov rdi, [src]
	mov rsi, buf
	mov rdx, 1024
	syscall
	mov r15, rax
	
	cmp r15, 0
	jle .exit

	;Write
	mov rax, SYS_WRITE
	mov rdi, [dst]
	mov rsi, buf
	mov rdx, r15
	syscall
	jmp .while

.exit:
	mov rax, SYS_EXIT
	mov rdi, 0
	syscall	
	

.error:
	mov rax, SYS_WRITE
	mov rdi, 1
	mov rsi, mesg
	mov rdx, 20
	syscall
	jmp .exit

.usage:
	mov rsi, [rsp+16]
	cmp BYTE [rsi], '-'
	jne .usage2
	cmp BYTE [rsi+1], '-'	
	jne .usage2
	cmp BYTE [rsi+2], 'h'
	jne .usage2
	cmp BYTE [rsi+3], 'e'
	jne .usage2
	cmp BYTE [rsi+4], 'l'
	jne .usage2
	cmp BYTE [rsi+5], 'p'
	jne .usage2
	jmp .helpful

.usage2:
	mov rax, SYS_WRITE
	mov rdi, 1
	mov rsi, args
	mov rdx, 17
	syscall
	jmp .exit

.helpful:
	mov rax, SYS_WRITE
	mov rdi, 1
	mov rsi, help
	mov rdx, 31
	syscall
	jmp .exit
		
