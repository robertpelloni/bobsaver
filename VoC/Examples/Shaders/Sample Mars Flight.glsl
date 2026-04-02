#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Mars Flight.
// Uses sphere tracing to accumulate direction normals across the landscape.
// Materials are calculated after the tracing loop,
// so only the normal can be used as reference.
// Sphere diameter to create depth of field is distance squared.
// For red/cyan 3D...
/////////////////////  Feel free to use it ;-)

// #define STEREO

// #define FASTER_LANDSCAPE

vec3 sunLight  = normalize( vec3(  0.35, 0.1,  0.3 ) );
vec3 cameraPos;
vec3 sunColour = vec3(1.0, .75, .4);
const mat2 rotate2D = mat2(1.732, 1.323, -1.523, 1.652);
float gTime = 0.0;

//--------------------------------------------------------------------------
// Noise functions...
float Hash( float n )
{
    return fract(sin(n)*33753.545383);
}

#ifdef FASTER_LANDSCAPE
//--------------------------------------------------------------------------
float Noise( in vec2 p )
{
    p+= vec2(13.323);
    p *= 0.024;
    return  texture2D( iChannel0, p ,-99.0).x;
}

//--------------------------------------------------------------------------
float Terrain( in vec2 p)
{
    vec2 pos = p*0.002;
    float w = 110.0;
    float f = .0;
    vec2  d = vec2(0.0);
    for (int i = 0; i < 5; i++)
    {
        f += Noise(pos) * w;
        w = w * 0.5;
        pos = rotate2D * pos;
    }

    return f;
}

//--------------------------------------------------------------------------
float Terrain2( in vec2 p, in float sphereR)
{
    vec2 pos = p*0.002;
    float w = 110.0;
    float f = .0;
    vec2  d = vec2(0.0);
    // Set a limit to the loop as further away terrain doesn't need fine detail.
    int t = 11-int(sphereR);
    if (t < 5) t = 5;
    
    for (int i = 0; i < 10; i++)
    {
        if (i > t) continue;
        f += Noise(pos) * w;
        w = w * 0.5;
        pos = rotate2D * pos;
    }

    return f;
}
#else
//--------------------------------------------------------------------------
vec3 NoiseD( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);

    vec2 u = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0;

    float a = Hash(n+  0.0);
    float b = Hash(n+  1.0);
    float c = Hash(n+ 57.0);
    float d = Hash(n+ 58.0);
    return vec3(a+(b-a)*u.x+(c-a)*u.y+(a-b-c+d)*u.x*u.y,
                30.0*f*f*(f*(f-2.0)+1.0)*(vec2(b-a,c-a)+(a-b-c+d)*u.yx));
}

//--------------------------------------------------------------------------
float Terrain( in vec2 p)
{
    vec2 pos = p*0.0035;
    float w = 70.0;
    float f = .0;
    vec2  d = vec2(0.0);
    for (int i = 0; i < 5; i++)
    {
        //f += Noise(pos) * w;
        vec3 n = NoiseD(pos);
        d += n.yz;
        f += w * n.x/(1.0+dot(d,d));
        w = w * 0.53;
        pos = rotate2D * pos;
    }

    return f;
}

//--------------------------------------------------------------------------
float Terrain2( in vec2 p, in float sphereR)
{
    vec2 pos = p*0.0035;
    float w = 70.0;
    float f = .0;
    vec2  d = vec2(0.0);
    // Set a limit to the loop as further away terrain doesn't need fine detail.
    int t = 11-int(sphereR);
    if (t < 5) t = 5;
    
    for (int i = 0; i < 10; i++)
    {
        if (i > t) continue;
        vec3 n = NoiseD(pos);
        d += n.yz;
        f += w * n.x/(1.0+dot(d,d));
        w = w * 0.53;
        pos = rotate2D * pos;
    }

    return f;
}
#endif
//--------------------------------------------------------------------------
float Map(in vec3 p)
{
    float h = Terrain(p.xz);
    return p.y - h;
}

//--------------------------------------------------------------------------
// Grab all sky information for a given ray from camera
vec3 GetSky(in vec3 rd)
{
    float sunAmount = max( dot( rd, sunLight), 0.0 );
    float v = pow(1.0-max(rd.y,0.0),6.);
    vec3  sky = mix(vec3(.015,0.0,.01), vec3(.42, .2, .1), v);
    //sky *= smoothstep(-0.3, .0, rd.y);
    sky = sky + sunColour * sunAmount * sunAmount * .25;
    sky = sky + sunColour * min(pow(sunAmount, 800.0)*1.5, .3);
    return clamp(sky, 0.0, 1.0);
}

//--------------------------------------------------------------------------
float SphereRadius(float t)
{
    t = abs(t-120.0);
    return clamp(t*t*0.0001, 350.0/resolution.y, 100.0);
}

//--------------------------------------------------------------------------
float Linstep(float a, float b, float t)
{
    return clamp((t-a)/(b-a),0.,1.);
}

//--------------------------------------------------------------------------
// Calculate sun light...
vec3 DoLighting(in vec3 mat, in vec3 normal, in vec3 eyeDir)
{
    float h = dot(sunLight,normal);
    mat = mat * sunColour*(max(h, 0.0));
    mat += vec3(0.04, .02,.02) * max(normal.y, 0.0);
    return mat;
}

//--------------------------------------------------------------------------
vec3 GetNormal(vec3 p, float sphereR)
{
    vec2 j = vec2(sphereR, 0.0);
    vec3 nor      = vec3(0.0,        Terrain2(p.xz, sphereR), 0.0);
    vec3 v2        = nor-vec3(j.x,    Terrain2(p.xz+j, sphereR), 0.0);
    vec3 v3        = nor-vec3(0.0,    Terrain2(p.xz-j.yx, sphereR), -j.x);
    nor = cross(v2, v3);
    return normalize(nor);
}

//--------------------------------------------------------------------------
vec4 Scene(in vec3 rO, in vec3 rD)
{
    float t = 0.0;
    float alpha;
    vec4 normal = vec4(0.0);
    vec3 p = vec3(0.0);
    for( int j=0; j < 100; j++ )
    {
        if (normal.w > .8 || t > 1500.0) break;
        p = rO + t*rD;
        float sphereR = SphereRadius(t);
        float h = Map(p);
        h += sphereR * .5;
        if( h < sphereR)
        {
            // Accumulate the normals...
            vec3 nor = GetNormal(p, sphereR);
            alpha = (1.0 - normal.w) * Linstep(-sphereR, sphereR, -h);
            normal += vec4(nor * alpha, alpha);
        }
        t += h*(.55 + clamp(t*.001,0.0, 0.45)) + .1;
    }
    // Scale the alpha up to 1.0...
    normal.w = clamp(normal.w * 1.25, 0.0, 1.0);
    // Fog...   :)
    normal.w /= 1.0+smoothstep(50.0, 2500.0, t);
    return normal;
}

//--------------------------------------------------------------------------
vec3 CameraPath( float t )
{
    vec2 p = vec2(200.0 * sin(3.54*t), 200.0 * cos(2.0*t) );
    return vec3(p.x+420.0,  0.0, -655.0+p.y);
} 

float Hash(vec2 p)
{
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 33758.5453)-.5;
}

//--------------------------------------------------------------------------
vec3 PostEffects(vec3 rgb, vec2 xy)
{
    // Gamma first...
    rgb = pow(rgb, vec3(0.45));

    // Then...
    #define CONTRAST 1.2
    #define SATURATION 1.3
    #define BRIGHTNESS 1.4
    rgb = mix(vec3(.5), mix(vec3(dot(vec3(.2125, .7154, .0721), rgb*BRIGHTNESS)), rgb*BRIGHTNESS, SATURATION), CONTRAST);
    // Noise...
    // rgb = clamp(rgb+Hash(xy*iGlobalTime)*.1, 0.0, 1.0);
    // Vignette...
    rgb *= .4+0.5*pow(40.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.2 );    

    return rgb;
}

//--------------------------------------------------------------------------
void main(void)
{
    float m = (mouse.x)*300.0;
    float gTime = (time*5.0+m+2352.0)*.006;
        vec2 xy = gl_FragCoord.xy / resolution.xy;
    vec2 uv = (-1.0 + 2.0 * xy) * vec2(resolution.x/resolution.y,1.0);
    vec3 camTar;
    
    float hTime = mod(gTime+1.85, 2.0);
    
    #ifdef STEREO
    float isCyan = mod(gl_FragCoord.x + mod(gl_FragCoord.y,2.0),2.0);
    #endif

    cameraPos = CameraPath(gTime + 0.0);

    //float height = 300.-hTime*24.0;
    float height = (smoothstep(.3, 0.0, hTime) + smoothstep(1.7, 2.0, hTime)) * 300.0;
    camTar     = CameraPath(gTime + .3);
    cameraPos.y += height;
    
    float t = Terrain(CameraPath(gTime + .009).xz)+11.0;
    if (cameraPos.y < t) cameraPos.y = t;
    camTar.y = cameraPos.y-clamp(height-40.0, 0.0, 100.0);

    float roll = .4*sin(gTime+.5);
    vec3 cw = normalize(camTar-cameraPos);
    vec3 cp = vec3(sin(roll), cos(roll),0.0);
    vec3 cu = cross(cw,cp);
    vec3 cv = cross(cu,cw);
    vec3 dir = normalize(uv.x*cu + uv.y*cv + 1.3*cw);
    mat3 camMat = mat3(cu, cv, cw);

    #ifdef STEREO
    cameraPos += .85*cu*isCyan; // move camera to the right - the rd vector is still good
    #endif

    vec3 col;
    float distance;
    vec4 normal;
    normal = Scene(cameraPos, dir);
    normal.xyz = normalize(normal.xyz);
    col = mix(vec3(.5, 0.5, 0.4), vec3(.7, .35, .1),smoothstep(0.8, 1.1, (normal.y)));
    col = mix(col, vec3(0.17, 0.05, 0.0), clamp(normal.z+.2, 0.0, 1.0));
    col = mix(col, vec3(1.), clamp((normal.x-.6)*1.3, 0.0, 1.0));

    if (normal.w > 0.0) col = DoLighting(col, normal.xyz, dir);

    col = mix(GetSky(dir), col, normal.w);

    // bri is the brightness of sun at the centre of the camera direction.
    // Yeah, the lens flares is not exactly subtle, but it was good fun making it.
    float bri = dot(cw, sunLight)*.7;
    if (bri > 0.0)
    {
        vec2 sunPos = vec2( dot( sunLight, cu ), dot( sunLight, cv ) );
        vec2 uvT = uv-sunPos;
        uvT = uvT*(length(uvT));
        bri = pow(bri, 6.0)*.8;

        // glare = the red shifted blob...
        float glare1 = max(dot(normalize(vec3(dir.x, dir.y+.3, dir.z)),sunLight),0.0)*1.4;
        // glare2 is the yellow ring...
        float glare2 = max(1.0-length(uvT+sunPos*.5)*4.0, 0.0);
        uvT = mix (uvT, uv, -2.3);
        // glare3 is a purple splodge...
        float glare3 = max(1.0-length(uvT+sunPos*5.0)*1.2, 0.0);

        col += bri * vec3(1.0, .0, .0)  * pow(glare1, 12.5)*.05;
        col += bri * vec3(1.0, .5, 0.5) * pow(glare2, 2.0)*2.5;
        col += bri * sunColour * pow(glare3, 2.0)*3.0;
    }
    col = PostEffects(col, xy);    
    
    #ifdef STEREO    
    col *= vec3( isCyan, 1.0-isCyan, 1.0-isCyan );    
    #endif
    
    glFragColor=vec4(col,1.0);
}

