#version 420

// original https://www.shadertoy.com/view/wstBD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.yy;
    float t = time;   
    
    float cSum = 0.0;
    for (float x = -1.; x < 1.0001; x++) {
        for (float y = -1.; y < 1.0001; y++) {
            vec2 gv = fract(uv * 4.);
            gv.x += x;
            gv.y += y;
            gv.x += 0.25*(sin(gv.y*8. + uv.y + t*3.));
              gv.y += 0.25*(sin(gv.x*9. + t*2.3));
            float d = length(gv - vec2(0.5, 0.5));
            
            cSum += smoothstep(0.5, 0.3, d);
        }
    }
    
    vec3 col = vec3(cSum);

    glFragColor = vec4(col, 1.0);
}
