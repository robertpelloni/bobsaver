#version 420

// original https://www.shadertoy.com/view/XssSRX

uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy;
    vec2 q = p - vec2(0.33,0.7);
        
    vec3 col = mix( vec3(1.0,0.3,0.0), vec3(1.0,0.8,0.3), sqrt(p.y) );
    
    float r = 0.2 + 0.1*cos( atan(q.y,q.x)*10.0 + 20.0*q.x + 1.0);
    col *= smoothstep( r, r+0.01, length( q ) );

    r = 0.015;
    r += 0.002*sin(120.0*q.y);
    r += exp(-40.0*p.y);
    col *= 1.0 - (1.0-smoothstep(r,r+0.002, abs(q.x-0.25*sin(2.0*q.y))))*(1.0-smoothstep(0.0,0.1,q.y));
    
    glFragColor = vec4(col,1.0);
}
