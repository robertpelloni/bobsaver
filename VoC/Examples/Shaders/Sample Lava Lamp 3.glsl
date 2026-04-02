#version 420

// original https://www.shadertoy.com/view/7lVSDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float EPS = 0.001;
const float L = 10.0;
const int FSAA = 1;

// Some colors
const vec3 Y1 = vec3(1, 0.9, 0.15);
const vec3 Y2 = vec3(1., 0.6, 0.1);
const vec3 Y3 = vec3(.9, .6, .1);
const vec3 R0 = vec3(.9, .3, .1);
const vec3 R1 = vec3(.2, .08, 0.);
const vec3 O1 = vec3(.7, .3, 0.);
const vec3 O2 = vec3(.2, .07, 0.);
const vec3 O3 = vec3(.13, .04, 0.);

float sq(float x) {
    return x * x;
}

// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
vec2 grad( ivec2 z )  // replace this anything that returns a random vector
{
    // 2D to 1D
    int n = z.x+z.y*11111;
    // Hugo Elias hash
    n = (n<<13)^n;
    n = (n*(n*n*15731+789221)+1376312589)>>16;
    // simple random vectors
    return vec2(cos(float(n)),sin(float(n)));
}
float noise( in vec2 p )
{
    ivec2 i = ivec2(floor( p ));
    vec2 f = fract( p );
    vec2 u = f*f*(3.0-2.0*f);
    return mix( mix( dot( grad( i+ivec2(0,0) ), f-vec2(0.0,0.0) ), 
                     dot( grad( i+ivec2(1,0) ), f-vec2(1.0,0.0) ), u.x),
                mix( dot( grad( i+ivec2(0,1) ), f-vec2(0.0,1.0) ), 
                     dot( grad( i+ivec2(1,1) ), f-vec2(1.0,1.0) ), u.x), u.y);
}
float gradient_noise(in vec2 uv) {
    float f = 0.;
    uv *= 8.0;
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    f  = 0.5000*noise( uv ); uv = m*uv;
    f += 0.2500*noise( uv ); uv = m*uv;
    f += 0.1250*noise( uv ); uv = m*uv;
    f += 0.0625*noise( uv ); uv = m*uv;
    return 0.5 + 0.5*f;
}

float simple_gradient_noise(in vec2 uv) {
    float f = 0.;
    uv *= 8.0;
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    f  = 0.5000*noise( uv ); uv = m*uv;
    f += 0.2500*noise( uv ); uv = m*uv;
    //f += 0.1250*noise( uv ); uv = m*uv;
    //f += 0.0625*noise( uv ); uv = m*uv;
    return f;
}

// From https://www.iquilezles.org/www/articles/smin/smin.htm
float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

float random(int i, float lo, float hi) {
    return (hi - lo) * 0.5 * (sin(float(997*i)) + 1.) + lo;
}

float add_ball(int id, vec3 pos, float radius, float period) {
    int i_period = int(time / period);
    float t = mod(time, period) / period;
    
    float o = random(id + 13 * i_period, 0., .2);
    float y = mix(-1., 1., smoothstep(o+0., o+.2, t));
    y = mix(y, -1., smoothstep(o+.5, o+.8, t));
    
    float xlo0 = random(id + 17 * i_period, -0.4, 0.4);
    float xlo1 = random(id + 17 * (i_period + 1), -0.4, 0.4);
    float xhi = random(id + 29 * i_period, -0.25, 0.25);
    float x = mix(xlo0, xhi, smoothstep(o+0., o+.2, t));
    x = mix(x, xlo1, smoothstep(o+.5, o+.8, t));
    
    float zlo0 = random(id + 23 * i_period, -0.2, 0.2);
    float zlo1 = random(id + 23 * (i_period + 1), -0.2, 0.2);
    float zhi = random(id + 31 * i_period, -0.2, 0.2);
    float z = mix(zlo0, zhi, smoothstep(o+0., o+.2, t));
    z = mix(z, zlo1, smoothstep(o+.5, o+.8, t));
    
    vec3 center = vec3(x, y, 2.+z);
    
    return length(pos - center) - radius;
}

// Signed distance function that defines the scene.
float sdf(in vec3 pos) {
    float sph0_sdf = add_ball(0, pos, 0.2, 40.);
    float sph1_sdf = add_ball(1, pos, 0.3, 50.);
    float sph2_sdf = add_ball(2, pos, 0.35, 60.);

    return smin(smin(sph0_sdf, sph1_sdf, .15), sph2_sdf, .15);
}

// Ray marching engine.
void rayMarcher(in vec2 uv, out bool hit, out float min_dist, out vec3 nml) {
    uv = uv + vec2(0, .3*simple_gradient_noise(.2*uv));

    float t = 0.0;
    float dist;
    vec3 pos;
    min_dist = L;
    do {
        // Orthographic camera
        pos = vec3(uv, t);
        dist = sdf(pos);
        t += dist;
        min_dist = min(dist, min_dist);
    } while(t < L && dist > EPS);
    
    nml = normalize(vec3(
        dist - sdf(pos - vec3(EPS, 0, 0)),
        dist - sdf(pos - vec3(0, EPS, 0)),
        dist - sdf(pos - vec3(0, 0, EPS))
    ));
    
    hit = dist <= EPS;
}

float lamp_sdf(vec2 uv) {
    float dl = sqrt(0.04*sq(uv.y+0.7)+0.005)-0.75 - uv.x;
    float dr = sqrt(0.04*sq(uv.y+0.7)+0.005)-0.75 + uv.x;
    return max(dl, dr);
}

float inner_sdf(vec2 uv) {
    float dl = 0.08*sq(uv.x) - 0.96 - uv.y;
    float dh = uv.y + 0.17*sq(uv.x) - 0.97;
    return max(dl, dh);
}

vec4 sampleColor(in vec2 sampleCoord )
{
    float aspectRatio = resolution.x / resolution.y;

    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = 2.0 * sampleCoord / resolution.xy - 1.0;
    // Normalized but keeping aspect ratio
    vec2 uva = vec2(uv.x * aspectRatio, uv.y);
    
    // TODO: change shape + gradient behind
    float d_lamp = lamp_sdf(uva);
    float d_inner = inner_sdf(uva);
    
    vec3 nml;
    bool hit;
    float min_dist;
    rayMarcher(uva, hit, min_dist, nml);
    
    float bg_halo_micro = smoothstep(0., .05, min_dist);
    float bg_halo_macro = smoothstep(0., .6, min_dist);
    float halo_sides = smoothstep(0., 1., min_dist);
    float bg_noise = gradient_noise(.2 * uv);
    float bg_mix = clamp(0.4 * bg_halo_macro + 0.6 * bg_noise, 0., 1.);
    vec3 bg = mix(O1, O2, bg_mix);
    bg = mix(R0, bg, bg_halo_micro);
    bg = mix(mix(Y3, bg, .6 + .4 * smoothstep(0., -0.06+0.01*sin(20.*uva.x+10.*uva.y), d_lamp)),
             bg, 0.8 * halo_sides);
    
    vec3 lightDir = vec3(0, -1, 0);
    vec3 fg = mix(Y1, Y2, smoothstep(0.1, -0.9, dot(lightDir, nml)));
    
    vec3 col = mix(fg, bg, smoothstep(EPS, .005, min_dist));

    vec3 back_gradient = mix(R1, vec3(0), smoothstep(.6, 2.5, length(uva)));
    col = mix(col, vec3(0), smoothstep(0., .02, d_inner));
    col = mix(col, back_gradient, smoothstep(0., .015, d_lamp));

    // Output to screen
    return vec4(col, 1.0);
}

void main(void) {
    vec4 colSum = vec4(0);
    for(int i = 0; i < FSAA; i++) {
        for(int j = 0; j < FSAA; j++) {
            colSum += sampleColor(gl_FragCoord.xy + vec2(float(i) / float(FSAA), float(j) / float(FSAA)));
        }
    }
    glFragColor = colSum / colSum.w;
}
