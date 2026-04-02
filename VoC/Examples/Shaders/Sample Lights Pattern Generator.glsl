#version 420

// original https://www.shadertoy.com/view/Xl3SzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//iq color palette
vec3 pal(float t, vec3 a, vec3 b, vec3 c, vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv*2.-1.;
    uv.x*=resolution.x/resolution.y;
    
    float e = time*.125;
    float d = 128.*mouse.x*resolution.x/resolution.x+8.5;
    
    float zoom = 16.;
    vec2 g = uv*zoom;
    uv = d*(floor(g)+.5)/zoom;
    g = fract(g)*2.-1.;
    
    float f = dot(uv,uv)-e;
    
    vec4 c = vec4(
        pal( f*.5 + e,
            vec3(0.5,0.5,0.5),
            vec3(0.5,0.5,0.5),
            vec3(1.0,1.0,1.0),
            vec3(0.0,0.10,0.20)),1.);
    
    glFragColor = c*(1.-dot(g,g))*.2/abs((fract(f)-.5)*8.);
}
