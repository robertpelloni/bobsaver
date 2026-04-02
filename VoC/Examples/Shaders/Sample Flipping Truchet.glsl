#version 420

// original https://www.shadertoy.com/view/lslBDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ----------------------------------------------------------------------------------------
//    "Flipping Truchet" by Antoine Clappier - July 2017
//
//    Licensed under:
//  A Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
//    http://creativecommons.org/licenses/by-nc-sa/4.0/
// ----------------------------------------------------------------------------------------

// Inspired by the paintings of Jean-Claude Ferry who studied Truchet tiles.
// See: http://jcferry.pagesperso-orange.fr/peinture/peinture/talon_architecte.html

// Antialiasing parameter:
float Epsilon;

// Draw antialiased disk:
float Disk(vec2 P,float Radius, vec2 Center)
{
    float d = length(P-Center) - Radius;
    return 1.0 - smoothstep(-Epsilon, Epsilon, d);
}

// Draw square:
float Square(vec2 P, float Size)
{
  return step(abs(P.x), Size)*step(abs(P.y), Size);
}

// Draw pattern:
float Pattern(vec2 P, float Flip)
{
    // Flip:
    P = mix(P, vec2(P.x, -P.y), Flip);
    
    // Parameters:
    float a0 = 0.4;
    float a1 = 2.0*a0;
    float a2 = 3.0*a0;
    float a3 = 4.0*a0;
    float a4 = 5.0*a0;
    vec2 c0 = vec2(-1.0, 1.0);
    vec2 c1 = vec2( 1.0, 1.0);
    vec2 c2 = vec2( 1.0,-1.0);
    vec2 c3 = vec2(-1.0,-1.0);
    
    // Draw shapes:
    float d0 = Disk(P, a4, c3), d1 = Disk(P, a3, c1);
    float d2 = Disk(P, a4, c1), d3 = Disk(P, a3, c3);
    
    float d4 = Disk(P, a2, c3), d5 = Disk(P, a1, c3);
    float d6 = Disk(P, a2, c1), d7 = Disk(P, a1, c1);
    
    float ds0 = Disk(P, a0, c0), ds1 = Disk(P, a0, c1);
    float ds2 = Disk(P, a0, c2), ds3 = Disk(P, a0, c3);
    
    // Blend:
    float d = (d0*d1 + d2*d3 + 1.0*(d4-d5) + 1.0*(d6-d7)) / 2.0 + (ds0+ds2)*(1.0-d0*d2) + ds1 + ds3;
    return d;
}

float Rand(vec2 P)
{
    return fract(sin(dot(P.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void)
{
    // Setup:
    float minResolution = min(resolution.x, resolution.y);
    vec2 uv = 2.0*(gl_FragCoord.xy - resolution.xy/2.0) / minResolution;
    float t = time / 5.0;
    
    // Antialiasing gradient size: 
    Epsilon = 2.0/minResolution;

    // Geometry:
    float blackDisk = Disk(uv, 0.81, vec2(0.0));
    float whiteSquare = Square(uv, 0.675);
    
    // Grid:
    float scaling = 2.77;
    vec2 grid = scaling*(vec2(abs(uv.x), uv.y));
    vec2 gridIndex = floor(grid);
    vec2 tile = 2.0*fract(grid) - vec2(1.0);
    
    // Draw tile with random orientation:
    Epsilon *= 2.0*scaling;
    float tile0 = Pattern(tile, floor(2.0*Rand(gridIndex+floor(vec2(t)))));
    float tile1 = Pattern(tile, floor(2.0*Rand(gridIndex+floor(vec2(1.0+t)))));
    
    // Smooth transition between randomm tiles:
    float speed = 0.2;
    float k = (1.0-speed)*Rand(floor(grid));
    float d = mix(tile0, tile1, smoothstep(k, k+speed, fract(t)));
    
    // Shade:
    vec3 back = vec3(121., 156., 210.) / 255.;
    d = 0.05+0.94*d;
    vec3 c1 = mix(back, d*back, blackDisk);
    vec3 c2 = mix(back, vec3(1.0), d);
    vec3 color = mix(mix(c1, c2, whiteSquare), vec3(d), whiteSquare*blackDisk);

    // Framing and vignetting:
    color *= Square(uv, 1.0);
    color *= 1.0 - 0.15*pow(length(uv), 3.0);
                  
    glFragColor = vec4(color, 1.0);
}
