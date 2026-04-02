#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
 
//rhombic triacontahedron
//sphinx

#define TAU     (8. * atan(1.))
#define PHI     ((sqrt(5.)+1.)*.5)
#define PHI2     (PHI*PHI)
#define PHI3     (PHI*PHI*PHI)

#define V00 vec3( PHI2,    0.,  PHI3)
#define V01 vec3(   0.,   PHI,  PHI3)
#define V02 vec3(-PHI2,    0.,  PHI3)
#define V03 vec3(   0.,  -PHI,  PHI3)
#define V04 vec3( PHI2,  PHI2,  PHI2)
#define V05 vec3(   0.,  PHI3,  PHI2)
#define V06 vec3(-PHI2,  PHI2,  PHI2)
#define V07 vec3(-PHI2, -PHI2,  PHI2)
#define V08 vec3(   0., -PHI3,  PHI2)
#define V09 vec3( PHI2, -PHI2,  PHI2)
#define V10 vec3( PHI3,    0.,   PHI)
#define V11 vec3(-PHI3,    0.,   PHI)
#define V12 vec3( PHI3,  PHI2,    0.)
#define V13 vec3(  PHI,  PHI3,    0.)
#define V14 vec3( -PHI,  PHI3,    0.)
#define V15 vec3(-PHI3,  PHI2,    0.)
#define V16 vec3(-PHI3, -PHI2,    0.)
#define V17 vec3( -PHI, -PHI3,    0.)
#define V18 vec3(  PHI, -PHI3,    0.)
#define V19 vec3( PHI3, -PHI2,    0.)
#define V20 vec3( PHI3,    0.,  -PHI)
#define V21 vec3(-PHI3,    0.,  -PHI)
#define V22 vec3( PHI2,  PHI2, -PHI2)
#define V23 vec3(   0.,  PHI3, -PHI2)
#define V24 vec3(-PHI2,  PHI2, -PHI2)
#define V25 vec3(-PHI2, -PHI2, -PHI2)
#define V26 vec3(   0., -PHI3, -PHI2)
#define V27 vec3( PHI2, -PHI2, -PHI2)
#define V28 vec3( PHI2,    0., -PHI3)
#define V29 vec3(   0.,   PHI, -PHI3)
#define V30 vec3(-PHI2,    0., -PHI3)
#define V31 vec3(   0.,  -PHI, -PHI3)

mat2 rmat(float t)
{
    float c = cos(t);
    float s = sin(t);
    return mat2(c, s, -s, c);
}

float segment(vec3 p, vec3 a, vec3 b, float r)
{
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
    
    return length(pa - ba * h) - r;
}

float map(vec3 position)
{
    vec3 origin     = position - vec3(0., 0., 8. * PHI);
    origin.xy     *= rmat(time * (PHI/17.));
    origin.xz     *= rmat(time * (PHI/5.));
    
    float radius     = .0625;

    float range     = 999.;    

    range        = min(range, segment(origin, V00, V01, radius));
    range        = min(range, segment(origin, V01, V02, radius));
    range        = min(range, segment(origin, V02, V03, radius));
    range        = min(range, segment(origin, V03, V00, radius));
    range        = min(range, segment(origin, V00, V04, radius));
    range        = min(range, segment(origin, V04, V05, radius));
    range        = min(range, segment(origin, V01, V05, radius));
    range        = min(range, segment(origin, V05, V06, radius));
    range        = min(range, segment(origin, V06, V02, radius));
    range        = min(range, segment(origin, V02, V11, radius));
    range        = min(range, segment(origin, V02, V07, radius));
    range        = min(range, segment(origin, V07, V08, radius));
    range        = min(range, segment(origin, V08, V03, radius));
    range        = min(range, segment(origin, V08, V09, radius));
    range        = min(range, segment(origin, V00, V09, radius));
    range        = min(range, segment(origin, V00, V10, radius));
    range        = min(range, segment(origin, V10, V12, radius));
    range        = min(range, segment(origin, V12, V13, radius));
    range        = min(range, segment(origin, V05, V13, radius));
    range        = min(range, segment(origin, V05, V14, radius));
    range        = min(range, segment(origin, V06, V15, radius));
    range        = min(range, segment(origin, V11, V15, radius));
    range        = min(range, segment(origin, V11, V16, radius));
    range        = min(range, segment(origin, V16, V07, radius));
    range        = min(range, segment(origin, V09, V19, radius));
    range        = min(range, segment(origin, V19, V10, radius));
    range        = min(range, segment(origin, V04, V12, radius));
    range        = min(range, segment(origin, V28, V29, radius));
    range        = min(range, segment(origin, V29, V30, radius));
    range        = min(range, segment(origin, V30, V31, radius));
    range        = min(range, segment(origin, V31, V28, radius));
    range        = min(range, segment(origin, V28, V22, radius));
    range        = min(range, segment(origin, V22, V23, radius));
    range        = min(range, segment(origin, V23, V29, radius));
    range        = min(range, segment(origin, V30, V24, radius));
    range        = min(range, segment(origin, V30, V21, radius));
    range        = min(range, segment(origin, V30, V25, radius));
    range        = min(range, segment(origin, V31, V26, radius));
    range        = min(range, segment(origin, V27, V28, radius));
    range        = min(range, segment(origin, V28, V20, radius));
    range        = min(range, segment(origin, V20, V12, radius));
    range        = min(range, segment(origin, V12, V22, radius));
    range        = min(range, segment(origin, V24, V23, radius));
    range        = min(range, segment(origin, V24, V15, radius));
    range        = min(range, segment(origin, V15, V21, radius));
    range        = min(range, segment(origin, V21, V16, radius));
    range        = min(range, segment(origin, V16, V25, radius));
    range        = min(range, segment(origin, V25, V26, radius));
    range        = min(range, segment(origin, V26, V27, radius));
    range        = min(range, segment(origin, V27, V19, radius));
    range        = min(range, segment(origin, V19, V20, radius));
    range        = min(range, segment(origin, V13, V23, radius));
    range        = min(range, segment(origin, V14, V23, radius));
    range        = min(range, segment(origin, V14, V15, radius));
    range        = min(range, segment(origin, V08, V18, radius));
    range        = min(range, segment(origin, V18, V26, radius));
    range        = min(range, segment(origin, V26, V17, radius));
    range        = min(range, segment(origin, V17, V08, radius));
    range        = min(range, segment(origin, V18, V19, radius));
    range        = min(range, segment(origin, V16, V17, radius));

    
    return range;
}

vec3 derive(in vec3 position, in float range)
{
    vec2 offset     = vec2(0., range);
    vec3 normal     = vec3(0.);
    normal.x        = map(position+offset.yxx)-map(position-offset.yxx);
    normal.y        = map(position+offset.xyx)-map(position-offset.xyx);
    normal.z        = map(position+offset.xxy)-map(position-offset.xxy);
    return normalize(normal);
}

void main( void ) 
{
    vec2 aspect        = resolution.xy/resolution.yy;
    
    vec2 uv         = gl_FragCoord.xy/resolution.xy;
    uv             = (uv - .5) * aspect;
    
    vec2 m            = (mouse-.5) * aspect;
    
    
    
    vec3 direction      = normalize(vec3(uv, 1.));
    vec3 origin        = vec3(0.);
    vec3 position        = origin;
    
    
    
    //raytrace
    float minimum_range    = 2./max(resolution.x, resolution.y);
    float max_range        = 64.;
    float range        = max_range;
    float total_range    = 0.;
    float steps         = 0.;
    for(int count = 1; count < 64; count++)
    {
        if(range > minimum_range && total_range < max_range)
        {
            steps++;
            
            range         = map(position);            
        
            range         *= .65;        
            minimum_range    *= 1.005;    
        
            total_range    += range;

        
            position     = origin + direction * total_range;            
        }
    }
    
    

    vec3 background_color     = (vec3(.375, .375, .5) - uv.y) * .0625;
    vec3 material_color    = vec3( .45, .35, .12) + .55;    
    vec3 color         = background_color + steps/64.;
    if(range < .01)
    {
        vec3 surface_direction     = derive(position, minimum_range);
    
        vec3 light_position     = vec3(32., 32., -64.);
        vec3 light_direction    = normalize(light_position - position);
        
        float light        = max(dot(surface_direction, light_direction), 0.);
        
        
        color             += material_color + material_color * light + light;
        color             -= max(material_color/total_range, .5);
    }
    else
    {
        color             += 1.-material_color;
    }
        
    color                 = pow(color * .5, vec3(1.6, 1.6, 1.6));
    
    glFragColor             = vec4(color, 1.);
}//sphinx
