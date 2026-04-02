#version 420

// original https://www.shadertoy.com/view/Wl3XzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 light1 = normalize(vec3(-0.2, 0.5, -0.5));
const vec3 light2 = normalize(vec3(-1.0,0.0, 0.0));
#define collisionIterations 10
//https://www.iquilezles.org/www/articles/smin/smin.htm
float sminCubic( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}
vec3 mirrorLoop(vec3 p){
    return abs(fract(0.5 - p) - 0.5);
}
float mirrorLoop(float p){
    return abs(fract(0.5 - p) - 0.5);
}
float random (vec2 st) {
    return mod(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        47123777.537, 1.0);
}
float noise2(vec2 v){
    float l = sin(v.x*0.5 + 21.321) - sin(v.y*0.44 + 219.34);
    float m = sin(v.x*4.0 + 42.4291 + l) + sin(v.y*2.0 + 2.14 + l);
    float n = sin(v.x*2.0 + l + 3.32) + sin(v.y*2.2 + m + 451.23);
    return  sin(l * 0.1)*5.0 + n + m*0.4;
}

float tiles (vec3 p){
    vec2 ipos = floor(p.xz*0.5);

    return step(random(ipos),0.1);//1.0 - clamp(smoothstep(x,0.0, 0.45) +  smoothstep(z, 0.0, 0.45),0.0,1.0);
    }

float scene (vec3 p){
    float size = 0.5;
    vec3 pMod = mod(p - 0.5,5.0) - 2.5;
    pMod.y = p.y + sin(p.y)*0.5;
    //pMod.y += 3.0;
    pMod.y *= 0.1;
    vec3 q = abs(pMod) - size;
    //q.y = 0.0;
    float cubes = length(max(q,0.0));
    //float spheres = length(mod(p,0.4) - 0.2) - 0.2;
    //return length(p) - 1.0;
    float height = 2.5 - abs(p.y ) ;
    height = (height + 1.0 + noise2(p.xz*0.1 + p.y*0.15) + length(noise2(p.xz*0.5))*0.2);
    //return cubes;
    return mix(height, sminCubic(height,cubes, 2.9), 0.5);
}

vec3 nor( vec3 p, float prec )
{
    vec2 e = vec2( prec, 0. );
    vec3 n = vec3(
        scene(p+e.xyy) - scene(p-e.xyy),
        scene(p+e.yxy) - scene(p-e.yxy),
        scene(p+e.yyx) - scene(p-e.yyx) );
    return normalize(n);
}

float grid (vec3 p){

    float x = abs(fract(0.5 - p.x ) - 0.5);
    float z = abs(fract(0.5 - p.z ) - 0.5);
    return smoothstep(x,0.0, 0.45) +  smoothstep(z, 0.0, 0.45);
    }

void main(void)
{

    vec2 uv = (gl_FragCoord.xy+gl_FragCoord.xy - resolution.xy) / resolution.y;

    glFragColor = vec4(0,0,0,1.0);
    
    vec3 ro = vec3(0,0.0,2.0 + time);

    
    float a = mouse.x*resolution.xy.x*0.01;
    //ro.x =  ro.z * sin(a);
    //ro.z =  ro.z * cos(a);
    
    vec3 w = normalize(ro);
    vec3 u = cross(w, vec3(0.0, 1.0, 0.0));
    vec3 v = cross(u, w);
    u = normalize(u);
    v = normalize(v);
    vec3 rd = normalize( uv.x * u + uv.y * v + 1.0*w);
    
    float altitude = 0.0;
    for (int i=0; i < collisionIterations; i++){
        altitude += scene(ro + rd*float(i)*0.5);
    }
    altitude /= float(collisionIterations);
    ro.y = ro.y + 1.9 - altitude; 
    float d = 0.0;
    float raystep = 0.01;
    for (int i=0; i<64; i++){
        vec3 p = ro + rd * d;
        float r = scene(p);
        int outside = int (r > 0.001);
        d += float(outside) * r;
    }
    vec3 p = ro + rd * d;
    float result = step(scene(p), 1.0);
    vec3 normal =  nor(p, 0.05);
       float diffuse = dot(light1,normal);
    diffuse = clamp(diffuse, 0.0, 1.0);
    float specular = dot(reflect(rd,normal), light2);
    specular = clamp(specular*specular,0.0,1.0);
    vec3 color = vec3 (0.7, 0.2, length(ro - p)*0.25);
    float patternMask = (d*0.25 - 2.0); 
    vec3 pattern = vec3(grid(p)) * clamp(2.0 - patternMask*patternMask, 0.0,1.0); 
    float wallsMask = 1.0 - clamp(dot(vec3(0.0,0.0,-1.0), normal),0.0,1.0);
    pattern *=wallsMask;
    float fresnel = 1.0 - clamp(dot(-rd, normal),0.0,1.0);
    
    float fog = clamp(color.z*0.1,0.0,1.0);
    vec4 finalColor = vec4( diffuse * color + specular,0 );
    finalColor = mix(finalColor, vec4(0.0,0.0,1.0,1.0),fog + pattern.x*pattern.x*400.0);
    //finalColor = mix(finalColor, vec4(0.0,0.0,1.0,1.0), pattern);
    glFragColor =  finalColor +fog*fresnel*0.15 ;
}
