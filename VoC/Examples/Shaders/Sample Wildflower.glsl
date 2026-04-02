#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tlVGz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
       _
\^/ILD|-LOWER

by Hazel Quantock 2020
This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License. https://creativecommons.org/licenses/by-sa/4.0/
*/

// create a simple repetetive patch of grass,
// then blend it with copies of itself randomly offset and rotated

// random hash from here: https://www.shadertoy.com/view/4dVBzz
#define M1 1597334677U     //1719413*929
#define M2 3812015801U     //140473*2467*11
#define M3 3299493293U     //467549*7057

#define F0 (1.0/float(0xffffffffU))

#define hash(n) n*(n^(n>>15))

#define coord1(p) (uint(p)*M1)
#define coord2(p) (uvec2(p).x*M1^uvec2(p).y*M2)
#define coord3(p) (uvec3(p).x*M1^uvec3(p).y*M2^uvec3(p).z*M3)

float hash1(uint n){return float(hash(n))*F0;}
vec2 hash2(uint n){return vec2(hash(n)*uvec2(0x1U,0x3fffU))*F0;}
vec3 hash3(uint n){return vec3(hash(n)*uvec3(0x1U,0x1ffU,0x3ffffU))*F0;}
vec4 hash4(uint n){return vec4(hash(n)*uvec4(0x1U,0x7fU,0x3fffU,0x1fffffU))*F0;}

float BladeOfGrass( vec3 base, vec3 tip, vec2 tile, vec3 pos, bool stalk )
{
    // cone, curved from vertical to tip
    // subtract a second cone, offset away from tip
    // maybe curve more on shorter ones

    float v = (pos.y-base.y) / (tip.y - base.y);
    
    // curve the blade
    v = pow(v,1.5);

    // apply the curved slope
    pos.xz -= mix(base.xz,tip.xz,v);

    // wrap space here, so it can follow the curve without needing duplicate blades
    // even if blade curves enough to lean into next repeat!
//    pos.xz = (abs(fract(pos.xz/(tile*2.)-.25)-.5)-.25)*tile*2.;    // this flips the crease inside out but makes the sdf continuous
    pos.xz = (fract(pos.xz/tile+.5)-.5)*tile;
    
    float r = .03*tip.y;
    vec2 cutBase = -normalize(tip.xz)*r*.3;
    
    if ( stalk )
        r = .0005;
    else
        r *= (1.-v);
    
    float f = length(pos.xz) - r;

    if ( !stalk )
    {
        f = max(f, -(length(pos.xz - cutBase*(1.-v)) - r*1.2) );
    }
        
    return max(pos.y-tip.y-.0, // improve distance values above tip (with a fudge because this is too low!?)
              f*.8); // HACK gradient too high because of tilt - todo: do this analytically (curve of v is a problem)
                    // this breaks looking top-down if pow(,2) or more
                    // better options: tilt plane of the circle, maybe sweep it along a circular curve
}

float Flower( vec3 base, vec3 tip, vec2 tile, vec3 pos, bool grass )
{
    vec3 tpos = pos-tip-vec3(0,-.0004,0);
    tpos.xz = (fract(tpos.xz/tile+.5)-.5)*tile;
    
//    float f = length(tpos)-.003;
    
    // tilt, so the flower sits at a nice angle
    tpos.yz = tpos.yz*sqrt(2./4.) + tpos.zy*sqrt(2./4.)*vec2(-1,1);
    
    // petals: mirror tpos in a circle around z
    tpos.xy = abs(tpos.xy);
    if ( tpos.x > tpos.y ) tpos.xy = tpos.yx;

// too thin at the edges
// better to intersect a thin sphere with a sphere to cut the shape
/*    float f = max(
            length(tpos-vec3(.001,.002,.002)*1.1) - .002,
            -(length(tpos-vec3(.001,.002,.003)) - .0028)
        );*/
    float f = max(
            length(tpos-vec3(.001,.002,.0005)*1.1) - .002, // cut shape
            abs( length(tpos-vec3(.001,.002,.003)) - .003)-.0001
        );
    f = min( f,
            max(
                length(tpos-vec3(0,0,.000)) -.001,
                length(tpos-vec3(0,0,.001)) -.001
            )
            )*.9;

    if ( grass ) f = min(min( f,
                             BladeOfGrass( base, tip, tile, pos, true )),
                             BladeOfGrass( base, tip+vec3(.003,-.008,-.001), tile, pos, false )
                            );
    
    return f;
}

float Tile( vec3 pos, float invWeight, vec4 rand, bool grass )
{
//    if ( rand.w > .2 ) invWeight = 1.; // isolate some of the blades
    
//    invWeight = invWeight*invWeight; // should be 0 until about .5
//    invWeight = smoothstep(.5,1.,invWeight); // should be 0 until about .5

    // vary the height a little to make it look less even
    pos.y += sqrt(rand.w)*.07;
    
    pos.xz += rand.xy;
    float a = rand.z*6.283;
    pos.xz = pos.xz*cos(a) + sin(a)*vec2(-1,1)*pos.zx;
    
    float f = 1e20;
    
    if ( grass )
    {
        f = min(f,min(min(min(min(
            BladeOfGrass(vec3(.01,0,0),vec3(.03,.15,.04),vec2(.06),pos,false),
            BladeOfGrass(vec3(0),vec3(-.05,.17,.02),vec2(.06),pos,false)),
            BladeOfGrass(vec3(0),vec3(-.01,.10,.02),vec2(.04),pos,false)),
            BladeOfGrass(vec3(0,0,-.01),vec3(-.01,.12,-.03),vec2(.03),pos,false)),
            BladeOfGrass(vec3(.005,0,0),vec3(.03,.16,-.05),vec2(.04),pos,false)
        )) + (1.-invWeight)*.0;
    }
    
    // flowers
    f = min(f, Flower(vec3(.1,0,0),vec3(.1,.2,.05),vec2(.13),pos,grass) + (1.-invWeight)*.0 );
    
    return mix( max(.03,pos.y-.2), f, invWeight );
//    return f;
}

float SDF( vec3 pos, bool grass )
{
    // bilinearly filter 4 instances of the Tile pattern with random offsets and rotations
    
    vec2 gridSize = vec2(.1);//.04);
    vec2 uv = pos.xz/gridSize;
    uvec2 idx00 = uvec2(ivec2(floor(uv))+0x10000);
    uv -= floor(uv);
    
    uvec2 d = uvec2(0,1);
    vec4 rand00 = hash4(coord2(idx00+d.xx));
    vec4 rand01 = hash4(coord2(idx00+d.yx));
    vec4 rand10 = hash4(coord2(idx00+d.xy));
    vec4 rand11 = hash4(coord2(idx00+d.yy));

//    uv = smoothstep(.0,1.,uv); // this causes a steeper gradient in the middle, so get fewer errors without it

    vec2 uvlo = smoothstep(1.,.5,uv);
    vec2 uvhi = smoothstep(0.,.5,uv);

    return min( pos.y,
                min(
                    min(
                        Tile( pos, uvlo.x*uvlo.y, rand00, grass ),
                        Tile( pos, uvhi.x*uvlo.y, rand01, grass )
                    ),
                    min(
                        Tile( pos, uvlo.x*uvhi.y, rand10, grass ),
                        Tile( pos, uvhi.x*uvhi.y, rand11, grass )
                    )
                )
            ) * 1.;
/*    return mix(
                    mix(
                        Tile( pos, uv.x*uv.y, rand00, grass ),
                        Tile( pos, (1.-uv.x)*uv.y, rand01, grass ),
                        uv.x
                    ),
                    mix(
                        Tile( pos, uv.x*(1.-uv.y), rand10, grass ),
                        Tile( pos, (1.-uv.x)*(1.-uv.y), rand11, grass ),
                        uv.x
                    ),
                    uv.y
                );*/
}

// adjust trace quality/performance
const float epsilon = .00005;
const int loopCount = 200;

float Trace( vec3 rayStart, vec3 rayDirection, float far )
{
    float t = epsilon;
    for ( int i=0; i < loopCount; i++ )
    {
        float h = SDF( rayDirection*t+rayStart, true );
        t += h;
        if ( t > far || h < epsilon ) // *t )
            return t;
    }
    
    return t;
}

vec3 Normal( vec3 pos )
{
    vec2 d = vec2(-1,1) * .000004;
    return
        normalize(
            SDF( pos + d.xxx, true )*d.xxx +
            SDF( pos + d.xyy, true )*d.xyy +
            SDF( pos + d.yxy, true )*d.yxy +
            SDF( pos + d.yyx, true )*d.yyx
        );
}

void main(void) //WARNING - variables void ( out vec4 fragColour, in vec2 gl_FragCoord.xy ) need changing to glFragColor and gl_FragCoord
{
    vec4 fragColour=glFragColor;
    vec2 camAngle = vec2(.5-.03*(time/8.-sin(time/8.))*8.,.15-cos(time/8.)*.08);
    //if ( mouse*resolution.xy.z > 0. ) camAngle = pow(mouse*resolution.xy.xy/resolution.xy,vec2(1.,.5))*vec2(6,-1.57) + vec2(0,1.57);
    vec3 camPos = 1.*vec3(cos(camAngle.y)*sin(camAngle.x),sin(camAngle.y),cos(camAngle.y)*cos(camAngle.x));
    vec3 camLook = vec3(0,.10,0)+camPos*vec3(1,0,1)*.3;
    float camZoom = 2.;
    
    vec3 camK = normalize(camLook-camPos);
    vec3 camI = normalize(cross(vec3(0,1,0),camK));
    vec3 camJ = cross(camK,camI);

    vec3 ray = vec3((gl_FragCoord.xy-resolution.xy*.5)/resolution.y,camZoom);
    ray = normalize(ray);
    ray = ray.x*camI + ray.y*camJ + ray.z*camK;
    
    float t = Trace( camPos, ray, 1e20 );
    
    float far = 20.;
    if ( t < far )
    {
        vec3 pos = camPos+ray*t;

        float sdf = SDF(pos,true);
        float sdfnograss = SDF(pos,false);

        vec3 flowerColour = sin(pos/.03)*.1+.9;
        vec3 grassColour = mix( vec3(.2,.6,.01), vec3(.5,.7,.2), .5+.5*sin(pos.yxz/.025+2.5) );

        vec3 albedo = mix( grassColour, mix( vec3(.03,.0,.0), flowerColour, smoothstep(.0,.05,pos.y)), step(sdfnograss,sdf) );

        vec3 n = Normal( camPos+ray*t );
        vec3 ambient = mix( vec3(.06,.1,.02), vec3(.15,.2,.25), n.y*.5+.5 );
        float nl = dot(n,normalize(vec3(1,3,2)));

        fragColour.rgb = ambient;
        fragColour.rgb += vec3(.9)*max(0.,nl); // direct light
        fragColour.rgb += vec3(.3)*pow(albedo*.99,vec3(4))*smoothstep(-1.,.1,nl); // subsurface light
        fragColour.rgb *= smoothstep(.0,.18,pos.y); // fake combined shadows & AO
        fragColour.rgb *= albedo;
    }
    else
    {
        fragColour.rgb = vec3(1);
        t = far; // so it gets fog applied
    }
    
    fragColour.rgb = mix( vec3(.7,.8,1), fragColour.rgb, exp2(-t/5.)*1.08 );
 
    fragColour.rgb = pow(fragColour.rgb,vec3(1./2.2));
    fragColour.a = 1.;

    glFragColor = fragColour;
}
