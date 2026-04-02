#version 420

// original https://www.shadertoy.com/view/NsVyRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define oct 5    //number of fbm octaves
#define pi  3.14159265

float random(vec2 p) {
    //a random modification of the one and only random() func
    return fract( sin( dot( p, vec2(12., 90.)))* 1e5 );
}

//this is taken from Visions of Chaos shader "Sample Noise 2D 4.glsl"
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = random(i + vec2(0.,0.));
    float b = random(i + vec2(1.,0.));
    float c = random(i + vec2(0.,1.));
    float d = random(i + vec2(1.,1.));
    vec2 u = f*f*(3.-2.*f); //smoothstep here, it also looks good with u=f
    
    //this equation is genius and i cannot figure out why it works so well
    return mix(a,b,u.x) + (c-a)*u.y*(1.-u.x) + (d-b)*u.x*u.y;

}

float fbm(vec2 p) {
    float v = 0.;
    float a = .5;
    vec2 shift = vec2(100.);  //play with this
    
    float angle = pi/4.;      //play with this
    float cc=cos(angle), ss=sin(angle);
    mat2 rot = mat2( cc, ss, -ss, cc );
    for (int i=0; i<oct; i++) {
        v += a * noise(p);
        p = rot * p * 2. + shift;
        a *= .6;  //changed from the usual .5
    }
    return v;
}

void main(void)
{

    float tt = time / 8.;
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv += 3.*vec2(cos(tt/5.),sin(tt/3.));  //move around in ellipse
    //uv *= 5.;  //check out the zoomed out view

    vec2 q = vec2(0.), r = vec2(0.);

    q.x = fbm(uv);
    q.y = fbm(uv + vec2(2.+tt/3.));
    r.x = fbm(uv + q + vec2(3., 8.) + tt);
    r.y = fbm(uv + q + vec2(8., 3.) + tt/2.);   
 
    float f = fbm(uv + r);
    
    vec3 cc = 3.*vec3(q.x,q.y,r.x);
    cc = f*f*pow(cc, vec3(2.5));    //play with this

    glFragColor = vec4(cc/4.,1.0);
    
    
}
