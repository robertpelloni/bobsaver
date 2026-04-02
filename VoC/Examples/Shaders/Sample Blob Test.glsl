#version 420

// original https://www.shadertoy.com/view/WlSSWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k/4.0;
}

float dist(vec3 point)
{
    float d = point.y + 1.0;
    for(float i = 1.0; i < 50.0; i++)
    {
        vec3 pos = vec3(sin(i*1.43+time*0.12), cos(i*1.13+time*0.345), sin(i*3.23+time*0.243));
        

        float sphere = (length(point - pos) - 0.001*i);
        d = smin(sphere, d, 0.8);
        
    }
    return d;
}

vec3 normal(vec3 point)
{
    vec3 delta = vec3(0.001, 0.0, 0.0);
    float center = dist(point);
    return(normalize(vec3(
        center - dist(point - delta.xyz),
        center - dist(point - delta.yxy),
        center - dist(point - delta.yyx)
        )));
}

void main(void)
{
    float time = time * 0.5;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    vec3 camera = vec3(3.0 * sin(time), 1.5, 3.0 * cos(time));
    vec3 target = vec3(0.1, 0.2, 0.5);
    vec3 light = normalize(vec3(-4.0, 3.0, -4.0));   
    
    vec3 ww = normalize(target - camera);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = normalize(cross(uu, ww));
    
    
    vec3 dir = normalize(uv.x*uu + uv.y*vv + 1.8*ww);
    
    float scan = 0.0;
    vec3 point;
    int i;
    for(i = 0; i < 100; i++)
    {
        point = camera + scan * dir;
        float d = dist(point);
        scan += d;
        if(scan > 40.0) break;
        if(scan < 0.01) break;
    }
    
    vec3 mat = vec3(0.2, 0.4, 0.8);
    
    if (scan <= 20.0)
    {
        vec3 n = normal(point);
        float shade = dot(n, light);
        
           vec3 halfv = normalize(light - dir);
        float spec = pow(max(dot(n, halfv), 0.0), 10.0);
        
        col = mat * shade + spec;
    }
    else
    {
        col = 0.5*vec3(1.0 - uv.y, 1.0 - 0.5*uv.y, 1.0);
    }
    
    //glow
    col += vec3(float(i)*0.007, float(i)*0.003, 0); 
    
    //dark
    col /= scan *0.5;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
