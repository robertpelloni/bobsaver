#version 420

uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;
uniform vec2 resolution;

out vec4 glFragColor;

//this is some sweet laplatian by an unknown author 
//terrain + mods == sphinx

vec4 laplacian();
vec2 format_to_screen( vec2 p );
float value_noise(in vec2 uv);
float fbm(float a, float f, vec2 uv, const int it);
float  map(vec2 position);
vec2 derive(vec2 position, float offset);
vec2 derive_prior(vec2 uv, float offset);
float smoothmin(float a, float b, float x);

#define CELERITY .9
#define ENERGY .125

#define TERRAIN_ITERATIONS 6

void main( void ) {

    vec2 uv         = gl_FragCoord.xy/resolution;
    
    vec2 p             = format_to_screen(uv);
    vec2 m             = format_to_screen(mouse);
    
    float terrain         = map(p);

    float collision     = float(terrain > .55);
    
    
    //previous pixel
    vec4 c             = (2.0 * texture2D(backbuffer, uv) - 1.0);;
        
        
    //weighted neighbor sample    
    vec4 l             = laplacian();
        
    

    //energy conservation
    c.zw             = mix(c.zw, c.wz, abs(l.zw-l.wz)*-ENERGY) - collision;
    
    
    //wave energy
    float prior        = c.w - l.z * CELERITY;
    float current        = c.z + (c.w - l.z) * CELERITY;
    
    
    
    vec4 result         = vec4(0., terrain * terrain * collision, current, prior);
    
    
    //light
    vec2 light_pos        = vec2(2.);
    vec2 light_dir        = vec2(-.71);
    float light_dist     = distance(p, m);
    
    vec2 terrain_normal    = derive(p, smoothmin(terrain, (1. + terrain) * terrain, 1.25));
    vec2 fluid_normal    = derive_prior(uv, .2+current);    
    
    vec2 normal         = mix(fluid_normal, terrain_normal, collision);
    normal            = normalize(normal);
    
    float light        = max(-.5, dot(normal, light_dir)); 
    

    
    float r = 0.25;
    float spec = 2./(r*r) - 2.;
    spec = (spec + 2.) * pow(max(dot(normal, normalize(vec2(0.71, .71) + light_pos)), 0.), spec) / 6.28;
    
    if(terrain > 0.55)
    {
        result.xyz         = vec3(.8*terrain*pow(terrain,1.96), .65-terrain*terrain*.5, 0.7*terrain);
        result.xyz        += float(terrain<cos(terrain)) * terrain * abs(fract(terrain - pow(terrain, 8.) * 32.) -.5) * .125;
        result.xyz        =  clamp(result.xyz * 2. * terrain * terrain, 0., 1.);
        result.xyz         *= .125 + result.xyz + result.xyz * light * collision + light * .125;
    }
    
    result.xy += (1.-collision) * (spec * .05);
    
    
    //emit waves from mouse cursor
    if (length(p-m)<.02+cos(time*32.)*.0025)
    {    
        result.xyz = vec3(1., c.y*.5, 0.0);
    }

    //normalize to 0-1
    result.zw = result.zw * .5 + .5;

    //mask out terrain
    result.zw -= float(collision>0.);
    
    //initialize at median
    result.zw = result.w == 0. ? vec2(.5) : result.zw;
        
    //reset on mouse in corner
    result *= float( mouse.x + mouse.y > .02 );
    
    glFragColor = result;
}

vec2 format_to_screen( vec2 p )
{
    p       = p * 2. - 1.;
    p.x     *= resolution.x / resolution.y;
    return p;
}

vec4 laplacian()
{
    vec2 uv = gl_FragCoord.xy/resolution;
    
    vec2 neighbor_offset[8]; 
        neighbor_offset[0] = vec2(  0., -1. ); //*.2
        neighbor_offset[1] = vec2( -1., -1. ); //*.05
        neighbor_offset[2] = vec2( -1.,  0. ); //*.2
    neighbor_offset[3] = vec2( -1.,  1. ); //*.05
    neighbor_offset[4] = vec2(  0.,  1. ); //*.2
    neighbor_offset[5] = vec2(  1.,  1. ); //*.05
    neighbor_offset[6] = vec2(  1.,  0. ); //*.2
    neighbor_offset[7] = vec2(  1., -1. ); //*.05
    
    vec4 o = (2.0 * texture2D(backbuffer, uv) - 1.0);
    
    for(int i = 0; i < 8; i++)
    {
        float weight         = mod(float(i), 2.) == 1. ? .2 : .05;
        vec2 neighbor_uv     = fract((gl_FragCoord.xy + neighbor_offset[i])/resolution);
        o                 -= weight * (2. * texture2D(backbuffer, neighbor_uv) - 1.);
    }

    return o;
}

float value_noise(in vec2 uv) 
{
    const float k = 257.;
    vec4 l  = vec4(floor(uv),fract(uv));
    float u = l.x + l.y * k;
    vec4 v  = vec4(u, u+1.,u+k, u+k+1.);
    v       = fract(fract(v*1.23456789)*9.18273645*v);
    l.zw    = l.zw*l.zw*(3.-2.*l.zw);
    l.x     = mix(v.x, v.y, l.z);
    l.y     = mix(v.z, v.w, l.z);
    return    mix(l.x, l.y, l.w);
}

//fractal brownian motion
float fbm(float a, float f, vec2 uv, const int it)
{
    float n = 0.;
    float t = .71;
    float c = cos(t);
    float s = sin(t);
        
    uv = (32.5 + uv) * mat2(c, s, -s, c);
    
    vec2 p = vec2(.3, .7);
    for(int i = 0; i < 32; i++)
    {
                if(i<it)
        {
            n += value_noise(uv*f+p)*a;
        
                    a *= .5;
            f *= 2.;
        }
        else
        {
            break;
        }
    }
    return n;
}

float smoothmin(float a, float b, float x)
{
    return -(log(exp(x*-a)+exp(x*-b))/x);
}

float  map(vec2 position)
{
    float n = fbm(.5, 2., position, TERRAIN_ITERATIONS);
    return n;
}

//partial derivitive of map function (the surface normal)
vec2 derive(vec2 position, float offset)
{
    vec2 epsilon = vec2(offset, 0.);
    vec2 normal  = vec2(0.);
    normal.x     = map( position + epsilon.xy ) - map( position - epsilon.xy );
    normal.y     = map( position + epsilon.yx ) - map( position - epsilon.yx );
    return normalize(normal);
}

vec2 derive_prior(vec2 uv, float offset)
{
    vec3 epsilon = vec3(offset + 1.5, offset + 1.5, 0.) * vec3(1./resolution, 1.);
    vec2 normal  = vec2(0.);
    normal.x     = texture2D(backbuffer, uv + epsilon.xz ).z - texture2D(backbuffer, uv - epsilon.xz ).w;
    normal.y     = texture2D(backbuffer, uv + epsilon.zy ).z - texture2D(backbuffer, uv - epsilon.zy ).w;
    return normalize(normal);
}
