#version 420

// original https://www.shadertoy.com/view/3tcBz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Creative Commons Licence Attribution-NonCommercial-ShareAlike 
   phreax 2021
*/

#define PI 3.141592
#define SIN(x) (sin(x)*.5+.5)
#define hue(v) ( .6 + .6 * cos( 6.3*(v) + vec3(0,23,21) ) )
#define RAINBOW 0

float tt;

mat2 rot2(float a) { return mat2(cos(a), sin(a), -sin(a), cos(a)); }

// by Nusan
float curve(float t, float d) {
  t/=d;
  return mix(floor(t), floor(t)+1., pow(smoothstep(0.,1.,fract(t)), 10.));
}

vec3 transform(vec3 p) {
    float a = PI*.5*curve(time, 4.);
    
    // rotate object
    p.xz *= rot2(a);
    p.xy *= rot2(a);
    return p;
}

float map(vec3 p) {

    vec3 bp = p;

    p = transform(p);

    //p.y = -(abs(p.y) -.3);   
    
    p.x *= 1.+.5*(smoothstep(-0.9, 0.9, -p.y));
    p.z *= 1.+.5*(smoothstep(-0.9, 1.5, -p.y));

    p.x = abs(p.x) -.5*SIN(tt*.5);
    p.y = abs(p.y) -.9*SIN(tt*.8);
    p.y -= 0.1;
    p.y = abs(p.y) -.1;
    p.x -= 0.2;
    p.x = abs(p.x) -.9; 
    p.z = abs(p.z) -.5;

    p.zy -= 0.5;
    p.xy *= rot2(0.1*tt);
    p.zy *= rot2(-.04*tt);
                           

    // torus
    float r1 = 1.0;
    float r2 = 0.03;
    
    vec2 cp = vec2(length(p.xz) - r1, p.y);
    vec2 cp2 = cp;
    
    // torus knots by BigWings
    float a = atan(p.z, p.x);
    cp *= rot2(3.*a+tt);
    cp.x = abs(cp.x) - .3;

    cp *= rot2(3.*a);
    
    // kifs
    float n = 10.;
    for(float i = 0.; i< n; i++) {
    
        cp.y = abs(cp.y) -.05*(.5*sin(tt)+.9);
        
        cp *= rot2(0.1*a*sin(0.1*time));
        cp -= i*0.01/n;
    }

    
    float d = length(cp) - r2;
  
    return .4*d;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float cz = -5.+1.*sin(curve(time, 2.));
    
    vec3 ro = vec3(0, .0, cz),
         rd = normalize(vec3(uv, .7));
         
    vec3 p = ro;
    vec3 col;
    
    float t, d = 0.1;
    
    tt = time;  
    tt = tt+2.*curve(tt, 2.);
    
    float acc = 0.0;
    for(float i=.0; i<200.; i++) {
    
        d = map(p);
        
        if(d < 0.0001 || t > 100.) break;
        
        // Phantom mode https://www.shadertoy.com/view/MtScWW
        d = max(abs(d), 0.009);
        acc += 0.07;
        
        t += d;
        p += rd*d;
    }
       
    if(d < 0.001) {
        col += 5./(t*t);
        float l = length(p);
        #if RAINBOW
            col *= acc*0.5*hue(1.-0.1*l+0.05*p.z+.25*time+curve(time, 4.));
        #else
            col *= acc*mix(vec3(0, .85, .75), vec3(.75, 0.35, .0), 1.-0.1*l*l+0.1*p.z);
        #endif
    }
    
    col = pow(col, vec3(1.3));
    
    // Output to screen
    glFragColor = vec4(col, 1.0 - t * 0.3);
}
