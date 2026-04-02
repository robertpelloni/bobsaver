#version 420

// original https://www.shadertoy.com/view/WstfD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// planet with atmosphere inspired by Sebastian Lague's Coding Adventure

// any tips on rendering the sun would be appreciated!

// noise from: https://github.com/ashima/webgl-noise/blob/master/src/noise3D.glsl
vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}
vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}
vec4 permute(vec4 x) {
    return mod289(((x*34.0)+1.0)*x);
}
vec4 taylorInvSqrt(vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}
float snoise(vec3 v) { 
    const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
    const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i  = floor(v + dot(v, C.yyy) );
    vec3 x0 =   v - i + dot(i, C.xxx) ;

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );

    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;

    // Permutations
    i = mod289(i); 
    vec4 p = permute( permute( permute( 
          i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
        + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
        + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

    // Gradients: 7x7 points over a square, mapped onto an octahedron.
    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
    float n_ = 0.142857142857; // 1.0/7.0
    vec3  ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );

    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);

    //Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.5 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 105.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1),
            dot(p2,x2), dot(p3,x3) ) );
}

vec2 raySphere (vec3 sphereCenter, float sphereRadius, vec3 origin, vec3 ray) {
    vec3 offset = origin - sphereCenter;
    float a = 1.0;
    float b = 2.0 * dot(offset, ray);
    float c = dot(offset, offset) - sphereRadius * sphereRadius;
    float d = b * b - 4.0 * a * c;

    if (d > 0.0) {
        float s = sqrt(d);
        float dstToSphereNear = max(0.0, (-b - s) / (2.0 * a));
        float dstToSphereFar = (-b + s) / (2.0 * a);
        if (dstToSphereFar >= 0.0) {
            return vec2(dstToSphereNear, dstToSphereFar - dstToSphereNear);
        }

    }
    return vec2(100.00, -1.0);
}

const float epsilon = 0.003;
const vec3 dirToSun = normalize(vec3(0.9, 0, 1));
const vec3 planetCenter = vec3(0.0, 0.0, 0.0);
const float atmosphereRadius = 1.7;
const float planetRadius = 1.0;
const float numInScatteringPoints = 8.0;
const float densityFalloff = 11.0;
const float numOpticalDepthPoints = 8.0;

const float scatteringStrength = 13.0;
const vec3 waveLengths = vec3(800, 530, 440);
const vec3 scatterCoefs = scatteringStrength * vec3(
    pow(400.0 / waveLengths.x, 4.0), 
    pow(400.0 / waveLengths.y, 4.0), 
    pow(400.0 / waveLengths.z, 4.0));

float densityAtPoint (vec3 p) {
    float heightAboveSurface = length(p - planetCenter) - planetRadius;
    float height01 = heightAboveSurface / (atmosphereRadius - planetRadius);
    float localDensity = exp(-height01 * densityFalloff) * (1.0 - height01);
    return localDensity;
}

float opticalDepth (vec3 ro, vec3 rd, float rl) {
    vec3 densitySamplePoint = ro.xyz;
    float stepSize = rl / (numOpticalDepthPoints - 1.0);
    float opticalDepth = 0.0;
    for (float i = 0.0; i < numOpticalDepthPoints; i += 1.0) {
        opticalDepth += densityAtPoint(densitySamplePoint) * stepSize;
        densitySamplePoint += rd * stepSize;
    }
    return opticalDepth;
}

vec3 calculateLight (vec3 ro, vec3 rd, float rl, vec3 originalColor) {

    vec3 inScatterPoint = ro.xyz;

    float stepSize = rl / (numInScatteringPoints - 1.0);

    vec3 inScatteredLight = vec3(0, 0, 0);

    float viewRayOpticalDepth = 0.0;

    float ii = 0.0;
    for (float i = 0.0; i < numInScatteringPoints; i += 1.0) {

        float sunRayLength = raySphere(
            planetCenter, atmosphereRadius, inScatterPoint, dirToSun).y;

        float sunRayOpticalDepth = opticalDepth(
            inScatterPoint, dirToSun, sunRayLength);

        viewRayOpticalDepth = opticalDepth(
            inScatterPoint, -rd, stepSize * ii);

        vec3 transmittance = exp(
            (-sunRayOpticalDepth-viewRayOpticalDepth) * scatterCoefs);

        float localDensity = densityAtPoint(inScatterPoint);

        inScatteredLight += 
            localDensity * transmittance * 
            scatterCoefs * stepSize;
        inScatterPoint += 
            rd * stepSize;

        ii += 1.0;
    }

    float originalTransmittance = exp(-2.0*viewRayOpticalDepth);
    return originalTransmittance * originalColor + inScatteredLight;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.0) / resolution.yy;
    
    vec3 ray = normalize(vec3(uv, 1.0));
    float rot = time*0.4;
    vec3 cpos = -4.0 * vec3(cos(rot + 3.14 / 2.0), 0, sin(rot + 3.14 / 2.0));
       
    float ct = cos(rot), st = sin(rot);
    ray.xz = vec2(ray.x * ct - ray.z * st, ray.x * st + ray.z * ct);
    
    vec2 dstToPlanet = raySphere(planetCenter, planetRadius, cpos, ray);
    
    vec3 tint = vec3(0, 0, 0);
    
    if (dstToPlanet.y > 0.0) {
        vec3 pos = cpos + ray * dstToPlanet.x;
        vec3 normal = normalize(pos);
        float ns = 10.0 + time * 0.2;
        vec3 normal_edit = vec3(
            snoise(normal.xyz*25.0+ns), 
            snoise(normal.yzx*25.0+ns), 
            snoise(normal.zyx *25.0+ns));
           normal += normal_edit * 0.2;
        float diffuse = max(dot(normal, dirToSun), 0.0);
        float specular = dot(reflect(ray, normal), dirToSun);
        specular = pow(max(specular, 0.0), 16.0);

        float light = 0.7 * diffuse + 0.3 * specular;

        tint = vec3(0.8, 0.8, 0.8) * light;
    } else {
        float dp = dot(ray, dirToSun);            
        float sn = snoise(ray.xyz * 50.0);
        if (sn > 0.8) {
            sn -= 0.8;
            tint = vec3(sn, sn, sn) * 5.0;
        }
        if (dp > 0.997) {
            dp -= 0.997;
            dp *= 1000.0;
            tint = dp * vec3(1.0, 0.8, 0.5);
        }
    }
    vec2 t = raySphere(planetCenter, atmosphereRadius, cpos, ray);
    if (t.y > 0.0) {
        float nt = t.x, ft = min(t.y, dstToPlanet.x - t.x);
        vec3 posInAtmosphere = cpos + ray * (nt + epsilon);
        tint = calculateLight(posInAtmosphere, ray, ft - epsilon * 2.0, tint);
    }
    glFragColor = vec4(tint,1.0);
}
