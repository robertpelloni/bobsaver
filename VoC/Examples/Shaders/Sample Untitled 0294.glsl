#version 420

// original https://www.shadertoy.com/view/4dGBDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define STEPS 64.
#define PI 3.14159
#define EPS 0.0001
#define EPSN 0.001

mat2 rot(float a){
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float distSphere(vec3 pos, float radius){
    return length(pos) - radius;
}

float distScene(in vec3 pos, out int material){
    
    material = 0;
    float minDist, dist;
    
    pos.xz = rot(0.5 * time + sin(0.5 * time)) * pos.xz;
    pos.yz = rot(0.5 * time) * pos.yz;
    pos.xy = rot(0.5 * time) * pos.xy;
    
    //blobby shapes
    float deform = 0.0075 * (sin(50. * pos.y) + sin(50. * pos.x) + sin(50. * pos.z));
    minDist = distSphere(pos, 0.02 + 0.07 * (1. + sin(time))) + deform;
    dist = distSphere(pos - vec3(0.4, 0., 0.), 0.02 + 0.07 * (1. + sin(time + 2. * PI / 3.))) + deform;
    if(dist < minDist){
        minDist = dist;
        material = 1;
    }
    dist = distSphere(pos - vec3( -0.4, 0., 0.), 0.02 + 0.07 * (1. + sin(time + 4. * PI / 3.))) + deform;
    if(dist < minDist){
        minDist = dist;
        material = 2;
    }
    
    return minDist;
}

vec3 getNormal(vec3 pos){
    int m;
    return normalize(vec3(distScene(pos + vec3(EPSN, 0., 0.), m) - distScene(pos - vec3(EPSN, 0., 0.), m),
                               distScene(pos + vec3(0., EPSN, 0.), m) - distScene(pos - vec3(0., EPSN,0.), m),
                               distScene(pos + vec3(0., 0.,EPSN), m) - distScene(pos - vec3(0., 0., EPSN), m)
                           )
                    );
}

vec3 render(vec2 uv){
    
    vec3 eye = vec3(0., 0., 4.);
    vec3 ray = normalize(vec3(uv, 1.) - eye);
    
    //background
    vec3 col = vec3(0.2, 0.2, 0.25);
    
    //raymarch
    float step, dist;
    int material;
    vec3 pos = eye;
    bool hit = false;
    for(step = 0.; step < STEPS; step++){
        dist = distScene(pos, material);
        if(abs(dist) < EPS){
            hit = true;
            break;
        }
        pos += ray * dist;
    }
    
    //normal
    vec3 normal = getNormal(pos);
    
    //surface color
    vec3 baseColor;
    float colorVariation = 0.5 + 0.5 * sin(3. * sin(3. * (sin(30. * pos.y) + sin(30. * pos.x) + sin(30. * pos.z))));
    float shine = 5. + 100. * (1. - colorVariation);

    colorVariation = 0.3 + 0.5 * colorVariation;
       colorVariation += step / STEPS;

    if(material == 0){
        baseColor = vec3(colorVariation, 0.33, 0.66);
    }else if(material == 1){
        baseColor = vec3(colorVariation, 0.66, 0.33);
    }else if(material == 2){
        baseColor = vec3(0.33, colorVariation, 0.66);
    }
    
    //shading
    vec3 light0 = vec3(2., 2., 0.);
    float lintensity0 = 0.8;
    vec3 lcolor0 = vec3(1., 1., 0.6);
    vec3 light1 = vec3(2., -2., 0.);
    float lintensity1 = 0.7;
    vec3 lcolor1 = vec3(0.9, 1., 1.);
    vec3 light2 = vec3(2., 0., 0.);
    float lintensity2 = 0.5;
    vec3 lcolor2 = vec3(1., 0.6, 1.);
    
    light0.xz = rot( 2. * time) * light0.xz;
    light1.xz = rot( 2. * time + 2. * PI / 3.) * light1.xz;
    light2.xz = rot( 2. * time + 4. * PI / 3.) * light2.xz;
    
    if(hit){
        vec3 l = normalize(light0 - pos);
        vec3 e = normalize(eye - pos);
        vec3 r = reflect(-l, normal);
    
        col = lintensity0 * vec3(max(dot(normal, l), 0.)) * baseColor * lcolor0; //diffuse
        col += lintensity0 * vec3(pow(max(dot(r, e), 0.), shine)) * lcolor0; //specular
        
        l = normalize(light1 - pos);
        r = reflect(-l, normal);
        col += lintensity1 * vec3(max(dot(normal, l), 0.)) * baseColor * lcolor1; //diffuse
        col += lintensity1 * vec3(pow(max(dot(r, e), 0.), shine)) * lcolor1; //specular
        
        l = normalize(light2 - pos);
        r = reflect(-l, normal);
        col += lintensity2 * vec3(max(dot(normal, l), 0.)) * baseColor * lcolor2; //diffuse
        col += lintensity2 * vec3(pow(max(dot(r, e), 0.), shine)) * lcolor2; //specular
        
        col += 0.2 * baseColor; //ambient
    }
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.x;
    uv = rot(0.1 * time) * uv;
    vec3 col = render(uv);
    glFragColor = vec4(col,1.0);
}
