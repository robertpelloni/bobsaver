#version 420

// original https://www.shadertoy.com/view/Wsc3Wn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* it basically works by making scaled copies of a repeating pattern,
 * summing those copies together, and then using a pallete to turn the sum
 * into a color.
 */

#define SIZE 5.
#define STRIDE 5
const float pattern[] = float[](
    2.,1. , 0.,1. , 2.,
    1.,1.5, 1.,1.5, 1.,
    0.,1. ,-2.,1. , 0.,
    1.,1.5, 1.,1.5, 1.,
    2.,1. , 0.,1. , 2.
);

/*
#define SIZE 3.
#define STRIDE 3
const float pattern[] = float[](
    -1., 0.,-1.,
     0., 1., 0.,
    -1., 0.,-1.
);
*/

mat2 rotmat(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

void main(void)
{
    float zoom = exp(sin(time * 1.5) * .7);
    
    vec2 pos = (gl_FragCoord.xy*2. - resolution.xy) / resolution.y;
    pos *= rotmat(time * .5);
    pos *= zoom;
    pos += vec2(1., 1.5) * time;
    {
        float tmp = pow(3., SIZE);
        pos /= tmp; zoom /= tmp;
    }
    
    float detail = (log(resolution.y / zoom)) / log(SIZE) - 1.3;
    
    float sum = detail * -1.;
    for(int i = 0; i < 16; i++) {
        pos = fract(pos);
        pos *= SIZE;
        if(i >= int(detail)) break;
        sum += pattern[int(pos.x) + int(pos.y) * STRIDE];
    };
    sum += pattern[int(pos.x) + int(pos.y) * STRIDE] * fract(detail);
    
    glFragColor = sin(sum + vec3(0.,.5,1.) + time * 3.).xyzz * .5 + .5;
}
