#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PHI         ((sqrt(5.)+1.)*.5)
#define TAU         (8.*atan(1.))

#define LEFT_DISPLAY_WIDTH (1.-(1./8.))

#define TARGET_RANGE    12.
#define VIEW_X         (normalize(vec3( 1., -.001,  .0)) * TARGET_RANGE)
#define VIEW_Y         (normalize(vec3(.0,   1., -.001)) * TARGET_RANGE)
#define VIEW_Z         (normalize(vec3(.0001, 0.,  -1.)) * TARGET_RANGE)
#define VIEW_HEX    (normalize(vec3(1., 1./PHI/PHI, 0.)) * TARGET_RANGE)
#define VIEW_PHI    (normalize(vec3(1., PHI, 0.)) * TARGET_RANGE)
#define VIEW_ORBIT      (normalize(vec3(3.*sin((mouse.x-.5)*2.*TAU), -3.*atan((mouse.y-.5) * TAU)*2., 3.*cos((mouse.x-.5)*2.*TAU+TAU*.5))) * -TARGET_RANGE) //orbit cam
#define VIEW_ORIGIN     (mouse.x > LEFT_DISPLAY_WIDTH ? (mouse.y < .8 ? (mouse.y < .6 ? (mouse.y < .4 ? (mouse.y < .2 ? VIEW_PHI : VIEW_HEX) : VIEW_Z) : VIEW_Y) : VIEW_X) : VIEW_ORBIT)

float rcp(float x)
{
    return x == 0. ? x : 1./x;    
}

float binary(float n, float e)
{
    return n/exp2(e+1.);
}

float gray(float n, float e)
{
    return binary(n,e+1.)+.25;
}

float step_bit(float b)
{
    return step(.5, fract(b));
}

vec3 h46cube(float i)
{    
    //135024
    float x = step_bit(gray(i, 0.));
    float y = step_bit(gray(i, 3.));
    float z = step_bit(gray(i, 5.));
    float u = step_bit(gray(i, 4.));
    float v = step_bit(gray(i, 2.));
    float w = step_bit(gray(i, 1.));
    
    float t = mod(time * .7, 10.)-5.;
    float l = t > 0. ? fract(t) : fract(1.-t);    
    t     = abs(t);

    float p = t < 1. ? 0.
        : t < 2. ? mix(0., 1., l)
        : t < 3. ? 1.
        : t < 4. ? mix(1., PHI, l)
        : PHI;

    p = pow(PHI, 1.);
    
//    return vec3(x * p - u * p + y + v,  y * p - v * p + z + w, z * p - w * p + x + u) - 1.;
    
    return (vec3((x - u) * p - y - v, 
            -(y - v) * p - z - w, 
             - (z - w) * p - x - u)  + 1.) ;
}

vec3 hsv(in float h, in float s, in float v)
{
        return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

float contour(float x, float r)
{
    return 1.-clamp(.75 * x *(dot(vec2(r),resolution)), 0., 1.);
}

float edge(vec2 p, vec2 a, vec2 b)
{
    vec2 q    = b - a;    
    float u = dot(p - a, q)/dot(q, q);
    u     = clamp(u, 0., 1.);

    return distance(p, mix(a, b, u));
}

float line(vec2 p, vec2 a, vec2 b, float r)
{
    vec2 q    = b - a;    
    float u = dot(p - a, q)/dot(q, q);
    u     = clamp(u, 0., 1.);

    return contour(edge(p, a, b), r);
}

mat2 rmat(float t)
{
    float c = cos(t);
    float s = sin(t);
    return mat2(c, s, -s, c);
}

mat3 projection_matrix(in vec3 origin, in vec3 target) 
{    
    vec3 w              = normalize(origin-target);
    vec3 u                 = normalize(cross(w,vec3(0.,1.,0.)));
    vec3 v              = -normalize(cross(u,w));
    return mat3(u, v, w);
}

mat3 phack;
vec3 project(vec3 origin, vec3 v)
{
    v     -= origin;
    v     *= phack*1.0;    
    v.z     = v.z-.0005;    
    
    if(gl_FragCoord.x > LEFT_DISPLAY_WIDTH * resolution.x)
    {
        v.xy *= rcp(TARGET_RANGE+.5);
    }
    else
    {
        if(mouse.x > LEFT_DISPLAY_WIDTH)
        {
            v.xy *= rcp(TARGET_RANGE-.5);
        }
        else
        {
            v.xy *= rcp(v.z);
        }
    }
    
    return v;
}

float fold(float i)
{
    return i;
}

float icosahedron(vec3 p, float r)
{
    vec4 q     = (vec4(.30901699437, .5, .80901699437, 0.));     
    p     = abs(p);
    return max(max(max(dot(p,q.wxz), dot(p, q.yyy)),dot(p,q.zwx)),dot(p,q.xzw))-r+(PHI-1.);
}

float dodecahedron(vec3 p, float r)
{
    vec3 q     = normalize(vec3(0., .5,.80901699437));    
    p     = abs(p);    
    return max(max(dot(p, q.yxz), dot(p, q.zyx)),dot(p, q.xzy))-r+(PHI-1.);
}

float rhombictriacontahedron(vec3 p, float r)
{
    vec3 q = vec3(.30901699437, .5,.80901699437);    
    p = abs(p);    
    return  max(max(max(max(max(p.x, p.y), p.z), dot(p, q.zxy)), dot(p, q.xyz)), dot(p, q.yzx)) - r;
}

float trucatedicosahedron(vec3 p, float r)
{
    vec4 q    = vec4(.30901699437, .5,.80901699437, 0.);    
    //p = abs(p);
    float d = 0.0;

    p    = abs(p);
    d    = max(max(max(max(max(p.x, p.y), p.z), dot(p, q.zxy)), dot(p, q.xyz)), dot(p, q.yzx));    
    d     = max(max(max(dot(p, q.ywz), dot(p, q.zyw)),dot(p, q.wzy)), d - .125);            
    d    -= r - .125;
    return  d;
}

void main( void ) 
{
    vec2 aspect            = resolution.xy/min(resolution.x, resolution.y);
    vec2 uv             = gl_FragCoord.xy/resolution.xy;
    
    bool left_display_panels    = uv.x < LEFT_DISPLAY_WIDTH; 
    float display_panel        = left_display_panels ? -1. : floor(uv.y * 5.);
    vec2 display_uv            = left_display_panels ? uv : fract(uv * vec2(5., 5.)) + vec2(.125, -.0625);
    
    vec2 p                = (display_uv - .5) * aspect;
    p                += left_display_panels ? vec2(0., 0.) : vec2(-.5,0.);
    
    vec3 origin            = display_panel == 0. ? VIEW_PHI : 
                      display_panel == 1. ? VIEW_HEX : 
                      display_panel == 2. ? VIEW_Z : 
                      display_panel == 3. ? VIEW_Y : 
                          display_panel == 4. ? VIEW_X : 
                                      VIEW_ORIGIN;
    
    vec3 view_position        = origin;
    vec3 target            = vec3(0., 0., 0.);
    
    mat3 projection            = projection_matrix(vec3(0.,0.,0.), origin);
    phack                = projection;
    vec3 view            = normalize(vec3(p, 1.61));

    float x                = floor((1.-uv.x)*96.-2.);    
    float y                = floor(uv.y*64.);    
    y                 = fold(y);

    
    float bits            = step_bit(gray(y*2., x-9.));
    
    float width            = 1.;
    vec3 path            = vec3(0., 0., 0.);
    vec3 vertex[2];
    vertex[0]            = h46cube(fold(63.));
    vertex[1]            = h46cube(fold(0.));
    
    vec3 axis[8];
    
    vec3 v_projection[16];
    axis[0]            = vec3(  1.,  1.,  1.);
    axis[1]            = vec3(  1.,  1., -1.);
    axis[2]            = vec3(  1., -1.,  1.);    
    axis[3]            = vec3( -1.,  1.,  1.);    
    axis[4]            = vec3( -1., -1.,  1.);
    axis[5]            = vec3(  1., -1., -1.);
    axis[6]            = vec3( -1.,  1., -1.);
    axis[7]            = vec3( -1., -1., -1.);    
    
    for(int i = 0; i < 8; i++)
    {

        v_projection[i]        = project(origin, axis[i] * vertex[0]);
    }

    
    float v_weight[8];
    path                += bits * .0125;
    float animation_speed        = 5.;
    float animation_step         = time * animation_speed;
    float cutoff            = mod(animation_step, 128.);
    bool reverse             = cutoff > 64.;
    float animation_interpolant    = reverse ? fract(1.-animation_step) : fract(animation_step) ;
    cutoff                = abs(cutoff-64.);
    
    if(mod(animation_step, 256.) > 128.)
    {
        cutoff            = 64.;
        animation_interpolant    = 1.;
    }
    

    float id_print            = 0.;    
    vec3 bit_hue            = vec3(0., 0., 0.);
    vec3 bit_display        = vec3(0., 0., 0.);
    float v                = 0.;
    for(float i = 0.; i < 64.; i++)
    {            
        v                 = fold(i);

        vertex[0]            = h46cube(v);
        
            
        bool last_vert            = i == floor(cutoff);    

        float saturation        = float(v < cutoff) - float(last_vert) * animation_interpolant;
        float brightness        = v < cutoff ? 1. : .5;
        vec3 color            = hsv(floor(v) * rcp(64.), saturation, brightness);

        
        if(i == y)
        {
            bit_display        = max(bit_display, bits * color);
        }
            

        float l     = 0.;
        for(int i = 0; i < 8; i++)
        {

        v_projection[i+8]     = v_projection[i];
            v_projection[i]        = project(origin, axis[i] * vertex[0]);
            v_weight[i]        = rcp(max(v_projection[i].z, v_projection[i+8].z));
            l            = max(l, line(view.xy, v_projection[i].xy,  v_projection[i+8].xy, v_weight[i]) * v_weight[i]);
        }

        l        = pow(l, 3.9);
        l         *= 8192.;
        path        = max(path, clamp(l * vec3(1.,1.,1.), 0., 1.));
        
        if(i < cutoff)
        {
            l        = 0.;
            if(last_vert)
            {
                vec3 c_vert_a    = project(origin, vertex[1]);

                vec3 c_vert_b    = mix(vertex[0], vertex[1], animation_interpolant);            
                c_vert_b    = project(origin, c_vert_b);
                float c_weight    = rcp(max(c_vert_a.z, c_vert_b.z));
                l        = line(view.xy, c_vert_a.xy, c_vert_b.xy, c_weight) * c_weight * 2.;
            }
            else
            {
                l        = line(view.xy, v_projection[0].xy,  v_projection[8].xy, v_weight[0]) * v_weight[0] * 2.;            

            }

            l        = pow(l, 3.7);
            l         *= 1024.;
            path        = max(path, l * color);            
        
        }

        
        vertex[1]         = vertex[0];            
    }
        
    vec3 result         = vec3(0., 0., 0.);        
    result             += bit_display * .75;
    result             += path;
    result            = pow(result, 1.2 * vec3(1., 1., 1.));
    
    glFragColor.xyz    = result;
    glFragColor.w         = 1.;
}//sphinx
