void Iterate(inout vec3 z,in vec3 c) {
int i;
float qu,qv,qw;
float qa=-1.0;
float qb=-1.0;
float qc=-1.0;
float qd=-1.0;
float qe=-1.0;
float qf=-1.0;
float qg=-1.0;
float qh=-1.0;
float qi=0.0;
vec3 tmpz;

//triplex Z^power
for(i=0; i<power; i++)
{
tmpz.x = z.x*( a*z.x*z.x + b*z.y*z.y + c*z.z*z.z ) + c.x;
tmpz.y = z.y*( d*z.x*z.z + e*z.x*z.y + f*z.y*z.z ) + c.y;
tmpz.z = z.z*( g*z.x*z.y + h*z.y*z.z + i*z.x*z.z ) + c.z;
z = tmpz;
}
//triplex z+c
z.x=z.x+c.x;
z.y=z.y+c.y;
z.z=z.z+c.z;
}
