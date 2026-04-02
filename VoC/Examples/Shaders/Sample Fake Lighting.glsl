#version 420

// original https://www.shadertoy.com/view/4tKBDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// simple sphere march (+ fake light / ref)
mat2 rotate(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}
#define    TAU 6.28318

float textureFunc( vec2 uv )
{
    uv *= 3.;
    vec2 f_uv = fract(uv);
    float v = smoothstep(.0,.5,length(vec2(.5)-f_uv));
    return v;
}

// IQ's patched sphere parametrization to squash texture on to a sphere.
// Reference: http://iquilezles.org/www/articles/patchedsphere/patchedsphere.htm

vec2 sphereToCube(in vec3 pointOnSphere)
{
   return vec2(pointOnSphere.x/pointOnSphere.z,pointOnSphere.y/pointOnSphere.z);
}
/* Check if x and y are between 0 and 1. If so, return v,
 * otherwise return zeros. This allows us to use a sum of
 * vectors to test what face of the cube we are on */ 
vec2 insideBounds(vec2 v)
{
    vec2 s = step(vec2(-1.,-1.), v) - step(vec2(1.,1.), v);
    return s.x * s.y * v;
}

float getSphereMappedTexture(in vec3 pointOnSphere)
{
    /* Test to determine which face we are drawing on.
     * Opposing faces are taken care of by the absolute
     * value, leaving us only three tests to perform.
     */
    vec2 st = abs(
        insideBounds(sphereToCube(pointOnSphere.xyz)) +
        insideBounds(sphereToCube(pointOnSphere.zyx)) +
        insideBounds(sphereToCube(pointOnSphere.xzy)));
    return textureFunc(st);
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBumpedSphere(vec3 p)
{
    float k = getSphereMappedTexture(p) * 0.25;        // 
    float d = sdSphere(p, 4.0);
    return d+k;
}

float map(vec3 p)
{
    float ox = p.x;
    vec4 tt = vec4(time*0.05,time*0.1,time*0.5,time*0.75) * TAU;
    p.xz *= rotate(tt.x);
    p.zy *= rotate(tt.y);

    float d2 = sdBumpedSphere(p);
    float d1 =  length(p.xyz);
    float ii = 6.0;
    float k = sin(p.x*ii);
    k*= sin(p.z*ii);
    k*= sin(p.y+p.z*d1);
    d1 = d1 - 4.0 + k*0.25;
    
    // blend between bumped texture sphere and the random displacement... :)
    float bv = 0.5+sin(ox*0.1+time*0.7)*0.5;
    bv = (bv*3.0)-1.5;
    bv = smoothstep(0.0,1.0,bv);
    return mix(d1,d2,bv);
}

vec3 normal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ) + 
                      e.yyx*map( pos + e.yyx ) + 
                      e.yxy*map( pos + e.yxy ) + 
                      e.xxx*map( pos + e.xxx ) );
}
vec3 render(vec3 ro, vec3 rd)
{
    // march    
    float tmin = 0.1;
    float tmax = 20.;
    vec3 p;
    float t = tmin;
    for (int i = 0; i < 180; i++)
    {
        p = ro + t * rd;
        float d = map(p);
        t += d*0.75;
        if (t > tmax)
            break;        
    }
    
    // light
    if (t < tmax)
    {
           vec3 lightDir = normalize(vec3(0.0, 1.0, -1.0));
        vec3 nor = normal(p);
        
        float dif = max(dot(nor, lightDir), 0.0);
        vec3 c = vec3(0.5) * dif;
        
        float tf = 0.05;
        c += vec3(0.3,0.3,0.3) + reflect(vec3(p.x*tf, p.y*tf, 0.05), nor);

        vec3 ref = reflect(rd, nor);
        float spe = max(dot(ref, lightDir), 0.0);
        c += vec3(2.0) * pow(spe, 32.);
        return c;
    }
    
    return vec3(0.24,0.24,0.35);
}

mat3 camera(vec3 ro, vec3 ta, vec3 up)
{
    vec3 nz = normalize(ta - ro);
    vec3 nx = cross(nz, normalize(up));
    vec3 ny = cross(nx, nz);
    return mat3(nx, ny, nz);
}

void main(void)
{
       vec2 q = (2.0*gl_FragCoord.xy / resolution.xy)-1.0;
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.xy;
    p.x *= resolution.x / resolution.y;

    vec3 ro = vec3(0.0, 0.0, 0.0);
    float ang = radians(-90.0);
    float d = 6.0;
    ro.z = sin(ang)*d;
    ro.x = cos(ang)*d;
    vec3 ta = vec3(0.0, 0.0, 0.0);
    
    vec3 rd = camera(ro, ta, vec3(0.0, 1.0, 0.0)) * normalize(vec3(p.xy, 1.0));

    // render
    vec3 c = render(ro, rd);

    // vignette
    float rf = sqrt(dot(q, q)) * 0.35;
    float rf2_1 = rf * rf + 1.0;
    float e = 1.0 / (rf2_1 * rf2_1);    
    c*=e;    

    glFragColor = vec4(c, 1.0);
}
