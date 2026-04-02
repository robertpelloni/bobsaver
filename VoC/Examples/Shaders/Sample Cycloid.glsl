#version 420

// original https://www.shadertoy.com/view/WtG3Ww

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float r = 0.5;
const float pi = 3.141592;

vec2 cycloid(float t) {
    return vec2( r*(t - sin(t)), r*(1.0 - cos(t)) );    
}

float disttoline(vec2 a, vec2 b, vec2 p) {
     return abs( (b.y-a.y)*p.x - (b.x-a.x)*p.y + b.x*a.y-a.x*b.y ) / sqrt( dot(b-a, b-a) ) 
        * (length(a-p) + length(b-p) - length(a-b) < 0.001 ? 1.0 : 3000.0);   
}

void main(void)
{
    vec2 uv = 2.0*pi*r * (2.0 * gl_FragCoord.xy - resolution.xy)/resolution.x + vec2(pi*r, 0.7);

    float dist = 10.0;
    float x = time * 3.0;
    float tpos = 4.0*pi*r*sin(x*0.25) + pi;// = mod( (x - 2.0*mod(x, 4.0*pi) * step(4.0*pi, mod(x, 8.0*pi))), 4.0*pi ) - pi;
    for(float t = -pi; t < tpos; t += 0.01) {
        vec2 point = cycloid(t);
        dist = min(dist, length(point - uv));
    }
    
    vec2 circle = vec2(r*tpos, r);
    vec2 finalpoint = cycloid(tpos);
    float linedist = disttoline( circle, finalpoint, uv );
    vec3 color = mix(vec3(0.0), mix( vec3(1.0), vec3(0.95, 0.96, 0.73), smoothstep(0.0, -0.01, length(uv-circle)-r) ), smoothstep(0.0, 0.01, abs(length(uv-circle)-r)));
    color = mix(color, vec3(1.0, 0.0, 0.0), smoothstep(0.01, 0.0, dist));
    color = mix(color, vec3(0.0), step(length(uv - finalpoint), 0.02));
    color = mix( color, mix( vec3(0.0), vec3(.8, .5, .51) + pow(0.5, 1.2+7.0*abs(circle.x-uv.x))*pow(0.5, 2.0*(-uv.y)), smoothstep(0.0, 0.01, abs(uv.y + 0.005)) ), step(uv.y, 0.00) );
    color = mix(color, vec3(0.0), smoothstep(0.01, 0.0, linedist));
    
    
    glFragColor = vec4(color, 1.0);
}
