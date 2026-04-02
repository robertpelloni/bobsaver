#version 420

// original https://www.shadertoy.com/view/tssGW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define degToRad (PI * 2.0) / 360.0

float noise(float x) {
    return fract(sin(dot(vec2(x), vec2(12.9898, 78.233)))* 43758.5453);
}

mat3 matRotateX(float rad)
{
    return mat3(1,       0,        0,
                0,cos(rad),-sin(rad),
                0,sin(rad), cos(rad));
}

mat3 matRotateY(float rad)
{
    return mat3(cos(rad), 0, -sin(rad),
                    0, 1, 0,
                    sin(rad), 0, cos(rad));
}

vec4 map(vec3 p){
    float speed = time*15.0;
    p.z += speed;
    
    float animSpeed = time*5.0;
    
    float n = floor(p.x/10.0);
    p.z = mod(p.z,15.0)-7.5;
    p.y = mod(p.y,6.0)-3.0;
    p.x = mod(p.x,6.0)-3.0;
    p.z += fract(noise(floor(p.z/10.0)*1.3))*sin(p.z+animSpeed)*0.2;
    p.y += fract(noise(n)*2.3)*sin(p.z+animSpeed)*0.3;
    p.x += fract(noise(n)*1.5-0.5)*cos(p.z+animSpeed)*0.5;
    p.y += noise(n)*0.1;
    p.z += noise(n)*0.2;
    
    // This is based on the Capsule Distance function from the IQ's, and it's modified.
    p += vec3(0.0,0.0,1.0);
    p.z -= clamp( p.z, 0.0, 8.0 );
    p.y += sin(n*time)*1.2;
    float pt = length( p ) - 0.05+sin(n*time*p.z)*0.02;
    
    return vec4(vec3(1.98,1.98,1.98),pt);
}

vec3 normalMap(vec3 p){
    float d = 0.0001;
    return normalize(vec3(
        map(p + vec3(  d, 0.0, 0.0)).w - map(p + vec3( -d, 0.0, 0.0)).w,
        map(p + vec3(0.0,   d, 0.0)).w - map(p + vec3(0.0,  -d, 0.0)).w,
        map(p + vec3(0.0, 0.0,   d)).w - map(p + vec3(0.0, 0.0,  -d)).w
    ));
}

float shadowMap(vec3 ro, vec3 rd){
    float h = 0.0;
    float c = 0.001;
    float r = 1.0;
    float shadow = 0.5;
    for(float t = 0.0; t < 30.0; t++){
        h = map(ro + rd * c).w;
        if(h < 0.001){
            return shadow;
        }
        r = min(r, h * 16.0 / c);
        c += h;
    }
    return 1.0 - shadow + r * shadow;
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    //mat3 camRotY = matRotateY(-(time*30.0)*degToRad)*matRotateX(20.*degToRad);
    mat3 camRotY = matRotateX(20.0*degToRad);
    
    vec3 ro=vec3(0.,-.1,-8.);
    vec3 rd=normalize(vec3(p,1.8));
    
    float t, dist;
    t = 0.0;
    vec3 distPos = vec3(0.0);
    vec4 distCl = vec4(0.0);
    for(int i = 0; i < 60; i++){
        distCl = map(distPos);
        dist = distCl.w;
        if(dist < 1e-4){break;}
        if(t>30.)break;
        t += dist;
        distPos = (ro+rd*t);
    }

    vec3 color;
    float shadow = 1.0;
    
    if(t < 30.){
        // lighting
        vec3 lightDir = vec3(1.0, 10.0, 1.0);
        vec3 light = normalize(lightDir);
        vec3 normal = normalMap(distPos);

        // difuse color
        float diffuse = clamp(dot(light, normal), 1.0, 1.0);
        float lambert = max(.0, dot( normal, light));
        
        // shadow
        shadow = shadowMap(distPos + normal * 0.001, light);

        // result
        color += vec3(lambert);
        color = diffuse*(distCl.xyz+(.1-length(p.xy)/3.))*vec3(1.0, 1.0, 1.0);
    }else{
        color =.84*max(mix(vec3(1.1,1.31,1.35)+(.1-length(p.xy)/3.),vec3(1),.1),0.);
    }

    // rendering result
    float brightness = 1.0;
    vec3 dst = (color * max(0.5, shadow))*brightness;
    glFragColor = vec4(dst, 1.0);

}
