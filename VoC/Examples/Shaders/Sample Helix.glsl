#version 420

// original https://www.shadertoy.com/view/WtXGz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float nearint(float x){
    return abs(x-round(x));
}

float f0(in vec2 p){
    return atan(p.y, p.x) / 6.2832;
}

vec2 f(in vec2 p){
    const float pi=3.1416;
    const float w=pi/2.;
    float t=time*0.1;
    
    float trim=-1e9;
    float val=0.0;
    for(int i=0;i<4;i++){
        vec2 pole = vec2(cos(t+w*float(i)),sin(3.*(t+w*float(i)))); 
        float wt = (i%2==0?1.:-1.);
        val += f0(p-pole)*wt;
        trim = max(trim, 0.2-length(p-pole));
    }
    return vec2(val, trim);
}

float dist(in vec3 p){
    vec2 vt = f(p.xz);
    float a = vt.x-p.y;
    float trim = vt.y;
    trim = max(trim, length(p.xz)-2.0);    
    
    float dist = abs(a-round(a))-0.02;
    return max(trim, dist)*0.5;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy - resolution.xy) / resolution.y;

    vec3 pos = vec3(0.0, 0.5, 6.0);
    vec3 eye = vec3(0.0, 0.0, -1.0);
    vec3 up = vec3(0.0, 1.0, 0.0);
    eye=normalize(eye);
    up=normalize(up);
    vec3 right = cross(up, eye);
    float angle = 0.4;
    
    vec3 ray = eye + (uv.x * right + uv.y * up) * angle;
    ray = normalize(ray);
    
    float depth = 0.;
    for(int i=0;i<200;i++){
        float d=dist(pos);
        if(d<1e-3){
            float col=1.0-float(i)/200.;
            float eps=1e-3;
            vec3 u=vec3(
                dist(pos+vec3(eps,0.0,0.0))-dist(pos-vec3(eps,0.0,0.0)),
                dist(pos+vec3(0.0,eps,0.0))-dist(pos-vec3(0.0,eps,0.0)),
                dist(pos+vec3(0.0,0.0,eps))-dist(pos-vec3(0.0,0.0,eps))
            );
            u=normalize(u);
            col *= 0.5+0.5*max(0.0, dot(u,-ray));
            glFragColor = vec4(vec3(col), 1.0);
            return;
        }
        depth += d;
        pos += d * ray;
        if(depth>1e2){
            glFragColor=vec4(vec3(0.0), 1.0);
            return;
        }
    }
}
