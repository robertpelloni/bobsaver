#version 420

// original https://www.shadertoy.com/view/3dSyzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Used resources :
// https://en.wikipedia.org/wiki/Rotation_matrix
// https://en.wikipedia.org/wiki/Schwarzschild_radius
// https://en.wikipedia.org/wiki/Gravitational_lens#Explanation_in_terms_of_spacetime_curvature
// https://thebookofshaders.com/11/

// rotation matrices

mat2 rot(float a){
    return mat2(cos(a), -sin(a),
               sin(a), cos(a));
}

mat3 rot(vec3 u, float a){
    float x = u.x;
    float y = u.y;
    float z = u.z; 
    return mat3(
        cos(a) + x*x*(1.-cos(a)), x*y*(1.-cos(a))-z*sin(a), x*z*(1.-cos(a))+y*sin(a),
        y*x*(1.-cos(a))+z*sin(a), cos(a)+y*y*(1.-cos(a)), y*z*(1.-cos(a))-x*sin(a),
        z*x*(1.-cos(a))-y*sin(a), z*y*(1.-cos(a))+x*sin(a), cos(a)+z*z*(1.-cos(a))
    );
}

// random and noise functions

float hash(float p) {
    p = fract(p * 0.011); p *= p + 7.5; p *= p + p;
    return fract(p);
}

float noise(vec3 x) {
    const vec3 step = vec3(110, 241, 171);

    vec3 i = floor(x);
    vec3 f = fract(x);
 
    float n = dot(i, step);

    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               mix(mix( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   mix( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}

// noise with octaves
float fbm(vec3 x) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100);
    for (int i = 0; i < 4; ++i) { // 4 octaves
        v += a * noise(x);
        x = x * 2.5 + shift;
        a *= 0.5;
    }
    return v;
}

// generate the background map
vec3 background(in vec3 rd){
    
    vec3 gc = vec3(0., 0., 1.); // galaxy center
    
    float i = (1.- abs(rd.y - gc.y));
    
    vec3 val = vec3(pow(i, 8.)) * fbm((rd+vec3(2., 1, -4.))*10.)*0.5;
    val *= clamp(dot(rd.xz, gc.xz), 0.,1.);
    
    val *= 0.5/distance(vec3(rd.x/2.5, rd.y*6., rd.z), gc);
    
    val.r *= 1./distance(rd, gc);
    val.b *= distance(rd, gc);
    
    val.g = (val.r + val.b) / 4.;
    
    val /= fbm(-rd);
    
    // add dust
    val = clamp(val, 0., 1.);
    if(abs(gc.y - rd.y) <= 0.1)
        val -= fbm(rd*30.)*vec3(1.-abs(gc.y - rd.y)*10.) * vec3(0.2, 0.8, 0.9) * pow(clamp(dot(rd, gc), 0., 1.), 1.5);
    
    // stars
    float s = fbm(rd * 100.);
    s = pow(s*1.18, 15.0);
    val += s;
    
    val.b += 0.05 * length(val) + 0.2;
    
    return val;
}

const float G = 0.01;
const float c = 100.;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;

    vec3 ro = vec3(5., 0., -10); // origin of the ray
    vec3 rd = normalize(vec3(uv, 1.)); // inital direction of the ray
    
    float time = time;
    
    vec3 col = vec3(0.); // pixel color
    
    vec4 bh = vec4(3., 0., 0., 100000.); // black hole (x, y, z, mass)
    // animate black hole
    float k = 4.;
    bh.x += cos(time)*k;
    bh.y += sin(time)*k;
    
    
    // rotate towards the black hole
    vec3 cam = vec3(0., 0., 1.);
    
    rd.xy *= rot(0.7*sin(time*0.25));
    rd.xz *= rot(0.2*sin(time*0.25));
    
    vec3 rb = bh.xyz - ro;
    
    float a = acos(dot(rb, cam) / length(rb));
    vec3 rn = normalize(cross(rb, cam));
    
    rd *= rot(rn, -a*0.8+sin(time)*0.1);
    
    
    
    // calculate the distance to the closest point between the ray and the black hole
    float t = dot(rd, bh.xyz - ro);
    
    vec3 v = ro + rd * t - bh.xyz; // vector between closest point and blackhole
    float r = length(v); // its distance

    // Schwarzfield radius
    float rs = 2. * G * bh.w / (c*c);
    if(r >= rs * 2.){ // some cheat on values to make it look better
        vec3 nml = normalize(cross(v, rd)); // axis of rotation of the ray
        float a = 4. * bh.w * G / (r * c * c); // angle of deflection caused by gravitational field

        rd *= rot(nml, a);

        col = background(rd);//texture(iChannel0, rd).rgb;
    }
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
