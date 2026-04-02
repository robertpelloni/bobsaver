#version 420

// original https://www.shadertoy.com/view/lXG3Wz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}

const float F3 =  0.3333333;
const float G3 =  0.1666667;
float snoise(vec3 p) {

    vec3 s = floor(p + dot(p, vec3(F3)));
    vec3 x = p - s + dot(s, vec3(G3));

    vec3 e = step(vec3(0.0), x - x.yzx);
    vec3 i1 = e*(1.0 - e.zxy);
    vec3 i2 = 1.0 - e.zxy*(1.0 - e);

    vec3 x1 = x - i1 + G3;
    vec3 x2 = x - i2 + 2.0*G3;
    vec3 x3 = x - 1.0 + 3.0*G3;

    vec4 w, d;

    w.x = dot(x, x);
    w.y = dot(x1, x1);
    w.z = dot(x2, x2);
    w.w = dot(x3, x3);

    w = max(0.6 - w, 0.0);

    d.x = dot(random3(s), x);
    d.y = dot(random3(s + i1), x1);
    d.z = dot(random3(s + i2), x2);
    d.w = dot(random3(s + 1.0), x3);

    w *= w;
    w *= w;
    d *= w;

    return dot(d, vec4(52.0));
}

const float PI = acos(-1.0);

float map(float v, float v_min, float v_max, float out1, float out2)
{
    if ( v_max - v_min == 0. )
        return out2;
        
     return (clamp(v,v_min,v_max) - v_min) / (v_max - v_min) * (out2-out1)+out1;
}

float fmod(float t,float a){
  return fract(t/a)*a;
}

#define nz1(x)   ( snoise(vec3(x,0.,0.)) )

vec4 disco_sun(vec2 uv) {

    uv += vec2(nz1(time),nz1(time+12.34)) * 0.2;
    float vz = 20. + nz1(time + 56.78)*10.;
    
    float far = clamp(2.0  / length(uv ) ,0., vz) + 0.25;
    float nfar = map(far, 0., vz, 0.,1.);
    float light = pow(nfar , map( sin(time*8.1234),-1.,1.,2.5,4.) );
    
    float light_g = map( pow( nfar, map( sin( time * 4.1234),-1.,1.,0.5,8.) ),0.,1.,0.5,0.7);
    

    float color =  pow( abs( snoise(vec3( uv.x*far*1.6,uv.y*far*1.6, time*1.2 ))*1.7 ), 8.);
    return vec4( color+light*0.8, color*light_g, color*light_g*0.33, 1.0 );
    
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy/2.) / min(resolution.x, resolution.y);
               
    glFragColor = disco_sun(uv);
    
}

