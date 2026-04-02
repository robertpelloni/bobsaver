#version 420

// original https://www.shadertoy.com/view/tsGGRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 N13(float p) {
    //  from DAVE HOSKINS
   vec3 p3 = fract(vec3(p) * vec3(.1031,.11369,.13787));
   p3 += dot(p3, p3.yzx + 19.19);
   return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

vec4 N14(float t) {
    return fract(sin(t*vec4(123., 1024., 1456., 264.))*vec4(6547., 345., 8799., 1564.));
}
float N(float t) {
    return fract(sin(t*12345.564)*7658.76);
}

vec3 ChromaColor(float a)
{
    return (vec3(sin(a), sin(a + 1.52), sin(a + 3.14)) * 0.8) + 0.5;
}

// A cellular voronoi with smooth boundaries and trippy colors
vec3 voronoi(vec2 pearlsUv, float colorOffset)
{    
    vec2 pearlsId =  floor(pearlsUv);
     
    pearlsUv = fract(pearlsUv);
    
    
    vec3 chroma;
    float bestlen = 1000.0;
    
    for (float y = -1.0; y <= 1.0; y++)
    {
        for (float x = -1.0; x <= 1.0; x++)
        {
            vec2 offset =  vec2(x, y);
            vec2 cellId = pearlsId - offset;
            vec3 rnd = N13(cellId.x * 34.0 + cellId.y * 345.0);
            vec2 center = rnd.xy - offset;
            
            center.x += sin(time * rnd.x) * 0.3;
            center.y += sin(time * rnd.y) * 0.3;

            float len = length(center - (pearlsUv));
            
            float diff = bestlen - len;
            
            float thres = 0.04;    
            float ratio = (diff + thres) / (2.0 * thres);
            
            if (ratio > 0.0)
            {
                bestlen = len;
                vec3 col =  ChromaColor(rnd.z * 100.0 + len * 0.5 + colorOffset);
                chroma = mix(chroma, col, min(ratio, 1.0));
            }
        }
    }
    
    return chroma;
}

vec2 mirror(vec2 uv, vec2 origin, vec2 dir)
{
    vec2 offset = uv - origin;
    float d = dot(offset, dir);
    if (d < 0.0)
    {
        return uv - dir * (2.0 * d);
    }
    return uv;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    
    float rot = time * 0.21;
    float s = sin(rot);
    float c = cos(rot);
    mat2 rotMat = mat2(s,c,-c,s);
    uv = uv * rotMat;
    
    
    
    float centerDst = length(uv);
    
    float distort = centerDst * centerDst;
    
    uv = abs(uv * (1.0 - distort * 0.2));

    float t1 = time * 0.14;
    float t2 = time * 0.2 + 23.0;
    float t3 = -time * 0.24 + 56.0;
    

    uv = mirror(uv, vec2(0.2, 0.7), vec2(sin(t2), cos(t2)));
    uv = mirror(uv, vec2(0.4, 0.3), vec2(sin(t3), cos(t3)));
    uv = mirror(uv, vec2(0.5, 0.5), vec2(sin(t1), cos(t1)));
    
    // Time varying pixel color

    vec2 pearlsUv = uv * 10.0 + sin(time) * 1.5;
    
    pearlsUv.y += time * 2.0;
    
    
 

    vec3 chroma = voronoi(pearlsUv, centerDst * 6.0) * smoothstep(1.5, 0.7, centerDst);

    // Output to screen
    glFragColor = vec4(chroma,1.0);
}
