#version 420

// original https://www.shadertoy.com/view/ll3yDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// nabr
// https://www.shadertoy.com/view/ll3yDf
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// https://creativecommons.org/licenses/by-nc-sa/3.0/

#define R(p, a) p = cos(a) * p + sin(a) * vec2(p.y, -p.x)
#define eps 1e-3

#define STEPS 128

float map(vec3 p) 
{
    // note: i make this for my personal use, 
    // you have to play with thouse values in order to archive the desired effect
    
    float noise = 
        ( 0.1 / (cos(p.x * 0.01 - sin(p.z * cos(time - p.y)))))
        / (/* 1.51 + */ 1.997 - cos((p.y * 2.001 - sin(p.x * cos(time - p.y)))));
    
    
   /* // littel booster just in case
   noise = min(noise * 1.5, 
                ( .1 / abs(cos(p.y * 1.001 - sin(p.z + cos(time + p.y * 3.14 )))))
                / (1.001 + cos((p.x * .1 +  cos(time * 3.14- p.z)))));
    */
   
    return min(noise,1.0 );
}

void main(void)
{
    // setup scene
    vec2 uv = 2.0 * (gl_FragCoord.xy / resolution.xy) - 1.0;
    uv.x *= resolution.x/resolution.y;
    
    vec3 ro = vec3(0.0, 0.0, -1.0 );
    float cameraZ = 1.;
    vec3 rd = normalize(vec3(uv,cameraZ));
    
    R(rd.yz, time * 0.43 );
    R(rd.xz, time * 0.31 );

    
    // raymarch
    
    float t = 0.0;
    
    for(int i = 0; i < STEPS; i++) 
    {
        t += map( ro + rd * t);
        if(t <  eps) break;
    }
    
    
    // ------- shade
    vec3 ip = ro + rd * t;
    glFragColor.rgb = (t * vec3( 0.12, 0.2, 0.24)) * map(ip - 0.2) + t * 0.02;
    glFragColor.a = 1.0;
}
