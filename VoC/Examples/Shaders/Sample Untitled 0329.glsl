#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//rhombic triacontahedron
//hrrrm
//sphinx

#define BRIGHTNESS    1.
#define GAMMA        .6

#define FLIP_VIEW    (mouse.y < .5 ? 1. : -1.)
#define TARGET_RANGE    32.

#define VIEW_POSITION     (normalize(vec3(sin((mouse.x-.5)*TAU), sin((mouse.y-.25)*TAU*.5)-.5, -cos((mouse.x-.5)*TAU+TAU*.5))) * TARGET_RANGE) //orbit cam
//#define VIEW_POSITION         (normalize(vec3(.5, .3, .0)) * TARGET_RANGE)
//#define VIEW_POSITION     (normalize(vec3(1., .01, 0.)) * TARGET_RANGE) //x
//#define VIEW_POSITION     (normalize(vec3(0.01, 1., 0.)) * TARGET_RANGE)//-y
//#define VIEW_POSITION     (normalize(vec3(0.01, 0., 1.)) * TARGET_RANGE)    //z

#define VIEW_TARGET     vec3(0., 0., 0.)

#define MAX_FLOAT     (pow(2., 128.)-1.)
    
#define TAU         (8. * atan(1.))
#define PHI         ((sqrt(5.)+1.)*.5)
#define PHI2         (PHI*PHI)
#define PHI3         (PHI*PHI*PHI)

vec4 g_ray        = vec4(0., 0., 0., 1.);
vec3 e_color        = vec3(0., 0., 0.);
bool get_material    = false;

mat2 rmat(float t);
vec3 hsv(in float h, in float s, in float v);
float squaresum(in vec3 v); 
float sum(in vec3 v);
float max_component(vec3 v);
float smoothmin(float a, float b, float x);
float hash(float x);

float segment(vec3 p, vec3 a, vec3 b, float r);
float edge(vec3 p, vec3 a, vec3 b);
float cube(vec3 p, vec3 s);
float rhombictriacontahedron(vec3 p, float r);

float quad( vec3 p, vec3 a, vec3 b, vec3 c, vec3 d );
float rtc_edges(vec3 position, float scale);
float rtc_faces(vec3 position, float scale, float depth);
float rtc_vertices(vec3 position, float scale, float radius);

vec4 derivative(in vec3 position, in float range);

float exp2fog(float depth, float density);
float shadow(vec3 origin, vec3 direction, float mint, float maxt, float k);
float ambient_occlusion(vec3 position, vec3 normal, float delta, float t, float f);
vec3 gamma_correction(vec3 color, float brightness, float gamma);

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
    float d = 0.;

    p    = abs(p);
    d    = max(max(max(max(max(p.x, p.y), p.z), dot(p, q.zxy)), dot(p, q.xyz)), dot(p, q.yzx));    
    d     = max(max(max(dot(p, q.ywz), dot(p, q.zyw)),dot(p, q.wzy)), d-.125);            
    d    -= r;
    return  d;
}

float map(in vec3 position)
{    
    vec4 v             = vec4(PHI3, PHI2, PHI, 0.);
    
    float ground    = cube(position + vec3(0., 5.,0.), vec3(8., .125, 8.));
    float range    = MAX_FLOAT;
    /*
    float rtc    = rhombictriacontahedron(position, PHI3);
    float ti    = trucatedicosahedron(position, PHI3);    
    float t        = time * .25;
    float lerp    = abs(fract(t)-.5)*2.;
    float poly    = mix(ti, rtc, lerp);
    */
    vec3 poly_pos = position;
    float phase = time*3.14/6.;
    poly_pos.xz *= mat2(cos(phase), sin(phase), -sin(phase), cos(phase));
    float poly    = cube(poly_pos, vec3(1, 1, 12));

    range        = min(range, ground);
    range        = min(range, poly);    
    
    if(get_material)
    {
        g_ray        *= 1.;
        g_ray.xyz    = ground     == range ? vec3(1.,1.,1.) * 1.25 : g_ray.xyz;    
        g_ray.xyz    = poly         == range ? vec3(.04, .75, 1.8) * 1.25 : g_ray.xyz;    
        get_material     = false;
    }
    
    return range;
}

void main( void ) 
{
    vec2 aspect            = resolution.xy/resolution.yy;
    vec2 uv             = gl_FragCoord.xy/resolution.xy;
    vec2 screen            = (uv - .5) * aspect;
    
    vec2 m                =  vec2(0.0);//(mouse-.5) * aspect;
    
    const float border_pixel_width = 5.0;
    bool hit_target = false
        || (abs(uv.x) < border_pixel_width/resolution.x) || (abs(1.-uv.x) < border_pixel_width/resolution.x)
        || (abs(uv.y) < border_pixel_width/resolution.y) || (abs(1.-uv.y) < border_pixel_width/resolution.y)
        || (abs(uv.x-0.33)*2. < border_pixel_width/resolution.x)
        || (abs(uv.x-0.67)*2. < border_pixel_width/resolution.x)
        ;
    
    
    float field_of_view        = PHI;
    
    vec3 w                  = normalize(VIEW_POSITION-VIEW_TARGET);
    vec3 u                  = normalize(cross(w,vec3(0.,1.,0.)));
    vec3 v                  = normalize(cross(u,w));

    vec3 direction             = normalize(screen.x * u + screen.y * v + field_of_view * -w);    
    vec3 origin            = VIEW_POSITION;
    vec3 position            = origin;
    
    
    //sphere trace    
    float minimum_range        = 16./max(resolution.x, resolution.y);
    float adaptive_range        = minimum_range;
    float max_range            = 64.;
    float range            = max_range;
    float total_range        = 0.;
    float steps             = 1.;
    const float iterations        = 64.;
    for(float i = 0.; i < iterations; i++)
    {
        if(hit_target && total_range > 30.){
            glFragColor = vec4(1);
            return;
        }
        if(range > adaptive_range && total_range < max_range)
        {
            steps++;
            
            range         = map(position);
            range        *= .9;
            adaptive_range    *= 1.03;
            
            total_range    += range;
            
            position     = origin + direction * total_range;    
        }
    }
    
    
    
    vec3 light_position     = vec3(-PHI3, PHI3, PHI) * 256.;
    vec3 light_direction    = normalize(light_position - position);
    
    
    
    //shade        
    vec3 color             = vec3(0., 0., 0.);    
    if(steps < iterations-1. && total_range < max_range)
    {        

        vec4 gradient        = derivative(position, range * 1.);
        
        vec3 surface_direction     = normalize(gradient.xyz);
    
        
        
        vec4 light_color    = vec4( .97, .95, .93, 1.);
        
            
        vec3 reflection     = reflect(direction, surface_direction);
        float light_direct    = clamp(dot(surface_direction, light_direction), .0125, 1.);
        float light_specular     = pow(clamp(dot(reflection, light_direction), 0., 1.), 4.);
        float light_bounce     = pow(clamp(abs(dot(-light_direction, reflection)), .0, 1.), 4.0);
        float light_ambient    = .5;
        
        float fog         = exp2fog(max_range/(1.+total_range), .5);
        float shadows        = shadow(position, light_direction, range * 2., 64., 64.) * .25 + .75;
        float occlusion        = ambient_occlusion(position, surface_direction, .1, .25, .5);

        get_material        = true;                
        float k         = map(position - surface_direction.xyz * range);
        
        light_color.xyz        += light_specular * light_color.xyz;        
        light_color.xyz        += light_direct   * light_color.xyz;        
        light_color.xyz        += light_bounce      * light_color.xyz;
        light_color.xyz        *= light_color.w;
    
        
        color            = g_ray.xyz * .5;        
        color            += light_direct * .25;        
        color            += light_specular * .123;
        color            += light_bounce * .25;
        color            *= clamp(shadows * occlusion * light_direct, light_ambient, 1.);
        color            += fog;

        color            += gradient.w;
        color            = gamma_correction(color, BRIGHTNESS, GAMMA);
    }
    else
    {
        color            = vec3(0., 0., 0.);
        color            += log(steps/32.);
    }
    
    
    glFragColor             = vec4(color, 1.);
}//sphinx

float squaresum(in vec3 v) 
{ 
    return dot(v,v); 
}

float sum(in vec3 v) 
{ 
    return dot(v, vec3(1., 1., 1.)); 
}

float smoothmin(float a, float b, float k)
{
//    const float k = 5.8;
        return -log(exp(-k*a)+exp(-k*b))/k;
}

float max_component(vec3 v)
{
    return max(max(v.x, v.y), v.z);
}

vec3 hsv(in float h, in float s, in float v)
{
    return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

float hash(in float x)
{
    float k = x * 65537.618034;       
    return fract(fract(k * x) * k);
}

mat2 rmat(float t)
{
    float c = cos(t);
    float s = sin(t);
    return mat2(c, s, -s, c);
}

float cube(vec3 p, vec3 s)
{
    vec3 d = abs(p) - s;
    return max(d.x,max(d.y,d.z) - min(length(d), 0.));
}

float segment(vec3 p, vec3 a, vec3 b, float r)
{

    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);

    return length(pa - ba * h)-r;
}

float edge(vec3 p, vec3 a, vec3 b)
{
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), .0, 1.);
    return length(pa - ba * h);
}

/*
float rtc_edges(vec3 position, float scale)
{    
    position    = abs(position);
    
    vec4 v         = vec4(PHI3, PHI2, PHI, 0.) * scale;
    
    float e[9];
    e[0] = edge(position, v.xyw, v.yyy);
    e[1] = edge(position, v.wxy, v.yyy);
    e[2] = edge(position, v.ywx, v.yyy);
    e[3] = edge(position, v.xyw, v.xwz);
    e[4] = edge(position, v.xyw, v.zxw);
    e[5] = edge(position, v.ywx, v.wzx);
    e[6] = edge(position, v.ywx, v.xwz);
    e[7] = edge(position, v.wxy, v.wzx);
    e[8] = edge(position, v.wxy, v.zxw);
    
    float edges    = MAX_FLOAT;
     for(int i = 0; i < 9; i++)
    {
        edges = min(edges, e[i]);
    }
    
    return edges;
}
*/

vec4 derivative(in vec3 position, in float epsilon)
{
    vec2 offset = vec2(-epsilon, epsilon);
    vec4 simplex = vec4(0.);
    simplex.x = map(position + offset.xyy);
    simplex.y = map(position + offset.yyx);
    simplex.z = map(position + offset.yxy);
    simplex.w = map(position + offset.xxx);
    vec3 grad = offset.xyy * simplex.x + offset.yyx * simplex.y + offset.yxy * simplex.z + offset.xxx * simplex.w;
    return vec4(grad, .2/epsilon*(dot(simplex, vec4(1.)) - 4. * map(position)));
}

float exp2fog(float depth, float density)
{
    float f = pow(2.71828, depth * density);
    return 1./(f * f);
}

float shadow(vec3 origin, vec3 direction, float mint, float maxt, float k) 
{
    float sh = 1.0;
    float t = mint;
    float h = t;
    for (int i = 0; i < 32; i++) 
    {
        if (t < maxt)
        {
            h         = map(origin + direction * t);
            sh         = smoothmin(abs(k * h/t), sh, k);
            t         += min(h, maxt);
        }
    }
    return clamp(sh, .0, 1.);
}

float ambient_occlusion(vec3 position, vec3 normal, float delta, float t, float f)
{       
    float occlusion = 0.0;
    for (float i = 1.; i <= 9.; i++)
    {
        occlusion    += t * (i * delta - map(position + normal * delta * i));
        t         *= f;
    }
     
    const float k     = 4.0;
    return 1.0 - clamp(k * occlusion, 0., 1.);
}

vec3 gamma_correction(vec3 color, float brightness, float gamma)
{
    return pow(color * brightness, vec3(1., 1., 1.)/gamma);
}
