#version 420

// original https://www.shadertoy.com/view/3dKBWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Hexagon Tiles Saw Blades Pattern
// https://www.shadertoy.com/view/4dX3zl

/*
 * Originally made in Blender nodes for a #nodegolf challenge:
 * https://twitter.com/GelamiSalami/status/1335114160535871490
 *
 * Not really hexagonal tiling, but triangle tiling made to look like a hexagonal one
 * Try fiddling with the constants, really makes some cool patterns :D
 */

// Thanks FabriceNeyret2!
#define S(v) smoothstep(1.5*scale/resolution.y, 0., v)    

#define pi acos(-1.)
#define tau (2.*pi)

const float scale = 4.;
const float angleOffset = .25;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    
    vec2 pos = uv * scale;
    
    vec2 md = vec2(sqrt(3.), 1.);
    vec2 mn = md*.5;
    
    vec2 ta = mod(pos, md)-mn;
    vec2 tb = mod(pos-mn, md)-mn;
    
    vec2 tri = dot(abs(ta), mn.yx) < sqrt(3.)/4. ? ta : tb;
    
    tri.x = abs(tri.x)-sqrt(3.)/6.;
    
    float angle = 1.-(atan(tri.y, tri.x)+pi)*(1./tau);
    float len = length(tri);
    
    //float sides = 3.; // Regular hexagonal tiling
    float sides = 3.+smoothstep(0.,1.,sin(tau*(time+3.)/4.)*.5+.5)*9.;
    
    float a = angle-floor(sides*angle+angleOffset)/sides;
    float c = cos(a*tau)*len;
    
    float lin = S(c - .26);
    float lout = 1.-S(c - .08);
    
    vec3 col = vec3(lin*lout);

    glFragColor = vec4(vec3(col),1.0);
}
