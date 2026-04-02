#version 420

// original https://www.shadertoy.com/view/3d2yzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float MAX = 200.;
const vec2 P = vec2(0.001, 0.0);

vec2 mul(vec2 z, vec2 w) { return vec2 (z.x*w.x - z.y*w.y, z.x*w.y + z.y*w.x); }

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float J(vec2 z, vec2 c, vec2 p)
{
    float i;
    for(i = MAX; i --> 0.;)
    {
        float lz = dot(z, z);
        if (lz > 4.0) {
            return (i + log2(log2(lz))) / MAX;
            //return 1.0-pow(float(i) / MAX, 15.);
        }

        vec2 z2 = vec2(z.x*z.x - z.y*z.y, 2. * z.x * z.y);
        vec2 rz2 = vec2(z2.x, -z2.y) / dot(z2, z2);
        
        z = z2 + c - mul(p, rz2);
    }
    
    return 1.0;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    uv *= 2.;
    
    vec2 m = mouse*resolution.xy.xy/resolution.xy - 0.5;
    
    vec2 c = vec2(-1.0, 0.0) / 100.0;

    // Time varying pixel color
    float val = J(uv, c, m /2.);
    val = pow(val,3.);
    vec3 col =  pal( val * 1.5, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.10,0.20) );

    // Output to screen
    glFragColor = vec4(col,1.0);
}
