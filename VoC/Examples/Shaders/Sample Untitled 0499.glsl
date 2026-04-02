#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 HSV2RGB(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    position-=0.5;
    float d = length(position)*1.9+sin(time*0.35);
    float koef = position.x + time*0.1;
    float vstep = sin(time*1.15+(position.x*(5.5*d))+position.y*4.0)*3.0 + koef * 20.0;
    float vfloor = floor(vstep);
    float vfract = fract(vstep);
    float top = clamp(vfract * 5. , 0., 1.);
    float color = vfloor * .1;//, -1.0, 1.0));
    
    glFragColor = vec4(HSV2RGB(vec3(color, 991.0, 1.0)) * (0.3 + top*.8), 1.0 );

}
