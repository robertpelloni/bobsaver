#version 420

// original https://www.shadertoy.com/view/7lfBRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2017 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// https://www.youtube.com/c/InigoQuilez
// https://iquilezles.org/

// Computes the analytic derivatives of a 3D Gradient Noise. This can be used for example to compute normals to a
// 3d rocks based on Gradient Noise without approximating the gradient by having to take central differences. More
// info here: https://iquilezles.org/articles/gradientnoise

vec3 hash( vec3 p ) // replace this by something better. really. do
{
    p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
              dot(p,vec3(269.5,183.3,246.1)),
              dot(p,vec3(113.5,271.9,124.6)));

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

// return value noise (in x) and its derivatives (in yzw)
vec4 noised( in vec3 x )
{
    // grid
    vec3 i = floor(x);
    vec3 w = fract(x);
    
    #if 1
    // quintic interpolant
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);
    #else
    // cubic interpolant
    vec3 u = w*w*(3.0-2.0*w);
    vec3 du = 6.0*w*(1.0-w);
    #endif    
    
    // gradients
    vec3 ga = hash( i+vec3(0.0,0.0,0.0) );
    vec3 gb = hash( i+vec3(1.0,0.0,0.0) );
    vec3 gc = hash( i+vec3(0.0,1.0,0.0) );
    vec3 gd = hash( i+vec3(1.0,1.0,0.0) );
    vec3 ge = hash( i+vec3(0.0,0.0,1.0) );
    vec3 gf = hash( i+vec3(1.0,0.0,1.0) );
    vec3 gg = hash( i+vec3(0.0,1.0,1.0) );
    vec3 gh = hash( i+vec3(1.0,1.0,1.0) );
    
    // projections
    float va = dot( ga, w-vec3(0.0,0.0,0.0) );
    float vb = dot( gb, w-vec3(1.0,0.0,0.0) );
    float vc = dot( gc, w-vec3(0.0,1.0,0.0) );
    float vd = dot( gd, w-vec3(1.0,1.0,0.0) );
    float ve = dot( ge, w-vec3(0.0,0.0,1.0) );
    float vf = dot( gf, w-vec3(1.0,0.0,1.0) );
    float vg = dot( gg, w-vec3(0.0,1.0,1.0) );
    float vh = dot( gh, w-vec3(1.0,1.0,1.0) );
    
    // interpolations
    return vec4( va + u.x*(vb-va) + u.y*(vc-va) + u.z*(ve-va) + u.x*u.y*(va-vb-vc+vd) + u.y*u.z*(va-vc-ve+vg) + u.z*u.x*(va-vb-ve+vf) + (-va+vb+vc-vd+ve-vf-vg+vh)*u.x*u.y*u.z,    // value
                 ga + u.x*(gb-ga) + u.y*(gc-ga) + u.z*(ge-ga) + u.x*u.y*(ga-gb-gc+gd) + u.y*u.z*(ga-gc-ge+gg) + u.z*u.x*(ga-gb-ge+gf) + (-ga+gb+gc-gd+ge-gf-gg+gh)*u.x*u.y*u.z +   // derivatives
                 du * (vec3(vb,vc,ve) - va + u.yzx*vec3(va-vb-vc+vd,va-vc-ve+vg,va-vb-ve+vf) + u.zxy*vec3(va-vb-ve+vf,va-vb-vc+vd,va-vc-ve+vg) + u.yzx*u.zxy*(-va+vb+vc-vd+ve-vf-vg+vh) ));
}

//===============================================================================================
//===============================================================================================
//===============================================================================================
//===============================================================================================
//===============================================================================================

#define BACKGROUND_COLOR vec3(0.5f, 0.5f, 1.0f)

#define NOISE_SCALE 4.0f
#define FLOW_TIME_SCALE 0.0625f
#define ROTATION_TIME_SCALE 0.0981747705f

#define CAMERA_OFFSET -2.0f
#define SPHERE_RADIUS 0.375f

#define DENSITY_MULTIPLYER 16.0f
#define MARCH_ITERATIONS 32

#define DECREASE_DENSITY_NEAR_EDGES 1
#define EDGE_DENSITY_DECREASE_OUTER (2.0f * SPHERE_RADIUS)
#define EDGE_DENSITY_DECREASE_INNER 0.0f

#define SPECULAR_HIGHLIGHT 1
#define POINT_LIGHT_POSITION vec3(1.0f, 0.5f, 0.0f)
#define SPECULAR_DEGREE 6

// Samples the color from a gradient
vec3 colorGradient(float x){
    return vec3(smoothstep(0.25f, 0.4f, x), smoothstep(0.4f, 0.6f, x), smoothstep(0.65f, 0.875f, x));
}

// Samples the color and density at the given coordinates
vec4 sampleAt(vec3 coords){

    // Rotate sphere
    float angle = time * ROTATION_TIME_SCALE;
    float c = cos(angle);
    float s = sin(angle);
    coords = mat3(c, 0.0f, -s, 0.0f, 1.0f, 0.0f, s, 0.0f, c) * coords;

    float t = noised(coords * NOISE_SCALE + vec3(0.0f, -time * FLOW_TIME_SCALE, 0.0f)).x + 0.5f;

    float sqrDist = dot(coords, coords);

    float density = sqrDist <= SPHERE_RADIUS * SPHERE_RADIUS ? smoothstep(0.0f, 1.0f, t) : 0.0f;

#if DECREASE_DENSITY_NEAR_EDGES != 0
    density *= 1.0f - smoothstep(EDGE_DENSITY_DECREASE_INNER, EDGE_DENSITY_DECREASE_OUTER, sqrt(sqrDist));
#endif

    return vec4(colorGradient(t), density);
}

// Marches through the volume once
vec3 march(vec3 stacked, vec3 coords){

    vec4 sampled = sampleAt(coords);
    return mix(stacked, sampled.xyz, sampled.w * DENSITY_MULTIPLYER / float(MARCH_ITERATIONS));
}

// Gets the full-alpha color of the sphere by ray-marching
// between the end and start positions
vec3 getSphereColor(vec3 start, vec3 end, vec3 backgroundColor){
    
    vec3 color = backgroundColor;
    float td = 1.0f / float(MARCH_ITERATIONS);
    float t = td / 2.0f;

    for (int i = 0; i < MARCH_ITERATIONS; ++i, t += td)
        color = march(color, mix(end, start, t));

    return color;
}

void main(void)
{
    float resolution2 = min(resolution.x, resolution.y);
    
    // The location of the pixel on the XY plane
    vec2 viewPlaneLocation = (gl_FragCoord.xy - resolution.xy* 0.5f) / vec2(resolution2, resolution2);

    vec3 cameraPosition = vec3(0.0f, 0.0f, CAMERA_OFFSET);

    // The direction of the pixel from the camera
    vec3 dir = normalize(vec3(viewPlaneLocation, 0.0f) - cameraPosition);
    
    // The vector from the camera to the closest point on the ray from the origin
    vec3 toClosest = dir * dot(dir, -cameraPosition);

    // The distance from the camera to the closest point on the ray from the origin
    float tcd = sqrt(dot(toClosest, toClosest));
    
    // The vector from the origin to the closest point on the ray
    vec3 closest = cameraPosition + toClosest;
    
    // The square distance from the origin to the closest point on the ray
    float csd = dot(closest, closest);
    
    // The distance from the origin to the closest point on the ray
    float cd = sqrt(csd);
    
    // The distance travelled by the ray inside of the sphere to the point
    // closest to the origin, which is half the distance it travels there total
    float ttcd = sqrt(abs(SPHERE_RADIUS * SPHERE_RADIUS - csd));

    // The start and end of the ray through the sphere
    vec3 start = cameraPosition + dir * (tcd - ttcd);
    vec3 end   = cameraPosition + dir * (tcd + ttcd);

    vec3 backgroundColor = BACKGROUND_COLOR;
    vec3 color = cd <= SPHERE_RADIUS ? getSphereColor(start, end, backgroundColor) : backgroundColor;

    // Previous version, marching with a fixed stride
    // vec3 color = backgroundColor;
    // for (float depth = 3.0f; depth > 1.0f; depth -= 0.0625)
    //     color = march(color, cameraPosition + depth * dir);

    // Take account of sphere depth
    color = mix(backgroundColor, color, ttcd / SPHERE_RADIUS);

#if SPECULAR_HIGHLIGHT != 0
    float plAngle = -time * ROTATION_TIME_SCALE;
    float plc = cos(plAngle);
    float pls = sin(plAngle);

    vec3 pointLightPosition = mat3(plc, 0.0f, -pls, 0.0f, 1.0f, 0.0f, pls, 0.0f, plc) * POINT_LIGHT_POSITION;
    vec3 pointLightDirection = -normalize(pointLightPosition - start);
    vec3 normal = normalize(start);
    float nDotPLD = dot(normal, pointLightDirection);
    vec3 reflection = nDotPLD * 2.0f * normal - pointLightDirection;

    float specularAmount = nDotPLD <= 0.0f ? dot(dir, reflection) : 0.0f;
    for (int i = 0; i < SPECULAR_DEGREE - 1; ++i)
        specularAmount *= specularAmount;
    color = cd <= SPHERE_RADIUS ? mix(color, vec3(1.0f, 1.0f, 1.0f), specularAmount) : color;
#endif

    // Output to screen
    glFragColor = vec4(color, 1.0);
}
