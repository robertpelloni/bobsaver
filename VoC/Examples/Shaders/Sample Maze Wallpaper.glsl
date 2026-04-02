#version 420

// original https://www.shadertoy.com/view/4td3D7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 si = resolution.xy;
    
    vec2 h = (gl_FragCoord.xy+gl_FragCoord.xy-si.xy)/si.y * 0.75;
    
    vec2 Coord=gl_FragCoord.xy;    

    Coord /= 18.;
    
    float r = cos(h.x)*cos(h.y)*.6;
    
    vec4 col = vec4(.34,1,1,1)/25.;
    
    float hash = sin( 64654.2 * sin(1e3 * length(floor(Coord))));
    
    float branch = Coord.y + Coord.x * sign(  hash );
    
    float rep = cos(3.14 * branch);
    
    glFragColor = r - col / rep;
}

