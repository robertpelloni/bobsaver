#version 420

// original https://www.shadertoy.com/view/fsjGRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float speed = -10.0;
float frequency = 20.0;

void spin(inout vec2 pos){
    float angle = time - atan(length(pos)) * 3.0;
    pos.xy = vec2( 
        pos.x * cos(angle) - pos.y * sin(angle),
        pos.y * cos(angle) + pos.x * sin(angle)
        );
}

void main(void)
{

    float t = time * speed;
    vec2 position = (gl_FragCoord.xy - resolution.xy * .5) / resolution.x;
    
    spin(position);
    
    float angle = atan(position.y, position.x) / (2. * 3.14159265359);
    angle -= floor(angle);
    float rad = length(position);
    float angleFract = fract(angle * 256.);
    float angleRnd = floor(angle * 256.) + 1.;
    float angleRnd1 = fract(angleRnd * fract(angleRnd * .7235) * 45.1);
    float angleRnd2 = fract(angleRnd * fract(angleRnd * .82657) * 13.724);
    float t2 = t + angleRnd1 * frequency;
    float radDist = sqrt(angleRnd2);
    float adist = radDist / rad * .1;
    float dist = (t2 * .1 + adist);
    dist = abs(fract(dist) - 0.5);
    
    float outputColor = (1.0 / (dist)) * cos(0.7 * sin(t)) * adist / radDist / 30.0;
    angle = fract(angle + .61);
    
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    glFragColor = vec4(outputColor * col,1.0);
}
