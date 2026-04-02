#version 420

// original https://www.shadertoy.com/view/7lVGWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time (time + 100.)

//color
//#define COLOR

//see all spheres
//#define SHOW_ALL

vec3 rand(vec3 p)
{
    float x = dot(p, vec3(105.2523, 323.6236, 246.634)),
    y = dot(p , vec3(225,123.35235,352.235)),
    z = dot(p, vec3(373,164.352,273.46343));
    
    return fract(sin(vec3(x,y,z))* 45364.623624);
}

mat2 rot(float a)
{
    float c= cos(a), s = sin(a);
    
    return mat2(c,-s,s,c);
}
vec4 voro(vec3 p)
{
    vec3 ip = floor(p), fp = fract(p);
    
    float dd = 1.;
    vec3 pos = vec3(0);
    for(int i = -1; i <= 1; i++)
    {
        for(int j = -1; j <= 1; j ++)
        {
            for(int k = -1; k <= 1; k++)
            {
                vec3 n = vec3 (j, i ,k); 
                vec3 o = ip + n;
                //o.xy *= rot(time * 0.01) *0.01;
                vec3 p = rand(o);
                
                //p.xz += 0.25 * sin(time + p.x) + cos(p.z + time) * 0.25;
                float d = length(n + p - fp);
            
                if(d < dd)
                {
                    dd = d;
                    pos = n + p - fp;
                }
            }
        }
    }
    return vec4(pos,dd);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 r = resolution.xy,uv = (2. * gl_FragCoord.xy - r)/r.y;
    
    
    vec3 ro = vec3(0, time* 0.01, time),rd = normalize(vec3 (uv,2.));
    
    // Time varying pixel color
    
    vec3 col = vec3(0);
    
    float dd = 0.;

    for(int i = 0; i < 255; i ++)
    {
        vec3 p = ro + rd * dd;
       // p.xy -= ro.xy;
        //p.xy *= mat2(cos(time + p.z), -sin(time + p.z), sin(time + p.z), cos(time + p.z)) * 0.5;
       //p.xy += ro.xy;
        vec4 vp = voro(p);
        float ll = vp.w - length(p - ro)* 0.03 + length(uv) * 0.1;
        
        if ( ll < 0.001)
        {
            col = 1.-vec3(max(dot(vp.xyz, p), 0.)) * 1.- length(p - ro) * .01; //col = vec3(1) * 100/;
#ifdef COLOR
            col.gb *= 0.5 + sin(time * 5. + length(ro-p) ) * 0.3;
#endif

#ifdef SHOW_ALL
            col = 1.-vec3(length(p - ro) * 0.01);
#endif

            break;
        }
        dd += ll;
        
        if(dd > 100.)
            break;
    }

    // Output to screen
    
#ifdef SHOW_ALL
    glFragColor = vec4(col,1.0);
#else
    glFragColor = vec4(col * length(uv /2.) ,1.0);
#endif
}
