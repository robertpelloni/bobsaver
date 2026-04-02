#version 420

// original https://www.shadertoy.com/view/sdKyR3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//philip.bertani@gmail.com

#define oct 6   //number of fbm octaves
#define pi  3.14159265

float random(vec2 p) {
    //a random modification of the one and only random() func
    return fract( sin( dot( p, vec2(12., 90.)))* 1e5 );
}

//this is taken from Visions of Chaos shader "Sample Noise 2D 4.glsl"
float noise(vec3 p) {
    vec2 i = floor(p.yz);
    vec2 f = fract(p.yz);
    float a = random(i + vec2(0.,0.));
    float b = random(i + vec2(1.,0.));
    float c = random(i + vec2(0.,1.));
    float d = random(i + vec2(1.,1.));
    vec2 u = f*f*(3.-2.*f); //smoothstep here, it also looks good with u=f
    
    //this equation is genius and i cannot figure out why it works so well
    return mix(a,b,u.x) + (c-a)*u.y*(1.-u.x) + (d-b)*u.x*u.y;

}

float fbm3d(vec3 p) {
    float v = 0.;
    float a = .5;
    vec3 shift = vec3(100.);  //play with this
    
    float angle = pi/2.;      //play with this
    float cc=cos(angle), ss=sin(angle);  //yes- I know cos(pi/2.)=0.
    mat3 rot = mat3( cc,  0., ss, 
                      0., 1., 0.,
                     -ss, 0., cc );
    for (int i=0; i<oct; i++) {
        v += a * noise(p);
        p = rot * p * 2. + shift;
        a *= .6;  //changed from the usual .5
    }
    return v;
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

    float tt = time / 8.;
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec2 mm = (2.*mouse*resolution.xy.xy-resolution.xy)/resolution.y;

    vec3 rd = normalize( vec3(uv, -2.) );  
    vec3 ro = vec3(0.,1.,0.);
    
    float delta = 2.*pi/10.;
    mat3 rot = rxz(-mm.x*delta) * ryz(-mm.y*delta);
    
    ro -= rot[2]*time/3.;
    
    vec3 p = ro + rot*rd;
    
    vec3 q;

    q.x = fbm3d(p);
    q.y = fbm3d(p.yzx);
    q.z = fbm3d(p.zxy);

    float f = fbm3d(p + q);
    
    vec3 cc = 5.*q;
    cc = pow(cc * f , vec3(2.3));    //play with this

    glFragColor = vec4(cc/11.,1.0);
    
    
}

