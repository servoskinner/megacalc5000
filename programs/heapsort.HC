jump start

// data section
// -------------
// constants

0:		$0
1:		$1
2:		$2

arr_start:	array
arr_length:	$11	

array:	$13
		$6
		$5
		$2
		$11
		$23
		$8
		$8
		$1
		$19
		$2

length: $11

cntr:	$0
end:	$0
comp:	$0

lchild:	copy right left // set RIGHT to index of left child of LEFT
		add	 right left
		add  right 1
		ret
	
rchild: copy right left // set RIGHT to index of left child of LEFT
		add  right left
		add  right 2
		ret
		
parent:	push left
		load right 0
p_div_loop:	sub left 2
			
p_div_end:	


start:	// heapify
		load  left 0					
		store left cntr
		store left sift_c

siftdn:	
