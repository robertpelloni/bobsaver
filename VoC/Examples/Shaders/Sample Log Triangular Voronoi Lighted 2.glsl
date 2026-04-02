#version 420

// original https://www.shadertoy.com/view/Wdd3WM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Stephane Cuillerdier - Aiekick/2019 (twitter:@aiekick)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// Tuned via NoodlesPlate (https://github.com/aiekick/NoodlesPlate/releases)

// thumbail at 14.95

const vec3 color0 = vec3(0.224071,0.115035,0.348214);
const vec3 color1 = vec3(0.6,1.1,1.6);
const vec3 lightColor = vec3(0.751786,1.6,0.6);

vec3 shape(vec2 g)
{
    float c = 9.0;
        
    float t = time;
    float t1 = t * 0.1;
    
    vec2 p = vec2(0), sp = p;
    
    g = vec2(log(length(g))-t, atan(g.x,g.y));
        
    float t2 = sin(t*0.2)*0.5+0.5;
        
    g.y = abs(fract(g.y/6.28318*(10.*t2+2.))-0.5);

    for(int x=-2;x<=2;x++)
    for(int y=-2;y<=2;y++)
    {    
        p = vec2(x,y);
        p += .5 + .5*sin( t1 * 10. + 9. * fract(sin((floor(g)+p)*mat2(2,5,5,2)))) - fract(g);
        p *= mat2(cos(t1), -sin(t1), sin(t1), cos(t1));
        float d = max(abs(p.x)*.866 - p.y*.5, p.y);
        if (d < c)
        {
            c = d;
            sp = p;
        }
    }

    return vec3(c,sp);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy)/resolution.y;
    
    float t = time * 0.5;
    
    float k = 0.01;
    vec3 f = shape(uv);
    float fx = shape(uv + vec2(k,0.0)).x-f.x;
    float fy = shape(uv + vec2(0.0, k)).x-f.x;
    
    vec3 n = normalize(vec3(fx, 0.1, fy) );
    
    vec3 col = mix( color0, color1, f.x );

    float r = sin(t+f.y)*cos(t+f.z)*0.5+0.5;
    col = mix(col.xyz, mix(col.zxy, col.yzx, r), 1.0-r);
    
    col += 0.2 * pow(max(dot( n, vec3(0,1,0)), 0.), 100.) * lightColor;
    
    glFragColor = vec4( col, 1.0 );
}
