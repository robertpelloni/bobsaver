__kernel void Gravity3DKernel( __global float * posx,
							   __global float * posy,
							   __global float * posz, 
							   __global float * velx, 
							   __global float * vely, 
							   __global float * velz, 
							   __global float * accx, 
							   __global float * accy, 
							   __global float * accz, 
							   __global float * mass, 
							   __global float * mingravdist, 
							   __global float * gsize)
{
	int index=get_global_id(0);
	float dx,dy,dz,distance,force,dx1,dx2,dy1,dy2,dz1,dz2;
	float positionx=posx[index];
	float positiony=posy[index];
	float positionz=posz[index];
	float gridsize=gsize[index];
	float halfgridsize=gridsize/2;
	float mingravdistsqr=mingravdist[index]*mingravdist[index];
	float accelerationx=0;
	float accelerationy=0;
	float accelerationz=0;
	float thismass=mass[index];

	for(int a=0; a<get_global_size(0); a++) {
		if (a!=index) {

			//toroidal distance https://blog.demofox.org/2017/10/01/calculating-the-distance-between-points-in-wrap-around-toroidal-space/
			dx=fabs(positionx-posx[a]);
			dy=fabs(positiony-posy[a]);
			dz=fabs(positionz-posz[a]);
			if (dx>halfgridsize) { dx=gridsize-dx; }
			if (dy>halfgridsize) { dy=gridsize-dy; }
			if (dz>halfgridsize) { dz=gridsize-dz; }
			
			distance=sqrt(dx*dx+dy*dy+dz*dz);

			dx=dx/distance;
			dy=dy/distance;
			dz=dz/distance;

			force=(thismass*mass[a])/(distance*distance+mingravdistsqr);
		
			accelerationx+=dx*force;
			accelerationy+=dy*force;
			accelerationz+=dz*force;
		}
	}
	velx[index]+=accelerationx;
	vely[index]+=accelerationy;
	velz[index]+=accelerationz;
	accx[index]=accelerationx;
	accy[index]=accelerationy;
	accz[index]=accelerationz;
}
