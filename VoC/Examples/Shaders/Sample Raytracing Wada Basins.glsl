#version 420

uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int raytraceDepth = 50;
const int samplepixels=2;
float sqrsamplepixels=4.0;

vec3 org=vec3(0.0,0.0,-1.25);
vec2 pixel=-1.0+2.0*gl_FragCoord.xy/resolution.xy;
vec3 lightPoint = vec3(0.0,0.0,25);
//vec3 lightPoint = vec3(0.0,0.0,0.0);

// compute ray origin and direction
float asp = resolution.x / resolution.y;
vec3 dir = normalize(vec3(asp*pixel.x, pixel.y, -1.5));

vec4 finalcol;
int superx,supery;
float stepx=2.0/resolution.x/float(samplepixels);
float stepy=2.0/resolution.y/float(samplepixels);

struct Ray
{
    vec3 org;
    vec3 dir;
};
struct Sphere
{
    vec3 c;
    float r;
    vec3 col;
};

struct Intersection
{
    float t;
    vec3 p;     // hit point
    vec3 n;     // normal
    int hit;
    vec3 col;
};

void shpere_intersect(Sphere s,  Ray ray, inout Intersection isect)
{
    // rs = ray.org - sphere.c
    vec3 rs = ray.org - s.c;
    float B = dot(rs, ray.dir);
    float C = dot(rs, rs) - (s.r * s.r);
    float D = B * B - C;

    if (D > 0.0)
    {
        float t = -B - sqrt(D);
        if ( (t > 0.0) && (t < isect.t) )
        {
            isect.t = t;
            isect.hit = 1;

            // calculate normal.
            vec3 p = vec3(ray.org.x + ray.dir.x * t,
                          ray.org.y + ray.dir.y * t,
                          ray.org.z + ray.dir.z * t);
            vec3 n = p - s.c;
            n = normalize(n);
            isect.n = n;
            isect.p = p;
            isect.col = s.col;
        }
    }
}

Sphere sphere[5];
void Intersect(Ray r, inout Intersection i)
{
    for (int c = 0; c < 5; c++)
    {
        shpere_intersect(sphere[c], r, i);
    }
}

vec3 computeLightShadow(in Intersection isect)
{
    int i, j;
    int ntheta = 16;
    int nphi   = 16;
    float eps  = 0.0001;

    // Slightly move ray org towards ray dir to avoid numerical probrem.
    vec3 p = vec3(isect.p.x + eps * isect.n.x,
                  isect.p.y + eps * isect.n.y,
                  isect.p.z + eps * isect.n.z);

    Ray ray;
    ray.org = p;
    ray.dir = normalize(lightPoint - p);

    Intersection lisect;
    lisect.hit = 0;
    lisect.t = 1.0e+30;
    lisect.n = lisect.p = lisect.col = vec3(0, 0, 0);
    Intersect(ray, lisect);
    if (lisect.hit != 0)
        return vec3(0.0,0.0,0.0);
    else
    {
        float shade = max(0.0, dot(isect.n, ray.dir));
        shade = pow(shade,3.0) + shade * 0.5;
        return vec3(shade,shade,shade);
    }
    
}

void main()
{
    sphere[0].c   = vec3(-0.5,-0.5,-2.0);
    sphere[0].r   = 0.5;
    sphere[0].col = vec3(1.0,0.3,0.3);
    //sphere[0].col = vec3(1.0,1.0,1.0);

    sphere[1].c   = vec3(0.5,-0.5,-2.0);
    sphere[1].r   = 0.5;
    sphere[1].col = vec3(0.3,1,0.3);
    //sphere[1].col = vec3(1.0,1.0,1.0);

    sphere[2].c   = vec3(-0.5,0.5,-2.0);
    sphere[2].r   = 0.5;
    sphere[2].col = vec3(1.0,1.0,0.3);
    //sphere[2].col = vec3(1.0,1.0,1.0);
    
    sphere[3].c   = vec3(0.5,0.5,-2.0);
    sphere[3].r   = 0.5;
    sphere[3].col = vec3(0.3,0.3,1);
    
    sphere[4].c   = vec3(0.0,0.0,-2.0);
    sphere[4].r   = 0.2;
    sphere[4].col = vec3(0.3,0.3,0.3);

    finalcol=vec4(0,0,0,0);

    for (supery=0;supery<samplepixels;supery++)
    {
    for (superx=0;superx<samplepixels;superx++)
    {

    Ray r;
    r.org = org;
    r.dir=dir;
    r.dir.x+=stepx*float(superx);
    r.dir.y+=stepy*float(supery);
    r.dir = normalize(r.dir);
    vec4 col = vec4(0,0,0,1);
    float eps  = 0.0001;
    vec3 bcol = vec3(1,1,1);
    for (int j = 0; j < raytraceDepth; j++)
    {
        Intersection i;
        i.hit = 0;
        i.t = 1.0e+30;
        i.n = i.p = i.col = vec3(0, 0, 0);
            
        Intersect(r, i);
        if (i.hit != 0)
        {
            col.rgb += bcol*i.col*computeLightShadow(i);
            bcol *= i.col;
        }
        else
        {
            break;
        }
                
        r.org = vec3(i.p.x + eps * i.n.x,
                     i.p.y + eps * i.n.y,
                     i.p.z + eps * i.n.z);
        r.dir = reflect(r.dir, vec3(i.n.x, i.n.y, i.n.z));
    }
    
    finalcol+=col;
    }
    }
    
    //glFragColor = col*0.3;
    glFragColor=vec4(finalcol/sqrsamplepixels);
    glFragColor.a =1.0;
}
