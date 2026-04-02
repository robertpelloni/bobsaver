#version 420

// original https://www.shadertoy.com/view/dsdSzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//philip.bertani@gmail.com

float numOct  = 3. ;  //number of fbm octaves
#define pi  3.14159265

float random(vec2 p) {
    //a random modification of the one and only random() func
    return fract( sin( dot( p, vec2(12., 90.)))* 1e6 );
}

float noise(vec3 p, float k) {
    int kk = int(k)%3, jj= (int(k)+1)%3;
    vec2 i = floor( vec2(p[kk],p[jj]) );
    vec2 f = fract( vec2(p[kk],p[jj]) );
    float a = random(i + vec2(0.,0.));
    float b = random(i + vec2(1.,0.));
    float c = random(i + vec2(0.,1.));
    float d = random(i + vec2(1.,1.));
    vec2 u =  f*f*(3.-2.*f); //smoothstep here
    
    return mix(a,b,u.x) + (c-a)*u.y*(1.-u.x) + (d-b)*u.x*u.y;
}

float fbm3d(vec3 p, float i) {
    float v = 0.;
    float a = .5;    

    for (float i=0.; i<numOct; i++) {
        v += a * noise(p, i);
        p = p * 2. + p/(1.+i); 
    }
    return v;
}

mat2 rotg(float an) {
     float cc=cos(an),ss=sin(an); 
     return mat2(cc,-ss,ss,cc);
}

mat3 rxz(float an){
    float cc=cos(an),ss=sin(an);
    return mat3(cc,0.,-ss,
                0.,1.,0.,
                ss,0.,cc);                
}
mat3 ryz(float an){
    float cc=cos(an),ss=sin(an);
    return mat3(1.,0.,0.,
                0.,cc,-ss,
                0.,ss,cc);
}                

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y*2.;
    vec2 mm = (2.*mouse*resolution.xy.xy-resolution.xy)/resolution.y/40.;

    //if ( mouse*resolution.xy.w == 0. )  mm += vec2(.1,0.); 

    vec3 rd = normalize( vec3(uv, -2.) );  
    vec3 ro = vec3(0.,1.,0.);
    
    float delta = mod(time,30.);
    mat3 rot = rxz(-mm.x*delta) * ryz(-mm.y*delta);
       
    ro -= rot[2]*time/6.;
    
    vec3 p = ro + rot*rd;
    
    vec3 q;
    
    vec3 cc = vec3(0.);
    float stepsize = 1.5;
    
    for (float i=0.; i<3.; i++) {
        q.x = fbm3d(p,i);
        q.y = fbm3d(p.yzx,i);
        q.z = fbm3d(p.zxy,i);
        float f = fbm3d(p + q,i);
        p += stepsize * rd;
        cc += q * f * exp(-i*i/4.);        
    }

    cc = 1. - exp(-cc);    
    cc = pow(cc,vec3(3.));
    glFragColor = vec4(cc,1.0);
    
}

