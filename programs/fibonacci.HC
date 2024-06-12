jump start

// data section
1:	$1
3:	$3
raddr:	$0

// find n-th Fibonacci number
// n is pushed onto stack before calling
// result is placed onto stack below return pointer

fibonacci:	pop left
			store left raddr
			pop left		// save return address from stack
			load right 3
			jumprg ret_one 	// if n < 3 (1, 2) then return 1
			
			load right raddr // return address to stack
			push right
			
			sub left 1		 // load args for next calls
			push left	
			sub left 1
			push left

			call fibonacci 	// get n-2th number
			pop left		// exchange 2 last elements on stack
			pop right	   
			push left 
			push right

			call fibonacci	// get n-1th number
			pop left
			pop right
			add left right
			pop right		// put result under return pointer
			jump fb_end

ret_one:	load left 1
			load right raddr
fb_end:		push left
			push right
			ret

// another data
arg: $1

start:	load left arg
		push left
		call fibonacci
		pop left
		halt
