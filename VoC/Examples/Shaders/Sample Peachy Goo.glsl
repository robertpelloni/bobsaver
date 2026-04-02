#version 420

// original https://www.shadertoy.com/view/ttSXRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Carl-Mikael Lagnecrantz 2019
// Much of this code was derived from shaders by Inigo Quilez (iq)

// Raymarches noise inside a sphere to create a peachy goo ball

vec3 intersectSphere( in vec3 rayPos, in vec3 rayDir, in vec3 spherePos, in float radius )
{
    vec3 v = rayPos - spherePos;
    float b = dot(v, rayDir);
    float c = dot(v, v) - radius * radius;
    float discr = b * b - c;
    
    // A negative discriminant corresponds to ray missing sphere 
    if (discr < 0.0) return vec3(0.0,0.0,discr);
    
    // Ray intersects sphere. Compute and return distances of both intersections, front and back of sphere
    discr = sqrt(discr);
    return vec3(-b - discr, -b + discr, discr);
}

float hash(float n) { return fract(sin(n)*753.5453123); }

float noise(in vec3 x)
{
    vec3 p = floor(x);
    vec3 w = fract(x);
    vec3 u = w * w*(3.0 - 2.0*w);
    vec3 du = 6.0*w*(1.0 - w);

    float n = p.x + p.y*157.0 + 113.0*p.z;

    float a = hash(n + 0.0);
    float b = hash(n + 1.0);
    float c = hash(n + 157.0);
    float d = hash(n + 158.0);
    float e = hash(n + 113.0);
    float f = hash(n + 114.0);
    float g = hash(n + 270.0);
    float h = hash(n + 271.0);

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = e - a;
    float k4 = a - b - c + d;
    float k5 = a - c - e + g;
    float k6 = a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return k0 + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x*u.y + k5 * u.y*u.z + k6 * u.z*u.x + k7 * u.x*u.y*u.z;
}

float fractalNoise(in vec3 x)
{
    const float scale = 3.0;
    
    float a = 0.0;
    float b = 0.5;
    float f = 1.0;

    float centerAspect = x.x*x.x + x.y*x.y + x.z*x.z;
    float centerFade = (1.0 - centerAspect) * (1.0 - centerAspect);
    
    // Run iterations of noise
    for (int i = 0; i<5; i++)
    {
        vec3 pp = f * x*scale;
        pp.x += sin(time * 0.1 * (float(i) + 1.0));
        pp.y += cos(time * 0.3 * (float(i) + 1.0));
        pp.z += sin(time * 0.6 * (float(i) + 1.0));
        float n = noise(pp);
        a += b * n;           // accumulate values        
        b *= 0.52;             // amplitude decrease
        f *= -1.3 - 2.2 * centerFade; // frequency increase
    }
    
    // Fade outer rim of sphere to nothing so that no part of the mesh will intersect the sphere hull
    centerAspect = 1.0 - pow(centerAspect, 40.0);
    
    a = 1.0 - pow(1.0 - a, 1.3);
    
    // Add small surface bumbs
    float smallBumps = noise(x * 130.0 + time * 4.0);
    a += smallBumps * 0.06 * (1.0 - centerAspect);
    
    return a * centerAspect;
}

vec3 calcNormal(vec3 pos)
{
    vec2 eps = vec2(0.001, 0.0);

    vec3 nor = vec3(fractalNoise(pos + eps.xyy) - fractalNoise(pos - eps.xyy),
        fractalNoise(pos + eps.yxy) - fractalNoise(pos - eps.yxy),
        fractalNoise(pos + eps.yyx) - fractalNoise(pos - eps.yyx));
    return normalize(nor);
}

vec3 background(vec2 uv)
{
    vec2 uvScreen = (uv + 1.0) * 0.5; // Convert from -1...1 to 0...1
    vec3 back = vec3(0.5, 0.6, 0.6);
    back += (vec3(0.6, 0.8, 0.95) - back) * uvScreen.y;
    back += vec3(1.0 - pow(1.0 - length(uv), 2.0)) * 0.2;
    back += (1.0 - clamp(length(uv), 0.0, 1.0)) * 0.3;
    
    return back;
}

vec3 raymarch(vec3 ro, vec3 rd, vec2 tminmax, vec2 uv)
{
    // Raymarch
    const int numIter = 96;
    float depth = tminmax.x;
    int hasSetDepth = 0;
    float accum = 0.0;
    for (int i = 0; i<numIter; i++)
    {
        float loopVal = float(i) / float(numIter);
        loopVal *= loopVal * loopVal * loopVal; // Move in smaller steps in the beginning to counter banding
        float t = tminmax.x + (tminmax.y - tminmax.x) * loopVal;
        
        vec3 pos = ro + t * rd;
        
        // Get noise value
        float noiseVal = fractalNoise(pos);
        
        // If the noise value is above 0.55 it counts as a surface hit
        if (noiseVal > 0.55 && hasSetDepth == 0)
        {
            depth = t;
            hasSetDepth = 1;
        }
        accum += noiseVal * 2.0; // Accumulate raymarching noise values
    }
    if (hasSetDepth == 0) return background(uv); // There was no hit
    
    
    vec3 sectPos = ro + rd * depth; // Intersection pos
    vec3 norm = calcNormal(sectPos); // Normal
    
    // Distance from sphere center values
    float centerAspect = length(sectPos);
    float centerAspectSquared = centerAspect * centerAspect;

    // Lighting
    vec3 lightDir = vec3(0.0, -1.0, 0.0); // Top light
    vec3 diffuse = clamp((dot(norm, lightDir)),0.0, 1.0) * vec3(0.4, 0.8, 0.9);
    diffuse *= diffuse * 1.5;
    vec3 lightDir2 = normalize(vec3(1.0, 0.0, 1.0)); // Back light
    vec3 diffuse2 = clamp((dot(norm, lightDir2)),0.0, 1.0) * vec3(0.2, 0.8, 0.9);
    diffuse2 *= centerAspectSquared * centerAspect;
    diffuse += diffuse2 * 2.5;
    
    // Specular
    vec3 camToPos = normalize(sectPos - ro);
    vec3 h = normalize(lightDir + camToPos);
    float nDotH = clamp((dot(norm, h)), 0.0, 1.0);
    float specular = pow(nDotH, 40.0); // Power controls glossiness
    diffuse += specular * 0.5;
    
    // Accumulated raymarch values simulates some smoke
    accum /= float(numIter);
    vec3 back = background(uv);
    vec3 smoke = back + (vec3(accum) - back) * accum * (1.0 - pow(centerAspect, 30.0));
    
    // Calculate inner glow
    float innerGlow = 1.0 - clamp((centerAspect / 0.75), 0.0, 1.0);
    
    centerAspect *= centerAspectSquared;
    centerAspectSquared = centerAspect * centerAspect;
    
    // Color adjustments
    vec3 finalCol = diffuse * vec3(0.36, 0.28, 0.28);
    finalCol += vec3(1.0, 0.4, 0.2) * centerAspect;
    finalCol += vec3(1.0, 0.8, 0.6) * centerAspectSquared * 0.5;
    
    // Darken towards middle
    finalCol *= 0.3 + 0.7 * centerAspect;
    
    // Inner glow
    finalCol += vec3(1.0, 0.35, 0.25) * innerGlow * 1.5;
    finalCol += vec3(1.0, 0.6, 0.25) * innerGlow * (1.0 - centerAspect) * (1.0 - centerAspect);
    
    // Smoke added from raymarch
    float camDot = 1.0 - pow(clamp(dot(rd, norm), 0.0, 1.0), 3.0); // Fresnel
    float smokeBlend = 0.7 * camDot * centerAspectSquared;
    finalCol += (smoke - finalCol) * smokeBlend;
    
    // Fade outer rim of sphere to background slightly
    float rimBlend = pow(length(uv), 6.0);
    finalCol += (back - finalCol) * rimBlend;

    // Some contrast
    finalCol = (finalCol - 0.8) * 1.2 + 0.8;
    
    return clamp(finalCol, 0.0, 1.0);
}

void main(void)
{
    // Camera coordinates (from -1 to 1)
    vec2 uv = (-resolution.xy + 2.0*gl_FragCoord.xy) / resolution.y;
    
    // Setup camera
    vec3 ro = vec3(0.0, 1.6, 1.6 );
    vec3 ta = vec3(0.0);
    
    // Camera matrix    
    vec3  cw = normalize( ta-ro );
    vec3  cu = normalize( cross(cw,vec3(0.0, 1.0, 0.0)) );
    vec3  cv = normalize( cross(cu,cw) );
    vec3  rd = normalize( uv.x*cu + uv.y*cv + 1.7*cw );
    
    // Intersect sphere
    vec3 sect = intersectSphere(ro, rd, vec3(0.0, 0.0, 0.0), 1.0);
    
    // Raymarch
    vec3 col;
    if (sect.z < 0.0) col = background(uv);
    else col = raymarch(ro, rd, sect.xy, uv);

    glFragColor = vec4(col,1.0);
}
