#version 420

// original https://www.shadertoy.com/view/wsjBzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 hash22(vec2 p)
{
    p = vec2( dot(p,vec2(127.1,311.7)),
              dot(p,vec2(269.5,183.3)));
  
    return -1.0 + 2.0 * fract(sin(p)*43758.5453123);
}

float perlin_noise(vec2 p)
{
    vec2 pi = floor(p);
    vec2 pf = p-pi;
    
    vec2 w = pf*pf*(3.-2.*pf);
    
    float f00 = dot(hash22(pi+vec2(.0,.0)),pf-vec2(.0,.0));
    float f01 = dot(hash22(pi+vec2(.0,1.)),pf-vec2(.0,1.));
    float f10 = dot(hash22(pi+vec2(1.0,0.)),pf-vec2(1.0,0.));
    float f11 = dot(hash22(pi+vec2(1.0,1.)),pf-vec2(1.0,1.));
    
    float xm1 = mix(f00,f10,w.x);
    float xm2 = mix(f01,f11,w.x);
    
    return mix(xm1,xm2,w.y);
}

// Official HSV to RGB conversion 
vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );

    return c.z * mix( vec3(1.0), rgb, c.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 uv2 = uv + perlin_noise(1.2 * vec2(uv.x + 38.913 + time * 0.04, uv.y + 81.975 + time * 0.04));
    uv2 = uv2 + vec2(time * 0.01, 0.0);

    // Time varying pixel color
    float f = perlin_noise(2.0 * uv2);

    // Output to screen
    f = (f + time * .01) * 8.0;
    f = f - floor(f);
    float f2 = 0.02;
    f2 = f2 + 0.08 * smoothstep(0.08, 0.12,f);
    f2 = f2 + 0.08 * smoothstep(0.21, 0.25, f);
    f2 = f2 + 0.06 * smoothstep(0.33, 0.37, f);
    f2 = f2 + 0.23 * smoothstep(0.46, 0.50, f);
    f2 = f2 + 0.08 * smoothstep(0.58, 0.62, f);
    f2 = f2 + 0.12 * smoothstep(0.71, 0.75, f);
    f2 = f2 + 0.12 * smoothstep(0.83, 0.87, f);
    f2 = f2 + 0.23 * smoothstep(0.96, 1.00, f);
    vec3 col2 = hsv2rgb(vec3(f2, 1.0, 1.0));
    
    glFragColor = vec4(col2.rgb, 1.0);
}
