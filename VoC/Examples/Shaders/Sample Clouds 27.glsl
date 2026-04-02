#version 420

// original https://www.shadertoy.com/view/wslGRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
#define degToRad (PI * 2.0) / 360.0

// noise and fbm function from https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
//-----------------------------------------------------------------------------
mat3 m = mat3( 0.00,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.0-2.0*f);

    float n = p.x + p.y*57.0 + 113.0*p.z;

    float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                        mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                    mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                        mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
    return res;
}

float noise(float x) {
    return fract(sin(dot(vec2(x), vec2(12.9898, 78.233)))* 43758.5453);
}

float fbm( vec3 p )
{
    float f;
    f  = 0.5000*noise( p ); p = m*p*2.02;
    f += 0.2500*noise( p ); p = m*p*2.03;
    f += 0.1250*noise( p );
    return f;
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
    float speed = time*1.0;
    p.z += speed;
    
    float n = floor(p.z/0.5);
    p.y += noise(n)*0.1+sin(p.z)*0.5+sin(time*0.1)*0.2;
    p.x += noise(n)*0.3+sin(p.z)*1.5;
    p.y -= 1.5;
    p.y = abs(p.y);
    p.y -= 1.5;

    float cloudD = (p.y+1.0+fbm(p*1.1)*0.6);
    vec3 cloudCol = vec3(1.5,1.5,1.5)+fbm(p*1.1);
    
    return vec4(cloudCol,cloudD);
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
