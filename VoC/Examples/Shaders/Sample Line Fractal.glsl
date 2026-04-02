#version 420

// original https://www.shadertoy.com/view/NtX3zl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time*0.5

mat2 r2d(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));
}

float line(vec2 uvu, float l, float w) {
    return smoothstep(w, 0.,abs(uvu.x-0.5)-0.005)*smoothstep(0.001,0.,abs(uvu.y-0.5)-l);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 R = resolution.xy;
    float ar = R.x/R.y;
    uv -= 0.5;
    uv.x *= ar;
    uv += 0.5;
    //
    // Time varying pixel color
    vec3 col = vec3(0.);
    //col.r += smoothstep(0.01,0.,abs(uv.x-0.5));
    //col.r *= smoothstep(0.01,0.,abs(uv.y-0.5)-0.4);
    uv -= 0.5;
    float c = length(uv);
    float cc = c;
    //uv.y -= 0.5;
    //uv = abs(uv)-(sin(time*0.5)*0.5+0.5)*0.5;
    //uv = abs(uv);
    //uv = fract(uv);
    //uv.x += 0.5;
    //c = fract(c);
    //uv.x += time;
    uv = vec2(log(c),atan(uv.x,uv.y));
    //uv.x *= 0.1;
    //uv.x *= 0.5;
    //uv.x /= c;
    uv.x -= sin(c+time*0.25);
    //uv.x -= sin(uv.y*4.+time);
    uv.x *= 0.5;
    //uv.x *= 2.;
    uv.x -= time;
    //uv.x *= 0.5;
    uv.x += 1.;
    //uv = abs(uv)-0.5;
    //uv *= r2d(time*0.1);
    //uv.x  = abs(uv.x);
    //uv.y *= 4./3.14;
    float vt = uv.x;
    //vt = c*20.;
    //float sy = float(int(fract(uv.x*0.05)*4.+0.9));
    float sy = floor(fract(uv.x*0.05)*4.+0.9);
    //uv.x -= sin(uv.y+time)*0.2;
    //sy = floor(fract(uv.x)*4.);
    //uv.x /= 8.-sy;
    //uv.x *= .0000001;
    //uv *= 0.25;
    uv.y *= sy/3.14;
    vt += time*0.025;
    float ux = uv.x;
    //vt += time+uv.y*0.1;
    //uv.y *= 4./3.14;
   // vt *= c*0.001;
    //uv.x -= time;
    //float vt = uv.x;
    uv = fract(uv)-0.5;
    c = length(uv);
    //uv = vec2(log(c),atan(uv.x,uv.y))*0.1;
    //uv.x += time;
    //uv.y *= 2.;
    //uv.x += 1.5;
    //uv.x += 0.5;
    int steps = 8;
    //float c = length(uv);
    //uv -= 0.5;
    //uv = abs(uv+0.5)-0.5;
    //uv += 0.5;
    int s2 = 6;
    s2 = int(mod(ux*1.,18.));
    for (int i=0;i<s2;i++) {
        uv = abs(uv)-(sin(vt*0.5)*0.5+0.5)*0.5;
        uv *= r2d(float(i)+vt);
    }
    //uv -= 0.5;
    //uv += 0.5;
    //float c = length(uv);
    uv *= r2d(sin(c*8.*sin(vt*0.5)+vt*0.5));
    for (int i=0;i<steps;i++) {
        uv *= r2d(-vt*0.1);
        col.r += line(uv+0.5,0.4,(sin(uv.x*04.91)*0.5+0.5)*0.01)*21.;
    }
    
    //col.r -= 4.5;
    //col.r = fract(col.r*0.01+time*0.1);
    //col.r *= 0.01;
    //col.r = sin(col.r+time*0.1);
    col.bg = col.rr;
    col.r *= 0.05;
    col.r += ux*0.2;
    //col.r -= time*4.;
    col = vec3(sin(col.r),cos(col.r+0.2),cos(-col.r))*0.8;
    //col = sin(col+uv.x);
    // Output to screen
    glFragColor = vec4(col,1.0);
}
