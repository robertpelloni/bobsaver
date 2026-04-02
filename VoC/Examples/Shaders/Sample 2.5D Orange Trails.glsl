#version 420

// original https://www.shadertoy.com/view/mssXz2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159
#define thc(a,b) tanh(a*cos(b))/tanh(a)
#define mlength(p) max(abs((p).x),abs((p).y))
#define rot(a) mat2(cos(a),-sin(a),sin(a),cos(a))

void main(void)
{
    vec2 res = resolution.xy;
    vec2 uv = (gl_FragCoord.xy - 0.5 * res) / res.y;
    vec2 ouv = uv;
    float t = time;
    vec3 s = vec3(0);
    float n = 45.;
    float k = 4. / res.y;
    vec2 p = 0.25 * vec2(cos(time), sin(time));
    for (float i = 0.; i < n; i++) {
        float io = 2. * pi * i / n;
        float a = atan(uv.y, uv.x);
        
        // uncomment these and comment other uv stuff, looks cool
        //uv *= 1. + 0.025 * cos(-5. * a + io + 1.5 * t);
        //uv *= rot(0.0025 * t * i / n + 0.04 * cos(-a-4. * log(length(uv)) + 0.25 * io + t));
        uv.x = (1. - i/n) * ouv.x + 0.05 * cos(0.5 * io + t);
        uv.y = (1. - i/n) * ouv.y + 0.05 * sin(0.5 * io + 0.75 * t);
        float sc = 10. + 0.2 * i;//exp(-0.1 * i);
        vec2 ipos = floor(sc * uv) + 0.5;
        vec2 fpos = fract(sc * uv) - 0.5;

        float th = 0.5 + 0.5 * thc(4., 10. * ipos.x - 4. * t + 4. * io);
        float th2 = 0.5 + 0.5 * thc(4., length(ipos) + 2. * t + 1.5 * io);

        float d  = length(fpos-p);
        float d2 = mlength(fpos-p);
        float r2 = (0.5 + 0.5 * cos(io + t)) * th2;
        float s2 = step(abs(d2 - 0.3 * r2), 0.02);
        s = max(s, exp(-3. * r2) * (1.-r2) * i* smoothstep(-k, k, -abs(d-r2) + 0.01) / n);
        
        float v = mix(10., 40., th);
        vec3 col2 = mix(vec3(0), vec3(1, 0.5,0.1), i/n);
        vec3 col3 = mix(vec3(0), vec3(0,1,1), i/n);
        s += .3*smoothstep(-k,k,-d+i/n * mix(0.12,0.05,th)) * col2;
        s = max(s, exp(-v * d) * pow(i / n, 2.) * col2);
        
       // s = max(s, exp(-v * abs(d2-r2)) * pow(i/n,2.) * col3);
       // s = max(s, r2 * s2 * pow(i/n,2.) * col3);
    }
    vec3 col = 0.05 + vec3(s);
    col *= 1./cosh(length(ouv));
    glFragColor = vec4(col,1.0);
}
