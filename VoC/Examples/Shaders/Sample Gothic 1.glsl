#version 420

// original https://www.shadertoy.com/view/cslfDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdHexagon( in vec2 p, in float r )
{
    const vec3 k = vec3(-0.866025404,0.5,0.577350269);
    p = abs(p);
    p -= 2.0*min(dot(k.xy,p),0.0)*k.xy;
    p -= vec2(clamp(p.x, -k.z*r, k.z*r), r);
    return length(p)*sign(p.y);
}

vec3 palette( float t){
    vec3 a = vec3(-0.342, -0.342, 0.000);
    vec3 b = vec3(1.258, 1.348, 1.078);
    vec3 c = vec3(1.000, 1.000, 1.000);
    vec3 d = vec3(2.558, 2.338, 2.488);
    return a + b*cos( 6.28318*(c*t+d) );
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec2 uv0 = uv;
    vec3 finalColor = vec3(0.0);
    
    for (float i = 0.0; i < 10.0; i++){
        //uv = fract(uv * (sin(i/time))) - 0.5;
        uv = fract(uv * 1.5) - 0.5;

        float d = length(uv) * exp(-length(uv0));
        float d0 = length(uv0);

        d = sdHexagon(uv,d0/1.8);
        vec3 col = palette(d0 + time*(i/3.3));
        d = sin(d*10.0+(time/2.0))/10.0;

        //d = abs(d);
        d = 0.02 / d;

        finalColor += d;
    }
    //d= smoothstep(0.0,0.03,d);
    // Output to screen
    glFragColor = vec4(finalColor,1.0);
}
