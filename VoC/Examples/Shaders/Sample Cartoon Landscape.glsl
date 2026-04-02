#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wljSDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926
#define ALPHA(d) 1. - clamp(d*200., 0., 1.)

float hash(float p) { vec3 p3 = fract(vec3(p) * 0.1031); p3 += dot(p3, p3.yzx + 19.19); return fract((p3.x + p3.y) * p3.z); }

vec2 rotate(vec2 v, float a) { return cos(a)*v + sin(a)*vec2(v.y,-v.x); }

float fade(float t) { return t*t*t*(t*(6.*t-15.)+10.); }

float grad(float hash, float p) { return (int(1e4*hash) & 1) == 0 ? p : -p; }

float perlinNoise1D(float p) {
    float pi = floor(p), pf = p - pi, w = fade(pf);
    return mix(grad(hash(pi), pf), grad(hash(pi + 1.0), pf - 1.0), w) * 2.0;
}

float fbm(float pos, int octaves, float persistence)  {
    float total = 0., frequency = 1., amplitude = 1., maxValue = 0.;
    for(int i = 0; i < octaves; ++i) {
        total += perlinNoise1D(pos * frequency) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.;
    }
    return total / maxValue;
}

//2d distance functions from http://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdTriangle(vec2 p, vec2 p0, vec2 p1, vec2 p2 ) {
    vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
    vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;
    vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
    vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
    vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
    float s = sign( e0.x*e2.y - e0.y*e2.x );
    vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
                     vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
                     vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));
    return -sqrt(d.x)*sign(d.y);
}

float sdCircle(vec2 p, float r) { return length(p) - r; }

float sdBox(vec2 p, vec2 b) { vec2 d = abs(p)-b; return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0); }

vec4 mixLayer(vec4 layer1, vec4 layer2) { return mix(layer1, layer2, layer2.a); }

vec4 sky(vec2 uv) { 
    vec3 col = vec3(.3,.5,.8)-uv.y*.3;
    col = mix(col, vec3(1.-uv.y,.6,.0), pow(1. - clamp(uv.y-.2,0.,1.), 2.));
    return vec4(col, 1.); 
}

vec4 sun(vec2 uv) {
    vec2 d = uv - vec2(1.1, .8);
    float t = pow(1./(1.+length(d)), 4.);
    vec3 col =  3. * vec3(.8, .7, .5) * t; //sun disk
    float a = atan(d.y/d.x)+time;
    col = mix(vec3(1.,1.,.5)*t*step(mod(a, PI/8.),PI/16.), col, t); //sun rays
    return vec4(col, t);
}

vec4 hill(vec2 pos, vec2 size, vec3 col, bool snow) {
    float d = (pos.y - size.y*cos(pos.x*1./size.x));
    if (abs(pos.x) > .5*PI*size.x || pos.y < 0.) return vec4(0.);
    if (snow && pos.y > .7*size.y + .1*fbm(pos.x*8., 1, .5)) col = vec3(.95);
    return vec4(col, ALPHA(d));
}

vec4 windmill(vec2 pos, float scale) {
    pos/=scale;
    float d = sdBox(pos, vec2(.003, .15));
    pos -= vec2(0.,.15);
    d = min(d, sdCircle(pos, .01));
#define WING d = min(d, sdTriangle(pos, vec2(0.), vec2(.1,-.09), vec2(.02,-.04)));
    pos = rotate(pos, time); WING;
    pos = rotate(pos, PI*2./3.); WING;
    pos = rotate(pos, PI*2./3.); WING;
    return vec4(vec3(1.), ALPHA(d));
}

vec4 grid(vec2 pos, vec3 v[4], vec3 col) {
    for (int i = 0; i < 4; ++i) {
        v[i].yz = rotate(v[i].yz, PI/4.);
        v[i].xz = rotate(v[i].xz, .5*sin(time));
        v[i]*=clamp(v[i].z+1., .2, 2.);
    }
    float d = sdTriangle(pos, v[0].xy, v[1].xy, v[2].xy);
    d = min(d, sdTriangle(pos, v[0].xy, v[2].xy, v[3].xy));
    return vec4(col, ALPHA(d));
}

vec4 solarPanel(vec2 pos, float scale) {
     pos/=scale;
    vec4 col = vec4(vec3(.8), ALPHA(sdBox(pos, vec2(.003, .1))));
    pos -= vec2(0.,.1);
    float w = .24, h = .12, dx = w / 4., dy = h / 2., k=1.;
    for (float x = -w/2.; x < w/2.; x += dx) {
        for (float y = -h/2.; y < h/2.; y += dy, k=-k) {
            vec3 gridCol = k > 0. ? vec3(0.,.2,.6) : vec3(0.,.3,.5);
            col = mixLayer(col, grid(pos, vec3[](vec3(x,y,0.),vec3(x+dx,y,0.),vec3(x+dx,y+dy,0.),vec3(x,y+dy,0.)), gridCol));
        }
    }
    return col;
}

vec4 opU(vec4 c1, vec4 c2) {return c1.w < c2.w ? c1 : c2; } 

vec4 tree(vec2 pos, float scale) {
     pos/=scale;
    vec4 col = vec4(vec3(.5), ALPHA(sdBox(pos, vec2(.008, .08))));
    pos.x += .1*sin(2.*time) * pos.y;
    col = mixLayer(col, vec4(vec3(.2, .32, .1), ALPHA(sdTriangle(pos, vec2(-.1, -.03), vec2(.1, -.03), vec2(0., .05)))));
    col = mixLayer(col, vec4(vec3(.2, .36, .1), ALPHA(sdTriangle(pos, vec2(-.07, .02), vec2(.07, .02), vec2(0., .08)))));
    col = mixLayer(col, vec4(vec3(.2, .34, .1), ALPHA(sdTriangle(pos, vec2(-.045, .06), vec2(.045, .06), vec2(0., .14)))));
    return col;
}

vec4 mountain(vec2 uv) {
    vec4 col = mixLayer(vec4(0.), windmill(uv-vec2(.5, .2), .3));
    col = mixLayer(col, hill(uv-vec2(-1.5, -.4), vec2(.2, .7), vec3(.2, .32, .1), true));
    col = mixLayer(col, hill(uv-vec2(1.5, -.4), vec2(.3, 1.2), vec3(.62, .67, .68), true));
    col = mixLayer(col, hill(uv-vec2(-.5, -.4), vec2(.5, .55), vec3(.0, .7, .2), false));
    col = mixLayer(col, hill(uv-vec2(.5, -.4), vec2(.5, .6), vec3(.0, .7, .2), false));
    col = mixLayer(col, hill(uv-vec2(-1., -.4), vec2(.4, .35), vec3(.2, .85, .4), false));
    col = mixLayer(col, windmill(uv-vec2(-.5, .1), .45));
    col = mixLayer(col, windmill(uv-vec2(1., -.05), .6));
    col = mixLayer(col, hill(uv-vec2(1., -.4), vec2(.4, .3), vec3(.2, .85, .4), false));
    col = mixLayer(col, hill(uv-vec2(.0, -.4), vec2(.5, .5), vec3(.2, .85, .4), false));
    col = mixLayer(col, windmill(uv-vec2(.2, .1), .8));
    col = mixLayer(col, windmill(uv-vec2(-.3, -.2), 1.));
    col = mixLayer(col, windmill(uv-vec2(-1., .05), .7));
       col = mixLayer(col, solarPanel(uv-vec2(.3, -.2), 1.));
    col = mixLayer(col, solarPanel(uv-vec2(-.8, -.1), .8));
    col = mixLayer(col, tree(uv-vec2(1.2, -.2), 1.));
    col = mixLayer(col, tree(uv-vec2(-1.1, -.1), .9));
    col = mixLayer(col, tree(uv-vec2(-.1, -.15), .9));
    col = mixLayer(col, tree(uv-vec2(0., .12), .6));
    col = mixLayer(col, tree(uv-vec2(.1, .0), .6));
    col = mixLayer(col, tree(uv-vec2(-.1, .1), .6));    
    return col;  
}

vec4 building(vec2 uv) {
    float d = uv.y - (.8*hash(floor(uv.x*8.))+.2);
    vec3 col = vec3(.15, .35, .5);
    return vec4(col, ALPHA(d));   
}

vec4 wave(vec2 uv, float height, float amplitude) {
    float noise = amplitude * (fbm(uv.x*4., 4, .1) + fbm(uv.x*4. + time, 4, .1));
    float d = uv.y - (noise + height);
    return vec4(vec3(.0, .15, .4), 1.-clamp(d*30., 0., 1.));
}

vec4 water(vec2 uv) {
    vec4 col;
    float height = -.4, amplitude = .005;
    for (int i = 0; i < 5; ++i, uv.x+=10., height-=.13, amplitude+=.003)
        col = mixLayer(col, wave(uv, height, amplitude));
    return col;
}

vec4 sailingBoat(vec2 uv) {
    vec4 col = vec4(vec3(1.), ALPHA(sdBox(uv-vec2(0.,.13), vec2(.001, .1))));
    vec2 p[4] = vec2[](vec2(-.1, .0), vec2(.1, .0), vec2(.15, .07), vec2(-.13,.05));
    col = mixLayer(col, vec4(vec3(1.,.8,.0), ALPHA(sdTriangle(uv, p[0], p[1], p[3]))));
    col = mixLayer(col, vec4(vec3(1.,.8,.0), ALPHA(sdTriangle(uv, p[1], p[2], p[3]))));
    col = mixLayer(col, vec4(vec3(1.), ALPHA(sdTriangle(uv, vec2(.01,.23), vec2(.01,.08), vec2(.1,.08)))));
    col = mixLayer(col, vec4(vec3(1.), ALPHA(sdTriangle(uv, vec2(-.01,.21), vec2(-.01,.08), vec2(-.08,.08)))));
    return col;
}

vec4 render(vec2 uv) {
    vec4 col = sky(uv);
    col = mixLayer(col, sun(uv));
    col = mixLayer(col, building(uv));
    col = mixLayer(col, mountain(uv));
    col = mixLayer(col, water(uv));
    return col;
}

void main(void) {
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy) / resolution.y;
    if (uv.y >= -.4) 
        glFragColor = render(uv);
    else //reflections
        glFragColor = mix(render(uv), render(vec2(uv.x, max(-.4, -uv.y*2.-1.2 + .04*fbm(uv.x*4.+time,4,.1)))), .1);
        float w = resolution.x / resolution.y + .2;
    
    uv -= vec2(2.*w*fract(.05*time+.5)-w,-.7);
    uv = rotate(uv, sin(5.*time) * .02);
    glFragColor = mixLayer(glFragColor, sailingBoat(uv));
    //reflection of the sailing boat
    glFragColor = mixLayer(glFragColor, .3*sailingBoat(vec2(uv.x, -uv.y*2.-.05 + .04*fbm(uv.x*4.+time,4,.1))));
}
