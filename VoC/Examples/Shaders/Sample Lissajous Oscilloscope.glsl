#version 420

// original https://www.shadertoy.com/view/Wd3GD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec2 p, float r, float t) {
    return distance(0.4*vec2(cos(3.0*t), sin(2.0*t)), p) - r;
}

void main(void)
{
    int l = 500;
   
    vec2 uv = (gl_FragCoord.xy-resolution.xy*.5)/resolution.y;

    vec3 col = vec3(smoothstep(-0.1,0.1, -map(uv, 0.03, time)));
    
    // Would there be a better way to do this? :D
    for(int i=0; i<l; i++) { 
        col = max(col,
                 vec3(
                     smoothstep(-0.005, 0.005, -map(uv, 0.02*float(l-i)/float(l), time-float(i)*0.005)))
                     *pow(float(l-i), 0.8)/float(l));
    }
    
    col *= vec3(1.0, 2.0, 1.0);

    col += vec3((1.0-step(0.002, abs(mod(uv.y, 0.1))))*(1.0-step(0.02, abs(uv.x))));
    col += vec3((1.0-step(0.002, abs(mod(uv.x, 0.1))))*(1.0-step(0.02, abs(uv.y))));
    col += vec3((1.0-step(0.002, abs(uv.y))));
    col += vec3((1.0-step(0.002, abs(uv.x))));

    glFragColor = vec4(col,1.0);
}
