#version 420

// original https://www.shadertoy.com/view/4dy3Ry

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec3 a)
{
    //return length(p)-1.0;
    vec3 p = fract(a)*2.0-1.0;
    //vec2 q = vec2(length(p.xz)-2.0 - sin(time),p.y);
    vec2 q = vec2(length(p.xz)-1.0,p.y);
    return length(q)-.07;
}

float trace(vec3 origin, vec3 ray)
{
    float t = 0.0;
    for (int i = 0; i < 64; ++i){
         vec3 p = origin + ray*t;
        float d = map(p);
        t += d*.35;
    }
    return t;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv*2.0 - 1.0;
    uv.x *= resolution.x/resolution.y;
    
    //comment for no warping
    uv.x += sin(uv.y+time);
    
    vec3 rey = normalize(vec3(uv, .5)); // decrease z for greater camera FoV
    
    float the = time*.5;
    //rey.xz *= mat2(cos(the),-sin(the),sin(the),cos(the));
    
    // rotation matrix
    rey *= mat3(cos(the),sin(the),sin(the),.7*sin(the),.7,0.0,-sin(the),cos(the),cos(the)); 
    
    vec3 origin = vec3(time*.4,time*.2, 0.0);
    float t = trace(origin, rey);
    float fog = 1.0/(0.5+t*t*.3);
    //vec3 fc = vec3(fog);
    vec3 fc = vec3(sin(t)*9.0);
    fc.x = sin(time)*fc.x;
    fc.y = .33*sin(time)*fc.y;
    fc.z = .7*cos(time)+1.0;
    vec3 fcc = vec3(fog)*fc;
    
    //fc.x = (sin(time)+1.0)/2.0;
    //fc.x = 2.0-2.0*sin(time);
    glFragColor = vec4(fcc,.9);
}
