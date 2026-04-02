#version 420

// original https://www.shadertoy.com/view/Nt23Dc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://www.shadertoy.com/view/4djSRW
vec3 hash32(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

const float gridSize = 75.;
const float sphereSize = 0.92;
const float speed = 10.;

void main(void) {
    
    vec3 lightDir = normalize(vec3(cos(time)*0.25,0.5,sin(time)*0.25));
    
    //slowly panning coordinates
    vec2 uv = (gl_FragCoord.xy+time*vec2(2.,1.)*speed)/gridSize;

    //a square that contains the sphere
    vec2 uv2 = (fract(uv)*2.-1.)/sphereSize;
    
    // a method to get sphere normals in orthographic projection
    // (if d >= 1. then we are not touching the sphere)  
    float d = dot(uv2,uv2);
    float z = (d>=1.) ? 0. : sqrt(1.-d);
    vec3 normals = vec3(uv2,z);
    
    //phong reflection model
    float specular = pow(max(2.*z*dot(lightDir,normals) -lightDir.z, 0.0),20.)*0.25;
    float diffuse = 0.5 + dot(normals,lightDir)*0.5;
    
    //here is the palette
    vec2 seed = floor(uv);
    vec3 col = hash32(seed);
    vec3 col2 = min(mix(0.1/(1.-col),col.zxy,diffuse),1.);
    //vec3 col2 = mix(min(0.1/(1.-col),1.),col.zxy,diffuse);
    
    //antialiasing
    col2 *= min(3.*z,1.);
    
    // Output to screen
    glFragColor = vec4(col2+specular,1.0);
}
