#version 420

// original https://www.shadertoy.com/view/wty3zh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// sphinx
// note: compilation error corrected, but white part is still wrong ???

// ?
// thank you
// here is a bunny
// which white part?

// Bugs fixed ?
// i fixed it ;) you have to change every pow(x,a) to pow(abs(x),a), because nvidia cards dont allow negative powers ^^

#define SURFACE_THRESHOLD     .001
#define FAR_PLANE        5.

#define VIEW_POSITION        vec3(0., -.15, 1.5)        
#define VIEW_TARGET        vec3(0., 0., -1.);

#define LIGHT_POSITION        vec3(128., 64., 128.)// * vec3(sin(time*.125), 1., cos(time*.125))
#define PI             (4.*atan(1.))

struct ray
{
    vec3 origin;
    vec3 position;
    vec3 direction;
    float range;
    float total_range;
    float edge;
    float id;
};

    
struct light
{
    vec3 position;
    vec3 direction;
    vec3 color;    
};

struct material
{
    float roughness;
    float index;
    vec3 normal;
    vec3 color;
};

mat2 rmat(in float t)
{
    float c = cos(t);
    float s = sin(t);
    return mat2(c, s, -s, c);
}

mat3 rmat(in vec3 r)
{
    vec3 a = vec3(cos(r.x)*cos(r.y),sin(r.y),sin(r.x)*cos(r.y));
    
    float c = cos(r.z);
    float s = sin(r.z);
    vec3 as  = a*s;
    vec3 ac  = a*a*(1.- c);
    vec3 ad  = a.yzx*a.zxy*(1.-c);
    mat3 rot = mat3(
        c    + ac.x, 
        ad.z - as.z, 
            ad.y + as.y,
        ad.z + as.z, 
        c    + ac.y, 
        ad.x - as.x,
        ad.y - as.y, 
        ad.x + as.x, 
        c    + ac.z);
    return rot;    
}

float sphere(vec3 p, float r)
{
    return length(p)-r;    
}
    
float smoothmax(float a, float b, float k)
{
    return log(exp(k*a)+exp(k*b))/k;
}

float smoothmin(float a, float b, float k)
{
    return -(log(exp(k*-a)+exp(k*-b))/k);
}

vec3 rotx(vec3 p, float a)
{
    float s = sin(a);
    float c = cos(a);
    return vec3(p.x, c*p.y - s*p.z, s*p.y + c*p.z);
}

float cube(vec3 p,vec3 s)
{
    vec3 d = (abs(p) - s);
      return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float bunny(vec3 p)
{
        float b = FAR_PLANE;
    p *= .75;
    p.y += .5;
    p.z += .5;
    p.x = abs(p.x)+.5;
    

       
        vec3 bp01 = p - vec3(.5, 0.14, .16);
        vec3 bp00 = p - vec3(.5, 0.18, .26);
        vec3 bp0 = p - vec3(.5, 0.25, .25);
        vec3 bp2 = p - vec3(.5, 0.25, .35);
        vec3 bp1 = p - vec3(.5, 0.20, .6);
        vec3 bp3 = p - vec3(.5, 0.25, .75);
        vec3 bp4 = p - vec3(.5, 0.2, .84);
        vec3 bp5 = p - vec3(.58, 0.25, .34)* vec3(1., .8, 1.);
        vec3 bp6 = (p - vec3(.6, 0.12, .5)) * vec3(2., 1.8, .8);
        vec3 bp7 = (p - vec3(.6, 0.1, .55)) ;
        vec3 bp8 = (p - vec3(.56, 0.08, .7)) * vec3(1., 1., .35);
        vec3 bp9 = (p - vec3(.56, 0.34, .62));
        vec3 bp10 = (p - vec3(.56, 0.25, .86)) * vec3(1., 1., .35);
        vec3 bp11 = (p - vec3(.56, 0.25, .82)) * vec3(.8, 1.1, .85);;
        vec3 bp12 = (p - vec3(.5, 0.16, .9));
    
        bp9     = rotx(bp9, -1.9) * vec3(.8, .15, .5);;
        
        float b01 = sphere(bp01, .015);
        float b00 = sphere(bp00, .05);
        float b0  = sphere(bp0, .05);
        float b1  = sphere(bp1, .07);
        float b2  = sphere(bp2, .15);
        float b3  = sphere(bp3, .085);
        float b4  = sphere(bp4, .055);
        float b5  = sphere(bp5, .12);
        float b6  = sphere(bp6, .08);
        float b7  = sphere(bp7, .03);
        float b8  = sphere(bp8, .02);
        float b9  = sphere(bp9, .02);
        float b10 = sphere(bp10, .01);
        float b11 = sphere(bp11, .012);
        float b12 = sphere(bp12, .005);
    
        b00  = smoothmin(b00,   b01, 128.);   //torso
        b0   = smoothmin(b00,   b0, 32.);     //torso
        b    = smoothmin(b0,    b1, 5.);      //torso
        b    = smoothmin(b,     b2, 35.);
        b    = smoothmin(b,     b3, 28.);
        
        b    = smoothmin(b,     b4, 27.);    //head

        b6 = smoothmin(b5, b6, 32.0);  //back leg
        b7 = smoothmin(b6, b7, 96.0);  
        b  = smoothmin( b, b7, 252.0);  
    
        b  = smoothmin(b, b8, 36.0);  //front legs
    
        b  = smoothmin(b, b9, 192.0);  //ears
    
        b  = smoothmax(b, -b10, 64.0);  //eye
        b  = smoothmin(b,  b11, 256.0);  
    
        b  = smoothmin(b,  b11, 256.0);  //nose
        b  = smoothmax(b,  -b12, 64.0); 
    
  
    return b;
}

vec2 map(in vec3 position)
{
    float fx         = abs(fract(position.x*2.)-.5);
    float fy         = abs(fract(position.z*2.)-.5);
    float f         = position.y + max(max(fx, fy)*.2, .095)+.5;
    
    position.xz         *= rmat(time*.125);
    
    float b         = bunny(position);

    float id         = b < f ? 1. : 2.;
    
    return vec2(min(f,b), id);
}

vec3 derive(const in vec3 position, const in float range)
{
    vec2 offset     = vec2(0., range);
    vec3 normal     = vec3(0.);
    normal.x        = map(position+offset.yxx).x-map(position-offset.yxx).x;
    normal.y        = map(position+offset.xyx).x-map(position-offset.xyx).x;
    normal.z        = map(position+offset.xxy).x-map(position-offset.xxy).x;
    return normalize(normal);
}

    
void emit(inout ray r)
{
    float minimum_range    = SURFACE_THRESHOLD;
    float closest_range    = FAR_PLANE;
    
    for(int i = 0; i < 256; i++)
    {
        vec2 scene    = map(r.position);
        r.range     = scene.x;
        r.id        = scene.y;
        r.range     = r.range < 0. ? r.range - r.range * .5 : r.range;
            
        r.range         *= .6;        //slow down ray
        minimum_range    *= 1.0125;    //relax surface
        
        r.total_range    += r.range;
        
        r.position     = r.origin + r.direction * r.total_range;    
        
        if(closest_range > r.range)
        {
            r.edge += .001225;    
        }
        
        closest_range    = min(closest_range, abs(r.range));
        
        if(r.range < minimum_range || r.total_range > FAR_PLANE)
        {
            break;    
        }
    }    
}

float fresnel(const in float i, const in float ndl)
{   
    return i + (1.-i) * pow(abs(1.-ndl), 5.0);
}

float geometry(in float i, in float ndl, in float ndv)
{
    ndl             = max(ndl, 0.);
    ndv             = max(ndv, 0.);
    float k         = i * sqrt(2./PI);
    float ik        = 1. - k;
    return (ndl / (ndl * ik + k)) * ( ndv / (ndv * ik + k) );
}

float distribution(const in float r, const in float ndh)
{  
    float m     = 2./(r*r) - 1.;
    return (m+r)*pow(abs(ndh), m)*.5;
}

float shadow(const in vec3 position, const in vec3 direction)
{
    float exposure     = 1.0;
    float penumbra     = 0.15;
    float umbra    = .00125;
        for(int i = 1; i < 8; ++i)
        {
        float range    = map(position + direction * penumbra).x;
        
        if ( range < umbra) return umbra;
        
        exposure     = min( exposure, 5. * range / penumbra);
        penumbra     += range;
    }
    
    return exposure;
}

float occlusion(in vec3 p, in vec3 n )
{
      float occlusion = 0.;
      float penumbra     = .125;
      for ( int i=0; i < 8; i++ )
      {
          float radius     = .125 * penumbra * float(i);
            float range     = map(n * radius + p).x - radius;
            occlusion     -= penumbra * range;
      }
      return 1.0 - 3.0 * occlusion;
}

//adapted from this nice sun here: http://glslsandbox.com/e#28403.2
vec3 sky(in vec3 direction, in vec3 light_direction)
{ 
    float yd     = min(-direction.y, 0.);

    direction.y     = max(direction.y, 0.)+.05;
    
    vec3 col     = vec3(0.);
    
    col += vec3(.4, .4 - exp( -direction.y * 20.) * .3, .0) * exp(-direction.y * 9.); // Red / Green 
    col += vec3(.3, .5, .6) * (1. - exp(-direction.y * 8.)) * exp(-direction.y * .9) ; // Blue
    
    col = mix(col, vec3(.4),  .45-exp(yd*7.)) * .65; // Fog
    
    vec3 sun_color = vec3(1., .66, .25);
    col += pow(dot(abs(direction), light_direction), 15. ) * sun_color * .35;
    col += pow(dot(abs(direction), light_direction), 150.0) *.05;
    
        return clamp(pow(abs(col), vec3(1.1))*2., 0., 1.);
}

vec4 shade( ray r,  light l,  material m)
{
    vec3 half_direction         = normalize(r.direction-l.direction);
    float half_normal           = dot(half_direction, m.normal);
        
    if(r.total_range < FAR_PLANE)
    {    
        //exposure coefficients
        float light_exposure        = dot(m.normal,  l.direction);   
        float view_exposure         = dot(m.normal, -r.direction);  
        
        //microfacet lighting components
        float d                     = distribution(m.roughness, half_normal);
        float g                     = geometry(m.roughness, light_exposure, view_exposure);
        float f                     = fresnel(m.index, light_exposure);
        float n                     = clamp(1. - fresnel(f, view_exposure), 0., 1.);
        
        //bidrectional reflective distribution function
        float brdf                  = n * (g*d*f)/(view_exposure*light_exposure*4.);        
        
        float shadows            = shadow(r.position, l.direction);
        shadows                = clamp(shadows, .125, 1.);

        float occlusions        = occlusion(r.position, m.normal);
        occlusions            = clamp(occlusions, .05, 1.);
    
        vec3 color            = m.color * n + m.color * l.color + brdf * l.color;
        color                 *= shadows * occlusions;
        color                 += exp(.025 * r.total_range) * l.color * .25;
        return vec4(color, occlusions * shadows);
    }
    else
    {
        return vec4(sky(r.direction, l.direction), 1.) * 1.5 + vec4(exp(-r.total_range));    
    }
}

vec3 hsv(float h,float s,float v)
{
    return mix(vec3(1.),clamp((abs(fract(h+vec3(3.,2.,1.)/3.)*6.-3.)-1.),0.,1.),s)*v;
}

vec3 facet(vec3 normal, vec3 position, float roughness)
{
    roughness *= .05;
    return normal;
}

vec3 cartesian_to_spherical(vec3 c)
{
    vec3 s;
    s.x = length(c);
    s.y = atan(c.z / c.x);
    s.z = asin(c.y / s.x);
    return s;
}

void assign_material(in ray r, out material m)
{
    m=material(0., 0., vec3(0.), vec3(0.));
    
    if(r.id == 0.)
    {
        m.roughness     = .5;
        m.index     = .5;
        vec3 p        = fract(r.position);
        m.color     += float(p.x < .5 ^^ p.y < .5 ^^ p.z < .5) + .25;
    }
    else if(r.id == 1.)
    {
        m.roughness     = .3125;
        m.index        = .75;
        m.color        = vec3(.5);
    }
    else if(r.id == 2.)
    {
        m.roughness     = .5;
        m.index     = .5;
        vec3 p        = fract(r.position);
        m.color     += float(p.x < .5 ^^ p.y < .5 ^^ p.z < .5) * .5 + .125;
    }
    
    m.normal = derive(r.position, SURFACE_THRESHOLD);
}

void main(void)
{
    vec2 aspect        = resolution.xy/resolution.yy;
    
    vec2 uv         = gl_FragCoord.xy/resolution.xy;
    uv                 = uv * 2. - 1.;
        uv               *= aspect;
       
    //view
    ray r;
    r.range         = 0.;
    r.total_range        = 0.;
    r.edge            = 0.;
    r.origin        = VIEW_POSITION;
    r.position        = r.origin;
    
    vec3 target        = VIEW_TARGET;
    float fov        = 2.5;
    vec3 w             = normalize(target-r.position);
        vec3 u             = normalize(cross(w, vec3(0.,1.,0.)));
        vec3 v             = normalize(cross(u,w));
    
        mat3 view         = mat3(u.x, v.x, w.x, 
                       u.y, v.y, w.y, 
                       u.z, v.z, w.z);

//    uv.y             = (mouse.y-.5+uv.y);
    uv.y             -= .25;
    r.direction          = normalize(uv.x * u + uv.y * v + fov * w) * view;
    r.direction.xz        *= rmat(PI);
    //r.direction.xz        *= rmat(.5 * mouse.x * PI + PI * .75);
    
    //trace
    emit(r);
    
    //shade        
    material m;
    assign_material(r, m);
        
    light l;
    l.position         = LIGHT_POSITION;
    vec4 color        = vec4(0.);    
    
    //reflections
    if(r.total_range < FAR_PLANE)
    {
        //reflection
        ray rr            = r;
        rr.position        = rr.position + m.normal * SURFACE_THRESHOLD * 1.5;
        rr.origin        = rr.position;
        rr.direction         = normalize(reflect(r.direction, m.normal));

        rr.range        = 0.;
        rr.total_range        = 0.;

        emit(rr);

        material rm;
        assign_material(rr, rm);
        l.direction        = normalize(l.position - rr.position);
        vec3 rsky        = sky(reflect(rr.direction, -rm.normal), l.direction);
        l.color         = rsky;
        vec4 reflection        = shade(rr, l, rm);

        l.direction        = normalize(l.position - r.position);
        vec3 skyVec        = sky(reflect(r.direction, m.normal), l.direction);
        l.color            = clamp(mix(skyVec, reflection.xyz*reflection.w, m.index), 0., 1.);
        
        color             = shade(r, l, m);
        color             = mix(max(color, reflection), color, clamp(1.-m.index + m.roughness, 0., 1.)) 
                              + vec4(.95 * r.edge * skyVec, 0.) * color.w;
    }
    else
    {
        r.position     = r.origin * r.direction * FAR_PLANE;    
        l.direction    = normalize(l.position - r.position);
        l.color        = sky(r.direction, l.direction);
        color.xyz    += l.color*1.25+2.5/(r.position.y+1.35)*.125;
    }
    
    color     = pow(color*.85, vec4(1.6));
    color.w = 1.;
    glFragColor         = color;
}

