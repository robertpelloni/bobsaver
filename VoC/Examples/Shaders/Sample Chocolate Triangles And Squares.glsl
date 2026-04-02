#version 420

// original https://www.shadertoy.com/view/ddGBRc

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    
Simple Semi-regular 3,3,4,3,4 Extrusion 

You can play with the mouse to change the colors or changing the code

References

    Shane - Semi-regular 3,3,4,3,4 Extrusion 
    https://www.shadertoy.com/view/DllSWB
    
    Nimitz - Cairo tiling 
    https://www.shadertoy.com/view/4ssSWf
    
    Live Coding: Cairo Tiling Explained! - The Art of Code
    https://youtu.be/51LwM2R_e_o?si=WK5B6F_dvMVV-2l-
    
    Wythoff Uniform Tilings + Duals - Fizzer 
    https://www.shadertoy.com/view/3tyXWw
    
    Parallelogram Grid - Shane (unlisted)
    https://www.shadertoy.com/view/dlBSRG
    
    IQ Distance functions
    https://iquilezles.org/articles/distfunctions
    https://iquilezles.org/articles/distfunctions2d
    
    resolution, mouse*resolution.xy, date, etc - Fabrice Neyret
    https://www.shadertoy.com/view/llySRh
    
    Palettes - IQ
    https://www.shadertoy.com/view/ll2GD3
    
    Snub square tiling - Wikipedia
    https://en.wikipedia.org/wiki/Snub_square_tiling

*/

const float squareOneId = 5.7;
const float squareTwoId = 6.;
const float triangleOneId =4.2;
const float triangleTwoId = 5.5;
const float triangleThreeId = 5.8;
const float triangleFourId = 4.9;

float hash( vec2 f )
{   uvec2 x = floatBitsToUint(f),
          q = 1103515245U * ( x>>1U ^ x.yx    );
    return float( 1103515245U * (q.x ^ q.y>>3U) ) / float(0xffffffffU);
}

const float maxHeight = .35;

float getHeight(vec2 cell)
{
    return hash(cell)*maxHeight*.8;
}

float opExtrussion( in vec3 p, in float sdf, in float h )
{
    vec2 w = vec2( sdf, p.y - h );
      return min(max(w.x,w.y),0.0) + length(max(w,0.0));
}

float sdColumn(vec3 p, vec4 cell, float sdf, float h)
{
    const float rounding = 0.02;
    float d = opExtrussion(p,sdf,h-sdf*.2); // nice rooftop trick
    return d-rounding;
}

float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

const float PI=3.141592;
const float shapeSize = .25/cos(PI/12.);
const float margin = .03;

float sdEquilateralTriangle(  in vec2 p, in float r )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    if( p.x+k*p.y>0.0 ) p=vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0*r, 0.0 );
    return -length(p)*sign(p.y);
}

vec2 opU(vec2 a, vec2 b)
{
    return a.x < b.x ? a : b;
}

vec4 getCell(vec2 p)
{
    vec2 id = floor(p);
    p -= id + .5;
    return vec4(p,id);
}

mat2 rot(float a) {
    float s=sin(a), c=cos(a);
    return mat2(c, -s, s, c);
}

vec4 rotatedCell(vec4 cell,float an)
{
    cell.xy *= rot(an);
    return cell;
}

vec2 sdSquaresWithHoles(vec3 p)
{
    const vec2 off = vec2(-.25,-.25);
    vec4 cell = rotatedCell(getCell(p.xz - off),PI/12.);
    float sdf = sdBox(cell.xy, vec2(shapeSize-margin));
    sdf = max(sdf,-sdBox(abs(cell.xy)-margin*3., vec2(margin*2.)));    
    float d = sdColumn(p,cell,sdf,getHeight(cell.zw + off));
    return vec2(d,squareOneId);
}

vec2 sdSolidSquares(vec3 p)
{
    const vec2 off = vec2(.25,.25);
    vec4 cell = rotatedCell(getCell(p.xz - off),-PI/12.);
    float sdf = sdBox(cell.xy, vec2(shapeSize-margin));
    float d = sdColumn(p,cell,sdf,getHeight(cell.zw + off));
    return vec2(d,squareTwoId);
}

vec2 sdFirstTwoTriangles(vec3 p)
{
    vec2 off = vec2(.25,-.25);
    float size = shapeSize-margin*2.;
    vec4 cell = getCell(p.xz - off);
    cell.xy = (cell.xy + vec2(-cell.y, cell.x))*sqrt(0.5);
    return opU(
        vec2(sdColumn(p,cell,sdEquilateralTriangle(vec2(cell.x, cell.y - margin), size),getHeight(cell.zw+off+.1)),triangleOneId),
        vec2(sdColumn(p,cell,sdEquilateralTriangle(vec2(cell.x,-cell.y - margin), size),getHeight(cell.zw+off-.1)),triangleTwoId));
}

vec2 sdSecondTwoTriangles(vec3 p)
{
    vec2 off = vec2(-.25,.25);
    float size = shapeSize-margin*2.;
    vec4 cell = getCell(p.xz - off);
    cell.xy = (cell.xy + vec2(cell.y, -cell.x))*sqrt(0.5);
    return opU(
        vec2(sdColumn(p,cell,sdEquilateralTriangle(vec2(cell.x, cell.y - margin), size),getHeight(cell.zw+off+.1)),triangleThreeId),
        vec2(sdColumn(p,cell,sdEquilateralTriangle(vec2(cell.x,-cell.y - margin), size),getHeight(cell.zw+off-.1)),triangleFourId));
}

vec2 getDist2(vec3 p) {
    vec2 dm = vec2(1e10,0.);
    dm = opU(dm,sdSquaresWithHoles(p));
    dm = opU(dm,sdSolidSquares(p));
    dm = opU(dm,sdFirstTwoTriangles(p));
    dm = opU(dm,sdSecondTwoTriangles(p));
    return dm;
}

float getDist(vec3 p)
{
    return getDist2(p).x;
}

const float maxDistance=10.;

float rayMarch(vec3 ro, vec3 rd) {
    const float surfaceDist=.001;
    float dO=(maxHeight-ro.y)/rd.y;
    for(int i=0; i<100; i++) {
        vec3 p = ro + rd*dO;
        float dS = getDist(p);
        dO += dS;
        if(dO>maxDistance || abs(dS)<surfaceDist) break;
    }
    return dO;
}

vec3 getNormal(vec3 p) {
    vec2 e = vec2(.001, 0);
    vec3 n = getDist(p) - 
        vec3(getDist(p-e.xyy), getDist(p-e.yxy),getDist(p-e.yyx));
    
    return normalize(n);
}

vec3 getRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 
        f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u;
    return normalize(i);
}

float calcOcclusion( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.11*float(i)/4.0;
        vec3 opos = pos + h*nor;
        float d = getDist(opos);
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 2.0*occ, 0.0, 1.0 );
}

vec2 path(float z)
{
    return vec2(sin(z*.8)*.35,0.);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float t = time*.5;
    vec3 ta = vec3(0, 0, t);
    vec3 ro = ta+vec3(0,1.0,-1.5);
    ro.xy += path(ro.z);
    ta.xy += path(ta.z);
    uv *= rot(sin(t)*.05);
    vec3 rd = getRayDir(uv, ro, ta, 1.);
    vec3 lp = ro+vec3(0,0,1.0);
    vec3 col = vec3(0);
    float d = rayMarch(ro, rd);
    if(d<maxDistance) {
        vec3 p = ro + rd * d;
        vec3 n = getNormal(p);
        vec3 ld = normalize(lp-p);
        float m = getDist2(p).y;
        vec3 c = vec3(.5);
        if ( m > 0.0 ) {
            vec2 mse = vec2(.3,1.);
            //if ( mouse*resolution.xy.x > 0.0 )
            //    mse = mouse*resolution.xy.xy/resolution.xy;
            c = .5+.48*cos(6.2832*mse.x+vec3(0,1,2)*mse.y+m); // Palette https://www.shadertoy.com/view/Dddfz7
        }
        float dif = dot(n, ld)*.8+.2;
        float spe = pow(clamp(dot(n,normalize(ld-rd)),0.0,1.0),8.0) * dif; // Blinn 
        float occ = calcOcclusion(p,n);
        col = dif*c*occ;
        col += spe;
    }
    col = mix(vec3(0),col,exp(-d*.5)); // fog
    col = pow(col, vec3(.4545));    // gamma correction
    glFragColor = vec4(col,1.0);
}