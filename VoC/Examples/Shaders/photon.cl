__kernel void PhotonKernel( __global uchar* r,
							__global uchar* g,
							__global uchar* b, 
							__global uchar* a,
							__global int* w,
							__global int* h,
							__global int* rcol,
							__global int* gcol,
							__global int* bcol
							)
{	
	unsigned int index=get_global_id(0);
	
	//X and Y pixel coodinates
	int x_pos=index%w[0]; //X pixel coordinate
	int y_pos=index/w[0]; //Y pixel coordinate
	
	//line at center X and Y axiis
	if ((x_pos==w[0]/2) || (y_pos==h[0]/2)) {
		r[index]=0;
		g[index]=0;
		b[index]=0;
	} else {
		//red scaled from left to right
		//r[index]=(float)x_pos/(float)(w[0]/256.0);
		//green scaled from top to bottom		
		//g[index]=(float)y_pos/(float)(h[0]/256.0);
		//b[index]=0;
		r[index]=rcol[0];		
		g[index]=gcol[0];		
		b[index]=bcol[0];		
	}
	a[index]=255;
}
