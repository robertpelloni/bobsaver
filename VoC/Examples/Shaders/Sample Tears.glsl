#version 420

// original https://www.shadertoy.com/view/WdjcDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.344532, 4321.3432))) * 321321.6);
}

void main(void)
{
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.xx;
    
    
    vec3 col = vec3(0.);
    
    for(int j=-1; j<=1; j++) {
        vec2 q = p;
        q = mod(q*6., 1.)-0.5;
        q.y -= float(j);

        vec2 id = floor(p*6.);

        q /= 0.5;
        q.y -= mod(-time*(0.5+rand(id.xx)*3.), 2.);
        q.y = q.y > 0. ? q.y/(2.0*exp(-abs(q.x))) : q.y;
        float d = smoothstep(0.1, 0.0, length(q)-0.3);

        col += d*vec3(0.6, 0.6, 1.0*(0.5+q.x) + (0.5-q.y));
    }
    
    glFragColor = vec4(col,1.0);
 }
