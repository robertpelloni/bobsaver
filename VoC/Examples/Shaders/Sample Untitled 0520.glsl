#version 420

// original https://www.shadertoy.com/view/WtVSDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}

float smin(float a, float b, float k) {
     float h = clamp(.5 + .5 * (b - a) / k, 0.0, 1.0);   
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sphere(vec3 pos, float radius){
     return length(pos) - radius;   
}
float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

float map(float v, float a, float b, float x, float y){
     float n = (v - a) / (b - a);
     return x + n * (y - x);
}
float scene(vec3 pos){
    
    vec3 i = floor(pos / .2);
    
    
    vec3 pos1 = pos;
    pos1 = mod(pos1, .2) - .1;
    
     pos1.x += random(i.xz) * .05;
     
    
    
     float s1 = sphere(pos1, .05);
    
  
    

    
    
    vec3 pos2 = pos;
     
    
    pos2.y += random(i.xz) + time * .3 * random(i.xz);
    
    
    
    pos2 = mod(pos2, .2) - .1;
    
    
    
    
    float s2 = sphere(pos2, .02);
    
    return smin(s1, s2, .05);
}

vec3 estimateNormal(vec3 pos){
    
     return normalize(
    vec3(
        scene(pos - vec3(.001, .0, .0)) - scene(pos + vec3(.001, .0, .0)),
        scene(pos - vec3(.0, .001, .0)) - scene(pos + vec3(.0, .001, .0)),
        scene(pos - vec3(.0, .0, .001)) - scene(pos + vec3(.0, .0, .001))
        
    ));   
}

vec3 light_dir = vec3(.0, -1.0, 1.0);

vec3 trace(vec3 camOrigin, vec3 dir, out float totalDist) {
     vec3 ray = camOrigin;
    totalDist = 0.0;
    
    // hacky near plane clipping
    totalDist += .1;
    ray += totalDist * dir;
    
    for(int i = 0; i < 128; i++) {
         float dist = scene(ray);
        if (abs(dist) < .001) {
            float diffuse = dot(light_dir, estimateNormal(ray));
            vec3 ambient = vec3(.2, .2, .2);
            return vec3(diffuse * .5) + ambient;
               
        }
        totalDist += dist;
        ray += dist * dir;
    }
    
    return vec3(0.0);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.y /= resolution.x / resolution.y;
    
    vec3 camOrigin = vec3(0.,0.,-3.);
    camOrigin.x += sin(time * .1) * .5;
    camOrigin.z += time * .4;
    vec3 rayOrigin = vec3(camOrigin.xy + uv, camOrigin.z + 3.0);
    vec3 dir = normalize(rayOrigin - camOrigin);
    pR(dir.xz, sin(time) * .08);
    pR(dir.xy, sin(time) * .09);
    pR(dir.zy, sin(time) * .10);
    
    float dist = 0.;
    vec3 color = trace(camOrigin, dir, dist);
    
    color = mix(vec3(0.0), color, clamp(map(dist, 2., 3.5, 1., 0.), 0.0, 1.0));
    // Output to screen
    glFragColor = vec4(color,1.0);
}
