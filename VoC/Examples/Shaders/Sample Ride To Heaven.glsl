#version 420

// original https://www.shadertoy.com/view/wtXGDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAT_RAILS 0
#define MAT_BARS 1
#define MAT_CART 2
#define MAT_TERRAIN 3
#define MAT_CART_BOLTS 4
#define MAT_RAIL_BOLTS 5
#define MAT_EDGE 6
#define MAT_TREE 7

#define PRIMARY_STEPS 256
#define SHADOW_STEPS 32

#define EPSILON 0.001
#define MAX_DIST 1750.

#define CEL_SHADES 6.
#define EDGE_THICKNESS 0.01
#define EDGE_MAX_DIST 1000.

float time2 = time;

struct Light {
    vec3 dir;
    vec3 diffColor;
    vec3 specColor;
};

struct Material {
    vec3 diffColor;
    vec3 specColor;
    float shininess;
};

struct ScenePoint {
    int materialId; //Material of closest object
    float d; //Distance to closest object
    float t; //Distance on ray that generated this point
};

Light lights[3];
Material materials[8];

float rand(float v) {
    return fract(sin(v) * 5364.54367);
}

float rand(vec2 p) {
    return fract(sin(dot(p.xy, vec2(12.9898, 78.233))) * 47851.5453123);
}

float noise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float a = rand(i);
    float b = rand(i + vec2(1., 0.));  
    float c = rand(i + vec2(0., 1.)); 
    float d = rand(i + vec2(1., 1.)); 
    
    float ab = mix(a, b, smoothstep(0., 1., f.x));
    float cd = mix(c, d, smoothstep(0., 1., f.x));
    return mix(ab, cd, smoothstep(0., 1., f.y));
}

float fbm(vec3 p) {
    float v = 0.;
    float amplitude = .5;
    float freq = 0.;
    
    for(int i = 0; i < 2; ++i) {
        v += amplitude * noise(p.xz);
        p *= 2.;
        amplitude *= .5;
    }
    return v;
}

vec3 cam2world(vec3 v, vec3 pos, vec3 lookAt) {
    vec3 z = normalize(lookAt - pos);
    vec3 y = vec3(0, 1, 0);
    vec3 x = normalize(cross(z, y));
    y = normalize(cross(x, z));
    mat3 m = mat3(x, y, z);
    return normalize(m * v);
}

float sphere(vec3 p, float r) {
     return length(p) - r;
}

float box(vec3 p, vec3 b)  {
    vec3 d = abs(p) - b;
    return length(max(d, 0.)) + min(max(d.x, max(d.y, d.z)), 0.);
}

float roundBox(vec3 p, vec3 b, float r) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.)) - r + min(max(d.x, max(d.y, d.z)), 0.);
}

float plane(vec3 p, vec3 n, float d)  {
    return dot(p, n) - d;
}

float roundCone( vec3 p, float r1, float r2, float h) {
    vec2 q = vec2(length(p.xz), p.y);
    float b = (r1 - r2) / h;
    float a = sqrt(1.0 - b * b);
    float k = dot(q, vec2(-b, a));
    if(k < 0.) return length(q) - r1;
    if(k > a * h) return length(q - vec2(0., h)) - r2;
    return dot(q, vec2(a, b) ) - r1;
}

vec3 repeat(vec3 p, vec3 period) {
    return mod(p, period) - .5 * period;
}

float smoothUnion(float v1, float v2, float k) {
    float h = clamp(.5 + .5 * (v2 - v1) / k, 0., 1.);
    return mix(v2, v1, h) - k * h * (1. - h); 
}

float hills(float z) {
    z -= time2;
    return sin(z / 128.) * cos(z / 64.) * 6.;
}

vec3 sky(vec3 originalColor, float dist, vec3 rd) {
    const vec3 SKY_COLOR = vec3(.2, .4, 1.);
    
    vec3 sunDir = -lights[0].dir;
    float skyAmmount = smoothstep(5., 25., dist) * (1. - exp(-dist * 0.012));
    float sunAmmount = max(dot(rd, sunDir), 0.);

    vec3 diff = sunDir - rd;
    float rays = smoothstep(-1., 1., sin(atan(diff.y, diff.x) * 8. + time2 * .3)) * .35;
    rays *= step(MAX_DIST * .5, dist);
    rays = min(rays, length(diff * .3));

    vec3 skyCol = mix(SKY_COLOR, lights[0].diffColor, pow(sunAmmount, 50.) + rays);
    return mix(originalColor, skyCol, skyAmmount);
}

ScenePoint scene(vec3 p) {
    ScenePoint result;

    p.y -= hills(p.z);

    //Rails
    vec3 xMirrorP = p;
    xMirrorP.x = abs(xMirrorP.x);

    float rails = box(xMirrorP - vec3(1.5, 0., 0.), vec3(.12, .2, 999.));
    rails = max(rails, -box(xMirrorP - vec3(1.4, 0., 0.), vec3(.06, .15, 999.)));
    result.materialId = MAT_RAILS;
    result.d = rails;
    
    //Bars
    vec3 scrollP = p;
    scrollP.z = scrollP.z - time2;
    
    vec3 repeatedP = scrollP;
    repeatedP.z = repeat(repeatedP, vec3(1, 1, 2)).z;
    
    vec3 xMirrorRepP = repeatedP;
    xMirrorRepP.x = abs(xMirrorRepP.x);
    
    repeatedP.x += rand(floor(scrollP.z + .5)) * .5 - .25;
    float bars = box(repeatedP - vec3(0, -.4, 0), vec3(2.4, .18, .2));
    if(bars < result.d) {
        result.materialId = MAT_BARS;
        result.d = bars;
    }

    //Bar bolts
    float bolts = sphere(xMirrorRepP - vec3(1.44, -.15, 0.1), .05);
    if(bolts < result.d) {
        result.materialId = MAT_RAIL_BOLTS;
        result.d = bolts;
    }
    
    //Cart
    const float cartZ = 19.4;
    float cart = roundBox(p - vec3(0., .8, cartZ), vec3(1.2, 1., 1.), .15);
    cart = max(cart, -roundBox(p - vec3(0., 1., cartZ), vec3(.9, 1., .7), .1));
    cart = max(cart, -roundBox(p - vec3(0., 1., cartZ), vec3(1., .65, .65), .16));
    cart = min(cart, box(p - vec3(0., 1., cartZ - 0.84), vec3(.75, .5, .05)));
    if(cart < result.d) {
        result.materialId = MAT_CART;
        result.d = cart;
    }

    //Cart bolts
    vec3 cartBoltsP = p;
    cartBoltsP.x *= step(-1.1, cartBoltsP.x) * step(cartBoltsP.x, 1.1);
    cartBoltsP.x = repeat(cartBoltsP, vec3(.25, 1., 1.)).x;
    float cartBolts = sphere(cartBoltsP - vec3(0., 1.83, cartZ - .76), .02);

    vec3 cartBoltsP2 = p;
    cartBoltsP2.x = abs(cartBoltsP2.x);
    cartBoltsP2.y = abs(cartBoltsP2.y - 1.05);
    cartBolts = min(cartBolts, sphere(cartBoltsP2 - vec3(0.63, .35, cartZ - .76), .02));
    if(cartBolts < result.d) {
        result.materialId = MAT_CART_BOLTS;
        result.d = cartBolts;
    }

    //Terrain
    vec3 terrP = scrollP;
    float ridge = smoothstep(2., 10., terrP.x) + smoothstep(-2., -10., terrP.x);
    terrP.y -= ridge * (sin(terrP.z * .02) * 2. + 8.);

    terrP.x -= sin(terrP.z * .65) * 2.;
    terrP.y -= fbm(terrP) * (ridge + .3);

    float terr = plane(terrP, vec3(0., 1., 0.), -.45);
    if(terr < result.d) {
        result.materialId = MAT_TERRAIN;
        result.d = smoothUnion(result.d, terr, .05);

        float n = noise(vec2(p.x, terrP.z) * 1.2);
        vec3 c = mix(vec3(.1, .9, .15), vec3(0., .85, .2), smoothstep(.3, .5, n));
        materials[MAT_TERRAIN].diffColor = mix(vec3(.6, .35, .33), c, pow(ridge, .4));
    }

    //Trees
    vec3 treeP = vec3(p.x, terrP.y, scrollP.z);
    treeP.x = abs(treeP.x);
    treeP -= vec3(11.5, 2.9, 0.);

    const float cells = 27.;
    treeP.z = repeat(treeP, vec3(1., 1., cells)).z;
    vec2 id = floor(vec2(step(p.x, .0), scrollP.z / cells));

    float r = rand(id);
    float r2 = rand(id + vec2(12.23, 42.25));
    float r3 = rand(id - vec2(76.432, 980.543));

    float tree = roundCone(treeP, (r + .3) * 2.5, (r2 + .45) * 1.4, (r3 + .4) * 3.2);
    if(tree < result.d) {
        result.materialId = MAT_TREE;
        result.d = tree;
        materials[MAT_TREE].diffColor = mix(vec3(.8, .3, .15), vec3(.15, .95, .15), r2);
    }
    tree = min(tree, box(treeP - vec3(0., -2., 0.), vec3(.2, 2., .2)));
    if(tree < result.d) {
        result.materialId = MAT_BARS;
        result.d = tree;
    }
    
    return result;
}

bool rm(int steps, vec3 ro, vec3 rd, out ScenePoint sp) {
    float t = 0.;
    float minD = 99999.;
    
    for(int i = 0; i < steps && t < MAX_DIST; ++i) {
        vec3 p = ro + rd * t;
        sp = scene(p);
        sp.t = t;
        if(sp.d < EPSILON)
            return true;
        
        //Edge detection
        minD = min(sp.d, minD);
        if(sp.d > minD && minD < EDGE_THICKNESS * (1. - (t / EDGE_MAX_DIST))) {
            sp.materialId = MAT_EDGE;
            return true;
        }
        
        t += sp.d;
    }
    return false;
}

vec3 normal(vec3 p, ScenePoint sp) {
    vec2 e = vec2(EPSILON, 0.);
    //float d = scene(p).d;
    float x = scene(p - e.xyy).d;
    float y = scene(p - e.yxy).d;
    float z = scene(p - e.yyx).d;
    return normalize(vec3(sp.d) - vec3(x, y, z));
}

vec3 shade(vec3 cameraPos, vec3 rd, ScenePoint sp) {
    if(sp.materialId == MAT_EDGE) {
        vec3 c = materials[MAT_EDGE].diffColor;
        return mix(c, c * .01, smoothstep(.0, 1., sp.d / EDGE_THICKNESS));
    }
    
    vec3 albedo = materials[sp.materialId].diffColor;
    vec3 specular = materials[sp.materialId].specColor;
    float shininess = materials[sp.materialId].shininess;
    
    vec3 p = cameraPos + rd * sp.t;
    vec3 N = normal(p, sp);
    vec3 V = normalize(cameraPos - p);
    
    vec3 sum = vec3(0);
    for(int i = 0; i < 3; ++i) {
    
        vec3 L = -lights[i].dir;
        vec3 H = normalize(V + L);
    
        float difFactor = max(0., dot(L, N));
        difFactor = ceil(difFactor * CEL_SHADES) / CEL_SHADES;
    
        float specFactor = pow(max(0., dot(H, N)), shininess);
        specFactor = ceil(specFactor * CEL_SHADES) / CEL_SHADES;
        
        sum += lights[i].diffColor * albedo * difFactor +
            lights[i].specColor * specular * specFactor;
    }
    
    ScenePoint shadowSp;
    bool hit = rm(SHADOW_STEPS, p + N * (EDGE_THICKNESS + EPSILON), -lights[0].dir, shadowSp);
    if(hit) {
        sum *= vec3(.8);
    }
    return sum;
}

void main(void) {
     time2 = time2 * 8.;

    //Sun Key
    lights[0].dir = normalize(vec3(0., -.05, 1.));
    lights[0].diffColor = vec3(.95, .95, .9);
    lights[0].specColor = vec3(1.);
    //Sun Fill
    lights[1].dir = normalize(vec3(1., -1., -.6));
    lights[1].diffColor = vec3(.7, .6, .6);
    lights[1].specColor = vec3(0.);
    //Sun Fill
    lights[2].dir = normalize(vec3(-1., -1., -.6));
    lights[2].diffColor = vec3(.7, .6, .6);
    lights[2].specColor = vec3(0.);

    materials[MAT_RAILS].diffColor = vec3(.1, .1, .05);
    materials[MAT_RAILS].specColor = vec3(.7);
    materials[MAT_RAILS].shininess = 10.;

    materials[MAT_BARS].diffColor = vec3(.1, .077, .05);
    materials[MAT_BARS].specColor = vec3(0.);
    materials[MAT_BARS].shininess = 1.;

    materials[MAT_CART].diffColor = vec3(.9, .55, .25);
    materials[MAT_CART].specColor = vec3(.7);
    materials[MAT_CART].shininess = 20.;

    //materials[MAT_TERRAIN].diffColor = vec3(0.); Dynamically generated
    materials[MAT_TERRAIN].specColor = vec3(0.);
    materials[MAT_TERRAIN].shininess = 1.;

    materials[MAT_CART_BOLTS].diffColor = vec3(.5, .35, .21);
    materials[MAT_CART_BOLTS].specColor = vec3(.2);
    materials[MAT_CART_BOLTS].shininess = 20.;

    materials[MAT_RAIL_BOLTS].diffColor = vec3(.05, .05, .05);
    materials[MAT_RAIL_BOLTS].specColor = vec3(.7);
    materials[MAT_RAIL_BOLTS].shininess = 10.;

    materials[MAT_EDGE].diffColor = vec3(0.1);
    materials[MAT_EDGE].specColor = vec3(.0);
    materials[MAT_EDGE].shininess = 1.;

    //materials[MAT_TREE].diffColor = vec3(.0); Dynamically generated
    materials[MAT_TREE].specColor = vec3(.0);
    materials[MAT_TREE].shininess = 1.;

    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;

    vec3 cameraPos = vec3(0., 2.5 + hills(19.1), 20.);   
    vec3 lookAt = vec3(sin(time2 * .05) * 1.3, 0.5, 0.);
    //if(mouse*resolution.xy.z > .0)
        lookAt.xy = vec2(15., 25.) * ((mouse*resolution.xy.xy / resolution.xy) - vec2(.5));
    
    vec3 rd = cam2world(vec3(uv, 1.5), cameraPos, lookAt); 

    ScenePoint sp;
    vec3 col = vec3(.4);

    bool hit = rm(PRIMARY_STEPS, cameraPos, rd, sp);
    if(hit) {
        col = shade(cameraPos, rd, sp);
    }

    col = sky(col, sp.t, rd);

    col = pow(col, vec3(1. / 2.2));
    glFragColor = vec4(col, 1.);
}
