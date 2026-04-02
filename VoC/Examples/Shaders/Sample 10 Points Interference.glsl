#version 420

// original https://www.shadertoy.com/view/3slXWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = radians(180.);

vec3 rotate(vec3 v, vec3 rad) {
    vec3 c = cos(rad), s = sin(rad);
    if (rad.x!=0.) v = vec3(v.x, c.x * v.y + s.x * v.z, -s.x * v.y + c.x * v.z);
    if (rad.y!=0.) v = vec3(c.y * v.x - s.y * v.z, v.y, s.y * v.x + c.y * v.z);
    if (rad.z!=0.) v = vec3(c.z * v.x + s.z * v.y, -s.z * v.x + c.z * v.y, v.z);
    return v;
}

void main(void) {
    float u_time = time;
    vec2 u_canvas = resolution.xy;
    vec2 u_mouse = mouse*resolution.xy.xy;
    
    float aspect = u_canvas.x/u_canvas.y;
    vec2 uv = gl_FragCoord.xy / u_canvas.xy;
    uv = uv - 0.5;
    //uv *= 0.2;
    uv.x *= aspect;

    float bright = 0.5;

    float z = 0.001;
    //if (u_mouse.y!=0.) z = 0.001 + u_mouse.y *0.0001;

    vec3 rd = vec3(uv, z);

    const int count = 10;

    vec3 p[count];
    float r;
    vec3 a = vec3(1.0, 1.5, 2.0);
    vec3 re = vec3(0);
    vec3 im = vec3(0);
    for (int i=0; i<count; i++) {
        p[i] = vec3(  0.05 ,  0., 0.0 );
        p[i].x *= aspect;
        p[i] = rotate(p[i], vec3(0,0,1)*(u_time*0.05*float(i)));
        r = length(rd - p[i]) * u_canvas.x;
        re += cos(r * a) / r;
        im += sin(r * a) / r;
    }
    vec3 color = bright * (re*re + im*im) * u_canvas.x;

    glFragColor = vec4(color, 1.);
}
