#version 420

// original https://www.shadertoy.com/view/tddyWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*

    Irreptile Triangle
    ------------------

    Recursively tiling this hexadrafter irreptile from George Sicherman
    https://userpages.monmouth.com/~colonel/drirrep/index.html

*/

// Polygon distance, iq https://www.shadertoy.com/view/wdBXRW

float dot2( in vec2 v ) { return dot(v,v); }
float cross2d( in vec2 v0, in vec2 v1) { return v0.x*v1.y - v0.y*v1.x; }

const int N = 6;

float sdPoly( in vec2[N] v, in vec2 p )
{
    int num = v.length();
    float d = dot(p-v[0],p-v[0]);
    float s = 1.0;
    for( int i=0, j=num-1; i<num; j=i, i++ )
    {
        // distance
        vec2 e = v[j] - v[i];
        vec2 w =    p - v[i];
        vec2 b = w - e*clamp( dot(w,e)/dot(e,e), 0.0, 1.0 );
        d = min( d, dot(b,b) );

        // winding number from http://geomalgorithms.com/a03-_inclusion.html
        bvec3 cond = bvec3( p.y>=v[i].y, p.y<v[j].y, e.x*w.y>e.y*w.x );
        if( all(cond) || all(not(cond)) ) s*=-1.0;  
    }
    
    return s*sqrt(d);
}

// Spectrum palette, iq https://www.shadertoy.com/view/ll2GD3

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 spectrum(float n) {
    return 1. - pal( n, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
}

#define PI 3.14159265359

// MATRIX

mat3 trs(vec2 t) {
    return mat3(1, 0, t.x, 0, 1, t.y, 0, 0, 1);
}

mat3 rot(float a) {
    return mat3(cos(a), -sin(a), 0, sin(a), cos(a), 0, 0, 0, 1);
}

mat3 scl(vec2 s) {
    return mat3(s.x, 0, 0, 0, s.y, 0, 0, 0, 1);
}

float decomposeScale(mat3 m) {
    vec3 a = vec3(0) * m;
    vec3 b = vec3(1,0,0) * m;
    return distance(a, b);
}

// MAIN

const int count = 11;
mat3 tiles[count];

float h = sqrt(3.) / 2.;

float sdTile(vec2 p) {
    vec2[] poly = vec2[](
        vec2(0, 0),
        vec2(2.5, 0),
        vec2(2.5 - .25, -h / 2.),
        vec2(1.5 - .25, -h / 2.),
        vec2(1., -h),
        vec2(.5, -h)
    );
    return sdPoly(poly, p);
}

//#define LOOP

vec3 shadeTile(float d, float s, int i, int iteration) {
    d = -d;
    d *= resolution.y * 2. / s;
    d += .001 * resolution.y;
    //d += (.002 / s + .0008)  * resolution.y;
    d = clamp(d, 0., 1.) / 4.;
    float t = float(i);
    #ifdef LOOP
        float time = mod(time / 3., 1.);
        if (iteration > 0) {
            t /= float(count);
        } else {
            t /= 3.;
        }
        //t *= 1.666;
        t += time;
    #else
        if (iteration > 0) {
            t /= float(count);
            t = t * mix(1., 10., cos(time / 10.) * .5 + .5);
        } else {
            t /= 3.;
        }
        t += time / 3.;
    #endif
    vec3 col = d * spectrum(t);
    return col;
}

bool drawTiles(inout vec2 p, inout vec3 col, inout float scale, int iteration) {
    
    float scaleOut;
    vec2 pOut;
    bool hit = false;
    
    vec2 p2 = p;
    float scale2 = scale;

    for(int i = 0; i < count; i++ )
    {
        mat3 txm = tiles[i];
        p = (vec3(p2, 1) * txm).xy;
        scale = scale2 * decomposeScale(txm);

        float d = sdTile(p);
        col -= shadeTile(d, scale, i, iteration);

        if (d < 0.) {
            pOut = p;
            scaleOut = scale;
            hit = true;
        }
        
        if (iteration == 0 && i == 2) {
            break;
        }
    }
    
    p = pOut;
    scale = scaleOut;

    return hit;
}

vec3 render(vec2 p) {

    float scale = 1.;
    vec3 col = vec3(1);

    // recurse
    for(int i = 0; i < 4; i++) {
        if ( ! drawTiles(p, col, scale, i)) {
            if (i == 0) {
                col = vec3(.0);
            }
            break;
        }
    }
    
    return col;
}

void main(void)
{
    vec2 p = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    p *= .55;
    p *= vec2(1,-1);
    p -= vec2(-.5,h/2.);
    
    
    // prepare matrices
    
    // tri
    mat3 triOrigin = trs(vec2(-.5, sqrt(3.) / 6.)) * scl(vec2(3));
    tiles[0] = triOrigin * trs(vec2(1., -h));
    tiles[1] = triOrigin * rot(PI / 1.5) * trs(vec2(1., -h));
    tiles[2] = triOrigin * rot(PI / -1.5) * trs(vec2(1., -h));
    
    // long
    mat3 rect = trs(vec2(-3.5, h)) * scl(vec2(-1));
    mat3 longOrigin = scl(vec2(3. / 1.5)) * trs(vec2(-5, 0)) * scl(vec2(-1, 1));
    tiles[3] = longOrigin;
    tiles[4] = tiles[3] * rect;
    
    // box
    mat3 boxOrigin = trs(vec2(-.5, h)) * scl(vec2(1.5 / .25));
    tiles[5] = boxOrigin * rot(PI / -3.);
    tiles[6] = tiles[5] * rect;
    tiles[7] = boxOrigin * trs(vec2(-1, 0)) * rot(PI / -3.);
    tiles[8] = tiles[7] * rect;
    tiles[9] = boxOrigin * trs(vec2(-2, 0)) * rot(PI / -3.);
    tiles[10] = tiles[9] * rect;

    // draw
    vec3 col = render(p);
    col = pow(col, vec3(1./2.2));
    glFragColor = vec4(col, 1);
}
