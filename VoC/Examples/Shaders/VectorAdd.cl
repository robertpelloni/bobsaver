__kernel void VectorAdd(__global float * c, __global float * a,__global float * b)
{
	// Index of the elements to add
	unsigned int n = get_global_id(0);
	// Sum the nth element of vectors a and b and store in c
	c[n] = a[n] + b[n];
}
