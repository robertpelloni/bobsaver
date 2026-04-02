#version 420

// original https://www.shadertoy.com/view/wlB3Rd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float SinLerp(float min, float max, float t) {
     return mix(min, max, sin(t) * 0.5 + 0.5);   
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    
    //uv = abs(uv);
    
    float x = uv.x;
    float y = uv.y;
    
    float pi2 = 3.14*2.;
    float t = time * 5.;
    
    vec3 col = vec3(uv.x, uv.y, 0);
    
    
    float d = sqrt(x*x+y*y);
    float rad = atan(y/x) / 3.14;
    
    float wave = sin(t + rad*55.)*.05;// SinLerp(0., .2, t);
    d += SinLerp(.0, wave + d*.1, rad * pi2 * 5.);
    float d2 = SinLerp(0., 1., d*pi2*5. + t + y);
    float rad2 = sin(rad*pi2* SinLerp(5., 10., (t + rad*15. + sin(rad*pi2*15.))*0.3) );
    //rad2 = smoothstep(.2, .6, rad2);    
    
    rad2 = rad2;
    
    col = vec3(rad);
    col = vec3(d2*.5 + rad2*.5);
    col = vec3(smoothstep(.5, .5+1.5*20./resolution.y, d2));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
