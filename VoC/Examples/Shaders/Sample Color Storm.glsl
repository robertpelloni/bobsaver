#version 420

// original https://www.shadertoy.com/view/cdlBW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//philip.bertani@gmail.com
float numOct  = 5.;
#define pi  3.14159265
float random(vec2 p) {
    return fract( sin( dot( p, vec2(12., 90.)))* 1e5 );
}
float noise(vec3 p, float k) {
    int kk = int(k)%3, jj= (int(k)+1)%3;
    vec2 i = floor( vec2(p[kk],p[jj]) );
    vec2 f = fract( vec2(p[kk],p[jj]) );
    float a = random(i + vec2(0.,0.));
    float b = random(i + vec2(1.,0.));
    float c = random(i + vec2(0.,1.));
    float d = random(i + vec2(1.,1.));
    vec2 u =  f*f*(3.-2.*f);   
    return mix(a,b,u.x) + (c-a)*u.y*(1.-u.x) + (d-b)*u.x*u.y;
}
float fbm3d(vec3 p, float i) {
    float v = 0., a = .3 + i/10.;    
    for (float i=0.; i<numOct; i++) {
        v += a * noise(p, i);
        p = p * 1.6; 
    }
    return v;
}
mat2 rotg(float an) {
     float cc=cos(an),ss=sin(an); return mat2(cc,-ss,ss,cc);
}
void main(void) {
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y*5.;
    vec3 rd = normalize( vec3(uv, -2.) ), ro = vec3(0.,1.,0.);      
    ro.z -= time/5.;
    vec3 p = ro + rd, q, cc = vec3(0.);
    float stepsize = 1.5;  
    for (float i=0.; i<5.; i++) {
        numOct =  - i/1.2 + 5. ;
        p.xy *= rotg((sqrt(i)/4.)*time);
        q.x = fbm3d(p,i);
        q.y = fbm3d(p.yzx,i);
        q.z = fbm3d(p.zxy,i);
        float f = fbm3d(p + q,i);
        p += stepsize * rd;
        cc += q * f * exp(-i*i/15.);        
    }
    cc = 1. - exp(-cc/1.3);    
    cc = pow( cc,vec3(8.));
    glFragColor = vec4(cc,1.0);
}

