#version 420

// original https://www.shadertoy.com/view/WlsXzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.141592654;

vec3 hash32(vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}
vec4 disco(vec2 uv) {
    float v = abs(cos(uv.x * PI * 2.) + cos(uv.y *PI * 2.)) * .5;
    uv.x -= .5;
    vec3 cid2 = hash32(vec2(floor(uv.x - uv.y), floor(uv.x + uv.y)));
    return vec4(cid2, v);
}
float nsin(float t) {return sin(t)*.5+.5; }

void main(void)
{
    vec4 o = glFragColor;
    vec2 R = resolution.xy;
    vec2 uv = gl_FragCoord.xy / R - .5;
    uv.x *= R.x / R.y;

    float t = (time + 129.) * .6; //t = 0.;
    uv = uv.yx;
    uv *= 2.+sin(t)*.2;
    uv.x += t*.5;
    
    o = vec4(1);
    float sgn = -1.;
    for(float i = 1.; i <= 5.; ++i) {
        vec4 d = disco(uv);
        float curv = pow(d.a, .5-((1./i)*.3));
        curv = pow(curv, .8+(d.b * 2.));
        curv = smoothstep(nsin(t)*.3+.2,.8,curv);
        o += sgn * d * curv;
        o *= d.a;
        sgn = -sgn;
        uv += 100.;// move to a different cell
        uv += sin(d.ar*7.33+t*1.77)*(nsin(t*.7)*.1+.04);
    }
    
    // post
       o.gb *= vec2(1.,.5);//tint
    vec2 N = (gl_FragCoord.xy / R )- .5;
    o = clamp(o,.0,1.);
    o = pow(o, vec4(.2));
    o.rgb -= hash32(gl_FragCoord.xy + time).r*(1./255.);
    
    N = pow(abs(N), vec2(2.5));
    N *= 7.;
    o *= 1.5-length(N);// ving
    o = clamp(o,.0,1.);
    o.a = 1.;
    glFragColor = o;
}

