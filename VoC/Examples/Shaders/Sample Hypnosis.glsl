#version 420

// original https://www.shadertoy.com/view/wtlyRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = acos(-1.);

float xor(float a, float b) { return a*(1.-b) + b*(1.-a); }

mat2 rot(float a){
    float c=cos(a);float s=sin(a);
    return mat2(c,-s,s,c);
}

float V(vec2 uv, float t) {
    
    
    
       uv *= rot(pi/4.);
    

    uv *= 5.;
    uv += .5;
    
    vec2 gv = fract(uv)-.5;
    vec2 id = floor(uv);
    
    
    float s = 0.;
    
    
    for(float x=-2.;x<3.;++x) {
        for(float y=-2.;y<3.;++y) {
            vec2 o = vec2(x, y);
            
            float d = length(id+o)*mix(.2, .7, sin(3.3*t+pi/4.)*.5+.5);
            
            float r = mix(.95, 2.5, sin(d-t)*.5+.5);
            
            float c = smoothstep(r, r*.985, length(gv-o));
            s = xor(s, c);
        }
    }
    
    return s;
}

void main(void)
{

    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    float t = time*.3 + 70.;
      
    
    vec3 col = vec3(0);
    
    for(int i=0;i<3;++i) {
        col[i] = V(uv, t + float(i)*0.015);    
    }
    
    
    col = pow(col, vec3(1./2.2));
   

    glFragColor = vec4(col,1.0);
}
