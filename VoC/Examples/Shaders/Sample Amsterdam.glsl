#version 420

// original https://www.shadertoy.com/view/ltVcDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Rotation
mat2 rot(float a) {
    return mat2(cos(a), -sin(a),
                sin(a), cos(a));
}
//Changing vector p
void pMod(inout vec3 p, vec3 rad) {
    p = mod(p + rad*0.5, rad) - rad*.5;
}
//Create spheres
float sphere(vec3 p, float rad) {
    return length(p) - rad;
}

//Map distance
float map(vec3 p) {
    vec3 q = p;

    pMod(q, vec3(0.75, 1., 0.8));
    
    float s1 = sphere(p, sin(time)); 
    float s2 = sphere(q, .5);
    
    float disp = .75 * (p.x *
                       p.y *
                       p.z);
    s1 += disp;
    return min(s1, s2); //return union    
}

//Trace
float trace(vec3 origin, vec3 ray) 
{
  float disp = 0.0;
    for (int i = 0; i < 128; ++i) {
        vec3 p = origin + ray * disp;
        float d = map(p);
        disp += d*.05;
        }
    return disp;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec3 color = vec3(0.924, 0.24, 0.336);
    uv = uv *2.-1.; // Remap the space to -1. to 1.
    uv.x *= resolution.x/resolution.y;
    
        
       float FOV = cos(time)*.75;
       vec3 ray = normalize(vec3(uv, FOV));
    
    
    vec3 og = vec3(time, 0.0, -1.75);
    float tr = trace(og, ray);
    //Other experiments
    //tr -= smoothstep(.5, tan(time), sin(time)*length(uv));
    //tr *= 1.- smoothstep(.1, sin(time), length(uv));
    float expFog = 0.5 / (tr*tr* 0.45); //fog
    vec3 fc = vec3(expFog); //instantiating fog
    
    glFragColor = vec4(cos(fc*cos(time)+color),sin(time)*1.2);
}
