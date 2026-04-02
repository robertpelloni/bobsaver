#version 420

// original https://www.shadertoy.com/view/WljXzy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Shader by Anton.

#define PI 3.14159

#define REP(p, r) (mod(p + r/2.,r) - r/ 2.)

// smin by iq
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

// from https://www.shadertoy.com/view/4djSRW
float hash11(float p)
{
    p = fract(p * .1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

// hash and noise from shane's : https://www.shadertoy.com/view/ldscWH
vec3 hash33(vec3 p) { 

    float n = sin(dot(p, vec3(7, 157, 113)));    
    return fract(vec3(2097152, 262144, 32768)*n)*2. - 1.;
}

float tetraNoise(in vec3 p)
{
    vec3 i = floor(p + dot(p, vec3(0.333333)) );  p -= i - dot(i, vec3(0.166666)) ;
    
    vec3 i1 = step(p.yzx, p), i2 = max(i1, 1.0-i1.zxy); i1 = min(i1, 1.0-i1.zxy);    
    
    vec3 p1 = p - i1 + 0.166666, p2 = p - i2 + 0.333333, p3 = p - 0.5;
  
    vec4 v = max(0.5 - vec4(dot(p,p), dot(p1,p1), dot(p2,p2), dot(p3,p3)), 0.0);
    vec4 d = vec4(dot(p, hash33(i)), dot(p1, hash33(i + i1)), dot(p2, hash33(i + i2)), dot(p3, hash33(i + 1.)));
    
    return clamp(dot(d, v*v*v*8.)*1.732 + .5, 0., 1.); 
}

mat2 mrn = mat2(0.8, -0.6, 0.6,0.8);
float animatedNoise(vec2 p)
{
    p*= .25;
    float t = time * .04;
    float h =0.;
    float amp = 1.;
    float freq = 1.;
    for(float i = 1.; i < 4.; ++i)
    {
        amp *= .9; 
        freq *= 2.5;
        h += sin(p.x * freq * .5) * amp;
        p*= mrn;
         p += t * (i-1.);
        h+= sin(p.y * freq * .45) * amp;
    }
    
    return h;
}

// Hexagonal Prism - exact by iq
float sdHexPrism( vec3 p, vec2 h )
{
    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2(
       length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
       p.z-h.y );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float hexDist(vec2 p) {
    p = abs(p);
    
    float c = dot(p, normalize(vec2(1,1.73)));
    c = max(c, p.x);
    
    return c;
}
vec4 hexCoord(vec2 uv)
{
    vec2 r = vec2(1.,1.73);
    vec2 h = r * .5;
    vec2 a = mod(uv, r) - h;
    vec2 b = mod(uv - h, r) - h;
    
    vec2 gv;
    if(length(a) < length(b))
    {
        gv = a;
    }
    else
    {
        gv = b;
    }
    
    vec2 id = uv - gv;
    
    return vec4(gv, id);
}

float getTileType(vec2 p)
{
    float id = floor(tetraNoise(p.xyy) * 6.);

    id = min(id-1., 2.);
    return id;
}

float sqLength(vec2 v)
{
    return dot(v,v);
}

const vec4 idDelta = vec4(1.,0.,-1.,0.);
const vec4 idDeltb = vec4(.5,.866,-.5,-.866);

const vec4 tileDelta = vec4(.5, 0., -.5, 0.);
const vec4 tileDeltb = vec4(.25,.433,-.25,-.433) ;

#define FLOAT_EQ(a ,b) (abs(a-b) < .1)

#define BPM (90. / 60.)
float bpmTime(float t)
{
    float ft = fract(t);
    return floor(t) + ft * ft;
}

const float gridScale = 10.;

int idMat = 0;
vec2 mat = vec2(0.,0.);
float morph;

float map(vec3 p)
{
    float basePlan = p.y + 1.;
    
    // tring to match the speed of www.youtube.com/watch?v=AwMpGIm1Dyo
    float time = (time * BPM * 8.957);
    
    p.z += time;
    
    
    vec4 hg = hexCoord(p.xz / gridScale);
    float tideTime = time / gridScale + hash11(hg.z) * .35;
    //tideTime = floor(tideTime);
    float stepLength = 1. / .557 * .5;
    tideTime = bpmTime(tideTime / stepLength) * stepLength;
    float ti = hg.w  - (tideTime) - 2.;
    float tide = max(0., ti) * 10.;
    
    morph = 1. - clamp(ti, 0., 1.);
    
    p.y /= morph;
    
    
    float baseHeight = p.y;
    float hexHeight = smoothstep(hg.y - .0001, -.005, .005);
    
    float id = getTileType(hg.zw);
    bool id_tl = FLOAT_EQ( id, getTileType(hg.zw + idDeltb.zy));
    bool id_tr = FLOAT_EQ( id, getTileType(hg.zw + idDeltb.xy));
    bool id_ml = FLOAT_EQ( id, getTileType(hg.zw + idDelta.zw));
    bool id_mr = FLOAT_EQ( id, getTileType(hg.zw + idDelta.xy));
    bool id_bl = FLOAT_EQ( id, getTileType(hg.zw + idDeltb.zw));
    bool id_br = FLOAT_EQ( id, getTileType(hg.zw + idDeltb.xw));
    
    bool c_up = id_tl && id_tr;
    bool c_tr = id_tr && id_mr;
    bool c_br = id_mr && id_br;
    bool c_do = id_br && id_bl;
    bool c_bl = id_bl && id_ml;
    bool c_tl = id_ml && id_tl;
    
    float innerRadius = 60.;
    float innerSmoothFactor = 10.;
    
    float elevation = sqLength(hg.xy) * innerRadius;
    
    // top left
    if(id_tl)
    {
        elevation = smin(elevation, sqLength(hg.xy + tileDeltb.xw) * innerRadius, innerSmoothFactor);
    }
    //top right
    if(id_tr)
    {
        elevation = smin(elevation, sqLength(hg.xy + tileDeltb.zw) * innerRadius, innerSmoothFactor);
    }
    //middle_left
    if(id_ml)
    {
        elevation = smin(elevation, sqLength(hg.xy + tileDelta.xy) * innerRadius, innerSmoothFactor);
    }
    //middle right
    if(id_mr)
    {
        elevation = smin(elevation, sqLength(hg.xy + tileDelta.zw) * innerRadius, innerSmoothFactor);
    }
    //bottom left
    if(id_bl)
    {
        elevation = smin(elevation, sqLength(hg.xy + tileDeltb.xy) * innerRadius, innerSmoothFactor);
    }
    //bottom right
    if(id_br)
    {
        elevation = smin(elevation, sqLength(hg.xy + tileDeltb.zy) * innerRadius, innerSmoothFactor);
    }

    // up
    if(c_up)
    {
        elevation = smin(elevation, sqLength(hg.xy - tileDelta.yx) * innerRadius, innerSmoothFactor);
    }
    // corner top right
    if(c_tr)
    {
        elevation = smin(elevation, sqLength(hg.xy - tileDeltb.yx) * innerRadius, innerSmoothFactor);
    }
    // corner bottom right
    if(c_br)
    {
        elevation = smin(elevation, sqLength(hg.xy - tileDeltb.yz) * innerRadius, innerSmoothFactor);
    }
    // corner bottom
    if(c_do)
    {
        elevation = smin(elevation, sqLength(hg.xy - tileDelta.yz) * innerRadius, innerSmoothFactor);
    }
    // corner bottom left
    if(c_bl)
    {
        elevation = smin(elevation, sqLength(hg.xy - tileDeltb.wz) * innerRadius, innerSmoothFactor);
    }
    // corner top left
    if(c_tl)
    {
        elevation = smin(elevation, sqLength(hg.xy - tileDeltb.wx) * innerRadius, innerSmoothFactor);
    }
    
    if(c_up && c_tr && c_br && c_do && c_bl && c_tl)
    {
        elevation -= pow((1.-sqLength(hg.xy * 1.8)) * 2.8,2.);
    }
    
    idMat = 0;
    if( FLOAT_EQ( id, 2.))
    {
        float max_depth = .3;
        
        
        elevation = smin(elevation - 2.9, .0, 1.8);
        elevation = -smin(-elevation, max_depth, .4);
        idMat = 2;
        mat.y = elevation;
        
        float wave = animatedNoise(p.xz);
        wave = pow(wave, 2.) * .025;
        elevation += wave * step(elevation, -.15);
        p.y -= elevation;
    }
    
    else if( FLOAT_EQ( id, 1.))
    {
        elevation = 2.- (elevation);
        elevation = elevation * 5.;
        elevation += tetraNoise(p.xzz * 5. / gridScale ) * 7.-3.5;
        elevation = -smin(0.,-elevation, 15.);
        
        p.y -=  elevation *.15;
        
        idMat = 1;
        mat.y = elevation;
    }
    
    float dist = sdHexPrism(vec3(hg.yx * 10.5 , p.y*2. + 3.), vec2(5.)) -.25;
    
    if(basePlan < .01)
    {
        idMat = 3;
        mat.xy = hg.xy;
    }
    
    dist = min(dist, basePlan);
    
    return dist; 
}

vec3 normal(vec3 p, float cd)
{
    vec2 e = vec2(0.,.1);
    return normalize(vec3(
        cd - map(p + e.yxx),
        cd - map(p + e.xyx),
        cd - map(p + e.xxy)
    ));
}

void ray(in vec3 ro, in vec3 rd, out vec3 cp, out float st, out float cd, out float dist)
{
    dist = 0.;
    for(; st < 1.; st += 1. /128.)
    {
        cp = ro + rd * dist; 
        cd = map(cp);
        if(cd < .01)
        {
            break;
        }
        
        dist += cd * st;
    }
}

vec3 lookAt(vec3 target, vec3 cp, vec2 uv)
{
    vec3 fd = normalize(target - cp);
    vec3 up = cross(fd, vec3(1.,0.,0.));
    vec3 ri = cross(up, fd);
    return normalize(fd + up * uv.y + ri * uv.x);
}

#define MOUSE (mouse*resolution.xy.x / resolution.x)

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - vec2(resolution * .5))/resolution.y;
    
    vec3 tar = vec3(100.,0.,0.);
    vec3 ro = tar + vec3(0.,12.,-20.);
       vec3 rd = lookAt(tar, ro, uv);
       vec3 cp;
    float st, cd, dist;
    
    ray(ro, rd, cp, st, cd, dist);
    int selectedMat = idMat;
    vec2 material = mat;
    float mo = morph;

    vec3 backCol = vec3(.3,.3,.7);
    vec3 col;
    if(cd < .01)
    {
        vec3 norm = normal(cp, cd);
        vec3 ld = normalize(vec3(-14.,-6.,2.));
        float li = clamp(dot(ld, norm),0.,1.);
        
        vec3 plainColor = vec3(.075,.09,.001);
        vec3 rockColor = vec3(.04,.02,.035);
        vec3 snowColor = vec3(.6);
        vec3 waterColor =vec3(.003,.0046,.094);
        
        vec3 tileColor = plainColor;
        
        if(selectedMat == 1)
        {
            vec3 bottomColor = tileColor;
            
            float elevation = clamp(material.y / 40., 0. ,1.) ;
            //elevation
            
            float rockFactor = smoothstep(-.025,.025, elevation - .015);
            tileColor = mix(tileColor,rockColor, rockFactor);
            
            elevation += norm.y*.25 ;
            float snowFactor = smoothstep(-.1, .1, elevation-.125);
            snowFactor -= .35 - abs(norm.y) * .2;
            
            snowFactor = clamp(snowFactor, 0., 1.) * .5;
            tileColor += vec3(.5,.5,.45) * snowFactor;
        }
        else if(selectedMat == 2)
        {
            float depth = clamp(-material.y* 50., .0, 1.);
            tileColor = mix(tileColor, waterColor, depth);
        }
        
        col = mix(backCol, tileColor, mo);
        
        col +=  vec3(.810,.800,.620) * li * .125;
        
        
        
        
    }
    else
    {
        col = backCol;
    }
    
    if(selectedMat == 3)
    {
        float grid = hexDist(material.xy * 2.);
        grid = 1. - smoothstep(-.05,.02,grid - .94);
        col = mix(backCol * 1.5, backCol*1.2, grid);
    }
    
    // fog
    col = mix(backCol, col, exp(min(-dist * .05 +2.5,0.)));
    
    // color grading
    col = col*vec3(1.15,1.29,.9) * 1.3;

    // compress        
    // col = 1.35*col/(1.0+col);
        
    
    // gama correction
    col = pow(col, vec3(.4545));
    
    glFragColor = vec4(col,1.);
}
