#version 420

// original https://www.shadertoy.com/view/Nsf3Dn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int maxSteps = 80;
const float hitThreshold = .002;
const float maxDistance = 800.;
const float specExp = 8.;
const float AA = 2.;

struct Sphere
{
    vec3 center;
    float radius;
    vec3 color;
};

struct Box
{
    vec3 center;
    vec3 size;
    vec3 color;
};

struct Ray
{
    vec3 origin;
    vec3 dir;
};

struct Light
{
    vec3 point;
    float intensity;
    vec3 color;
    float sharpness;
};

struct Hit
{
    float t;
    vec3 color;
};

vec3 rayToPos(Ray ray, float t)
{
    return ray.origin + ray.dir * t;
}

mat3 rotMat3(vec3 u, float t)
{
    u = normalize(u);
    float c = cos(t);
    float nc = 1. - cos(t);
    float s = sin(t);
    float xy = u.x*u.y;
    float yz = u.y*u.z;
    float xz = u.x*u.z;
    return mat3(
        c+u.x*u.x*nc, xy*nc+u.z*s, xz*nc-u.y*s,
        xy*nc-u.z*s, c+u.y*u.y*nc, yz*nc+u.x*s,
        xz*nc+u.y*s, yz*nc-u.x*s,  c+u.z*u.z*nc
    );
}

mat2 rotMat2(float t)
{
    float c = cos(t);
    float s = sin(t);
    return mat2(
        c, s,
        -s, c
    );
}

Hit sphereSDF(vec3 p, Sphere s)
{
    return Hit(length(p - s.center) - s.radius, s.color);
}

Hit boxSDF( vec3 p, Box b )
{
  vec3 q = abs(p - b.center) - (b.size);
  float radius = 0.02;
  return Hit(length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - radius, b.color);
}

// Signed distance functions for different shapes

Hit mandelbulbSDF(vec3 p)
{
    float power = 8.;
    vec3 z = p;
    float dr = 1.;
    float r;
    vec3 c1 = vec3(1., 1., 1.);
    vec3 c2 = vec3(1., 0., 0.) * .02;
    
    for (int i = 0; i < 15; i++)
    {
        r = length(z);
        if (r > 2.)
        {
            break;
        }
        float theta = acos(z.z / r) * power + time;
        float phi = atan(z.y/z.x) * power + time;
        float zr = pow(r, power);
        dr = pow(r, power - 1.) * power * dr + 1.;
        z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
        z += p;
        c2 += c2;
    }
    return Hit(0.5 * log(r) * r / dr, c1 - c2);
}

Hit linesSDF(vec3 _p)
{
    vec2 p = _p.xz;
    int iter = 4;
    float q = 10.8 + .2*_p.y;
    float scale = 2.2;
    float s = .5;
    p *= s;
    float r = (1.1+sin(time))/3.;
    vec3 color = vec3(0.);
    int i = 0;
    p = p*rotMat2(-0.4*q);
    for (; i < iter; i++)
    {
        if (p.x < 0.)
        {
            p.x = -p.x;
            color.r += 1.;
        }
        p = rotMat2(.9 * q) * p;
        if (p.y < 0.)
        {
            p.y = -p.y;
            color.g += 1.;
        }
        p = rotMat2(q) * p;
        if (p.x - p.y < 0.)
        {
            p.xy = p.yx;
            color.b += 1.;
        }
        p *= scale;
        p -= 2.;
        p = rotMat2(time) * p;
    }
    float d = .6 * (length(p)-r) * pow(scale, float(-i))/s;
    return Hit(d, color/float(iter));
}

// Smooth min to cause shapes to morph into eachother
float smin( float a, float b, float k )
{
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return mix(b, a, h) - k*h*(1.0-h);
}

Hit hitMin(Hit a, Hit b)
{
    if (a.t < b.t)
    {
        return a;
    } else {
        return b;
    }
}

Hit hitSMin(Hit a, Hit b, float k)
{
    float h = clamp(0.5+0.5*(b.t-a.t)/k, 0.0, 1.0 );
    float f = mix(b.t, a.t, h) - k*h*(1.0-h);
    vec3 c = mix(b.color, a.color, h) - k*h*(1.0-h);
    return Hit(f, c);
}

// Define the objects in the scene and their relations to eachother
Hit map(vec3 p)
{
    mat3 rot = rotMat3(vec3(1., 0., -0.5), 1.2);
    return linesSDF(rot * p);
}

// Calculate the gradient of the world at a point
vec3 calcNormal(vec3 p)
{
    const vec3 eps = vec3(0.001, 0., 0.);
    
    float deltaX = map(p + eps.xyy).t - map(p - eps.xyy).t;
    float deltaY = map(p + eps.yxy).t - map(p - eps.yxy).t;
    float deltaZ = map(p + eps.yyx).t - map(p - eps.yyx).t;
    
    return normalize(vec3(deltaX, deltaY, deltaZ));
}

// Convert a ray into a shadow scalar
float calcShadow(Ray ray, float maxT, float k)
{
    float res = 1.0;
    float ph = 1e20;
    int i = 0;
    for (float t = hitThreshold * 50.; t < maxT; )
    {
        float h = map(rayToPos(ray, t)).t;
        if (h < hitThreshold)
        {
            return 0.;
        }
        float hsqr = pow(h, 2.);
        float y = hsqr/(2. * ph);
        float d = sqrt(hsqr - pow(y, 2.));
        res = min(res, k * d / max(0., t - y));
        ph += h;
        t += h;
        i += 3;
        if (i > maxSteps)
        {
            break;
        }
    }
    return res;
}

// Combine all the lights in the scene to color objects
vec3 calcLight(vec3 p, vec3 v, vec3 n)
{
    const int lCount = 3;
    Light[lCount] lights = Light[lCount](
        Light(vec3(5., 0., -6.), 50., vec3(1., .2, 0.), 8.),
        Light(vec3(0., 5., 5.), 25., vec3(1., .5, .1), 8.),
        Light(vec3(0., 0., 0.), 25., vec3(1., 0.5, 1.), 1.)
    );
    vec3 ambient = vec3(1.) * .2;
    
    vec3 color = vec3(0.);
    for (int i = 0; i < lCount; i++)
    {
        vec3 ldir = lights[i].point - p;
        float lmag = length(ldir); 
        ldir /= lmag;
        
        vec3 h = normalize(ldir - v);
        float spec = max(0., pow(dot(n, h), specExp));
        
        float diff = max(0., dot(ldir, n));

        float shadow = calcShadow(Ray(p, ldir), lmag, lights[i].sharpness) * 4.;
        
        float strength = shadow * lights[i].intensity * (1./pow(lmag, 2.));
        color += strength * (lights[i].color * diff + vec3(1.) * spec);
    }
    
    return ambient + color;
}

// Convert Pixel Rays to Colors
vec3 raymarch(Ray ray)
{
    vec3 glowBase = vec3(1., .5, 1.) * .001;
    vec3 glow = vec3(0.);
    float t = 0.;
    for (int i = 0; i < maxSteps && t <= maxDistance; i++)
    {
        vec3 currentPos = rayToPos(ray, t);
        Hit closestHit = map(currentPos);
        
        if (closestHit.t < hitThreshold)
        {
            vec3 normal = calcNormal(currentPos);
            vec3 color = closestHit.color * calcLight(currentPos, ray.dir, normal);
            return color;
        }
        t += closestHit.t;
        glow += glowBase;
    }

    return vec3(0.01, 0.02, 0.03) + glow;
}

vec4 render(in vec3 e, in mat4 view, in vec2 uv) {
    // Create viewing rays and get colors from them
    vec3 p = (view * vec4(uv, -1., 1.)).xyz;
    Ray viewRay = Ray(e, normalize(p - e));
    return vec4(raymarch(viewRay), 1.0);
}

void main(void)
{
    // Define Camera
    vec3 viewpoint = vec3(0., 0., 0.);
    mat3 rot = rotMat3(vec3(0.), 0.);
    vec3 e = vec3(0., 0., 10.);
    
    // Construct camera Matrix
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 w = -normalize(viewpoint - e);
    vec3 u = cross(w, up);
    vec3 v = normalize(cross(u, w));
    
    mat4 view = mat4(
        u, 0.0,
        v, 0.0,
        w, 0.0,
        e, 1.0
    );
    
        // Convert pixel coordinates to uv coordinates
    if (AA > 1.) {
      vec4 average = vec4(0.0);
      for (float s = 0.; s < AA; s++) {
        for (float t = 0.; t < AA; t++) {
            vec2 offset = (vec2(s, t) / AA) - 0.5;

            vec2 uv = (gl_FragCoord.xy + offset)/resolution.xy * 2. - 1.;
            uv.y *= resolution.y/resolution.x;

            average += render(e, view, uv);
        }
      }  
      average /= AA*AA;
      glFragColor = average;
    } else {
      vec2 uv = gl_FragCoord.xy/resolution.xy * 2. - 1.;
      uv.y *= resolution.y/resolution.x;

      glFragColor = render(e, view, uv);
    }
}
