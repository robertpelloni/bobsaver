#version 420

#define HorizontalAmplitude        1.00
#define VerticleAmplitude        1.00
#define HorizontalSpeed            0.10
#define VerticleSpeed            0.50
#define ParticleMinSize            1.96
#define ParticleMaxSize            1.91
#define ParticleBreathingSpeed        0.30
#define ParticleColorChangeSpeed    0.70
#define ParticleCount            200.0
#define ParticleColor1            vec3(9.0, 9.0, 0.0)
#define ParticleColor2            vec3(9.0, 9.0, 0.0)
#define PASS_COUNT 1
// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//adapted by coler706@gmail.com from shader toy

// Volumetric clouds. It performs level of detail (LOD) for faster rendering
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}
float fBrightness = 2.5;

// Number of angular segments
float fSteps = 121.0;

float fParticleSize = 0.015;
float fParticleLength = 0.5 / 60.0;

// Min and Max star position radius. Min must be present to prevent stars too near camera
float fMinDist = 0.8;
float fMaxDist = 5.0;

float fRepeatMin = 1.0;
float fRepeatMax = 2.0;

// fog density
float fDepthFade = 0.8;

float Random(float x)
{
    return fract(sin(x * 123.456) * 23.4567 + sin(x * 345.678) * 45.6789 + sin(x * 456.789) * 56.789);
}

vec3 GetParticleColour( const in vec3 vParticlePos, const in float fParticleSize, const in vec3 vRayDir )
{        
    vec2 vNormDir = normalize(vRayDir.xy);
    float d1 = dot(vParticlePos.xy, vNormDir.xy) / length(vRayDir.xy);
    vec3 vClosest2d = vRayDir * d1;
    
    vec3 vClampedPos = vParticlePos;
    
    vClampedPos.z = clamp(vClosest2d.z, vParticlePos.z - fParticleLength, vParticlePos.z + fParticleLength);
    
    float d = dot(vClampedPos, vRayDir);
    
    vec3 vClosestPos = vRayDir * d;
    
    vec3 vDeltaPos = vClampedPos - vClosestPos;    
        
    float fClosestDist = length(vDeltaPos) / fParticleSize;
    
    float fShade =     clamp(1.0 - fClosestDist, 0.0, 1.0);
        
    fShade = fShade * exp2(-d * fDepthFade) * fBrightness;
    
    return vec3(fShade,fShade,0.0);
}

vec3 GetParticlePos( const in vec3 vRayDir, const in float fZPos, const in float fSeed )
{
    float fAngle = atan(vRayDir.x, vRayDir.y);
    float fAngleFraction = fract(fAngle / (3.14 * 2.0));
    
    float fSegment = floor(fAngleFraction * fSteps + fSeed) + 0.5 - fSeed;
    float fParticleAngle = fSegment / fSteps * (3.14 * 2.0);

    float fSegmentPos = fSegment / fSteps;
    float fRadius = fMinDist + Random(fSegmentPos + fSeed) * (fMaxDist - fMinDist);
    
    float tunnelZ = vRayDir.z / length(vRayDir.xy / fRadius);
    
    tunnelZ += fZPos;
    
    float fRepeat = fRepeatMin + Random(fSegmentPos + 0.1 + fSeed) * (fRepeatMax - fRepeatMin);
    
    float fParticleZ = (ceil(tunnelZ / fRepeat) - 0.5) * fRepeat - fZPos;
    
    return vec3( sin(fParticleAngle) * fRadius, cos(fParticleAngle) * fRadius, fParticleZ );
}

vec3 Starfield( const in vec3 vRayDir, const in float fZPos, const in float fSeed )
{    
    vec3 vParticlePos = GetParticlePos(vRayDir, fZPos, fSeed);
    
    return GetParticleColour(vParticlePos, fParticleSize, vRayDir);    
}

vec3 RotateX( const in vec3 vPos, const in float fAngle )
{
    float s = sin(fAngle);
    float c = cos(fAngle);
    
    vec3 vResult = vec3( vPos.x, c * vPos.y + s * vPos.z, -s * vPos.y + c * vPos.z);
    
    return vResult;
}

vec3 RotateY( const in vec3 vPos, const in float fAngle )
{
    float s = sin(fAngle);
    float c = cos(fAngle);
    
    vec3 vResult = vec3( c * vPos.x + s * vPos.z, vPos.y, -s * vPos.x + c * vPos.z);
    
    return vResult;
}

vec3 RotateZ( const in vec3 vPos, const in float fAngle )
{
    float s = sin(fAngle);
    float c = cos(fAngle);
    
    vec3 vResult = vec3( c * vPos.x + s * vPos.y, -s * vPos.x + c * vPos.y, vPos.z);
    
    return vResult;
}

vec3 stars( vec2 fragCoord,in vec3 ro,in vec3 rd )
{
    vec2 vScreenUV = fragCoord.xy / resolution.xy;
    
    vec2 vScreenPos = vScreenUV * 2.0 - 1.0;
    vScreenPos.x *= resolution.x / resolution.y;

    vec3 vRayDir = rd;//normalize(vec3(vScreenPos, 1.0));

    vec3 vEuler = vec3(0.5 + sin(time * 0.2) * 0.125, 0.5 + sin(time * 0.1) * 0.125, time * 0.1 + sin(time * 0.3) * 0.5);
            
    /*if(iMouse.z > 0.0)
    {
        vEuler.x = -((iMouse.y / iResolution.y) * 2.0 - 1.0);
        vEuler.y = -((iMouse.x / iResolution.x) * 2.0 - 1.0);
        vEuler.z = 0.0;
    }
    */    
    /*vRayDir = RotateX(vRayDir, vEuler.x);
    vRayDir = RotateY(vRayDir, vEuler.y);
    vRayDir = RotateZ(vRayDir, vEuler.z);*/
    
    float fShade = 0.0;
        
    float a = 0.2;
    float b = 10.0;
    float c = 1.0;
    float fZPos = -time;
    float fSpeed = 0.0;//c + a * b * cos(a * time);
    
    fParticleLength = 0.25 * fSpeed / 60.0;
    
    float fSeed = 0.0;
    
    vec3 vResult = mix(vec3(0.005, 0.0, 0.01), vec3(0.01, 0.005, 0.0), vRayDir.y * 0.5 + 0.5);
    
    for(int i=0; i<PASS_COUNT; i++)
    {
        vResult += Starfield(vRayDir, fZPos, fSeed);
        fSeed += 1.234;
    }
    
    return vec3(sqrt(vResult));
}
float map5( in vec3 p )
{
    vec3 q = p - vec3(0.0,0.1,1.0)*time;
    float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q ); q = q*2.01;
    f += 0.06250*noise( q ); q = q*2.02;
    f += 0.03125*noise( q );
    return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}

float map4( in vec3 p )
{
    vec3 q = p - vec3(0.0,0.1,1.0)*time;
    float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q ); q = q*2.01;
    f += 0.06250*noise( q );
    return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}
float map3( in vec3 p )
{
    vec3 q = p - vec3(0.0,0.1,1.0)*time;
    float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q );
    return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}
float map2( in vec3 p )
{
    vec3 q = p - vec3(0.0,0.1,1.0)*time;
    float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q );;
    return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}

vec3 sundir = normalize( vec3(-1.0,0.0,-1.0) );

vec4 integrate( in vec4 sum, in float dif, in float den, in vec3 bgcol, in float t )
{
    // lighting
    vec3 lin = vec3(0.65,0.7,0.75)*1.4 + vec3(1.0, 0.6, 0.3)*dif;        
    vec4 col = vec4( mix( vec3(1.0,0.95,0.8), vec3(0.25,0.3,0.35), den ), den );
    col.xyz *= lin;
    col.xyz = mix( col.xyz, bgcol, 1.0-exp(-0.003*t*t) );
    // front to back blending    
    col.a *= 0.4;
    col.rgb *= col.a;
    return sum + col*(1.0-sum.a);
}

#define MARCH(STEPS,MAPLOD) for(int i=0; i<STEPS; i++) { vec3  pos = ro + t*rd; if( pos.y<-3.0 || pos.y>2.0 || sum.a > 0.99 ) break; float den = MAPLOD( pos ); if( den>0.01 ) { float dif =  clamp((den - MAPLOD(pos+0.3*sundir))/0.6, 0.0, 1.0 ); sum = integrate( sum, dif, den, bgcol, t ); } t += max(0.05,0.02*t); }

vec4 raymarch( in vec3 ro, in vec3 rd, in vec3 bgcol )
{
    vec4 sum = vec4(0.0);

    float t = 0.0;

    MARCH(30,map5);
    MARCH(30,map4);
    MARCH(30,map3);
    MARCH(30,map2);

    return clamp( sum, 0.0, 1.0 );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}
vec3 particles( vec2 uv )
{
    vec2 pos = uv * 2.0 - 1.0;
    pos.x *= (resolution.y / resolution.x)/2.0;
    pos.y *= (resolution.y / resolution.x)/2.0;
    
    vec3 c = vec3( 0, 0, 0 );
    
    for( float i = 1.0; i < ParticleCount+1.0; ++i )
    {
        float cs = cos( time * HorizontalSpeed * (i/ParticleCount) ) * HorizontalAmplitude;
        float ss = sin( time * VerticleSpeed   * (i/ParticleCount) ) * VerticleAmplitude;
        vec2 origin = vec2( cs , ss );
        
        float t = sin( time * ParticleBreathingSpeed * i ) * 0.5 + 0.5;
        float particleSize = mix( ParticleMinSize, ParticleMaxSize, t );
        float d = clamp( sin( length( pos - origin )  + particleSize ), 0.0, particleSize);
        
        float t2 = sin( time * ParticleColorChangeSpeed * i ) * 0.5 + 0.5;
        vec3 color = mix( ParticleColor1, ParticleColor2, t2 );
        c += color * pow( d, 70.0 );
    }
    
    return c;
}
vec4 render( in vec3 ro, in vec3 rd )
{
    // background sky     
    float sun = clamp( dot(sundir,rd), 0.0, 1.0 );
    vec3 col = vec3(0.6,0.71,0.75)*0.1 - rd.y*0.2*vec3(1.0,0.5,1.0) + 0.15*0.5;
    col += 0.2*vec3(1.0,.6,0.1)*pow( sun, 8.0 );

    // clouds    
    vec4 res = raymarch( ro, rd, col );
    col = col*(1.0-res.w) + res.xyz;
    
    // sun glare    
    col += 0.2*vec3(1.0,0.4,0.2)*pow( sun, 3.0 );

    return vec4( col, 1.0 );
}

void main( void )
{
    vec2 fragCoord=gl_FragCoord.xy;
    vec2 p = (-resolution.xy + 2.0*fragCoord.xy)/ resolution.y;

    vec2 m = mouse.xy/resolution.xy;
    
    // camera
    vec3 ro = 4.0*normalize(vec3(sin(3.0*m.x), 0.5*m.y+0.5, cos(3.0*m.x)));
    vec3 ta = vec3(0.0, -1.0, 0.0);
    mat3 ca = setCamera( ro, ta, 0.0 );
    // ray
    vec3 rd = ca * normalize( vec3(p.xy,1.5));
    
    glFragColor = render( ro, rd )+vec4(stars(fragCoord,ro,rd),1.0);
}

void mainVR( out vec4 fragColor, in vec2 fragCoord, in vec3 fragRayOri, in vec3 fragRayDir )
{
    fragColor = render( fragRayOri, fragRayDir );
}
