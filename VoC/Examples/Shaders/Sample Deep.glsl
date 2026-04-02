#version 420

// original https://www.shadertoy.com/view/lsXfRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define DEPTH_STEP 64

float map(vec3 p){
    float a = p.z*0.1001;
    p.xy *= mat2(cos(a), sin(a), -sin(a), cos(a));
    float t = length(mod(p.xy, 2.0) - 1.0) - 0.07 - sin(p.z)*0.1;
    t = min(t,length(mod(p.yz, 2.0) - 1.0) - 0.07 - sin(p.x)*0.1);
    t = min(t,length(mod(p.zx, 2.0) - 1.0) - 0.07 - sin(p.y)*0.1);
    return t;
}

void main(void) {
    float j = 0.;
    float depth = 1.;
    float d = 0.;
    for(int i=0;i<64;i++){
        depth += (d = map(vec3(0.,0.,time*3) + normalize(vec3((gl_FragCoord.xy+gl_FragCoord.xy-R)/R.y,2.)) * depth));
        j = float(i);
        if(d<0.01)
            break;
    }
    depth = 1.-j/float(DEPTH_STEP);
    float coeff = pow(depth,2.2)*3.;
    float c1 = clamp(coeff,0.,1.);
    float c2 = clamp(coeff,1.,2.)-1.;   
    float c3 = clamp(coeff,2.,3.)-2.;
    vec3 col = vec3(c1,c2,c3);
    glFragColor = vec4(col,0.);
}

