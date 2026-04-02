#version 420

// original https://www.shadertoy.com/view/lsjcWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float middle(vec3 p) {
    return   p.x<min(p.y,p.z) ? p.y<p.z ? p.y : p.z
           : p.x>max(p.y,p.z) ? p.y>p.z ? p.y : p.z
           : p.x;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    
    vec3 pos = vec3(3.0,3.0,time);
    
    vec3 dir = normalize(vec3(uv,1.0));
    vec3 signdir = sign(dir);
    float stepsize = 1.0;
    float dist = 0.0;
    float len;
    vec3 num;
    for (int i = 0; i < 6; i++) {
        vec3 pos2 = mod(pos,6.0*stepsize)-3.0*stepsize;
        num = stepsize-(pos2)*signdir;
        num *= step(abs(pos2),vec3(stepsize));
        num/=dir*signdir;
        len = max(0.0,middle(num));
        
        if (len < 0.01) stepsize /= 3.0;        //branch
        //stepsize /= 1.0+step(len,0.001)*2.0;  //no branch
        
        pos += dir*len;
        dist += len;
        
    }
    
    glFragColor = vec4((sin(pos*3.0)*0.5+0.5)/(dist+1.0)*2.0,1.0);
}
