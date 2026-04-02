#version 420

// original https://www.shadertoy.com/view/wlSSRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float h=0.5;
const float j=0.5;
const float F=5.0;
const float G=5.0;

void main(void)

{
    float f = F;
    float g = G;
    
    vec2 res = resolution.xy;
    vec2 mou = vec2(0., 0.);
    
    mou.x = sin((time*0.2) * .3) * sin((time*0.2) * .15) * 2. + sin((time*0.2) * .3);
    mou.y = (1.0-sin((time*0.2) * .3 * 2.) )* sin((time*0.2) * .15) + cos((time*0.2) * .3);
    mou *= res;

    vec2 z = ( (-res+2.0 * gl_FragCoord.xy) / res.y);
    vec2 p = ( (-res+2.0 + mou) / res.y) * j ;
    
    for( int i = 0; i < 30; i++) {
        
        float d = dot(z, z) + 0.0 * dot(p*0.1,z*0.1);
        z = (vec2( z.x, -z.y ) / d) + p * (h)/(j); 
        z.x = 1.0- abs(z.x);
        f = max( d-f, tan(dot(z-p,z-p) ));
        g = min( g*d, sin(dot(z+p,z+p))+1.0);
    }
    
    f = abs(-log(f) / 3.5);
    g = abs(+log(g) / 3.5 );
    
    vec3 col =  vec3(g*j, g*f, f*j);
    glFragColor = vec4( min( col, 1.0), 1.0);
}
