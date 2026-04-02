#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rnd(vec2 uv)
{
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 0.5 + 0.5);
}

void main( void ) {

    vec2 uv = ( gl_FragCoord.xy / resolution.xy );
    uv.x *= resolution.x/resolution.y;
    
    uv.y += sin(time+uv.x*0.3)*0.1;
    uv.x += cos(time+uv.y*0.3)*0.1;
    float d = length(uv*0.85);
    d = (0.5+(sin(2.*time+uv.x*uv.y)*0.2))/(d);
    
    vec2 ouv = uv;
    
    const float c = 20.0;
    uv = mod(uv * c, 1.0) * 2.0 - 1.0;
    
    float t = 1.0-smoothstep(0.5, 1.0, length(uv));
    float s = fract(rnd(floor(ouv * c)) + time * 0.3);
    t = mix( 0.0, t-0.2, s);
    vec3 fc = vec3(t* 2.1, d*t * 3.5, t * 1.2);

    glFragColor = vec4( fc, 1.0 );

}
