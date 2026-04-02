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
							   __global float * mingravdist)
{	
	int index=get_global_id(0);
	float dx,dy,dz,distance,force;
	float positionx=posx[index];
	float positiony=posy[index];
	float positionz=posz[index];
	float mingravdistsqr=mingravdist[index]*mingravdist[index];
	float accelerationx=0;
	float accelerationy=0;
	float accelerationz=0;
	float thismass=mass[index];
	for(int a=0; a<get_local_size(0); a++) {
		if (a!=index) {
			dx=posx[a]-positionx;
			dy=posy[a]-positiony;
			dz=posz[a]-positionz;
			distance=sqrt(dx*dx+dy*dy+dz*dz);
			dx=dx/distance;
			dy=dy/distance;
			dz=dz/distance;
			//old method - all objects are assumed to have the same mass
			//force=1/(distance*distance+mingravdistsqr);
			//new method - allows objects to have different masses
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
