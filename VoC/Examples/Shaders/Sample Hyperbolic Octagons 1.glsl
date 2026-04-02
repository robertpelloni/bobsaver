#version 420

// original https://www.shadertoy.com/view/3d2cz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define swap(x,y) {t=x;x=y;y=t;}

vec3 color(vec2 z) {
    float pi = 3.14159265359;
    float theta = pi/8.0;
    // someday I'll explain the cross-ratio magic that got me these numbers
    float r = 2.0 / (1.0 - sqrt(1.0 - 4.0 * sin(theta) * sin(theta)));
    float p = - r * cos(theta);
    bool fl = false;
    vec3[3] colors;
    colors[0] = vec3(1.0,0.0,0.0);
    colors[1] = vec3(0.0,1.0,0.0);
    colors[2] = vec3(0.0,0.0,1.0);
    vec3 t; // for temp space
    for(int i=0;i<100;i++) {
        if (z.x < 0.0) {
            z.x = -z.x;
            colors[2] = 1.0 - colors[2];
            fl = !fl;
            continue;
        }
        if (dot(z,z) < 1.0) {
            z /= dot(z,z);
            fl = !fl;
            swap(colors[0],colors[1]);
            continue;
        }
        z.x -= p;
        if (dot(z,z) > r*r) {
            z *= r * r / dot(z,z);
            fl = !fl;
            z.x += p;
            swap(colors[1],colors[2]);
            continue;
        }
        z.x += p;
        vec3 col = colors[0];
        if (fl) {
            col = 0.5 * col;
        }
    return col;
    }
    return vec3(1.0,1.0,1.0);
}

void main(void)
{
    vec2 uv = 2.0 * (gl_FragCoord.xy - resolution.xy * 0.5)/resolution.y;
    
    float r2 = dot(uv,uv);
    if (r2 < 1.0) {
        uv.y -= 1.0;
        uv /= dot(uv,uv);
        uv.y = -0.5 - uv.y;
        uv.x += 0.1 * time;
        glFragColor = vec4(color(uv),1.0);
    } else {
        glFragColor = vec4(0.0,0.0,0.0,1.0);
    }
}
