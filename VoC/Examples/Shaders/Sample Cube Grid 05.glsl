#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITE_MAX      40
#define DIST_COEFF   1.00
#define DIST_MIN     0.01
#define DIST_MAX     1000.0

#define inf 100000
#define PI 3.14159276

#define ELIM(arg) ,arg
#define GEN_REP(NAME,META_PRIM,arg)  float NAME(vec3 p,vec3 c){ vec3 q = vec3(mod((p).x,(c).x)-0.5*(c).x,mod((p).y,(c).y)-0.5*(c).y,mod((p).z,(c).z)-0.5*(c).z);return META_PRIM(q ELIM(arg));}
#define GEN_TRANS(NAME,META_PRIM,arg) float NAME(vec3 p,mat4 m){vec4 q = m*vec4(p,1.);return META_PRIM(q.xyz ELIM(arg));}
#define GEN_SCALE(NAME,META_PRIM,arg) float NAME(vec3 p, float s){return META_PRIM(p/s ELIM(arg))*s;}

mat3 rotationMatrix(vec3 axis, float angle)
{
   
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat3(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c );
}

vec3 GenRay(vec3 pos,vec3 dir,vec3 up,float angle)
{
 vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
vec3 u = normalize(cross(dir,up));
vec3 v = normalize(cross(u,dir));
    
float fov = angle * PI * 0.5 / 180.;

return  normalize(sin(fov) * u * p.x + sin(fov) * v * p.y + cos(fov) * dir);
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float sdCross( in vec3 p )
{
  float da = sdBox(p.xyz,vec3(inf,1.0,1.0));
  float db = sdBox(p.yzx,vec3(1.0,inf,1.0));
  float dc = sdBox(p.zxy,vec3(1.0,1.0,inf));
  return min(da,min(db,dc));
}

mat4 time_shift(){
mat4 mat = mat4(1.);
    mat[0][0] = 1.*sin(time);
    return mat;
}

GEN_REP(Boxes,sdBox,(vec3(1.0)))
GEN_TRANS(G_Boxes,Boxes,(vec3(8.)))
GEN_SCALE(S_Boxes,G_Boxes,(time_shift()))
    
float map5( in vec3 p )
{
   float d = S_Boxes(p,.06);
   return d;
}
    

         void main( void ) {
        if(abs(sin(time)) > 1.)
            return;
             vec2 uv = ( gl_FragCoord.xy / resolution.xy ) * 2.0 - 1.0;
             float aspect = resolution.x / resolution.y;
             vec3  dir = normalize(vec3(uv * vec2(aspect, 1.0), 1.0));
             vec3 pos = vec3(0.5,0.,-2.5);
             dir = GenRay(pos,vec3(0.,0.,1.),vec3(1.,0.,0.),120.);
             float t = 0.0;
             for(int i = 0 ; i < ITE_MAX; i++) {
                 float ttemp = map5(rotationMatrix(vec3(.0,1.,0.),time)*(t * dir + pos));
                 if(ttemp < DIST_MIN) break;
                 t += ttemp * DIST_COEFF;
             }
             vec3 ip = pos + dir * t;
             vec3 color = vec3(1./t);
             glFragColor = vec4(color, 1.0);
}
