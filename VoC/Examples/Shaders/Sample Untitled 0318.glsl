#version 420

#define PI 3.14159265359

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main( void ) {

    vec2 uv = ( gl_FragCoord.xy / resolution.x) - vec2(.25,.25);    
    float zz = uv.x;
    vec2 uvb = uv;
    uv.y = abs(uv.y);
    
    uv.y += 0.005 * (1.0 + cos(time * 3.2));
    uv.y = max(0.3* 0.2, uv.y);
    uv.x /= uv.y;
    
    
    uv.x += time;
    
    
    float color = mod(floor(uv.x) + floor(uv.y * 2.0), 2.0)+0.5;
    color =  1.0-clamp((sin(uv.x * PI )) *10. *(1.-abs(zz))  + .5, 0., 1.);
    vec3 col = mix(vec3(0.7,0.7,0.2), vec3(0.1,0.6,0.9),color)*1.8;
    float dist = sqrt(uv.y) * 1.0;
    col *=  max(0.1, min(1.0, dist *dist* 3.9));
    
    glFragColor = vec4( col,1.0 );

}
