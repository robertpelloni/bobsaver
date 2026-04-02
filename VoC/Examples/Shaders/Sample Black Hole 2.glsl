#version 420

// original https://www.shadertoy.com/view/3syXzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float G = 6.67408e-11;
const float mass = 1.0e10;
const vec3 bhpos = vec3(0, 0, 0); 
const float planetRadius = 4.0;
const vec3 planetPosition = vec3(0, 0, 20.0);
const float sdc = 300.0;
const float hsdc = 150.0;
const float bhrad = 2.0 * G * mass;

struct RayHit
{
    vec3 pos;
    float dist;
};

// Noise 3D
mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float fbm( vec3 p )
{
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p );
    return f;
}

// SDFS
float sphere(vec3 x, vec3 c, float r)
{
    return length(x-c)-r;             
}
float sdDisc( vec3 position, vec3 n, float r )
{
    position = abs(position);
    float dl = length(position) - r;
    float d = dot(position, n);
    return max(dl, d);
}

// Xy axis rotation
vec3 xzRotate(vec3 position, float theta)
{
    float dx = position.x * cos(theta) - position.z * sin(theta);
    float dz = position.x * sin(theta) + position.z * cos(theta);
    return vec3(dx, position.y, dz);
}

// Planet "Jet"
float map(vec3 position)
{
    float theta = time * 0.25;
    position = xzRotate(position, theta);
    vec3 spos = position - planetPosition;
    
    float s1 = (fbm(position) + fbm(position*2.0) * 0.25) * 0.75;
    return sphere(spos, vec3(0), planetRadius) + s1;
}
float getao (vec3 pos, vec3 normal)
{
    return clamp(map(pos+normal*0.2)/0.2, 0.0, 1.0);
}
vec3 getnormal (vec3 p)
{
 const float eps = 0.001;
 
 return normalize
 ( vec3
     ( map(p + vec3(eps, 0, 0) ) - map(p - vec3(eps, 0, 0)),
       map(p + vec3(0, eps, 0) ) - map(p - vec3(0, eps, 0)),
      map(p + vec3(0, 0, eps) ) - map(p - vec3(0, 0, eps))
     )
 );
}

// Blackhole (BH)
float blackhole(vec3 position)
{
    return distance(position, bhpos) - 1.0;
}
vec3 holefeild (vec3 p)
{
 const float eps = 0.001;
 
 return normalize
 ( vec3
     ( blackhole(p + vec3(eps, 0, 0) ) - blackhole(p - vec3(eps, 0, 0)),
       blackhole(p + vec3(0, eps, 0) ) - blackhole(p - vec3(0, eps, 0)),
      blackhole(p + vec3(0, 0, eps) ) - blackhole(p - vec3(0, 0, eps))
     )
 );
}
float calcGrav(float r, float m)
{
    return G * m/(r * r);
}

// Ray march
RayHit marchDisc(vec3 ori, vec3 dir)
{
    vec3 pos = ori;
    for(int i = 0; i < 250; ++i)
    {
        float bh = blackhole(pos); //get bh distance
        if(bh <= bhrad) //check if we are under the schwarzchildradius
            return RayHit(vec3(1.0), 0.0);
        vec3 bhdir = holefeild(pos); //get the normal in space towards the BH
        float grav = calcGrav(bh, mass); //calc the gavitation at a point
        
        float dd = sdDisc(pos, vec3(0, 1.0, 0), 14.0); //make acceleration disc
        
           dir = normalize(dir - bhdir * grav);
        pos += dir * min((bh - bhrad), dd); //get new position with BH gravity bending
        if(dd < 0.001) //check if we hit 
            return RayHit(pos, dd);
        if(dd > 120.0)
            return RayHit(vec3(0.0), 0.0);
    }
    return RayHit(vec3(0.0), 0.0);
}
RayHit marchPlanet(vec3 ori, vec3 dir)
{
    vec3 pos = ori;
    float dmin = 1.0;
    for(int i = 0; i < 250; ++i)
    {
        float bh = blackhole(pos); //get bh distance
        if(bh <= bhrad) //check if we are under the schwarzchildradius
            return RayHit(vec3(1.0, dmin, float(i)), 0.0);
        vec3 bhdir = holefeild(pos); //get the normal in space towards the BH
        float grav = calcGrav(bh, mass); //calc the gavitation at a point
        
        float cs = map(pos);
        dmin = min(dmin, cs);
        
           dir = normalize(dir - bhdir * grav);
        pos += dir * min((bh - bhrad), cs); //get new position with BH gravity bending
        if(cs < 0.001) //check if we hit 
            return RayHit(pos, cs);
        if(cs > 120.0)
            return RayHit(vec3(0.0, dmin, float(i)), 0.0);
    }
    return RayHit(vec3(0.0), 0.0);
}
RayHit bhwarp(vec3 ori, vec3 dir)
{
    vec3 pos = ori;
    for(int i = 0; i < 10; ++i)
    {
        float bh = blackhole(pos); //get bh distance
        if(bh <= bhrad) //check if we are under the schwarzchildradius
            return RayHit(vec3(0.0), bh);
        vec3 bhdir = holefeild(pos); //get the normal in space towards the BH
        float grav = calcGrav(bh, mass); //calc the gavitation at a point
        
           dir = normalize(dir - bhdir * grav);
        pos += dir * (bh - bhrad); //get new position with BH gravity bending
    }
    return RayHit(dir, 0.0);
}

// Night sky
float nightsky(vec3 dir)
{
    return noise(dir * 500.0) > 0.9 ? 0.65 : 0.0;
}

//ray marching view stuff
vec3 rayDirection(float fieldOfView, vec2 size) {
    vec2 xy = gl_FragCoord.xy - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}
mat4 viewMatrix(vec3 eye, vec3 center, vec3 up) {
    // Based on gluLookAt man page
    vec3 f = normalize(center - eye);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}

void main(void)
{
    vec3 viewDir = rayDirection(45.0, resolution.xy);
    vec3 eye = vec3(40.0, 10.0, 40.0);
    mat4 viewToWorld = viewMatrix(eye, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    vec3 normal, color;
    
    // Ray march the scene
    RayHit hitDisc = marchDisc(eye, worldDir);
    RayHit hitPlanet = marchPlanet(eye, worldDir);
    if(hitDisc.dist != 0.0)
    {
        float distinv = 1.0/(length(hitDisc.pos.xz) - 0.5); 
        float distinv2 = 2.0 * distinv * distinv * distinv;
        RayHit warp = bhwarp(eye, worldDir);
        vec3 sky = vec3(nightsky(warp.pos));
        vec3 cdist = vec3(sdc, hsdc, hsdc);
        vec3 disc = abs(fbm(xzRotate(hitDisc.pos, time * distinv * 5.0))) * cdist;
        color = disc * distinv2 + sky * (1.0-distinv2);
    }
    if(hitPlanet.dist != 0.0)
    {
        float theta = time * 0.25;
        vec3 position = xzRotate(planetPosition, theta);
        vec3 planetPos = position - planetPosition;
        float angle = dot(planetPos, vec3(1.0, 0.0, -1.0));
        normal = getnormal(hitPlanet.pos);
        float ao = max(getao(hitPlanet.pos, normal), 0.1);
        if(angle > 0.0) //dumb transparancy ordering
            color += 0.8*vec3(1.0, 1.0, 1.0) * ao * max(dot(normal, normalize(bhpos - hitPlanet.pos)), 0.2);
        else
            color = 0.8*vec3(1.0, 1.0, 1.0) * ao * max(dot(normal, normalize(bhpos - hitPlanet.pos)), 0.2);
    }
    if(hitDisc.dist == 0.0 && hitPlanet.dist == 0.0 && hitPlanet.pos.x == 0.0)
    {
        RayHit warp = bhwarp(eye, worldDir);
        color = vec3(nightsky(warp.pos));
    }
    if(hitPlanet.pos.y < 1.0 || hitPlanet.dist != 0.0) //fake atmosphere
    {
        float dist = hitPlanet.dist != 0.0 ? abs(hitPlanet.dist) : hitPlanet.pos.y;
        dist = 0.5*(2.0-(dist+1.0));
        float redshift = 0.5*(2.0-((hitPlanet.pos.z/250.0)+1.0));
        redshift *= redshift * 2.0;
        if(hitPlanet.dist != 0.0)
            color += 0.2*vec3(0.25, dist*(redshift * 1.5), dist*redshift * 1.5);
        else
            color += 0.7*vec3(dist*(1.0-redshift), dist*(redshift * 1.5), dist*redshift * 1.5);
    }
    // Output to screen
    glFragColor = vec4(color,1.0);
}
