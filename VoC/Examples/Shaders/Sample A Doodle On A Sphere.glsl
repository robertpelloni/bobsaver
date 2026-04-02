#version 420

// original https://www.shadertoy.com/view/md3SDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Cole Peterson

#define R resolution.xy
#define m ( mouse*resolution.xy.xy - .5*R.xy ) / R.y
#define ss(a, b, t) smoothstep(a, b, t)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

vec4 sphere(vec3 ro, vec3 rd, vec3 cn, float r){
    float b = 2.*dot(rd, ro - cn);
    float c = dot(ro - cn, ro - cn) - (r*r);
    float d = (b*b) - (4.*c);
     
    if(d < 0.) 
        return vec4(0);
    else{
         float t = .5*(-b - sqrt(d));   
        return vec4(ro+rd*t, t);
    }
}

void main(void) {
	vec4 f = vec4(0.0);
	vec2 u = gl_FragCoord.xy;

    float t = time*.25 - 1.5;
    vec2 uv2 = vec2(u.xy - 0.5*R.xy)/R.y * rot(-t*.5);
    
    vec3 ro = vec3(0., 0., -2.0);
    vec3 rd = normalize(vec3(uv2, 1.));
    
    // Intersect sphere
    float rad = .88;
    vec3 nrm = vec3(0), cntr = vec3(0);
    vec4 p = sphere(ro, rd, cntr, rad);
    vec2 uv = 1.5*vec2( u - .5*R ) / R.y;
    
    if(p.w > 0.){
         nrm = normalize(p.xyz -cntr);
         uv = vec2(atan(nrm.z, nrm.x), acos(p.y / rad)); 
    }
    else
        uv /= (1.-.3*length(uv2*12.));

    uv += vec2(t*.5, -t*.2);
    
    //if(mouse*resolution.xy.z > 0.) uv += m*2.;
    
    // Fractal
    uv = (uv + vec2(-uv.y,uv.x) ) / 1.41;
    uv = -abs(fract(uv * .35) - .5);
    
    vec2 v = vec2(cos(.09), sin(.09));
    float dp = dot(uv, v);
    uv -= v*max(0., dp)*2.;
    
    float w = 0.;
    for(float i = 0.; i < 18.;i++){
        uv *= 1.35;
        uv = abs(uv);
        uv -= 0.5;
        uv -= v*min(0., dot(uv, v))*2.;
        uv *= rot(i*.02 + 33.83);
        uv.y += cos(uv.x*45.)*.003;
        w += dot(uv, uv);
    }
    
    float n = (w*12. + dp*25.);
    vec3 col = 1. - (.6 + .6*cos(vec3(.45, 0.6, .81) * n + t*5. +vec3(-.6, .3, -.6)));
    
    if(p.w > 0.){
        vec3 ld = normalize(vec3(.4, -.4, -1.));
        float dif = dot(nrm, ld);
        col *= dif;
    }
    else{
        col = col.yzx;
        col *= .11;
    }
    
    col *= max(ss(.04, .11, abs(uv.y*.4)), .1);
    f = vec4(1.-exp(-col), 1.);

	glFragColor = f;
}
