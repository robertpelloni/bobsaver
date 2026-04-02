#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3scXR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// should be a square for best results
#define NUM 25

void main(void) {
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y * .25;
    // warm up the clock a bit
    float dt = time + 10.;

    // init points
    vec2 points[NUM];
    int stride = 5;
    for(int i = 0; i < NUM; i++) {
        float row = float(i / stride);
        float col = float(i % stride);
        points[i] = (-2. + vec2(col, row)) / float(stride);

        // todo this could probably use some more interesting movement
        points[i] += vec2(
             sin(dt*.123*float(i)) * .1,
             sin(19. + dt*.256*float(i)) * .1
            );
    }
    
    // debug origin draw
    #if 0
    if (uv.x > -.01 && uv.x < .01) { glFragColor = vec4(1.,0.,0.,1.); return;}
    if (uv.y > -.01 && uv.y < .01) { glFragColor = vec4(1.,0.,0.,1.); return;}
    #endif

    // this loop calculates the closest and second closest distances
    // it will be used for the classic f2-f1 voronoi border
    vec2 dist = vec2(.5);
    for(int i = 0; i < NUM; i++) {
        float d = distance(uv, points[i]);
        if (d < dist.x) {
            // store the new closest value and record
            // what the previous one was in dist.y
            dist.y = dist.x;
            dist.x = d;
        } else if (d < dist.y) {
            // sometimes the closest value doesn't 
            // change but the second closest does
            dist.y = d;
        }
    }

    // colors are based on leopard print patterns
    vec3 base = vec3(1.,.8,.5);
    vec3 outerspot = vec3(0.1, .05, .02);
    vec3 innerspot = vec3(.81, .37, .01);

    // easy f2-f1 voronoi. consider incorporating iq's perfect border
    // if you want something more predictable
    vec3 voro = vec3(dist.y - dist.x);
    vec3 col = mix(base, outerspot, step(.02, voro));
    col = mix(col, innerspot, step(.06, voro));

    glFragColor = vec4(col, 1);
}
