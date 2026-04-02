#version 420

// original https://www.shadertoy.com/view/WsSczD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float max_distance = 1000.;
float plank = .001;
int max_iter = 128;
float EPSILON = .001;

float displacement(vec3 p, float scale)
{
    return sin(scale*p.x)*sin(scale*p.y)*sin(scale*p.z);
}

float octahedronSDF( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}
float sceneSDF(vec3 p)
{
    return (length(p) - .8)*(cos(time)*.5+.5) + octahedronSDF(p,.8)*(cos(time+3.14)*.5+.5) + (sin(time * 2. - 3.14*.5)*.5+.5) * displacement(p,5.) / 3.;
}

vec3 estimateNormal(vec3 p)
{
    return normalize(vec3(
        sceneSDF(vec3(p.x+EPSILON,p.y,p.z)) - sceneSDF(vec3(p.x-EPSILON,p.y,p.z)),
        sceneSDF(vec3(p.x,p.y+EPSILON,p.z)) - sceneSDF(vec3(p.x,p.y-EPSILON,p.z)),
        sceneSDF(vec3(p.x,p.y,p.z+EPSILON)) - sceneSDF(vec3(p.x,p.y,p.z-EPSILON))
        ));
}

vec3 calculateDeffuse(vec3 p)
{
    vec3 deffuse = vec3(0, 0, 0);
    vec3 normal = estimateNormal(p);
    vec3 lightdir = normalize(vec3(2.,2.,-3.) - p);
    float diff = max(dot(normal,lightdir),0.0);
    deffuse += diff * (1.,1.,1.);
    return deffuse;
}
    
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy*2. - resolution.xy)/resolution.x;
    vec3 rd = vec3(uv, 1.);
    
    vec3 ro = vec3(.0,0.,-3.);
    
    vec3 col = vec3(.4,.4,.4);
    
    for(int iter=0; iter<max_iter; iter++)    
    {
        float curr = sceneSDF(ro);
        
        //Hit condition
        if(plank > curr)
        {
            col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
            col*= (.1 + calculateDeffuse(ro));
        }
            
        
        ro += rd*curr;
    }
        

    // Output to screen
    glFragColor = vec4(col,1.0);
}
