// this program copies a vector to other location and demonstrates how to use pointers.

jump start // skip data section
	
1:			$1 // you can use any names other than instruction keywords for tags, including numbers
origin:		original_vec
target:		copy_here
length:		$8	

// vector to be copied:
original_vec:	$1
				$4
				$9
				$16
				$25
				$36
				$49
				$64
				
// space to copy the vector to:
copy_here:		$0
				$0
				$0
				$0
				$0
				$0
				$0
				$0
				
bound:	$0
start:	load left origin
		copy right left
		add right length
		store right bound

loop:	jumpeq end
		store left copyfrom // set first pointer

		sub left origin // change base to target's, keep offset
		add left target
		store left copyto // set second pointer

		load right copyfrom: $0 // to resolve pointers, write directly to the cell
		store right copyto:	$0	// corresponding read/write operation's argument

		sub left target // change base back
		add left origin
		add left 1 		// increment

		load right bound
		jump loop

end:	halt
