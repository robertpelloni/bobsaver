__kernel void PhotonKernel( __global float * r )
{	
	unsigned int index=get_global_id(0);
	r[index]=1.0;
}
