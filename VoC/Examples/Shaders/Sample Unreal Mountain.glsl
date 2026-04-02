#version 420

// original https://www.shadertoy.com/view/MtVfzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//creator: ldm0
//Personal website: ldm0.xyz
void main(void)
{
    float m;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv.x *= 2.;
    uv.x -= 1.;
    //uv.y *= 1.382;
    uv.y += .382;
    for (int i = 0; i < 33; ++i) {
        uv= abs(uv);
        m = uv.x * uv.x  + uv.y * uv.y;// - .0031;
        uv.x = uv.x/m - .217;
        uv.y = uv.y/m - .105;
    }
    glFragColor = vec4(vec3(m + .28), 1.);
}
