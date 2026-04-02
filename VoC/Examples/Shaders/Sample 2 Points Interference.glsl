#version 420

// original https://www.shadertoy.com/view/3dfSDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 u_canvas = resolution.xy;
    float u_time = time;
    
    float aspect = u_canvas.x/u_canvas.y;
    vec2 uv = gl_FragCoord.xy / u_canvas.xy;
    uv = uv - 0.5;
    uv.x *= aspect;
    uv *= 0.2;

    float bright = 0.7;
    float z = 0.01;

    vec3 p = vec3(uv, z);

    vec3 p1 = vec3(  0.1,  0., 0. );
    vec3 p2 = vec3( -0.1,  0., 0. );

    float time1 = mod(u_time, 10.);
    //-0.2...+0.2 за 10 секунд
    p1.x = 0.20 - time1 * 0.40/10.;    
    p2.x = -0.20 + time1 * 0.40/10.;    

    float time2 = mod(u_time, 60.);
    if (time2<10.) {
        p1.y = 0.;
        p1.z = 0.01;
        p2.y = 0.;
        p2.z = 0.01;
    } else if (time2<20.) {
        p1.y = 0.01;
        p1.z = 0.01;
        p2.y = -0.01;
        p2.z = 0.01;
    } else if (time2<30.) {
        p1.y = 0.03;
        p1.z = 0.01;
        p2.y = -0.03;
        p2.z = 0.01;
    } else if (time2<40.) {
        p1.y = 0.03;
        p1.z = 0.05;
        p2.y = -0.03;
        p2.z = 0.05;
    } else if (time2<50.) {
        p1.y = 0.01;
        p1.z = 0.05;
        p2.y = -0.01;
        p2.z = 0.05;
    } else if (time2<60.) {
        p1.y = 0.;
        p1.z = 0.05;
        p2.y = 0.;
        p2.z = 0.05;
    }

    float r1 = length(p - p1) * u_canvas.x;
    float r2 = length(p - p2) * u_canvas.x;

    vec3 a = vec3(1.0, 1.5, 2.0);
    vec3 re = cos(r1 * a) / r1 + cos(r2 * a)/r2;
    vec3 im = sin(r1 * a) / r1 + sin(r2 * a)/r2;
    vec3 color = bright * (re*re + im*im) * u_canvas.x;

    glFragColor = vec4(color, 1.0);

}
