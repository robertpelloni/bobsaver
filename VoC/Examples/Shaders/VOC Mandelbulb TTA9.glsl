void Iterate(inout vec3 z,in vec3 c) {
int i;
float qu,qv,qw;
float qa=1.0;
float qb=1.0;
float qc=1.0;
float qd=1.0;
float qe=1.0;
float qf=1.0;
float qg=1.0;
float qh=1.0;
float qi=1.0;
vec3 tmpz;

//triplex Z^power
for(i=0; i<power; i++)
{
tmpz.x = z.x*( qa*z.x*z.x + qb*z.y*z.y + qc*z.z*z.z );
tmpz.y = z.y*( qd*z.x*z.z + qe*z.x*z.y + qf*z.y*z.z );
tmpz.z = z.z*( qg*z.x*z.y + qh*z.y*z.z + qi*z.x*z.z );
z = tmpz;
}
//triplex z+c
z.x=z.x+c.x;
z.y=z.y+c.y;
z.z=z.z+c.z;
}
