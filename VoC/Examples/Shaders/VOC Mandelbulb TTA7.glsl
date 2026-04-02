void Iterate(inout vec3 z,in vec3 c) {
int i;
float qu,qv,qw;
float qa=-1.0;
float qb=-1.0;
float qc=1.0;
float qd=1.0;
float qe=-1.0;
float qf=0.0;
float qg=1.0;
float qh=1.0;
float qi=-1.0;
float qj=1.0;
float qk=-1.0;
float ql=-1.0;
vec3 tmpz;

//triplex Z^power
for(i=0; i<power; i++)
{
float zxzx=z.x*z.x;
float zyzy=z.y*z.y;
float zyzz=z.y*z.z;
float zzzz=z.z*z.z;
tmpz.x = z.x*( zxzx + zyzz*(qg + qj) + zyzy*qa + zzzz*qd );
tmpz.y = z.y*( 2.0*z.x*z.y + zyzz*(qh + qk) + zyzy*qb + zzzz*qe );
tmpz.z = z.z*( 2.0*z.x*z.z + zyzz*(qi + ql) + zyzy*qc + zzzz*qf );
z = tmpz;
}
//triplex z+c
z.x=z.x+c.x;
z.y=z.y+c.y;
z.z=z.z+c.z;
}
