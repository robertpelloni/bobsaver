#version 420

// original https://www.shadertoy.com/view/tsKXRd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define hue(h) clamp( abs( fract(h + vec4(3,2,1,0)/3.) * 6. - 3.) -1. , 0., 1.)
#define rand1(p) fract(sin(p* 78.233)* 43758.5453) 

float map(vec3 p) {    
    vec3 pp = floor(p+.1);
    p += vec3(
        time * (rand1(pp.z) - .5),
        time * (rand1(pp.z + 200.) - .5), 
        0.
    );
        
    return length(
        (fract(p) - 0.5)                
    ) - .15 + sin(time*2.)*.025;
}
vec3 getN(vec3 p) {
    float t = map(p);
    vec2 d = vec2(0.001, .0);
    return normalize(vec3(
        t - map(p + d.xyy),
        t - map(p + d.yxy),
        t - map(p + d.yyx)));
        
}
    
void main(void)
{    
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy)/resolution.y;       

    vec3 dir = normalize(vec3(uv, 1.));
    vec3 pos = vec3(-50 , 50, 1.);
    float t= 0.0;
    for(int i = 0 ; i < 200; i++ ) {
        t += map(dir * t * 1.0 + pos);        
    }
    vec3 ip = dir * t + pos;
    vec3 L = normalize(vec3(1,2,3));
    vec3 N = getN(ip);

    vec3 ipp = floor(ip);    
    
    ipp = floor(ipp);    
    vec3 vip = ip + vec3(
        time * (rand1(ipp.z) - .5),
        time * (rand1(ipp.z + 200.) - .5), 
        0.
    );
    vip = floor(vip);
    
    vec3 col = hue(rand1(floor(vip.z*vip.x*vip.y)*.1)).rgb;       
    
    glFragColor = vec4(col * dot(L, N), 1.);
}
