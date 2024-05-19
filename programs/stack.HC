// this program inverts the order of elements in a vector to demonstrate stack operations

jump start

vec_1:	$hAA
vec_2: 	$hBB
vec_3:	$hCC

start:	load left vec_1
		push left
		load left vec_2
		push left
		load left vec_3
		push left

		pop left
		store left vec_1
		pop left
		store left vec_2
		pop left
		store left vec_3

		halt
