#version 420

// original https://www.shadertoy.com/view/lXtGRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//philip.bertani@gmail.com

float focus = 0.;
float focus2 = 0.;
#define pi  3.14159265

float random(vec2 p) {
    //a random modification of the one and only random() func
    return fract( sin( dot( p, vec2(12., 90.)))* 1e6 );
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

float noise(vec3 p) {
    vec2 i = floor(p.yz);
    vec2 f = fract(p.yz);
    float a = random(i + vec2(0.,0.));
    float b = random(i + vec2(1.,0.));
    float c = random(i + vec2(0.,1.));
    float d = random(i + vec2(1.,1.));
    vec2 u = f*f*(3.-2.*f);
    
    return mix(a,b,u.x) + (c-a)*u.y*(1.-u.x) + (d-b)*u.x*u.y;

}

float fbm3d(vec3 p) {
    float v = 0.;
    float a = .5;
    vec3 shift = vec3(focus - focus2);  //play with this
    
    float angle = pi/3. ;
    float cc=cos(angle), ss=sin(angle);  
    mat3 rot = mat3( cc,  0., ss, 
                      0., 1., 0.,
                     -ss, 0., cc );
                     
    for (float i=0.; i<2.; i++) {
        v += a * noise(p);
        p = rot * p * 2. + shift;
        a *= .5 *(1.+ 2.5*(focus+focus2));  //changed from the usual .5
    }
    return v;
}

           

void main(void)
{

    float coord_scale = 1.5;
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec2 mm = (2.*vec2(0,0)*resolution.xy.xy-resolution.xy)/resolution.y;

    mm.xy += vec2(2.5,.6);

    uv *= coord_scale;
    mm *= coord_scale;

    vec3 rd = normalize( vec3(uv, -2.) );  
    vec3 ro = vec3(0.,1.,0.);
    
    float delta = pi/100.;
    
    mat3 rot = rxz(-mm.x*delta) * ryz(-mm.y*delta);
    
    ro -= rot[2]*time;
    
    
    vec3 q;
    
    
    focus = length(uv-mm);
    focus = sqrt(focus);
    focus = 2./(1.+focus/2.); 

    focus2 = length(uv+mm );
    focus2 = 1.6/(1.+focus2*focus2);
    
    
    float i=0., stepsize=1.;
    vec3 cc=vec3(0);
    vec3 p=ro;
    for (; i<4.; i++) {
        
        p += rd * stepsize;
           
        q.x = fbm3d(p);
        q.y = fbm3d(p.yzx);
        q.z = fbm3d(p.zxy);
        
        float f = fbm3d(p + q);
       
        cc += q * f * exp(-i*i/10.);
    }
    
    cc.r += 2.5*focus*focus; cc.g+= 1.5*focus; cc.b += 7.*focus2; cc.r-=4.*focus2;    
    cc /= 7.;
    
    glFragColor = vec4( pow(cc,vec3(2.)),1.0);
    
}
