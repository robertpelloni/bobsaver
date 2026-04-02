#version 420

// original https://www.shadertoy.com/view/XlKXDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Cloudscape with hyprboloid cloud features
// Tuan Tran and Zander Majercik
// Based on work by inigo quilez https://www.shadertoy.com/view/XslGRr
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define Vector3 vec3
#define Color3 vec3
#define Matrix3 mat3
#define Point3 vec3
#define Color4 vec4
#define Vector2 vec2
#define Radiance4 vec4

#define g3d_SceneTime time

#define pi 3.141592653589793

vec3 sundir = normalize( vec3(0.5, 0.2, -1.0) );

/////////////////////https://www.shadertoy.com/view/lss3zr////////////////////
//-----------------------------------------------------------------------------
// Maths utils
//-----------------------------------------------------------------------------
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

//////////////////////////////////////////////

// Worley Noise taken from https://github.com/Erkaman/glsl-worley by Erkaman. MIT License.
// Permutation polynomial: (34x^2 + x) mod 289
Vector3 permute(Point3 x) {
  return mod((34.0 * x + 1.0) * x, 289.0);
}

Vector3 dist(Vector3 x, Vector3 y, Vector3 z,  bool manhattanDistance) {
  return manhattanDistance ?  abs(x) + abs(y) + abs(z) :  (x * x + y * y + z * z);
}

/** Worley noise function */
Vector2 worley(Point3 P, float jitter, bool manhattanDistance) {
float K = 0.142857142857; // 1/7
float Ko = 0.428571428571; // 1/2-K/2
float  K2 = 0.020408163265306; // 1/(7*7)
float Kz = 0.166666666667; // 1/6
float Kzo = 0.416666666667; // 1/2-1/6*2

    Vector3 Pi = mod(floor(P), 289.0);
     Vector3 Pf = fract(P) - 0.5;

    Vector3 Pfx = Pf.x + Vector3(1.0, 0.0, -1.0);
    Vector3 Pfy = Pf.y + Vector3(1.0, 0.0, -1.0);
    Vector3 Pfz = Pf.z + Vector3(1.0, 0.0, -1.0);

    Vector3 p = permute(Pi.x + Vector3(-1.0, 0.0, 1.0));
    Vector3 p1 = permute(p + Pi.y - 1.0);
    Vector3 p2 = permute(p + Pi.y);
    Vector3 p3 = permute(p + Pi.y + 1.0);

    Vector3 p11 = permute(p1 + Pi.z - 1.0);
    Vector3 p12 = permute(p1 + Pi.z);
    Vector3 p13 = permute(p1 + Pi.z + 1.0);

    Vector3 p21 = permute(p2 + Pi.z - 1.0);
    Vector3 p22 = permute(p2 + Pi.z);
    Vector3 p23 = permute(p2 + Pi.z + 1.0);

    Vector3 p31 = permute(p3 + Pi.z - 1.0);
    Vector3 p32 = permute(p3 + Pi.z);
    Vector3 p33 = permute(p3 + Pi.z + 1.0);

    Vector3 ox11 = fract(p11*K) - Ko;
    Vector3 oy11 = mod(floor(p11*K), 7.0)*K - Ko;
    Vector3 oz11 = floor(p11*K2)*Kz - Kzo; // p11 < 289 guaranteed

    Vector3 ox12 = fract(p12*K) - Ko;
    Vector3 oy12 = mod(floor(p12*K), 7.0)*K - Ko;
    Vector3 oz12 = floor(p12*K2)*Kz - Kzo;

    Vector3 ox13 = fract(p13*K) - Ko;
    Vector3 oy13 = mod(floor(p13*K), 7.0)*K - Ko;
    Vector3 oz13 = floor(p13*K2)*Kz - Kzo;

    Vector3 ox21 = fract(p21*K) - Ko;
    Vector3 oy21 = mod(floor(p21*K), 7.0)*K - Ko;
    Vector3 oz21 = floor(p21*K2)*Kz - Kzo;

    Vector3 ox22 = fract(p22*K) - Ko;
    Vector3 oy22 = mod(floor(p22*K), 7.0)*K - Ko;
    Vector3 oz22 = floor(p22*K2)*Kz - Kzo;

    Vector3 ox23 = fract(p23*K) - Ko;
    Vector3 oy23 = mod(floor(p23*K), 7.0)*K - Ko;
    Vector3 oz23 = floor(p23*K2)*Kz - Kzo;

    Vector3 ox31 = fract(p31*K) - Ko;
    Vector3 oy31 = mod(floor(p31*K), 7.0)*K - Ko;
    Vector3 oz31 = floor(p31*K2)*Kz - Kzo;

    Vector3 ox32 = fract(p32*K) - Ko;
    Vector3 oy32 = mod(floor(p32*K), 7.0)*K - Ko;
    Vector3 oz32 = floor(p32*K2)*Kz - Kzo;

    Vector3 ox33 = fract(p33*K) - Ko;
    Vector3 oy33 = mod(floor(p33*K), 7.0)*K - Ko;
    Vector3 oz33 = floor(p33*K2)*Kz - Kzo;

    Vector3 dx11 = Pfx + jitter*ox11;
    Vector3 dy11 = Pfy.x + jitter*oy11;
    Vector3 dz11 = Pfz.x + jitter*oz11;

    Vector3 dx12 = Pfx + jitter*ox12;
    Vector3 dy12 = Pfy.x + jitter*oy12;
    Vector3 dz12 = Pfz.y + jitter*oz12;

    Vector3 dx13 = Pfx + jitter*ox13;
    Vector3 dy13 = Pfy.x + jitter*oy13;
    Vector3 dz13 = Pfz.z + jitter*oz13;

    Vector3 dx21 = Pfx + jitter*ox21;
    Vector3 dy21 = Pfy.y + jitter*oy21;
    Vector3 dz21 = Pfz.x + jitter*oz21;

    Vector3 dx22 = Pfx + jitter*ox22;
    Vector3 dy22 = Pfy.y + jitter*oy22;
    Vector3 dz22 = Pfz.y + jitter*oz22;

    Vector3 dx23 = Pfx + jitter*ox23;
    Vector3 dy23 = Pfy.y + jitter*oy23;
    Vector3 dz23 = Pfz.z + jitter*oz23;

    Vector3 dx31 = Pfx + jitter*ox31;
    Vector3 dy31 = Pfy.z + jitter*oy31;
    Vector3 dz31 = Pfz.x + jitter*oz31;

    Vector3 dx32 = Pfx + jitter*ox32;
    Vector3 dy32 = Pfy.z + jitter*oy32;
    Vector3 dz32 = Pfz.y + jitter*oz32;

    Vector3 dx33 = Pfx + jitter*ox33;
    Vector3 dy33 = Pfy.z + jitter*oy33;
    Vector3 dz33 = Pfz.z + jitter*oz33;

    Vector3 d11 = dist(dx11, dy11, dz11, manhattanDistance);
    Vector3 d12 =dist(dx12, dy12, dz12, manhattanDistance);
    Vector3 d13 = dist(dx13, dy13, dz13, manhattanDistance);
    Vector3 d21 = dist(dx21, dy21, dz21, manhattanDistance);
    Vector3 d22 = dist(dx22, dy22, dz22, manhattanDistance);
    Vector3 d23 = dist(dx23, dy23, dz23, manhattanDistance);
    Vector3 d31 = dist(dx31, dy31, dz31, manhattanDistance);
    Vector3 d32 = dist(dx32, dy32, dz32, manhattanDistance);
    Vector3 d33 = dist(dx33, dy33, dz33, manhattanDistance);

    Vector3 d1a = min(d11, d12);
    d12 = max(d11, d12);
    d11 = min(d1a, d13); // Smallest now not in d12 or d13
    d13 = max(d1a, d13);
    d12 = min(d12, d13); // 2nd smallest now not in d13

    Vector3 d2a = min(d21, d22);
    d22 = max(d21, d22);
    d21 = min(d2a, d23); // Smallest now not in d22 or d23
    d23 = max(d2a, d23);
    d22 = min(d22, d23); // 2nd smallest now not in d23

    Vector3 d3a = min(d31, d32);
    d32 = max(d31, d32);
    d31 = min(d3a, d33); // Smallest now not in d32 or d33
    d33 = max(d3a, d33);
    d32 = min(d32, d33); // 2nd smallest now not in d33

    Vector3 da = min(d11, d21);
    d21 = max(d11, d21);
    d11 = min(da, d31); // Smallest now in d11
    d31 = max(da, d31); // 2nd smallest now not in d31

    d11.xy = (d11.x < d11.y) ? d11.xy : d11.yx;
    d11.xz = (d11.x < d11.z) ? d11.xz : d11.zx; // d11.x now smallest
    d12 = min(d12, d21); // 2nd smallest now not in d21
    d12 = min(d12, d22); // nor in d22
    d12 = min(d12, d31); // nor in d31
    d12 = min(d12, d32); // nor in d32
    d11.yz = min(d11.yz,d12.xy); // nor in d12.yz
    d11.y = min(d11.y,d12.z); // Only two more to go
    d11.y = min(d11.y,d11.z); // Done! (Phew!)

    return sqrt(d11.xy); // F1, F2
}

//Taken from http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

/**
    A hyperboloid intersection function
    when the point is far within the hyperboloid (centered at the origin)
*/
float sdCappedHyperboloid( Point3 p, Vector3 c) // modified from iq: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
{
    Vector2 q = Vector2( length(p.xz), -(3. * p.y * p.y + 0.6) ); //altered portion of sdCappedCone, making the sides curve quadratically
    Vector2 v = Vector2( c.z * c.y / c.x, -c.z );
    Vector2 w = v - q;
    Vector2 vv = Vector2( dot(v, v), v.x * v.x );
    Vector2 qv = Vector2( dot(v, w), v.x * w.x );
    Vector2 d = max(qv, 0.0) * qv / vv;

    return sqrt( dot(w, w) - max(d.x, d.y) ) * sign(max(q.y * v.x - q.x * v.y, w.y));//added to make the clouds random
}

/** Create a series of hyperboloid clouds */
float repeatedHyperboloid(Point3 P, Point3 C) {
    Point3 Q = Point3(cos(P.x * 0.75), P.y - 0.1, sin(P.z * 0.75));
    float distance = sdCappedHyperboloid(Q, C);    
    return distance;
}

/** further randomize the value in fbm to achieve desired effect */
float map(Point3 Q, int lod) {
    float hyperboloid = repeatedHyperboloid(Q * .05, Point3(1.3, 2.0, 1.3));
    //float sphereDist = repeatedSphere(Q  * .05, spherePrim);
    //float triDist = repeatedTriangularPrism(Q);

    float d = -.1 - min(1.25*Q.y, 12.*hyperboloid);//+ min(1.25 * Q.y, min( triDist * 0.75, min(12. * hyperboloid, 7. * sphereDist)));
    
    if (Q.y < 0.0 || hyperboloid < 0.0){//|| sphereDist < 0.0 || triDist < 0.0) {
        float fbm = clamp(noise(Q * 0.25 + .6 * g3d_SceneTime) + 0.5, 0., 2.); //Perlin noise

        // Add Worley noise to achieve cumulus-like cloud pattern.
        // Inspired by Horizon:zero Dawn http://advances.realtimerendering.com/s2015/index.html
        d += 6.25 * fbm - 6. * length(worley(Q * 0.001, 0., false)) 
             - 2. * length(worley(Q * 0.01 + Point3 (0.3, 0.5, 0.3), 0., false))
             - 0.5 * length(worley(Q * 0.1 + 0.4, 0., false));
    }
    
    return clamp(d, 0., 1.5);
}

/** Return a shade of cloud color */
Color4 shade(float dif, float den) {
    // color map
    Color4 color = Color4(mix(Color3(1.) * 0.85, Color3(0.5), den), den);
    Color3 lin = Color3(0.65, 0.7, 0.75) * 1.5 + Color3(0.9, 0.5, 0.4) * dif;        
    color.rgb *= lin;

    // front to back blending    
    color.a *= 0.6;
    color.rgb *= color.a;
    return color;
}

/** Ray marching through a noise function to create cloud-like image */
void march(/*const int samples,*/ Point3 P, Vector3 w, int lod, inout float t, inout Color4 sum) {
    P = P + Vector3(0., 9., 0.) - Vector3(0.0, -0.0, 3.0) *  2.0 * g3d_SceneTime;
    for (int i = 0; i < 100; i++) {
        // Break if our cloud is dense
        if (sum.a > 0.99) {
            break;
        }

        Vector3 pos = P + t * w;
        float den = map(pos, lod) * 1.1;

        if (den > 0.01) {
            float dif = clamp(den - noise(pos + 0.6 * sundir), 0.0, 1.0);
            Color4 color = shade(dif, den);
            sum += color * (1.0 - sum.a);
        }

        t += min( 0.06 + 0.025 * t, 0.6 + 0.0025 * t);
    }
} 

/** Using raymarch to create cloud layers */
Color4 raymarch( Point3 P, Vector3 w) {
    Color4 sum = Color4(0.0);
    float t = 0.0;

    // Different level of detail
    //march(50, P, w, 5, t, sum);
    march(P, w, 4, t, sum);
    march(P, w, 3, t, sum);
    march(P, w, 2, t, sum);

    return clamp(sum, 0.0, 1.0);
}

/** Calculating the background sky */
Color3 backgroundColor(Point3 P, Vector3 w, float sun) {
    Color3 col = Color3(0.);
    
    // The sky
    float hort = 1. - clamp(abs(w.y), 0., 1.);
    col += 0.5*vec3(.99,.5,.0)*exp2(hort*8.-8.);
    col += 0.1*vec3(.8,.6,0.7)*exp2(hort*3.-3.);
    col += 0.55*vec3(.9,.4,.6);

    
    // The sun
    col += .2*vec3(0.6,0.3,0.2)*pow( sun, 2.0 );
    col += .5*vec3(1.,.9,.9)*exp2(sun*650.-650.);
    col += .1*vec3(1.,1.,0.1)*exp2(sun*100.-100.);
    col += .3*vec3(1.,.7,0.)*exp2(sun*50.-50.);
    col += .5*vec3(1.,0.3,0.05)*exp2(sun*10.-10.); 
       
    return clamp(col, 0.0, 1.0);
}

/** Render the cloudscape */
Color4 render( Point3 P, Vector3 w ) {
    float sun = clamp(dot(sundir, w), 0.0, 1.0);

    // background sky
    // To change background, uncomment the above block and comment this line
    Color3 color = backgroundColor(P, w, sun);

    // clouds    
    Radiance4 result = raymarch(P, w);
    result *= Color4(pow(color, Color3(0.3)), 0.9);
    color = 0.9 * color * (1.0 - result.w) + 1.1* result.xyz;

    // sun glare
    color += Color3(0.2, 0.15, 0.07) * pow( sun, 2.0 );
    color = clamp(color, 0.0, 1.);

    return Color4( color, 1.0 );
}

//iq https://www.shadertoy.com/view/4dKGWm
mat3 setCamera( in vec3 ro, in vec3 rt, in float cr )
{
    vec3 cw = normalize(rt-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, -cw );
}

//camera work from iq https://www.shadertoy.com/view/4dKGWm
void main(void)
{
    vec2 q = gl_FragCoord.xy/resolution.xy;
    vec2 p = (-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y;

    // camera
    float an = 0.0 - 1.25- 1.0*mouse.x*resolution.x/resolution.x;
    vec3 ro = vec3(5.7*sin(an),-3.0,5.7*cos(an));
    vec3 ta = vec3(0.0,-4.,0.0);

    // ray
    mat3 ca = setCamera( ro, ta, 0.0 );
    vec3 rd = normalize( ca * vec3(p,-3.5) );
    
    glFragColor = render(ro, rd);
}
