#version 420

// original https://www.shadertoy.com/view/fscXDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// taste of noise 2 by leon denise 2021/10/12
// result of experimentation with organic patterns
// using code from Inigo Quilez, David Hoskins and NuSan
// licensed under hippie love conspiracy

// global variable
float material;

// Dave Hoskins
// https://www.shadertoy.com/view/4djSRW
float hash13(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

// Inigo Quilez
// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }
float smoothing(float d1, float d2, float k) { return clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 ); }
    

// rotation matrix
mat2 rot(float a) { return mat2(cos(a),-sin(a),sin(a),cos(a)); }

#define repeat(p,r) (mod(p,r)-r/2.)

// sdf
float map (vec3 p)
{
    vec3 pp = p;
    
    // time
    float t = time * 0.1;
    
    // travel
    p.z += t;
    
    // rotation parameter
    vec3 angle = vec3(4.,3.,8.) + p;
    
    // domain repeat
    float grid = 1.5;
    p = repeat(p, grid);
    
    // kif
    const int count = 6;
    float a = 1.0;
    float scene = 1000.;
    float shape = 1000.;
    for (int index = 0; index < count; ++index)
    {
        // fold
        p = abs(p)-.4*a;
        
        // rotate
        p.xz *= rot(angle.y/a);
        p.yz *= rot(angle.x/a);
        p.yx *= rot(angle.z/a);
        
        // sphere
        shape = length(p)-.3*a;
        
        // material blending
        material = mix(material, float(index), smoothing(shape, scene, 0.1*a));
        
        // add
        scene = smin(scene, shape, 0.1 * a);
        
        // falloff
        a /= 1.9;
    }
    
    // cylinder hole
    scene = smin(scene, length(pp.xy)-0.15, 0.1);
    
    // shell
    scene = -(scene);
    
    // surface details
    p = repeat(p, 0.03);
    scene -= length(p)*.2;
        
    return scene;
}

// return color from pixel coordinate
void main(void)
{
    // reset color
    glFragColor = vec4(0);
    material = 0.0;
    
    // camera coordinates
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.y;
    vec3 eye = vec3(0,0,-0.2);
    vec2 mouse = mouse*resolution.xy.xy / resolution.xy;
    eye.xz *= rot(0.4+mouse.x*3.);
    eye.xy *= rot(0.6-mouse.y*3.);
    vec3 z = normalize(-eye);
    vec3 x = normalize(cross(z, vec3(0,1,0)));
    vec3 y = normalize(cross(x, z));
    vec3 ray = normalize(vec3(z * 0.5 + uv.x * x + uv.y * y));
    vec3 pos = eye + ray * .1;
    
    // white noise
    vec3 seed = vec3(gl_FragCoord.xy, time);
    float rng = hash13(seed);
    
    // raymarch
    const int steps = 30;
    for (int index = steps; index > 0; --index)
    {
        // volume estimation
        float dist = map(pos);
        if (dist < 0.001)
        {
            float shade = float(index)/float(steps);
            
            // compute normal by NuSan (https://www.shadertoy.com/view/3sBGzV)
            vec2 off=vec2(.001,0);
            vec3 normal = normalize(map(pos)-vec3(map(pos-off.xyy), map(pos-off.yxy), map(pos-off.yyx)));
            
            // Inigo Quilez color palette (https://iquilezles.org/www/articles/palettes/palettes.htm)
            vec3 tint = vec3(1.)+vec3(0.5)*cos(vec3(1,2,3)*material*0.2+pos.z);
            
            // specular lighting
            float ld = dot(normal, -ray)*0.5+0.5;
            vec3 light = vec3(0.196,0.925,0.914) * pow(ld, 10.) * 0.5;
            
            // pixel color
            glFragColor.rgb = (tint + light) *  shade;
            
            break;
        }
        
        // dithering
        dist *= 0.8 + 0.1 * rng;
        
        // raymarch
        pos += ray * dist;
    }
}

