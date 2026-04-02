#version 420

// original https://www.shadertoy.com/view/stlyW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
//
// The Arrival
//
// The initial idea was a composition of an nightly scenery - mixing abstract water, moonlight, stars
// horizon and lensflares together with even more abstract moving forms...
// Well - seeing what it all turned out - it looks more like my tribute to late 80s airbrush culture
// but still I like it a lot...
//
//
// This shader shall exist in its/this form on shadertoy.com only 
// You shall not use this shader in any commercial or non-commercial product, website or project. 
// This shader is not for sale nor can´t be minted (ecofriendly or not) as NFT.
//
//
// Related examples
//
// distance function(s):
// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
// xTr1m / BluFlame´s lunaquatic:
// https://github.com/joric/pyshadertoy/blob/master/lunaquatic.glsl
// Yusef28´s lensflares:
// https://www.shadertoy.com/view/Xlc3D2 
// 
//
//

#define pi 3.14159265359

vec4 Y;
vec3 circColor  = vec3(0.9, 0.2, 0.1);
vec3 circColor2 = vec3(0.3, 0.1, 0.9);
vec4 arrivalPos;
vec3 lightPos, lightDir, ro, rd;
float FAR, eps=0.0001;

float saturate(float x) { return clamp(x,0.0,1.0); }
float ftime(float t, float s, float e) { return (t-s)/(e-s); }

//////////////////////////////////////////////////////////////////////////////////////
// x,y,z rotation(s)
//////////////////////////////////////////////////////////////////////////////////////

vec3 rotateY(vec3 v, float x)
{
    return vec3(
        cos(x)*v.x - sin(x)*v.z,
        v.y,
        sin(x)*v.x + cos(x)*v.z
    );
}

vec3 rotateX(vec3 v, float x)
{
    return vec3(
        v.x,
        v.y*cos(x) - v.z*sin(x),
        v.y*sin(x) + v.z*cos(x)
    );
}

vec3 rotate_z(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +ca, -sa, +.0,
        +sa, +ca, +.0,
        +.0, +.0,+1.0);
}

vec3 rotate_y(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +ca, +.0, -sa,
        +.0,+1.0, +.0,
        +sa, +.0, +ca);
}

vec3 rotate_x(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +1.0, +.0, +.0,
        +.0, +ca, -sa,
        +.0, +sa, +ca);
}

//////////////////////////////////////////////////////////////////////////////////////
// randomness and hash´ing like a pro
//////////////////////////////////////////////////////////////////////////////////////

float rnd(vec2 x) {
    int n = int(x.x * 40.0 + x.y * 6400.0);
    n = (n << 13) ^ n;
    return 1.0 - float( (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff) / 1073741824.0;
}

float rnd(float w) {
    float f = fract(sin(w)*1000.);
    return f;   
}

float smoothrnd(vec2 x) {
    x = mod(x,1000.0);
    vec2 a = fract(x);
    x -= a;
    vec2 u = a*a*(3.0-2.0*a);
    return mix(
    mix(rnd(x+vec2(0.0)),rnd(x+vec2(1.0,0.0)), u.x),
    mix(rnd(x+vec2(0.0,1.0)),rnd(x+vec2(1.0)), u.x), u.y);
}

float noise(vec2 uv){
    vec3 p3  = fract(vec3(uv.xyx) * .1831);
    p3 += dot(p3, p3.yzx + 339.33);
    return fract((p3.x + p3.y) * p3.z);
}

//////////////////////////////////////////////////////////////////////////////////////
// Converting from [-1,1] to [0,1]
//////////////////////////////////////////////////////////////////////////////////////

float norm(float x)
{
    return x * 0.5 + 0.5;
}

//////////////////////////////////////////////////////////////////////////////////////
// generate animated caustics and calculate water "waves"
//////////////////////////////////////////////////////////////////////////////////////

float caustic(float u, float v, float t)
{
    return pow((
    norm(sin(pi * 2.0 * (u + v + Y.z*t))) +
    norm(sin(pi       * (v - u - Y.z*t))) +
    norm(sin(pi       * (v     + Y.z*t))) +
    norm(sin(pi * 3.0 * (u     - Y.z*t)))) * 0.3, 2.0);
}

float height(vec2 x) {
    float maxV = Y.z;
    float l = mix(1., max(0., arrivalPos.w - arrivalPos.y), 1.0 - ((maxV > 0.0 && length(x - arrivalPos.xz) < maxV) ? 1.0 : 0.0)) /
            pow(1./max(0., 1.0-length(arrivalPos.xz-x)*0.8), 2.0);
    x += length(x-ro.xy);
    x *= min(length(x-ro.xy)*5.0, 4.0);

    return    caustic(x.x+Y.z*0.75, x.y*0.5, 0.3) * 0.006 +
            caustic(x.x*0.1+Y.z*0.2, x.y*0.1, 0.02) * 0.125 -
            0.15;
}

vec3 getWaterNormal(vec3 p) {
    return normalize(vec3(
        caustic(p.x * 160.0 - 12.0 * cos(10.0 * p.z), p.z * 140.0, 4.0),
        8.0,
        caustic(p.z * 160.0 - 12.0 * sin(10.0 * p.x), p.x * 140.0, 4.0)) * 2.0 - 1.0);
}

//////////////////////////////////////////////////////////////////////////////////////
// raymarch the terrain function, returns the distance from the ray origin to the 
// terrain voxel. This function was originally adopted from an implementation by IQ
//////////////////////////////////////////////////////////////////////////////////////

int traceTerrain( vec3 ro, vec3 rd, float maxt, out float depth ) {
    float lh, ly, delt=0.0;
    for ( float t = 0.1; t < maxt; t += delt ) {
          
          ro += rd * delt;
          depth = height(ro.xz);

          if ( ro.y <= depth ) {
               depth = t - delt + delt*(lh-ly)/(ro.y-depth+lh-ly);
               return 1;
          }
          
          lh = depth;
          ly = ro.y;

          delt = 0.002 + (t/(40.0 * clamp(rd.y+1.0,0.0,1.0))); //detail level
    }
    return 0;
}

//////////////////////////////////////////////////////////////////////////////////////
// Converting from [-1,1] to [0,1]
//////////////////////////////////////////////////////////////////////////////////////

vec3 calculateSkySub(vec3 rd) {
    return  norm(smoothrnd(abs(rd.xy*rd.z+rd.y*2.0))) * vec3(0.15) +
            norm(smoothrnd(1.5*abs(rd.xy*rd.z+rd.y+10.0)))* vec3(0.15) +
            norm(smoothrnd(2.5*abs(rd.xy*rd.z+rd.y+20.0)))* vec3(0.15);
}

//////////////////////////////////////////////////////////////////////////////////////
// lensflare(s) circles and shapes
//////////////////////////////////////////////////////////////////////////////////////

float regShape(vec2 p, int N) {
    float f;
    float a=atan(p.x,p.y)+.2;
    float b=6.28319/float(N);
    f=smoothstep(.5,.51, cos(floor(.5+a/b)*b-a)*length(p.xy));
    return f;
}

vec3 circle(vec2 p, float size, float decay, vec3 color,vec3 color2, float dist, vec2 pos) {
    float l = length(p + pos*(dist*4.))+size/2.;
    float l2 = length(p + pos*(dist*4.))+size/3.;
    
    float c = max(00.01-pow(length(p + pos*dist), size*1.4), 0.0)*50.;
    float c1 = max(0.001-pow(l-0.3, 1./40.)+sin(l*30.), 0.0)*3.;
    float c2 =  max(0.04/pow(length(p-pos*dist/2. + 0.09)*1., 1.), 0.0)/20.;
    float s = max(00.01-pow(regShape(p*5. + pos*dist*5. + 0.9, 6) , 1.), 0.0)*5.;
    
    color = 0.5+0.5*sin(color);
    color = cos(vec3(0.44, .24, .2)*8. + dist*4.)*0.5+.5;
    vec3 f = c*color ;
    f += c1*color;
    
    f += c2*color;  
    f +=  s*color;
    return f-0.01;
}

//////////////////////////////////////////////////////////////////////////////////////
// calculate sky: horizon´s color, moon, stars, lensflares
//////////////////////////////////////////////////////////////////////////////////////

vec3 calculateSky(vec3 ro, vec3 rd) {
    
    vec3 col = vec3(0.);
    vec3 sundir = normalize( vec3(0.15, .225, 1.) );
    
    float yd = min(rd.y, 0.);
    rd.y = max(rd.y, 0.);
  
    col += vec3(.4, .4 - exp( -rd.y*20. )*.15, .0) * exp(-rd.y*9.); // Red / Green 
    col += vec3(.3, .5, .9) * (1. - exp(-rd.y*8.) ) * exp(-rd.y*.9) ; // Blue
    
    col = mix(col*1.2, vec3(.3),  1.-exp(yd*100.)); // Fog
    
    col += vec3(1.0, .8, .55) * pow( max(dot(rd,sundir),0.), 15. ) * .6; // Sun
    col += pow(max(dot(rd, sundir),0.), 150.0) *.15;

    for( float i=0.;i<10.;i++ ) {
        
         col += circle(Y.xy, pow(rnd(i*2000.)*1.8, 2.)+1.41, 0.0, circColor+i , circColor2+i, rnd(i*20.)*3.+0.2-.5, vec2(0.5,0.5));
    }

    vec3 sky = vec3(0.);

   
    float moonValue = max(0.,dot(sundir,rd));
    float moonCircle = pow(moonValue,2000.)*5.;
    moonCircle = clamp(moonCircle,0.,1.);
    sky = mix(sky, vec3(0.95,0.95,1.),moonCircle); 
    //light
    sky = mix(sky, vec3(0.2,0.95,1.), pow(moonValue,100.)*0.1);
    //less light
    sky = mix(sky, vec3(0.5,0.5,1.), pow(moonValue,20.)*0.1);

    if( Y.y > 0.65 ) {
        vec3 rds = rd;
        
        float v = 1.0/( 2. * ( 1. + rds.z ) );
        vec2 xy = vec2(rds.y * v, rds.x * v);
        float s = noise(rds.xz*134.);
        s += noise(rds.xz*370.);
        s += noise(rds.xz*870.);
        s = pow(s,19.0) * 0.00000001 * max(rd.y, 0.0 );
        if (s > 0.1) {
            vec3 backStars = vec3((1.0-sin(xy.x*20.0+Y.z*13.0*rds.x+xy.y*30.0))*.5*s,s, s); 
            col += backStars;
        }
    }
    col = mix( col, sky, 0.45 );

    rd.xy += ro.xy*eps;
    col += (calculateSkySub(normalize(rd + vec3(sin(Y.z*0.1),0.0,cos(Y.z*0.1)) * 0.1)*3.0) +
              calculateSkySub(normalize(rd + vec3(sin(Y.z*0.1),0.0,cos(Y.z*0.1)) * 0.2)*5.0)*0.6 +
              calculateSkySub(normalize(rd + vec3(sin(Y.z*0.1),0.0,cos(Y.z*0.1)) * 0.4)*7.0)*0.1 -
              calculateSkySub(normalize(rd + vec3(sin(Y.z*0.2),0.0,0) * 0.5))*1.5) * saturate(rd.y+0.1);

    return col;

}

//////////////////////////////////////////////////////////////////////////////////////
// Smooth min by IQ -> https://iquilezles.org/www/articles/smin/smin.htm
//////////////////////////////////////////////////////////////////////////////////////

float smin( float a, float b ) {
    float k = 0.95;
    float h = clamp( 0.5 + 0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

//////////////////////////////////////////////////////////////////////////////////////
// Displacement
//////////////////////////////////////////////////////////////////////////////////////

float displace(vec3 p) {
    return ((cos(1.1*p.x)*sin(1.4*p.x)*sin(1.2*p.y))+cos(0.1))* sin(Y.z);
}

//////////////////////////////////////////////////////////////////////////////////////
// Tori
//////////////////////////////////////////////////////////////////////////////////////

float torus1(vec3 p) {
        
    return length(vec2(length(p.xy) -14.24, p.z)) -1.19;
        
}

float torus(vec3 p) {
        
    return length(vec2(length(p.xz) -14.24, p.y)) -1.19;
        
}

//////////////////////////////////////////////////////////////////////////////////////
// sdLink
//////////////////////////////////////////////////////////////////////////////////////

float sdLink( vec3 p, float le, float r1, float r2 ) {
  vec3 q = vec3( p.x, max(abs(p.y)-le,0.0), p.z );
  return length(vec2(length(q.xy)-r1,q.z)) - r2;
}

//////////////////////////////////////////////////////////////////////////////////////
// sdOctahedron
//////////////////////////////////////////////////////////////////////////////////////

float sdOctahedron( vec3 p, float s) {
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

//////////////////////////////////////////////////////////////////////////////////////
// sdSphere
//////////////////////////////////////////////////////////////////////////////////////

float sdSphere (in vec3 p, in float r) {
    return length (p) - r;
}

//////////////////////////////////////////////////////////////////////////////////////
// combine
//////////////////////////////////////////////////////////////////////////////////////

float opCombine (in float d1, in float d2, in float r) {
    float h = saturate (.5 + .5 * (d2 - d1) / r);
    return mix (d2, d1, h) - r * h * (1. - h);
}

//////////////////////////////////////////////////////////////////////////////////////
// metaballs
//////////////////////////////////////////////////////////////////////////////////////

float metaballs (in vec3 p, in float factor) {
    float r1 = factor * .1 + .3 * (.5 + .5 * sin (2. * time));
    float r2 = factor * .15 + .2 * (.5 + .5 * sin (3. * time));
    float r3 = factor * .2 + .2 * (.5 + .5 * sin (4. * time));
    float r4 = factor * .25 + .1 * (.5 + .5 * sin (5. * time));

    float t = 2. * time;
    vec3 offset1 = vec3 (-.1*cos(t), .1, -.2*sin(t));
    vec3 offset2 = vec3 (.2, .2*cos(t), .3*sin(t));
    vec3 offset3 = vec3 (-.2*cos(t), -.2*sin(t), .3);
    vec3 offset4 = vec3 (.1, -.4*cos(t), .4*sin(t));
    vec3 offset5 = vec3 (.4*cos(t), -.2, .3*sin(t));
    vec3 offset6 = vec3 (-.2*cos(t), -.4, -.4*sin(t));
    vec3 offset7 = vec3 (.3*sin(t), -.6*cos(t), .6);
    vec3 offset8 = vec3 (-.3, .5*sin(t), -.4*cos(t));

    float ball1 = sdSphere (p + offset1, r4);
    float ball2 = sdSphere (p + offset2, r2);
    float metaBalls = opCombine (ball1, ball2, r1);

    ball1 = sdSphere (p + offset3, r1);
    ball2 = sdSphere (p + offset4, r3);
    metaBalls = opCombine (metaBalls, opCombine (ball1, ball2, .2), r2);

    ball1 = sdSphere (p + offset5, r3);
    ball2 = sdSphere (p + offset6, r2);
    metaBalls = opCombine (metaBalls, opCombine (ball1, ball2, .2), r3);

    ball1 = sdSphere (p + offset7, r3);
    ball2 = sdSphere (p + offset8, r4);
    metaBalls = opCombine (metaBalls, opCombine (ball1, ball2, .2), r4);

    return metaBalls;
}

//////////////////////////////////////////////////////////////////////////////////////
// distance field
//////////////////////////////////////////////////////////////////////////////////////

float isoSurface(vec3 p) {
    
    float b = 0.4;
    p = rotateX(rotateY(rotateX(rotateY(p - arrivalPos.xyz, 2.0*Y.z), 2.0*Y.z), b*sin(2.0*2.0+2.0*p.y)), b*sin(2.0*Y.z+2.0*p.x));
    
    vec3 q  = p;
    vec3 mb = p;
    
    q  *= 8.0;
    p  *= 20.0;
    mb *= 1.9;
    
    float dsp  = displace(q);
    float d    = torus(p);
    float d1   = torus1(p);
    float octa = sdOctahedron( p, 10.0 );
    float sd   = sdLink(p.zyx, 12.5, 12.0, 0.9 );
    
    return min( smin (sd, sd + dsp * 1.2), smin( d, min(d1, mix( octa + dsp, metaballs(mb, 1.0 ) + dsp * 0.05, sin(1.0+cos(Y.z)*0.5)*0.5+0.55))));
}

float traceIso(vec3 ro, vec3 rd, float mint, float maxt, float s)
{
    float lt, liso, exact, delt = (maxt-mint)/s;

    for (float t = mint; t < maxt; t += delt)
    {
        vec3 p = ro + t * rd;
        float iso = isoSurface(p);
        if (iso <= 0.0)
        {
            for(int i = 0; i < 9; i++)
            {
                exact = (lt + t) / 2.0;
                if (isoSurface(ro + exact * rd) < 0.0) t = exact;
                else lt = exact;
            }
            return exact;
        }

        lt = t;
        liso = iso;
    }

    return FAR;
}

vec3 trace(vec3 ro, vec3 rd) {
    float upperPlane = (0.1-ro.y) / rd.y;
    float finalDepth = 200.0;
    vec3 color = calculateSky(ro, rd);
    if (rd.y < -0.01 && traceTerrain(ro+rd*upperPlane, rd, finalDepth, finalDepth)>0) // prevent endless stuff and other funny %&*$
    {
        finalDepth += upperPlane;
        vec3 pos = ro+rd*finalDepth;
        vec3 normal = normalize(normalize(
                                        vec3(
                                            height(pos.xz - vec2(eps, 0.0)) - height(pos.xz + vec2(eps, 0.0)),
                                            eps*2.0,
                                            height(pos.xz - vec2(0.0, eps)) - height(pos.xz + vec2(0.0, eps))
                                            )
                                        ) +
                                        (getWaterNormal(pos*0.2)*1.5+getWaterNormal(pos*0.1)) * max(0., 1.0-finalDepth/FAR*7.0)
                            );

        color = max(0., dot(normal, lightDir)    // diffuse
                + pow(max(0., dot(normal,  normalize(lightDir-rd))), 1.5) // specular
                ) *
                calculateSky(pos, reflect(rd, normal) );

        // depth fog
        color = mix(    color,
                        calculateSky(ro, rd),
                        saturate(finalDepth/FAR*1.6 + saturate(dot(normalize(normal+rd*.2), rd)))
                    ); // sky refl and fog
    }

    return color;
}

void main(void) {

    FAR = 9.0;
    
    Y.xy = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    Y.z = time;

    rd = normalize(vec3(Y.xy - 0.5, 1.0));

    vec2 uv = gl_FragCoord.xy / resolution.xy - 0.5;
    uv.x *= resolution.x/resolution.y; //fix aspect ratio
    vec3 mouse = vec3(0.0); //vec3(mouse*resolution.xy.xy/resolution.xy,mouse*resolution.xy.z);
    
     rd = rotate_x(rd,mouse.y / pi * 0.5 );
    rd = rotate_y(rd,mouse.x / pi );

    arrivalPos = vec4( -0.85, 0.0, 2.1, 0.0);
    
    ro = vec3(.0, .25, 0.);
    float t = Y.z;

    lightPos = vec3(-400.0, 250.0, 1000.0);
    ro.y -= 0.1;
    arrivalPos.w = 0.0;

    lightDir = normalize(lightPos-ro);

    float dist = length(ro-arrivalPos.xyz)-1.0;
    float isoDistance = traceIso(ro, rd, dist, dist+2.0, 99.0);
    if (isoDistance < FAR)
    {
        ro += isoDistance * rd;
        vec3 n = normalize(vec3(
                isoSurface(vec3(ro.x-eps, ro.y, ro.z))-isoSurface(vec3(ro.x+eps, ro.y, ro.z)),
                isoSurface(vec3(ro.x, ro.y-eps, ro.z))-isoSurface(vec3(ro.x, ro.y+eps, ro.z)),
                isoSurface(vec3(ro.x, ro.y, ro.z-eps))-isoSurface(vec3(ro.x, ro.y, ro.z+eps))));
        rd = reflect(rd, n);
    }

    glFragColor = vec4(trace(ro, rd) * 1.65,1.0);
}
