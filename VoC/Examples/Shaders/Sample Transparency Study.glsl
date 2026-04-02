#version 420

// original https://www.shadertoy.com/view/ssj3zD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://www.shadertoy.com/view/4djSRW
vec2 hash21(float p){
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx+p3.yz)*p3.zy);
}
float circle(vec2 uv, float r){
return smoothstep(r,r-0.04*hash21(r).x,length(uv));
}

void main(void)
{
    float t = time+10.0;
    vec2 R = resolution.xy;
    vec2 uv = (gl_FragCoord.xy-.5*R.xy)/R.y;
    vec3 col = vec3(0.0);
    
    for(int i = 0; i<150; i++){
        float fi = float(i); 
        vec3 c= vec3(hash21(fi*0.3123+floor(t)),hash21(fi*0.3344+floor(t)).x);
        vec2 pos = +vec2(sin(hash21(fi).x*t),cos(hash21(fi).y*t));
        c*=vec3(circle(uv+pos,0.1+0.0002*fi+0.1*hash21(fi).x))*(hash21(fi).x*0.7);
        col.rgb+=c;
    }
    col+=0.25*(1.0-smoothstep(0.1,0.102,-(abs(uv.y)-0.3-0.2*sin(t)*sin(t))+0.02*sin(uv.x*20.0+t*10.0)));
    glFragColor = vec4(col,0.0);
}
