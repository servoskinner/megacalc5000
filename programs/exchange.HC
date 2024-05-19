// this program exchanges the values of two data cells,
// labeled first and second

load left first
load right second
store left second
store right first
halt

first: 	$hDEAD
second: $hBABE
