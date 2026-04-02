#version 420

// original https://www.shadertoy.com/view/sdKfRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

const vec3 u_TrapColors[3] = vec3[](
    vec3(0.0, 0.8, 1.0),
    vec3(0.0, 1.0, 1.0),
    vec3(1.0, 0.1, 0.1)
);
const vec3 u_SunDir = vec3(0.747474, 0.0,  -0.7474747);
const float u_Metalness = 0.7;
const float u_Roughness = 0.4;
const bool u_Rotate = true;
const float u_Brightness = 0.0;
const float u_Contrast = 1.02;
const float u_Fog = 0.5;
const bool u_RaytracedReflection = true;
const float u_ShadowHardness = 2.0;
const float u_AOStrength = 1.0;

// https://iquilezles.org/articles/intersectors/
vec2 isphere( in vec4 sph, in vec3 ro, in vec3 rd )
{
    vec3 oc = ro - sph.xyz;
    float b = dot(oc,rd);
    float c = dot(oc,oc) - sph.w*sph.w;
    float h = b*b - c;
    if(h < 0.0) return vec2(-1.0);
    h = sqrt( h );
    return -b + vec2(-h,h);
}

vec3 rotate( vec3 pos, float x, float y, float z )
{
    mat3 rotX = mat3( 1.0, 0.0, 0.0, 0.0, cos( x ), -sin( x ), 0.0, sin( x ), cos( x ) );
    mat3 rotY = mat3( cos( y ), 0.0, sin( y ), 0.0, 1.0, 0.0, -sin(y), 0.0, cos(y) );
    mat3 rotZ = mat3( cos( z ), -sin( z ), 0.0, sin( z ), cos( z ), 0.0, 0.0, 0.0, 1.0 );

    return rotX * rotY * rotZ * pos;
}

float map(vec3 p, out vec4 col) {
    if(u_Rotate) {
        p = rotate(p, sin(time*0.25), cos(time*0.25), 0.0);
    }
    vec3 w = p;
    float m = length(w);
    float dz = 1.0;
    
    vec4 trap = vec4(abs(w), m);

    for(int i = 0; i < 4; i++)
    {
        if(m > 16.0) {
            break;
        }

        dz = 8.0*pow(m,7.0)*dz + 1.0;

        float b = 8.0*acos( w.y/m);
        float a = 8.0*atan( w.x, w.z );
        w = p + pow(m,8.0) * vec3( sin(b)*sin(a), cos(b), sin(b)*cos(a) );

        m = length(w);
        trap = min(trap, vec4(abs(w), m));
    }
    col = vec4(m, trap.yzw);

    return 0.5*log(m)*m/dz;
}

vec3 estimateNormal(vec3 p, float t) {
    vec4 tmp;
    const float h = 0.002; 
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*map( p + k.xyy*h, tmp ) + 
                      k.yyx*map( p + k.yyx*h, tmp ) + 
                      k.yxy*map( p + k.yxy*h, tmp ) + 
                      k.xxx*map( p + k.xxx*h, tmp ) );

}

float shadow( in vec3 ro, in vec3 rd, in float k )
{
    vec2 sph = isphere(vec4(0.0, 0.0, 0.0, 1.25), ro, rd);
    sph.x = max(0.0, sph.x);
    sph.y = min(sph.y, 10.0);

    float res = 1.0;
    float t = sph.x;
    vec4 tmp;
    for( int i=0; i<32; i++ )
    {
        float h = map(ro + rd*t, tmp);
        res = min( res, k*h/t );
        if(t > sph.y || res<0.001) break;
        t += clamp( h, 0.01, 0.2 );
    }
    return clamp(res, 0.0, 1.0);
}

vec3 skybox(vec3 d) {
    return mix(vec3(0.51,0.79,1), vec3(0.85,0.97,1), max(0.0, d.y));
}

vec2 raycast(vec3 o, vec3 d, out float i, out vec4 col) {
    vec2 sph = isphere(vec4(0.0, 0.0, 0.0, 1.25), o, d);
    sph.x = max(0.0, sph.x);
    sph.y = min(sph.y, 10.0);

    float t = sph.x;
    for(i = 0.0; i < 1000.0; ++i) {
        float m = map(o + t*d, col);
        if(t > sph.y) {
            break;
        }
        if(m < 0.001) {
            return vec2(t, 1.0);
        }
        t += m;
    }
    return vec2(-1.0, -1.0);
}

// https://www.unrealengine.com/en-US/blog/physically-based-shading-on-mobile
float NDF_Approx(float roughness, float ndotv )
{
    // Same as EnvBRDFApprox( 0.04, Roughness, NoV )
    const vec2 c0 = vec2(-1, -0.0275);
    const vec2 c1 = vec2(1, 0.0425);
    vec2 r = roughness * c0 + c1;
    return min( r.x * r.x, exp2( -9.28 * ndotv)) * r.x + r.y;
}

// Trowbridge-Reitz GGX
float normalDistribution(vec3 h, vec3 n, float a) {
    float nh = max(dot(n, h), 0.0);
    float a2 = a*a;
    float denom = (nh*nh*(a2-1.0)+1.0);
    return a2 / (PI*denom*denom);
}

// Schlick-GGX
float geometrySub(float ndotv, float k) {
    return ndotv / (ndotv * (1.0 - k) + k);
}

float geometry(vec3 d, vec3 n, vec3 l, float ndotl, float a) {
    float r = a + 1.0;
    float k = r*r / 8.0;
    float nv = max(dot(d,n), 0.0);
    return geometrySub(ndotl, k)*geometrySub(nv, k);
}

// fresnel equation
vec3 fresnel(float costheta, vec3 f0) {
    return f0 + (vec3(1.0)-f0) * pow(1.0 - costheta, 5.0);
}

vec3 trapToCol(vec4 trap) {
    vec3 col = vec3(0.01);
    col = mix( col, u_TrapColors[0], clamp(trap.y,0.0,1.0) );
    col = mix( col, u_TrapColors[1], clamp(trap.z*trap.z,0.0,1.0) );
    col = mix( col, u_TrapColors[2], clamp(pow(trap.w,6.0),0.0,1.0) );
    return col * 0.5;
}

// Cook-Torrance microfacet model
vec3 render(vec3 o, vec3 d, out float t) {
    float i;
    vec4 trap;
    vec2 hit = raycast(o, d, i, trap);
    t = hit.x;
    if(hit.y < 0.0) {
        return skybox(d);
    } 
    vec3 dcol = trapToCol(trap);

    vec3 point = o + hit.x * d;
    float sun_intensity = 5.0;
    float indirect_intensity = 0.64;
    float ambient = 0.4; // (indirect diffuse)

    float roughness = u_Roughness;
    float metallic = u_Metalness;

    roughness *= roughness; // better for input
    vec3 v = -d;
    vec3 l = -normalize(u_SunDir);
    vec3 n = estimateNormal(point, hit.x);
    vec3 h = normalize(l+v);
    vec3 r = reflect(d, n);
    float ndotl = max(0.0, dot(n, l));
    float hdotv = max(0.0, dot(h, v));
    vec3 f0 = mix(vec3(0.04), dcol, metallic);

    float ndf = normalDistribution(h, n, roughness);
    float g = geometry(v, n, l, ndotl, roughness);
    vec3 f = fresnel(hdotv, f0);
    float denom = 4.0*max(dot(n,v), 0.0) * ndotl + 0.0001;
    vec3 specular = ndf*g*f/denom;
    vec3 diffuse = dcol / PI;

    vec3 kd = (1.0 - f) * (1.0 - metallic);
    vec3 direct = kd * diffuse + specular;
    float sh = shadow(point+0.01*n, l, u_ShadowHardness*u_ShadowHardness);
    direct *= sh * ndotl * sun_intensity;
    
    vec3 indirect_dif = dcol * ambient / PI;

    float itmp;
    vec4 spec_trap;
    vec3 indirect_specular = vec3(0.0);
    if(u_RaytracedReflection) {
        vec2 rhit = raycast(point + 0.001 * n, r, itmp, spec_trap);
        vec3 rpoint = point + 0.001 * n + rhit.x * r;
        float choose = max(0.0, sign(rhit.y));
        indirect_specular = mix(skybox(r), trapToCol(spec_trap), max(0.0, sign(rhit.y)));
    }
    float ao = min(1.0, 20.0 / max(u_AOStrength*2.0 * i, 0.01));
    vec3 indirect = indirect_dif * dcol * kd + indirect_specular * NDF_Approx(roughness, abs(dot(n, v)) + 1e-5); 
    return (direct + indirect * indirect_intensity)*ao;
}

vec3 brightnessContrast(vec3 value, float brightness, float contrast)
{
    return (value - 0.5) * contrast + 0.5 + brightness;
}

// Narkowicz 2015, "ACES Filmic Tone Mapping Curve"
vec3 tonemap(const vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return (x * (a * x + b)) / (x * (c * x + d) + e);
}

vec3 gamma(const vec3 linear) {
    return pow(linear, vec3(1.0 / 2.2));
}

void main(void)
{
    vec3 ro = vec3( 0.0, 0.0,  3.0 );;
    
    vec3 cameraDir = vec3(0.0, 0.0, -1.0);
    vec3 cameraRight = vec3(1.0, 0.0, 0.0);
    vec3 cameraUp = vec3(0.0, resolution.y/resolution.x, 0.0);
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 rd = normalize( 
        + cameraDir
        + cameraRight * (uv.x-0.5)
        + cameraUp * (uv.y-0.5) 
    );
    float t;
    vec3 col = render(ro, rd, t);
    col = brightnessContrast(col, u_Brightness, u_Contrast);
    col = tonemap(col);

    vec3 lambda = exp(vec3(1.0, 2.0, 4.0) * (-0.05 * u_Fog * u_Fog) * t) * max(0.0, sign(t)) + max(0.0, -sign(t));  // fog
    col = lambda * col + (1.0 - lambda) * vec3(0.7, 0.7, 0.7);
    //col = col / (col + 1.0);
    col = gamma(col);
    glFragColor = vec4(col, 1.0);
}
