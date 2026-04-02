#version 420

// original https://www.shadertoy.com/view/WlXGWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotation(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c,s,-s,c);
}

float torus(in vec3 p, in vec2 t) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float cylinder(in vec3 p, float radius) {
    return length(p.xz) - radius;
}

float map(vec3 pos) {
    pos.xy *= rotation(pos.z*.2 + sin(pos.z*10.+time*5.)*.05);
    pos.z += time * .9;
    
    float size = 2.;
    pos = mod(pos,size)-size/2.;
    
    float radius = .5;
    float geometry = torus(pos,vec2(1.,.1*abs(sin(time*0.7))+.5));
    geometry = min(geometry,cylinder(pos.yzx,.05));
    return geometry;
}

void main(void)
{
    vec2 pos = gl_FragCoord.xy/resolution.xy;
    pos = pos * 2. - 1.;
    pos.x *= resolution.x/resolution.y;

    vec3 eye = vec3(0.,0.,-2.);
    vec3 ray = normalize(vec3(pos,1.));
    float shade = 0.;
    for(int i=0; i<20; ++i) {
        float dist = map(eye);
        if (dist < 0.001) {
            shade = 1.-float(i)/20.;
            break;
        }
        eye+=ray*dist;
    }
    
    
    glFragColor = vec4(sin(eye.z)*shade,shade,.5,1.);
}
