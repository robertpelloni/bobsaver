#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//rhombic triacontahedron
//incomplete study of internal polyhedra
//work in progress (this red shape is wrong)
//sphinx

#define BRIGHTNESS    .45
#define GAMMA        .6

#define FLIP_VIEW    (mouse.y < .5 ? 1. : -1.)
#define TARGET_RANGE    1024.

#define VIEW_POSITION     (normalize(vec3(sin((mouse.x-.5)*TAU), sin((mouse.y-.25)*TAU*.5), cos((mouse.x-.5)*TAU+TAU*.5))) * TARGET_RANGE) //orbit cam

//#define VIEW_POSITION     (normalize(vec3(1., .01, 0.)) * TARGET_RANGE) //x
//#define VIEW_POSITION     (normalize(vec3(0.01, 1., 0.)) * TARGET_RANGE)//-y
//#define VIEW_POSITION     (normalize(vec3(0.01, 0., 1.)) * TARGET_RANGE)    //z

#define VIEW_TARGET     vec3(0., 0., 0.)

#define MAX_FLOAT     (pow(2., 128.)-1.)
    
#define TAU         (8. * atan(1.))
#define PHI         ((sqrt(5.)+1.)*.5)
#define PHI2         (PHI*PHI)
#define PHI3         (PHI*PHI*PHI)

vec4 g_ray        = vec4(0., 0., 0., 0.);

mat2 rmat(float t);
vec3 hsv(in float h, in float s, in float v);
float squaresum(in vec3 v); 
float sum(in vec3 v);
float max_component(vec3 v);
float smoothmin(float a, float b, float x);

float segment(vec3 p, vec3 a, vec3 b, float r);
float edge(vec3 p, vec3 a, vec3 b);
float cube(vec3 p, vec3 s);
float rhombictriacontahedron(vec3 p, float r);

float quad( vec3 p, vec3 a, vec3 b, vec3 c, vec3 d );
float rtc_edges(vec3 position, float scale);
float rtc_faces(vec3 position, float scale, float depth);
float rtc_vertices(vec3 position, float scale, float radius);

vec3 derivative(in vec3 position, in float range);
float curvature(const in vec3 position , const in float epsilon);

float exp2fog(float depth, float density);
float shadow(vec3 origin, vec3 direction, float mint, float maxt, float k);
float ambient_occlusion(vec3 position, vec3 normal);
vec3 gamma_correction(vec3 color, float brightness, float gamma);

//via http://glslsandbox.com/e#48652.0
float pReflect(inout vec3 p, vec3 planeNormal, float offset) {
    float t = dot(p, planeNormal)+offset;
    if (t < 0.) {
        p = p - (2.*t)*planeNormal;
    }
    return sign(t);
}

float rhombictriacontahedron(vec3 p, float r)
{
    vec3 q = vec3(.30901699437, .5,.80901699437);    
    p = abs(p);    
    return  max(max(max(max(max(p.x, p.y), p.z), dot(p.zxy, q)), dot(p.xyz, q)), dot(p.yzx, q)) - r;
}

float axes(vec3 position, float scale)
{
    float x = edge(position, vec3(0., 0., 0.), vec3(scale, 0., 0.));
    float y = edge(position, vec3(0., 0., 0.), vec3(0., scale, 0.));
    float z = edge(position, vec3(0., 0., 0.), vec3(0., 0., scale));
    
    float tx = min(edge(position - vec3(scale, .125, 0.), vec3(.0, 0., 0.), vec3(-.5, .5, 0.)), edge(position - vec3(scale, .125, 0.), vec3(-.5, 0., 0.), vec3(0., .5, 0.)));
    float ty = min(edge(position - vec3(.625, scale - .5,  0.), vec3(-.25, 0.25, 0.), vec3(-.5, .5, 0.)), edge(position - vec3(.625, scale-.5,  0.), vec3(-.5, 0., 0.), vec3(0., .5, 0.)));    
    float tz = min(min(edge(position - vec3(0.,.125,scale), vec3(.0, 0., 0.), vec3(0., .0, -.5)), edge(position  - vec3(0.,.125,scale), vec3(0., 0., -.5), vec3(0., .5, 0.))),edge(position - vec3(0.,.125,scale), vec3(.0, .5, 0.), vec3(0., .5, -.5)));
    return min(min(min(min(min(x,y), z), tx),ty), tz);
}

float sgn(float x) {
    return (x<0.)?-1.:1.;
}

vec3 sgn(vec3 v)
{
    return vec3(sgn(v.x),sgn(v.x),sgn(v.x));
}

float map(in vec3 position)
{
    g_ray.xyz    = vec3(.5, .5, .5);
    
    float range         = MAX_FLOAT;
    
    vec3 origin    = position;
    float t     = fract(time * .0625) * TAU;
    origin.xz     *= rmat(t);
    origin.yz     *= rmat(t);
        
    vec4 v        = vec4(PHI3, PHI2, PHI, 0.); //this is the shared basis vector set

    float axes    = axes(origin, 6.) - .0125;
    vec3 n         = vec3(.30901699437, .5,.80901699437);    
    

    float f        = max_component(origin);
    
    
    vec3 m        = vec3(1.,1., 1.);
    
    

    float w        = 1.;
    origin        = abs(origin);
    float r        = pow(PHI, 9.);
    for(float i = 0.; i < 7.; i++)
    {
        w         = pReflect(origin, -n, r);
        origin        = abs(origin.zxy);
        r         /= PHI;
        n        = n.zxy;
    }

    float field     = rhombictriacontahedron(origin, PHI3 + PHI3);
    
    
    
    //range        = min(range, axes);

    range        = min(range, field);
    
    
    
    
    g_ray.xyz    = range == axes     ? vec3(1., 1., 1.) : g_ray.xyz + normalize(floor(origin * 512.))*.5;
    
    
    
    
    return range;
}

void main( void ) 
{
    vec2 aspect            = resolution.xy/resolution.yy;
    vec2 uv             = gl_FragCoord.xy/resolution.xy;
    vec2 screen            = (uv - .5) * aspect;
    
    vec2 m                = (mouse-.5) * aspect;
    
    
    float field_of_view        = 1.65;
    
    vec3 w                  = normalize(VIEW_POSITION-VIEW_TARGET);
    vec3 u                  = normalize(cross(w,vec3(0.,1.,0.)));
    vec3 v                  = normalize(cross(u,w));

    vec3 direction             = normalize(screen.x * u + screen.y * v + field_of_view * -w);    
    vec3 origin            = VIEW_POSITION;
    vec3 position            = origin;
    
    
    //sphere trace    
    float minimum_range        = 8./max(resolution.x, resolution.y);
    float max_range            = 2048.;
    float range            = max_range;
    float total_range        = 10.;
    float abberation        = length(abs(direction.z-direction.xy));
    float steps             = 1.;
    const float iterations        = 128.;
    for(float i = 0.; i < iterations; i++)
    {
        if(range > minimum_range && total_range < max_range)
        {
            steps++;
            
            range         = min(map(position), 127.);
            range        *= .95;
            minimum_range    *= 1.05;

            
            total_range    += range;

        
            position     = origin + direction * total_range;    
        }
    }
    
    
    
    //shade
    vec3 background_color         = vec3(1., 1., 1.);
    vec4 light_color        = vec4( .97, .95, .93, 1.);        
    vec3 color             = background_color;
    float glow             = 1./exp2fog(steps, .0125);
    float curvature            = curvature(position, minimum_range);
        
    if(steps < iterations-1. && total_range < max_range)
    {
        vec3 gradient        = derivative(position, 4. * minimum_range);
//        float curvature        = curvature(position, minimum_range);
        
        vec3 surface_direction     = normalize(gradient);
    
        vec3 light_position     = VIEW_POSITION+vec3(-80., 90., -42.);
        vec3 light_direction    = normalize(light_position - position);
        
        float light        = max(dot(surface_direction, light_direction), -.1);
            
        vec3 reflection     = reflect(direction, surface_direction);
        float specular         = pow(clamp(dot(reflection, light_direction), 0.0, 1.0), 12.0);
        float bounce         = pow(clamp(dot(-light_direction, reflect(direction, surface_direction)), 0.0, 1.0), 4.0);
        
        float fog         = exp2fog(max_range/total_range, .35);
        
        
        color            *= curvature;        
        color             = g_ray.xyz * light_color.xyz * light_color.w;

        color             = color + color + light * .9 + color * specular * .5 + specular + bounce * .95;
        color             *= ambient_occlusion(position, surface_direction) * .75;
        color             *= .125 + .95 * shadow(position, light_direction, .1, 512., 1.5);
        color             += fog * .25 + log(glow) * (1.-g_ray.xyz) * .25;
        
        
    }
    else
    {
        color            = vec3(1., 1., 1.);
    }
    
    color                = gamma_correction(color, BRIGHTNESS, GAMMA);
    
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

float smoothmin(float a, float b, float x)
{
    return -(log(exp(x*-a)+exp(x*-b))/x);
}

float max_component(vec3 v)
{
    return max(max(v.x, v.y), v.z);
}

vec3 hsv(in float h, in float s, in float v)
{
    return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
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
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
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
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);
    return length(pa - ba * h);
}

float curvature(const in vec3 position , const in float epsilon) //via nimitz
{
    vec2 offset = vec2(epsilon, -epsilon);
    vec4 simplex = vec4(0.);
    simplex.x = map(position + offset.xyy);
    simplex.y = map(position + offset.yyx);
    simplex.z = map(position + offset.yxy );
    simplex.w = map(position + offset.xxx);
    return .2/epsilon*(dot(simplex, vec4(1.)) - 4. * map(position));
}

vec3 derivative(in vec3 position, in float range)
{
    vec2 offset     = vec2(0., range);
    vec3 gradient    = vec3(0.);
    gradient.x        = map(position+offset.yxx)-map(position-offset.yxx);
    gradient.y        = map(position+offset.xyx)-map(position-offset.xyx);
    gradient.z        = map(position+offset.xxy)-map(position-offset.xxy);
    return gradient;
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
    float h = 0.0;
    for (int i = 0; i < 32; i++) 
    {
        if (t > maxt)            
            continue;
            h     = map(origin + direction * t);
            sh     = smoothmin(sh, k * h/t, 8.0);
            t     += clamp( h, 0.01, 0.5 );        
    }
    return clamp(sh, 0., 1.);
}

float ambient_occlusion(vec3 position, vec3 normal)
{       
    float delta     = 0.125;
    float occlusion = 0.0;
    float t     = .2;
    for (float i = 1.; i <= 9.; i++)
    {
        occlusion    += t * (i * delta - map(position + normal * delta * i));
        t         *= .5;
    }
     
    const float k     = 4.0;
    return 1.0 - clamp(k * occlusion, 0., 1.);
}

vec3 gamma_correction(vec3 color, float brightness, float gamma)
{
    return pow(color * brightness, vec3(1., 1., 1.)/gamma);
}     
