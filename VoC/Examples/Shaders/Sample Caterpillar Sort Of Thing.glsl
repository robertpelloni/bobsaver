#version 420

// original https://www.shadertoy.com/view/3lVSDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Sphere(vec3 p, float radius) {
    return length(p)-radius;
}

// Blending function
float smin( float a, float b, float k ){
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}

// Get the distance to the plane and sphere
float GetDist(vec3 p) {
    float d = p.y;
    float t = time;
    
    for(float i = 8.; i >= 1.; i-=1.) {
        float size = .9 + i *.15 + 0.1*sin(time);
        float spiral = 9.;                             // eight figure size
        float ds = size*2.5;                         // distance between spheres
        
        float x = spiral*cos(t+ds);
        float y = .3+1.5*size*sin(3.*t+i);
        float z = spiral*cos(t+ds)*sin(t+ds);
        
        d = smin(Sphere(p-vec3(x, y, z), size), d, .4);
    }
    return d;
}

float RayMarch(vec3 ro, vec3 rd) {
    float d = 0.;
    for(int i = 0; i < 80; i++) {
        float step = GetDist(ro + rd*d);
        d += step*.5;
        if(abs(d) < 0.0001 || d > 30.) break;
    }
    return d;
}

vec3 GetNormal(vec3 p) {
    float d = GetDist(p);
    vec2 e = vec2(.01, 0.);
    vec3 normal = d - vec3(GetDist(p-e.xyy),
                           GetDist(p-e.yxy),
                           GetDist(p-e.yyx)); //differentiation
    normal = normalize(normal);
    return normal;
}

float GetLight(vec3 p){
    vec3 light = vec3(3., 10., 7.);
    vec3 normal = GetNormal(p);
    
    vec3 lightVec = normalize(light-p);
    float dif = max(0., dot(normal, lightVec));
    float shadow = RayMarch(p+normal*.002, lightVec);
    
    if(shadow < length(light-p)){
        dif *= clamp(shadow*.2, 0.,1.);
    }
    
    return dif;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy / resolution.xy;
    vec3 col = vec3(0.);
   
    // any ideas about mouse rotation?
    vec3 ro = vec3(8., 10., 13.);
    vec3 lookAt = vec3(0.);
    float zoom = 1.;
    
    // front, right and up vectors (3d camera model)
    vec3 f = normalize(lookAt - ro);
    vec3 r = normalize(cross(f, vec3(0.,1.,0.)));
    vec3 u = normalize(cross(r,f));
    vec3 c = ro + f * zoom;             // center
    vec3 i = c + r*uv.x + u*uv.y;         // point on the rotated uv screen
    vec3 rd = i - ro;
    
    float d = RayMarch(ro, rd);
    float dif = GetLight(ro + rd *d);
    col = vec3(dif);
    
    glFragColor = vec4(col,1.0);
    
}
