#version 420

// original https://www.shadertoy.com/view/lssXWX

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 nrand3( vec2 co )
{
    vec3 a = fract( cos( co.x*8.3e-3 + co.y )*vec3(1.3e5, 4.7e5, 2.9e5) );
    vec3 b = fract( sin( co.x*0.3e-3 + co.y )*vec3(8.1e5, 1.0e5, 0.1e5) );
    vec3 c = mix(a, b, 0.5);
    return c;
}

void main(void)
{
    vec2 ruv = gl_FragCoord.xy / resolution.xy;
    
    
    //Simplicity Galaxy's starfield + scrolling code
    vec2 uv = 2. * gl_FragCoord.xy / resolution.xy - 1.;
    vec2 uvs = uv * resolution.xy / max(resolution.x, resolution.y);
    vec3 p = vec3(uvs / 4., 0) + vec3(1., -1.3, 0.);
    p += .15 * vec3(sin(time / 16.), sin(time / 12.),  sin(time / 128.));
    
    vec3 col = vec3(0.);
    
    vec2 seed = (p.xy * 2.0);    
    seed = floor(seed * resolution.x);
    vec3 rnd = nrand3( seed );
    col += vec3(pow(rnd.y,30.0));
    
    float rps0 = .5+sin(time)*.3;
    float rps1 = .5+cos(time)*.3;
    float rps2 = .5+sin(3.14159+time)*.3;
    rps0 = abs(ruv.y-rps0);
    rps1 = abs(ruv.y-rps1);
    rps2 = abs(ruv.y-rps2);
    if(rps0 < .08) col = vec3(1., .5, 0.)*pow(1.-(rps0/.08), .5);
    if(rps1 < .08) col = vec3(0., .5, 1.)*pow(1.-(rps1/.08), .5);
    if(rps2 < .08) col = vec3(0.5, 0., 1.)*pow(1.-(rps2/.08), .5);
    glFragColor = vec4(col,1.0);
}
