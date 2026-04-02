#version 420

// original https://www.shadertoy.com/view/MsXyzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

const int maxIter = 100;
float df(vec3 p) {
    vec3 z = p;
    float r = 0.0;
    float dr = 1.0;
    float power = 8.0;
    //float power = 6.0*abs(sin(0.3*time)) + 2.0;
    for(int i = 0; i < maxIter; i++) {
        r = length(z);
        if(r > 2.0) break;
        
        float theta = acos(z.z/r);
        float phi = atan(z.y, z.x);
        
        dr = power*pow(r, power-1.0)*dr + 1.0;
        
        r = pow(r, power);
        theta *= power;
        phi *= power;
        
        z = r*vec3(sin(theta)*cos(phi), sin(theta)*sin(phi), cos(theta));
        z += p;
    }
    float d = 0.5*log(r)*r/dr;
    
    //box
    d = min(d, sdBox(p - vec3(0, -1, 0), vec3(5, 0.01, 5)));
    return d;
}

vec3 calcNormal(vec3 p) {
    float eps = 0.00001;
    return normalize(vec3(
        df(p + vec3(eps, 0, 0)) - df(p - vec3(eps, 0, 0)),
        df(p + vec3(0, eps, 0)) - df(p - vec3(0, eps, 0)),
        df(p + vec3(0, 0, eps)) - df(p - vec3(0, 0, eps))
        ));
}

struct Ray {
    bool hit;
    vec3 hitPos;
    vec3 hitNormal;
    vec3 rayDir;
    float t;
    int steps;
};
const int maxSteps = 200;
Ray trace(vec3 camPos, vec3 rayDir) {
    vec3 p;
    vec3 normal;
    float t;
    int steps;
    bool hit = false;
    for(int i = 0; i < maxSteps; i++) {
        p = camPos + t*rayDir;
        float d = df(p);
        if(d < 0.001) {
            p -= 0.001*rayDir;
            hit = true;
            normal = calcNormal(p);
            steps = i;
            break;
        }
        t += d*0.9;
    }
    return Ray(hit, p, normal, rayDir, t, steps);
}

bool isVisible(vec3 p, vec3 lightPos) {
    Ray tr = trace(lightPos, normalize(p - lightPos));
    if(distance(tr.hitPos, p) < 0.001) {
        return true;
    }
    else {
        return false;
    }
}

const vec3 lightPos = vec3(30, 30, 30);
const vec3 skyColor = vec3(0.85, 1.0, 1.0);

vec3 phong(Ray tr) {
    vec3 color;
    
    vec3 ao = pow(float(tr.steps)/float(maxSteps), 0.7) * skyColor;
    color += 0.5*ao;
    
    bool visible = isVisible(tr.hitPos, lightPos);
    vec3 sunDir = normalize(lightPos - tr.hitPos);
    vec3 diffuse, specular;
    if(visible) {
        diffuse = max(dot(tr.hitNormal, sunDir), 0.0) * vec3(1.0);
        
        vec3 r = reflect(-sunDir, tr.hitNormal);
        specular = pow(max(dot(-tr.rayDir, r), 0.0), 14.0) * vec3(1.0);
    }
    color += 0.8*diffuse + 0.2*specular;
    
    return color;
}

vec3 shading(Ray tr) {
    if(!tr.hit) {
        return vec3(skyColor);
    }
    vec3 color;
    
    color += phong(tr);
    
    vec3 refl = reflect(tr.rayDir, tr.hitNormal);
    Ray tr2 = trace(tr.hitPos, refl);
    color += 0.2*phong(tr2);
    
    return color;
}

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    //camera settings
    vec3 camPos = 2.0*vec3(sin(0.5*time), 0, cos(0.5*time));
    vec3 camFront = normalize(-camPos);
    vec3 camUp = vec3(0, 1, 0);
    vec3 camRight = cross(camFront, camUp);
    float focus = 1.3;

    vec3 rayDir = normalize(uv.x*camRight + uv.y*camUp + focus*camFront);
    Ray tr = trace(camPos, rayDir);

    glFragColor = vec4(shading(tr), 1.0);
}
