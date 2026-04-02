#version 420

// original https://www.shadertoy.com/view/3dVXzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS     80.
#define MAX_DIST    50.
#define MIN_DIST    .001
#define EPSILON        .0001

#define PI 3.1415926535897
#define PI2 6.281385306
// Change to 2 to for antialiasing
#define AA 2
#define ZERO (min(1,0))

mat2 r2(float a){ 
  float c = cos(a); float s = sin(a); 
  return mat2(c, s, -s, c); 
}

vec3 get_mouse(vec3 ro) {
    float x = mouse*resolution.xy.xy==vec2(0) ? 0.2 :
        (mouse.y*resolution.xy.y / resolution.y * 1. - .5) * PI;
    float y = mouse*resolution.xy.xy==vec2(0) ? .1 :
        -(mouse.x*resolution.xy.x / resolution.x * 1. - .5) * PI;
    float z = 0.0;

    ro.zy *= r2(x);
    //ro.zx *= r2(y);
    return ro;
}

//iq of hsv2rgb
vec3 hsv2rgb( in vec3 c ){
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}
//iq sdf functions and twist
float sdBox(vec3 p,vec3 s) {
    p = abs(p) - s;
    return max(max(p.x,p.y),p.z);
}
// twist update - little mouse action
vec3 twist( in vec3 p, in vec2 px ){
    float x = -(mouse.x*resolution.xy.x / resolution.x * 1.- .5) * PI;
        
    float k = 0.05 * x; 
    float c = cos(k*p.z);
    float s = sin(k*p.z);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3(m*p.xy,p.z);
    return q;
}

vec4 map(vec3 pos) {
    // set up size for repetition
    float size = 20.;
    float rep_dbl = size* 2.;
    float rep_half = size/2.;
    // get center vec and some movement
    vec3 center = vec3(0.,0., 0.);
    
    vec3 tt = pos-center;
    tt.zy *= r2(55.);
    tt.xy *= r2(time*0.1);
   
    //tt.y -= sin(tt.z*.25+time*3.);
    vec3 ti = vec3(
      floor((tt.x + size)/rep_dbl),
      floor((tt.y + size)/rep_dbl),
      floor((tt.z + rep_half)/size)
    );
    tt =  vec3(
      mod(tt.x+size,rep_dbl) - size,
      mod(tt.y+size,rep_dbl) - size,
      tt.z
    );
    tt = twist(tt,ti.xz);
    tt =  vec3(
      tt.x,
      tt.y,
      mod(tt.z+rep_half,size) - rep_half
    );
    float len = 10.5;
    float tx =  1.15;

    float d1 = sdBox(abs(tt)-vec3(10.,10.,0.), vec3(tx,tx,len) );
    float d2 = sdBox(abs(tt)-vec3(10.,0.,10.), vec3(tx,len,tx) );
    d1 = min(d1,d2);
    d2 = sdBox(abs(tt)-vec3(0.,10.,10.), vec3(len,tx,tx) );
    d1 = min(d1,d2);
    
    vec4 res = vec4(d1,ti);

    return res;
}

vec4 get_ray( in vec3 ro, in vec3 rd ) {
    float col = 0.0;
     float shd = 0.;
    vec3 mate = vec3(0.);
    vec3 p = ro;
    bool hit = false;
    
    for (float i=0.; i<MAX_STEPS; i++)
    {
        vec4 d = map(p);
        if (d.x<MIN_DIST||shd>MAX_DIST)
        {
            hit = true;
            shd = abs(i/90.);
            mate = vec3(d.y,d.z,d.w);
            break;
        }
        p += d.x*rd *.5;
    }
    if (hit) col = 1.-shd;
    return vec4(col,mate);
}
 
mat3 get_camera(vec3 ro, vec3 ta, float rotation) {
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(rotation), cos(rotation),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec3 color = vec3(0.);
    vec3 col = vec3(0.);
    vec2 uv;
    #if AA>1
        for( int m=ZERO; m<AA; m++ )
        for( int n=ZERO; n<AA; n++ )
        {
            vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
            uv = (2. * gl_FragCoord.xy - (resolution.xy+o))/resolution.y;
    #else    
            uv = (2. * gl_FragCoord.xy - resolution.xy )/resolution.y;
    #endif
       

    vec3 ta = vec3(0.0,0.0,0.);
    vec3 ro = vec3(0.,0.,-25.);
    ro = get_mouse(ro);
 
    mat3 cameraMatrix = get_camera(ro, ta, 0. );
    vec3 rd = cameraMatrix * normalize( vec3(uv.xy, .75) );

    vec4 dist = get_ray(ro, rd);
    vec3 pos = ro + dist.x * rd;
    float size = 20.;
    float rep_dbl = size* 2.;
    float rep_half = size/2.;

    if(dist.x>0.001) {
        float cv = dist.y*.1 + dist.z*.1;
        vec3 mate = hsv2rgb(vec3(cv,1.,.5));
        vec3 shade = vec3(dist.x);
        col = vec3(2.5) * smoothstep(.1,1.,shade); 

        color += col;
        color *= mate;
    } 
            
    #if AA>1
        }
        color /= float(AA*AA);
    #endif

    col = pow(col, vec3(0.4545));
    glFragColor = vec4(color,1.0);
}
