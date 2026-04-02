#version 420

// original https://www.shadertoy.com/view/3l3yW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Made using functions from http://jamie-wong.com/2016/07/15/ray-marching-signed-distance-functions/#signed-distance-functions
//and https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

const int MAX_MARCHING_STEPS=255;
const float MIN_DIST=0.;
const float MAX_DIST=100.;
const float EPSILON=.0001;

//GENERAL FUNCTIONS//

float smin(float a,float b,float k){
    float res=exp(-k*a)+exp(-k*b);
    return-log(res)/k;
}

mat4 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat4(
        vec4(c, 0, s, 0),
        vec4(0, 1, 0, 0),
        vec4(-s, 0, c, 0),
        vec4(0, 0, 0, 1)
    );
}

mat4 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);

    return mat4(
        vec4(c, -s, 0, 0),
        vec4(s, c, 0, 0),
        vec4(0, 0, 1, 0),
        vec4(0, 0, 0, 1)
    );
}

//GENERAL FUNCTIONS end//--

//SDFs//

float sdSphere(vec3 p,float r){
    return length(p)-r;
}

//SDFs end//--

//SCENE COMPOSITION//

float sceneSDF(vec3 p){
    //outside ring 1
    float rotSpeed1_y = time * 0.25;
    float rotSpeed1_z = cos(time*0.5)*13.0;
    vec3 rotP1 = (rotateZ(rotSpeed1_z) * rotateY(rotSpeed1_y) * vec4(p,1.0)).xyz;

    float s1 = sdSphere(rotP1,1.0);
    float s2 = sdSphere(rotP1+vec3(-1.0,0.0,0.0),1.2);
    float s = max(s1,-s2);
    float s3 = sdSphere(rotP1+vec3(1.0,0.0,0.0),1.2);
    s = max(s,-s3);
    
    //outside ring 2
    float rotSpeed2_y = sin(time*0.24)*13.0;
    float rotSpeed2_z = cos(time*0.24+0.6)*13.0;
    vec3 rotP2 = (rotateZ(rotSpeed2_z) * rotateY(rotSpeed2_y) * vec4(p,1.0)).xyz;

    float s4 = sdSphere(rotP2,1.5);
    float s5 = sdSphere(rotP2+vec3(-1.0,0.0,0.0),1.6);
    s4 = max(s4,-s5);
    float s6 = sdSphere(rotP2+vec3(1.0,0.0,0.0),1.6);
    s4 = max(s4,-s6);
    s = min(s,s4);
    
    //middle sphere
    float sMid = sdSphere(p,0.5);
    float sMid_1 = sdSphere(p+vec3(-0.5,0.0,0.0),0.5);
    sMid = max(sMid,-sMid_1);
    s = min(s,sMid);

    return s;
}

//SCENE COMPOSITION end//--

//RAYMARCHING FUNCTIONS//

float shortestDist(vec3 eye,vec3 marchDir,float start,float end){
    float t=start;
    for(int i=0;i<MAX_MARCHING_STEPS;i++){
        float dist=sceneSDF(eye+t*marchDir);
        if(dist<EPSILON){
            return t;//hits object
        }
        t+=dist;
        if(t>=end){
            return end;//hits sky (gives up)
        }
    }
    return end;
}

vec3 rayDirection(float fieldOfView,vec2 size,vec2 fragCoor){
    vec2 xy=fragCoor-size/2.;
    float z=size.y/tan(radians(fieldOfView)/2.);
    return normalize(vec3(xy,-z));
}

vec3 normal(vec3 p){
    return normalize(vec3(
        sceneSDF(vec3(p.x+EPSILON,p.y,p.z))-sceneSDF(vec3(p.x-EPSILON,p.y,p.z)),
        sceneSDF(vec3(p.x,p.y+EPSILON,p.z))-sceneSDF(vec3(p.x,p.y-EPSILON,p.z)),
        sceneSDF(vec3(p.x,p.y,p.z+EPSILON))-sceneSDF(vec3(p.x,p.y,p.z-EPSILON))
    ));
}

vec3 phongContrib(vec3 k_diffuse, vec3 k_specular, float alpha, vec3 p, vec3 eye, vec3 lightPos, vec3 lightIntes){
    vec3 N = normal(p);
    vec3 LightDir = normalize(lightPos-p);
    vec3 RayDir = normalize(eye-p);
    vec3 ReflectDir = normalize(reflect(-LightDir,N));

    float dotLightNorm = dot(lightPos,N);
    float dotRefRay = dot(ReflectDir,RayDir);

    if(dotLightNorm < 0.0){
        //light not vissable if dot less than 0
        return vec3(0.0);
    }

    if(dotRefRay < 0.0){
        //apply only diffuse
        return lightIntes * (k_diffuse*dotLightNorm);
    }
    return lightIntes * (k_diffuse * dotLightNorm + k_specular * pow(dotRefRay, alpha));
}

vec3 phongIllum(vec3 k_ambient, vec3 k_diffuse, vec3 k_specular, float alpha, vec3 p, vec3 eye){
    const vec3 ambientLight = 0.5 * vec3(1.0);
    vec3 color = ambientLight * k_ambient;

    vec3 lightPos1 = vec3(3.0,2.0,4.0);
    vec3 lightIntes1 = vec3(0.2);
    color += phongContrib(k_diffuse, k_specular, alpha, p, eye, lightPos1, lightIntes1);

    return color;
}

mat4 vMatrix(vec3 eye, vec3 center, vec3 up){
    vec3 f = normalize(center-eye);
    vec3 s = normalize(cross(f,up));
    vec3 u = cross(s,f);
    return mat4(    
        vec4(s,0.0),
        vec4(u,0.0),
        vec4(-f,0.0),
        vec4(0.0,0.0,0.0,1.0)
    );
}

//RAYMARCHING FUNCTIONS end//--

void main(void) {
    //CAMERA SETTINGS
    float fieldOfView = 30.0;
    vec3 eyePos = vec3(10.0,2.0,0.0);
    float rotationSpeed = 0.25;
    vec4 bgColor = vec4(0.0118, 0.0078, 0.0667, 1.0);

    vec3 viewDir=rayDirection(fieldOfView,resolution.xy,gl_FragCoord.xy);
    vec3 eye=(vec4(eyePos,1.0) * rotateY(time*rotationSpeed)).xyz;
    mat4 viewToWorld = vMatrix(eye, vec3(0.0), vec3(0.0,1.0,0.0));
    vec3 worldDir = (viewToWorld * vec4(viewDir,0.0)).xyz;
    float dist=shortestDist(eye,worldDir,MIN_DIST,MAX_DIST);
    if(dist>MAX_DIST-EPSILON){glFragColor=bgColor;return;}
    
    vec3 p = eye + dist * worldDir;//hit position

    //COLOR SETTINGS
    vec3 ambientCol = (normal(p)+2.0)*0.3;
    vec3 diffuseCol = vec3(0.9647, 0.3098, 0.0471);
    vec3 specularCol = vec3(1.0, 0.9098, 0.9098);
    float gloss = 50.0;

    vec3 color = phongIllum(ambientCol, diffuseCol, specularCol, gloss, p, eye);

    glFragColor=vec4(color,1.);
}
