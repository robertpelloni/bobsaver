#version 420

// original https://www.shadertoy.com/view/MXBfWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Helixify was fun, right? https://www.shadertoy.com/view/MXjBWR
// Let's go deeper now! Helixify of helixify of helixify... the approximation
// starts to feel at some point, but still looking fun.
//
// Copyright (c) Élie Michel -- MIT licensed (for what is not borrowed from other shaders)
//
// CREDITS:
// Shading is borrowed from iq https://www.shadertoy.com/view/Xds3zN

#define EPSILON 1e-3
#define MAX_ITER 100
#define TWO_PI 6.28318530718

//------------------------------------------------------------
// Core of the helix shape.
// Copyright (c) Élie Michel -- MIT licensed
// See https://www.shadertoy.com/view/MXjBWR for detailed comments
// This is a macro because it is a second-order function
#define MAKE_HELIXIFY(name, largeShape2D, smallShape3D) \
float name(vec3 pos, float stepSize) { \
    float dist_xz = largeShape2D(pos.xz); \
    float frac_cu = atan(pos.z, pos.x) / TWO_PI; \
     \
    int base_n = int(floor(pos.y / stepSize - frac_cu)); \
     \
    float dist_y = 2.0 * stepSize; \
    float cu = 0.0; \
    for (int n = base_n - 1 ; n <= base_n + 1 ; ++n) { \
        float candidate_cu = float(n) + frac_cu; \
        float helix_y = candidate_cu * stepSize; \
        float candidate_dist_y = pos.y - helix_y; \
        if (abs(candidate_dist_y) < abs(dist_y)) { \
            dist_y = candidate_dist_y; \
            cu = candidate_cu; \
        } \
    } \
     \
    vec3 local_pos = vec3(dist_xz, dist_y, cu); \
    return smallShape3D(local_pos); \
}

//------------------------------------------------------------
// Core scene definition

// Shape of 1 turn of the helix
float smallShape3D_1(vec3 pos) {
    return length(pos.xy) - 0.005;
}

// Cross-section of the helix
float largeShape2D_1(vec2 pos) {
    return length(pos) - 0.02;
}

MAKE_HELIXIFY(helixify_1, largeShape2D_1, smallShape3D_1)

// Cross-section of the helix
float largeShape2D_2(vec2 pos) {
    return length(pos) - 0.1;
}

// Shape of 1 turn of the helix
float smallShape3D_2(vec3 pos) {
    float bump = 0.01 * (sin(4. * time - 5. * pos.z) * .5 + .5) - 0.002;
    return (helixify_1(pos.xzy * vec3(1.0, 0.5, 1.0), 0.05) - bump);
}

float smallShape3D_2c(vec3 pos) {
    return length(pos.xy) - 0.01;
}

MAKE_HELIXIFY(helixify_2, largeShape2D_2, smallShape3D_2)

MAKE_HELIXIFY(helixify_2c, largeShape2D_2, smallShape3D_2c)

// Cross-section of the helix
float largeShape2D_3(vec2 pos) {
    return length(pos) - 0.4;
}

// Shape of 1 turn of the helix
float smallShape3D_3(vec3 pos) {
    pos.z += 0.025 * time;
    return helixify_2(pos.xzy * vec3(1.0, 3.0, 1.0), 0.2);
}

// Shape of 1 turn of the helix
float smallShape3D_3c(vec3 pos) {
    pos.z += 0.025 * time;
    return helixify_2c(pos.xzy * vec3(1.0, 3.0, 1.0), 0.2);
}

float smallShape3D_3b(vec3 pos) {
    return length(pos.xy) - 0.04;
}

MAKE_HELIXIFY(helixify_3, largeShape2D_3, smallShape3D_3)

MAKE_HELIXIFY(helixify_3b, largeShape2D_3, smallShape3D_3b)

MAKE_HELIXIFY(helixify_3c, largeShape2D_3, smallShape3D_3c)

vec2 sdmUnion(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}

vec2 sceneDist(vec3 pos) {
    float sd = helixify_3(pos, 1.2);
    return sdmUnion(
        sdmUnion(
            vec2(helixify_3(pos, 1.2), 0.0),
            vec2(helixify_3b(pos, 1.2), 1.0)
        ),
        vec2(helixify_3c(pos, 1.2), 2.0)
    );
}

//------------------------------------------------------------
// Shading, borrowed from iq

vec3 calcNormal( in vec3 pos )
{
    if (pos.y < EPSILON) return vec3(0.0, 1.0, 0.0);
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*sceneDist(pos+0.0005*e).x;
      //if( n.x+n.y+n.z>100.0 ) break;
    }
    return normalize(n);
}

// https://iquilezles.org/articles/rmshadows
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    // bounding volume
    float tp = (0.8-ro.y)/rd.y; if( tp>0.0 ) tmax = min( tmax, tp );

    float res = 1.0;
    float t = mint;
    for( int i=0; i<24; i++ )
    {
        float h = sceneDist( ro + rd*t ).x;
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s );
        t += clamp( h, 0.01, 0.2 );
        if( res<0.004 || t>tmax ) break;
    }
    res = clamp( res, 0.0, 1.0 );
    return res*res*(3.0-2.0*res);
}

// https://iquilezles.org/articles/nvscene2008/rwwtt.pdf
float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = sceneDist( pos + h*nor ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
        if( occ>0.35 ) break;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

vec3 computeShading(vec3 pos, vec3 nor, vec3 rd, float t, float m) {
    vec3 ref = reflect( rd, nor );
    vec3 col = (
        m == 0.0
        ? vec3(1.0, 0.5, 0.0) * 0.5
        : m == 1.0
        ? vec3(1.0, 1.0, 0.0) * 0.5
        : vec3(0.4, 0.1, 0.3) * 0.5
    );
    float ks = 0.4;
    float occ = calcAO( pos, nor );

    vec3 lin = vec3(0.0);
    // sun
    {
        vec3  lig = normalize( vec3(0.5, -0.1, -0.6) );
        vec3  hal = normalize( lig-rd );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
              dif *= calcSoftshadow( pos, lig, 0.02, 2.5 );
        float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0);
              spe *= dif;
              spe *= 0.04+0.96*pow(clamp(1.0-dot(hal,lig),0.0,1.0),5.0);
        lin += col*2.20*dif*vec3(1.30,1.00,0.70);
        lin +=     5.00*spe*vec3(1.30,1.00,0.70)*ks;
    }
    // sky
    {
        float dif = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
              dif *= occ;
        float spe = smoothstep( -0.2, 0.2, ref.y );
              spe *= dif;
              spe *= 0.04+0.96*pow(clamp(1.0+dot(nor,rd),0.0,1.0), 5.0 );
              spe *= calcSoftshadow( pos, ref, 0.02, 2.5 );
        lin += col*0.60*dif*vec3(0.40,0.60,1.15);
        lin +=     2.00*spe*vec3(0.40,0.60,1.30)*ks;
    }
    
    return mix( lin, vec3(1.0, 0.8, 0.0), 1.0-exp( -0.001*t*t*t ) );
}

//------------------------------------------------------------
// Main function

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.x;
    
    vec3 direction = normalize(vec3(uv.xy, 1.0));
    direction.yz = direction.zy;
    vec3 pos = vec3(0.0, time, 0.0);
    
    float fac = -1.0;
    float t = 0.0;
    float m = 0.0;
    for (int i = 0 ; i < MAX_ITER ; ++i) {
        vec2 sd_m = sceneDist(pos);
        float sd = sd_m.x;
        m = sd_m.y;
        if (sd < EPSILON) {
            fac = float(i) / float(MAX_ITER);
            break;
        }
        pos += .95 * direction * sd;
        t += .95 * sd;
    }
    
    if (fac >= 0.0) {
        vec3 normal = calcNormal(pos);
        vec3 col = vec3(fac);
        col = normal * 0.5 + 0.5;
        col = computeShading(pos, normal, direction, t, m);
        col = pow(col, vec3(0.4545));
        glFragColor = vec4(col,1.0);
    } else {
        glFragColor = mix(
            vec4(0.0, 0.0, 0.0, 1.0),
            pow(vec4(1.0, 0.8, 0.0, 1.0), vec4(0.4545)),
            step(length(uv), 0.05)
        );
    }
}
