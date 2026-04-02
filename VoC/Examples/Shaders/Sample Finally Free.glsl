#version 420

// original https://www.shadertoy.com/view/dt3fRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AMPLITUDE .78 // the height of the waves
float PI = 3.14159;

struct Hit {
    vec3 point;
    vec3 dir;
    int material;
};

struct OceanHit {
    float d;
    int material;
};

struct DuckHit {
    float d;
    int material;
};

struct WaterHit {
    float ocean;
    float duckie;
};

float opSmoothUnion( float d1, float d2, float k )
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdEllipsoid(vec3 p, vec3 r)
{
    float k0 = length(p / r);
    float k1 = length(p / (r * r));
    return k0 * (k0 - 1.0) / k1;
}

// some of this inspired by https://www.shadertoy.com/view/MdXyzX
WaterHit calcHeight(vec3 p, float iterations) {
    float iter = 0.;
    float addedNoiseW = 0.;
    float addedNoiseD = 0.;
    float frequency = .7;
    float weight = 1.;
    float timeMultiplier = 2.6;
    float sumW = 0.;
    float sumD = 0.;
    for(float i = 1.; i < iterations; i += 1.) {
        vec2 p2 = vec2(sin(iter), cos(iter));
        vec3 waveDirection = vec3(p2.x, 0., p2.y);
        // line of wave: waveDirection.x * x + waveDirection.z * y + 0
        // therefore the distance from our current point to this line is
        float a = waveDirection.x;
        float b = waveDirection.z;
        float distToLine = abs(a * p.x + b * p.z + 15.) / sqrt(a*a + b*b);
        
        float additionW = pow(3.5, sin(distToLine*frequency+time*timeMultiplier)-1.) * (weight);
        addedNoiseW += additionW;
        
        if(i < 7.) {
            vec3 dp = p;
            dp.y += 1.5;
            dp.z += 1.5;
            vec3 pd = vec3(0.,dp.y+0.8,dp.z-2.);
            distToLine = abs(a * pd.x + b * pd.z + 15.) / sqrt(a*a + b*b);
            float additionD = pow(3.5, sin(distToLine*frequency+time*timeMultiplier)-1.) * (weight);

            addedNoiseD += additionD;
            sumD += weight;
        }
        
        iter += 0.399963;
        weight *= 0.79;
        frequency *= 1.22;
        timeMultiplier /= 1.1;
        sumW += weight;
    }
    
    WaterHit waterHit;
    waterHit.ocean = addedNoiseW*AMPLITUDE / sumW;
    waterHit.duckie = addedNoiseD*AMPLITUDE / sumD;
    
    return waterHit;
}

vec4 translate(vec4 v, vec3 t) {
    mat4 translation = mat4(
        1., 0., 0., t.x,
        0., 1., 0., t.y,
        0., 0., 1., t.z,
        0., 0., 0., 1.
    );
    return v * translation;
}

vec4 rotateY(vec4 v, float theta) {
    float s = sin(PI * theta);
    float c = cos(PI * theta);
    mat4 rotX = mat4(
          c,  0.,  s, 0.,
          0., 1.,  0., 0.,
         -s,  0.,  c, 0.,
          0., 0.,  0.,  1.
    );
    return v * rotX;
}

vec4 rotateZ(vec4 v, float theta) {
    float s = sin(PI * theta);
    float c = cos(PI * theta);
    mat4 rotX = mat4(
          c, -s,  0., 0.,
          s,  c,  0., 0.,
          0., 0., 1., 0.,
          0., 0., 0.,  1.
    );
    return v * rotX;
}

DuckHit sdDuck(vec3 p) {

    vec4 dp = vec4(p.xyz, 1.);
    dp = translate(dp, vec3(0.,0.8,3.));
    float dBody = sdEllipsoid(dp.xyz, vec3(2., 1.3, 1.));
    
    vec4 head = vec4(p.xyz, 1.);
    head = translate(head, vec3(0.5,0.8-1.8,3.));
    head = rotateZ(head, 0.2);
    float dHead = sdEllipsoid(head.xyz, vec3(1., 1.05, 1.));
    
    vec4 wing1 = vec4(p.xyz, 1.);
    wing1 = translate(wing1, vec3(-0.3,0.7,2.));
    wing1 = rotateZ(wing1, -.3);
    wing1 = rotateY(wing1, 0.1);
    float dWing1 = sdEllipsoid(wing1.xyz/.1, vec3(5.,4.,2.))*.1;
    
    vec4 tail = vec4(p.xyz, 1.);
    tail = translate(tail, vec3(-1.8,0.3,3.));
    tail = rotateZ(tail, 0.7);
    float dTail = sdEllipsoid(tail.xyz/.1, vec3(4.6,2.,3.))*.1;
    
    vec4 beak1 = vec4(p.xyz, 1.);
    beak1 = translate(beak1, vec3(0.9, 0.8-2.,3.));
    beak1 = rotateZ(beak1, 0.15);
    float dBeak1 = sdEllipsoid(beak1.xyz/.2, vec3(5.,1.,3.))*.2;
    
    vec4 beak2 = vec4(p.xyz, 1.);
    beak2 = translate(beak2, vec3(0.9, 0.8-2.,3.));
    beak2 = rotateZ(beak2, -0.);
    float dBeak2 = sdEllipsoid(beak2.xyz/.2, vec3(5.,1.,3.))*.2;

    vec4 eye1 = vec4(p.xyz, 1.);
    eye1 = translate(eye1, vec3(.87, 0.8-2.4, 2.2));
    eye1 = rotateY(eye1, -0.2);
    eye1 = rotateZ(eye1, 0.2);
    float dEye1 = sdEllipsoid(eye1.xyz/.05, vec3(1., 3., 3.))*.05;
    
    float d = opSmoothUnion(dBody, dWing1, 0.1);
    d = opSmoothUnion(d, dHead, 0.1);
    d = opSmoothUnion(d, dTail, 0.4);
    d = opSmoothUnion(d, dBeak1, 0.1);
    d = opSmoothUnion(d, dBeak2, 0.1);
    
    DuckHit duckHit;
    if(dBeak2 <= 0.05 || dBeak1 <= 0.05) {
        duckHit.material = 2;
    } else if(dEye1 <= 0.05) {
        duckHit.material = 3;
    } else {
        duckHit.material = 1;
    }
    duckHit.d = d;
    return duckHit;
}

OceanHit sceneOpaque(vec3 p) {
    vec3 np = p;
    np.y += 11.7;
    
    WaterHit calcedHeight = calcHeight(np,20.);
    
    float oceanLocation = sdBox(np, vec3(40., 10., 40.))
                          -calcedHeight.ocean;
    
    vec3 dp = p;
    dp.y += 1.4;
    dp.z += 1.5;
    float duckieLocation = 10.;
    DuckHit duckHit;
    dp.y -= calcedHeight.duckie;
    duckHit = sdDuck(dp/.2);
    duckHit.d *= .2;
    duckieLocation = duckHit.d;
    OceanHit oceanHit;
    oceanHit.material = duckHit.material * int(step(duckieLocation-oceanLocation,0.));
    oceanHit.d = min(oceanLocation, duckieLocation);
    return oceanHit;
}

OceanHit sceneWater(vec3 p) {
    //return opSmoothUnion(sceneOpaque(p), sdOrca(p), 1.);
    return sceneOpaque(p);
}

float sceneFull(vec3 p) {
    return sceneWater(p).d;
}

vec3 calcNormal(vec3 p) {
    vec2 h = vec2(.0001, 0); // Epsilon vector for swizzling
    vec3 normal = vec3(
       sceneFull(p+h.xyy) - sceneFull(p-h.xyy),   // x gradient
       sceneFull(p+h.yxy) - sceneFull(p-h.yxy),   // y gradient
       sceneFull(p+h.yyx) - sceneFull(p-h.yyx)    // z gradient
    );
    return normalize(normal);
}

// return where we hit, and the direction to move from there
Hit newHit(Hit h) {
    Hit hit;
    hit.point = vec3(-111.);
    hit.dir = h.dir;
    hit.material = 0;
    
    vec3 ogPoint = h.point;
    vec3 ogDir = h.dir;
    
    ogPoint += normalize(ogDir)*0.011;
    for(int i = 0; i < 100; i++) {
        OceanHit oceanHit = sceneWater(ogPoint);
        float distToWater = oceanHit.d;
        if(distToWater <= 0.01) {
            vec3 d = normalize(ogDir);
            vec3 n = calcNormal(ogPoint);
            
            hit.point = ogPoint;
            hit.dir = reflect(normalize(ogDir), n);
            hit.material = oceanHit.material;
            
            break;
        }
        ogPoint += normalize(ogDir)*distToWater;
    }
    return hit;
}

vec3 colors[4];

vec3 calcSkyColor(Hit hit, float damper, int material) {
    vec3 dir = hit.dir;
    vec3 ret = vec3(0.);
    
    colors[1] = vec3(1.,1.,0.2);
    colors[2] = vec3(1.,0.2,0.2);
    colors[3] = vec3(0.);
    
    vec3 color1;
    if(material == 1 || material == 2 || material == 3) {
        vec3 duckColor = colors[material];
        vec3 n = calcNormal(hit.point);
        vec3 lightDir = normalize(vec3(0.,1.,0.));
        float diffuse = clamp(dot(n, lightDir),0.,1.)*2.;
        vec3 fc = duckColor * diffuse;
        fc = max(fc, duckColor*0.67);
        color1 = clamp(fc+0.1*duckColor, 0., 1.);
    }
    
    
    dir.y -= sin(time/4.)/5.;
    ret.rg = vec2((.8-abs(dir.y/1.5)));
    ret.g -= 0.15;
    ret.b += 0.3;
    
    vec3 newDir = vec3(dir.xy*6., dir.z);
    float dotProduct = dot(normalize(newDir), normalize(vec3(0.,0.,1.)));
    
    vec3 newRet = vec3(1.)*pow(-dotProduct, 7.)*5.;
    ret += newRet;
    
    vec3 color2 = clamp(ret / damper, 0., 1.);
    return mix(color1, color2, step(float(material), .5));
}

void main(void)
{
    // Calculate uv
    vec2 uv = (gl_FragCoord.xy / resolution.xy - .5) * 2.;
    uv.x *= resolution.x / resolution.y;
    
    vec3 lightPos = vec3(-0.8,-0.1,1.);
    vec3 lightColor = vec3(.8,0.8,0.3);
   
    vec3 cam_origin = vec3(0.,0.,1.);
    vec3 rayDir = normalize(vec3(uv,0.) - cam_origin);
    vec3 camPos = cam_origin;
    vec3 color = vec3(0.);
    float blurFactor = 0.;
    
    vec3 d;
    vec3 n;
    vec3 r;
    float distToWater;
    
    Hit hit;
    hit.point = camPos;
    hit.dir = rayDir;
    if(rayDir.y > 0.) {
        color = calcSkyColor(hit, 1., -1);
        
        color -= mod(color,.1);
        glFragColor = vec4(color, 1.);
        return;
    }
    
    Hit secondHit;
    secondHit.material = 0;
    hit = newHit(hit);
    if(hit.material != 0 || hit.dir.y > 0. || hit.dir.x > 0.3 || hit.dir.x < -0.3) {
        color = calcSkyColor(hit, 1., hit.material);
    } else {
        vec3 waterColor = calcSkyColor(hit, 1., hit.material);
        Hit secondHit;
        secondHit = newHit(hit);
        if(secondHit.material != 0) {
            vec3 duckieColor = calcSkyColor(secondHit, 1., secondHit.material);
            color = mix(waterColor, duckieColor, 0.7);
            glFragColor = vec4(color,1.);
            return;
        } else {
            color = waterColor;
        }
    }
    
    if(hit.point != vec3(-111.) && hit.material == 0) {
        // genius by https://www.shadertoy.com/view/MdXyzX
        vec3 n = calcNormal(hit.point);
        n.y = abs(n.y);
        float dist = distance(camPos, hit.point);
        n = mix(n, vec3(0.0, 1.0, 0.0), min(1.0, sqrt(dist*0.5) * 1.1));
        float fres = (0.1 + (1.0-0.04)*(pow(1.0 - max(0.0, dot(-n, rayDir)), 1.0)));
        
        vec3 scattering = vec3(0.0493, 0.1598, 0.317)*2.4;
        if(secondHit.material != 0) {
            scattering = vec3(0.3, 0.3, 0.15)*2.4;
        }
        
        color = fres * color + (1.0 - fres) * scattering;
        
    }
    
    color -= mod(color,.1);
    glFragColor = vec4(color,1.);
}
